--[[
    ============================================================================
    Loki Medical Suite - Physical Rehabilitation Nausea & Punishment Effects
    Ported & Optimized from Oxlyn Crutch System
    Ramps intensity 0..1 when patient stands up and abandons wheelchair
    ============================================================================
]]

RehabEffects = {
    intensity = 0.0,
    rampUp = 8,         -- Segundos para atingir 1.0 fora da cadeira
    rampDown = 6,       -- Segundos para retornar a 0.0 sentado
    running = false,
    drunkLoaded = false,
}

local TICK_MS = 250
local TICKS_PER_SECOND = 1000 / TICK_MS

local function loadDrunkClipset()
    local clipset = Config.Wheelchair and Config.Wheelchair.drunkClipset or "move_m@drunk@verydrunk"
    RequestAnimSet(clipset)
    local attempts = 0
    while not HasAnimSetLoaded(clipset) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    RehabEffects.drunkLoaded = HasAnimSetLoaded(clipset)
end

local function stopCamShake()
    if IsGameplayCamShaking() then
        StopGameplayCamShaking(true)
    end
end

local function applyScreenEffects(intensity)
    local cfg = Config.Wheelchair or {}
    local mild = cfg.screenEffectMild or 'DrugsMichaelAliensFightIn'
    local heavy = cfg.screenEffectHeavy or 'DrugsMichaelAliensFight'

    if intensity >= 0.6 then
        if not AnimpostfxIsRunning(heavy) then
            AnimpostfxStop(mild)
            AnimpostfxPlay(heavy, 0, true)
        end
    elseif intensity >= 0.2 then
        if not AnimpostfxIsRunning(mild) then
            AnimpostfxStop(heavy)
            AnimpostfxPlay(mild, 0, true)
        end
    else
        AnimpostfxStopAll()
    end

    if intensity > 0.05 then
        SetTimecycleModifier("Drunk")
        SetTimecycleModifierStrength(intensity)
    else
        ClearTimecycleModifier()
    end

    if intensity > 0.4 then
        if not IsGameplayCamShaking() then
            ShakeGameplayCam("DRUNK_SHAKE", math.min(0.8, intensity))
        end
    else
        stopCamShake()
    end
end

local function applyMovement(intensity)
    local ped = cache.ped or PlayerPedId()
    local clipset = Config.Wheelchair and Config.Wheelchair.drunkClipset or "move_m@drunk@verydrunk"

    if intensity > 0.1 then
        if not RehabEffects.drunkLoaded then
            loadDrunkClipset()
        end
        if RehabEffects.drunkLoaded then
            SetPedMovementClipset(ped, clipset, 1.0)
        end
        SetPedIsDrunk(ped, true)
    else
        SetPedIsDrunk(ped, false)
        ResetPedMovementClipset(ped, 1.0)
    end
end

local function clearAllEffects()
    AnimpostfxStopAll()
    ClearTimecycleModifier()
    stopCamShake()
end

function RehabEffects.Start(isSeatedCallback)
    if RehabEffects.running then return end

    RehabEffects.running = true
    RehabEffects.intensity = 0.0
    RehabEffects.rampUp = Config.Wheelchair and Config.Wheelchair.nauseaRampUp or 8
    RehabEffects.rampDown = Config.Wheelchair and Config.Wheelchair.nauseaRampDown or 6

    loadDrunkClipset()

    CreateThread(function()
        local lastWarning = 0

        while RehabEffects.running do
            local seated = isSeatedCallback and isSeatedCallback() or false

            -- Decresce enquanto sentado, sobe enquanto estiver fora da cadeira
            local direction = seated and -1 or 1
            local rampSeconds = seated and RehabEffects.rampDown or RehabEffects.rampUp
            local step = direction * (1.0 / (rampSeconds * TICKS_PER_SECOND))

            RehabEffects.intensity = math.max(0.0, math.min(1.0, RehabEffects.intensity + step))

            applyScreenEffects(RehabEffects.intensity)
            applyMovement(RehabEffects.intensity)

            -- Aviso sonoro / notificação periódica para voltar à cadeira
            if not seated and (Config.Wheelchair and Config.Wheelchair.showReturnWarning) then
                local now = GetGameTimer()
                if now - lastWarning > 6000 then
                    lastWarning = now
                    Bridge.Notify.showNotify("Aviso Médico: Retorne à cadeira de rodas para evitar náuseas severas e desmaio!", "error")
                end
            end

            -- Em intensidade máxima (0.99+), aplica leve dano por esforço indevido
            if RehabEffects.intensity >= 0.99 then
                local ped = cache.ped or PlayerPedId()
                local hp = GetEntityHealth(ped)
                if hp > 120 then
                    SetEntityHealth(ped, hp - 1)
                end
            end

            -- Totalmente recuperado após sentar
            if seated and RehabEffects.intensity < 0.01 then
                clearAllEffects()
            end

            Wait(TICK_MS)
        end

        clearAllEffects()
        local ped = cache.ped or PlayerPedId()
        SetPedIsDrunk(ped, false)
        ResetPedMovementClipset(ped, 1.0)
    end)
end

function RehabEffects.Stop()
    RehabEffects.running = false
    RehabEffects.intensity = 0.0
    clearAllEffects()
    local ped = cache.ped or PlayerPedId()
    SetPedIsDrunk(ped, false)
    ResetPedMovementClipset(ped, 1.0)
end
