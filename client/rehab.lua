--[[
    ============================================================================
    Loki Medical Suite - Physical Rehabilitation Engine (Client)
    Handles Wheelchair Mechanics, Crutch Limp Walk, Pill HUD & Stage Progression
    ============================================================================
]]

RehabClient = {
    active = false,
    mode = nil,            -- 'wheelchair' or 'crutch'
    duration = 0,
    startedAtMs = 0,
    endsAtMs = 0,
    currentObject = nil,
    currentVehicle = nil,
    sittingOnChair = false,
    pausedAtMs = nil,
    timerOpen = false,
}

local TICK_INTERVAL_MS = 500

---------------------------------------------------------------------
-- Prop & Vehicle Spawning Helpers
---------------------------------------------------------------------

local function spawnCrutchProp()
    local cfg = Config.Crutch and Config.Crutch.prop or {}
    local modelHash = lib.requestModel(cfg.model or "prop_mads_crutch01")
    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)

    local bone = cfg.bone or 70
    local c = cfg.coords or vec3(1.18, -0.36, -0.20)
    local r = cfg.rot or vec3(-20.0, -87.0, -20.0)

    AttachEntityToEntity(
        prop, ped, bone,
        c.x, c.y, c.z,
        r.x, r.y, r.z,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

local function spawnWheelchairVehicle()
    local modelName = Config.Wheelchair and Config.Wheelchair.model or "iak_wheelchair"
    local ped = cache.ped or PlayerPedId()
    local modelHash = lib.requestModel(modelName)

    if not modelHash then
        -- Fallback to prop wheelchair if vehicle model is not found
        return nil
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.1)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, true)
    if not DoesEntityExist(veh) then
        return nil
    end

    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleHasBeenOwnedByPlayer(veh, true)

    if Bridge.Fuel then
        Bridge.Fuel.SetFuel(veh, 100.0)
    end

    if Bridge.CarKeys then
        Bridge.CarKeys.CreateKeys(GetVehicleNumberPlateText(veh), veh)
    end

    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(modelHash)

    return veh
end

---------------------------------------------------------------------
-- Pill HUD Timer (NUI Dispatcher)
---------------------------------------------------------------------

local function sendTickNUI(remaining, progress, paused)
    SendNUIMessage({
        action = "tickTimer",
        remaining = math.max(0, remaining),
        progress = math.min(1.0, math.max(0.0, progress)),
        mode = RehabClient.mode,
        paused = paused == true,
    })
end

local function startTimerHUD()
    if RehabClient.timerOpen then return end

    local labelText = (RehabClient.mode == "wheelchair") and "CADEIRA DE RODAS" or "MULETAS ORTOPÉDICAS"
    SendNUIMessage({
        action = "openTimer",
        position = "right",
        mode = RehabClient.mode,
        label = labelText,
    })

    RehabClient.timerOpen = true

    CreateThread(function()
        while RehabClient.active do
            local now = GetGameTimer()

            -- Timer is paused when standing out of wheelchair
            local isPaused = (RehabClient.mode == "wheelchair" and not RehabClient.sittingOnChair)

            if isPaused then
                if not RehabClient.pausedAtMs then
                    RehabClient.pausedAtMs = now
                    SendNUIMessage({ action = "timerPaused", paused = true })
                end

                local totalMs = math.max(1, RehabClient.duration * 1000)
                local elapsedMs = math.max(0, RehabClient.pausedAtMs - RehabClient.startedAtMs)
                local remainingMs = math.max(0, RehabClient.endsAtMs - RehabClient.pausedAtMs)
                local remainingSec = math.floor(remainingMs / 1000)
                local progress = elapsedMs / totalMs

                sendTickNUI(remainingSec, progress, true)
            else
                if RehabClient.pausedAtMs then
                    local pausedDuration = now - RehabClient.pausedAtMs
                    RehabClient.endsAtMs = RehabClient.endsAtMs + pausedDuration

                    if pausedDuration >= 1000 then
                        TriggerServerEvent("loki_prescriptions:rehab:server:extendRecovery", math.floor(pausedDuration / 1000))
                    end

                    RehabClient.pausedAtMs = nil
                    SendNUIMessage({ action = "timerPaused", paused = false })
                end

                local totalMs = math.max(1, RehabClient.duration * 1000)
                local elapsedMs = math.max(0, now - RehabClient.startedAtMs)
                local remainingMs = math.max(0, RehabClient.endsAtMs - now)
                local remainingSec = math.floor(remainingMs / 1000)
                local progress = elapsedMs / totalMs

                sendTickNUI(remainingSec, progress, false)

                if remainingSec <= 0 and RehabClient.active then
                    TriggerServerEvent("loki_prescriptions:rehab:server:recoveryEnded")
                    break
                end
            end

            Wait(TICK_INTERVAL_MS)
        end

        SendNUIMessage({ action = "closeTimer" })
        RehabClient.timerOpen = false
    end)
end

---------------------------------------------------------------------
-- Equipment Activation & Management
---------------------------------------------------------------------

