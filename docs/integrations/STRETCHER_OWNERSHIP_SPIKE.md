# 🎯 Spike R7 — Dono da Maca, Checkup e Transporte (loki ↔ vp_aicalls)

Data: 2026-10 · Decisão de arquitetura para a integração EMS→prontuário (R6 do CONFORMITY_AUDIT).

---

## 1. O que foi comparado

| Capacidade | loki_prescriptions | vp_aicalls (módulo EMS) |
| :--- | :--- | :--- |
| **Maca** | `client/stretcher.lua` (593 l.) + `server/stretcher.lua` (166 l.) | `client/modules/ems/client.lua` (variáveis locais) |
| Modelo | `strykergurney` / `loweredstrykergurney` (fold via `CreateModelSwap`) | `prop_stretcher` (config `StretcherModel`) |
| Sync | **Server-authoritative** — eventos `p_ambulancejob/server/stretcher/*`, validação de job + distância 7 m, state bags (`usingStretcher`, `isFolded`, `hasStretcher`) | **Nenhuma** — `hasStretcher`/`isonstretcher`/`stretcherinback` são locais do client; sem state bag, sem evento server |
| Paciente | **Jogador real** (1 por vez), body bag opcional | **NPC do chamado IA** (`AttachEntityToEntity` no ped gerado) |
| Veículo | Whitelist multi-modelo (`ambulance`, `maverick`) | Só `ambulance` |
| Item persistente | ✅ item `stretcher` no inventário | ❌ keybind `GrabStretcher` (E) |
| Exports | Não tem (só eventos + ox_target) | Não tem |
| **Checkup** | Minigames NUI reais (BP grava `lastBP`/`pulse` no state bag) + `pulse`/`temperature` dinâmicos + `state.damages` | Progressbar 10 s → flag `CheckupDone`; vitais = **`math.random` no spawn** (`server/modules/ems/server.lua:309-327`), nunca consultam o loki |
| **Entrega** | Check-in com leitos pagos (`Config.CheckIn`, `hospital_beds`) | Dropoff fixo (raio 15 m) → **deleta o NPC** (`server.lua:593`), paga recompensa, abre PCR no vp_tablet |

## 2. Achado-chave

**As duas macas servem a sujeitos diferentes:** a do loki é para **jogadores reais**; a do aicalls, para **NPCs de missão gerados por IA**. Elas não disputam o mesmo paciente — mas disputam o **mesmo socorrista** e o **mesmo estado clínico**:

1. Duas macas com modelos/offsets distintos; o loki só enxerga a própria (`isOurStretcher`, `client/stretcher.lua:105-107`) — a do aicalls fica órfã para os targets do loki;
2. Dois fluxos de keybind **E** (checkup do aicalls vs targets do loki) competindo no mesmo ped;
3. **Estados clínicos duplicados e desconectados** — os vitais random do aicalls nunca tocam `state.pulse`/`temperature`/`damages` do loki; o PCR no vp_tablet registra vitais falsos enquanto o loki tem os reais;
4. **Entrega fantasma** — o dropoff deleta o NPC sem tocar check-in/leitos do loki; o atendimento "desaparece" do RP clínico;
5. Bug interno do loki encontrado no caminho: `client/saline.lua:35` lê o state bag `onStretcher`, que **nunca é setado** (o stretcher usa `usingStretcher`/`attachedTo`).

## 3. Custo das duas arquiteturas

| | Opção A — loki manda no clínico | Opção B — aicalls manda no operacional |
| :--- | :--- | :--- |
| O que muda no loki | Expor exports de maca/checkup (falta pouco) + endpoint `registerCallReport` | Consumir hooks novos em `bridge/integrations/` + aceitar paciente NPC em `attachPlayer` |
| O que muda no aicalls | Parar de inventar vitais; ler/escrever no loki; notificar dropoff | **Reescrever a maca** (sync + server) + expor exports de ciclo de chamado |
| Esforço | **Menor** — loki já é autoritativo e já tem a ponte de vitais | Maior — reescrever o sistema de maca mais fraco para se tornar autoritativo |

