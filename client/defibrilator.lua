-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK 𝐀𝐤 𝐋𝐞𝐚𝐤𝐬 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

-- Wait until Config.Defibrilator is loaded
while not (Config and Config.Defibrilator) do
    Citizen.Wait(100)
end

-- Exit early if the defibrillator feature is disabled
if not Config.Defibrilator.enabled then
    return
end


-- Main defibrillator table, holds state (object, attachedPlayer, cam, points, etc.)
Defibrilator = {}
Defibrilator.points = {}

Citizen.CreateThread(function()
    Citizen.Wait(3000)

    local propModel = Config.Defibrilator.propModel or "lifepak15"

    -- Attach action: opens player selection context menu
    local attachOption = {
        name     = "p_ambulancejob/defibrilator/attach",
        label    = locale("attach_defibrilator"),
        icon     = "fa-solid fa-magnifying-glass",
        distance = 2.0,
        groups   = Editable.allJobs,
    }

    function attachOption.onSelect()
        local playerOptions = {}
        local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 7.0, false)

        for i = 1, #nearbyPlayers do
            local serverId = GetPlayerServerId(nearbyPlayers[i].id)
            local option = {
                title    = locale("player", serverId),
                icon     = "fa-solid fa-user",
                onSelect = function()
                    Defibrilator:attach(serverId)
                end,
            }
            playerOptions[#playerOptions + 1] = option
        end

        lib.registerContext({
            id      = "defibrilator_attach",
            title   = locale("select_player"),
            options = playerOptions,
        })
        lib.showContext("defibrilator_attach")
    end

    function attachOption.canInteract()
        return Defibrilator.object ~= nil
    end

    -- Use action: triggers defibrillation on the attached patient
    local useOption = {
        name     = "p_ambulancejob/defibrilator/use",
        label    = locale("use_defibrilator"),
        icon     = "fa-solid fa-heart-pulse",
        distance = 2.0,
        groups   = Editable.allJobs,
    }

    function useOption.onSelect()
        Defibrilator:useOnPatient()
    end

    function useOption.canInteract()
        return Defibrilator.attachedPlayer ~= nil
    end

    -- Remove action: removes the placed defibrillator prop
    local removeOption = {
        name     = "p_ambulancejob/defibrilator/remove",
        label    = locale("remove_defibrilator"),
        icon     = "fa-solid fa-trash",
        distance = 2.0,
        groups   = Editable.allJobs,
    }

    function removeOption.onSelect()
        Defibrilator:remove()
    end

    function removeOption.canInteract()
        return Defibrilator.object ~= nil
    end

    Bridge.Target.addModel(propModel, { attachOption, useOption, removeOption })
end)

