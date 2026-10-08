# 🔍 Auditoria de Conformidade (CONFORMITY_AUDIT)

Data: 2026-10 · Escopo: roadmap × código × referências de estudo × integração `vp_aicalls`
Régua: consistência documental + paridade funcional com as referências. Sem correção de código neste ciclo.

---

## 1. Sumário executivo

| Dimensão | Veredito |
| :--- | :--- |
| 7 features da TRACEABILITY_MATRIX | ✅ **7/7 implementadas** com código real |
| ROADMAP (fases 0–6) | ✅ **Corrigido** — Phase 4/medbox marcados como concluídos |
| Referências de estudo (ledger) | ✅ Cobertura completa; ✅ SDC_MedCalls marcado como migrado para o `vp_aicalls` |
| Matriz de features (docs/research) | ✅ **Corrigido** (DUI TV + conjunto de minigames) |
| Bugs apontados pela varredura | ✅ **Corrigidos** (evento Lucas 3 + `TV:terminal()` desativado) |
| Integração `vp_aicalls` | ✅ **Contrato implementado** (R6/R7 concluídos — spike em `docs/integrations/STRETCHER_OWNERSHIP_SPIKE.md`) |

**Veredito geral:** o núcleo funcional está sólido e à frente do roadmap. As divergências de documentação e os dois pontos de runtime (R1–R5) foram **corrigidos neste ciclo**; permanecem abertos o contrato de integração EMS→prontuário (R6) e o spike de dono da maca/checkup (R7).

---

## 2. Roadmap × realidade

Fonte: `docs/ROADMAP.md`. Fatos verificados no código.

| Fase | Status no ROADMAP | Status real | Evidência |
| :--- | :--- | :--- | :--- |
| **0** Estabilização & conformidade | CONCLUÍDO | ✅ Confirmado | Fail-closed em remoção de itens (`server/saline.lua:37`, `server/server.lua:228,344,359`) |
| **1** Arquitetura & referências | CONCLUÍDO | ✅ Confirmado | `docs/research/*` completo (7 projetos no ledger) |
| **2** Minigames & UI | CONCLUÍDO | ✅ Confirmado | 7 minigames em `client/minigames.lua` + `web/build/prescription.js` |
| **3** Soro & Lucas 3 | CONCLUÍDO | ✅ Confirmado | `client/saline.lua` / `server/saline.lua` (vp_needs:80-83) e `client/lucas3.lua` / `server/lucas3.lua` |
| **4** Volante & triagem START | CONCLUÍDO *(atualizado)* | ✅ **Entregue** | SteerBias em `client/damages.lua:73-91`; triagem em `client/triage.lua` + `server/triage.lua` |
| **5** Medbox & DUI Monitor | CONCLUÍDO *(atualizado)* | ✅ **Entregue** | Medbox (`client/medbox.lua`, `server/medbox.lua`) + TV/DUI (`client/tv.lua`, `server/tv.lua`) |
| **6** Hardening & release | FINAL | ⏳ Não iniciado | — |

**Recomendação R1 — ✅ APLICADO:** `ROADMAP.md` atualizado — Phase 4 = CONCLUÍDO, medbox = CONCLUÍDO dentro da Phase 5, DUI Monitor como único item pendente da fase.

---

## 3. As 7 features da TRACEABILITY_MATRIX

Todas verificadas com implementação real (não stub):

| # | Feature | Arquivos | Evidência-chave | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 7 minigames cirúrgicos | `client/minigames.lua`, `web/build/prescription.js` | 7 exports (`StartSuture`:26, `StartClamp`:64, `StartBullet`:102, `StartBP`:140, `StartBandage`:185, `StartBreathalyzer`:338, `StartSwipeCard`:293) + UI (startSuture:402 … swipe:1736) | ✅ |
| 2 | Infusão salina IV | `client/saline.lua`, `server/saline.lua` | Thread de infusão 3s (`server/saline.lua`), state bag `hasSaline`:88, `VpNeedsBridge.ApplySalineTick` (`bridge/integrations/vp_needs_server.lua:81`) | ✅ |
| 3 | Lucas 3 | `client/lucas3.lua`, `server/lucas3.lua` | attach/remove + devolução de item em `playerDropped`:45-52; prop + sync client:21,48,86 | ✅ ⚠️ bug de evento (§5.2) |
| 4 | Muleta / limp | `client/crutch.lua`, `server/crutch.lua` | enable/disable/give (client:47,88,106), export `isCrutchEnabled`:222, expiração server:58 | ✅ |
| 5 | Pulso & temperatura | `client/pulse.lua`, `client/temperature.lua` | State bag `pulse` (pulse:45-119), exports; temperature:72,130-151 | ✅ |
| 6 | Bloqueio de volante | `client/damages.lua` | Braço >40 + motorista + vel >6.0 → `SetVehicleSteerBias(veh, ±0.45)`:86, cooldown 18s; complemento de staggering em perna:93-104 | ✅ |
| 7 | Triagem START | `client/triage.lua`, `server/triage.lua` | Tags GREEN/YELLOW/RED/BLACK:8-13, `/triagem`:76, DrawMarker:95-122; server com job+distância 4.5 e state bag `triageTag`:16-61, export `getPlayerTriageTag`:63 | ✅ |

