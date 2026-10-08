# 🌐 Integrações de Ecossistema: vp_needs & NexusOS

O **Loki Medical Suite v2.5.0** foi projetado para interoperabilidade nativa com os dois maiores pilares de gameplay da base: o motor fisiológico/metabólico **`vp_needs`** e o sistema operacional unificado **`nexus_os`**.

---

## 🧬 1. Integração Fisiológica & Metabólica com `vp_needs`

A integração clínica com o [`vp_needs`](../vp_needs) atua diretamente nos estados biológicos do jogador, permitindo que tratamentos hospitalares e medicamentos alterem condições reais de saúde e dependência.

### Ações & Efeitos Automáticos

```mermaid
graph LR
    subgraph Loki ["Loki Medical Suite"]
        Pill[Medicamentos Controlados]
        Syr[Seringa de Sedativo]
        Blood[Bolsa de Sangue]
        ToxCmd[/vertoxicologia]
    end

    subgraph VP ["vp_needs Engine"]
        Stress[Estresse & Ansiedade]
        Addict[Dependência Química]
        Sick[Enfermidade / Sickness]
        StateBag[StateBag: toxicity / bac / isOverdosing]
    end

    Pill -->|RelieveStress / AdjustNeed| Stress
    Pill -->|TreatAddiction| Addict
    Pill -->|AdjustNeed 'sickness'| Sick
    Syr -->|Sedação Profunda -70 Estresse| Stress
    Blood -->|Restauração de Volemia / Thirst| VP
    ToxCmd -->|Leitura de Estado| StateBag
```

### 1.1 Farmacologia Integrada (`Config.Medicine`)
- **Alívio de Estresse:** Medicamentos como Paracetamol, Ibuprofeno e Alprazolam (`med_xanax`) disparam `exports.vp_needs:RelieveStress()`, reduzindo a barra de estresse e neutralizando tremores de mira.
- **Tratamento de Doenças:** Antibióticos (Amoxicilina) e antivirais curam infecções ativas (`exports.vp_needs:AdjustNeed(src, 'sickness', -amount)`).
- **Tratamento de Vícios:** Medicamentos controlados de desmame auxiliam no tratamento gradual de dependências químicas (`exports.vp_needs:TreatAddiction()`).
- **Supressão de Sintomas:** Medicamentos específicos interrompem crises de asfixia/tosse do módulo `consumption_choking` e neutralizam enjoo e vômitos gástricos.

### 1.2 Sedativo Clínico Injetável (`sedative`)
- Ao aplicar a seringa de sedativo no paciente agitado ou em surto psicótico, o script aciona `VpNeedsBridge.ApplySedation(target)`, reduzindo **70 pontos de estresse** de forma imediata e interrompendo crises de abstinência severa.

### 1.3 Hemoterapia & Choque Hipovolêmico (`blood_bag`)
- Transfusões de sangue realizadas por socorristas restauram a volemia sanguínea e recuperam parâmetros críticos de hidratação e pressão arterial no `vp_needs`.

### 1.4 Exame Toxicológico & Triagem de Overdose
- Médicos e socorristas contam com o comando `/vertoxicologia [id]`:
  - Lê em tempo real as propriedades de StateBag do `vp_needs`:
    - `toxicity`: Nível de intoxicação por substâncias ilícitas (0 a 100%).
    - `bac`: Alcoolemia no sangue em g/L.
    - `isOverdosing`: Se o paciente está em estado de colapso respiratório/cardíaco por overdose.
  - Se detectada overdose, o sistema alerta o médico com prioridade para realização de lavagem gástrica (`/stomachpump`) ou administração de Naloxona.

---

## 🖥️ 2. Integração Operacional com `NexusOS`

O **NexusOS** (`nexus_os`) é o sistema operacional presente nos computadores e notebooks portáteis do servidor. O **Loki Medical Suite** conecta-se a ele em duas frentes fundamentais:

