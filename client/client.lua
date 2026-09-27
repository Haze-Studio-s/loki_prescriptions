local Cache = {
    ped = PlayerPedId(),
    points = {}
}

local nuiCb = RegisterNuiCallback
local RegisterNuiCallback = function(name, fn, keepCallback)
    nuiCb(name, function(data, cb)
        if keepCallback then
            fn(data, cb)
        else
            fn(data)
            cb()
        end
    end)
end

RegisterNetEvent('loki_prescriptions:oxNotify', function(heading, description, style)
    if style == "info" then
        style = "inform"
    end
    if lib and lib.notify then
        lib.notify({
            title = heading,
            description = description,
            type = style
        })
    else
        print(('^3[%s] %s: %s^7'):format(style, heading, description))
    end
end)

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local i = 0
    while not HasModelLoaded(hash) do
        i = i + 1
        if i > 500 then
            error('Falha ao carregar modelo: ' .. tostring(model))
        end
        Wait(10)
    end
    return hash
end

local function loadAnim(dict)
    RequestAnimDict(dict)
    local i = 0
    while not HasAnimDictLoaded(dict) do
        i = i + 1
        if i > 500 then
            error('Falha ao carregar dicionário de animação: ' .. tostring(dict))
        end
        Wait(10)
    end
end

local function openPrescription(data, targetServerId)
    Cache.targetServerId = targetServerId
    Cache.nuiFocused = not Cache.nuiFocused
    SetNuiFocus(Cache.nuiFocused, Cache.nuiFocused)

    if Cache.nuiFocused then
        if not data then
            SendNUIMessage({ event = 'open_nui' })
        else
            SendNUIMessage({
                event = 'show_prescription',
                prescription = data.data,
                date = data.date,
            })
        end

        if Config.Anim and Config.Anim.enabled then
            loadAnim(Config.Anim.dict)
            if Config.Anim.prop then
                local propHash = loadModel(Config.Anim.prop.model)
                local pCoords = GetEntityCoords(Cache.ped)
                Cache.prop = CreateObject(propHash, pCoords.x, pCoords.y, pCoords.z + 1, true, true, false)
                AttachEntityToEntity(
                    Cache.prop, Cache.ped, GetPedBoneIndex(Cache.ped, 28422),
                    Config.Anim.prop.offsets[1], Config.Anim.prop.offsets[2], Config.Anim.prop.offsets[3],
                    Config.Anim.prop.rotations[1], Config.Anim.prop.rotations[2], Config.Anim.prop.rotations[3],
                    false, false, false, false, 2, true
                )
                SetModelAsNoLongerNeeded(propHash)
            end
            TaskPlayAnim(Cache.ped, Config.Anim.dict, Config.Anim.anim, 8.0, 1.0, -1, 17, 1.0, false, false, false)
            RemoveAnimDict(Config.Anim.dict)
        end
    else
        SendNUIMessage({ event = 'close_nui' })
        if Cache.prop and DoesEntityExist(Cache.prop) then
            DeleteEntity(Cache.prop)
            Cache.prop = nil
        end
        ClearPedTasks(Cache.ped)
    end
end

RegisterNuiCallback('nuiClosed', function()
    Cache.nuiFocused = false
    SetNuiFocus(false, false)
    if Cache.prop and DoesEntityExist(Cache.prop) then
        DeleteEntity(Cache.prop)
        Cache.prop = nil
    end
    ClearPedTasks(Cache.ped)
    Cache.targetServerId = nil
end)

RegisterNuiCallback('load_config', function()
    SendNUIMessage({
        event = "load_config",
        style = Config.NuiStyle or "de",
        locale = Config.TimeFormat or "pt-BR",
        medicine = Config.Medicine,
        label_submit = _U('nui_submit'),
        label_cancel = _U('nui_cancel')
    })
end)

RegisterNuiCallback('submit_prescription', function(data)
    TriggerServerEvent('loki_prescriptions:createPrescription', data, Cache.targetServerId)
    Cache.targetServerId = nil
end)

AddEventHandler('playerSpawned', function()
    Cache.ped = PlayerPedId()
end)

RegisterNetEvent('loki_prescriptions:viewPrescription', function(data)
    openPrescription(data)
end)

RegisterNetEvent('loki_prescriptions:createPrescription', function(targetServerId)
    openPrescription(nil, targetServerId)
end)

-- Processamento do Resgate com Barra de Progresso Imersiva
local function handleRedeemPrescription()
    if lib and lib.progressBar then
        local completed = lib.progressBar({
            duration = 2500,
            label = _U('processingRedeem'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            },
            anim = {
                dict = 'amb@prop_human_atm@male@idle_a',
                clip = 'idle_a'
            }
        })
        if completed then
            TriggerServerEvent('loki_prescriptions:redeemPrescription')
        end
    else
        TriggerServerEvent('loki_prescriptions:redeemPrescription')
    end
