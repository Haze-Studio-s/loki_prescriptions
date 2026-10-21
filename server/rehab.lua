--[[
    ============================================================================
    Loki Medical Suite - Physical Rehabilitation Engine (Server)
    Authoritative QBox/OneSync State Bags, Progressive Stages & Persistence
    ============================================================================
]]

local activeRecoveries = {}   -- [identifier] = recovery record
local bandageCooldowns = {}   -- [identifier] = os.time() of last bandage application

local DEFAULT_WHEELCHAIR_RATIO = 0.6
local DEFAULT_MIN_STAGE_SECONDS = 15

---------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------

local function getIdentifier(src)
    local s = tonumber(src)
    if not s or s <= 0 then return nil end
    return Bridge.Framework.getUniqueId(s)
end

local function getPlayerName(src)
    local s = tonumber(src)
    if not s or s <= 0 then return "Desconhecido" end
    return Bridge.Framework.getPlayerName(s) or GetPlayerName(s) or ("ID " .. tostring(s))
end

local function isAllowedMedic(src)
    local s = tonumber(src)
    if not s or s <= 0 then return false end
    local job = Bridge.Framework.getPlayerJob(s)
    if not job then return false end

    local cfgJobs = Config.Crutch.allowedJobs or { ['ambulance'] = 0, ['doctor'] = 0 }
    local minGrade = tonumber(cfgJobs[job.name])
    local playerGrade = tonumber(job.grade) or 0
    if minGrade ~= nil and playerGrade >= minGrade then
        return true
    end

    if Config.PrescriptionJobs then
        for _, allowed in ipairs(Config.PrescriptionJobs) do
            if allowed == job.name then return true end
        end
    end

    return false
end

local function findSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and getIdentifier(src) == identifier then
            return src
        end
    end
    return nil
end

local function buildClientPayload(record)
    local now = os.time()
    return {
        active = true,
        mode = record.mode,
        duration = record.duration,
        remaining = math.max(1, record.endsAt - now),
        endsAt = record.endsAt,
        startedAt = record.startedAt,
        nextStage = record.nextStage,
        nextDuration = record.nextDuration,
        appliedByName = record.appliedByName or "Corpo Médico",
        targetName = record.targetName
    }
end

local function rowToRecord(row)
    return {
        mode = row.mode,
        duration = tonumber(row.duration),
        startedAt = tonumber(row.started_at),
        endsAt = tonumber(row.ends_at),
        nextStage = row.next_stage,
        nextDuration = row.next_duration and tonumber(row.next_duration) or nil,
        appliedBy = row.applied_by,
        appliedByName = row.applied_by_name,
        targetName = row.target_name,
    }
end

local function planProgressiveStages(mode, duration, wantsProgressive)
    local cfg = Config.Rehab and Config.Rehab.progressiveStages or { enabled = true, wheelchairRatio = 0.6, minStageDuration = 15 }
    local opts = {}

    if not wantsProgressive or not cfg.enabled or mode ~= "wheelchair" then
        return duration, opts, false
    end

    local ratio = cfg.wheelchairRatio or DEFAULT_WHEELCHAIR_RATIO
    local first = math.floor(duration * ratio + 0.5)
    local second = duration - first
    local minStage = cfg.minStageDuration or DEFAULT_MIN_STAGE_SECONDS

    if first >= minStage and second >= minStage then
        opts.nextStage = "crutch"
        opts.nextDuration = second
        return first, opts, false
    end

    return duration, opts, true -- downgraded to single stage because duration was too short
end

---------------------------------------------------------------------
-- Core State Machine: Start / Transition / Stop
---------------------------------------------------------------------

local function startRecovery(target, mode, duration, appliedBy, opts)
    if not (target and mode and duration) or duration <= 0 then
        return false, "invalid_params"
    end

    local identifier = getIdentifier(target)
    if not identifier then return false, "no_identifier" end

    if activeRecoveries[identifier] then
        return false, "already_in_recovery"
    end

    opts = opts or {}
    local now = os.time()

    local record = {
        mode = mode,
        duration = duration,
        startedAt = now,
        endsAt = now + duration,
        appliedBy = appliedBy and getIdentifier(appliedBy) or nil,
        appliedByName = appliedBy and getPlayerName(appliedBy) or "Corpo Médico",
        targetName = getPlayerName(target),
        nextStage = opts.nextStage,
        nextDuration = opts.nextDuration,
    }

    activeRecoveries[identifier] = record
    RehabDB.Upsert(identifier, record)

    local payload = buildClientPayload(record)
    Player(target).state:set('loki_rehab', payload, true)
    TriggerClientEvent("loki_prescriptions:rehab:client:startRecovery", target, payload)

    return true
