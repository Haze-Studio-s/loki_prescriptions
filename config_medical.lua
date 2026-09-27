-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK ð€ð¤ ð‹ðžðšð¤ð¬ 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

Config = Config or {}

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

Config.Hospital = 'gabz_hospital'

Citizen.CreateThread(function()
    if type(Config.Hospital) == 'string' then
        local hospitalFile = lib.load(('hospitals.%s'):format(Config.Hospital))
        if not hospitalFile then return end

        Config.Hospitals = hospitalFile.Hospital
        Config.TV.points = hospitalFile.TV
        Config.CheckIn.points = hospitalFile.CheckIn
        Config.CheckIn.beds = hospitalFile.CheckInBeds
        Config.Insurance.points = hospitalFile.Insurances
        Config.Shops = hospitalFile.Shops
        Config.Garages = hospitalFile.Garages
        Config.Elevators.points = hospitalFile.Elevators
    elseif type(Config.Hospital) == 'table' then
        for k, v in pairs(Config.Hospital) do
            local hospitalFile = lib.load(('hospitals.%s'):format(v))
            if hospitalFile then
                lib.table.merge(Config.Hospitals, hospitalFile.Hospital)
                lib.table.merge(Config.TV.points, hospitalFile.TV)
                lib.table.merge(Config.CheckIn.points, hospitalFile.CheckIn)
                lib.table.merge(Config.CheckIn.beds, hospitalFile.CheckInBeds)
                lib.table.merge(Config.Insurance.points, hospitalFile.Insurances)
                lib.table.merge(Config.Shops, hospitalFile.Shops)
                lib.table.merge(Config.Garages, hospitalFile.Garages)
                lib.table.merge(Config.Elevators.points, hospitalFile.Elevators)
            end
        end
    else
        for k, v in pairs({'kiiya_hospital', 'fm_hospital', 'wxmaps_hospital', 'prompts_hospital', 'nteam_hospital', 'gabz_hospital', 'hane_hospital', 'fiv3devs_hospital', 'diables_hospital', 'ajaxon_hospital'}) do
            local hospitalFile = lib.load(('hospitals.%s'):format(v))
            if hospitalFile then
                lib.table.merge(Config.Hospitals, hospitalFile.Hospital)
                lib.table.merge(Config.TV.points, hospitalFile.TV)
                lib.table.merge(Config.CheckIn.points, hospitalFile.CheckIn)
                lib.table.merge(Config.CheckIn.beds, hospitalFile.CheckInBeds)
                lib.table.merge(Config.Insurance.points, hospitalFile.Insurances)
                lib.table.merge(Config.Shops, hospitalFile.Shops)
                lib.table.merge(Config.Garages, hospitalFile.Garages)
                lib.table.merge(Config.Elevators.points, hospitalFile.Elevators)
            end
        end
    end
end)

---@class Config.Hospitals: table<string, Hospital>
---@class Hospital
---@field jobs table<string> [which jobs are allowed to use this hospital]
---@field blip table {enabled: boolean, sprite: number, scale?: number, color: number, name: string} [blip settings]
---@field duty table {coords: vec4 [coords of duty point], ped?: string [ped model, remove to disable ped], anim?: table {dict: string [animation dictionary], clip: string [animation clip], flag?: number [animation flag, default 1]}, prop?: table {model: string [prop model], bone: number [bone index], coords: vec3 [prop position], rot: vec3 [prop rotation]}} [duty point settings]
-- Blip Reference: https://docs.fivem.net/docs/game-references/blips/
Config.Hospitals = {} -- will be filled in thread above

Config.Shops = {} -- will be filled in thread above
Config.Garages = {} -- will be filled in thread above

---@class Config.Alerts
---@field enabled boolean [enable alerts feature?]
---@field jobs table<string> [which jobs are allowed to see alerts]
---@field menuKey string | false [key to open alerts menu, false = none key]
---@field menuCommand string | false [command to open alerts menu, false = none command]
---@field autoResolveAlert boolean [should alerts auto resolve when player get medical assistance?]
Config.Alerts = {
    enabled = true,
    jobs = {'ambulance'},
    menuKey = 'F5',
    menuCommand = 'emsDispatch',
    autoResolveAlert = true
}

-- Minigames Médicos Interativos (Absorvidos do Pluto & Lation UI)
Config.InteractiveMinigames = {
    enabled = true,
    suture = true,          -- Sutura Cirúrgica Dinâmica em Canvas
    clamp = true,           -- Hemostasia e Anastomose Vascular
    bullet = true,          -- Extração Balística sem colisão arterial
    bp = true,              -- Esfigmomanômetro com tubo Bezier SVG
    bandage = true,         -- Curativo de Trauma em 3 Etapas (Assepsia, Gaze, 4x Fita)
    breathalyzer = true,    -- Etilômetro / Bafômetro Digital NUI sincronizado
    swipeCard = true,       -- Leitor de Cartão Magnético Hospitalar
}

---@class Config.TV
---@field enabled boolean [enable tv feature?]
---@field points table<string, table<string, TVPoint>> [list of tv points, string is unique name of hospital!]

---@class TVPoint
---@field coords vec3 [coords of tv, they should be at least 20.0 units away from other tv points in same hospital to avoid texture issues]
---@field rot vec3 [rotation of tv]
Config.TV = {
    enabled = true,
    points = {} -- will be filled in thread above
}

---@class Config.CheckIn
---@field enabled boolean [enable check-in feature?]
---@field canPayForOther boolean [can player pay for another players check-in? as option on target if close to checkin and dead]
---@field moneyIntoSociety boolean [should money from check-in go into society account?]
---@field points table<string, CheckInPoint> [list of check-in points, string is unique name!]
---@field beds table<string, vec4[]> [list of beds for each check-in point, string must be the same as in points!]

---@class CheckInPoint
---@field label string [display name of check-in point]
---@field coords vec4 [coords of point]
---@field ped string [ped model at point]
---@field duration number [time in ms for check-in progress]
---@field maxDutyMedics number | false [maximum medics on duty to enable check-in, false = can always use]
---@field price table<string, number> | false [price for check-in in different accounts, false = no payment]
Config.CheckIn = {
    enabled = true,
    canPayForOther = true,
    useTextUI = false, -- use textui instead of target for check-in?
    moneyIntoSociety = true, -- should money from check-in go into society account?
    camera = {
        enabled = true, -- enable script camera when checking in?
        offset = vec3(-1.5, 1.25, -0.65), -- offset from player coords [left/right, forward/back, up/down]
    },
    AiMedic = {
        enabled = true, -- enable AI medic? [will use ai medic instead of respawn menu]
        model = 's_m_m_paramedic_01', -- ped model of AI medic
        vehModel = 'ambulance', -- vehicle model of AI medic
        maxMedics = 2, -- if there is more than 2 real medics on duty, ai medic will doesnt work
    },
    onStart = function(hospitalName, spawnType) -- spawnType can be 'respawn' or 'check-in' [respawn means player used E on death]
        -- this code inside will execute when player start check-in
        return true
    end,
    onFinish = function(hospitalName, isRespawn) -- isRespawn = true/false
        -- this code inside will execute when player finish check-in
        local offset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.1, 1.5, 0.0)
        if hospitalName == 'fm_hospital' then
            offset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.35, 0.0, 0.1)
        end
        SetEntityCoordsNoOffset(cache.ped, offset.x, offset.y, offset.z, true, true, true)
    end,
    points = {}, -- will be filled in thread above
    beds = {} -- will be filled in thread above
}

Citizen.CreateThread(function()
    -- fix for fm hospital camera issue
    if (type(Config.Hospital) == 'string' and Config.Hospital == 'fm_hospital') or (type(Config.Hospital) == 'table' and lib.table.contains(Config.Hospital, 'fm_hospital')) then
        Config.CheckIn.camera.offset = vec3(1.5, 1.25, -0.65) -- you can change offset
    end
end)

---@class Config.Insurance
---@field enabled boolean [enable insurance feature?]
---@field moneyIntoSociety boolean [should money from insurance go into society account?]
Config.Insurance = Config.Insurance or {}
Config.Insurance.enabled = true
Config.Insurance.moneyIntoSociety = true
Config.Insurance.options = {
        -- list of insurance policies
        -- each policy must have unique name!
        ['basic'] = {
            label = 'Basic Insurance',
            price = 1000, -- price to buy this insurance
            duration = 7 * 24 * 60 * 60, -- duration of insurance in seconds [7 days]
        },
        ['premium'] = {
            label = 'Premium Insurance',
            price = 4000,
            duration = 30 * 24 * 60 * 60, -- 30 days
        }
    }
Config.Insurance.points = Config.Insurance.points or {}

