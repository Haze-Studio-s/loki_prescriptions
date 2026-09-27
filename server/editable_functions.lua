-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK ð€ð¤ ð‹ðžðšð¤ð¬ 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

if not locale then
    locale = function(k, ...)
        if lib and lib.locale then
            local res = lib.locale(k)
            if res and res ~= k then
                if ... then
                    return string.format(res, ...)
                end
                return res
            end
        end
        return k
    end
end

Editable = {}
Editable.cooldowns = {}

-- Drop items on death
RegisterNetEvent('p_ambulancejob/server/death/dropItems', function()
    local dropItemsData = Config.Death and Config.Death.stages and Config.Death.stages['death'] and Config.Death.stages['death'].dropItems
    if not (dropItemsData and dropItemsData.enabled) then return end

    local _source = source
    local plyItems = Bridge.Inventory.getPlayerItems(_source)
    local droppedItems = {}
    local index = 1
    for k, v in pairs(plyItems) do
        if not dropItemsData.whitelistItems[v.name] then
            if not v.count then
                v.count = v.amount or 1 -- to avoid any issues with reading item count from other inventories
            end
            
            Bridge.Inventory.removeItem(_source, v.name, v.count, v.metadata, v.slot)
            if dropItemsData.dropType == "stash" then
                droppedItems[index] = {v.name, v.count, v.metadata}
                index = index + 1
            end
        end
    end

    if #droppedItems > 0 then
        Bridge.Inventory.CustomDrop(Bridge.Framework.getPlayerName(_source), droppedItems, GetEntityCoords(GetPlayerPed(_source)))
    end
end)

-- ITS ONLY FOR OUR PIOTREQ_GMT DISPATCH SYSTEM! CHANGE YOUR DISPATCH IN P_BRIDGE CONFIG!
RegisterNetEvent('p_ambulancejob/server/editable/alert', function() 
    local _source = source
    local coords = GetEntityCoords(GetPlayerPed(_source))
    if GetResourceState('vms_housing') == 'started' then
        local playerProperty = exports['vms_housing']:GetPlayerCurrentProperty(source)
        if playerProperty then
            local property = exports['vms_housing']:GetProperty(playerProperty)
            if property.object_id then
                local building = exports['vms_housing']:GetProperty(property.object_id)
                if building.type == 'building' then
                    property = building
                end
            end
            if property.metadata and property.metadata.exit then
                coords = property.metadata.exit
            end
        end
    end

    if GetResourceState('piotreq_gmt') == 'started' then
        exports['piotreq_gmt']:SendAlert(_source, {
            title = 'Report',
            code = '911',
            icon = 'fa-solid fa-mask',
            info = {
               {icon = 'fa-solid fa-road', isStreet = true},
               {icon = 'fa-solid fa-triangle-exclamation', data = Bridge.Framework.getPlayerName(_source)},
            },
            jobs = {['ambulance'] = true}, -- optional
            blip = { -- optional
                scale = 1.1,
                sprite = 1,
                category = 3, -- default 1
                color = 1,
                hidden = false, -- default false (hidden on legend)
                priority = 5, -- default 5
                short = true, -- as short range? default true
                alpha = 200, -- default 255
                name = "Report"
            },
            coords = coords,
            type = 'normal', -- default normal
            canAnswer = true, -- default false
            maxOfficers = 4, -- default 4
            time = 5,-- 10 minutes, default 5
            notifyTime = 8000, -- 8 seconds, default 7
        })
    elseif GetResourceState('pp-ems-mdt') == 'started' then
        exports['pp-ems-mdt']:AddDispatchCall({
            title = 'Report',
            description = '911',
            showCitizen = 'name',
            coords = coords,
            duration = 5 * 60000,
            blip = {
                color = 1,
                sprite = 1,
                scale = 0.8,
            },
            code = {
                code = '911',
                color = 'red'
            },
            flash = true,
        }, _source)
    end
end)

