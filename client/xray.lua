--[[
    ============================================================================
    Módulo de Radiologia & Raio-X Digital Hospitalar (Client)
    Terminal de Tomografia / Raio-X interativo integrado ao sistema de fraturas
    ============================================================================
]]

local isXrayOpen = false
local currentPatientPed = nil
local currentPatientServerId = nil

-- Locais pré-configurados dos terminais e leitos de radiologia no Pillbox
local XrayStations = {
    {
        name = 'Pillbox Radiologia Subsolo',
        terminalCoords = vec3(307.0, -584.5, 30.63),
        bedCoords = vec3(305.25, -583.56, 30.63),
        radius = 3.0
    },
    {
        name = 'Pillbox Centro de Trauma Térreo',
        terminalCoords = vec3(307.25, -595.14, 43.28),
        bedCoords = vec3(311.19, -582.88, 43.20),
        radius = 4.0
    }
}

local function isDoctor()
    local job = Bridge.Framework.fetchPlayerJob()
    if not job then return false end
    if Config.PrescriptionJobs and lib.table.contains(Config.PrescriptionJobs, job.name) then
        return true
    end
    return job.name == 'ambulance'
end

-- Busca o paciente mais próximo do leito de radiologia ou do terminal
local function findPatientForScan(station)
    local checkCoords = station and station.bedCoords or GetEntityCoords(cache.ped)
    local closestPlayer, closestDist = nil, 999.0

    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= cache.ped and DoesEntityExist(targetPed) then
            local dist = #(GetEntityCoords(targetPed) - checkCoords)
            if dist < closestDist and dist <= 4.0 then
                closestDist = dist
                closestPlayer = player
            end
        end
    end

    if closestPlayer then
        local ped = GetPlayerPed(closestPlayer)
        local srvId = GetPlayerServerId(closestPlayer)
        return ped, srvId
    end

    return nil, nil
end

-- Abertura da interface do terminal de Raio-X
local function openXrayTerminal(station)
    if isXrayOpen then return end
    if not isDoctor() then
        Bridge.Notify.showNotify('Acesso restrito a médicos e técnicos em radiologia.', 'error')
        return
    end

    local patientPed, patientServerId = findPatientForScan(station)
    currentPatientPed = patientPed
    currentPatientServerId = patientServerId

    isXrayOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        type = 'show',
        state = true
    })

    if patientServerId then
        local pName = Bridge.Framework.getPlayerName(patientServerId) or 'Paciente'
        SendNUIMessage({
            type = 'setPatient',
            patient = {
                name = pName,
                id = patientServerId
            }
        })
        Bridge.Notify.showNotify(('Paciente %s sincronizado no leito radiológico.'):format(pName), 'success')
    else
        SendNUIMessage({
            type = 'setPatient',
            patient = nil
        })
        Bridge.Notify.showNotify('Aviso: Nenhum paciente detectado sobre o leito de exame.', 'inform')
    end
end

-- Callbacks NUI
RegisterNUICallback('closeUI', function(_, cb)
    isXrayOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'show',
        state = false
    })
    cb('ok')
end)

RegisterNUICallback('syncInteraction', function(data, cb)
    if data and data.type == 'startScan' then
        if not currentPatientServerId then
            Bridge.Notify.showNotify('Posicione um paciente sobre o leito para realizar a varredura.', 'error')
            cb('error')
            return
        end

        -- Toca efeito sonoro de feixe de raios-X e ressonância magnética
        SendNUIMessage({
            action = 'playSound',
            sound = 'defibrillator_charge',
            volume = 0.4
        })

        -- Consulta ao servidor os ossos danificados
        lib.callback('loki_prescriptions:server:scanPatientXray', false, function(injuries)
            SetTimeout(3200, function()
                if isXrayOpen then
                    SendNUIMessage({
                        type = 'scanResults',
                        injuries = injuries or {}
                    })
                    Bridge.Notify.showNotify('Varredura concluída. Chapa radiológica processada.', 'success')
                end
            end)
        end, currentPatientServerId)
    end
    cb('ok')
end)

RegisterNUICallback('printXrayReport', function(data, cb)
    if data and data.patient and data.results then
        TriggerServerEvent('loki_prescriptions:server:printXrayReport', data)
    end
    cb('ok')
end)

-- Registro do comando para médicos
RegisterCommand('raiox', function()
    openXrayTerminal(nil)
end, false)

-- Registro dos pontos no Ox Target
CreateThread(function()
    Wait(2000)

    if exports.ox_target then
        for i, station in ipairs(XrayStations) do
            exports.ox_target:addBoxZone({
                coords = station.terminalCoords,
                size = vec3(1.2, 1.2, 1.5),
                rotation = 0.0,
                debug = false,
                options = {
                    {
                        name = 'loki_xray_station_' .. i,
                        icon = 'fa-solid fa-x-ray',
                        label = 'Acessar Terminal de Raio-X & Tomografia',
                        distance = 2.0,
                        canInteract = function()
                            return isDoctor()
                        end,
                        onSelect = function()
                            openXrayTerminal(station)
                        end
                    }
                }
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if isXrayOpen then
        SetNuiFocus(false, false)
        isXrayOpen = false
    end
end)
