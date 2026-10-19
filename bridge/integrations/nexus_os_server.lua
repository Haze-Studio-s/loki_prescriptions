--[[
    LOKI MEDICAL SUITE - NEXUS_OS INTEGRATION (SERVER)
    Ponte de comunicação para notificações push em smartphones e ecossistema NexusOS.
]]

NexusBridge = {}

function NexusBridge.IsActive()
    return GetResourceState('haze_os') == 'started'
end

--- Envia notificação push para o smartphone do jogador via NexusOS ou fallback ox_lib
---@param source number Source do jogador destinatário
---@param title string Título da notificação
---@param message string Mensagem explicativa
---@param appType string Categoria ('docs', 'health', 'general')
---@param metadata table|nil Metadados opcionais
function NexusBridge.SendNotification(source, title, message, appType, metadata)
    if not source or source <= 0 then return end

    if NexusBridge.IsActive() then
        local success = pcall(function()
            if exports['haze_os'] and exports['haze_os'].SendPhoneNotification then
                exports['haze_os']:SendPhoneNotification(source, title, message, appType or 'docs', metadata or {})
            else
                TriggerClientEvent('loki_prescriptions:oxNotify', source, title, message, 'inform')
            end
        end)
        if success then return end
    end

    -- Fallback via notificação padrão
    TriggerClientEvent('loki_prescriptions:oxNotify', source, title, message, 'inform')
end

-- Exporta globalmente para uso em outros módulos do Loki Medical Suite
exports('SendNexusNotification', function(source, title, message, appType, metadata)
    NexusBridge.SendNotification(source, title, message, appType, metadata)
end)