```mermaid
graph TD
    subgraph Nexus ["NexusOS Ecosystem"]
        Store[Nexus App Store]
        Desktop[Área de Trabalho & Dock]
        PhoneBridge[DeviceBridge: SendPhoneNotification]
    end

    subgraph LokiApp ["App Oficial: LSMC — Portal Clínico"]
        RxEmit[Emissão de Receitas]
        CertEmit[Atestados Médicos]
        XrayReq[Exames de Raio-X]
        StretcherReq[Maca Fernocot]
    end

    subgraph PatientDevice ["Smartphone do Paciente"]
        PushNotif[Notificação Push na Lockscreen]
    end

    Store --> Desktop
    Desktop -->|Acesso por Médicos| LokiApp
    RxEmit -->|Push Notification| PhoneBridge
    CertEmit -->|Push Notification| PhoneBridge
    PhoneBridge -->|Alerta em Tempo Real| PatientDevice
```

### 2.1 Aplicativo Oficial "LSMC — Portal Clínico"
- Registrado automaticamente na **App Store**, no **Desktop** e na barra de tarefas do NexusOS via `exports['nexus_os']:RegisterApp()`.
- **Restrição de Acesso:** Exclusivo para funcionários do departamento de emergência médica (`ambulance`, `doctor`).
- **Recursos Disponíveis no App:**
  1. 📝 **Bloco de Receituário Médico:** Abre a interface digital Lation UI com prancheta de emissão rápida de medicamentos controlados.
  2. 📜 **Emissão de Atestado Médico:** Homologação de licença médica e atestado de dispensa laboral.
  3. 🩻 **Centro Radiográfico:** Inicialização de exame fluoroscópico por Raio-X com feixe CRT.
  4. 🔬 **Avaliação Toxicológica:** Aferição de substâncias e alcoolemia integrada ao `vp_needs`.
  5. 🚑 **Logística Pré-Hospitalar:** Requisitar ou recolher maca Fernocot.

### 2.2 Notificações Push no Smartphone do Cidadão
Quando um procedimento é homologado, o servidor aciona `NexusBridge.SendNotification()` que despacha notificações push diretamente para o celular do paciente:
- **Receita Emitida:** O paciente recebe no celular o alerta *"LSMC Farmácia: Nova receita emitida pelo Dr(a). [Nome do Médico]. Retire seus medicamentos em qualquer unidade."*
- **Atestado Homologado:** O paciente recebe *"LSMC Departamento Médico: Seu atestado médico de X dia(s) foi homologado."*
- Caso o smartphone do jogador não esteja com o aplicativo aberto, o sistema converte automaticamente o alerta em notificação flutuante de alta prioridade via `ox_lib`.

---

## 📱 3. Integração com `vp_phone` (Smartphone dos Cidadãos)

O [`vp_phone`](../vp_phone) é o smartphone padrão de todos os jogadores. O **Loki Medical Suite** despacha eventos nativos diretamente no ecossistema de apps do telefone:

### 3.1 Notificações no App "Saúde" (Health)
- **Receitas Médicas:** Ao emitir um receituário, o paciente recebe um aviso oficial com remetente *"LSMC Farmácia"* detalhando o médico prescritor e orientando a retirada no balcão.
- **Atestados Médicos:** Ao receber dispensa laboral, o paciente é notificado em tempo real com os dias homologados e validade do documento.
- **Alertas de Emergência:** Caso um paciente seja resgatado ou estabilizado, o sistema pode despachar avisos prioritários na tela de bloqueio do celular via `VpPhoneBridge.SendNotification()`.

---

## 📟 4. Integração com `vp_tablet` (MDT de Paramédicos & Despacho 10-47)

O [`vp_tablet`](../vp_tablet) atua como a central tática de despacho e prontuário médico eletrônico dos socorristas:

