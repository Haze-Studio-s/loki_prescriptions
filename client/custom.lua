local oxTarget = GetResourceState('ox_target') == 'started'
local qbTarget = GetResourceState('qb-target') == 'started'

---@param entity number entity handle
---@param label string
---@param icon string? icon to display with target (optional)
---@param cb function function to be executed when target is selected
function AddTarget(entity, label, icon, cb)
    if oxTarget then
        local options = {
            label = label,
            name = label,
            distance = 2.5,
            onSelect = cb,
            icon = icon or 'fa-solid fa-capsules'
        }
        exports['ox_target']:addLocalEntity(entity, options)
    elseif qbTarget then
        local parameters = {
            options = {{
                label = label,
                action = cb,
                targeticon = icon or 'fa-solid fa-capsules'
            }},
            distance = 2.5
        }
        exports['qb-target']:AddTargetEntity(entity, parameters)
    end
end

--- Adiciona opção de interação de target em outros jogadores (médico mirando em paciente)
---@param label string
---@param icon string
---@param cb function
---@param canInteract function
function AddGlobalPlayerTarget(label, icon, cb, canInteract)
    if oxTarget then
        exports['ox_target']:addGlobalPlayer({
            {
                name = 'prescriptions_doctor_interact',
                label = label,
                icon = icon or 'fa-solid fa-file-prescription',
                distance = 2.5,
                onSelect = cb,
                canInteract = canInteract
            }
        })
    elseif qbTarget then
        exports['qb-target']:AddGlobalPlayer({
            options = {
                {
                    label = label,
                    targeticon = icon or 'fa-solid fa-file-prescription',
                    action = cb,
                    canInteract = canInteract
                }
            },
            distance = 2.5
        })
    end
end