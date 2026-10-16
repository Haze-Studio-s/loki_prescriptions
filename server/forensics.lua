--[[
    ============================================================================
    Módulo de Necropsia & Perícia Médico-Legal (Server)
    Compilação tanatológica de danos, toxicologia e emissão de laudo oficial
    ============================================================================
]]

local WeaponForensicNames = {
    -- Armas Brancas e Impacto Contuso
    [joaat('WEAPON_UNARMED')] = 'Trauma Contuso por Força Muscular / Espancamento',
    [joaat('WEAPON_KNUCKLE')] = 'Trauma Contuso por Soco Inglês / Golpe de Impacto',
    [joaat('WEAPON_KNIFE')] = 'Ferimento Pérfuro-Cortante por Arma Branca (Faca)',
    [joaat('WEAPON_SWITCHBLADE')] = 'Ferimento Pérfuro-Cortante por Canivete Automático (Switchblade)',
    [joaat('WEAPON_DAGGER')] = 'Perfuração Profunda por Punhal / Adaga Militar',
    [joaat('WEAPON_MACHETE')] = 'Lesão Corto-Contundente Severa por Facão / Machete',
    [joaat('WEAPON_HATCHET')] = 'Fratura Corto-Contundente por Machado / Machadinha',
    [joaat('WEAPON_BAT')] = 'Traumatismo Cranioencefálico / Ósseo por Taco de Beisebol',
    [joaat('WEAPON_CROWBAR')] = 'Lesão Contusa com Laceração por Pé de Cabra',
    [joaat('WEAPON_HAMMER')] = 'Fratura com Afundamento Ósseo por Martelo',
    [joaat('WEAPON_NIGHTSTICK')] = 'Contusão Muscular e Traumatismo por Bastão / Tonfa Policial',
    [joaat('WEAPON_GOLFCLUB')] = 'Trauma Contuso por Taco de Golfe',
    [joaat('WEAPON_BOTTLE')] = 'Laceração Pérfuro-Cortante por Gargalo de Garrafa Quebrada',

    -- Armas de Fogo Curtas / Pistolas
    [joaat('WEAPON_PISTOL')] = 'Perfuração por Projétil de Arma de Fogo Calibre 9x19mm (Pistola)',
    [joaat('WEAPON_COMBATPISTOL')] = 'Perfuração por Projétil Balístico 9mm Luger (Pistola de Combate)',
    [joaat('WEAPON_APPISTOL')] = 'Múltiplas Perfurações Balísticas em Rajada 9mm (AP Pistol)',
    [joaat('WEAPON_PISTOL50')] = 'Laceração Tecidual Maciça por Projétil Pesado Calibre .50 Action Express',
    [joaat('WEAPON_SNSPISTOL')] = 'Perfuração por Projétil de Baixo Calibre .380 ACP (SNS Pistol)',
    [joaat('WEAPON_HEAVYPISTOL')] = 'Lesão Transfixante por Projétil Calibre .45 ACP',
    [joaat('WEAPON_VINTAGEPISTOL')] = 'Perfuração Balística por Projétil 9mm Vintage',
    [joaat('WEAPON_MARKSMANPISTOL')] = 'Perfuração de Alta Precisão .22 LR / Match Pistol',
    [joaat('WEAPON_REVOLVER')] = 'Destruição Óssea Traumática por Projétil Calibre .44 Magnum',

    -- Submetralhadoras
    [joaat('WEAPON_MICROSMG')] = 'Perfurações Múltiplas por Rajada 9mm (Micro SMG / Uzi)',
    [joaat('WEAPON_SMG')] = 'Perfurações por Projétil de Submetralhadora 9mm (MP5)',
    [joaat('WEAPON_ASSAULTSMG')] = 'Múltiplos Orifícios de Entrada/Saída por Munição Perfurante 5.7x28mm (P90)',
    [joaat('WEAPON_COMBATPDW')] = 'Perfurações em Rajada por Munição 9mm PDW',
    [joaat('WEAPON_MACHINEPISTOL')] = 'Ferimentos Balísticos Múltiplos 9mm (Machine Pistol)',
    [joaat('WEAPON_MINISMG')] = 'Perfurações Múltiplas por Submetralhadora Compacta 9mm',

    -- Espingardas / Shotguns
    [joaat('WEAPON_PUMPSHOTGUN')] = 'Ferimento Pérfuro-Disperso Severo por Balote/Chumbo Calibre 12',
    [joaat('WEAPON_SAWNOFFSHOTGUN')] = 'Destruição Tecidual Imediata por Tiro Queima-Roupa Calibre 12 Serrado',
    [joaat('WEAPON_ASSAULTSHOTGUN')] = 'Múltiplas Lesões Concomitantes de Chumbo Grosso Calibre 12 Auto',
    [joaat('WEAPON_BULLPUPSHOTGUN')] = 'Politraumatismo Balístico por Disparos Calibre 12 Bullpup',
    [joaat('WEAPON_HEAVYSHOTGUN')] = 'Destruição Óssea Maciça por Balote Único Calibre 12 Slug',
    [joaat('WEAPON_DBSHOTGUN')] = 'Devastação Tecidual por Disparo Duplo Calibre 12',

    -- Fuzis de Assalto e Carabinas
    [joaat('WEAPON_ASSAULTRIFLE')] = 'Lesão Cavitária Grave por Projétil Militar 7.62x39mm (AK-47)',
    [joaat('WEAPON_CARBINERIFLE')] = 'Lesão Transfixante Cavitária por Projétil de Alta Energia 5.56x45mm (M4A1)',
    [joaat('WEAPON_ADVANCEDRIFLE')] = 'Trauma Balístico Militar de Alta Velocidade 5.56mm (TAR-21)',
    [joaat('WEAPON_SPECIALCARBINE')] = 'Orifício Pérfuro-Contuso com Estilhaçamento Ósseo 5.56mm (G36C)',
    [joaat('WEAPON_BULLPUPRIFLE')] = 'Perfuração Transfixante Militar 5.56mm Bullpup',
    [joaat('WEAPON_COMPACTRIFLE')] = 'Lesão Balística de Fuzil Compacto 7.62mm',

    -- Fuzis de Precisão / Snipers
    [joaat('WEAPON_SNIPERRIFLE')] = 'Destruição de Órgãos Vitais por Disparo Sniper .308 Winchester (7.62x51mm)',
    [joaat('WEAPON_HEAVYSNIPER')] = 'Destruição Corpórea Catastrófica por Projétil Antimaterial Calibre .50 BMG',
    [joaat('WEAPON_MARKSMANRIFLE')] = 'Múltiplas Perfurações Balísticas de Fuzil Semiautomático 7.62mm',

    -- Causas Não-Armadas / Físicas / Ambientais
    [joaat('WEAPON_RAMMED_BY_CAR')] = 'Politraumatismo por Impacto / Atropelamento de Veículo Automotor',
    [joaat('WEAPON_RUN_OVER_BY_CAR')] = 'Esmagamento e Fraturas Múltiplas por Compressão de Rodado Veicular',
    [joaat('WEAPON_EXPLOSION')] = 'Barotrauma Pulmonar e Onda de Choque por Detonação / Explosão',
    [joaat('WEAPON_FIRE')] = 'Queimaduras Térmicas Graves de 3º/4º Grau por Combustão e Fogo',
    [joaat('WEAPON_DROWNING')] = 'Asfixia Mecânica por Submersão e Inundação Pulmonar (Afogamento)',
    [joaat('WEAPON_DROWNING_IN_VEHICLE')] = 'Asfixia por Afogamento em Habitáculo de Veículo Submerso',
    [joaat('WEAPON_FALL')] = 'Politraumatismo com Fraturas Múltiplas por Queda de Altura Elevada',
    [joaat('WEAPON_BLEEDING')] = 'Choque Hipovolêmico Irreversível por Hemorragia Exsanguinante',
    [joaat('WEAPON_ELECTRIC_FENCE')] = 'Eletrocussão com Parada Cardíaca por Descarga de Alta Voltagem'
}

