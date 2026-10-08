# 🏥 LOKI MEDICAL SUITE v2.5.0 (Enterprise EMS & Pharmacology)

> **Suíte Médica, Hospitalar e Farmacológica Avançada para FiveM / QBox**  
> Desenvolvida com arquitetura de alta performance (**0.00ms resmon**), blindagem rigorosa contra exploits, design system moderno inspirado no **Lation UI** (Dark Glassmorphism, OLED Contrast, Emerald & Cyan Glow) e absorção completa das melhores tecnologias dos ecossistemas Wasabi, Pluto, AK47 e OSP.

---

## 🌟 Visão Geral do Sistema

O **Loki Medical Suite** transforma o atendimento pré-hospitalar e hospitalar no FiveM em uma experiência clínica profunda, dinâmica e altamente imersiva tanto para paramédicos quanto para pacientes.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LOKI MEDICAL SUITE                                │
├──────────────────┬───────────────────┬───────────────────┬──────────────────┤
│ 🩺 DIAGNÓSTICO   │ ⚡ SUPORTE À VIDA │ 💊 FARMACOLOGIA   │ 🔬 PERÍCIA & RX  │
│ • Anatomia 3D    │ • Desfibrilador   │ • Receituário     │ • Raio-X CRT     │
│ • Fraturas/Ossos │ • Lucas 3 Auto-CPR│ • Farmácias Ox    │ • Balística Wasabi│
│ • Sangramento    │ • Macas Fernocot  │ • Recargas/Vias   │ • Resíduos Pólvora│
│ • Pulso & Temp   │ • Sedação Clínica │ • Efeitos Reais   │ • Atestado Médico│
└──────────────────┴───────────────────┴───────────────────┴──────────────────┘
```

---

## 🎨 Interface Visual (Lation UI Design Language)

Todas as interfaces gráficas (NUI) foram reformuladas com o padrão de excelência visual **Lation UI**:
- **Dark Glassmorphism Profundo:** Fundos `rgba(11, 15, 25, 0.94)` com `backdrop-filter: blur(28px)`.
- **Acentos Esmeralda & Ciano:** Paleta clínica moderna (`#10b981` e `#06b6d4`) com sombras luminescentes sutis.
- **Tipografia Inter & Caveat:** Tipografia corporativa e assinaturas médicas fluidas em estilo caligráfico.
- **Raio-X com Efeito CRT:** Scanner com grade fluoroscópica, feixe de varredura animado, seletor de anatomia (Crânio, Tórax, Coluna, Braços, Pernas) e monitor OLED de sinais vitais.
- **Painel de Receituário Moderno:** Cadastro ágil de múltiplos remédios com contadores em pílula, visualizador autenticado com marca d'água de segurança e código de barras oficial.

---

## 🧩 Módulos e Recursos

### 1. 🩺 Atendimento Clínico & Diagnóstico Anatômico
- **Exame Físico Detalhado:** Permite ao socorrista inspecionar ossos fraturados, perfurações, contusões e queimaduras em tempo real.
- **Sinais Vitais:** Aferição de frequência cardíaca (BPM) e temperatura corporal com oscilação térmica de acordo com estado de choque.
- **Tratamento Específico:**
  - `bandage` / `gauze`: Hemostasia e estancamento de sangramentos.
  - `suturekit`: Sutura de lacerações profundas com animação médica.
  - `tweezers`: Extração cirúrgica de projéteis e estilhaços balísticos.
  - `burncream`: Tratamento de queimaduras térmicas e químicas.
  - `icepack` / `splint`: Imobilização de fraturas e luxações.
  - `blood_bag`: Transfusão de sangue com checagem de tipo sanguíneo e restauração de volemia.

### 2. ⚡ Suporte Avançado de Vida (SAV)
- **Desfibrilador Bifásico (AED):** Choque sincronizado com animação de descarga, sonorização tridimensional (`web/sounds/`) e recuperação de parada cardíaca.
- **Lucas 3 (Compressor Torácico Mecânico):** Prop físico implantável com animação de compressão cardíaca contínua no paciente durante o transporte na ambulância.
- **Coma Sensorial & Morte Clínica:** Sistema imersivo de perda de consciência, visão de túnel, blackout progressivo e efeitos auditivos de batimentos cardíacos esmaecendo.
- **Sedação Clínica com Seringa:** Aplicação de sedativos com animação de injeção, redução de estresse e indução de repouso forçado.
- **Nocaute Não-Letal (Knockout):** Mecânica desarmada que nocauteia brigões sem causar morte permanente, simulando concussão leve.

### 3. 🚑 Logística & Transporte de Pacientes
- **Maca Fernocot Articulada (`/maca`, `/stretcher`):**
  - Prop de alta fidelidade com animação de empurrar.
  - Acoplamento automático na traseira de ambulâncias compatíveis.
  - Pacientes podem deitar, receber oxigênio e medicação endovenosa em movimento.
