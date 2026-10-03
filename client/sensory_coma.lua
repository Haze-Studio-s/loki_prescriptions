--[[
    ============================================================================
    Coma Sensorial & Reação de Dor do Paciente (Sensory Coma)
    Substitui a tela preta monótona por uma experiência sensorial imersiva
    ============================================================================
]]

local inComa = false
local lastGroan = 0

local function startSensoryComa()
    if inComa then return end
    inComa = true

    -- Filtro de áudio cinematográfico (muffled / abafado)
    StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")

    -- Efeito visual de túnel e choque hemodinâmico (não bloqueia 100% da visão)
    SetTimecycleModifier("DeathFailMPDark")
    SetTimecycleModifierStrength(0.75)

    -- Thread de batimentos cardíacos vitais
    CreateThread(function()
        while inComa do
            SendNUIMessage({
                action = 'playSound',
                sound = 'slowheartbeat',
                volume = 0.35
            })
            Wait(2000)
        end
    end)

    -- Notificação discreta de socorro via lib.showTextUI
    if lib and lib.showTextUI then
        lib.showTextUI('[E] Gemer de Dor / Pedir Socorro', {
            position = 'bottom-center',
            icon = 'heart-pulse'
        })
    end

    -- Thread de interação de dor / socorro pelo paciente (0.00ms resmon)
    CreateThread(function()
        while inComa do
            Wait(4)
            if IsControlJustPressed(0, 38) then -- Tecla E
                local now = GetGameTimer()
                if now - lastGroan > 4000 then
                    lastGroan = now
                    -- Toca áudio e reação física de dor
                    PlayPain(cache.ped, 7, 0, 0)
                    TriggerServerEvent('loki_prescriptions:server:playerMoan', GetEntityCoords(cache.ped))
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
                end
            end
        end
    end)
end

local function stopSensoryComa()
    if not inComa then return end
    inComa = false

    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end

    StopAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
end

-- Monitoramento do State Bag de Coma/Morte do QBox
AddStateBagChangeHandler('isDead', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value then
        startSensoryComa()
    else
        stopSensoryComa()
    end
end)

-- Sincronização de gemidos de dor audíveis para pessoas próximas
RegisterNetEvent('loki_prescriptions:client:hearMoan', function(coords)
    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - coords)
    if dist <= 12.0 and dist > 0.5 then
        -- Volume decai com a distância
        local vol = math.max(0.05, 0.4 - (dist / 30.0))
        SendNUIMessage({
            action = 'playSound',
            sound = 'cough',
            volume = vol
        })
    end
end)

-- Limpeza ao nascer / spawnar
AddEventHandler('playerSpawned', function()
    stopSensoryComa()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        stopSensoryComa()
    end
end)
