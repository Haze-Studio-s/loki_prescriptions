local ESX, QB
local playerDoses = {}

if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
    QB = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    ESX = exports["es_extended"]:getSharedObject()
end

local function checkOverdose(src)
    if not Config.Overdose or not Config.Overdose.enabled then return false end
    local now = os.time()
    playerDoses[src] = playerDoses[src] or {}
    
    -- Filtra apenas doses dentro da janela avaliada (ex: 60s)
    local recent = {}
    for _, t in ipairs(playerDoses[src]) do
        if (now - t) <= (Config.Overdose.windowSeconds or 60) then
            table.insert(recent, t)
        end
    end
    table.insert(recent, now)
    playerDoses[src] = recent

    return #recent >= (Config.Overdose.threshold or 3)
end

local function handleDstCure(src, med)
    if not med or not med.cure_dst then return end
    if GetResourceState('aurp_put') ~= 'started' then return end
    pcall(function()
        if exports['aurp_put'] and exports['aurp_put'].CurePlayer then
            exports['aurp_put']:CurePlayer(src, med.cure_dst)
        end
    end)
end

-- Registro automático de todos os medicamentos configurados
CreateThread(function()
    Wait(1000)
    for _, med in ipairs(Config.Medicine) do
        local itemName = med.item

        if QB then
            QB.Functions.CreateUseableItem(itemName, function(src, item)
                local hasIt = HasItem(src, itemName)
                if not hasIt then return end

                local removed = RemoveItem(src, itemName, nil, item and item.slot)
                if removed then
                    local isOverdose = checkOverdose(src)
                    TriggerClientEvent('loki_prescriptions:client:applyMedicineEffects', src, med, isOverdose)
                    
                    handleDstCure(src, med)

                    if VpNeedsBridge then
                        VpNeedsBridge.ApplyMedicineEffects(src, med)
                    elseif Config.EnableVpNeedsIntegration and med.vp_effects and med.vp_effects.stress and med.vp_effects.stress < 0 then
                        pcall(function()
                            if exports.vp_needs and exports.vp_needs.RelieveStress then
                                exports.vp_needs:RelieveStress(src, math.abs(med.vp_effects.stress))
                            end
                        end)
                    end

                    local msg = _U('usedMedicine', med.label)
                    TriggerClientEvent('loki_prescriptions:oxNotify', src, _U('pharmacy'), msg, 'success')

                    if isOverdose then
                        TriggerClientEvent('loki_prescriptions:oxNotify', src, 'Emergência', _U('overdoseWarning'), 'error')
                    end
                end
            end)
        elseif ESX then
            ESX.RegisterUsableItem(itemName, function(src, item, properties)
                local hasIt = HasItem(src, itemName)
                if not hasIt then return end

                local slot = properties and properties.slot or (item and item.slot)
                local removed = RemoveItem(src, itemName, nil, slot)
                if removed then
                    local isOverdose = checkOverdose(src)
                    TriggerClientEvent('loki_prescriptions:client:applyMedicineEffects', src, med, isOverdose)
                    
                    handleDstCure(src, med)
                    
                    if VpNeedsBridge then
                        VpNeedsBridge.ApplyMedicineEffects(src, med)
                    elseif Config.EnableVpNeedsIntegration and med.vp_effects and med.vp_effects.stress and med.vp_effects.stress < 0 then
                        pcall(function()
                            if exports.vp_needs and exports.vp_needs.RelieveStress then
                                exports.vp_needs:RelieveStress(src, math.abs(med.vp_effects.stress))
                            end
                        end)
                    end

                    local msg = _U('usedMedicine', med.label)
                    TriggerClientEvent('loki_prescriptions:oxNotify', src, _U('pharmacy'), msg, 'success')

                    if isOverdose then
                        TriggerClientEvent('loki_prescriptions:oxNotify', src, 'Emergência', _U('overdoseWarning'), 'error')
                    end
                end
            end)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerDoses[src] = nil
end)