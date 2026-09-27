local ESX, QB, inv

if GetResourceState('qbx_core') == 'started' then
    -- Qbox nativo com suporte a exports diretos ou fallback para QB
    QB = exports['qb-core']:GetCoreObject()
elseif GetResourceState('qb-core') == 'started' then
    QB = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    ESX = exports["es_extended"]:getSharedObject()
end

-- Detecção de Inventário
if GetResourceState('ox_inventory') == 'started' then
    inv = 'ox'
elseif GetResourceState('qs-inventory') == 'started' then
    inv = 'qs'
elseif GetResourceState('qb-inventory') == 'started' then
    inv = 'qb'
end

-- Registro de itens usáveis baseados no framework
if ESX then
    ESX.RegisterUsableItem(Config.PrescriptionItem, function(src, item, properties)
        local meta = (properties and (properties.metadata or properties.info)) or (item and (item.info or item.metadata))
        ShowPrescription(src, meta)
    end)
    ESX.RegisterUsableItem(Config.PrescriptionPadItem, function(src)
        CreatePrescription(src)
    end)
elseif QB then
    QB.Functions.CreateUseableItem(Config.PrescriptionItem, function(src, item)
        local meta = item and (item.info or item.metadata)
        ShowPrescription(src, meta)
    end)
    QB.Functions.CreateUseableItem(Config.PrescriptionPadItem, function(src)
        CreatePrescription(src)
    end)
end

function SQL(query, params)
    return MySQL.query.await(query, params)
end

function GiveItem(src, item, count, metadata)
    count = count or 1
    if inv == 'ox' then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    elseif inv == 'qs' then
        return exports['qs-inventory']:AddItem(src, item, count, nil, metadata)
    elseif inv == 'qb' then
        return exports['qb-inventory']:AddItem(src, item, count, false, metadata, 'loki_prescriptions', false)
    end
    return false
end

function RemoveItem(src, item, metadata, slot)
    if inv == 'ox' then
        if slot then
            return exports.ox_inventory:RemoveItem(src, item, 1, nil, slot)
        end
        return exports.ox_inventory:RemoveItem(src, item, 1, metadata)
    elseif inv == 'qs' then
        return exports['qs-inventory']:RemoveItem(src, item, 1, nil, metadata)
    elseif inv == 'qb' then
        if slot then
            return exports['qb-inventory']:RemoveItem(src, item, 1, slot, "loki_prescriptions")
        end
        return exports['qb-inventory']:RemoveItem(src, item, 1, false, "loki_prescriptions")
    end
    return false
end

function UpdateItemMetadata(src, slot, metadata)
    if inv == 'ox' and slot then
        exports.ox_inventory:SetMetadata(src, slot, metadata)
        return true
    end
    return false
end

function CanCarryItem(src, item, count)
    count = count or 1
    if inv == 'ox' then
        return exports.ox_inventory:CanCarryItem(src, item, count)
    elseif inv == 'qb' then
        if QB then
            local xPlayer = QB.Functions.GetPlayer(src)
            if xPlayer and xPlayer.Functions.CanAddItem then
                return xPlayer.Functions.CanAddItem(item, count)
            end
        end
        return true
    elseif inv == 'qs' then
        if exports['qs-inventory'] and exports['qs-inventory'].CanCarryItem then
            return exports['qs-inventory']:CanCarryItem(src, item, count)
        end
        return true
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.canCarryItem then
            return xPlayer.canCarryItem(item, count)
        end
    end
    return true
end

function RemovePlayerMoney(src, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        local money = xPlayer.getAccount('bank').money
        if money < amount then return false end
        xPlayer.removeAccountMoney('bank', amount)
        return true
    elseif QB then
        local xPlayer = QB.Functions.GetPlayer(src)
        if not xPlayer then return false end
        if xPlayer.PlayerData.money.bank < amount then return false end
        xPlayer.Functions.RemoveMoney('bank', amount, 'pharmacy_prescription')
        return true
    end
    return false
end

function DepositHospitalMoney(amount)
    if not Config.EnableHospitalProfit or not amount or amount <= 0 then return end
    local account = Config.HospitalAccount or 'ambulance'

    if GetResourceState('Renewed-Banking') == 'started' then
        pcall(function()
            exports['Renewed-Banking']:addAccountMoney(account, amount)
        end)
    elseif GetResourceState('qb-banking') == 'started' then
        pcall(function()
            exports['qb-banking']:AddMoney(account, amount, 'Venda de Medicamentos (Farmácia)')
        end)
    elseif GetResourceState('esx_addonaccount') == 'started' then
        pcall(function()
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. account, function(acc)
                if acc then acc.addMoney(amount) end
            end)
        end)
    end
end

function GetPlayerIdentifier(src)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getIdentifier() or GetPlayerIdentifierByType(src, 'license')
    elseif QB then
        local xPlayer = QB.Functions.GetPlayer(src)
        return xPlayer and xPlayer.PlayerData.citizenid or GetPlayerIdentifierByType(src, 'license')
    else
        return GetPlayerIdentifierByType(src, 'license')
    end
end

function GetCharacterName(src)
    if QB then
        local xPlayer = QB.Functions.GetPlayer(src)
        if xPlayer and xPlayer.PlayerData and xPlayer.PlayerData.charinfo then
            local info = xPlayer.PlayerData.charinfo
            return (info.firstname or '') .. ' ' .. (info.lastname or '')
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.getName()
        end
    end
    return GetPlayerName(src)
end

function GetPlayerJob(src)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getJob().name
    elseif QB then
        local xPlayer = QB.Functions.GetPlayer(src)
        return xPlayer and xPlayer.PlayerData.job.name
    end
    return nil
end

function HasItem(src, item)
    if inv == 'ox' then
        local count = exports.ox_inventory:Search(src, 'count', item)
        return count and count > 0
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.hasItem(item)
    elseif QB then
        local xPlayer = QB.Functions.GetPlayer(src)
        return xPlayer and xPlayer.Functions.HasItem(item, 1)
    end
    return false
end

function GetItem(src, item)
    if inv == 'ox' then
        local items = exports.ox_inventory:Search(src, 'slots', item)
        if items then
            for slot, data in pairs(items) do
                if data and (data.count or 0) > 0 then
                    data.slot = slot
                    return data
                end
            end
        end
        return nil
    elseif inv == 'qb' then
        local items = exports['qb-inventory']:GetItemsByName(src, item)
        return items and items[1] or nil
    elseif inv == 'qs' then
        local inventory = exports['qs-inventory']:GetInventory(src)
        if inventory then
            for slot, data in pairs(inventory) do
                if data and data.name == item then
                    data.slot = slot
                    return data
                end
            end
        end
        return nil
    end
    return nil
end