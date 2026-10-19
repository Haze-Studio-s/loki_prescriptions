--[[
    LOKI MEDICAL SUITE - VP_TABLET INTEGRATION (SERVER)
    Comunicação direta com o MDT de paramédicos e despacho tático (vp_tablet).
]]

VpTabletBridge = {}

function VpTabletBridge.IsActive()
    return GetResourceState('haze_tablet') == 'started'
end

--- Envia notificação no aplicativo do tablet dos socorristas ou do paciente
---@param targetSource number ID do jogador
---@param title string Título do alerta
---@param message string Conteúdo explicativo
---@param appName string|nil Nome do app ('ambulance', 'mail', etc.)
function VpTabletBridge.SendNotification(targetSource, title, message, appName)
    if not targetSource or targetSource <= 0 then return false end
    if not VpTabletBridge.IsActive() then return false end

    local ok, res = pcall(function()
        if exports['haze_tablet'] and exports['haze_tablet'].SendNotification then
            exports['haze_tablet']:SendNotification({
                source = targetSource,
                app = appName or 'ambulance',
                title = title or 'LSMC Portal Clínico',
                content = message or 'Notificação clínica recebida.',
                duration = 6000
            })
            return true
        end
        return false
    end)

    return ok and res == true
end

--- Cria um chamado tático de emergência médica no despacho do tablet (10-47)
---@param title string Título do chamado
---@param description string Detalhes da ocorrência
---@param coords vector3 Coordenadas do incidente
---@param code string|nil Código penal/rádio (padrão: '10-47')
function VpTabletBridge.CreateDispatch(title, description, coords, code)
    if not VpTabletBridge.IsActive() or not coords then return false end

    local callCode = code or '10-47'
    local callTitle = title or 'Emergência Médica'
    local callDesc = description or 'Cidadão inconsciente com sinais vitais instáveis.'

    local ok, res = pcall(function()
        if exports['haze_tablet'] and exports['haze_tablet'].CreateDispatch then
            exports['haze_tablet']:CreateDispatch({
                code = callCode,
                title = callTitle,
                description = callDesc,
                coords = coords,
                job = 'ambulance',
                blip = {
                    sprite = 153,
                    color = 1,
                    scale = 1.0,
                    text = ('%s - %s'):format(callCode, callTitle)
                }
            })
            return true
        end
        return false
    end)

    return ok and res == true
end

--- Registra ocorrência médica ou receita no prontuário do paciente no tablet MDT
---@param patientCid string CitizenID do paciente
---@param doctorName string Nome do médico
---@param title string Título do registro (ex: 'Receituário Emitido')
---@param description string Detalhes clínicos e posologia
function VpTabletBridge.RecordAmbulanceReport(patientCid, doctorName, title, description)
    if not VpTabletBridge.IsActive() or not patientCid then return false end

    pcall(function()
        MySQL.insert([[
            INSERT INTO lbtablet_ambulance_reports (patient, title, `description`, report_type, created_by)
            VALUES (?, ?, ?, 'treatment', 1)
        ]], {
            patientCid,
            title or 'Registro Clínico LSMC',
            string.format('Emitido por: %s\n%s', doctorName or 'Corpo Médico', description or '')
        })
    end)
    return true
end

-- Exporta globalmente
exports('GetVpTabletBridge', function()
    return VpTabletBridge
end)