---

## 4. Referências de estudo

### 4.1 Inventário × ledger

| Projeto | No inventário | No ledger | Caminho no disco | Situação |
| :--- | :--- | :--- | :--- | :--- |
| wasabi_ambulance | ✅ | ✅ (37 entradas) | ✅ `F:\Nova pasta (6)\...` | OK |
| p_ambulancejob | ✅ | ✅ (72) | ✅ | OK |
| osp_ambulance | ✅ | ✅ (149) | ✅ | OK |
| ak47_qb_ambulancejob | ✅ | ✅ (74) | ✅ | OK |
| pluto | ✅ | ✅ (109) | ✅ | OK |
| lation_ui | ✅ | ✅ (27) | ✅ | OK |
| SDC_MedCalls | ✅ | ✅ (6) | ❌ **caminho não existe mais** | ⚠️ Órfão |
| loki_prescriptions (target) | ✅ | (não coberto — aceitável) | ✅ | OK |

- O ledger cobre **todos os 7 projetos de referência** com contagens compatíveis com os arquivos de código do inventário. Nenhum projeto claramente incompleto.
- O **SDC_MedCalls** sumiu do disco (`...\SDC_MedCalls-1.0.3`). Descoberta: seu conteúdo foi absorvido pelo **`vp_aicalls`** — o módulo EMS de lá é literalmente rotulado `CONFIGURAÇÃO DO MÓDULO EMS (SDC_MedCalls)` (`vp_aicalls/config/ems.lua:1`).

**Recomendação R2:** no `REFERENCE_INVENTORY.md`, marcar o SDC_MedCalls como *migrado/absorvido pelo vp_aicalls* e apontar o novo caminho; sem isso o ledger afirma leitura de algo não re-auditável.

### 4.2 Correção das features coladas (docs de pesquisa)

| Afirmação | Onde | Verdicto |
| :--- | :--- | :--- |
| "Monitor TV/ECG em DUI ✅ Telas Hospitalares" | `REFERENCE_FEATURE_MATRIX.md:22` | ❌ **Falso.** O único DUI real é o ECG do Lifepak (`client/defibrilator.lua:243` → `web/ecg.html`). `web/tv.html` existe mas não é carregado por nenhum Lua. |
| "7 Minigames ✅" (conjunto) | `FEATURE_HARVEST.md:18-25` | ⚠️ **Conjunto errado.** O harvest lista ausculta, reflexo patelar, punção venosa, tipagem sanguínea — nenhum existe. O conjunto real é suture/clamp/bullet/BP/bandage/breathalyzer/swipe (`config_medical.lua:95-104`). |
| "6 scripts" (referências) | `ROADMAP.md:10` | ⚠️ São **7** referências (`FEATURE_HARVEST.md:3`, `REFERENCE_FEATURE_MATRIX.md:3`). |

**Recomendação R3:** corrigir `REFERENCE_FEATURE_MATRIX.md` e `FEATURE_HARVEST.md` para refletir o conjunto real de minigames e remover/qualificar a linha do monitor DUI. É erro de documento, não de código — mas é o tipo de coisa que faz a Phase 6 auditar a coisa errada.

---

## 5. Divergências de runtime

### 5.1 `TV:terminal()` sem classe — erro ao usar a opção (CRÍTICO)

`config_medical.lua:1443` chama `TV:terminal()`, porém **a classe `TV` não existe em nenhum script client/server**. `web/tv.html` (146 linhas) está pronto, `Config.TV` tem pontos (`config_medical.lua:113` + `hospitals/*.lua:33`), mas nenhum consumidor — grep `tv.html|CreateDui` só encontra o `fxmanifest.lua:101`.

- **Efeito:** selecionar a opção de TV/monitor no menu → **erro de runtime**.
- **Recomendação R4 — ✅ APLICADO (implementação completa):** classe `TV` criada em `client/tv.lua` + `server/tv.lua` (absorvida do `p_ambulancejob`), com prop `ex_prop_ex_tv_flat_01`, DUI em `web/tv.html`, sincronização via `GlobalState['loki_prescriptions/tv']`, input dialog para definir paciente/ETA e target para limpar o terminal. Entrada `emsTerminal` reativada no menu.

### 5.2 Evento quebrado no Lucas 3 (MÉDIO)