function RehabClient.start(data)
    if not data or not data.mode then return end

    -- Cleanup any existing equipment first
    RehabClient.stop("restart")

    RehabClient.active = true
    RehabClient.mode = data.mode
    RehabClient.duration = tonumber(data.duration) or 300
    local remaining = tonumber(data.remaining) or RehabClient.duration

    local now = GetGameTimer()
    RehabClient.startedAtMs = now - ((RehabClient.duration - remaining) * 1000)
    RehabClient.endsAtMs = now + (remaining * 1000)

    local ped = cache.ped or PlayerPedId()

    if RehabClient.mode == "wheelchair" then
        RehabClient.sittingOnChair = true
        RehabClient.currentVehicle = spawnWheelchairVehicle()

        -- Watchdog thread for wheelchair: checks if player leaves the seat
        CreateThread(function()
            while RehabClient.active and RehabClient.mode == "wheelchair" do
                Wait(300)
                local currentPed = cache.ped or PlayerPedId()
                local inChair = false

                if RehabClient.currentVehicle and DoesEntityExist(RehabClient.currentVehicle) then
                    inChair = (GetVehiclePedIsIn(currentPed, false) == RehabClient.currentVehicle)
                end

                if inChair and not RehabClient.sittingOnChair then
                    -- Player sat back in the chair!
                    RehabClient.sittingOnChair = true
                elseif not inChair and RehabClient.sittingOnChair then
                    -- Player stood up / left the wheelchair!
                    RehabClient.sittingOnChair = false
                    RehabEffects.Start(function() return RehabClient.sittingOnChair end)
                end

                -- Disable exit if strict lock configured
                if Config.Wheelchair and Config.Wheelchair.disableExitWhenForced and inChair then
                    DisableControlAction(0, 75, true)
                end
            end
        end)

    elseif RehabClient.mode == "crutch" then
        RehabClient.sittingOnChair = false
        RehabClient.currentObject = spawnCrutchProp()

        -- Limp walking clipset
        local animSet = Config.Crutch and Config.Crutch.animSet or "move_lester_CaneUp"
        lib.requestAnimSet(animSet)
        SetPedMovementClipset(ped, animSet, 1.0)

        -- Control lock thread
        CreateThread(function()
            local disabledList = Config.Crutch and Config.Crutch.disabledControls or { 21, 22, 24, 25, 37, 140, 141, 142 }
            while RehabClient.active and RehabClient.mode == "crutch" do
                for _, ctrl in ipairs(disabledList) do
                    DisableControlAction(0, ctrl, true)
                end
                Wait(1)
            end
        end)

        -- Watchdog to recreate prop if despawned
        CreateThread(function()
            while RehabClient.active and RehabClient.mode == "crutch" do
                Wait(1500)
                if RehabClient.active and RehabClient.mode == "crutch" and not DoesEntityExist(RehabClient.currentObject) then
                    RehabClient.currentObject = spawnCrutchProp()
                end
            end
        end)
    end

    startTimerHUD()
end

function RehabClient.transition(data)
    if not data then return end

    -- Cleanup wheelchair
    if RehabClient.currentVehicle and DoesEntityExist(RehabClient.currentVehicle) then
        DeleteVehicle(RehabClient.currentVehicle)
        RehabClient.currentVehicle = nil
    end

    RehabEffects.Stop()

    -- Start crutch phase
    RehabClient.start(data)
end

function RehabClient.stop(reason)
    if not RehabClient.active then return end
    RehabClient.active = false

    if RehabClient.currentObject and DoesEntityExist(RehabClient.currentObject) then
        DeleteEntity(RehabClient.currentObject)
        RehabClient.currentObject = nil
    end

    if RehabClient.currentVehicle and DoesEntityExist(RehabClient.currentVehicle) then
        DeleteVehicle(RehabClient.currentVehicle)
        RehabClient.currentVehicle = nil
    end

    RehabEffects.Stop()

    local ped = cache.ped or PlayerPedId()
    ResetPedMovementClipset(ped, 1.0)
    SetPedIsDrunk(ped, false)

    SendNUIMessage({ action = "closeTimer" })
    RehabClient.timerOpen = false
end

---------------------------------------------------------------------
-- Network Events & State Bag Handler
---------------------------------------------------------------------

RegisterNetEvent("loki_prescriptions:rehab:client:startRecovery", function(payload)
    RehabClient.start(payload)
end)

RegisterNetEvent("loki_prescriptions:rehab:client:transitionStage", function(payload)
    RehabClient.transition(payload)
end)

RegisterNetEvent("loki_prescriptions:rehab:client:stopRecovery", function(reason)
    RehabClient.stop(reason)
end)

RegisterNetEvent("loki_prescriptions:rehab:client:updateRecovery", function(data)
    if not RehabClient.active or not data or not data.secondsRemoved then return end
    local removedMs = data.secondsRemoved * 1000
    RehabClient.endsAtMs = math.max(GetGameTimer() + 1000, RehabClient.endsAtMs - removedMs)
    RehabClient.duration = math.max(1, RehabClient.duration - data.secondsRemoved)
end)

