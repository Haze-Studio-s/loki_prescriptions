# ⚙️ Guia Completo de Configuração - Loki Medical Suite

Este documento descreve detalhadamente cada parâmetro existente nos arquivos de configuração do script: [`config.lua`](../config.lua) e [`config_medical.lua`](../config_medical.lua).

---

## 📄 1. Configurações Gerais e Farmacológicas (`config.lua`)

| Parâmetro | Tipo | Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `Config.Framework` | `string` | `'auto'` | Framework da base (`'qbx'`, `'esx'`, `'qb'` ou `'auto'` para detecção automática via bridge). |
| `Config.Notification` | `string` | `'lib'` | Sistema de notificação (`'lib'` para `ox_lib:notify`, `'qb'`, `'esx'`, `'okoknotify'`, `'wasabi_notify'`). |
| `Config.PrescriptionJobs` | `table` | `{'ambulance', 'doctor'}` | Lista de profissões (jobs) autorizadas a assinar receituários e emitir atestados. |
| `Config.PrescriptionPadItem` | `string` | `'prescription_pad'` | Nome do item do bloco de receitas que o médico precisa ter na mochila. |
| `Config.PrescriptionItem` | `string` | `'prescription'` | Nome do item da receita emitida gerada para o paciente. |
| `Config.MaxDifferentMeds` | `number` | `4` | Limite máximo de medicamentos distintos por receituário médico. |
| `Config.MaxMedsPerPrescription` | `number` | `5` | Quantidade máxima de unidades de cada remédio permitido na receita. |
| `Config.PrescriptionExpireDays`| `number` | `3` | Tempo em dias reais para a receita expirar e não ser mais aceita nas farmácias. |
| `Config.Insurance` | `table` | `{ enabled = true, duration = 30, cost = 500 }` | Configuração do convênio médico/plano de saúde (dias de validade e custo). |
| `Config.SocietyAccount` | `string` | `'society_ambulance'` | Conta institucional do hospital no `Renewed-Banking` que recebe os pagamentos da farmácia. |

### Configuração de Farmácias (`Config.Pharmacies`)
Define os pontos físicos com coordenadas `vector3`, raio de alcance `lib.points` e horário de funcionamento:
```lua
Config.Pharmacies = {
    [1] = {
        name = "Farmácia Central LSMC",
        coords = vector3(311.5, -593.2, 43.2),
        heading = 340.0,
        blip = { enabled = true, sprite = 51, color = 2, scale = 0.7 }
    }
}
```

---

## 🏥 2. Configurações Clínicas & Suporte de Vida (`config_medical.lua`)

| Parâmetro | Tipo | Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `ConfigMedical.Bleeding` | `boolean` | `true` | Ativa a mecânica de hemorragia progressiva que drena vida gradualmente. |
| `ConfigMedical.BonesDamage` | `boolean` | `true` | Ativa o rastreamento anatômico de fraturas nos ossos e membros. |
| `ConfigMedical.LimpingEffect` | `boolean` | `true` | Força animação de mancar quando pernas ou pés sofrem dano grave. |
| `ConfigMedical.BlackoutEffect` | `boolean` | `true` | Ativa o efeito de túnel escuro e desmaio ao perder grande quantidade de sangue. |
| `ConfigMedical.HealCooldown` | `number` | `1200` | Cooldown mínimo do servidor (em milissegundos) entre ações consecutivas de cura. |
| `ConfigMedical.CPRSuccessRate` | `number` | `45` | Porcentagem base de sucesso da manobra de reanimação manual (RCP). |
| `ConfigMedical.DefibSuccessRate`| `number` | `85` | Porcentagem base de sucesso do choque do desfibrilador AED. |
| `ConfigMedical.SedativeDuration`| `number` | `45` | Tempo (em segundos) que a sonolência e redução de estresse do sedativo perduram. |
| `ConfigMedical.LucasBPM` | `number` | `102` | Taxa de compressões por minuto simulada pelo compressor Lucas 3. |

### Configuração de Macas (`ConfigMedical.Stretcher`)
- `Model`: Prop hash da maca Fernocot (`'fernocot'`).
- `AllowedVehicles`: Lista de modelos de viaturas (`ambulance`, `emsroamer`, etc.) que possuem suporte para acoplamento traseiro.
- `AttachOffset`: Coordenadas de ancoragem da maca dentro do baú da ambulância.

### Configuração de Raio-X (`ConfigMedical.XRay`)
- `Rooms`: Lista de posições 3D das salas de radiologia nos hospitais cadastrados.
- `ScanDuration`: Duração do escaneamento do feixe CRT (em milissegundos).
- `CostPerScan`: Taxa cobrada para emissão do laudo radiográfico.

### Configuração de TVs de Hospital (`Config.TV`)
- `enabled`: Liga/desliga o terminal de TV (painel de "paciente a caminho").
- `points`: Preenchido automaticamente a partir de `hospitals/*.lua` (`TV = { [hospital] = { [nome] = { coords, rot } } }`). Cada ponto de TV deve ficar a pelo menos 20 unidades de distância de outro no mesmo hospital (limitação de textura do GTA).