`server/lucas3.lua:42` disparava `client:useLucas3Item`, mas o client registra `client:useLucas3` (`client/lucas3.lua:21`). O handler **nunca rodava**.

- **Recomendação R5 — ✅ APLICADO:** server agora dispara `loki_prescriptions:client:useLucas3`; o handler do client passou a resolver o paciente mais próximo (raio 2.5 m) quando o evento vem do item utilizável, no mesmo padrão do `useSalineItem`. O caminho via ox_target (que já passava `targetServerId` explícito) continua funcionando.

### 5.3 Outros

- fxmanifest: todos os arquivos referenciados existem; nada fora do manifesto quebrando (tests/docs/ITEM_SETUP são extras legítimos).
- Fail-closed da Phase 0 confirmado em código.

---

## 6. Contrato de integração: loki_prescriptions ↔ vp_aicalls

### 6.1 Situação atual

**Não existe integração nenhuma hoje** — zero referência cruzada entre os dois resources (grep nos dois lados). O `vp_aicalls` é um dispatch de chamados com IA (polícia/EMS/fire) com módulo EMS descendente do SDC_MedCalls.

### 6.2 Superfícies relevantes

**vp_aicalls (EMS) — o que expõe:**

| Superfície | Detalhe | Local |
| :--- | :--- | :--- |
| Chamados EMS | `AssistanceNeeded` (P1/P2) e `HospitalTransport` (P3); timer 15–30 min; máx. 3 ativos | `config/ems.lua:17-34` |
| Vitals no checkup | `PreformCheckup` com helpers de vitals ("low/normal/high") | `config/ems.lua:47-54` |
| Maca própria | `prop_stretcher` + offsets; veículos whitelistados | `config/ems.lua:67-74` |
| Entrega hospitalar | `HospitalDropOff` com validação de raio 15 m | `server/modules/ems/server.lua:40-51`, `config/ems.lua:25-29` |
| Recompensa | `Bridge.AddMoney` por chamada (150–200) | `server/modules/ems/server.lua:26` |
| **PCR (Patient Care Report)** | Relatório de atendimento abre no **vp_tablet** (app Ambulance), com tempos, tripulação, lesões | `server/modules/ems/server.lua:53-116` |
| Admin/dispatch | `adminStartEMS`, `adminCancelOperation`, `GetActiveOperations`, dashboard | `server/modules/population.lua:635-670,985-1031` |

**loki_prescriptions — o que expõe (pontos de acoplagem):**

| Export / evento | Papel |
| :--- | :--- |
| `GetPlayerStatus`, `IsDead`, `IsLaststand`, `Revive`, `Heal`, `HealPartially` | Estado clínico do paciente (`bridge/compat_qbx_server.lua:132-142`) |
| `getPlayerTriageTag` | Tag START (`server/triage.lua:63`) |
| `isSalineActive` | Infusão corrente (`server/saline.lua:126`) |
| `GetOccupiedBeds` | Leitos ocupados (`server/hospital_beds.lua:199`) |
| `GetVpNeedsBridge`, `GetVpTabletBridge`, `GetVpPhoneBridge` | Padrão de bridge existente (`bridge/integrations/*`) |
| Eventos de minigames (`completeBPCheck`, `completeSuture`, …) | Procedimentos com resultado clínico (`server/minigames.lua:43-233`) |

### 6.3 Sobreposição (quem é dono do quê — EM ABERTO)

| Capacidade | vp_aicalls | loki_prescriptions | Trade-off |
| :--- | :--- | :--- | :--- |
| Maca / stretcher | ✅ `prop_stretcher` | ✅ `client/stretcher.lua` + `server/stretcher.lua` (eventos `p_ambulancejob/server/stretcher/*`) | Duas macas competindo por prop/estado → duplicação de sync e bugs de attach |
| Checkup / vitais | ✅ `PreformCheckup` (helpers genéricos) | ✅ pulso, temperatura, minigames de BP | Vitals do aicalls são cosméticos; os do loki são state bags com gameplay |
| Transporte ao hospital | ✅ drop-off com raio e recompensa | ⚠️ parcial (interactions putIn/takeOut) | Fluxo de missão vs fluxo clínico |
| Registro do atendimento | ✅ **PCR no vp_tablet** | ✅ prontuário/prescrição (NUI própria) | Dois relatórios paralelos sem conversa |

**Duas arquiteturas candidatas (decisão sua, pós-auditoria):**

**Opção A — loki manda no clínico**
- `vp_aicalls` fica responsável só por: gerar chamado, spawnar NPC, marcar ponto de coleta/entrega, pagar recompensa.
- Todo estado clínico (maca, vitais, lesões, triagem, PCR) é **delegado ao loki** via exports (`GetPlayerStatus`, `getPlayerTriageTag`, eventos de minigames).
- *Prós:* uma fonte de verdade clínica; reaproveita o que já está testado. *Contras:* exige que o aicalls abra mão da maca e do checkup próprios.

