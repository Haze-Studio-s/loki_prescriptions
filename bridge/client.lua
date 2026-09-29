--[[
    ============================================================================
    Native Bridge Client for Medical & Clinical Hub
    Provides complete compatibility with QBox Core, ox_inventory, ox_target & ox_lib
    ============================================================================
]]

Bridge = Bridge or {}
Bridge.Framework = Bridge.Framework or {}
Bridge.Inventory = Bridge.Inventory or {}
Bridge.Target = Bridge.Target or {}
Bridge.Notify = Bridge.Notify or {}
Bridge.Progress = Bridge.Progress or {}
Bridge.Debug = function(...)
    if Config and Config.Debug then
        print('^2[MedicalHub:Debug]^7', ...)
    end
end

-- Compatibilidade com referências legadas a `Death.deathType` e `Death.inVehicle`
Death = Death or setmetatable({
    inVehicle = false,
}, {
    __index = function(t, k)
        if k == 'deathType' then
            if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isDead then
                return 'death'
            end
            if GetResourceState('qbx_core') == 'started' then
                local ok, pData = pcall(function() return exports.qbx_core:GetPlayerData() end)
                if ok and pData and pData.metadata then
                    if pData.metadata.isdead then return 'death' end
                    if pData.metadata.inlaststand then return 'bleeding' end
                end
            end
            return 'none'
        end
        return rawget(t, k)
    end
})

-- ============================================================================
-- Framework (Client)
-- ============================================================================
function Bridge.Framework.fetchPlayerJob()
    if GetResourceState('qbx_core') == 'started' then
        local pData = exports.qbx_core:GetPlayerData()
        if pData and pData.job then
            return {
                name = pData.job.name or 'unemployed',
                label = pData.job.label or 'Desempregado',
                grade = type(pData.job.grade) == 'table' and (pData.job.grade.level or 0) or tonumber(pData.job.grade) or 0
            }
        end
    elseif GetResourceState('qb-core') == 'started' then
        local QB = exports['qb-core']:GetCoreObject()
        local pData = QB.Functions.GetPlayerData()
        if pData and pData.job then
            return {
                name = pData.job.name or 'unemployed',
                label = pData.job.label or 'Desempregado',
                grade = type(pData.job.grade) == 'table' and (pData.job.grade.level or 0) or tonumber(pData.job.grade) or 0
            }
        end
    end
    return { name = 'unemployed', label = 'Desempregado', grade = 0 }
end

function Bridge.Framework.isPlayerLoaded()
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:IsPlayerLoaded()
    end
    return LocalPlayer.state.isLoggedIn or false
end

-- ============================================================================
-- Inventory (Client)
-- ============================================================================
function Bridge.Inventory.getItemCount(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', itemName)
        return count or 0
    end
    return 0
end

function Bridge.Inventory.getItemData(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local item = exports.ox_inventory:Items(itemName)
        if item then
            return {
                name = item.name,
                label = item.label,
                description = item.description or '',
                image = item.name .. '.png'
            }
        end
    end
    return { name = itemName, label = itemName, description = '', image = itemName .. '.png' }
end

-- ============================================================================
-- Target (Client)
-- ============================================================================
function Bridge.Target.addGlobal(options)
    if GetResourceState('ox_target') == 'started' then
        local opts = {}
        for _, opt in ipairs(options) do
            table.insert(opts, {
                name = opt.name or opt.label,
                label = opt.label,
                icon = opt.icon or 'fa-solid fa-hand-holding-medical',
                distance = opt.distance or 2.0,
                onSelect = opt.onSelect,
                canInteract = opt.canInteract,
                groups = opt.groups
            })
        end
        exports.ox_target:addGlobalPlayer(opts)
    end
end

function Bridge.Target.addPlayer(options)
    Bridge.Target.addGlobal(options)
end

function Bridge.Target.addVehicle(options)
    if GetResourceState('ox_target') == 'started' then
        local opts = {}
        for _, opt in ipairs(options) do
            table.insert(opts, {
                name = opt.name or opt.label,
                label = opt.label,
                icon = opt.icon or 'fa-solid fa-car',
                distance = opt.distance or 2.5,
                onSelect = function(data)
                    if opt.onSelect then
                        opt.onSelect(data.entity)
                    end
                end,
                canInteract = function(entity, distance, coords, name, bone)
                    if opt.canInteract then
                        return opt.canInteract(entity)
                    end
                    return true
                end,
                groups = opt.groups
            })
        end
        exports.ox_target:addGlobalVehicle(opts)
    end
end

function Bridge.Target.addModel(models, options)
    if GetResourceState('ox_target') == 'started' then
        local opts = {}
        for _, opt in ipairs(options) do
            table.insert(opts, {
                name = opt.name or opt.label,
                label = opt.label,
                icon = opt.icon or 'fa-solid fa-hand',
                distance = opt.distance or 2.0,
                onSelect = function(data)
                    if opt.onSelect then
                        opt.onSelect(data.entity)
                    end
                end,
                canInteract = function(entity, distance, coords, name, bone)
                    if opt.canInteract then
                        return opt.canInteract(entity)
                    end
                    return true
                end,
                groups = opt.groups
            })
        end
        exports.ox_target:addModel(models, opts)
    end
end

function Bridge.Target.addEntity(entity, options)
    if GetResourceState('ox_target') == 'started' then
        local opts = {}
        for _, opt in ipairs(options) do
            table.insert(opts, {
                name = opt.name or opt.label,
                label = opt.label,
                icon = opt.icon or 'fa-solid fa-hand',
                distance = opt.distance or 2.0,
                onSelect = function(data)
                    if opt.onSelect then
                        opt.onSelect(entity)
                    end
                end,
                canInteract = function()
                    if opt.canInteract then
                        return opt.canInteract(entity)
                    end
                    return true
                end,
                groups = opt.groups
            })
        end
        exports.ox_target:addLocalEntity(entity, opts)
    end
end

-- ============================================================================
-- Notifications & Progress (Client)
-- ============================================================================
function Bridge.Notify.showNotify(msg, ntype)
    if type(msg) == 'string' then
        ntype = ntype == 'info' and 'inform' or (ntype or 'inform')
        if lib and lib.notify then
            lib.notify({
                title = 'Hospital Central',
                description = msg,
                type = ntype
            })
        end
    end
end

function Bridge.Progress.Start(data)
    if lib and lib.progressBar then
        return lib.progressBar({
            duration = data.duration or 3000,
            label = data.label or 'Em andamento...',
            useWhileDead = data.useWhileDead or false,
            canCancel = data.canCancel ~= false,
            disable = data.disable or { move = true, car = true, combat = true },
            anim = data.anim,
            prop = data.prop
        })
    end
    Wait(data.duration or 3000)
    return true
end

function Bridge.Progress.StartCircle(data)
    if lib and lib.progressCircle then
        return lib.progressCircle({
            duration = data.duration or 3000,
            label = data.label or 'Em andamento...',
            position = data.position or 'bottom',
            useWhileDead = data.useWhileDead or false,
            canCancel = data.canCancel ~= false,
            disable = data.disable or { move = true, car = true, combat = true },
            anim = data.anim,
            prop = data.prop
        })
    end
    return Bridge.Progress.Start(data)
end
