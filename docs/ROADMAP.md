# 🗺️ Roadmap Estratégico de Engenharia (ROADMAP)

Fases de evolução e prontidão para produção do **loki_prescriptions**.

---

* **PHASE 0: Estabilização Crítica & Conformidade** [CONCLUÍDO]
  * Resolução de todas as falhas sintáticas, verificação via `luac.exe -p` e fail-closed em remoção de itens.
* **PHASE 1: Arquitetura e Absorção de Referências** [CONCLUÍDO]
  * Engenharia reversa completa dos 7 scripts de referência e documentação em `docs/`.
* **PHASE 2: Minigames Anatômicos & UI Moderna** [CONCLUÍDO]
  * Integração dos 7 procedimentos do Pluto com o design Lation Dark Slate.
* **PHASE 3: Suporte Avançado de Vida (Soro & Lucas 3)** [CONCLUÍDO]
  * Implementação da bolsa de soro com `vp_needs` e compressor torácico Lucas 3.
* **PHASE 4: Traumatologia Dinâmica & Triagem START** [CONCLUÍDO]
  * Travamento de volante por braço fraturado (`client/damages.lua`) e etiquetas de triagem START (`client/triage.lua` + `server/triage.lua`).
* **PHASE 5: Caixa de Suprimentos Móvel & DUI Monitor** [CONCLUÍDO]
  * Stash de campo: medbox com stash ox_inventory (`client/medbox.lua`, `server/medbox.lua`).
  * Monitor em televisores de leito: classe `TV` com DUI (`client/tv.lua`, `server/tv.lua`, `web/tv.html`).
* **PHASE 6: Hardening, Testes Concorrentes & Release** [FINAL]
  * Auditoria adversarial red-team e verificação final.