- **Cadeira de Rodas & Muletas:** Auxiliares de locomoção com animação física de mancar ao sofrer fraturas graves nos membros inferiores.
- **Mochila Médica de Resgate (`medicbag`):** Acesso rápido a todos os insumos de primeiros socorros diretamente no local da ocorrência.
- **Medbox de Campo (`/medbox`):** Caixa de suprimentos portátil (`prop_medbox`) com stash temporário via `ox_inventory` para atendimento em massa em incidentes remotos.
- **Terminal de TV Hospitalar:** Painel de "paciente a caminho" (nome, idade, condição, ETA) em TVs de hospital via DUI, sincronizado para toda a equipe. Definido pelo menu médico ("Definir Terminal").
- **Triagem START (`/triagem`):** Etiquetas de cor (Verde/Amarelo/Vermelho/Preto) com marcador 3D para triagem de vítimas em massa.

### 4. 🩻 Centro de Diagnóstico por Imagem (Raio-X)
- **Máquina de Fluoroscopia / Raio-X (`/raiox`):**
  - Permite aos médicos e técnicos inspecionar chapas radiográficas do corpo do paciente.
  - Renderiza visualmente ossos fraturados, fissuras e projéteis alojados.
  - Laudo radiográfico oficial assinado pelo médico examinador.

### 5. 🔬 Necropsia, Balística Forense & Atestados
- **Perícia de Calibres Wasabi:** O sistema identifica o calibre balístico das lesões (ex: 9mm Luger, 5.56x45mm NATO, 12 Gauge, 7.62x39mm, .45 ACP, .50 AE, Taser).
- **Detecção de Resíduos de Pólvora (GSR):** Identifica se o suspeito ou vítima efetuou disparos nas últimas horas.
- **Atestado Médico Oficial (`/atestado`):** Médicos emitem atestados de dispensa de trabalho/atividade policial com prazo de validade em dias e registro no banco de dados.

### 6. 💊 Receituário Eletrônico & Farmacologia Ativa
- **Bloco de Receitas Oficial (`/receita`):** Médicos prescrevem de 1 a 4 remédios com quantidades específicas e instruções de posologia.
- **Farmácias Hospitalares Automatizadas:**
  - Validação estrita por proximidade e inventário.
  - Receitas de **Uso Contínuo** (com até 3 vias/recargas).
  - Receitas de **Retenção Obrigatória** para remédios tarja preta.
  - Faturamento depositado diretamente no cofre institucional da sociedade médica (`society_ambulance`).
- **Efeitos Farmacológicos Integrados:** Efeitos imediatos no metabolismo, alívio de estresse, proteção gástrica contra vômitos e neutralização de tosse/asfixia.

---

## 🛡️ Blindagem de Segurança & Anti-Exploit (OmniRoute Quality Gate)

Auditado com **Codex** e **Claude Sonnet 4.6**, o script possui as seguintes camadas de segurança ativas:

| Camada | Mecanismo | Proteção |
| :--- | :--- | :--- |
| **Trava Atômica de Concorrência** | `healingLocks[target]`, `activeRedeems[src]` | Impossibilita duplicação de itens ou tratamentos múltiplos por pacotes de rede simultâneos. |
| **Rate Limit / Cooldown Proporcional** | Cooldown de 1.2s entre curas; 5s entre manobras de RCP | Bloqueia spam de eventos via executores de scripts. |
| **Validação 3D + Altura Z** | `dist <= maxDist and zDiff <= 3.5` | Evita explorações de proxymity bypass em andares superiores ou subterrâneos. |
| **Fail-Closed de Inventário** | Remoção do insumo/dinheiro **antes** da concessão de saúde/cura | Se a remoção falhar, o processo é abortado imediatamente sem side effects. |
| **Sanitização de Quantidades** | Capped com `math.min(amount, Config.MaxMedsPerPrescription)` | Bloqueia injeção de inteiros gigantes ou negativos (`math.floor` + limites). |
| **Ciclo de Vida em `playerDropped`** | Limpeza de todas as tabelas de sessão no disconnect | Elimina vazamentos de memória no Garbage Collector do runtime Lua. |

---

## 🎮 Comandos & Atalhos

| Comando | Descrição | Permissão |
| :--- | :--- | :--- |
| `/receita` | Abre o bloco de receituário médico digital | Médicos / Paramédicos |
| `/raiox [id]` | Inicia exame de Raio-X do paciente | Médicos / Paramédicos |
| `/atestado` | Abre emissor de atestado médico oficial | Médicos / Paramédicos |
| `/maca` ou `/stretcher` | Spawna a maca de ambulância articulada | Médicos / Paramédicos |
| `/cpr` | Inicia manobras de massagem cardíaca | Todos / Paramédicos |
| `/checkpulse` | Mede o pulso do paciente próximo | Todos / Paramédicos |
| `/checktemp` | Mede a temperatura do paciente próximo | Todos / Paramédicos |
| `/menuems` | Abre o menu radial avançado de paramédico (`ox_lib`) | Paramédicos |