end

local function transitionStage(identifier)
    local record = activeRecoveries[identifier]
    if not (record and record.nextStage and record.nextDuration) then
        return false
    end

    local now = os.time()
    record.mode = record.nextStage
    record.duration = record.nextDuration
    record.startedAt = now
    record.endsAt = now + record.nextDuration
    record.nextStage = nil
    record.nextDuration = nil

    RehabDB.Upsert(identifier, record)

    local targetSrc = findSourceByIdentifier(identifier)
    if targetSrc then
        local payload = buildClientPayload(record)
        Player(targetSrc).state:set('loki_rehab', payload, true)
        TriggerClientEvent("loki_prescriptions:rehab:client:transitionStage", targetSrc, payload)
        Bridge.Notify.showNotify(targetSrc, "Fase 1 concluída! Sua reabilitação progrediu para uso de muletas ortopédicas.", "inform")
    end

    return true
end

local function stopRecovery(targetOrId, reason)
    local identifier
    local targetSrc

    if type(targetOrId) == "number" then
        targetSrc = targetOrId
        identifier = getIdentifier(targetSrc)
    else
        identifier = targetOrId
        targetSrc = findSourceByIdentifier(identifier)
    end

    if not identifier then return false end

    local record = activeRecoveries[identifier]
    if not record then return false end

    activeRecoveries[identifier] = nil
    RehabDB.Delete(identifier)

    if targetSrc then
        Player(targetSrc).state:set('loki_rehab', nil, true)
        TriggerClientEvent("loki_prescriptions:rehab:client:stopRecovery", targetSrc, reason or "completed")

        if reason == "ems_removed" then
            Bridge.Notify.showNotify(targetSrc, "Sua reabilitação física foi finalizada pelo médico responsável.", "inform")
        elseif reason == "natural" then
            Bridge.Notify.showNotify(targetSrc, "Parabéns! Seu ciclo de reabilitação física foi concluído com sucesso.", "success")
        end
    end

    return true
end

---------------------------------------------------------------------
-- Exports & API
---------------------------------------------------------------------

exports("StartRehab", startRecovery)
exports("StopRehab", stopRecovery)
exports("GetActiveRehab", function(target)
    local identifier = getIdentifier(target)
    return identifier and activeRecoveries[identifier] or nil
end)
exports("GetAllActiveRehabs", function()
    return activeRecoveries
end)

---------------------------------------------------------------------
-- Network Events: LSMC Tablet & Field Paramedic Interactions
---------------------------------------------------------------------

-- Request list of nearby patients for Tablet & UI
RegisterNetEvent("loki_prescriptions:rehab:server:requestNearbyPatients", function()
    local src = source
    if not isAllowedMedic(src) then
        Bridge.Notify.showNotify(src, "Acesso restrito ao corpo médico hospitalar.", "error")
        return
    end

    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)
    local maxDist = Config.Rehab and Config.Rehab.maxDistance or 6.0
    local list = {}
    local now = os.time()

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id and id ~= src then
            local targetPed = GetPlayerPed(id)
            if targetPed and targetPed ~= 0 then
                local dist = #(srcCoords - GetEntityCoords(targetPed))
                if dist <= maxDist then
                    local identifier = getIdentifier(id)
                    local record = identifier and activeRecoveries[identifier] or nil

                    list[#list + 1] = {
                        id = id,
                        name = getPlayerName(id),
                        distance = math.floor(dist * 10) / 10,
                        inRecovery = record ~= nil,
                        mode = record and record.mode or nil,
                        remaining = record and math.max(0, record.endsAt - now) or 0,
                        nextStage = record and record.nextStage or nil
                    }
                end
            end
        end
    end

    TriggerClientEvent("loki_prescriptions:rehab:client:receiveNearbyPatients", src, list)
end)

