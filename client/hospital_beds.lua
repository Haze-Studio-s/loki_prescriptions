--[[
    LOKI MEDICAL SUITE v2.5.0 — Sistema de Leitos Hospitalares (CLIENT)
    
    Fluxo:
      1. ox_target detecta os leitos registrados em Config.HospitalBeds
      2. Jogador interage → servidor valida leito disponível e cobra taxa
      3. Cliente deita: animação, câmera relaxante, HP/bleed recuperam gradualmente
      4. [E] sai do leito e notifica servidor para liberar a vaga
]]

-- Aguarda Config estar disponível
while not (Config and Config.HospitalBeds) do
    Citizen.Wait(100)
end

if not Config.HospitalBeds.enabled then return end

-- ── Estado local do leito ──────────────────────────────────────────────────
local bedSession = {
    active      = false,    -- em uso
    bedIndex    = nil,      -- índice global da cama (hospital + idx)
    healThread  = nil,      -- thread de cura
    cam         = nil,      -- câmera relaxante
}

-- ── Helpers ───────────────────────────────────────────────────────────────

--- Destroi a câmera do leito de forma segura
local function destroyBedCam()
    if not bedSession.cam then return end
    RenderScriptCams(false, true, 800, true, true)
    SetCamActive(bedSession.cam, false)
    DestroyCam(bedSession.cam, false)
    bedSession.cam = nil
end

--- Cria câmera estilo "hospital relaxante" acima do leito
local function createBedCam(bedCoords)
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local camPos = vec3(bedCoords.x, bedCoords.y, bedCoords.z + 1.6)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    SetCamFov(cam, 55.0)
    SetCamRot(cam, -85.0, 0.0, GetEntityHeading(cache.ped), 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, true)
    bedSession.cam = cam
end

--- Inicia a cura gradual local enquanto no leito
local function startHealTick()
    if bedSession.healThread then return end

    bedSession.healThread = Citizen.CreateThread(function()
        -- Intervalo de notificação ao servidor a cada 5s
        while bedSession.active do
            Citizen.Wait(Config.HospitalBeds.healInterval or 5000)
            if not bedSession.active then break end

            -- Notifica o servidor para aplicar 1 tick de cura
            TriggerServerEvent("loki_prescriptions:server:hospitalBedTick", bedSession.bedIndex)
        end
        bedSession.healThread = nil
    end)
end

--- Encerra a sessão de leito: limpa animações, câmera e estado
local function exitBed()
    if not bedSession.active then return end

    bedSession.active = false

    -- Para animação deitada
    ClearPedTasks(cache.ped)
    SetEntityVisible(cache.ped, true, false)

    -- Restaura câmera normal
    destroyBedCam()

    -- Remove TextUI de saída
    lib.hideTextUI()

    -- Avisa o servidor para liberar o leito
    if bedSession.bedIndex then
        TriggerServerEvent("loki_prescriptions:server:exitHospitalBed", bedSession.bedIndex)
    end

    bedSession.bedIndex = nil
    Bridge.Notify.showNotify(locale("bed_session_ended"), "inform")
end

-- ── Entrada no leito ─────────────────────────────────────────────────────

--- Deita o jogador numa cama hospitalar
---@param bedIndex string Chave única da cama (ex: "gabz_hospital_1")
---@param bedCoords vector4 Coordenadas + heading do leito
local function enterBed(bedIndex, bedCoords)
    if bedSession.active then
        Bridge.Notify.showNotify(locale("bed_already_in_use"), "error")
        return
    end

    -- Pede ao servidor para reservar o leito e cobrar a taxa
    local granted = lib.callback.await("loki_prescriptions:server:requestBed", false, bedIndex)
    if not granted then
        -- Motivo já notificado pelo servidor
        return
    end

    bedSession.active   = true
    bedSession.bedIndex = bedIndex

    -- Teleporta suavemente para o leito
    local coords = vec3(bedCoords.x, bedCoords.y, bedCoords.z)
    SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(cache.ped, bedCoords.w)

    -- Animação de se deitar
    local animDict = "amb@world_human_sunbathe@male@back@base"
    lib.requestAnimDict(animDict)
    TaskPlayAnim(cache.ped, animDict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Câmera relaxante
    createBedCam(coords)

    -- TextUI de saída
    lib.showTextUI(locale("bed_press_to_exit"), {
        position = "left-center",
        icon     = "fa-solid fa-bed",
        style    = { borderRadius = 0, backgroundColor = "#1a2535", color = "white" },
    })

    -- Inicia cura gradual (ticks ao servidor)
    startHealTick()

    -- Thread de controle: aguarda [E] para sair
    Citizen.CreateThread(function()
        while bedSession.active do
            Citizen.Wait(0)
            DisableControlAction(0, 38, true)  -- bloqueia enter veículo
            DisableControlAction(0, 44, true)  -- bloqueia cobertura
            DisableControlAction(0, 245, true) -- bloqueia arma
            DisableControlAction(0, 21, true)  -- bloqueia correr

            -- [E] = tecla 51 (INPUT_CONTEXT)
            if IsDisabledControlJustPressed(0, 51) then
                exitBed()
                break
            end
        end
    end)
end

-- ── Registro dos leitos via ox_target ─────────────────────────────────────

Citizen.CreateThread(function()
    Citizen.Wait(3000)

    -- Itera todos os hospitais e seus CheckInBeds
    for hospitalKey, beds in pairs(Config.CheckInBeds or {}) do
        for i, bedCoords in ipairs(beds) do
            local bedIndex = hospitalKey .. "_" .. i
            local bedPos   = vec3(bedCoords.x, bedCoords.y, bedCoords.z)

            -- Registra zona de interação via ox_target no raio do leito
            exports.ox_target:addSphereZone({
                coords   = bedPos,
                radius   = 1.0,
                name     = "hospital_bed_" .. bedIndex,
                debug    = false,
                options  = {
                    {
                        name     = "loki_use_bed_" .. bedIndex,
                        icon     = "fa-solid fa-bed",
                        label    = locale("bed_interact"),
                        distance = 2.0,
                        onSelect = function()
                            enterBed(bedIndex, bedCoords)
                        end,
                    },
                },
            })
        end
    end
end)

-- ── Eventos de controle do servidor ──────────────────────────────────────

-- Servidor pode forçar saída do leito (ex: server restart, disconnect cleanup)
RegisterNetEvent("loki_prescriptions:client:forceExitBed")
AddEventHandler("loki_prescriptions:client:forceExitBed", function()
    if bedSession.active then
        exitBed()
    end
end)

-- Aplica HP local quando servidor confirma um tick de cura
RegisterNetEvent("loki_prescriptions:client:applyBedHeal")
AddEventHandler("loki_prescriptions:client:applyBedHeal", function(hpAmount)
    if not bedSession.active then return end
    local currentHp = GetEntityHealth(cache.ped)
    local newHp     = math.min(currentHp + (hpAmount or 5), 200)
    SetEntityHealth(cache.ped, newHp)
end)