**Opção B — vp_aicalls manda no operacional**
- O aicalls conduz o chamado (spawn, transporte, entrega) e o loki só **injeta estado clínico** quando solicitado (checkup consulta exports do loki; PCR puxa lesões/triagem).
- *Prós:* menos invasão no aicalls. *Contras:* maca duplicada continua; risco de dois estados clínicos divergentes.

> **Posição do relatório:** sem ver os contratos de runtime dos dois lados em jogo, **não se escolhe o dono agora**. Recomenda-se a Opção A como alvo (uma fonte de verdade clínica), com a decisão formal tomada após um spike de integração.

### 6.4 Transbordo para o prontuário (superfície recomendada)

O ponto de maior valor é o **PCR do `vp_aicalls`**: quando um chamado EMS termina (coleta → hospital), o relatório já tem tempo, tripulação, tipo e lesões. Hoje ele só vai para o vp_tablet.

**Contrato proposto (EMS + transbordo):**

```
vp_aicalls (EMS)                          loki_prescriptions
─────────────────                         ──────────────────
chamado criado ─────────────────────────►  (opcional) registrar
                                           "atendimento em curso"
checkup NPC ── consulta ────────────────►  exports.GetPlayerStatus()
                                           exports.getPlayerTriageTag()
                                           exports.isSalineActive()
                                           → devolve vitais reais
PCR montado ── payload ─────────────────►  evento/callback:
                                           loki_prescriptions:server:registerCallReport
                                           { callId, callType, crew, times,
                                             injuries, triageTag, vitals }
                                           → grava no prontuário do paciente
entrega hospital ───────────────────────►  (opcional) exports.Heal /
                                           admissão em leito (GetOccupiedBeds)
```

**Regras do contrato:**
1. **Validação server-side** nos dois lados (o aicalls já tem `Config.EMS.Security` com raios/tempos — `config/ems.lua:25-29`); o loki deve exigir job + distância no `registerCallReport`, como já faz em `server/triage.lua:16-61`.
2. **Payload tipado e versionado** (chave `schema: 1`) para não travar o prontuário se o aicalls mudar o PCR.
3. **Fail-closed:** se o loki não estiver ativo, o PCR continua funcionando sozinho (fallback para vp_tablet apenas); se o aicalls não estiver ativo, o loki não perde nada.
4. **Não duplicar maca** enquanto o dono não for decidido — spike primeiro.

**Recomendação R6 (fase sugerida: nova Phase 5.5 ou item da Phase 6):** implementar o `registerCallReport` + consulta de vitais via exports, com feature-flag (`Config.Integrations.VpAiCalls`). Deixar a resolução de dono da maca para o spike.

---

## 7. Recomendações consolidadas

| ID | Ação | Fase sugerida | Prioridade | Status |
| :--- | :--- | :--- | :--- | :--- |
| R1 | Atualizar ROADMAP (Phase 4 = concluída; medbox = concluído; só DUI TV pende) | agora (doc) | Alta | ✅ Aplicado |
| R2 | Marcar SDC_MedCalls como absorvido pelo vp_aicalls no inventário | agora (doc) | Média | ✅ Aplicado |
| R3 | Corrigir REFERENCE_FEATURE_MATRIX (DUI TV) e FEATURE_HARVEST (conjunto de minigames) | agora (doc) | Alta | ✅ Aplicado |
| R4 | Implementar classe `TV`/DUI **ou** desativar `TV:terminal()` do menu | Phase 5 | **Crítica** (runtime) | ✅ **Implementado** (classe `TV` + DUI) |
| R5 | Alinhar evento `client:useLucas3` / `client:useLucas3Item` | imediato (1 linha) | **Alta** (runtime) | ✅ Aplicado |
| R6 | Contrato de integração EMS→prontuário (`registerCallReport` + exports de vitais) | Phase 5.5/6 | Média | ✅ **Aplicado** (export `RegisterCallReport` + hook no dropoff) |
| R7 | Spike de decisão: dono da maca/checkup (Opção A vs B) | antes do R6 | Média | ✅ **Decidido: Opção A** (`docs/integrations/STRETCHER_OWNERSHIP_SPIKE.md`) |

---

## 8. Limitações desta auditoria

- Verificação estática (leitura de código e docs); não houve execução em servidor FiveM.
- As referências em `F:\Nova pasta (6)\` foram conferidas por existência de caminho, não re-lidas arquivo a arquivo (o ledger já registra essa leitura).
- O módulo de polícia/fire do `vp_aicalls` ficou fora de escopo por decisão (só EMS + transbordo).