local function isAuthorizedJob(src)
    local plyJob = Bridge.Framework.getPlayerJob(src)
    if not plyJob then return false end
    if plyJob.name == 'police' then return true end
    if Config.PrescriptionJobs then
        for _, j in ipairs(Config.PrescriptionJobs) do
            if j == plyJob.name then return true end
        end
    end
    return plyJob.name == 'ambulance'
end

-- Identificação forense do nome da arma/causa através do hash
local function getForensicWeaponName(weaponHash)
    if not weaponHash then return 'Objeto Não Identificado' end

    -- Se já for string descritiva
    local numHash = tonumber(weaponHash)
    if numHash and WeaponForensicNames[numHash] then
        return WeaponForensicNames[numHash]
    end

    -- Tenta joaat se for string de weapon
    local strHash = joaat(tostring(weaponHash))
    if WeaponForensicNames[strHash] then
        return WeaponForensicNames[strHash]
    end

    local str = tostring(weaponHash):upper()
    if str:find('PISTOL') then return 'Projétil Balístico de Arma de Fogo Curta (Pistola)' end
    if str:find('RIFLE') then return 'Projétil Balístico de Fuzil / Carabina' end
    if str:find('SHOTGUN') then return 'Munição de Espingarda / Dispersão de Chumbo Calibre 12' end
    if str:find('KNIFE') or str:find('BLADE') then return 'Arma Branca / Instrumento Pérfuro-Cortante' end
    if str:find('CAR') or str:find('VEHICLE') then return 'Trauma por Impacto Veicular Automotor' end

    return ('Instrumento Lesivo [%s]'):format(tostring(weaponHash))
