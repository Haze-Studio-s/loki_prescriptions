--[[
    ============================================================================
    QBox Medical Compatibility Bridge (Client)
    Handles Full Death State Machine (Last Stand -> Bleedout -> Dead -> Hospital Respawn)
    Exposes 100% of canonical exports expected by QBox ecosystem
    ============================================================================
]]

local playerState = LocalPlayer.state
local deathState = DeathStateEnum.ALIVE
local deathTime = 0
local laststandTime = 0
local respawnHoldTime = 5
local isHoldingRespawn = 0

local LastStandDict = 'combat@damage@writhe'
local LastStandAnim = 'writhe_loop'

-- Coordenadas de emergência dos principais hospitais de Los Santos
local HospitalRespawns = {
    vec4(298.54, -584.28, 43.26, 70.0),    -- Central Pillbox Hill Hospital
    vec4(1839.25, 3672.84, 34.28, 210.0),  -- Sandy Shores Medical
    vec4(-247.38, 6331.42, 32.43, 225.0),  -- Paleto Bay Clinic
    vec4(-449.62, -340.75, 34.50, 80.0),   -- Mount Zonah Medical
    vec4(1151.81, -1529.74, 35.37, 350.0), -- St. Fiacre Hospital
}

local function getClosestHospital()
    local myCoords = GetEntityCoords(cache.ped)
    local closest = HospitalRespawns[1]
    local minDist = #(myCoords - vec3(closest.x, closest.y, closest.z))

    for i = 2, #HospitalRespawns do
        local h = HospitalRespawns[i]
        local dist = #(myCoords - vec3(h.x, h.y, h.z))
        if dist < minDist then
            minDist = dist
            closest = h
        end
    end
    return closest
end

-- Sincronização da State Bag local
AddStateBagChangeHandler(DEATH_STATE_STATE_BAG, ('player:%s'):format(cache.serverId), function(_, _, value)
    deathState = value or DeathStateEnum.ALIVE
end)

function SetLocalDeathState(newState)
    deathState = newState
    playerState:set(DEATH_STATE_STATE_BAG, newState, true)
    playerState:set('isDead', newState == DeathStateEnum.DEAD or newState == DeathStateEnum.LAST_STAND, true)
    playerState:set('inLastStand', newState == DeathStateEnum.LAST_STAND, true)
end

-- ============================================================================
-- EXPORTS NATIVOS (Compatibilidade com qbx_medical)
-- ============================================================================
exports('IsDead', function()
    return deathState == DeathStateEnum.DEAD
end)

exports('IsLaststand', function()
    return deathState == DeathStateEnum.LAST_STAND
end)

exports('GetDeathTime', function()
    return deathTime
end)

exports('GetLaststandTime', function()
    return laststandTime
end)

exports('IncrementDeathTime', function(seconds)
    deathTime = deathTime + (seconds or 0)
end)

exports('IncrementLaststandTime', function(seconds)
    laststandTime = laststandTime + (seconds or 0)
end)

exports('GetRespawnHoldTimeDeprecated', function()
    return respawnHoldTime
end)

exports('PlayDeadAnimation', function()
    if deathState == DeathStateEnum.DEAD or deathState == DeathStateEnum.LAST_STAND then
        lib.requestAnimDict(LastStandDict)
        TaskPlayAnim(cache.ped, LastStandDict, LastStandAnim, 1.0, 8.0, -1, 1, 0, false, false, false)
    end
end)

exports('AllowRespawn', function()
    deathTime = 0
end)

exports('DisableRespawn', function()
    deathTime = 999999
end)

exports('StartLastStand', function()
    TriggerEvent('loki_prescriptions:client:startLastStand')
end)

exports('KillPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)

exports('MakePedLimp', function() end)
exports('SendBleedAlert', function() end)
exports('MakePlayerBlackout', function() end)
exports('MakePlayerFadeOut', function() end)
exports('RemoveBleed', function()
    playerState:set(BLEED_LEVEL_STATE_BAG, 0, true)
end)
exports('EnableBleeding', function() end)
exports('DisableBleeding', function() end)
exports('EnableDamageEffects', function() end)
exports('DisableDamageEffects', function() end)

-- ============================================================================
-- EVENTOS DE REVIVER E CURA
-- ============================================================================
local function doReviveCleanup()
    SetLocalDeathState(DeathStateEnum.ALIVE)
    deathTime = 0
    laststandTime = 0
    isHoldingRespawn = 0

    local ped = cache.ped
    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, false)
    ResurrectPed(ped)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    playerState:set(BLEED_LEVEL_STATE_BAG, 0, true)

    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

RegisterNetEvent('qbx_medical:client:playerRevived', doReviveCleanup)
RegisterNetEvent('p_ambulancejob/client/death/revive', doReviveCleanup)
RegisterNetEvent('loki_prescriptions:client:revive', doReviveCleanup)

