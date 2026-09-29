--[[
    ============================================================================
    Native Bridge Server for Medical & Clinical Hub
    Provides complete compatibility with QBox Core, ox_inventory, oxmysql & Renewed-Banking
    ============================================================================
]]

Bridge = Bridge or {}
Bridge.Framework = Bridge.Framework or {}
Bridge.Inventory = Bridge.Inventory or {}
Bridge.Notify = Bridge.Notify or {}
Bridge.Society = Bridge.Society or {}
Bridge.Logs = Bridge.Logs or {}
Bridge.Debug = function(...)
    if Config and Config.Debug then
        print('^2[MedicalHub:Debug]^7', ...)
    end
end

-- ============================================================================
-- Framework (Server)
-- ============================================================================
function Bridge.Framework.getPlayerById(source)
    if not source or source <= 0 then return nil end
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayer(source)
    elseif GetResourceState('qb-core') == 'started' then
        local QB = exports['qb-core']:GetCoreObject()
        return QB.Functions.GetPlayer(source)
    end
    return nil
end

function Bridge.Framework.getPlayerJob(source)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.PlayerData and player.PlayerData.job then
        return {
            name = player.PlayerData.job.name or 'unemployed',
            label = player.PlayerData.job.label or 'Desempregado',
            grade = type(player.PlayerData.job.grade) == 'table' and (player.PlayerData.job.grade.level or 0) or tonumber(player.PlayerData.job.grade) or 0
        }
    end
    return { name = 'unemployed', label = 'Desempregado', grade = 0 }
end

function Bridge.Framework.getUniqueId(source)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.PlayerData then
        return player.PlayerData.citizenid or GetPlayerIdentifierByType(source, 'license')
    end
    return GetPlayerIdentifierByType(source, 'license') or tostring(source)
end

function Bridge.Framework.getPlayerName(source)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.PlayerData and player.PlayerData.charinfo then
        local c = player.PlayerData.charinfo
        return (c.firstname or '') .. ' ' .. (c.lastname or '')
    end
    return GetPlayerName(source) or 'Desconhecido'
end

function Bridge.Framework.addMoney(source, moneyType, amount, reason)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.Functions and player.Functions.AddMoney then
        return player.Functions.AddMoney(moneyType or 'bank', tonumber(amount) or 0, reason or 'hospital_service')
    end
    return false
end

function Bridge.Framework.removeMoney(source, moneyType, amount, reason)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.Functions and player.Functions.RemoveMoney then
        return player.Functions.RemoveMoney(moneyType or 'bank', tonumber(amount) or 0, reason or 'hospital_fee')
    end
    return false
end

function Bridge.Framework.getMoney(source, moneyType)
    local player = Bridge.Framework.getPlayerById(source)
    if player and player.PlayerData and player.PlayerData.money then
        return player.PlayerData.money[moneyType or 'bank'] or 0
    end
    return 0
end

function Bridge.Framework.registerItem(itemName, callback)
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:CreateUseableItem(itemName, callback)
    elseif GetResourceState('qb-core') == 'started' then
        local QB = exports['qb-core']:GetCoreObject()
        QB.Functions.CreateUseableItem(itemName, callback)
    end
end

function Bridge.Framework.getJobs()
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetJobs() or {}
    elseif GetResourceState('qb-core') == 'started' then
        local QB = exports['qb-core']:GetCoreObject()
        return QB.Shared.Jobs or {}
    end
    return {}
end

-- ============================================================================
-- Inventory (Server)
-- ============================================================================
function Bridge.Inventory.addItem(source, itemName, count, metadata)
    count = tonumber(count) or 1
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, itemName, count, metadata)
    end
    return false
end

function Bridge.Inventory.removeItem(source, itemName, count, metadata, slot)
    count = tonumber(count) or 1
    if GetResourceState('ox_inventory') == 'started' then
        if slot then
            return exports.ox_inventory:RemoveItem(source, itemName, count, nil, slot)
        end
        return exports.ox_inventory:RemoveItem(source, itemName, count, metadata)
    end
    return false
end

function Bridge.Inventory.getItemCount(source, itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search(source, 'count', itemName)
        return count or 0
    end
    return 0
end

function Bridge.Inventory.getPlayerItems(source)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetInventoryItems(source) or {}
    end
    return {}
end

function Bridge.Inventory.CustomDrop(title, items, coords)
    if GetResourceState('ox_inventory') == 'started' then
        -- Cria drop customizado no ox_inventory
        pcall(function()
            exports.ox_inventory:CustomDrop(title, items, coords)
        end)
    end
end

-- ============================================================================
-- Notifications (Server)
-- ============================================================================
function Bridge.Notify.showNotify(source, msg, ntype)
    if not source or source <= 0 then return end
    ntype = ntype == 'info' and 'inform' or (ntype or 'inform')
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hospital Central',
        description = msg,
        type = ntype
    })
end

-- ============================================================================
-- Society / Hospital Account (Server)
-- ============================================================================
function Bridge.Society.addMoney(source, societyAccount, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    societyAccount = societyAccount or (Config and Config.HospitalAccount) or 'ambulance'

    if GetResourceState('aust_banking') == 'started' then
        pcall(function()
            exports['aust_banking']:addAccountMoney(societyAccount, amount)
        end)
    elseif GetResourceState('Renewed-Banking') == 'started' then
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney(societyAccount, amount)
        end)
    elseif GetResourceState('qb-banking') == 'started' then
        pcall(function()
            exports['qb-banking']:AddMoney(societyAccount, amount, reason or 'Serviço Hospitalar')
        end)
    end
end

-- ============================================================================
-- Logs (Server)
-- ============================================================================
function Bridge.Logs.Send(source, action, description, webhook)
    local name = Bridge.Framework.getPlayerName(source)
    local cid = Bridge.Framework.getUniqueId(source)
    Bridge.Debug(('LOG [%s] (%s | %s): %s'):format(action, name, cid, description))
end