---@class Config.MedicBag
---@field enabled boolean [enable medic bag feature?]
---@field prop table {model: string [prop model], coords: vector3 [prop position], rot: vector3 [prop rotation]}
---@field anims table {putdown: table {dict: string [animation dictionary], clip: string [animation clip], flag?: number [animation flag, default 1]}, pickup: table {dict: string [animation dictionary], clip: string [animation clip], flag?: number [animation flag, default 1]}} [animations for putting down and picking up medic bag]
---@field items table<string, boolean> [list of items that can be used from medic bag]
Config.MedicBag = {
    enabled = true,
    prop = {
        model = 'xm_prop_x17_bag_med_01a',
        coords = vector3(0.35, 0.0, 0.01),
        rot = vector3(0.0, 270.0, -120.0)
    },
    anims = {
        putdown = {dict = 'pickup_object', clip = 'pickup_low', flag = 1},
        pickup = {dict = 'pickup_object', clip = 'pickup_low', flag = 1}
    },
    items = {
        ['medicbag'] = { -- THIS MUST BE ITEM NAME
            ['bandage'] = true,
            ['icepack'] = true,
            ['defibrilator'] = true,
            ['ointment'] = true,
            ['disinfectant'] = true,
            ['splint'] = true,
            ['suture_kit'] = true,
            ['morphine'] = true,
            ['medical_kit'] = true,
            ['advanced_medical_kit'] = true,
            ['blood_bag_250'] = true,
            ['blood_bag_500'] = true,
            ['painkillers'] = true,
            ['gauze'] = true,
            ['adrenaline'] = true,
            ['cyclonamine'] = true,
            ['tourniquet'] = true,
            ['antipyretics'] = true,
        },
        ['medicbag_small'] = { -- THIS MUST BE ITEM NAME, THIS ITEM DOESNT EXIST BY DEFAULT, ITS EXAMPLE OF USAGE!
            ['bandage'] = true,
            ['icepack'] = true,
            ['ointment'] = true,
            ['disinfectant'] = true,
            ['splint'] = true,
            ['morphine'] = true,
            ['medical_kit'] = true,
        }
    }
}