### 4.1 Despacho Tático de Emergência (Código 10-47)
- Quando um paciente entra em estado crítico de coma sensorial, parada cardiorrespiratória ou quando manobras de RCP/Desfibrilador falham, o script executa:
  ```lua
  VpTabletBridge.CreateDispatch('Parada Cardíaca / Emergência Médica', 'Vítima inconsciente com instabilidade hemodinâmica.', coords, '10-47')
  ```
- O chamado cria um **blip sonoro e visual em tempo real** nos tablets de todas as viaturas de ambulância em patrulha.

### 4.2 Prontuário Médico Automático (`lbtablet_ambulance_reports`)
- Toda receita médica emitida e todo atestado médico homologado no **Loki Medical Suite** são registrados automaticamente no histórico clínico do paciente no tablet dos socorristas, garantindo auditoria e continuidade do atendimento hospitalar.

### 4.3 Aplicativo Nativo "LSMC Receituário" no Tablet
- O app vem pré-instalado na grade de serviços do tablet de socorristas (`defaultApp = true`), permitindo consultas e prescrições diretamente pelo dispositivo móvel.

---

## 📟 5. Integração de Chamados EMS com `vp_aicalls`

O [`vp_aicalls`](../vp_aicalls) gera chamados médicos com IA (pacientes NPC, transporte inter-hospitalar). A divisão de responsabilidades segue a decisão do spike (`docs/integrations/STRETCHER_OWNERSHIP_SPIKE.md`): **o `vp_aicalls` é dono do operacional do chamado; o Loki é dono do estado clínico**.

### 5.1 Registro de Atendimento (`RegisterCallReport`)
- Quando um chamado EMS termina no dropoff do hospital, o `vp_aicalls` chama `exports.loki_prescriptions:RegisterCallReport(...)`.
- O Loki valida o job do socorrista, registra o atendimento (callId, tipo, prioridade, detalhes do paciente, tempos, tripulação) e notifica a equipe.
- Consultas: `exports.loki_prescriptions:GetCallReports()` / `GetCallReport(callId)`.
- **Fail-closed nos dois sentidos:** se o Loki estiver parado, o PCR do tablet segue sozinho; se o `vp_aicalls` estiver parado, o Loki não perde nada.

### 5.2 Macas
- As duas macas coexistem por domínio: a do Loki (`strykergurney`, server-authoritative) é para **jogadores reais**; a do `vp_aicalls` (`prop_stretcher`, local/cosmética) é para **NPCs de missão**. Elas não disputam o mesmo paciente.

---

## 🔧 Como Testar e Validar as Integrações em Jogo

1. **Teste de Farmacologia (`vp_needs`):**
   - Consuma um medicamento (`med_paracetamol` ou `med_xanax`).
   - Observe a barra de estresse diminuir e os batimentos cardíacos estabilizarem.
2. **Teste de Toxicologia (`vp_needs`):**
   - Com um paciente próximo que ingeriu álcool ou substâncias, digite `/vertoxicologia [id]`.
   - O laudo exibirá os níveis de `toxicity`, `bac` e indicador de overdose.
3. **Teste no NexusOS (`nexus_os`):**
   - Abra um notebook portátil (`laptop`) ou computador de mesa em um hospital.
   - Abra a **App Store** ou localize o ícone **LSMC — Portal Clínico** no Desktop.
   - Clique para abrir a central de ações do corpo médico.
4. **Teste no Smartphone (`vp_phone`):**
   - Emita uma receita mirando em um jogador. Verifique a notificação push surgindo no aplicativo de Saúde do celular do paciente.
5. **Teste no MDT (`vp_tablet`):**
   - Abra o tablet policial/médico (`/tablet` ou item `tablet`).
   - Verifique o histórico de relatórios atualizado em tempo real e os chamados 10-47 de emergência médica.
6. **Teste de Chamado EMS (`vp_aicalls`):**
   - Complete um chamado médico (checkup → maca → entrega no hospital).
   - Os socorristas envolvidos recebem a notificação "Atendimento registrado no prontuário clínico."
   - Confirme com `exports.loki_prescriptions:GetCallReports()` no console do servidor.