function Defibrilator:use()
    -- Prevent re-entry if already in use
    if self.isUsing then return end

    -- Block if inside a vehicle
    if cache.vehicle and cache.vehicle ~= 0 then return end

    -- Check the player has an allowed job
    local job = Bridge.Framework.fetchPlayerJob()
    if not (job and Editable.allJobs[job.name]) then
        Bridge.Notify.showNotify(locale("no_access"), "error")
        return
    end

    self.isUsing = true

    -- Load and spawn a placement ghost object
    local propModel = Config.Defibrilator.propModel or "lifepak15"
    local modelHash = lib.requestModel(propModel)
    local ghostObject = CreateObject(modelHash, GetEntityCoords(cache.ped), false, true, true)
    FreezeEntityPosition(ghostObject, true)
    SetEntityCollision(ghostObject, false, false)
    SetEntityAlpha(ghostObject, 200)
    PlaceObjectOnGroundProperly(ghostObject)

    -- Thread to disable combat/weapon controls while placing
    Citizen.CreateThread(function()
        while self.isUsing do
            Citizen.Wait(1)
            DisableControlAction(0, 24,  true) -- attack
            DisableControlAction(0, 69,  true) -- aim
            DisableControlAction(0, 92,  true) -- next weapon
            DisableControlAction(0, 106, true) -- weapon wheel
            DisableControlAction(0, 257, true) -- attack 2
            DisableControlAction(1, 24,  true) -- attack (gamepad)
            DisableControlAction(0, 14,  true) -- scroll wheel up
            DisableControlAction(0, 15,  true) -- scroll wheel down
        end
    end)

    -- Main placement loop
    while self.isUsing do
        Citizen.Wait(0)

        -- Disable combat/weapon controls and hijack scroll wheel while placing
        DisableControlAction(0, 24,  true) -- attack
        DisableControlAction(0, 69,  true) -- aim
        DisableControlAction(0, 92,  true) -- next weapon
        DisableControlAction(0, 106, true) -- weapon wheel
        DisableControlAction(0, 257, true) -- attack 2
        DisableControlAction(1, 24,  true) -- attack (gamepad)
        DisableControlAction(0, 14,  true) -- scroll wheel up   (prevent camera zoom)
        DisableControlAction(0, 15,  true) -- scroll wheel down (prevent camera zoom)

        -- Raycast from camera to find ground placement position
        -- lib.raycast.fromCamera returns: hit, distance, coords, entityHit
        local hit, _, hitCoords, _ = lib.raycast.fromCamera(511, 4, 10.0)
        if hit and hit ~= 0 then
            SetEntityCoordsNoOffset(ghostObject, hitCoords.x, hitCoords.y, hitCoords.z, true, true, true)
            PlaceObjectOnGroundProperly(ghostObject)
        end

        -- Rotate with scroll wheel (15 degrees per tick for a snappy feel)
        if IsDisabledControlPressed(0, 14) then
            SetEntityHeading(ghostObject, GetEntityHeading(ghostObject) + 15.0)
        elseif IsDisabledControlPressed(0, 15) then
            SetEntityHeading(ghostObject, GetEntityHeading(ghostObject) - 15.0)
        end

        -- Confirm placement (attack / enter)
        if IsDisabledControlPressed(0, 24) then
            local spawnCoords  = GetEntityCoords(ghostObject)
            local spawnHeading = GetEntityHeading(ghostObject)
            self:spawn(spawnCoords, spawnHeading)
            DeleteEntity(ghostObject)
            self.isUsing = false
            break
        -- Cancel placement (X / back)
        elseif IsControlPressed(0, 73) then
            DeleteEntity(ghostObject)
            SetModelAsNoLongerNeeded(modelHash)
            self.isUsing = false
            break
        end
    end
end
Defibrilator.use = Defibrilator.use

RegisterNetEvent("p_ambulancejob/client/defibrilator/use")
AddEventHandler("p_ambulancejob/client/defibrilator/use", function()
    Defibrilator:use()
end)

function Defibrilator:spawn(coords, heading)
    -- Remove item from player inventory on spawn
    TriggerServerEvent("p_bridge/server/removeItem", "defibrilator", 1)

    local propModel = Config.Defibrilator.propModel or "lifepak15"
    local modelHash = lib.requestModel(propModel)

    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, true)
    self.object = obj

    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(modelHash)
end
Defibrilator.spawn = Defibrilator.spawn

RegisterNetEvent("p_ambulancejob/client/defibrilator/syncDUI")
AddEventHandler("p_ambulancejob/client/defibrilator/syncDUI", function(serverId, patientName)
    Defibrilator:syncDUI(serverId, patientName)
end)

RegisterNetEvent("p_ambulancejob/client/defibrilator/removeDUI")
AddEventHandler("p_ambulancejob/client/defibrilator/removeDUI", function(serverId)
    Defibrilator:removeDUI(serverId)
end)

-- Remove a DUI point for a given player
function Defibrilator:removeDUI(serverId)
    local point = self.points[serverId]
    if not point then return end

    self.points[serverId]:remove()
    self.points[serverId] = nil
end
Defibrilator.removeDUI = Defibrilator.removeDUI