end

-- Callback para compilar e formatar o laudo de necropsia do cadáver
lib.callback.register('loki_prescriptions:server:performAutopsy', function(source, targetServerId)
    local src = source
    if not isAuthorizedJob(src) then return nil end

    local target = tonumber(targetServerId)
    if not target or target <= 0 then return nil end

    local docPed = GetPlayerPed(src)
    local vicPed = GetPlayerPed(target)
    if not DoesEntityExist(docPed) or not DoesEntityExist(vicPed) then return nil end

    local dist = #(GetEntityCoords(docPed) - GetEntityCoords(vicPed))
    if dist > 6.0 then return nil end

    -- Dados do Legista
    local coronerName = Bridge.Framework.getPlayerName(src)
    local coronerCid = Bridge.Framework.getUniqueId(src)

    -- Dados da Vítima
    local victimName = Bridge.Framework.getPlayerName(target)
    local victimCid = Bridge.Framework.getUniqueId(target)

    -- Coleta de Danos Anatômicos e Balísticos da vítima
    local damages = Player(target).state.damages or {}
    local injuryList = {}
    local causesDetected = {}

    local boneTranslations = {
        head = 'Crânio / Região Encefálica',
        neck = 'Região Cervical / Pescoço',
        spine = 'Coluna Vertebral / Tronco',
        upper_body = 'Tórax / Caixa Torácica',
        lower_body = 'Região Abdominal / Pélvis',
        larm = 'Membro Superior Esquerdo',
        rarm = 'Membro Superior Direito',
        lleg = 'Membro Inferior Esquerdo',
        rleg = 'Membro Inferior Direito',
        mouth = 'Cavidade Oral e Facial'
    }

    for boneKey, weaponEntries in pairs(damages) do
        local boneName = boneTranslations[boneKey] or boneKey
        for weaponHash, entry in pairs(weaponEntries) do
            local rawWeapon = entry.data and entry.data.weapon or weaponHash
            local forensicName = getForensicWeaponName(rawWeapon)
            table.insert(injuryList, ('• **%s**: %s'):format(boneName, forensicName))
            table.insert(causesDetected, forensicName)
        end
    end

    local injuriesFormatted = #injuryList > 0 and table.concat(injuryList, '\n') or '• Lesões contusas superficiais sem fraturas aparentes expostas.'

    local primaryCause = 'Parada Cardiorrespiratória por Choque Hipovolêmico / Politraumatismo'
    if #causesDetected > 0 then
        primaryCause = causesDetected[1]
    end

    -- Avaliação Toxicológica
    local toxicDetails = {}
    if Player(target).state.isOverdosed then
        table.insert(toxicDetails, '⚠️ Presença tóxica compatível com INTOXICAÇÃO EXÓGENA AGUDA (Overdose Farmacológica).')
    end

    -- Integração com vp_needs
    pcall(function()
        if exports.vp_needs then
            local playerNeeds = exports.vp_needs:GetPlayerNeeds(target)
            if playerNeeds and playerNeeds.alcohol and playerNeeds.alcohol > 20 then
                table.insert(toxicDetails, ('⚠️ Dosagem de Alcoolemia Positiva no Sangue (Nível: %d%%).'):format(math.floor(playerNeeds.alcohol)))
            end
        end
    end)

    -- Integração com aurp_put (Triagem Sorológica de DSTs)
    pcall(function()
        if GetResourceState('aurp_put') == 'started' and exports['aurp_put'] and exports['aurp_put'].GetPlayerDisease then
            local identifier = GetPlayerIdentifierByType(target, 'license')
            if identifier then
                identifier = identifier:gsub('license:', '')
                local diseaseData = exports['aurp_put']:GetPlayerDisease(identifier)
                if diseaseData and diseaseData.disease then
                    table.insert(toxicDetails, ('⚠️ Triagem Infecciosa Sorológica: Positivo para Patógeno Sexualmente Transmissível (%s).'):format(diseaseData.disease:upper()))
                end
            end
        end
    end)

    local toxicologyFormatted = #toxicDetails > 0 and table.concat(toxicDetails, '\n') or 'Nenhum metabólito tóxico ou substância química ilícita identificada no teste preliminar.'

    local reportData = {
        reportId = ('IML-%s-%03d'):format(os.date('%y%m%d'), math.random(100, 999)),
        date = os.date('%d/%m/%Y %H:%M'),
        coronerName = coronerName,
        coronerCid = coronerCid,
        victimName = victimName,
        victimCid = victimCid,
        causeOfDeath = primaryCause,
        injuries = injuriesFormatted,
        toxicology = toxicologyFormatted,
        targetServerId = target
    }

    return reportData
end)