---@class Config.Death
---@field forceDeathAfterHeadshot boolean [should player automatically go to death state after headshot instead of bleeding stage?]
---@field forceDeathAfterFall boolean [should player automatically go to death state after fall damage die instead of bleeding stage?]
---@field spawnDeadAboveGround boolean [should player spawn above ground when dead/bleeding, good for avoiding bugs with underground spawns]
---@field spawnFullHealthIfAlive boolean [should player spawn when join with full health if is alive?, good for avoiding bugs with low health on join]
---@field targetRevive table {enabled: boolean [enable target revive feature?], onStart: function [function that will be executed when player starts reviving someone]}
---@field preventDeath function [function that will be executed before executing death logic, if it returns true, death logic will be skipped]
---@field useEnviMedic boolean [use envi-medic integration?]
---@field animals table {enabled: boolean [enable animal death animations?], anims: table<string, {dict: string [animation dictionary], clip: string [animation clip], flag?: number [animation flag, default 1]}>} [list of animal models with their death animations]
---@field commands table<string, {enabled: boolean [enable/disable this command?], names: string[] [command names], restricted: string[] [who can use this command]}[]> [list of kill commands]
---@field enabledKeys table<number> [enabled keys while player is dead/bleeding/recovering]
---@field stages table<string, any>
---@field onInit function [will be executed when this status is initialized]
---@field time number [time in seconds for death screen]
---@field anim table [animation data]
---@field enabled boolean [is stage enabled?]
---@field movement boolean [is player movement enabled? crawling on bleeding state]
---@field anims table[] [list of animations for this stage, script will choose one random]
---@field weapons table<string, {label: string [display name of weapon], bleedOutTime: number [different death screen time for each weapon]]}>
Config.Death = {
    forceDeathAfterHeadshot = false,
    forceDeathAfterFall = false,
    spawnDeadAboveGround = false, 
    spawnFullHealthIfAlive = false,
    targetRevive = {
        enabled = false,
        allowedDeathStage = {
            ['bleeding'] = true,
            -- ['death'] = true,
        },
        reviveHealth = 200,
        onStart = function(targetId)
            local animDict = lib.requestAnimDict('amb@medic@standing@tendtodead@idle_a')
            TaskPlayAnim(cache.ped, animDict, 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)
            local result = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'hard'}, {'w', 'a', 's', 'd'})
            if result then
                if Bridge.Progress.StartCircle({
                    duration = 25000,
                    label = locale('reviving_player'),
                    position = 'center',
                    useWhileDead = true,
                    canCancel = true
                }) then
                    TriggerServerEvent('p_ambulancejob/server/death/targetRevive', targetId)
                end
            end
            RemoveAnimDict(animDict)
            ClearPedTasks(cache.ped)
        end
    },
    preventDeath = function() -- script will not execute death function if this function returns true
        if GetResourceState('ws_ffa_v2') == 'started' then
            return exports["ws_ffa-v2"]:isInZone()
        end
        return false
    end,
    useEnviMedic = false,
    -- support animal death animations? [if is enabled and player is using animal model, script will play death animation for that animal and skip bleeding/recovering]
    animals = {
        enabled = true,
        anims = {
            [joaat('A_C_Rottweiler')] = {dict = 'creatures@rottweiler@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Cat_01')] = {dict = 'creatures@cat@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Pug')] = {dict = 'creatures@pug@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Chop')] = {dict = 'creatures@rottweiler@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Husky')] = {dict = 'creatures@rottweiler@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Boar')] = {dict = 'creatures@boar@move', clip = 'dead_right', flag = 1},
            [joaat('A_C_Cow')] = {dict = 'creatures@cow@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Deer')] = {dict = 'creatures@deer@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_MtLion')] = {dict = 'creatures@coyote@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Rabbit_01')] = {dict = 'creatures@rabbit@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Shepherd')] = {dict = 'creatures@rottweiler@move', clip = 'dead_left', flag = 1},
            [joaat('A_C_Westy')] = {dict = 'creatures@pug@move', clip = 'dead_left', flag = 1},
        }
    },
    commands = {
        ['kill'] = {
            enabled = true, -- enable/disable this command
            names = {'kill', 'slay'}, -- command names
            restricted = {'group.best', 'group.owner', 'group.admin'}, -- who can use this command
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end
        },
        ['killall'] = {
            enabled = false, -- enable/disable this command
            names = {'killall'}, -- command names
            restricted = {'group.god', 'group.best', 'group.owner', 'group.admin'}, -- who can use this command
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end
        },
        ['killradius'] = {
            enabled = false,
            names = {'killradius', 'slayradius'}, -- command names
            restricted = {'group.god', 'group.best', 'group.owner', 'group.admin'}, -- who can use
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end
        },
        ['revive'] = {
            enabled = true, -- enable/disable this command
            names = {'revive', 'rev'}, -- command names
            restricted = {'group.best', 'group.owner', 'group.admin'}, -- who can use this command
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end,
            canUseEvent = function(invokingResource)
                return true
            end,
            serverFunction = function(playerId, targetId)
                if GetResourceState('qbx_smallresources') == 'started' then
                    exports['qbx_smallresources']:SetHunger(targetId, 100)
                    exports['qbx_smallresources']:SetThirst(targetId, 100)
                    Player(targetId).state:set("stress", 0, true)
                end

                if GetResourceState('jg-stress-addon') == 'started' then
                    Player(targetId).state:set('stress', 0, true) -- jg-stress-addon
                end

                if GetResourceState('jim-consumables') == 'started' then
                    local player = Bridge.Framework.getPlayerById(targetId)
                    player.Functions.SetMetaData('hunger', 100.0)
                    player.Functions.SetMetaData('thirst', 100.0)
                    player.Functions.SetMetaData('stress', 0.0)
                    TriggerClientEvent("hud:client:UpdateNeeds", targetId, 100.0, 100.0)
                    TriggerClientEvent('hud:client:UpdateStress', targetId, 0.0)
                end

                if GetResourceState('pickle_consumables') == 'started' and GetResourceState('qb-core') == 'started' then
                    local player = Bridge.Framework.getPlayerById(targetId)
                    player.Functions.SetMetaData('hunger', 100.0)
                    player.Functions.SetMetaData('thirst', 100.0)
                    player.Functions.SetMetaData('stress', 0.0)
                    TriggerClientEvent('hud:client:UpdateNeeds', source, 100.0, 100.0)
                    TriggerClientEvent('hud:client:UpdateStress', source, 0.0)
                end
            end,
            clientFunction = function()
                if GetResourceState('qb-smallresources') == 'started' then
                    TriggerServerEvent('consumables:server:addHunger', 100)
                    TriggerServerEvent('consumables:server:addThirst', 100)
                    TriggerServerEvent('hud:server:RelieveStress', 100)
                end

                if GetResourceState('esx_status') == 'started' then
                    TriggerEvent('esx_status:set', 'hunger', 1000000)
                    TriggerEvent('esx_status:set', 'thirst', 1000000)
                    TriggerEvent('esx_status:set', 'stress', 0) -- for stress system in esx status :)
                end

                if GetResourceState('rcore_drunk') == 'started' then
                    exports['rcore_drunk']:SetPlayerDrunkPercentage(0.0)
                end

                if GetResourceState('es_extended') == 'started' then
                    local ESX = exports['es_extended']:getSharedObject()
                    ESX.SetPlayerData('dead', false)
                    TriggerEvent('esx:onPlayerSpawn')
                    LocalPlayer.state:set('canUseWeapons', true, false)
                end
            end
        },
        ['reviveall'] = {
            enabled = true, -- enable/disable this command
            names = {'reviveall', 'revall'}, -- command names
            restricted = {'group.best', 'group.owner', 'group.admin'}, -- who can use this command
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end,
        },
        ['reviveradius'] = {
            enabled = true,
            names = {'reviveradius', 'revradius'}, -- command names
            restricted = {'group.best', 'group.owner', 'group.admin'}, -- who can use
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end,
        },
        ['heal'] = {
            enabled = true, -- enable/disable this command
            names = {'heal'}, -- command names
            restricted = {'group.best', 'group.owner', 'group.admin'}, -- who can use this command
            canUse = function(playerId, targetId)
                -- custom logic to check if player can use this command on target
                return true
            end,
            canUseEvent = function(invokingResource)
                return true
            end,
            serverFunction = function(playerId, targetId)
                if GetResourceState('qbx_smallresources') == 'started' then
                    exports['qbx_smallresources']:SetHunger(targetId, 100)
                    exports['qbx_smallresources']:SetThirst(targetId, 100)
                    Player(targetId).state:set("stress", 0, true)
                end

                if GetResourceState('jg-stress-addon') == 'started' then
                    Player(targetId).state:set('stress', 0, true) -- jg-stress-addon
                end

                if GetResourceState('jim-consumables') == 'started' then
                    local player = Bridge.Framework.getPlayerById(targetId)
                    player.Functions.SetMetaData('hunger', 100.0)
                    player.Functions.SetMetaData('thirst', 100.0)
                    player.Functions.SetMetaData('stress', 0.0)
                    TriggerClientEvent("hud:client:UpdateNeeds", targetId, 100.0, 100.0)
                    TriggerClientEvent('hud:client:UpdateStress', targetId, 0.0)
                end

                if GetResourceState('pickle_consumables') == 'started' and GetResourceState('qb-core') == 'started' then
                    local player = Bridge.Framework.getPlayerById(targetId)
                    player.Functions.SetMetaData('hunger', 100.0)
                    player.Functions.SetMetaData('thirst', 100.0)
                    player.Functions.SetMetaData('stress', 0.0)
                    TriggerClientEvent('hud:client:UpdateNeeds', source, 100.0, 100.0)
                    TriggerClientEvent('hud:client:UpdateStress', source, 0.0)
                end
            end,
            clientFunction = function()
                if GetResourceState('qb-smallresources') == 'started' then
                    TriggerServerEvent('consumables:server:addHunger', 100)
                    TriggerServerEvent('consumables:server:addThirst', 100)
                    TriggerServerEvent('hud:server:RelieveStress', 100)
                end

                if GetResourceState('esx_status') == 'started' then
                    TriggerEvent('esx_status:set', 'hunger', 1000000)
                    TriggerEvent('esx_status:set', 'thirst', 1000000)
                    TriggerEvent('esx_status:set', 'stress', 0) -- for stress system in esx status :)
                end

                if GetResourceState('rcore_drunk') == 'started' then
                    exports['rcore_drunk']:SetPlayerDrunkPercentage(0.0)
                end

                if GetResourceState('es_extended') == 'started' then
                    local ESX = exports['es_extended']:getSharedObject()
                    ESX.SetPlayerData('dead', false)
                    TriggerEvent('esx:onPlayerSpawn')
                end
            end
        }
    },

    -- script disable all control actions, add here controls which you want to enable while player is dead/bleeding/recovering
    -- https://docs.fivem.net/docs/game-references/controls/
    enabledKeys = {0, 1, 2, 3, 5, 245, 249},
    stages = {
        ['alive'] = {
            enableFadeOut = true, -- enable screen fade out when player is revived?
            onInit = function()
                -- this will execute when player revives
                if GetResourceState('lb-phone') == 'started' then
                    if not LocalPlayer.state.isCuffed then
                        exports["lb-phone"]:ToggleDisabled(false)
                    end
                end

                if GetResourceState('qs-smartphone-pro') == 'started' then
                    if not LocalPlayer.state.isCuffed then
                        exports['qs-smartphone-pro']:SetCanOpenPhone(true)
                    end
                end

                if GetResourceState('pma-voice') == 'started' then
                    exports['pma-voice']:resetProximityCheck()
                end
            end
        },
        ['vehicle'] = {
            anim = {dict = 'missprologuedead_guard', clip = 'dead_guard', flag = 49},
            onInit = function()
                -- this will execute when player enters vehicle while is death
            end
        },
        ['death'] = {
            time = 10,
            anim = {dict = 'dead', clip = 'dead_a', flag = 1},
            dropItems = {
                enabled = false, -- drop items when player dies?
                type = 'chance', -- chance / medics [chance = drop items is based on chance, medics = drop items only when medics are on duty]
                chance = 50, -- chance in % to drop items [only for chance type]
                minMedics = 0, -- minimum medics on duty to drop items [only for medics type]
                dropType = 'stash', -- stash / remove [stash = script will create temporary stash on player death, remove = script will just remove items]
                useInsurance = false, -- use insurance to prevent item loss?
                whitelistItems = {
                    ['phone'] = true,
                    ['simcard'] = true,
                }
            },
            alert = function()
                if GetResourceState('emergencydispatch') == 'started' then
                    TriggerEvent('emergencydispatch:emergencycall:new', "ambulance", "bewusstlose Person (automatischer Notruf)", false)
                    return
                end

                if GetResourceState('piotreq_gmt') == 'started' or GetResourceState('pp-ems-mdt') == 'started' then
                    TriggerServerEvent('p_ambulancejob/server/editable/alert')
                    return
                end

                local coords = lib.callback.await('p_ambulancejob/server/editable/getPlyCoords', false)
                if GetResourceState('redutzu-ems') == 'started' then
                    TriggerEvent('redutzu-ems:client:addDispatchToEMS', {
                        code = '911',
                        title = 'Alert 911',
                        street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)),
                        gender = GetEntityModel(cache.ped) == joaat('mp_f_freemode_01') and 'female' or 'male',
                        duration = (5 * 60 * 60),
                        coords = {x = coords.x, y = coords.y, z = coords.z}
                    })
                end

                -- Always send to internal EMS dispatch board (F5 menu)
                TriggerServerEvent('p_ambulancejob/server/alerts/new', {
                    code = '911',
                    title = 'Alert',
                    message = 'I need help!',
                    coords = coords,
                    expire = 60, -- 60 seconds
                    blip = {
                        sprite = 153,
                        color = 1,
                        scale = 1.1,
                        pulse = true
                    }
                })

                -- Also forward to external dispatch system if one is available
                if Bridge.Dispatch and Bridge.Dispatch.SendAlert then
                    Bridge.Dispatch.SendAlert({
                        job = {'ambulance'},
                        code = '911',
                        title = 'Alert',
                        coords = coords,
                        time = 60,
                        priority = 'normal',
                        icon = 'fa solid fa-skull',
                        blip = {
                            sprite = 153,
                            color = 1,
                            length = 1,
                            scale = 1.1,
                            name = 'Medical Emergency',
                        }
                    })
                end
            end,
            onInit = function()
                -- this will execute when player enters death state
                if GetResourceState('lb-phone') == 'started' then
                    exports["lb-phone"]:ToggleDisabled(true)
                end
                if GetResourceState('qs-smartphone-pro') == 'started' then
                    exports['qs-smartphone-pro']:SetCanOpenPhone(false)
                end
                local disableVoice = false -- set true if you want to disable voice chat when player is dead
                if disableVoice then
                    exports['pma-voice']:overrideProximityCheck(function()
                        return false
                    end)
                end
            end
        },
        ['bleeding'] = {
            enabled = true, -- enable bleeding as death stage? [true = when someone kill you, first will be bleeding then death]
            movement = true,
            enableAlert = false, -- enable alert in bleeding stage?
            -- script will choose one random anim from this table
            anims = {
                {dict = 'move_injured_ground', clip = 'front_loop'},
                {dict = 'move_injured_ground', clip = 'back_loop'}
            },
            time = 120,
            animWhilePrevented = {dict = 'dead', clip = 'dead_a', flag = 1},
            preventAnimation = function()
                -- you can implement here code which will prevent doing crawling animation [for example when player is dragged/carried]
                if LocalPlayer.state.isCarried then
                    return 'disabled' -- completely disabled anim
                end

                if LocalPlayer.state.draggedBy then
                    return true -- prevent anim
                end

                return false -- do not prevent anim
            end,
            onInit = function()
                -- this will execute when player enters bleeding state
                if GetResourceState('lb-phone') == 'started' then
                    exports["lb-phone"]:ToggleDisabled(true)
                end
                if GetResourceState('qs-smartphone-pro') == 'started' then
                    exports['qs-smartphone-pro']:SetCanOpenPhone(false)
                end
                local disableVoice = false -- set true if you want to disable voice chat when player is in bleeding stage
                if disableVoice then
                    exports['pma-voice']:overrideProximityCheck(function()
                        return false
                    end)
                end
            end
        },
        ['recovering'] = {
            enabled = true, -- enable recovering as death stage? [true = when someone beat you with melee, you will recover up]
            anim = {dict = 'missfinale_c1@', clip = 'lying_dead_player0', flag = 1},
            maxKnockoutsToDeath = 2, -- how many knockouts with melee weapons until player goes to death state
            weapons = {
                [joaat('WEAPON_UNARMED')] = { label = locale('fist'), recoveryTime = 20, healthAfterRecover = 150 },
                [joaat('WEAPON_BAT')] = { label = locale('bat'), recoveryTime = 25, healthAfterRecover = 150 },
                [joaat('WEAPON_FLASHLIGHT')] = { label = locale('flashlight'), recoveryTime = 20, healthAfterRecover = 150 },
                [joaat('WEAPON_STUNGUN')] = { label = locale('stungun'), recoveryTime = 30, healthAfterRecover = 150 },
                [joaat('WEAPON_STUNGUN_MP')] = { label = locale('stungun'), recoveryTime = 30, healthAfterRecover = 150 },
                [joaat('WEAPON_NIGHTSTICK')] = { label = locale('nightstick'), recoveryTime = 25, healthAfterRecover = 150 },
                [joaat('WEAPON_CANDYCANE')] = { label = locale('candycane'), recoveryTime = 25, healthAfterRecover = 150 },
                [joaat('WEAPON_KNUCKLE')] = { label = locale('knuckle'), recoveryTime = 20, healthAfterRecover = 150 },

            },
            onInit = function()
                -- this will execute when player enters recovering state
                local disableVoice = false -- set true if you want to disable voice chat when player is recovering
                if disableVoice then
                    exports['pma-voice']:overrideProximityCheck(function()
                        return false
                    end)
                end
            end
        }
    }
}