-- only for integration with vms housing for alerts
lib.callback.register('p_ambulancejob/server/editable/getPlyCoords', function(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    if GetResourceState('vms_housing') == 'started' then
        local playerProperty = exports['vms_housing']:GetPlayerCurrentProperty(source)
        if playerProperty then
            local property = exports['vms_housing']:GetProperty(playerProperty)
            if property.object_id then
                local building = exports['vms_housing']:GetProperty(property.object_id)
                if building.type == 'building' then
                    property = building
                end
            end
            if property.metadata and property.metadata.exit then
                coords = property.metadata.exit
            end
        end
    end

    return coords
end)

lib.addCommand('911', {
    help = locale('command_911_help'),
    params = {
        {
            name = 'message',
            type = 'longString',
            help = locale('message_to_send'),
        },
    },
}, function(source, args, raw)
    local _source = source
    if Editable.cooldowns[_source] and Editable.cooldowns[_source] > os.time() then
        Bridge.Notify.showNotify(_source, locale('command_911_cooldown'), 'error')
        return
    end

    Editable.cooldowns[_source] = os.time() + 30
    local message = args.message
    if Config.Alerts.enabled then
        Alerts:new(_source, {
            code = '911',
            title = locale('alert_911'),
            message = message,
            coords = GetEntityCoords(GetPlayerPed(_source)),
            expire = 300,
            blip = {
                sprite = 480,
                color = 1,
                scale = 1.0,
                text = locale('alert_911')
            }
        })
    else
        if Bridge.Dispatch and Bridge.Dispatch.SendAlert then
            Bridge.Dispatch.SendAlert({
                job = {'ambulance'},
                code = '911',
                title = locale('alert_911'),
                time = 60,
                priority = 'normal',
                icon = 'fa solid fa-skull',
                blip = {
                    sprite = 153,
                    color = 1,
                    scale = 1.1,
                    name = locale('alert_911'),
                }
            })
        elseif GetResourceState('piotreq_gmt') == 'started' then
            exports['piotreq_gmt']:SendAlert(_source, {
                title = locale('alert_911'),
                code = '911',
                icon = 'fa-solid fa-mask',
                info = {
                   {icon = 'fa-solid fa-road', isStreet = true},
                   {icon = 'fa-solid fa-triangle-exclamation', data = Bridge.Framework.getPlayerName(_source)},
                },
                jobs = {['ambulance'] = true}, -- optional
                blip = { -- optional
                    scale = 1.1,
                    sprite = 1,
                    category = 3, -- default 1
                    color = 1,
                    hidden = false, -- default false (hidden on legend)
                    priority = 5, -- default 5
                    short = true, -- as short range? default true
                    alpha = 200, -- default 255
                    name = locale('alert_911')
                },
                type = 'normal', -- default normal
                canAnswer = true, -- default false
                maxOfficers = 4, -- default 4
                time = 5,-- 10 minutes, default 5
                notifyTime = 8000, -- 8 seconds, default 7
            })
        end
    end

end)

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' or type(eventData.id) ~= 'number' then
		return
	end

	TriggerClientEvent('p_ambulancejob/client/death/revive', eventData.id)
end)

function Editable:frameworkDeathSave(playerId, data)
    if GetResourceState('es_extended') == 'started' then
        local identifier = Bridge.Framework.getUniqueId(playerId)
        local success, result = pcall(MySQL.update, 'UPDATE users SET is_dead = ? WHERE identifier = ?', {data.type ~= 'none' and true or false, identifier})
    elseif GetResourceState('qb-core') == 'started' then -- works for qbx_core too :)
        local player = Bridge.Framework.getPlayerById(playerId)
        if player then
            player.Functions.SetMetaData('isdead', data.type == 'death' and true or false)
            player.Functions.SetMetaData('inlaststand', data.type == 'bleeding' and true or false)
        end
    end
end

