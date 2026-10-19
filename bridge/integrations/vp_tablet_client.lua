--[[
    LOKI MEDICAL SUITE - VP_TABLET INTEGRATION (CLIENT)
    Registro de aplicativo médico corporativo no VP Tablet para paramédicos e médicos.
    Sistema EHR nativo embarcado em iframe sem fechamento de tablet.
]]

local function registerTabletApp()
    if GetResourceState('haze_tablet') ~= 'started' then return end

    pcall(function()
        exports['haze_tablet']:RegisterApp({
            identifier  = 'loki_medical',
            name        = 'LSMC EHR Clinical',
            description = 'Prontuário eletrônico hospitalar, telemetria CTI, radiologia PACS e prescrição digital.',
            icon        = 'https://cfx-nui-loki_prescriptions/web/assets/lifepak.png',
            ui          = 'web/tablet/index.html',
            defaultApp  = true,
            removable   = false,
            category    = 'services',
            author      = 'Los Santos Medical Center',
            onOpen      = function()
                -- Permanece dentro do tablet! Sem fechar a interface
            end,
        })
    end)
end

-- Callbacks NUI acionados a partir do iframe do tablet
RegisterNUICallback('tabletSubmitPrescription', function(data, cb)
    if data and data.medications then
        TriggerServerEvent('loki_prescriptions:createPrescription', {
            patient = data.patient,
            medications = data.medications,
            notes = string.format("[CID-10: %s | Repouso: %s dias] %s", data.cid10 or "N/A", data.leaveDays or 0, data.notes or "")
        })
        cb({ success = true, token = 'RX-' .. math.random(1000, 9999) })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('tabletDispensePrescription', function(data, cb)
    if data and data.token then
        TriggerServerEvent('loki_prescriptions:server:dispensePharmacyToken', data.token)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- Callbacks NUI para o Módulo de Reabilitação Física no Tablet
RegisterNUICallback('tabletGetRehabPatients', function(_, cb)
    local p = promise.new()
    local handler
    handler = RegisterNetEvent('loki_prescriptions:rehab:client:receiveNearbyPatients', function(list)
        RemoveEventHandler(handler)
        p:resolve(list or {})
    end)
    TriggerServerEvent('loki_prescriptions:rehab:server:requestNearbyPatients')
    SetTimeout(2000, function()
        if not p.value then
            RemoveEventHandler(handler)
            p:resolve({})
        end
    end)
    local result = Citizen.Await(p)
    cb(result)
end)

RegisterNUICallback('tabletApplyRehab', function(data, cb)
    if data and data.target and data.mode and data.duration then
        TriggerServerEvent('loki_prescriptions:rehab:server:apply', {
            target = data.target,
            mode = data.mode,
            duration = data.duration,
            progressive = data.progressive == true
        })
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('tabletRemoveRehab', function(data, cb)
    if data and data.target then
        TriggerServerEvent('loki_prescriptions:rehab:server:remove', data.target)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('tabletBandageRehab', function(data, cb)
    if data and data.target then
        TriggerServerEvent('loki_prescriptions:rehab:server:useBandage', data.target)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

CreateThread(function()
    Wait(2500)
    registerTabletApp()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName == 'vp_tablet' then
        Wait(1500)
        registerTabletApp()
    end
end)

-- Comando de atalho / fallback caso o médico queira abrir o EHR standalone
RegisterCommand('lsmc_ehr', function()
    local job = Framework.GetPlayerJob and Framework.GetPlayerJob() or 'ambulance'
    if Config.PrescriptionJobs then
        local allowed = false
        for _, v in ipairs(Config.PrescriptionJobs) do
            if v == job then
                allowed = true
                break
            end
        end
        if not allowed then
            lib.notify({ title = 'LSMC EHR', description = 'Acesso restrito ao corpo médico hospitalar.', type = 'error' })
            return
        end
    end

    if GetResourceState('haze_tablet') == 'started' then
        exports['haze_tablet']:OpenApp('loki_medical')
    else
        lib.notify({ title = 'LSMC EHR', description = 'Abra o tablet institucional para acessar o portal clínico.', type = 'info' })
    end
end, false)