---@class Config.Bleeding
---@field enabled boolean [enabled bleeding feature?]
---@field screenEffect table {enabled: boolean [enable screen effect bleeding?], requiredValue: number [required minimum value to show it up]}
---@field loopInterval number [time in ms for bleeding loop, how often player will get damage from bleeding]
---@field maxValue number [maximum bleeding value]
---@field items table<string, {value: number [how much this item will reduce bleeding value], duration: number [time in ms for using item], anim: table {dict: string [animation dictionary], clip: string [animation clip], flag?: number [animation flag, default 1]}}> [list of items which can reduce bleeding value]
---@field disabledControlsWhileUsing table {move: boolean [disable movement controls while using bleeding item?], combat: boolean [disable combat controls while using bleeding item?], mouse: boolean [disable mouse controls while using bleeding item?], car: boolean [disable car controls while using bleeding item?]}
---@field weapons table<string, number [when u got hit by this weapon, it will add this value to overall bleeding value]>
---@field onInit function [this will execute when player enters bleeding state]
Config.Bleeding = {
    enabled = true, -- enabled bleeding feature? [you will bleed when u get stabbed / shot]
    screenEffect = {
        enabled = true, -- enable screen effect bleeding?
        requiredValue = 5, -- required minimum value to show it up
    },
    walkType = 'move_injured_generic', -- set player walk type when bleeding [set false to disable it]
    loopInterval = 10000,
    maxValue = 25,
    items = {
        ['gauze'] = {
            value = 1,
            health = 5, -- health restored by gauze [SCRIPT WILL ADD HEALTH IF PLAYER IS NOT BLEEDING, OTHERWISE WILL STOP BLEEDING]
            duration = 3000,
            anim = {dict = 'mp_suicide', clip = 'pill', flag = 49},
        },
        ['adrenaline'] = {
            value = 5,
            health = 10, -- health restored by adrenaline [SCRIPT WILL ADD HEALTH IF PLAYER IS NOT BLEEDING, OTHERWISE WILL STOP BLEEDING]
            duration = 3000,
            anim = {dict = 'mp_suicide', clip = 'pill', flag = 49},
        },
        ['bandage'] = {
            value = 10,
            health = 20, -- health restored by bandage [SCRIPT WILL ADD HEALTH IF PLAYER IS NOT BLEEDING, OTHERWISE WILL STOP BLEEDING]
            duration = 5000,
            anim = {dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49},
        },
        ['cyclonamine'] = {
            value = 10,
            duration = 3000,
            anim = {dict = 'mp_suicide', clip = 'pill', flag = 49},
        },
        ['tourniquet'] = {
            value = 15,
            duration = 3000,
            anim = {dict = 'mp_suicide', clip = 'pill', flag = 49},
        }
    },
    disabledControlsWhileUsing = {move = false, combat = true, mouse = false, car = true},
    weapons = {
        -- Melee / bladed weapons
        [joaat('WEAPON_KNIFE')] = 3,
        [joaat('WEAPON_DAGGER')] = 3,
        [joaat('WEAPON_SWITCHBLADE')] = 3,
        [joaat('WEAPON_MACHETE')] = 4,
        [joaat('WEAPON_HATCHET')] = 4,
        [joaat('WEAPON_STONE_HATCHET')] = 4,
        [joaat('WEAPON_BATTLEAXE')] = 5,
        [joaat('WEAPON_STUNROD')] = 2,
        -- Pistols
        [joaat('WEAPON_PISTOL')] = 3,
        [joaat('WEAPON_PISTOL_MK2')] = 3,
        [joaat('WEAPON_COMBATPISTOL')] = 3,
        [joaat('WEAPON_APPISTOL')] = 3,
        [joaat('WEAPON_SNSPISTOL')] = 3,
        [joaat('WEAPON_SNSPISTOL_MK2')] = 3,
        [joaat('WEAPON_HEAVYPISTOL')] = 4,
        [joaat('WEAPON_VINTAGEPISTOL')] = 3,
        [joaat('WEAPON_FLAREGUN')] = 3,
        [joaat('WEAPON_MARKSMANPISTOL')] = 3,
        [joaat('WEAPON_REVOLVER')] = 4,
        [joaat('WEAPON_REVOLVER_MK2')] = 4,
        [joaat('WEAPON_DOUBLEACTION')] = 4,
        [joaat('WEAPON_CERAMICPISTOL')] = 3,
        [joaat('WEAPON_NAVYREVOLVER')] = 4,
        [joaat('WEAPON_PISTOL50')] = 4,
        [joaat('WEAPON_PISTOLXM3')] = 3,
        -- SMGs
        [joaat('WEAPON_MICROSMG')] = 3,
        [joaat('WEAPON_SMG')] = 4,
        [joaat('WEAPON_SMG_MK2')] = 4,
        [joaat('WEAPON_ASSAULTSMG')] = 4,
        [joaat('WEAPON_COMBATPDW')] = 4,
        [joaat('WEAPON_MACHINEPISTOL')] = 3,
        [joaat('WEAPON_MINISMG')] = 3,
        [joaat('WEAPON_RAILGUN')] = 5,
        [joaat('WEAPON_GUSENBERG')] = 4,
        -- Assault Rifles
        [joaat('WEAPON_ASSAULTRIFLE')] = 5,
        [joaat('WEAPON_ASSAULTRIFLE_MK2')] = 5,
        [joaat('WEAPON_CARBINERIFLE')] = 5,
        [joaat('WEAPON_CARBINERIFLE_MK2')] = 5,
        [joaat('WEAPON_ADVANCEDRIFLE')] = 5,
        [joaat('WEAPON_SPECIALCARBINE')] = 5,
        [joaat('WEAPON_SPECIALCARBINE_MK2')] = 5,
        [joaat('WEAPON_BULLPUPRIFLE')] = 5,
        [joaat('WEAPON_BULLPUPRIFLE_MK2')] = 5,
        [joaat('WEAPON_COMPACTRIFLE')] = 5,
        [joaat('WEAPON_MILITARYRIFLE')] = 5,
        [joaat('WEAPON_HEAVYRIFLE')] = 6,
        [joaat('WEAPON_TACTICALRIFLE')] = 5,
        [joaat('WEAPON_RIFLE')] = 5,
        -- Machine Guns
        [joaat('WEAPON_MG')] = 5,
        [joaat('WEAPON_COMBATMG')] = 5,
        [joaat('WEAPON_COMBATMG_MK2')] = 5,
        [joaat('WEAPON_GATTLINGGUN')] = 6,
        -- Shotguns
        [joaat('WEAPON_PUMPSHOTGUN')] = 6,
        [joaat('WEAPON_PUMPSHOTGUN_MK2')] = 6,
        [joaat('WEAPON_SAWNOFFSHOTGUN')] = 5,
        [joaat('WEAPON_ASSAULTSHOTGUN')] = 5,
        [joaat('WEAPON_BULLPUPSHOTGUN')] = 5,
        [joaat('WEAPON_MUSKET')] = 5,
        [joaat('WEAPON_HEAVYSHOTGUN')] = 6,
        [joaat('WEAPON_DBSHOTGUN')] = 6,
        [joaat('WEAPON_AUTOSHOTGUN')] = 6,
        [joaat('WEAPON_COMBATSHOTGUN')] = 5,
        -- Sniper Rifles
        [joaat('WEAPON_SNIPERRIFLE')] = 6,
        [joaat('WEAPON_HEAVYSNIPER')] = 7,
        [joaat('WEAPON_HEAVYSNIPER_MK2')] = 7,
        [joaat('WEAPON_MARKSMANRIFLE')] = 6,
        [joaat('WEAPON_MARKSMANRIFLE_MK2')] = 6,
    },
    onInit = function()
        -- this will execute when player enters bleeding state
    end,
    onClear = function()
        -- this will execute when player bleeding is cleared
    end
}

