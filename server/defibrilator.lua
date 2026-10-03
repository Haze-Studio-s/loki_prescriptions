-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK 𝐀𝐤 𝐋𝐞𝐚𝐤𝐬 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

Defibrilator = {}

-- Defibrilator:useOnPatient – handle defibrillation result
-- self      : Defibrilator table
-- sourceSrv : server ID of the medic who used the device
-- targetId  : server ID of the patient
-- success   : bool – whether the defibrillation succeeded
function Defibrilator:useOnPatient(sourceSrv, targetId, success)
    local suffix = success and "success" or "fail"
    Bridge.Notify.showNotify(sourceSrv, locale("defibrilator_used_" .. suffix), "inform")

    -- On success, reset the patient's pulse
    if success then
        TriggerClientEvent("p_ambulancejob/client/pulse/reset", targetId)
    end
end
Defibrilator.useOnPatient = Defibrilator.useOnPatient

-- Event: useOnPatient – validate job then forward
RegisterNetEvent("p_ambulancejob/server/defibrilator/useOnPatient")
AddEventHandler("p_ambulancejob/server/defibrilator/useOnPatient", function(data)
    local sourceSrv = source
    local job       = Bridge.Framework.getPlayerJob(sourceSrv)

    -- Only allow players with an authorised job
    if not (job and Editable.allJobs[job.name]) then
        Bridge.Notify.showNotify(sourceSrv, locale("no_access"), "error")
        return
    end

    Defibrilator:useOnPatient(sourceSrv, data.targetId, data.result)
end)

-- Event: sync – attach defibrillator to a patient
-- AKA0_2 : server ID of the target patient
RegisterNetEvent("p_ambulancejob/server/defibrilator/sync")
AddEventHandler("p_ambulancejob/server/defibrilator/sync", function(targetId)
    local sourceSrv  = source
    local sourcePed  = GetPlayerPed(sourceSrv)
    local sourcePos  = GetEntityCoords(sourcePed)
    local targetPos  = GetEntityCoords(GetPlayerPed(targetId))

    -- Enforce proximity check (max 6 units)
    if #(sourcePos - targetPos) > 6.0 then return end

    -- Job authorisation check
    local job = Bridge.Framework.getPlayerJob(sourceSrv)
    if not (job and Editable.allJobs[job.name]) then
        Bridge.Notify.showNotify(sourceSrv, locale("no_access"), "error")
        return
    end

    -- Broadcast DUI sync to all clients, passing patient name
    local patientName = Bridge.Framework.getPlayerName(targetId)
    TriggerClientEvent("p_ambulancejob/client/defibrilator/syncDUI", -1, targetId, patientName)
end)

-- Event: remove – delete prop and return item
-- AKA0_2 : network ID of the defibrillator entity
-- AKA1_2 : server ID of the attached patient (for DUI removal)
RegisterNetEvent("p_ambulancejob/server/defibrilator/remove")
AddEventHandler("p_ambulancejob/server/defibrilator/remove", function(netId, attachedPlayerId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    -- Bail if entity does not exist
    if not (entity and entity ~= 0 and DoesEntityExist(entity)) then return end

    local sourceSrv = source
    local sourcePed = GetPlayerPed(sourceSrv)
    local sourcePos = GetEntityCoords(sourcePed)
    local entityPos = GetEntityCoords(entity)

    -- Enforce proximity check (max 6 units)
    if #(sourcePos - entityPos) > 6.0 then return end

    -- Job authorisation check
    local job = Bridge.Framework.getPlayerJob(sourceSrv)
    if not (job and Editable.allJobs[job.name]) then
        Bridge.Notify.showNotify(sourceSrv, locale("no_access"), "error")
        return
    end

    -- Remove the world prop, return item to inventory, clean up DUI
    DeleteEntity(entity)
    Bridge.Inventory.addItem(sourceSrv, "defibrilator", 1)
    TriggerClientEvent("p_ambulancejob/client/defibrilator/removeDUI", -1, attachedPlayerId)
end)