RegisterNetEvent('qbx_medical:client:killPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)

RegisterNetEvent('qbx_medical:client:heal', function(healType)
    local ped = cache.ped
    if healType == 'full' then
        doReviveCleanup()
    else
        SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + 50))
        playerState:set(BLEED_LEVEL_STATE_BAG, 0, true)
    end
end)

-- ============================================================================
-- MÁQUINA DE ESTADOS DO CICLO VITAL (DOWNED -> LAST STAND -> DEAD -> RESPAWN)
-- ============================================================================
local function enterLastStand()
    if deathState ~= DeathStateEnum.ALIVE then return end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Ressuscita o ped imediatamente com HP baixo para prevenir tela preta nativa do GTA
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetEntityHealth(ped, 110)
    SetEntityInvincible(ped, true)

    SetLocalDeathState(DeathStateEnum.LAST_STAND)
    laststandTime = 300 -- 5 minutos de sangramento
    deathTime = 60

    lib.requestAnimDict(LastStandDict)
    TaskPlayAnim(ped, LastStandDict, LastStandAnim, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Notificação discreta via ox_lib TextUI
    if lib and lib.showTextUI then
        lib.showTextUI(('EM CHOQUE TRAUMÁTICO - Aguarde socorro médico (%ds)'):format(laststandTime), {
            position = 'bottom-center',
            icon = 'heart-pulse'
        })
    end
end

local function enterDeadState()
    SetLocalDeathState(DeathStateEnum.DEAD)
    laststandTime = 0
    deathTime = 30

    if lib and lib.showTextUI then
        lib.showTextUI('PARADA CARDIORRESPIRATÓRIA - Segure [E] para Respawn Hospitalar', {
            position = 'bottom-center',
            icon = 'skull-crossbones'
        })
    end
end

local function executeHospitalRespawn()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end

    local targetHospital = getClosestHospital()
    local ped = cache.ped
    SetEntityCoords(ped, targetHospital.x, targetHospital.y, targetHospital.z, false, false, false, false)
    SetEntityHeading(ped, targetHospital.w)

    Wait(500)
    lib.callback.await('qbx_medical:server:respawn', false)

    DoScreenFadeIn(1200)
    Bridge.Notify.showNotify('Você acordou no hospital sob cuidados médicos intensivos.', 'inform')
end

-- Thread de monitoramento de vida e morte (0.00ms resmon em repouso)
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = cache.ped

        if deathState == DeathStateEnum.ALIVE then
            if IsEntityDead(ped) or GetEntityHealth(ped) <= 100 then
                sleep = 0
                enterLastStand()
            end
        elseif deathState == DeathStateEnum.LAST_STAND then
            sleep = 1000
            SetEntityInvincible(ped, true)

            -- Garante manter a animação de ferido no chão
            if not IsEntityPlayingAnim(ped, LastStandDict, LastStandAnim, 3) then
                lib.requestAnimDict(LastStandDict)
                TaskPlayAnim(ped, LastStandDict, LastStandAnim, 8.0, -8.0, -1, 1, 0, false, false, false)
            end

            if laststandTime > 0 then
                laststandTime = laststandTime - 1
                if laststandTime % 2 == 0 and lib and lib.showTextUI then
                    lib.showTextUI(('EM CHOQUE TRAUMÁTICO - Aguarde socorro médico (%ds)'):format(laststandTime), {
                        position = 'bottom-center',
                        icon = 'heart-pulse'
                    })
                end
            else
                enterDeadState()
            end
        elseif deathState == DeathStateEnum.DEAD then
            sleep = 100
            SetEntityInvincible(ped, true)

            -- Segurar tecla E (38) para respawn hospitalar
            if IsControlPressed(0, 38) then
                isHoldingRespawn = isHoldingRespawn + 100
                local pct = math.min(100, math.floor((isHoldingRespawn / (respawnHoldTime * 1000)) * 100))
                if lib and lib.showTextUI then
                    lib.showTextUI(('PARADA CARDIORRESPIRATÓRIA - Respawn: %d%%'):format(pct), {
                        position = 'bottom-center',
                        icon = 'hospital'
                    })
                end

                if isHoldingRespawn >= (respawnHoldTime * 1000) then
                    isHoldingRespawn = 0
                    executeHospitalRespawn()
                end
            else
                if isHoldingRespawn > 0 then
                    isHoldingRespawn = 0
                    if lib and lib.showTextUI then
                        lib.showTextUI('PARADA CARDIORRESPIRATÓRIA - Segure [E] para Respawn Hospitalar', {
                            position = 'bottom-center',
                            icon = 'skull-crossbones'
                        })
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