## 4. Decisão

### ✅ Opção A — loki é dono do clínico

**Princípio:** *uma fonte de verdade clínica*. Tudo que é estado de paciente (maca para jogador real, vitais, lesões, triagem, prescrição, check-in/leito) é propriedade do `loki_prescriptions`. O `vp_aicalls` continua dono do **operacional de chamado** (gerar ocorrência, spawnar NPC, conduzir a missão, pagar recompensa, emitir PCR no tablet).

**Divisão concreta:**

| Domínio | Dono |
| :--- | :--- |
| Geração de chamado, spawn de NPC, missão, recompensa, cancelamento | `vp_aicalls` |
| PCR no vp_tablet (relatório operacional do chamado) | `vp_aicalls` |
| Maca de **jogador real**, vitais reais, lesões, triagem, prescrição, leito/check-in | `loki_prescriptions` |
| Maca de **NPC de missão** (cosmética, local, sem sync) | `vp_aicalls` — pode coexistir, pois é outro domínio |
| Estado clínico (pulse, temperature, damages, triageTag) | `loki_prescriptions` — o aicalls **lê**, não inventa |
| Registro de atendimento (quem atendeu o quê, quando) | `loki_prescriptions` via `registerCallReport` |

**Por que não B:** exigiria reescrever a maca do aicalls (hoje zero sync, zero server) e fazer o loki aceitar NPCs — inverter a autoridade para o lado mais fraco, com mais trabalho e mais risco.

## 5. Contrato derivado (alimenta o R6)

```
vp_aicalls (EMS)                          loki_prescriptions
─────────────────                         ──────────────────
checkup do NPC ──(opcional, se alvo for
                  jogador real)─────────►  exports.GetPlayerStatus()
                                           exports.getPlayerTriageTag()
                                           → popula Details.Vitals do chamado

dropoff / fim do chamado ── payload ────►  loki_prescriptions:server:registerCallReport
                                           { schema=1, callId, callType, crew,
                                             times, injuries, vitals, triageTag }
                                           → valida job+distância (fail-closed)
                                           → registra atendimento + notifica tripulação

PCR no vp_tablet (paralelo, inalterado)     prontuário/clínica do loki
```

**Regras:**
1. Validação server-side nos dois lados (o aicalls já tem `Config.EMS.Security`; o loki segue o padrão de `server/triage.lua`).
2. Payload versionado (`schema = 1`).
3. **Fail-closed nos dois sentidos:** se o loki não estiver ativo, o PCR do tablet segue sozinho; se o aicalls não estiver ativo, o loki não perde nada.
4. As duas macas coexistem sem conflito de paciente (domínios distintos) — **não** unificar os modelos de prop.

## 6. Residual

- Persistência em banco do `registerCallReport` (hoje memória + notificação) — pode vir depois.
- Corrigir `onStretcher` fantasma em `client/saline.lua:35` (bug interno do loki, fora da integração).

## 7. Status de implementação (R6)

| Peça | Local | Status |
| :--- | :--- | :--- |
| Export `RegisterCallReport` (validação job + schema v1 + registro + notificação da tripulação) | `loki_prescriptions/bridge/integrations/vp_aicalls_server.lua` | ✅ |
| Exports `GetCallReports` / `GetCallReport` | idem | ✅ |
| Hook no dropoff do chamado EMS (payload com callId, tipo, prioridade, detalhes, tempos, tripulação) | `vp_aicalls/server/modules/ems/server.lua` (após validação do paciente, antes do PCR) | ✅ |
| Locale `call_report_registered` (pt/en) | `locales/*.json` | ✅ |
| Consulta de vitais reais no checkup (a icalls → loki) | — | ⏳ Pendente (requer tocar o fluxo de spawn de NPC) |
