--[[
    LOKI MEDICAL SUITE - VP_PHONE INTEGRATION (SERVER)
    Comunicação direta com o smartphone dos cidadãos (vp_phone).
    Despacha notificações no aplicativo nativo de Saúde (Health) ou Mail.
]]

VpPhoneBridge = {}

function VpPhoneBridge.IsActive()
    return GetResourceState('haze_phone') == 'started'
end

--- Envia uma notificação formatada para o smartphone do cidadão
---@param targetSource number ID do jogador destinatário
---@param title string Título da notificação (ex: 'LSMC Farmácia')
---@param message string Conteúdo do texto
---@param appName string|nil Nome do app ('Health', 'Mail', etc.)
---@return boolean Sucesso do envio
function VpPhoneBridge.SendNotification(targetSource, title, message, appName)
    if not targetSource or targetSource <= 0 then return false end
    if not VpPhoneBridge.IsActive() then return false end

    local ok, res = pcall(function()
        if exports['haze_phone'] and exports['haze_phone'].SendNotification then
            exports['haze_phone']:SendNotification(targetSource, {
                app = appName or 'Health',
                title = title or 'LSMC Saúde',
                content = message or 'Notificação clínica recebida.'
            })
            return true
        end
        return false
    end)

    return ok and res == true
end

--- Envia um alerta de emergência médica prioritário na tela de bloqueio
---@param targetSource number ID do jogador destinatário
---@param title string Título da emergência
---@param message string Conteúdo do alerta
function VpPhoneBridge.SendEmergency(targetSource, title, message)
    if not targetSource or targetSource <= 0 then return end
    if not VpPhoneBridge.IsActive() then return end

    pcall(function()
        if exports['haze_phone'] and exports['haze_phone'].EmergencyNotification then
            exports['haze_phone']:EmergencyNotification(targetSource, title or 'ALERTA MÉDICO', message or 'Condição crítica detectada.')
        elseif exports['haze_phone'] and exports['haze_phone'].SendAmberAlert then
            exports['haze_phone']:SendAmberAlert(title or 'ALERTA MÉDICO', message or 'Condição crítica detectada.')
        end
    end)
end

-- Exporta globalmente
exports('GetVpPhoneBridge', function()
    return VpPhoneBridge
end)
