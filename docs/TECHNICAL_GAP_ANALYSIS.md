# ⚙️ Gap Analysis Técnico (TECHNICAL_GAP_ANALYSIS)

Classificação por criticidade técnica de todos os subsistemas pendentes de refinamento.

---

### P0 — Crítico / Obrigatório
* **[RESOLVIDO] Validação Sintática 100%:** Todos os 79 arquivos Lua compilam com saída 0 em `luac.exe -p`.
* **[RESOLVIDO] Autoridade Server-Side:** Remoção de eventos com client authority no consumo de remédios.

### P1 — Importante / Core Gameplay
* **[RESOLVIDO] Módulo de Fraturas Ósseas Integrado:** Travamento de volante (`SetVehicleSteerBias` em `client/damages.lua:73-91`) e tropeço de perna (`CauseFractureStaggering`, mesmas linhas).
* **[RESOLVIDO] MCI START Triage Tags:** `client/triage.lua` + `server/triage.lua` com tags GREEN/YELLOW/RED/BLACK, marcador 3D e state bag `triageTag`.
* **[RESOLVIDO] Caixa de Suprimentos Portátil (`prop_medbox`):** `client/medbox.lua` + `server/medbox.lua` com stash `ox_inventory` (comando `/medbox`).

### P2 — Melhoria Relevante
* **Conexão Dinâmica dos Minigames com State Bags:** Ajustar a frequência cardíaca audível no estetoscópio para bater no ritmo exato do `LocalPlayer.state.pulse`.