function Editable:frameworkDataSave(identifier, data)
    if GetResourceState('es_extended') == 'started' then
        MySQL.update('UPDATE users SET ambulanceData = ? WHERE identifier = ?', {json.encode(data), identifier})
    elseif GetResourceState('qb-core') == 'started' then -- works for qbx_core too :)
        MySQL.update('UPDATE players SET ambulanceData = ? WHERE citizenid = ?', {json.encode(data), identifier})
    end
end

function Editable:frameworkDataFetch(playerId)
    local identifier = Bridge.Framework.getUniqueId(playerId)
    if GetResourceState('es_extended') == 'started' then
        local row = MySQL.single.await('SELECT ambulanceData FROM users WHERE identifier = ?', {identifier})
        return row and json.decode(row.ambulanceData) or nil
    elseif GetResourceState('qb-core') == 'started' then -- works for qbx_core too :)
        local row = MySQL.single.await('SELECT ambulanceData FROM players WHERE citizenid = ?', {identifier})
        return row and json.decode(row.ambulanceData) or nil
    end
    return nil
end

function Editable:frameworkSetDuty(playerId, state)
    if GetResourceState('es_extended') == 'started' then
        local player = Bridge.Framework.getPlayerById(playerId)
        if player then
            player.setJob(player.job.name, player.job.grade, state)
        end
    elseif GetResourceState('qb-core') == 'started' then -- works for qbx_core too :)
        local player = Bridge.Framework.getPlayerById(playerId)
        if player then
            player.Functions.SetJobDuty(state)
        end
    end
    Bridge.Notify.showNotify(playerId, locale('duty_changed_'..(state and 'on' or 'off')), 'success')
end

RegisterNetEvent('p_ambulancejob/server/editable/setDuty', function(state)
    local _source = source
    Editable:frameworkSetDuty(_source, state)
end)

Editable.allJobs = {}
Editable.playersOnDuty = {}
Editable.medicsCount = 0
GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount

Citizen.CreateThread(function()
    for k, v in pairs(Config.Hospitals) do
        for _, jobName in pairs(v.jobs) do
            Editable.allJobs[jobName] = 0
        end
    end
end)

if GetResourceState('es_extended') ~= 'missing' then
    AddEventHandler('esx:playerLoaded', function(player, xPlayer)
        local jobName = xPlayer and xPlayer.job and xPlayer.job.name
        if not jobName then return end
        if Editable.allJobs[jobName] then
            Editable.playersOnDuty[player] = jobName
            Editable.medicsCount = Editable.medicsCount + 1
            GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
        end
    end)

    AddEventHandler('esx:setJob', function(player, job)
        local jobName = job.name
        if not jobName then return end
        if Editable.allJobs[jobName] and not Editable.playersOnDuty[player] then
            Editable.playersOnDuty[player] = jobName
            Editable.medicsCount = Editable.medicsCount + 1
            GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
        elseif Editable.playersOnDuty[player] and not Editable.allJobs[jobName] then
            Editable.playersOnDuty[player] = nil
            Editable.medicsCount = math.max(0, Editable.medicsCount - 1)
            GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
        end
    end)

    AddEventHandler('esx:playerDropped', function(player)
        if Editable.playersOnDuty[player] then
            Editable.playersOnDuty[player] = nil
            Editable.medicsCount = math.max(0, Editable.medicsCount - 1)
            GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
        end
    end)

    Citizen.CreateThread(function()
        -- on script restart
        Citizen.Wait(2500)
        local ESX = exports['es_extended']:getSharedObject()
        local players = ESX.GetExtendedPlayers()
        for _, player in pairs(players) do
            if Editable.allJobs[player.job.name] then
                Editable.playersOnDuty[player.source] = player.job.name
                Editable.medicsCount = Editable.medicsCount + 1
            end
        end
        GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
    end)