-- OneSync State Bag Listener
AddStateBagChangeHandler('loki_rehab', nil, function(bagName, key, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == cache.playerId or ply == PlayerId() then
        if value and value.active then
            if not RehabClient.active then
                RehabClient.start(value)
            end
        else
            if RehabClient.active then
                RehabClient.stop("statebag_cleared")
            end
        end
    end
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("loki_prescriptions:rehab:server:requestState")
end)

---------------------------------------------------------------------
-- Paramedic Field Commands & Radial / Target Interactions
---------------------------------------------------------------------

local function isAllowedMedicClient()
    local job = Bridge.Framework.fetchPlayerJob()
    if not job then return false end

    local cfgJobs = Config.Crutch and Config.Crutch.allowedJobs or { ['ambulance'] = 0, ['doctor'] = 0 }
    local minGrade = cfgJobs[job.name]
    if minGrade ~= nil and (job.grade or 0) >= minGrade then
        return true
    end

    if Config.PrescriptionJobs then
        for _, allowed in ipairs(Config.PrescriptionJobs) do
            if allowed == job.name then return true end
        end
    end

    return false
end

-- Open Quick Field Menu for Paramedics
local function openFieldRehabMenu()
    if not isAllowedMedicClient() then
        Bridge.Notify.showNotify("Acesso restrito ao corpo médico.", "error")
        return
    end

    local ped = cache.ped or PlayerPedId()
    local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(ped), Config.Rehab and Config.Rehab.maxDistance or 6.0, true)
    local options = {}

    for _, pData in ipairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(pData.id)
        if serverId ~= cache.serverId then
            options[#options + 1] = {
                title = string.format("Paciente (ID %d)", serverId),
                description = "Prescrever Cadeira de Rodas ou Muletas Ortopédicas",
                icon = "wheelchair",
                onSelect = function()
                    local input = lib.inputDialog("Prescrição de Reabilitação Física", {
                        {
                            type = "select",
                            label = "Equipamento Médico",
                            options = {
                                { value = "wheelchair", label = "Cadeira de Rodas (Com Náusea ao Levantar)" },
                                { value = "crutch",     label = "Muletas Ortopédicas (Limp Walk Lester)" },
                            },
                            default = "wheelchair",
                            required = true,
                        },
                        {
                            type = "select",
                            label = "Tempo de Repouso / Tratamento",
                            options = {
                                { value = "300",  label = "5 Minutos" },
                                { value = "600",  label = "10 Minutos" },
                                { value = "900",  label = "15 Minutos" },
                                { value = "1800", label = "30 Minutos" },
                            },
                            default = "600",
                            required = true,
                        },
                        {
                            type = "checkbox",
                            label = "Recuperação Progressiva em 2 Fases (60% Cadeira → 40% Muletas)",
                            checked = true,
                        }
                    })

                    if not input then return end

                    TriggerServerEvent("loki_prescriptions:rehab:server:apply", {
                        target = serverId,
                        mode = input[1],
                        duration = tonumber(input[2]),
                        progressive = input[3] == true,
                    })
                end
            }
        end
    end

    if #options == 0 then
        Bridge.Notify.showNotify("Nenhum paciente próximo encontrado.", "error")
        return
    end

    lib.registerContext({
        id = "rehab_field_menu",
        title = "LSMC - Reabilitação Física de Campo",
        options = options
    })
    lib.showContext("rehab_field_menu")
end

RegisterCommand("rehab", openFieldRehabMenu, false)
RegisterCommand("crutch", openFieldRehabMenu, false)

-- Register Target on Players for EMS
CreateThread(function()
    Wait(1500)
    Bridge.Target.addPlayer({
        {
            name = "loki_rehab_remove",
            label = "Alta Médica / Remover Reabilitação",
            icon = "fa-solid fa-person-walking",
            distance = 2.5,
            groups = Config.Crutch and Config.Crutch.allowedJobs or { ['ambulance'] = 0, ['doctor'] = 0 },
            onSelect = function(targetData)
                local entity = (type(targetData) == "number" and targetData) or targetData.entity
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                TriggerServerEvent("loki_prescriptions:rehab:server:remove", targetSrc)
            end,
            canInteract = function(targetData)
                local entity = (type(targetData) == "number" and targetData) or targetData.entity
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                local targetState = Player(targetSrc).state
                return targetState and targetState.loki_rehab ~= nil
            end,
        },
        {
            name = "loki_rehab_bandage",
            label = "Aplicar Bandagem Rápida (-60s)",
            icon = "fa-solid fa-bandage",
            distance = 2.5,
            groups = Config.Crutch and Config.Crutch.allowedJobs or { ['ambulance'] = 0, ['doctor'] = 0 },
            onSelect = function(targetData)
                local entity = (type(targetData) == "number" and targetData) or targetData.entity
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                TriggerServerEvent("loki_prescriptions:rehab:server:useBandage", targetSrc)
            end,
            canInteract = function(targetData)
                local entity = (type(targetData) == "number" and targetData) or targetData.entity
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                local targetState = Player(targetSrc).state
                return targetState and targetState.loki_rehab ~= nil
            end,
        }
    })
end)

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("isRehabActive", function()
    return RehabClient.active
end)

exports("getRehabMode", function()
    return RehabClient.active and RehabClient.mode or nil
end)
