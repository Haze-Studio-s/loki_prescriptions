# 📊 Matriz Comparativa Completa de Recursos (REFERENCE_FEATURE_MATRIX)

Este documento estabelece a comparação analítica multidimensional entre o **loki_prescriptions** e as 7 referências do ecossistema médico e hospitalar FiveM.

---

## 🏛️ Matriz Geral de Funcionalidades

| Recurso / Mecânica | loki_prescriptions (Alvo) | Wasabi Ambulance | P-Ambulancejob | OSP Ambulance | AK47 Ambulance | Pluto Medical | Lation UI | SDC MedCalls | Melhor Conceito Identificado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Prontuário e Prescrições** | ✅ Nativo Avançado | ❌ Inexistente | ❌ Inexistente | ⚠️ Básico | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **loki_prescriptions** |
| **Farmacologia e Dosagens** | ✅ Sistema Multidose | ⚠️ Consumo Simples | ⚠️ Itens com Efeito | ⚠️ Supressão Temporal | ⚠️ Efeitos de Tela | ⚠️ Itens Básicos | ❌ Inexistente | ❌ Inexistente | **loki_prescriptions + OSP** |
| **Minigames Cirúrgicos (7)** | ✅ Sutura, Pinça, Projétil, Pressão, Bandagem, Bafômetro, Cartão | ❌ Apenas Skillcheck | ❌ Skillcheck Ox | ❌ Básico | ⚠️ Batimento NUI | ✅ 7 Procedimentos | ⚠️ Primitivas UI | ❌ Inexistente | **Pluto Medical (Absorvido)** |
| **Soro IV Físico (Saline)** | ✅ Implementado | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ✅ Prop Saline | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **AK47 Ambulance** |
| **Compressor Lucas 3 (RCP)** | ✅ Implementado | ❌ Inexistente | ⚠️ Prop no Stream | ❌ Inexistente | ✅ Funcional | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **AK47 Ambulance** |
| **Telemetria Pulso/Temp** | ✅ State Bags Vivos | ❌ Inexistente | ✅ State Bags | ❌ Inexistente | ❌ Inexistente | ⚠️ Estático | ❌ Inexistente | ❌ Inexistente | **P-Ambulancejob** |
| **Muleta com Walking Gait** | ✅ Lester Clipset | ❌ Limp Básico | ✅ Lester + Prop | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **P-Ambulancejob** |
| **Bloqueio de Volante (Arm)**| ✅ LockSteering | ⚠️ Tremor de Mira | ❌ Inexistente | ✅ LockSteering | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **OSP Ambulance** |
| **Gesso e Adornos no Ped**  | 🔄 Em Planejamento | ❌ Inexistente | ❌ Inexistente | ✅ Variação Roupas | ❌ Inexistente | ⚠️ Bandagem Ped | ❌ Inexistente | ❌ Inexistente | **OSP Ambulance** |
| **Triagem START (MCI Tags)** | ✅ Verde/Amarelo/Vermelho/Preto | ❌ Inexistente | ❌ Inexistente | ✅ Tags Visuais | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **OSP Ambulance** |
| **Saco Mortuário (Bodybag)** | ✅ Funcional | ❌ Inexistente | ✅ Anexo em Maca | ❌ Inexistente | ❌ Inexistente | ⚠️ Modelo 3D | ❌ Inexistente | ❌ Inexistente | **P-Ambulancejob** |
| **Monitor TV / ECG em DUI**  | ✅ TV HTML/DUI + ECG (Lifepak) | ❌ Inexistente | ✅ TV HTML/DUI | ✅ DUI Raio-X | ❌ Inexistente | ✅ Raio-X DUI | ❌ Inexistente | ❌ Inexistente | **P-Ambulancejob + Pluto** |
| **Caixa de Suprimentos Solo**| ✅ Medbox Portátil | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ✅ Prop Medbox | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **AK47 Ambulance** |
| **Maca com Raycast Físico**  | ✅ Raycast LosProbe | ✅ Raycast Nativo | ⚠️ Spawn Livre | ⚠️ Spawn Livre | ⚠️ Spawn Livre | ⚠️ Spawn Livre | ❌ Inexistente | ❌ Inexistente | **Wasabi Ambulance** |
| **Nocaute Melee & Concussão**| ✅ Bloom Shader | ✅ Bloom Shader | ❌ Inexistente | ❌ Inexistente | ⚠️ Básico | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | **Wasabi Ambulance** |
| **Design System Glassmorphism**| ✅ Lation Slate Dark | ❌ CSS Legado | ⚠️ Mantine Clean | ⚠️ CSS Padrão | ❌ CSS Legado | ⚠️ CSS Clássico | ✅ Glassmorphism Puro | ❌ Inexistente | **Lation UI** |
| **Chamadas Procedurais NPC** | 🔄 Módulo Integrável | ❌ Inexistente | ❌ Inexistente | ❌ Inexistente | ⚠️ IA Simples | ❌ Inexistente | ❌ Inexistente | ✅ Sistema Completo | **SDC MedCalls** |

---

## 🔍 Análise Comparativa Detalhada por Eixo

### Eixo 1: Autoridade e Segurança de Rede
* **Vencedor Técnico:** `loki_prescriptions` + `P-Ambulancejob`.
* **Motivo:** Utilização do padrão Server-Authoritative para transações de itens e dinâmicas de morte, eliminando NetEvents vulneráveis a injeção via exploiters que infestavam scripts legados como AK47.

### Eixo 2: Profundidade Cirúrgica e Imersão Clínica
* **Vencedor Técnico:** `Pluto Medical` (Absorvido pelo `loki_prescriptions`).
* **Motivo:** A introdução de simulações físicas vetoriais (curvas Bézier e colisões 2D em tempo real) substitui completamente os cliques repetitivos e traz realismo de alta complexidade ao Heavy RP.

### Eixo 3: Ergonomia e Estética (UI/UX)
* **Vencedor Técnico:** `Lation UI` (Adotado como padrão visual do `loki_prescriptions`).
* **Motivo:** Elimina layouts genéricos, adotando transparências sutis de vidro escuro, tipografia JetBrains Mono / Inter e feedback sonoro háptico imediato.