elseif GetResourceState('qb-core') ~= 'missing' then -- works for qbx_core too :)
    AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        Citizen.Wait(1000)
        local player = Bridge.Framework.getPlayerById(src)
        if player and player.PlayerData then
            local jobName = player.PlayerData.job.name
            if Editable.allJobs[jobName] and player.PlayerData.job.onduty and not Editable.playersOnDuty[src] then
                Editable.medicsCount = Editable.medicsCount + 1
                GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
                Editable.playersOnDuty[src] = jobName
            end
        end
    end)
    
    AddEventHandler('QBCore:Server:PlayerLoggedOut', function()
        local src = source
        local player = Bridge.Framework.getPlayerById(src)
        if player and player.PlayerData then
            local jobName = player.PlayerData.job.name
            if Editable.allJobs[jobName] and player.PlayerData.job.onduty and Editable.playersOnDuty[src] then
                Editable.medicsCount = math.max(0, Editable.medicsCount - 1)
                GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
                Editable.playersOnDuty[src] = nil
            end
        end
    end)
    
    AddEventHandler('QBCore:Server:SetDuty', function(source, onDuty)
        local src = source
        local player = Bridge.Framework.getPlayerById(src)
        if player and player.PlayerData then
            local jobName = player.PlayerData.job.name
            if Editable.allJobs[jobName] then
                if onDuty then
                    Editable.medicsCount = Editable.medicsCount + 1
                    Editable.playersOnDuty[src] = jobName
                elseif Editable.playersOnDuty[src] then
                    Editable.playersOnDuty[src] = nil
                    Editable.medicsCount = Editable.medicsCount - 1
                end
                GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
            elseif Editable.playersOnDuty[src] then
                Editable.playersOnDuty[src] = nil
                Editable.medicsCount = math.max(0, Editable.medicsCount - 1)
                GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
            end
        end
    end)

    AddEventHandler('QBCore:Server:OnJobUpdate', function(playerId, newJob)
        local jobName = newJob.name
        if Editable.allJobs[jobName] then
            if newJob.onduty and not Editable.playersOnDuty[playerId] then
                Editable.playersOnDuty[playerId] = jobName
                Editable.medicsCount = Editable.medicsCount + 1
                GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
            end
        elseif Editable.playersOnDuty[playerId] and not Editable.allJobs[jobName] then
            Editable.playersOnDuty[playerId] = nil
            Editable.medicsCount = math.max(0, Editable.medicsCount - 1)
            GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
        end
    end)

    Citizen.CreateThread(function()
        -- on script restart
        Citizen.Wait(2500)
        local QBCore = exports['qb-core']:GetCoreObject()
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            if Editable.allJobs[player.PlayerData.job.name] and player.PlayerData.job.onduty then
                Editable.playersOnDuty[player.PlayerData.source] = player.PlayerData.job.name
                Editable.medicsCount = Editable.medicsCount + 1
            end
        end
        GlobalState['p_ambulancejob/medicsCount'] = Editable.medicsCount
    end)
end

local usableItems = {
    ['ambulance_gps'] = function(playerId)
        TriggerClientEvent('p_ambulancejob/client/gps/toggle', playerId)
    end,
    ['crutch'] = function(playerId)
        TriggerClientEvent('p_ambulancejob/client/crutch/menu', playerId)
    end,
    ['wheelchair'] = function(playerId)
        TriggerClientEvent('p_ambulancejob/client/wheelchair/menu', playerId)
    end,
    ['stretcher'] = function(playerId)
        TriggerClientEvent('p_ambulancejob/client/stretcher/create', playerId)
    end,
    ['defibrilator'] = function(playerId)
        TriggerClientEvent('p_ambulancejob/client/defibrilator/use', playerId)
    end
}

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    for medicBagName, items in pairs(Config.MedicBag.items) do
        usableItems[medicBagName] = function(playerId)
            TriggerClientEvent('p_ambulancejob/client/medicbag/use', playerId, medicBagName)
        end
    end

    for k, v in pairs(usableItems) do
        Bridge.Framework.registerItem(k, v)
    end
end)

lib.checkDependency('p_bridge', '1.1.0')