end

local function handleBuyInsurance()
    TriggerServerEvent('loki_prescriptions:buyInsurance')
end

-- Criação do NPC e Ponto de Convênio Médico
local function createInsuranceNPC()
    local hash = loadModel(Config.Insurance.npc.model)
    local pos = Config.Insurance.npc.position
    local npc = CreatePed(0, hash, pos.x, pos.y, pos.z, pos.w, false, true)
    SetModelAsNoLongerNeeded(hash)
    loadAnim(Config.Insurance.npc.anim.dict)
    TaskPlayAnim(npc, Config.Insurance.npc.anim.dict, Config.Insurance.npc.anim.anim, 8.0, 1.0, -1, Config.Insurance.npc.anim.flags, 1.0, false, false, false)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    Cache.InsuranceNPC = npc

    if Config.Insurance.blip then
        local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipAsShortRange(blip, Config.Insurance.blip.shortRange)
        SetBlipSprite(blip, Config.Insurance.blip.sprite)
        SetBlipColour(blip, Config.Insurance.blip.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Insurance.blip.label)
        EndTextCommandSetBlipName(blip)
        SetBlipDisplay(blip, Config.Insurance.blip.display)
        SetBlipScale(blip, Config.Insurance.blip.scale)
        Cache.InsuranceBlip = blip
    end

    if Config.Target then
        AddTarget(npc, _U("insuranceHelpText", Config.Insurance.price), "fa-solid fa-file-invoice-dollar", handleBuyInsurance)
    else
        -- Zero-overhead com lib.points (0.00ms idle)
        if lib and lib.points then
            local point = lib.points.new({
                coords = vector3(pos.x, pos.y, pos.z),
                distance = 2.0,
                onEnter = function()
                    lib.showTextUI(('[E] %s'):format(_U('insuranceHelpText', Config.Insurance.price)))
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                nearby = function()
                    if IsControlJustPressed(0, 38) then
                        handleBuyInsurance()
                        Wait(1000)
                    end
                end
            })
            table.insert(Cache.points, point)
        end
    end
end

-- Criação dos NPCs e Pontos das Farmácias
local function createPharmacies()
    Cache.PharmaciePeds = {}
    for k, v in ipairs(Config.Pharmacies) do
        local hash = loadModel(v.pedModel)
        local ped = CreatePed(0, hash, v.position.x, v.position.y, v.position.z, v.position.w, false, true)
        SetModelAsNoLongerNeeded(hash)
        loadAnim(v.anim.dict)
        TaskPlayAnim(ped, v.anim.dict, v.anim.anim, 8.0, 1.0, -1, v.anim.flags, 1.0, false, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        Cache.PharmaciePeds[k] = ped

        if v.blip then
            local blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
            SetBlipAsShortRange(blip, v.blip.shortRange)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipColour(blip, v.blip.color)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(blip)
            SetBlipDisplay(blip, v.blip.display)
            SetBlipScale(blip, v.blip.scale)
        end

        if Config.Target then
            AddTarget(ped, _U('redeemPrescription'), "fa-solid fa-capsules", handleRedeemPrescription)
        else
            if lib and lib.points then
                local point = lib.points.new({
                    coords = vector3(v.position.x, v.position.y, v.position.z),
                    distance = 2.5,
                    onEnter = function()
                        lib.showTextUI(('[E] %s'):format(_U('redeemPrescription')))
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                    nearby = function()
                        if IsControlJustPressed(0, 38) then
                            handleRedeemPrescription()
                            Wait(1000)
                        end
                    end
                })
                table.insert(Cache.points, point)
            end
        end
    end
end

-- Target de Interação Direta com Paciente Próximo para Médicos
local function setupDoctorPlayerTarget()
    if Config.Target and AddGlobalPlayerTarget then
        AddGlobalPlayerTarget(_U('prescribeToPatient'), 'fa-solid fa-file-prescription', function(entity)
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
            if targetServerId and targetServerId > 0 then
                TriggerServerEvent('loki_prescriptions:requestPrescribePad', targetServerId)
            end
        end, function(entity)
            return not IsPedInAnyVehicle(Cache.ped, false) and not IsPedInAnyVehicle(entity, false)
        end)
    end
end

RegisterNetEvent('loki_prescriptions:client:openPadForPatient', function(targetServerId)
    openPrescription(nil, targetServerId)
end)

CreateThread(function()
    createInsuranceNPC()
    createPharmacies()
    setupDoctorPlayerTarget()
end)