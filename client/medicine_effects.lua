local isTakingPill = false

RegisterNetEvent('loki_prescriptions:client:applyMedicineEffects', function(medData, isOverdose)
    if not medData then return end
    local ped = PlayerPedId()

    -- Animação de Ingestão de Medicamento
    if lib and lib.progressBar then
        lib.progressBar({
            duration = 2000,
            label = ('Tomando %s...'):format(medData.label),
            useWhileDead = false,
            canCancel = false,
            anim = {
                dict = 'mp_suicide',
                clip = 'pill'
            },
            disable = {
                car = false,
                move = false,
                combat = true
            }
        })
    else
        RequestAnimDict('mp_suicide')
        local timeout = 0
        while not HasAnimDictLoaded('mp_suicide') and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
        TaskPlayAnim(ped, 'mp_suicide', 'pill', 8.0, -8.0, 2000, 49, 0, false, false, false)
        Wait(2000)
        ClearPedSecondaryTask(ped)
    end

    local effects = medData.vp_effects or {}

    -- 1. Restauração de Vida Gradual
    if effects.hp and effects.hp > 0 then
        local currentHp = GetEntityHealth(ped)
        local maxHp = GetEntityMaxHealth(ped)
        local newHp = math.min(maxHp, currentHp + effects.hp)
        SetEntityHealth(ped, newHp)
    end

    -- 2. Recuperação de Estamina
    if effects.stamina and effects.stamina > 0 then
        ResetPlayerStamina(PlayerId())
    end

    -- 3. Integração Direta com vp_needs
    if Config.EnableVpNeedsIntegration then
        -- Desengasgo / Interrupção de Crises de Tosse
        if effects.cure_choking then
            TriggerEvent('vp_needs:client:stopChoking')
            TriggerEvent('vp_needs:client:relieveChoking')
        end

        -- Alívio de Náusea Gástrica (Comida Estragada)
        if effects.cure_nausea then
            TriggerEvent('vp_needs:client:cureNausea')
            TriggerEvent('vp_needs:client:relievePoison')
        end

        -- Redução de Estresse
        if effects.stress and effects.stress < 0 then
            local stressRelief = math.abs(effects.stress)
            TriggerEvent('vp_needs:client:relieveStress', stressRelief)
            TriggerEvent('hud:client:relieveStress', stressRelief)
        end

        -- Aceleração de Desintoxicação / Parsons Rehab
        if effects.detox_boost then
            TriggerEvent('vp_needs:client:accelerateDetox')
        end
    end

    -- 4. Efeitos Severos em caso de Overdose (Intoxicação Medicamentosa)
    if isOverdose then
        CreateThread(function()
            local duration = (Config.Overdose and Config.Overdose.effectDuration) or 30
            SetTimecycleModifier("drug_drive_blend01")
            SetTimecycleModifierStrength(0.8)
            ShakeGameplayCam('DRUNK_SHAKE', 1.2)
            SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)

            local elapsed = 0
            while elapsed < duration do
                Wait(1000)
                elapsed = elapsed + 1
                if elapsed % 8 == 0 then
                    -- Náusea induzida por overdose
                    RequestAnimDict('missfam5_blackout')
                    if HasAnimDictLoaded('missfam5_blackout') then
                        TaskPlayAnim(ped, 'missfam5_blackout', 'vomit', 8.0, -8.0, 2000, 49, 0, false, false, false)
                    end
                end
            end

            ClearTimecycleModifier()
            StopGameplayCamShaking(true)
        end)
    end
end)