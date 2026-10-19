--[[
    LOKI MEDICAL SUITE - NEXUS_OS INTEGRATION (CLIENT)
    Registro do aplicativo 'LSMC — Portal de Saúde' no Desktop e App Store do NexusOS.
]]

local function registerNexusApp()
    if GetResourceState('haze_os') ~= 'started' then return end

    pcall(function()
        exports['haze_os']:RegisterApp({
            id          = 'loki_medical',
            title       = 'LSMC — Portal Clínico',
            icon        = 'fas fa-heartbeat',
            category    = 'government',
            badge       = 'Saúde',
            description = 'Portal oficial do Los Santos Medical Center: emissão de receituários eletrônicos, atestados médicos e diagnóstico por imagem.',
            minWidth    = 960,
            minHeight   = 620,
            requires    = {
                jobs = { 'ambulance', 'doctor' }
            },
            customAction = {
                closeLaptop = true,
                type        = 'client',
                event       = 'loki_prescriptions:client:openDoctorPortal'
            }
        })
    end)
end

-- Tenta registrar no boot ou quando o nexus_os for iniciado
CreateThread(function()
    Wait(2000)
    registerNexusApp()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName == 'nexus_os' then
        Wait(1000)
        registerNexusApp()
    end
end)

-- Menu do Portal Clínico acionado pelo NexusOS
RegisterNetEvent('loki_prescriptions:client:openDoctorPortal', function()
    lib.registerContext({
        id = 'loki_nexus_medical_portal',
        title = 'LSMC — Portal Clínico Corporativo',
        options = {
            {
                title = 'Bloco de Receituário Médico',
                description = 'Abrir a prancheta Lation UI para prescrever remédios ao paciente próximo.',
                icon = 'prescription',
                onSelect = function()
                    ExecuteCommand('receita')
                end
            },
            {
                title = 'Emissão de Atestado Médico',
                description = 'Homologar dispensa laboral e licença médica oficial.',
                icon = 'file-medical',
                onSelect = function()
                    ExecuteCommand('atestado')
                end
            },
            {
                title = 'Centro Radiográfico (Raio-X)',
                description = 'Iniciar exame fluoroscópico com feixe CRT no paciente.',
                icon = 'x-ray',
                onSelect = function()
                    local input = lib.inputDialog('Exame Radiográfico (Raio-X)', {
                        { type = 'number', label = 'ID do Paciente', required = true, min = 1 }
                    })
                    if input and input[1] then
                        ExecuteCommand(('raiox %s'):format(input[1]))
                    end
                end
            },
            {
                title = 'Exame Toxicológico Integrado',
                description = 'Aferir toxicidade sanguínea, alcoolemia e triagem de overdose.',
                icon = 'vial',
                onSelect = function()
                    ExecuteCommand('vertoxicologia')
                end
            },
            {
                title = 'Equipamento Móvel: Maca Fernocot',
                description = 'Requisitar ou recolher maca articulada de ambulância.',
                icon = 'bed-pulse',
                onSelect = function()
                    ExecuteCommand('maca')
                end
            }
        }
    })

    lib.showContext('loki_nexus_medical_portal')
end)
