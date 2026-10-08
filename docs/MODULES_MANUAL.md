# 📖 Manual Operacional dos Módulos Clínicos - Loki Medical Suite

Guia completo de procedimentos médicos, operação de equipamentos e comandos para socorristas, médicos e administradores.

---

## 📑 Índice
1. [Exame Físico & Tratamento de Ferimentos](#1-exame-físico--tratamento-de-ferimentos)
2. [Suporte Avançado de Vida (AED, Lucas 3 & RCP)](#2-suporte-avançado-de-vida-aed-lucas-3--rcp)
3. [Radiologia & Diagnóstico por Imagem (Raio-X)](#3-radiologia--diagnóstico-por-imagem-raio-x)
4. [Receituário Eletrônico & Farmácias](#4-receituário-eletrônico--farmácias)
5. [Transporte & Maca de Ambulância Fernocot](#5-transporte--maca-de-ambulância-fernocot)
6. [Sedação Clínica & Nocaute Não-Letal](#6-sedação-clínica--nocaute-não-letal)
7. [Perícia Balística & Atestados Médicos](#7-perícia-balística--atestados-médicos)
8. [Menu Radial de Emergência (`ox_lib`)](#8-menu-radial-de-emergência-ox_lib)
9. [Terminal de TV & Medbox de Campo](#9-terminal-de-tv--medbox-de-campo)

---

## 1. Exame Físico & Tratamento de Ferimentos

### Procedimento Clínico
1. Aproxime-se do paciente deitado ou ferido.
2. Acesse o menu de tratamento mirando no paciente (`ox_target`) ou utilizando o comando `/diagnostico [id]`.
3. A interface Lation UI exibirá o mapa de ossos e ferimentos do paciente com cores indicativas (Verde = Íntegro, Amarelo = Lesão Leve, Vermelho = Fratura/Trauma Grave).
4. Utilize a ação correspondente no menu de ações rápidas:
   - **Aferir Pulso (`/checkpulse`):** Informa os Batimentos por Minuto (BPM).
   - **Aferir Temperatura (`/checktemp`):** Mede a temperatura corporal (indicando hipotermia em choque hipovolêmico ou febre).

### Protocolo de Insumos Médicos
- **`bandage` / `gauze`:** Aplica compressão e estanca hemorragias ativas.
- **`tweezers` (Pinça Cirúrgica):** Realiza a remoção de projéteis alojados no músculo ou osso antes da sutura.
- **`suturekit`:** Sutura lacerações abertas, impedindo reabertura de sangramento ao correr.
- **`burncream`:** Alivia queimaduras de 1º a 3º grau causadas por fogo ou produtos químicos.
- **`icepack` / `splint`:** Imobiliza membros com fratura óssea, permitindo que o paciente volte a andar sem mancar.
- **`blood_bag`:** Transfusão intravenosa que restaura o volume intravascular e recupera a pressão arterial do paciente.

---

## 2. Suporte Avançado de Vida (AED, Lucas 3 & RCP)

### Desfibrilador Portátil (AED)
- **Item Requerido:** `defib`
- **Uso:** Utilizável pelo inventário mirando no paciente em parada cardíaca.
- **Operação:** O aparelho executa a análise de ritmo e instrui os socorristas a se afastarem ("Clear!"). O choque é desferido com som sincronizado e animação física de espasmo muscular.

### Compressor Torácico Mecânico (Lucas 3)
- **Comando:** `/lucas3 [id]` ou mira `ox_target`.
- **Operação:** Um suporte mecânico é fixado ao tórax do paciente desacordado, realizando compressões cardíacas automáticas e contínuas enquanto a equipe prepara o transporte ou dirige a viatura.
- **Desativação:** Mirar novamente no aparelho e selecionar "Remover Lucas 3".

### Reanimação Cardiopulmonar Manual (RCP)
- **Comando:** `/cpr [id]`
- **Regra de Cooldown:** Cooldown de 5 segundos no servidor para impedir abusos. O socorrista executa ciclos de 30 compressões com animação médica.

---

## 3. Radiologia & Diagnóstico por Imagem (Raio-X)

### Como Realizar o Exame
1. Conduza o paciente até a sala de radiologia de qualquer hospital configurado (Los Santos Medical Center, Pillbox, Sandy Shores, Paleto).
2. Posicione o paciente na maca de exame.
3. O médico ou técnico digita `/raiox [id]` ou clica na maca de raio-x via `ox_target`.
4. A tela CRT fluoroscópica do **Lation UI** será carregada:
   - Navegue pelos seletores anatômicos: **Crânio, Tórax, Coluna, Braço Esquerdo, Braço Direito, Perna Esquerda, Perna Direita**.
   - O feixe de varredura laser inspeciona a densidade óssea.
   - Ossos fraturados ou fissurados aparecem destacados em tom avermelhado com laudo descritivo.

---

## 4. Receituário Eletrônico & Farmácias

### Prescrevendo Medicamentos
1. O médico deve portar o item `prescription_pad` (Bloco de Receitas).
2. Utilize o item pelo inventário ou digite `/receita` com o paciente ao lado.
3. Preencha o nome do paciente, ID cívico, endereço e posologia.
4. Adicione de 1 a 4 remédios configurados e defina as quantidades (ex: `2x Paracetamol`, `1x Amoxicilina`).
5. Digite seu nome no campo de assinatura digital (gerando uma assinatura caligráfica em tempo real).
6. Clique em **Emitir Receituário**. A receita carimbada (`prescription`) será entregue diretamente no bolso do paciente.

### Retirada na Farmácia
1. O paciente dirige-se a qualquer balcão de farmácia hospitalar.
2. Interage no ponto marcado com a receita em mãos.
3. Se for remédio de **Uso Contínuo**, o farmacêutico carimba a via e desconta uma recarga (ex: de 3/3 para 2/3).
4. Se for de **Retenção Obrigatória** (tarja preta), a receita é recolhida e arquivada pelo sistema.
5. O valor pago pelos remédios é depositado automaticamente no cofre institucional do hospital.

---

## 5. Transporte & Maca de Ambulância Fernocot

### Operação da Maca
- **Spawnar Maca:** Digite `/maca` ou `/stretcher`.
- **Empurrar Maca:** Aproxime-se e pressione a tecla de interação para segurar as alças da maca.
- **Deitar Paciente:** O paciente olha para a maca e escolhe "Deitar na Maca".
- **Colocar na Ambulância:** Empurre a maca até a porta traseira de qualquer ambulância (`ambulance`). O sistema detectará o porta-malas e acoplará a maca suavemente no interior do veículo.
- **Retirar da Ambulância:** Interaja na traseira da ambulância para desacoplar a maca de volta ao solo.

---

## 6. Sedação Clínica & Nocaute Não-Letal

### Sedativo Injetável
- **Item Requerido:** `sedative`
- **Operação:** O médico aplica a seringa de sedativo diretamente no paciente agitado ou em surto psicótico.
- **Efeito:** Uma animação de injeção é tocada, seguida de visão embaçada suave e sonolência temporária, reduzindo instantaneamente o estresse para níveis seguros.

### Nocaute Desarmado (Knockout)
- Brigas de socos desarmadas monitoram os danos no crânio do jogador.
- Ao atingir o limiar de trauma encefálico leve, o agredido cai momentaneamente em estado de nocaute (ragdoll por 15 segundos) sem sofrer morte mecânica, simulando uma perda de consciência por concussão esportiva.

---

## 7. Perícia Balística & Atestados Médicos

### Perícia de Calibres & GSR
- Médicos e legistas podem examinar o corpo de vítimas para determinar:
  - Tipo de projétil que causou a lesão (9mm, 5.56mm NATO, 12 Gauge, etc.).
  - Distância estimada do disparo (à queima-roupa ou longa distância).
  - Teste de Pólvora nas Mãos (GSR): Identifica se a pessoa realizou disparos nas últimas 2 horas reais.

### Atestado Médico de Afastamento
- **Comando:** `/atestado [id] [dias] [motivo]`
- **Exemplo:** `/atestado 12 3 "Fratura na tíbia esquerda pós-acidente"`
- O documento é registrado no banco de dados com validade em dias reais, comprovando afastamento oficial do trabalho para polícias e empregadores.

---

## 8. Menu Radial de Emergência (`ox_lib`)

Os socorristas contam com atalhos rápidos pelo menu radial do `ox_lib`:
- Pressione a tecla do radial (ou digite `/menuems`) para acessar:
  - 🩺 **Diagnóstico do Paciente**
  - ⚡ **Desfibrilador AED**
  - 🩹 **Curativo Rápido**
  - 🚑 **Maca Fernocot**
  - 📜 **Bloco de Receitas**
  - 🩻 **Solicitar Raio-X**

---

## 9. Terminal de TV & Medbox de Campo

### Terminal de TV Hospitalar ("Paciente a Caminho")
- **Acesso:** Menu médico → **Definir Terminal**.
- **Operação:** O socorrista seleciona a TV do hospital, informa nome, idade, gênero, condição (Estável/Crítico) e ETA em minutos. O painel em **todas as TVs daquele hospital** exibe "PACIENTE A CAMINHO!" com os dados, sincronizado em tempo real para toda a equipe.
- **Limpar:** Mire na TV (`ox_target`) e selecione **Limpar Terminal** para voltar ao estado ocioso.
- **Técnico:** Prop `ex_prop_ex_tv_flat_01` com DUI (`web/tv.html`) aplicado na textura da tela; estado replicado via `GlobalState['loki_prescriptions/tv']`. Os pontos de TV vêm de `hospitals/*.lua` (`Config.TV`).

### Medbox de Campo
- **Comando:** `/medbox`
- **Operação:** Posiciona uma caixa de suprimentos (`prop_medbox`) no chão, com stash `ox_inventory` de 25 slots para atendimento em massa. Pode ser recolhida por interação (`ox_target`).
- **Uso típico:** Incidentes remotos, desastres (com a Triagem START) e postos de atendimento improvisados.
