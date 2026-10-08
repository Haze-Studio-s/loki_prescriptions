# 🎯 Gap Analysis de Gameplay (GAMEPLAY_GAP_ANALYSIS)

Mapeamento de lacunas de roleplay e imersão entre o estado atual e a visão final.

---

| Mecânica de RP | Estado Atual | Visão Alvo | Prioridade | Solução Projetada |
| :--- | :--- | :--- | :--- | :--- |
| **Triagem de Desastre (MCI)** | Concluído | Tags START visuais 3D | **Concluído** | `client/triage.lua` + `server/triage.lua` (`/triagem`, marcador 3D, state bag `triageTag`) |
| **Consequência ao Dirigir Ferido**| Concluído | Volante perde tração com braço quebrado | **Concluído** | `SetVehicleSteerBias` em `client/damages.lua:73-91` + stagger de perna |
| **Soro IV Físico em Campo** | Concluído na fase anterior | Bolsa de soro com hidratação e fome | **Concluído** | Módulo `client/saline.lua` integrado ao `vp_needs` |
| **Caixa de Suprimentos Portátil**| Concluído | Stash móvel no chão para incidentes remotos | **Concluído** | `client/medbox.lua` + `server/medbox.lua` (`/medbox`, stash `ox_inventory`) |
| **Laudo com Histórico CID** | Parcial (Texto livre) | Diagnósticos catalogados com CID real | **P2** | Tabela de códigos CID médicos no receituário |
