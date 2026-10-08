--[[
    ============================================================================
    LUCAS 3 - Mechanical CPR Chest Compression System (Server)
    ============================================================================
]]

local activeLucasPatients = {}

RegisterNetEvent('loki_prescriptions:server:attachLucas3', function(targetServerId)
    local src = source
    if not src or src <= 0 then return end

    if not Bridge.Inventory.getItemCount(src, 'lucas3') or Bridge.Inventory.getItemCount(src, 'lucas3') < 1 then
        Bridge.Notify.showNotify(src, 'Você não possui o aparelho LUCAS 3.', 'error')
        return
    end

    -- Remove o aparelho do inventário do médico enquanto acoplado
    Bridge.Inventory.removeItem(src, 'lucas3', 1)
    activeLucasPatients[targetServerId] = src

    -- Sincroniza visualização do prop em todos os clientes
    TriggerClientEvent('loki_prescriptions:client:syncAttachLucas3', -1, targetServerId)
    Bridge.Notify.showNotify(src, 'LUCAS 3 acoplado ao tórax do paciente. Compressões ativas.', 'success')
    Bridge.Notify.showNotify(targetServerId, 'Um compressor torácico LUCAS 3 foi instalado em seu peito.', 'inform')
end)

RegisterNetEvent('loki_prescriptions:server:removeLucas3', function(targetServerId)
    local src = source
    if not src or src <= 0 then return end

    activeLucasPatients[targetServerId] = nil
    TriggerClientEvent('loki_prescriptions:client:syncRemoveLucas3', -1, targetServerId)

    -- Devolve o aparelho para o inventário do socorrista
    Bridge.Inventory.addItem(src, 'lucas3', 1)
    Bridge.Notify.showNotify(src, 'LUCAS 3 desinstalado e guardado.', 'inform')
end)

-- Registro do item utilizável
Bridge.Framework.registerItem('lucas3', function(source)
    TriggerClientEvent('loki_prescriptions:client:useLucas3', source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeLucasPatients[src] then
        local medicSrc = activeLucasPatients[src]
        Bridge.Inventory.addItem(medicSrc, 'lucas3', 1)
        activeLucasPatients[src] = nil
        TriggerClientEvent('loki_prescriptions:client:syncRemoveLucas3', -1, src)
    end
end)