---

## 📦 Lista de Itens no `ox_inventory`

Os seguintes itens médicos devem estar registrados no arquivo `ox_inventory/data/items.lua`:

```lua
-- Itens de Primeiros Socorros e Tratamento Avançado
['sedative'] = { label = 'Seringa de Sedativo', weight = 100, stack = true, close = true },
['burncream'] = { label = 'Pomada para Queimadura', weight = 150, stack = true, close = true },
['suturekit'] = { label = 'Kit de Sutura Estéril', weight = 200, stack = true, close = true },
['tweezers'] = { label = 'Pinça Cirúrgica', weight = 80, stack = true, close = true },
['icepack'] = { label = 'Bolsa de Gelo Térmica', weight = 250, stack = true, close = true },
['blood_bag'] = { label = 'Bolsa de Sangue Total', weight = 500, stack = true, close = true },
['defib'] = { label = 'Desfibrilador Portátil AED', weight = 2500, stack = false, close = true },
['stretcher'] = { label = 'Maca Fernocot Articulada', weight = 8000, stack = false, close = true },
['crutch'] = { label = 'Muleta Ortopédica', weight = 1200, stack = false, close = true },
['wheelchair'] = { label = 'Cadeira de Rodas Hospitalar', weight = 9000, stack = false, close = true },
['medicbag'] = { label = 'Mochila de Trauma do Socorrista', weight = 1500, stack = false, close = true },
['prescription_pad'] = { label = 'Bloco de Receitas Oficiais', weight = 200, stack = false, close = true },
['prescription'] = { label = 'Receituário Médico Carimbado', weight = 50, stack = false, close = true },
['medical_certificate'] = { label = 'Atestado Médico Oficial', weight = 50, stack = false, close = true },
```

---

## 🛠️ Instalação & Setup

1. **Colocação do Resource:**
   Certifique-se de que a pasta `loki_prescriptions` está localizada dentro do seu diretório `resources/[standalone]/` ou `resources/`.
2. **Dependências Obrigatórias:**
   - `ox_lib`
   - `oxmysql`
   - `ox_inventory`
   - `qbx_core` (ou compatível com ESX/QB via bridge automática).
3. **Importação do Banco de Dados:**
   Importe as tabelas em `server/database.lua` (o script cria automaticamente na inicialização via `CREATE TABLE IF NOT EXISTS`).
4. **Inicialização no `server.cfg`:**
   ```cfg
   ensure ox_lib
   ensure ox_inventory
   ensure loki_prescriptions
   ```

---

## 📚 Documentação Técnica Completa

Para aprofundar-se em cada aspecto do ecossistema, consulte nossos manuais dedicados na pasta [`docs/`](./docs/):

| Documento | Descrição |
| :--- | :--- |
| [🏛️ **Arquitetura do Sistema**](./docs/ARCHITECTURE.md) | Diagramas de fluxo, autoridade do servidor, ciclos de vida e net events. |
| [📖 **Manual dos Módulos Clínicos**](./docs/MODULES_MANUAL.md) | Passo a passo de procedimentos (AED, Lucas 3, Raio-X, Maca Fernocot, RCP, etc.). |
| [📦 **Catálogo de Itens & Inventário**](./docs/ITEMS_AND_INVENTORY.md) | Tabela completa de pesos, stacks, propriedades e setup no `ox_inventory`. |
| [⚙️ **Guia de Configuração**](./docs/CONFIGURATION.md) | Explicação detalhada de todos os parâmetros de `config.lua` e `config_medical.lua`. |
| [🗄️ **Esquema de Banco de Dados**](./docs/DATABASE_SCHEMA.md) | Definição de tabelas, índices, queries otimizadas e persistência. |
| [🛡️ **Relatório de Auditoria de Segurança**](./docs/SECURITY_AUDIT_REPORT.md) | Análise OmniRoute (Codex + Sonnet), vetores mitigados e portão de qualidade. |
| [🧬 **Integração Farmacológica com vp_needs**](./docs/INTEGRATION_VP_NEEDS.md) | Mapeamento de efeitos metabólicos, combate a náusea/tosse e mecânica de overdose. |
| [🌐 **Integrações de Ecossistema (vp_needs & NexusOS)**](./docs/INTEGRATIONS_ECOSYSTEM.md) | Ponte fisiológica com vp_needs e app 'LSMC — Portal Clínico' no NexusOS. |

---

## 👨‍💻 Créditos e Autoria

- **Arquitetura & Engenharia:** Loki Scripts & Vinicius
- **Auditoria de Segurança:** OmniRoute Multi-Model Engine (Claude Sonnet 4.6 & Codex Auto-Review)
- **Design System:** Inspirado na excelência estética do **Lation UI**
- **Módulos Integrados:** Wasabi Ambulance, Pluto Core, AK47 & OSP Medical