--[[
    ============================================================================
    Módulo de Nocaute Físico Não-Letal (Client Knockout System)
    Evita mortes e chamados hospitalares desnecessários em brigas corpo a corpo
    ============================================================================
]]

local isKnockedOut = false
local disableKnockout = false

CreateThread(function()
    while true do
        local sleep = 1000

        if not disableKnockout and not isKnockedOut then
            local ped = cache.ped
            -- Verifica se o jogador está em combate corporal ou desarmado
            if IsPedInMeleeCombat(ped) and not LocalPlayer.state.isDead then
                sleep = 100
                local health = GetEntityHealth(ped)

                -- Se a vida cair para estado crítico decorrente de socos (abaixo de 135 e acima de 105)
                if health <= 135 and health > 105 then
                    local isMeleeDamage = HasPedBeenDamagedByWeapon(ped, joaat('WEAPON_UNARMED'), 0)
                        or HasPedBeenDamagedByWeapon(ped, joaat('WEAPON_KNUCKLE'), 0)
                        or HasPedBeenDamagedByWeapon(ped, joaat('WEAPON_NIGHTSTICK'), 0)
                        or HasPedBeenDamagedByWeapon(ped, joaat('WEAPON_BAT'), 0)
                        or HasPedBeenDamagedByWeapon(ped, joaat('WEAPON_FLASHLIGHT'), 0)

                    if isMeleeDamage then
                        ClearEntityLastDamageEntity(ped)
                        isKnockedOut = true
                        sleep = 0

                        Bridge.Notify.showNotify('Você foi nocauteado e perdeu a consciência momentaneamente...', 'error')

                        -- Efeito de tela e tremor de impacto craniano
                        SetTimecycleModifier('Bloom')
                        SetTimecycleModifierStrength(2.8)
                        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.5)

                        -- Ragdoll temporário
                        local endTime = GetGameTimer() + 8000
                        while GetGameTimer() < endTime do
                            SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
                            ResetPedRagdollTimer(ped)
                            Wait(200)
                        end

                        -- Restauração e recuperação
                        ClearTimecycleModifier()
                        StopGameplayCamShaking(true)

                        -- Requisita recuperação segura ao servidor
                        TriggerServerEvent('loki_prescriptions:server:recoverKnockout')

                        Bridge.Notify.showNotify('Você recobrou a consciência com dor de cabeça e atordoamento.', 'inform')
                        Wait(10000) -- Cooldown de 10s para não levar nocaute em looping
                        isKnockedOut = false
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
