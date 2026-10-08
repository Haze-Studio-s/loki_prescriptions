# 🌾 Catálogo Geral de Funcionalidades Colhidas (FEATURE_HARVEST)

Classificação sistemática de todas as funcionalidades de alto valor identificadas na engenharia reversa das 7 referências.

---

### 1. CORE
* **Prontuário Médico Digital com CRM Único:** Registro eletrônico imutável de diagnósticos, receitas emitidas e histórico de cirurgias do paciente.
* **Farmácia Hospitalar e Comercial:** Sistema de dispensação com retenção automática de receita para tarjas pretas/vermelhas e limite de dosagem.
* **Sistema de Diagnóstico Anátomo-Topográfico:** Identificação milimétrica do membro ferido (cabeça, tórax, braço esquerdo/direito, perna esquerda/direita) mapeado no modelo esquelético.

### 2. HEAVY RP
* **Laudos e Atestados Médicos com Assinatura Digital:** Emissão de licenças de trabalho com carimbo oficial do hospital, prazo em dias e CID.
* **Análise Toxicológica e Triagem de Dependência:** Verificação laboratorial de dosagens de álcool no sangue (BAC), saturação de drogas e níveis de dependência química.
* **Incapacitação Motora e Muletas Físicas:** Pacientes com tíbia fraturada precisam usar muleta física com o walking style Lester (`move_heist_lester`).

### 3. IMMERSION
* **7 Minigames de Alta Fidelidade Anatômica (Pluto) — conceitos colhidos:**
  * ✅ Esfigmomanômetro com insuflação da braçadeira e leitura de pressão sistólica/diastólica. (`bp`)
  * ❌ Ausculta com estetoscópio posicionável em 5 pontos com áudio de estridor/sibilos. *(não implementado)*
  * ❌ Reflexo patelar com martelo neurológico. *(não implementado)*
  * ❌ Punção venosa com cateter e refluxo de sangue ("flashback"). *(não implementado)*
  * ✅ Sutura vascular de colchoeiro para hemostasia. (`suture`)
  * ✅ Extração de projétil por pinça cirúrgica com colisão anatômica 2D. (`bullet`)
  * ❌ Tipagem sanguínea com lâmina de reação de aglutinação Anti-A/B/Rh. *(não implementado)*
* **Conjunto efetivamente implementado em `Config.InteractiveMinigames` (`config_medical.lua:95-104`):** suture, clamp (hemostasia), bullet, bp, bandage (curativo em 3 etapas), breathalyzer (bafômetro) e swipeCard (leitor magnético). *(corrige a divergência anterior entre este catálogo e o código)*
* **Monitor Cardíaco em Televisão de Quarto (DUI):** ECG dinâmico sincronizado em tempo real na tela do hospital. *(implementado: ECG do Lifepak via `web/ecg.html` e TV de paciente a caminho via `web/tv.html` + `client/tv.lua`)*

### 4. PROGRESSION
* **Especialização Cirúrgica & Médica:** Registro de histórico de atendimentos bem-sucedidos no banco de dados, habilitando promoções no departamento hospitalar.
* **Condecorações de Serviço:** Medalhas oficiais por salvamentos de vida (Star of Life, Lifesaving Award).

### 5. ECONOMY
* **Sistema de Seguros de Saúde:** Planos de saúde com débito automático no banco e desconto nas consultas e na compra de medicamentos.
* **Recompensa Variável por Procedimento:** Payouts calculados com base na complexidade do trauma tratado (queimadura, tiro, facada, fratura).

### 6. SOCIAL
* **Interação Paramédico-Paciente em Transporte:** Macas articuladas e cadeiras de rodas empurradas em sincronia, com acompanhamento de familiares no leito.
* **Triagem de Vítimas em Massa (START Triage):** Identificação visual com tags coloridas para triagem rápida em acidentes com múltiplos feridos.

### 7. POLICE / GOVERNMENT
* **Autópsia Forense de Cadáveres:** Extração de projéteis com estriamento balístico para cruzamento de calibre pela perícia policial.
* **Atestados para Tribunal e Emprego:** Comprovação documental de incapacidade civil em processos judiciais e perícias da prefeitura.

### 8. ILLEGAL
* **Desvio de Opiáceos e Falsificação de Receituários:** Risco e recompensa para roubo de blocos de receita médica ou adulteração de CRM.
* **Atendimento Clandestino / Clínicas de Fachada:** Check-ins informais para tratamento de criminosos procurados sem notificação à polícia.

### 9. ADMIN
* **Painel de Auditoria e Logs de Combate:** Registro instantâneo de quem feriu quem, arma utilizada, dano e tratamento aplicado via Discord Webhooks.
* **Comandos de Suporte e Ressuscitação Cirúrgica:** Ferramentas de cura administrativa com verificação de permissões.

### 10. SECURITY
* **Transações Fail-Closed:** Dedução estrita de itens ou pagamento financeiro antes de qualquer aplicação de efeito benéfico.
* **Verificação de Distância Server-Side:** Impossibilidade de exploiters reviverem ou medicarem jogadores a distâncias anormais.

### 11. RELIABILITY
* **Idempotência de Tratamento e Locks Temporais:** Liberação segura de travas de animação caso o jogador caia ou desconecte durante o minigame.
* **Watchdogs de Prop:** Recriação automática de muletas e macas caso o motor gráfico do jogo faça culling da entidade.

### 12. UX
* **Interface Glassmorphism Lation Dark Slate:** Painéis elegantes, ausência de poluição visual, contraste equilibrado e legibilidade de prontuários.
* **Áudio Háptico e Espacial:** Feedback sonoro imediato em cada clique, batimento cardíaco 3D audível ao redor do paciente.

### 13. PERFORMANCE
* **Zero Loops Bloqueantes no Cliente:** Substituição de threads ativas por State Bags reativos (`LocalPlayer.state`).
* **Pooling de Entidades e Cleanup Rigoroso:** Destruição completa de props em `onResourceStop` e `playerDropped`.