-- Apply rehabilitation plan to a patient
RegisterNetEvent("loki_prescriptions:rehab:server:apply", function(data)
    local src = source
    if not isAllowedMedic(src) then
        Bridge.Notify.showNotify(src, "Você não tem autorização para prescrever reabilitação.", "error")
        return
    end

    if type(data) ~= "table" then return end
    local target = tonumber(data.target)
    local mode = tostring(data.mode)
    local duration = tonumber(data.duration)
    local progressive = data.progressive == true

    if not target or (mode ~= "wheelchair" and mode ~= "crutch") or not duration or duration <= 0 then
        Bridge.Notify.showNotify(src, "Dados de prescrição inválidos.", "error")
        return
    end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if not targetPed or targetPed == 0 then
        Bridge.Notify.showNotify(src, "Paciente não encontrado ou desconectado.", "error")
        return
    end

    local maxDist = Config.Rehab and Config.Rehab.maxDistance or 6.0
    if #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) > maxDist then
        Bridge.Notify.showNotify(src, "Paciente está muito longe para aplicar o equipamento.", "error")
        return
    end

    local identifier = getIdentifier(target)
    if activeRecoveries[identifier] then
        Bridge.Notify.showNotify(src, "Este paciente já se encontra em reabilitação ativa.", "error")
        return
    end

    local finalDuration, opts, downgraded = planProgressiveStages(mode, duration, progressive)
    local ok, err = startRecovery(target, mode, finalDuration, src, opts)

    if ok then
        local equipLabel = (mode == "wheelchair") and "Cadeira de Rodas" or "Muletas Ortopédicas"
        local durationMin = math.floor(duration / 60)
        Bridge.Notify.showNotify(src, string.format("Reabilitação iniciada para %s (%s, %d min).", getPlayerName(target), equipLabel, durationMin), "success")
        Bridge.Notify.showNotify(target, string.format("Você recebeu %s por recomendação médica (%d min).", equipLabel, durationMin), "inform")

        if downgraded then
            Bridge.Notify.showNotify(src, "Duração muito curta para divisão em 2 fases. Aplicado estágio único.", "warning")
        end
    else
        Bridge.Notify.showNotify(src, "Falha ao iniciar reabilitação: " .. tostring(err), "error")
    end
end)

-- Discharge / Remove rehabilitation equipment
RegisterNetEvent("loki_prescriptions:rehab:server:remove", function(targetId)
    local src = source
    if not isAllowedMedic(src) then
        Bridge.Notify.showNotify(src, "Você não tem autorização para dar alta.", "error")
        return
    end

    local target = tonumber(targetId)
    if not target then return end

    local identifier = getIdentifier(target)
    if not (identifier and activeRecoveries[identifier]) then
        Bridge.Notify.showNotify(src, "Este paciente não possui reabilitação ativa.", "error")
        return
    end

    stopRecovery(target, "ems_removed")
    Bridge.Notify.showNotify(src, string.format("Reabilitação de %s foi removida com sucesso.", getPlayerName(target)), "success")
end)

-- Accelerate recovery via Bandage application (-60s)
RegisterNetEvent("loki_prescriptions:rehab:server:useBandage", function(targetId)
    local src = source
    if not isAllowedMedic(src) then
        Bridge.Notify.showNotify(src, "Apenas socorristas autorizados podem acelerar a cura por bandagem.", "error")
        return
    end

    local target = tonumber(targetId) or src
    local identifier = getIdentifier(target)
    local record = identifier and activeRecoveries[identifier]
    if not record then
        Bridge.Notify.showNotify(src, "Paciente não possui reabilitação ativa.", "error")
        return
    end

    local now = os.time()
    local lastUsed = bandageCooldowns[identifier] or 0
    local cooldown = Config.Rehab and Config.Rehab.bandage and Config.Rehab.bandage.cooldown or 30
    local elapsed = now - lastUsed

    if elapsed < cooldown then
        Bridge.Notify.showNotify(src, string.format("Aguarde %d segundos antes de aplicar outra bandagem.", cooldown - elapsed), "error")
        return
    end

    local bandageItem = Config.Rehab and Config.Rehab.bandage and Config.Rehab.bandage.itemName or 'bandage'
    local hasItem = Bridge.Inventory.getItemCount(src, bandageItem) > 0

    if not hasItem then
        Bridge.Notify.showNotify(src, "Você precisa de uma bandagem no inventário.", "error")
        return
    end

    -- Fail-closed item removal
    local removed = Bridge.Inventory.removeItem(src, bandageItem, 1)
    if not removed then
        Bridge.Notify.showNotify(src, "Falha ao consumir a bandagem.", "error")
        return
    end

    bandageCooldowns[identifier] = now
    local secondsRemoved = Config.Rehab and Config.Rehab.bandage and Config.Rehab.bandage.secondsRemoved or 60
    record.endsAt = math.max(now + 1, record.endsAt - secondsRemoved)
    record.duration = math.max(1, record.duration - secondsRemoved)

    RehabDB.UpdateEnd(identifier, record.endsAt, record.duration)

    local payload = buildClientPayload(record)
    Player(target).state:set('loki_rehab', payload, true)
    TriggerClientEvent("loki_prescriptions:rehab:client:updateRecovery", target, { secondsRemoved = secondsRemoved })

    Bridge.Notify.showNotify(src, string.format("Curativo aplicado em %s (-%d seg de repouso).", getPlayerName(target), secondsRemoved), "success")
    Bridge.Notify.showNotify(target, string.format("Curativo aplicado! Seu tempo de repouso foi reduzido em %d segundos.", secondsRemoved), "success")
end)