-- Emissão formal do item do laudo de necropsia no inventário do perito
RegisterServerEvent('loki_prescriptions:server:issueAutopsyReport', function(reportData)
    local src = source
    if not isAuthorizedJob(src) then return end
    if type(reportData) ~= 'table' then return end

    local now = os.time()
    local metadata = {
        data = {
            reportId = reportData.reportId or ('IML-' .. now),
            date = reportData.date or os.date('%d/%m/%Y %H:%M'),
            coronerName = reportData.coronerName or Bridge.Framework.getPlayerName(src),
            coronerCid = reportData.coronerCid or Bridge.Framework.getUniqueId(src),
            victimName = reportData.victimName or 'Não Identificado',
            victimCid = reportData.victimCid or 'N/A',
            causeOfDeath = reportData.causeOfDeath or 'Causa Indeterminada',
            injuries = reportData.injuries or 'Sem achados',
            toxicology = reportData.toxicology or 'Negativo',
            issued_at = now
        },
        description = ('Laudo Tanatológico [%s] | Vítima: %s'):format(reportData.reportId or 'IML', reportData.victimName or 'Indigente')
    }

    local given = Bridge.Inventory.addItem(src, 'autopsy_report', 1, metadata)
    if given then
        Bridge.Notify.showNotify(src, 'Laudo Pericial Oficial de Necropsia arquivado no seu inventário.', 'success')
    else
        Bridge.Notify.showNotify(src, 'Mochila cheia. Não foi possível receber o documento.', 'error')
    end
end)

-- Registro do item utilizável no servidor para visualização com fé pública
CreateThread(function()
    Wait(1500)
    Bridge.Framework.registerItem('autopsy_report', function(source, item)
        local meta = item and (item.metadata or item.info)
        TriggerClientEvent('loki_prescriptions:client:viewAutopsyReport', source, meta)
    end)
end)
