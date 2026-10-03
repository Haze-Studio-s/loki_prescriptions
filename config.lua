Config = {}

if lib and lib.locale then
    lib.locale()
end

--[[
  _____       ___   ___  ____   _____   ______     ______  _______     _____  _______   _________   ______          
 |_   _|    .'   `.|_  ||_  _| |_   _|.' ____ \  .' ___  ||_   __ \   |_   _||_   __ \ |  _   _  |.' ____ \         
   | |     /  .-.  \ | |_/ /     | |  | (___ \_|/ .'   \_|  | |__) |    | |    | |__) ||_/ | | \_|| (___ \_|        
   | |   _ | |   | | |  __'.     | |   _.____`. | |         |  __ /     | |    |  ___/     | |     _.____`.         
  _| |__/ |\  `-'  /_| |  \ \_  _| |_ | \____) |\ `.___.'\ _| |  \ \_  _| |_  _| |_       _| |_   | \____) |        
 |________| `.___.'|____||____||_____| \______.' `.____ .'|____| |___||_____||_____|     |_____|   \______.'        
]]

Config.VersionCheck = false
Config.VersionCheckOmitLatest = true
Config.CreateDatabase = true -- Criação automática da tabela de seguro saúde

Config.NuiStyle = "de" -- Estilo visual da receita: us, uk ou de
Config.TimeFormat = "pt-BR" -- Formatação de datas
Config.Locale = "pt" -- de, en, es ou pt

Config.Target = true -- Se true, usa ox_target / qb-target; se false, usa lib.points com 0.00ms de resmon

Config.PrescriptionJobs = {"ambulance", "pharmacy"} -- Cargos autorizados a emitir receitas médicas
Config.PrescriptionItem = 'prescription'
Config.PrescriptionPadItem = 'prescription_pad'

-- Ciclo de Vida e Anti-Exploit de Receitas
Config.ExpirationDays = 3 -- Validade da receita médica (em dias reais)
Config.MaxMedsPerPrescription = 5 -- Quantidade máxima de caixas por tipo de remédio na mesma receita
Config.MaxDifferentMeds = 4 -- Quantidade máxima de tipos de remédios diferentes na mesma receita
Config.MaxRedeemDistance = 4.0 -- Distância máxima (em metros) do balcão da farmácia para resgate seguro

-- Integração Financeira do Hospital
Config.EnableHospitalProfit = true -- Se true, o dinheiro das vendas vai para a conta institucional do hospital
Config.HospitalAccount = 'ambulance' -- Conta bancária no Renewed-Banking / qb-banking

-- Integração Farmacológica com vp_needs
Config.EnableVpNeedsIntegration = true

-- Sistema de Prevenção e Efeitos de Overdose
Config.Overdose = {
    enabled = true,
    threshold = 3, -- Limite de comprimidos tomados em janela curta para disparar overdose
    windowSeconds = 60, -- Janela de tempo avaliada (em segundos)
    effectDuration = 30 -- Duração dos sintomas de intoxicação (em segundos)
}

Config.Anim = {
    enabled = true,
    dict = "amb@world_human_tourist_map@male@base",
    anim = "base",
    prop = {
        model = 'prop_notepad_02',
        bone = 28422,
        offsets = {0.1, 0.0, 0.0},
        rotations = {50.0, 0.0, 0.0}
    }
}

-- Mapeamento Farmacológico de Medicamentos
-- refills: Número de vias atendidas na farmácia antes da retenção definitiva
-- vp_effects: Integração terapêutica direta com os índices do vp_needs
Config.Medicine = {
    {
        item = 'tylacare',
        label = "Tylacare",
        cost = 150,
        refills = 3,
        description = "Analgésico suave e antitérmico para alívio de febre e desconfortos.",
        vp_effects = { stress = -10, hp = 10 }
    },
    {
        item = 'flurimax',
        label = "Flurimax",
        cost = 200,
        refills = 2,
        description = "Antigripal com ação descongestionante contra sintomas de mal-estar.",
        vp_effects = { stress = -15, hp = 15 }
    },
    {
        item = 'dayrelief',
        label = "Dayrelief",
        cost = 250,
        refills = 3,
        description = "Composto revigorante que estabiliza o ritmo e combate a fadiga diurna.",
        vp_effects = { stamina = 25, stress = -10 }
    },
    {
        item = 'gutguard',
        label = "GutGuard",
        cost = 300,
        refills = 3,
        description = "Protetor da mucosa gástrica: cessa náuseas e mal-estar de comida estragada.",
        vp_effects = { cure_nausea = true, hunger_relief = 10 }
    },
    {
        item = 'stopdiaril',
        label = "Stopdiaril",
        cost = 300,
        refills = 2,
        description = "Regulador intestinal para restauração metabólica e controle hidro-eletrolítico.",
        vp_effects = { thirst_relief = 15 }
    },
    {
        item = 'triptaril',
        label = "Triptaril",
        cost = 350,
        refills = 2,
        description = "Relaxante e estabilizador de humor indicado para episódios de estresse extremo.",
        vp_effects = { stress = -35 }
    },
    {
        item = 'ibrofenix',
        label = "Ibrofenix",
        cost = 250,
        refills = 3,
        description = "Anti-inflamatório não esteroide para dores musculares e contusões.",
        vp_effects = { hp = 15, stress = -15 }
    },
    {
        item = 'allerblock',
        label = "AllerBlock",
        cost = 200,
        refills = 3,
        description = "Anti-histamínico de ação rápida contra reações alérgicas e espirros.",
        vp_effects = { stress = -10 }
    },
    {
        item = 'clearairin',
        label = "Clearairin",
        cost = 400,
        refills = 3,
        description = "Broncodilatador de emergência: interrompe crises agudas de tosse e engasgo.",
        vp_effects = { cure_choking = true, stamina = 20 }
    },
    {
        item = 'motionex',
        label = "Motionex",
        cost = 220,
        refills = 3,
        description = "Antiemético preventivo para enjoo de movimento e tontura.",
        vp_effects = { cure_nausea = true }
    },
    {
        item = 'meklirin',
        label = "Meklirin",
        cost = 260,
        refills = 2,
        description = "Estabilizador labiríntico contra vertigens e perda de equilíbrio.",
        vp_effects = { stress = -15 }
    },
    {
        item = 'vironix',
        label = "Vironix",
        cost = 500,
        refills = 1, -- Receita de retenção (antibiótico/antiviral)
        description = "Antiviral clínico de uso restrito para recuperação imunológica hospitalar.",
        vp_effects = { hp = 30, detox_boost = true }
    },
    {
        item = 'vaxora',
        label = "Vaxora",
        cost = 450,
        refills = 1,
        description = "Imunizante terapêutico para aumento de anticorpos e defesas vitais.",
        vp_effects = { hp = 20 }
    },
    {
        item = 'cycurex',
        label = "Cycurex",
        cost = 600,
        refills = 1,
        description = "Terapia antimicrobiana intensiva para quadros de infecção severa.",
        vp_effects = { hp = 40, detox_boost = true }
    },
    {
        item = 'painaway',
        label = "PainAway",
        cost = 550,
        refills = 1, -- Receita controlada de retenção obrigatória
        description = "Analgésico opioide de controle especial contra traumas físicos agudos.",
        vp_effects = { hp = 35, stress = -50 }
    },
    {
        item = 'zithromed',
        label = "ZithroMed",
        cost = 480,
        refills = 1,
        description = "Azitromicina de alta pureza para infecções do trato respiratório e dérmico.",
        vp_effects = { hp = 25, cure_choking = true }
    },
    {
        item = 'doxallin',
        label = "Doxallin",
        cost = 420,
        refills = 1,
        description = "Doxiciclina antibiótica para estabilização metabólica e bacteriana.",
        vp_effects = { hp = 25 }
    },
    {
        item = 'loprexin',
        label = "Loprexin",
        cost = 320,
        refills = 3,
        description = "Bloqueador beta para regulação do ritmo cardíaco e estabilização de pulso.",
        vp_effects = { stamina = 30, stress = -20 }
    },
}

--- CONVÊNIO MÉDICO (PLANO DE SAÚDE)
Config.Insurance = {
    duration = 60 * 60 * 24 * 7, -- 7 dias de cobertura (ou nil para vitalício)
    price = 500,
    reduction = 0.35, -- Desconto: paciente paga 35% do valor total dos remédios
    npc = {
        position = vector4(-291.5244, -430.6360, 29.2375, 341.2159),
        model = 'ig_andreas',
        anim = {dict = "amb@world_human_hang_out_street@female_arms_crossed@idle_a", anim = "idle_a", flags = 17}
    },
    blip = {
        sprite = 276,
        color = 3,
        label = "Plano de Saúde",
        shortRange = true,
        display = 4,
        scale = 0.85
    }
}

--- FARMÁCIAS URBANAS (PONTOS DE ATENDIMENTO)
Config.Pharmacies = {
    {
        position = vector4(343.5782, -1398.8131, 31.5092, 50.1448),
        pedModel = 's_m_m_doctor_01',
        anim = {dict = "amb@world_human_hang_out_street@female_arms_crossed@idle_a", anim = "idle_a", flags = 17},
        blip = {sprite = 153, color = 2, label = "Farmácia Central", shortRange = true, display = 4, scale = 0.85}
    },
    {
        position = vector4(-248.3205, 6332.7231, 31.4261, 226.4288),
        pedModel = 's_m_m_doctor_01',
        anim = {dict = "amb@world_human_hang_out_street@female_arms_crossed@idle_a", anim = "idle_a", flags = 17},
        blip = {sprite = 153, color = 2, label = "Farmácia Paleto", shortRange = true, display = 4, scale = 0.85}
    },
}

---------------------- Notificações ----------------------
Config.Notification = 'lib' -- lib (ox_lib), okoknotify, esx, qb, wasabi_notify, custom

---------------------- Leitos Hospitalares ----------------------
--- Módulo de camas de hospital com cura gradual, cobrança e XP médico.
Config.HospitalBeds = {
    enabled = true,

    --- Preço padrão caso o hospital não tenha CheckIn configurado
    defaultPrice = 250,

    --- Intervalo (ms) entre ticks de cura do cliente ao servidor
    healInterval = 5000,

    --- HP restaurado por tick (servidor autoriza, cliente aplica)
    hpPerTick = 5,

    --- Redução de bleed_level por tick (state bag)
    bleedReductionPerTick = 1,

    --- XP concedido ao socorrista pela desfibrilação bem-sucedida
    xpDefibrilation = 25,

    --- XP por outros procedimentos médicos (hemostasia, transfusão, etc.)
    xpBleeding  = 10,
    xpFracture  = 15,
    xpSaline    = 8,
}