-- Create a proximity point that shows the ECG DUI screen when nearby
function Defibrilator:syncDUI(serverId, patientName)
    -- Skip if a point already exists for this player
    if self.points[serverId] then return end

    local point = lib.points.new({
        coords   = GetEntityCoords(cache.ped),
        distance = 5,
    })

    -- On enter: create the DUI and start ECG update loop
    function point.onEnter(self)
        local duiUrl   = ("nui://%s/web/ecg.html"):format(cache.resource)
        local debugMode = (Bridge and Bridge.Config and Bridge.Config.Debug) or false

        local dui = lib.dui:new({
            url    = duiUrl,
            width  = 1920,
            height = 1080,
            debug  = debugMode,
        })
        self.dui = dui

        Citizen.Wait(100)
        -- Replace the lifepak monitor texture with the DUI.
        -- ox_lib DUI exposes the runtime texture via :getTextureDict() / :getTextureName()
        AddReplaceTexture("lifepak15", "55_002_lifepak15monitorde_220a_2", dui.dictName, dui.txtName)

        -- Poll player state and push ECG data to the DUI every 2 seconds
        Citizen.CreateThread(function()
            while self.dui do
                local playerState = Player(serverId).state
                dui:sendMessage({
                    action = "updateECG",
                    value  = {
                        heartRate   = playerState.pulse      or 0,
                        temperature = playerState.temperature or 0,
                        patientName = patientName,
                    },
                })
                Citizen.Wait(2000)
            end
        end)
    end

    -- On exit: destroy the DUI and restore the original texture
    function point.onExit(self)
        self.dui:remove()
        self.dui = nil
        RemoveReplaceTexture("lifepak15", "55_002_lifepak15monitorde_220a_2")
    end

    self.points[serverId] = point
end
Defibrilator.syncDUI = Defibrilator.syncDUI

function Defibrilator:attach(serverId)
    if not self.object then return end

    -- Patient must have a critical pulse state
    local patientState = Player(serverId).state
    if not patientState.criticalPulse then
        Bridge.Notify.showNotify(locale("player_no_critical_pulse"), "error")
        return
    end

    self.attachedPlayer = serverId
    TriggerServerEvent("p_ambulancejob/server/defibrilator/sync", serverId)
end
Defibrilator.attach = Defibrilator.attach

function Defibrilator:remove()
    if not self.object then return end

    local netId = NetworkGetNetworkIdFromEntity(self.object)
    TriggerServerEvent("p_ambulancejob/server/defibrilator/remove", netId, self.attachedPlayer)
    self.object         = nil
    self.attachedPlayer = nil
end
Defibrilator.remove = Defibrilator.remove

function Defibrilator:useOnPatient()
    -- Require both a placed object and an attached patient
    if not (self.cam or self.attachedPlayer) then return end

    -- Play the medic animation
    local animDict = lib.requestAnimDict("amb@medic@standing@tendtodead@base")
    TaskPlayAnim(cache.ped, animDict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Create a cinematic camera focused on the patient
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self.cam = cam

    local patientPed    = GetPlayerPed(GetPlayerFromServerId(self.attachedPlayer))
    local camOffset     = GetOffsetFromEntityInWorldCoords(patientPed, -1.25, 1.0, 0.25)

    SetCamCoord(cam, camOffset.x, camOffset.y, camOffset.z)
    SetCamFov(cam, 40.0)
    PointCamAtEntity(cam, patientPed, 0.0, 0.0, -0.5, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)

    Citizen.Wait(2000)

    -- Run the config-defined onUse callback and report result to server
    local result = Config.Defibrilator.onUse()
    TriggerServerEvent("p_ambulancejob/server/defibrilator/useOnPatient", {
        targetId = self.attachedPlayer,
        result   = result,
    })

    -- Stop animation
    StopAnimTask(cache.ped, "amb@medic@standing@tendtodead@base", "base", 3.0)

    Citizen.Wait(1000)

    -- Restore normal camera
    RenderScriptCams(false, true, 1000, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, false)
    self.cam            = nil
    self.attachedPlayer = nil
end
Defibrilator.useOnPatient = Defibrilator.useOnPatient

function Defibrilator:playReviving()
    local animDict = lib.requestAnimDict("mini@cpr@char_b@cpr_str")
    TaskPlayAnim(cache.ped, animDict, "cpr_pumpchest", 8.0, -8.0, -1, 1, 0, false, false, false)
    RemoveAnimDict(animDict)
end
Defibrilator.playReviving = Defibrilator.playReviving

RegisterNetEvent("p_ambulancejob/client/defibrilator/playReviving")
AddEventHandler("p_ambulancejob/client/defibrilator/playReviving", function()
    Defibrilator:playReviving()
end)