-- Extend recovery when patient was standing out of wheelchair
RegisterNetEvent("loki_prescriptions:rehab:server:extendRecovery", function(seconds)
    local src = source
    local identifier = getIdentifier(src)
    local record = identifier and activeRecoveries[identifier]
    if not record then return end

    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return end

    seconds = math.min(seconds, 3600)
    record.endsAt = record.endsAt + seconds

    RehabDB.UpdateEnd(identifier, record.endsAt, record.duration)
    local payload = buildClientPayload(record)
    Player(src).state:set('loki_rehab', payload, true)
end)

-- Natural timer conclusion triggered by client or server
RegisterNetEvent("loki_prescriptions:rehab:server:recoveryEnded", function()
    local src = source
    local identifier = getIdentifier(src)
    local record = identifier and activeRecoveries[identifier]
    if not record then return end

    if record.nextStage and record.nextDuration then
        transitionStage(identifier)
    else
        stopRecovery(src, "natural")
    end
end)

---------------------------------------------------------------------
-- Lifecycle: Reconnect, Player Loaded, Server Restart
---------------------------------------------------------------------

local function restorePlayerState(src)
    local identifier = getIdentifier(src)
    if not identifier then return end

    local record = activeRecoveries[identifier]
    if not record then
        local row = RehabDB.FetchByIdentifier(identifier)
        if row then
            record = rowToRecord(row)
            activeRecoveries[identifier] = record
        end
    end

    if not record then
        Player(src).state:set('loki_rehab', nil, true)
        return
    end

    local now = os.time()
    if record.endsAt <= now then
        if record.nextStage and record.nextDuration then
            transitionStage(identifier)
        else
            stopRecovery(src, "natural")
        end
        return
    end

    local payload = buildClientPayload(record)
    Player(src).state:set('loki_rehab', payload, true)
    TriggerClientEvent("loki_prescriptions:rehab:client:startRecovery", src, payload)
end

RegisterNetEvent("QBCore:Server:PlayerLoaded", function()
    restorePlayerState(source)
end)

RegisterNetEvent("qbx_core:server:playerLoaded", function()
    restorePlayerState(source)
end)

RegisterNetEvent("loki_prescriptions:rehab:server:requestState", function()
    restorePlayerState(source)
end)

AddEventHandler("loki_prescriptions:rehab:databaseReady", function()
    local rows = RehabDB.FetchAllActive()
    for _, row in ipairs(rows) do
        activeRecoveries[row.identifier] = rowToRecord(row)
    end
    print(("^2[Loki Medical]^7 Carregadas %d reabilitações ativas do banco de dados."):format(#rows))

    for _, playerId in ipairs(GetPlayers()) do
        restorePlayerState(tonumber(playerId))
    end
end)

-- Periodic Server Watchdog (checks every 5s)
CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()

        for identifier, record in pairs(activeRecoveries) do
            if now >= record.endsAt then
                if record.nextStage and record.nextDuration then
                    transitionStage(identifier)
                else
                    local src = findSourceByIdentifier(identifier)
                    if src then
                        stopRecovery(src, "natural")
                    else
                        activeRecoveries[identifier] = nil
                        RehabDB.Delete(identifier)
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------------------
-- Legacy Backwards Compatibility Hooks
---------------------------------------------------------------------

RegisterNetEvent("p_ambulancejob/server/crutch/forceCrutch", function(data)
    if type(data) ~= "table" or not data.targetId or not data.time then return end
    local src = source
    local durationSec = (tonumber(data.time) or 5) * 60
    startRecovery(data.targetId, "crutch", durationSec, src, {})
end)

RegisterNetEvent("p_ambulancejob/server/wheelchair/forceWheelchair", function(data)
    if type(data) ~= "table" or not data.targetId or not data.time then return end
    local src = source
    local durationSec = (tonumber(data.time) or 5) * 60
    startRecovery(data.targetId, "wheelchair", durationSec, src, {})
end)

RegisterNetEvent("p_ambulancejob/server/crutch/remove", function(targetId)
    local src = source
    if isAllowedMedic(src) then
        stopRecovery(targetId, "ems_removed")
    end
end)
