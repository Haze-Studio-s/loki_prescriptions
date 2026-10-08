--[[
    ============================================================================
    LUCAS 3 - Mechanical CPR Chest Compression System
    Absorbed from ak47_qb_ambulancejob and upgraded for QBox & ox_target
    ============================================================================
]]

local activeLucas = {}

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 200 do
        Wait(10)
        timeout = timeout + 1
    end
    return hash
end

RegisterNetEvent('loki_prescriptions:client:useLucas3', function(targetServerId)
    if not targetServerId then
        local closestPlayer, closestDist = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 2.5, false)
        if closestPlayer and closestDist <= 2.5 then
            targetServerId = GetPlayerServerId(closestPlayer)
        else
            Bridge.Notify.showNotify('Nenhum paciente próximo para instalar o LUCAS 3.', 'error')
            return
        end
    end

    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
    if not targetPed or targetPed == 0 then return end

    if activeLucas[targetServerId] then
        -- Desacoplar LUCAS 3
        TriggerServerEvent('loki_prescriptions:server:removeLucas3', targetServerId)
        return
    end

    if lib and lib.progressBar then
        local success = lib.progressBar({
            duration = 3000,
            label = 'Instalando LUCAS 3 no tórax...',
            useWhileDead = false,
            canCancel = true,
            anim = {
                dict = 'mini@cpr@char_a@cpr_str',
                clip = 'cpr_pumpchest'
            }
        })
        if not success then return end
    end

    TriggerServerEvent('loki_prescriptions:server:attachLucas3', targetServerId)
end)

RegisterNetEvent('loki_prescriptions:client:syncAttachLucas3', function(targetServerId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
    if not targetPed or targetPed == 0 then return end

    if activeLucas[targetServerId] and DoesEntityExist(activeLucas[targetServerId].object) then
        DeleteEntity(activeLucas[targetServerId].object)
    end

    local modelHash = loadModel('prop_lucas3')
    local pCoords = GetEntityCoords(targetPed)
    local obj = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
    
    AttachEntityToEntity(
        obj, targetPed, 0,
        -0.02, -0.15, 0.30,
        270.0, 0.0, -10.0,
        false, false, false, false, 2, true
    )
    SetModelAsNoLongerNeeded(modelHash)

    activeLucas[targetServerId] = {
        object = obj,
        targetPed = targetPed
    }

    -- Tocar som rítmico cardíaco contínuo
    CreateThread(function()
        while activeLucas[targetServerId] and DoesEntityExist(activeLucas[targetServerId].object) do
            SendNUIMessage({
                action = 'playSound',
                sound = 'rapidheartbeat',
                volume = 0.4
            })
            Wait(1200)
        end
    end)
end)

RegisterNetEvent('loki_prescriptions:client:syncRemoveLucas3', function(targetServerId)
    if activeLucas[targetServerId] then
        if DoesEntityExist(activeLucas[targetServerId].object) then
            DeleteEntity(activeLucas[targetServerId].object)
        end
        activeLucas[targetServerId] = nil
    end
end)

-- Registro de Target no Jogador para Paramédicos
Citizen.CreateThread(function()
    Wait(2000)
    Bridge.Target.addPlayer({
        {
            name = 'attach_lucas3_device',
            label = 'Instalar/Remover LUCAS 3 (RCP Automática)',
            icon = 'fa-solid fa-heart-pulse',
            distance = 2.0,
            groups = Editable.allJobs or { ambulance = 0 },
            canInteract = function(entity)
                return Bridge.Inventory.getItemCount('lucas3') > 0 or false
            end,
            onSelect = function(data)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                TriggerEvent('loki_prescriptions:client:useLucas3', targetId)
            end
        }
    })
end)