---@class Config.Crutch
---@field enabled boolean [enable crutch feature?]
---@field allowedJobs table<string, number> [which jobs are allowed to force crutch on some player]
---@field disableSprint boolean [disable sprint when using crutch?]
---@field prop table {model: string [crutch prop model], coords: vec3 [coords of prop], rot: vec3 [rotation of prop]}
Config.Crutch = {
    enabled = true,
    allowedJobs = {['ambulance'] = 0},
    disabledControls = {22, 21, 24, 25},
    prop = {
        model = 'prop_mads_crutch01', -- Author of Prop [https://mads.tebex.io/]
        coords = vec3(1.18, -0.36, -0.20), -- coords of prop
        rot = vec3(-20.0, -87.0, -20.0), -- rotation of prop
    }
}

---@class Config.Wheelchair
---@field enabled boolean [enable wheelchair feature?]
---@field allowedJobs table<string, number> [which jobs are allowed to force wheelchair on some player]
---@field model string [wheelchair model as vehicle]
---@field disableExitWhenForced boolean [disable exit when forced into wheelchair]
Config.Wheelchair = {
    enabled = true,
    allowedJobs = {['ambulance'] = 0},
    model = 'iak_wheelchair',
    disableExitWhenForced = true
}

---@class Config.DeathScreen
---@field enabled boolean [enable death screen feature?, false = you should use your own death screen]
---@field setVisibility function(state: boolean, data: table) [function to set visibility of death screen, state = true/false, data = table with additional data]
Config.DeathScreen = {
    enabled = true,
    setVisibility = function(state, data)
        -- implement your death screen visibility here
        -- state = true/false
        -- data = table with additional data
    end,
}

---@class Config.Damages
---@field enabled boolean [enable damages feature?]
---@field reviveAnimation boolean [play revive animation? when medic heal all injuries]
---@field moneyIntoSociety boolean [should money from healing injuries go into society account?]
---@field moneyforHealing table {perInjury: boolean [add money for each injury?], amount: number [base amount of money for healing], medicPercent: number [how much % from base amount will get medic]} [money settings for healing injuries]
---@field effects table {enabled: boolean [enable damage effects?], chance: number [chance in % to get effect when get hit in some body part below], bones: table<string, string> [list of bones with their effects]} [effects settings]
---@field bones table<string, table<string, boolean>> [list of bones which will be tracked for damages]
---@field weapons table<string, {injuries: table<number, {label: string [display name of injury], color: string [color from p_notify], items: table<string, number> [items needed to heal this injury]}[]>}> [list of weapons with their injuries]
-- Bones Reference: https://wiki.rage.mp/wiki/Bones
Config.Damages = {
    enabled = true,
    refreshRate = 500, -- time in ms for refreshing healing menu [lower = more smooth but more performance impact]
    reviveAnimation = true,
    advancedHealing = true, -- [true = progress bar and animation per used item to heal, false = no progress / animation]
    moneyIntoSociety = true,
    damagesUI = false,
    damagesUIKey = 'TAB',
    informAndFreeze = false, -- [true = script will show notify and freeze player when medic is healing injuries]
    preventRegister = function(weaponHash)
        -- return true to prevent registering damage for this weapon [you can use deathmatch/paintball etc exports]
        if GetResourceState('nass_paintball') == 'started' then
            if exports['nass_paintball']:inGame() then return true end
        end

        if GetResourceState('pug-paintball') == 'started' then
            if exports["pug-paintball"]:IsInPaintball() then return true end
        end
        
        if GetResourceState('brutal_paintball') == 'started' then
            if exports.brutal_paintball:isInPaintball() then return true end
        end

        if GetResourceState('0r-paintball-v2') == 'started' then
            if exports['0r-paintball-v2']:inGame() then return true end
        end

        if GetResourceState('qs-deathmatch') == 'started' then
            if exports['qs-deathmatch']:IsPlayerInDM() then return true end
        end

        return false
    end,
    moneyforHealing = {
        perInjury = true,
        amount = 100,
        medicPercent = 20, -- how much % from base amount will get medic
    },
    effects = {
        enabled = true,
        generalEffect = true, -- enable general damage effect? (will show up blood on screen when player is damaged)
        chance = 10, -- 10% chance to get effect when get hit in some body part below
        bones = {
            ['head'] = {effect = 'blackOut', value = 30}, -- add 30 value to blackOut effect
            ['leftArm'] = {effect = 'shakeAim', value = 30},
            ['rightArm'] = {effect = 'shakeAim', value = 30},
        }
    },
    modifiers = {
        [joaat('WEAPON_UNARMED')] = 0.25, -- fist
    },
    bones = {
        -- These means when player got hit in one of these bones, it will register damage for that body part :)
        ['head'] = {
            ['12844'] = true, ['31086'] = true, ['25260'] = true, ['27474'] = true, ['39317'] = true,
        },
        ['torso'] = {
            ['0'] = true, ['11816'] = true,  ['24816'] = true, ['24817'] = true, ['24818'] = true
        },
        ['leftArm'] = {
            ['45509'] = true, ['61163'] = true, ['18905'] = true, ['36029'] = true, ['60309'] = true,
            ['61163'] = true, ['65245'] = true, ['64729'] = true,
        },
        ['rightArm'] = {
            ['2992'] = true, ['6286'] = true, ['24806'] = true, ['28422'] = true, ['37119'] = true,
            ['40269'] = true, ['57005'] = true, ['10706'] = true,
        },
        ['leftLeg'] = {
            ['14201'] = true, ['46078'] = true, ['57717'] = true, ['58271'] = true, ['65245'] = true,
            ['63931'] = true,
        },
        ['rightLeg'] = {
            ['16335'] = true, ['24806'] = true, ['35502'] = true, ['36864'] = true, ['51826'] = true,
            ['52301'] = true,
        }
    },
    weapons = {
        [joaat('WEAPON_UNARMED')] = {
            injuries = {
                -- there must be some damage at [1] index !!!
                [1] = {label = 'Bruise', color = 'grape.6', items = {['ointment'] = 1}},
                [5] = {label = 'Minor Cut', color = 'red.6', items = {['disinfectant'] = 1, ['gauze'] = 1, ['bandage'] = 1}},
                [7] = {label = 'Deep Cut', color = 'red.7', items = {['disinfectant'] = 1, ['suture_kit'] = 1, ['bandage'] = 1}},
                [10] = {label = 'Fracture', color = 'red.8', items = {['splint'] = 1, ['medical_kit'] = 1}},
                [20] = {label = 'Broken Bone', color = 'red.9', items = {['splint'] = 1, ['advanced_medical_kit'] = 2}},
            }
        },
        [joaat('WEAPON_KNIFE')] = {
            injuries = {
                [1] = {label = 'Knife Small Cut', color = 'grape.6', items = {['disinfectant'] = 1, ['gauze'] = 1, ['bandage'] = 1}},
                [2] = {label = 'Knife Minor Cut', color = 'red.6', items = { ['disinfectant'] = 1, ['gauze'] = 2, ['bandage'] = 1}},
                [3] = {label = 'Knife Deep Cut', color = 'red.7', items = {['disinfectant'] = 1, ['suture_kit'] = 1, ['medical_kit'] = 1, ['bandage'] = 1}},
                [4] = {label = 'Stab Wound', color = 'red.8', items = {['suture_kit'] = 2, ['advanced_medical_kit'] = 1, ['bandage'] = 2}},
                [5] = {label = 'Severed Artery', color = 'red.9', items = {['gauze'] = 2, ['blood_bag_250'] = 1, ['suture_kit'] = 1, ['advanced_medical_kit'] = 1}},
                [6] = {label = 'Critical Laceration', color = 'red.9', items = {['gauze'] = 2, ['blood_bag_500'] = 1, ['suture_kit'] = 1, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_PISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            },

            -- you can use advancedInjuries for every weapon and bones [head, torso, leftArm, rightArm, leftLeg, rightLeg]
            -- advancedInjuries = {
            --     ['head'] = {
            --         [1] = {label = 'Headshot Wound', color = 'red.8', items = {['suture_kit'] = 2, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            --     },
            -- }
        },
        [joaat('WEAPON_COMBATPISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_VINTAGEPISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_SNSPISTOL_MK2')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_PISTOL50')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_SNSPISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_PISTOL_MK2')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_HEAVYPISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_APPISTOL')] = {
            injuries = {
                [1] = {label = 'Small Caliber Wound', color = 'red.5', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Caliber Wound', color = 'red.6', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1, ['morphine'] = 1}},
                [5] = {label = 'Large Caliber Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['morphine'] = 2}},
                [7] = {label = 'Heavy Bleeding Wound', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_SMG')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_COMBATPDW')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_MICROSMG')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_TECPISTOL')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_MINISMG')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_MACHINEPISTOL')] = {
            injuries = {
                [1] = {label = 'Light SMG Wound', color = 'red.6', items = {['tourniquet'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [5] = {label = 'SMG Wound', color = 'red.7', items = {['bandage'] = 1, ['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [7] = {label = 'Multiple SMG Wounds', color = 'red.8', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1}},
                [10] = {label = 'Critical SMG Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
                [15] = {label = 'SMG Arterial Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_CARBINERIFLE')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_ASSAULTRIFLE_MK2')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_ADVANCEDRIFLE')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_ASSAULTRIFLE')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_TACTICALRIFLE')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_CARBINERIFLE_MK2')] = {
            injuries = {
                [1] = {label = 'Rifle Graze', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [4] = {label = 'Rifle Entry Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [7] = {label = 'Rifle Exit Wound', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [9] = {label = 'High Velocity Impact', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [12] = {label = 'Rifle Organ Damage', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_SHOTGUN')] = {
            injuries = {
                [1] = {label = 'Shotgun Pellet Wound', color = 'red.6', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1}},
                [2] = {label = 'Shotgun Spread Wound', color = 'red.7', items = {['suture_kit'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [4] = {label = 'Shotgun Blast Trauma', color = 'red.8', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1, ['medical_kit'] = 1}},
                [6] = {label = 'Close Range Devastation', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1, ['advanced_medical_kit'] = 1}},
                [8] = {label = 'Shotgun Critical Trauma', color = 'red.9', items = {['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 2, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_SNIPER')] = {
            injuries = {
                [1] = {label = 'Sniper Graze', color = 'red.7', items = {['bandage'] = 2, ['advanced_medical_kit'] = 1}},
                [2] = {label = 'High Caliber Impact', color = 'red.8', items = {['bandage'] = 3, ['suture_kit'] = 1, ['morphine'] = 1, ['blood_bag_250'] = 1}},
                [3] = {label = 'Armor Piercing Wound', color = 'red.9', items = {['bandage'] = 4, ['suture_kit'] = 1, ['cyclonamine'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1}},
                [4] = {label = 'Devastating Impact', color = 'red.9', items = {['bandage'] = 4, ['suture_kit'] = 2, ['cyclonamine'] = 1, ['adrenaline'] = 1, ['blood_bag_500'] = 1}},
                [5] = {label = 'Critical Sniper Trauma', color = 'red.9', items = {['bandage'] = 4, ['suture_kit'] = 1, ['cyclonamine'] = 1, ['morphine'] = 1, ['morphine'] = 1, ['blood_bag_500'] = 1}},
            }
        },
        [joaat('WEAPON_MACHETE')] = {
            injuries = {
                [1] = {label = 'Machete Slash', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [3] = {label = 'Deep Machete Cut', color = 'red.7', items = {['bandage'] = 2, ['disinfectant'] = 1, ['suture_kit'] = 1}},
                [5] = {label = 'Severed Muscle', color = 'red.8', items = {['bandage'] = 2, ['suture_kit'] = 1, ['tourniquet'] = 1}},
            }
        },
        [joaat('WEAPON_CROWBAR')] = {
            injuries = {
                [1] = {label = 'Blunt Force Bruise', color = 'grape.6', items = {['bandage'] = 1, ['ointment'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Crowbar Laceration', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [4] = {label = 'Bone Fracture', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2}},
                [6] = {label = 'Compound Fracture', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['morphine'] = 1, ['adrenaline'] = 1}},
                [8] = {label = 'Severe Head Trauma', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['morphine'] = 2, ['suture_kit'] = 1}},
            }
        },
        [joaat('WEAPON_WRENCH')] = {
            injuries = {
                [1] = {label = 'Blunt Force Bruise', color = 'grape.6', items = {['bandage'] = 1, ['ointment'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Wrench Laceration', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [4] = {label = 'Bone Fracture', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2}},
                [6] = {label = 'Compound Fracture', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['morphine'] = 1, ['adrenaline'] = 1}},
                [8] = {label = 'Severe Head Trauma', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['morphine'] = 2, ['suture_kit'] = 1}},
            }
        },
        [joaat('WEAPON_HAMMER')] = {
            injuries = {
                [1] = {label = 'Blunt Force Bruise', color = 'grape.6', items = {['bandage'] = 1, ['ointment'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Hammer Laceration', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [4] = {label = 'Bone Fracture', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2}},
                [6] = {label = 'Compound Fracture', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['morphine'] = 1, ['adrenaline'] = 1}},
                [8] = {label = 'Severe Head Trauma', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['morphine'] = 2, ['suture_kit'] = 1}},
            }
        },
        [joaat('WEAPON_DAGGER')] = {
            injuries = {
                [1] = {label = 'Knife Small Cut', color = 'grape.6', items = {['disinfectant'] = 1, ['gauze'] = 1, ['bandage'] = 1}},
                [2] = {label = 'Knife Minor Cut', color = 'red.6', items = { ['disinfectant'] = 1, ['gauze'] = 2, ['bandage'] = 1}},
                [3] = {label = 'Knife Deep Cut', color = 'red.7', items = {['disinfectant'] = 1, ['suture_kit'] = 1, ['medical_kit'] = 1, ['bandage'] = 1}},
                [4] = {label = 'Stab Wound', color = 'red.8', items = {['suture_kit'] = 2, ['advanced_medical_kit'] = 1, ['bandage'] = 2}},
                [5] = {label = 'Severed Artery', color = 'red.9', items = {['gauze'] = 2, ['blood_bag_250'] = 1, ['suture_kit'] = 1, ['advanced_medical_kit'] = 1}},
                [6] = {label = 'Critical Laceration', color = 'red.9', items = {['gauze'] = 2, ['blood_bag_500'] = 1, ['suture_kit'] = 1, ['advanced_medical_kit'] = 1}},
            }
        },
        [joaat('WEAPON_BATTLEAXE')] = {
            injuries = {
                [1] = {label = 'Blunt Force Bruise', color = 'grape.6', items = {['bandage'] = 1, ['ointment'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Axe Laceration', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [4] = {label = 'Bone Fracture', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2}},
                [6] = {label = 'Compound Fracture', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['morphine'] = 1, ['adrenaline'] = 1}},
                [8] = {label = 'Severe Head Trauma', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['morphine'] = 2, ['suture_kit'] = 1}},
            }
        },
        [joaat('WEAPON_BAT')] = {
            injuries = {
                [1] = {label = 'Bat Bruise', color = 'grape.6', items = {['bandage'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Bat Welt', color = 'red.6', items = {['bandage'] = 2, ['icepack'] = 1}},
                [3] = {label = 'Rib Fracture', color = 'red.7', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1}},
                [4] = {label = 'Multiple Fractures', color = 'red.8', items = {['bandage'] = 4, ['advanced_medical_kit'] = 2, ['splint'] = 1}},
                [5] = {label = 'Severe Blunt Trauma', color = 'red.9', items = {['bandage'] = 5, ['advanced_medical_kit'] = 3, ['blood_bag_250'] = 1}},
            }
        },
        [joaat('WEAPON_HAMMER')] = {
            injuries = {
                [1] = {label = 'Hammer Bruise', color = 'grape.6', items = {['bandage'] = 1, ['icepack'] = 1}},
                [2] = {label = 'Hammer Laceration', color = 'red.6', items = {['bandage'] = 2}},
                [3] = {label = 'Crushed Bone', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['splint'] = 1}},
                [4] = {label = 'Shattered Bone', color = 'red.9', items = {['bandage'] = 4, ['advanced_medical_kit'] = 1, ['suture_kit'] = 1}},
                [5] = {label = 'Pulverized Trauma', color = 'red.9', items = {['bandage'] = 4, ['advanced_medical_kit'] = 1, ['blood_bag_250'] = 1, ['suture_kit'] = 2}},
            }
        },
        [joaat('WEAPON_EXPLOSION')] = {
            injuries = {
                [1] = {label = 'Blast Bruise', color = 'red.6', items = {['bandage'] = 2, ['ointment'] = 1}},
                [2] = {label = 'Shrapnel Wound', color = 'red.7', items = {['bandage'] = 3, ['suture_kit'] = 1, ['ointment'] = 1}},
                [3] = {label = 'Blast Burns', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['ointment'] = 2}},
                [4] = {label = 'Multiple Shrapnel', color = 'red.9', items = {['bandage'] = 3, ['suture_kit'] = 2, ['blood_bag_250'] = 1}},
                [5] = {label = 'Catastrophic Blast Injury', color = 'red.9', items = {['ointment'] = 3, ['suture_kit'] = 1, ['bandage'] = 1, ['gauze'] = 1}},
            }
        },
        [joaat('WEAPON_FIRE')] = {
            injuries = {
                [1] = {label = 'Minor Burn', color = 'orange.6', items = {['ointment'] = 1}},
                [2] = {label = 'First Degree Burn', color = 'orange.7', items = {['bandage'] = 1, ['ointment'] = 2}},
                [3] = {label = 'Second Degree Burn', color = 'red.7', items = {['bandage'] = 2, ['advanced_medical_kit'] = 1, ['ointment'] = 3}},
                [4] = {label = 'Third Degree Burn', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['ointment'] = 4, ['morphine'] = 1}},
                [5] = {label = 'Severe Burns', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 3, ['ointment'] = 5, ['suture_kit'] = 1, ['morphine'] = 2}},
            }
        },
        [joaat('WEAPON_FALL')] = {
            injuries = {
                [1] = {label = 'Scraped Knee', color = 'grape.6', items = {['bandage'] = 1, ['disinfectant'] = 1}},
                [2] = {label = 'Sprained Ankle', color = 'red.6', items = {['bandage'] = 2, ['icepack'] = 1}},
                [3] = {label = 'Broken Arm', color = 'red.7', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['splint'] = 1}},
                [4] = {label = 'Multiple Fractures', color = 'red.8', items = {['bandage'] = 3, ['advanced_medical_kit'] = 2, ['splint'] = 2}},
                [5] = {label = 'Spinal Injury', color = 'red.9', items = {['bandage'] = 3, ['advanced_medical_kit'] = 1, ['blood_bag_500'] = 1, ['suture_kit'] = 2, ['morphine'] = 2}},
            }
        },
        -- damages from vehicle
        [-1553120962] = {
            injuries = {
                [1] = {label = 'Road Rash', color = 'red.6', items = {['bandage'] = 2, ['disinfectant'] = 1}},
                [2] = {label = 'Impact Bruising', color = 'red.7', items = {['bandage'] = 3, ['icepack'] = 2}},
                [3] = {label = 'Broken Ribs', color = 'red.8', items = {['bandage'] = 1, ['advanced_medical_kit'] = 2, ['splint'] = 1}},
                [4] = {label = 'Internal Bleeding', color = 'red.9', items = {['morphine'] = 2, ['blood_bag_250'] = 1, ['suture_kit'] = 1}},
                [5] = {label = 'Massive Trauma', color = 'red.9', items = {['morphine'] = 2, ['blood_bag_500'] = 1, ['suture_kit'] = 1}},
            }
        },
    }
}

---@class Config.Pulse
---@field enabled boolean [enable pulse feature?]
---@field minPulse number [default minimum pulse value]
---@field maxPulse number [default maximum pulse value]
---@field critical table {enabled: boolean, chance: number, requiredInjuries: number, pulse: table<number>} [critical pulse settings]
--- Info: Pulse will decrease when player get injuries and increase when player heal injuries
--- Info: When player is in death/bleeding state there is a chance to get critical pulse value
Config.Pulse = {
    enabled = true,
    minPulse = 70, 
    maxPulse = 200,
    critical = {
        enabled = true,
        chance = 10, -- 10% chance to get critical pulse when in death/bleeding state
        requiredInjuries = 5, -- required number of injuries to get critical pulse
        pulse = {35, 50}, -- pulse value when critical [script will choose 35 or 50]
    }
}

---@class Config.Temperature
---@field enabled boolean [enable temperature feature?]
---@field minTemperature number [minimum temperature]
---@field maxTemperature number [maximum temperature]
---@field items table<string, number> [list of items that can affect temperature and their effect value]
---@field critical table {enabled: boolean, chance: number, requiredInjuries: number, temperature: table<number>} [critical temperature settings]
--- Info: Temperature will decrease when player get cold items and increase when player get hot items
--- Info: When player is in death/bleeding state there is a chance to get critical temperature value
Config.Temperature = {
    enabled = true,
    minTemperature = 36, -- minimum temperature
    maxTemperature = 38, -- maximum temperature
    items = {
        ['icepack'] = -0.5, -- icepack will reduce temperature by 0.5
        ['antipyretics'] = 0.5, -- antipyretics will increase temperature by 0.5
    },
    critical = {
        enabled = true,
        chance = 10, -- 10% chance to get critical temperature when in death/bleeding state
        requiredInjuries = 10, -- required number of injuries to get critical temperature
        temperature = {32, 41}, -- temperature value when critical [script will choose 34.0 or 42.0]
    }
}

---@class Config.Defibrilator
---@field enabled boolean [enable defibrilator feature?]
---@field allowedJobs table<string> [which jobs are allowed to use defibrilator]
---@field propModel string [defibrilator prop model]
---@field onUse function(targetId: number) [this will execute when defibrilator is used on some player, targetId = player id of target]
Config.Defibrilator = {
    enabled = true,
    allowedJobs = {'ambulance'},
    propModel = 'lifepak15',
    onUse = function(targetId)
        -- this will execute when defibrilator is used on some player
        -- targetId = player id of target
        if Bridge.Progress.StartCircle({
            duration = 5000,
            label = locale('preparing_defibrilator'),
            position = 'bottom',
            canCancel = false
        }) then
            local result = lib.skillCheck({'easy', 'medium', 'hard'})
            return result
        end
    end
}

---@class Config.BodyBag
---@field enabled: boolean [enable body bag feature?]
---@field respawnPlayer: boolean [option to respawn player at hospital in body bag for medics?]
---@field dropItems: boolean [drop items on ground when player is respawned in body bag?]
---@field prop: {model: string, coords: vec3, rot: vec3} [body bag prop settings]
Config.BodyBag = {
    enabled = true,
    respawnPlayer = true,
    dropItems = true, -- drop items on ground when player is respawned in body bag
    prop = {
        model = 'xm_prop_body_bag',
        coords = vec3(-0.4, -0.13, -0.14),
        rot = vec3(-94.32, 93.43, 114.67)
    }
}

---@class Config.Stretcher
---@field enabled boolean [enable stretcher feature?]
---@field useDetachTarget boolean [use target to detach stretcher? only for ox_target, false = text ui]
---@field anims table {carry: {dict: string, clip: string, flag: number}, lay: {dict: string, clip: string, flag: number}} [stretcher animations]
---@field prop {model: string, foldModel: string, coords: vec3, rot: vec3, bone: number} [stretcher prop settings]
---@field vehicleModels table<integer, {coords: vec3, rot: vec3}> [list of vehicle models that can store stretcher and their coords/rot settings]
--- Info: You can add your custom vehicle models to this list
Config.Stretcher = {
    enabled = true,
    useDetachTarget = false,
    anims = {
        carry = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
        lay = { dict = 'anim@gangops@morgue@table@', clip = 'body_search', flag = 1 }
    },
    prop = {
        model = 'strykergurney',
        foldModel = 'loweredstrykergurney',
        coords = vec3(1.58, -0.08, -0.17),
        rot = vec3(81.91, 10.4, -143.3),
        bone = 18905 -- left hand
    },
    vehicleModels = {
        [joaat('ambulance')] = {
            -- left/right | forward/back | up/down
            coords = vec3(0.0, -3.25, -0.25),
            rot = vec3(0.0, 0.0, 0.0)
        },
        [joaat('maverick')] = {
            coords = vec3(0.0, -0.15, -0.45),
            rot = vec3(0.0, 0.0, 0.0)
        }
    },
}

---@class Config.Radial
---@field enabled boolean [enable radial menu feature?]
---@field requireDuty boolean [require to be on duty to see menu?]
---@field items table<{id: string, icon: string, label: string, onSelect: function}> [list of radial items]
--- Info: Our script use ox_lib radial menu!
Config.Radial = {
    enabled = true,
    requireDuty = true, -- require to be on duty to see menu?
    items = {
        {
            id = 'emsTablet',
            icon = 'tablet',
            label = locale('tablet'),
            onSelect = function()
                if GetResourceState('piotreq_gmt') == 'started' then
                    TriggerEvent('piotreq_gmt:OpenGMT')
                elseif GetResourceState('tk_mdt') == 'started' then
                    exports['tk_mdt']:openUI('ambulance')
                elseif GetResourceState('lb-tablet') == 'started' then
                    TriggerEvent('tablet:toggleOpen')
                elseif GetResourceState('kartik-mdt') == 'started' then
                    exports['kartik-mdt']:openMDT()
                elseif GetResourceState('qf_mdt') == 'started' then
                    exports['qf_mdt']:OpenMDT()
                else
                    lib.print.error('You are not using supported MDT! Add it in config.lua')
                end
            end
        },
        {
            id = 'emsDispatch',
            icon = 'tablet',
            label = locale('dispatch'),
            onSelect = function()
                if GetResourceState('piotreq_gmt') == 'started' then
                    exports['piotreq_gmt']:OpenDispatch()
                    return
                end

                if Bridge.Dispatch and Bridge.Dispatch.Open then
                    Bridge.Dispatch.Open()
                else
                    Alerts:open()
                end
            end
        },
        {
            id = 'emsTerminal',
            icon = 'tablet',
            label = locale('set_terminal'),
            onSelect = function()
                TV:terminal()
            end
        },
        {
            id = 'emsInsurance',
            icon = 'hospital-user',
            label = locale('check_insurance'),
            onSelect = function()
                local plyId, plyPed, _ = lib.getClosestPlayer(GetEntityCoords(cache.ped), 4.0, false)
                if not plyPed or plyPed == 0 then
                    Bridge.Notify.showNotify(locale('no_players'), 'error')
                    return
                end
                
                if Bridge.Progress.Start({
                    duration = 10000,
                    label = locale('checking_insurance'),
                    canCancel = true,
                    anim = {dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', clip = 'idle_a', flag = 49},
                    prop = {model = 'prop_cs_tablet', pos = vec3(0.0, 0.0, -0.02), rot = vec3(0.0, 0.0, 0.0)}
                }) then
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(plyPed))
                    TriggerServerEvent('p_ambulancejob/server/insurance/check', targetId)
                end
            end
        }
    }
}

---@class Config.Radio
---@field enabled boolean [enable radio feature?]
---@field channels table<{label: string, channel: number, jobs: string[]}> [list of radio channels]
--- Info: You can add your custom radio channels to this list
--- Info: This feature require pma-voice resource [its not custom radio, its as option in radial menu!]
Config.Radio = {
    enabled = true,
    channels = {
        {label = '#1 EMS', channel = 1, jobs = {'ambulance'}},
        {label = '#2 EMS', channel = 2, jobs = {'ambulance'}},
        {label = '#3 EMS', channel = 3, jobs = {'ambulance'}},
        {label = '#4 EMS', channel = 4, jobs = {'ambulance'}},
        {label = '#5 EMS', channel = 5, jobs = {'ambulance'}}
    }
}

---@class Config.Interactions
---@field enabled boolean [enable interactions feature?]
---@field options table<string, Interaction> [list of interactions]

---@class Interaction
---@field type string ['player' or 'vehicle']
---@field label string [display name of interaction]
---@field icon string [icon for interaction]
---@field distance number [max distance to interact]
---@field jobs string[] [which jobs are allowed to see this interaction]
---@field onSelect function [this will execute when interaction is selected]
---@field canInteract? function [if this function return false, interaction will be hidden]
Config.Interactions = {
    enabled = true,
    playerBlood = {
        enabled = true, -- enabled option to take player blood?
        healthToRemove = 20, -- how much health to remove when taking blood [max is 200]
        cooldownPerPlayer = 10, -- in minutes
        doubleCooldown = true -- if true, taking 500ml blood will set cooldown 2x longer
    },
    options = {
        ['openHealingMenu'] = {
            type = 'player',
            label = locale('heal_player'),
            icon = 'fas fa-suitcase-medical',
            distance = 2.0,
            jobs = {'ambulance'},
            onSelect = function(data)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                Damages:menu(targetId)
            end,
            canInteract = function(entity)
                return Death.deathType == "none"
            end
        },
        ['checkPlayerInsurance'] = {
            type = 'player',
            label = locale('check_insurance'),
            icon = 'fas fa-file-medical',
            distance = 2.0,
            jobs = {'ambulance'},
            onSelect = function(data)
                if Bridge.Progress.Start({
                    duration = 10000,
                    label = locale('checking_insurance'),
                    canCancel = true,
                    anim = {dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', clip = 'idle_a', flag = 49},
                    prop = {model = 'prop_cs_tablet', pos = vec3(0.0, 0.0, -0.02), rot = vec3(0.0, 0.0, 0.0)}
                }) then
                    local entity = type(data) == 'number' and data or data.entity
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                    TriggerServerEvent('p_ambulancejob/server/insurance/check', targetId)
                end
            end,
            canInteract = function(entity)
                return Death.deathType == "none"
            end
        },
        ['putPlayerInVehicle'] = {
            type = 'player',
            label = locale('put_in_vehicle'),
            icon = 'fas fa-car',
            distance = 2.0,
            jobs = {'ambulance'},
            onSelect = function(data, seat)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                TriggerServerEvent('p_ambulancejob/server/interactions/putInPlayer', {seat = seat, player = targetId})
            end,
            canInteract = function(entity, seat)
                -- to avoid duplicated options from both jobs :)
                if GetResourceState('p_policejob') == 'started' then
                    return false
                end

                if Death.deathType ~= "none" then
                    return false
                end

                local vehicle, coords = lib.getClosestVehicle(GetEntityCoords(cache.ped), 4.0, false)
                if not vehicle or vehicle == 0 or not IsVehicleSeatFree(vehicle, seat) or not NetworkGetEntityIsNetworked(vehicle) then
                    return false
                end

                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                return Player(targetId).state.isDead
            end,
        },
        ['takeOutPlayerVehicle'] = {
            type = 'vehicle',
            label = locale('take_out_vehicle'),
            icon = 'fas fa-car',
            distance = 3.0,
            jobs = {'ambulance'},
            onSelect = function(data, seat)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(entity, seat)))
                TriggerServerEvent('p_ambulancejob/server/interactions/takeOutPlayer', {seat = seat, player = targetId})
            end,
            canInteract = function(entity, seat)
                -- to avoid duplicated options from both jobs :)
                if GetResourceState('p_policejob') == 'started' then
                    return false
                end

                local seatPed = GetPedInVehicleSeat(entity, seat)
                if not seatPed or seatPed == 0 or not IsPedAPlayer(seatPed) then
                    return false
                end
                
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(seatPed))
                return Death.deathType == "none" and Player(targetId).state.isDead
            end
        },
        ['takePlayerBlood'] = {
            type = 'player',
            label = locale('collect_player_blood'),
            icon = 'fas fa-eye-dropper',
            distance = 3.0,
            jobs = {'ambulance'},
            onSelect = function(data)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                local function takePlayerBlood(amount)
                    if Bridge.Progress.Start({
                        duration = amount == 250 and 5000 or 10000,
                        label = locale('collecting_blood'),
                        canCancel = true,
                        anim = {dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 49},
                        prop = {model = 'prop_syringe_01', pos = vec3(0.04, 0.04, 0.0), rot = vec3(125.44, 0.0, 0.0), bone = 6286}
                    }) then
                        TriggerServerEvent('p_ambulancejob/server/interactions/takeBlood', targetId, amount)
                    end
                end
                lib.registerContext({
                    id = 'take_player_blood_menu',
                    title = locale('take_player_blood_menu'),
                    options = {
                        {
                            title = locale('take_250ml_blood'),
                            description = locale('take_250ml_blood_desc'),
                            icon = 'fas fa-eye-dropper',
                            onSelect = function()
                                takePlayerBlood(250)
                            end
                        },
                        {
                            title = locale('take_500ml_blood'),
                            description = locale('take_500ml_blood_desc'),
                            icon = 'fas fa-eye-dropper',
                            onSelect = function()
                                takePlayerBlood(500)
                            end
                        },
                    }
                })
                lib.showContext('take_player_blood_menu')
            end,
            canInteract = function(entity)
                if not Config.Interactions.playerBlood.enabled then
                    return false
                end

                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                return Death.deathType == "none" and not Player(targetId).state.isDead
            end,
        },
        ['carryPlayer'] = {
            type = 'player',
            label = locale('carry_player'),
            icon = 'fas fa-hands-helping',
            distance = 2.0,
            onSelect = function(data)
                local entity = type(data) == 'number' and data or data.entity
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                TriggerServerEvent('p_ambulancejob/server/interactions/carryPlayer', targetId)
            end,
            canInteract = function(entity)
                if GetResourceState('p_policejob') == 'started' then
                    return false
                end

                return Death.deathType == "none"
            end,
            needConfirm = true, -- require confirmation from other player before executing interaction
            animData = {
                carried = {
                    dict = 'nm',
                    clip = 'firemans_carry',
                    flag = 33,
                    offset = {
                        coords = vector3(0.25, -0.05, 0.63),
                        rotation = vector3(0.25, 0.0, 180.0)
                    }
                },
                carrying = {
                    dict = 'missfinale_c2mcs_1',
                    clip = 'fin_c2_mcs_1_camman',
                    flag = 49
                }
            }
        }
    }
}

---@class Config.GPS
---@field allowedJobs table<string> [which jobs are allowed to use GPS]
Config.GPS = {
    requiredItem = true, -- true = gps will turn off when player remove gps item from inventory
    allowedJobs = {'ambulance'},
    showHeading = true, -- show heading on gps?
    types = {
        ['walk'] = {sprite = 1, color = 1, sirenColor = 63, scale = 1.1},
        ['car'] = {sprite = 56, color = 1, sirenColor = 63, scale = 1.1},
        ['boat'] = {sprite = 755, color = 1, sirenColor = 63, scale = 1.1},
        ['heli'] = {sprite = 43, color = 1, sirenColor = 63, scale = 1.1},
        ['plane'] = {sprite = 758, color = 1, sirenColor = 63, scale = 1.1}
    }
}

---@class Config.Elevators
---@field enabled boolean [enable elevators feature?]
---@field points table<string, ElevPoint> [list of elevator points]

Config.Elevators = {
    enabled = true,
    points = {} -- points are added from thread at top of file
}

---@class Config.Beds
---@field enabled boolean [enable beds feature?]
---@field coords table<vec3> [list of coords where player can lie on bed]
---@field models table<string | number, {offset: vec3, rot: vec3, detach?: vec3}> [list of bed models with their offset and rotation]
---@field detach? vec3 [optional detach position of player from bed, if not set, player will be detached on default offset vec3(0.0, -1.0, 0.0)]
Config.Beds = {
    enabled = true,
    -- useful if bed is not an object
    coords = {
        {
            target = vec3(312.42, -598.66, 42.79), -- target coords where player can lie on bed
            offset = vec4(312.21, -598.91, 43.79, 167.00), -- coords where player will be placed when lying on bed
        }
    },
    models = {
        [joaat('kiiya_pillbox_prop_bed_3')] = {
            offset = vec3(0.0, 0.0, 1.75),
            rot = vec3(-0.05, 0.0, 90.0)
        },
        [joaat('fm_hsp_med_bed_02')] = {
            offset = vec3(0.0, 0.0, 1.25),
            rot = vec3(0.0, 0.0, 270.0)
        },
        [joaat('fm_hsp_med_bed_01')] = {
            offset = vec3(0.0, 0.0, 1.25),
            rot = vec3(0.0, 0.0, 90.0)
        },
        [joaat('wx_hospital_bed')] = {
            offset = vec3(-0.2, 0.0, 1.825),
            rot = vec3(0.0, 0.0, 180.0),
            detach = vec3(0.0, -1.65, 0.0)
        },
        [joaat('promt_hospital_sandy_bed2')] = {
            offset = vec3(-0.2, 0.0, 1.825),
            rot = vec3(0.0, 0.0, 180.0),
            detach = vec3(0.0, -1.65, 0.0)
        },
        [joaat('v_med_bed1')] = {
            offset = vec3(-0.2, 0.0, 1.35),
            rot = vec3(0.0, 0.0, 180.0),
            detach = vec3(0.0, -1.65, 0.0)
        },
        [joaat('5d_pillbox_letto1')] = {
            offset = vec3(-0.2, 0.0, 1.35),
            rot = vec3(0.0, 0.0, 180.0),
            detach = vec3(0.0, -1.65, 0.0)
        },
        [joaat('v_diables_hopital_bed01')] = {
            offset = vec3(-0.2, 0.0, 1.35),
            rot = vec3(0.0, 0.0, 180.0),
            detach = vec3(0.0, -1.65, 0.0)
        },
        [joaat('aldore_hospital_med_bed')] = {
            offset = vec3(-0.2, 0.0, 1.35),
            rot = vec3(0.0, 0.0, 90.0),
            detach = vec3(0.0, -1.65, 0.0)
        }
    },
    anims = {
        {dict = 'missfinale_c1@', clip = 'lying_dead_player0', flag = 1}
    }
}

---@class Config.Outfits
---@field enabled: boolean [enable outfits feature?]
---@field access table<{[jobName]: grade}> [which jobs and grades are allowed to create outfits]
Config.Outfits = {
    enabled = true,
    access = {
        ['ambulance'] = 0
    }
}

---@class Config.Sounds
---@field enabled boolean [enable sounds feature?]
---@field presets table<string, {volume: number [0.0 - 1.0], sounds: table<string>}> [list of sound presets with their volume and sound files]
--- You can use Sounds:play('sound_name', volume) to play a sound, sounds must be in web/sounds folder!
Config.Sounds = {
    enabled = true,
    presets = {
        ['damage'] = {
            volume = 0.1,
            sounds = {'fracture1.wav', 'fracture2.wav'}
        },
        ['heal'] = {
            volume = 0.15,
            sounds = {'inject.wav'}
        },
        ['bleeding'] = {
            volume = 0.15,
            sounds = {'slowheartbeat.wav'}
        },
    }
}

---@class Config.BloodTypes
---@field enabled boolean [enable blood types feature?, true = script will assign blood type to player and blood bags will have blood types]
---@field overwriteQB boolean [set to true if you want to overwrite qb blood types, if false you should set types in qb config]
---@field types string[] [list of blood types available in the server]
Config.BloodTypes = {
    enabled = false,
    overwriteQB = false,
    types = {'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'},
}
