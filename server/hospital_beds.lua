--[[
    LOKI MEDICAL SUITE v2.5.0 — Sistema de Leitos Hospitalares (SERVER)
    
    Autoridade server-side:
      - Verifica se leito está livre e se jogador pode usar
      - Cobra taxa via aust_banking (sociedade ambulance) ou banco direto
      - Aplica ticks de HP/bleed a cada confirmação do cliente
      - Gerencia mapa de leitos ocupados com TTL de segurança
      - Cleanup em playerDropped
]]

-- ── Estado global de leitos ──────────────────────────────────────────────
-- Mapa: bedIndex → { playerId, expiresAt }
local occupiedBeds = {}

-- TTL máximo de um leito sem tick (60s = o cliente travou ou desconectou)
local BED_TTL_MS = 60000

-- ── Funções de gerenciamento de leitos ───────────────────────────────────

--- Verifica se um leito está ocupado (e se o TTL ainda é válido)
---@param bedIndex string
---@return boolean
local function isBedOccupied(bedIndex)
    local session = occupiedBeds[bedIndex]
    if not session then return false end
    -- TTL expirado → libera automaticamente
    if GetGameTimer() > session.expiresAt then
        occupiedBeds[bedIndex] = nil
        return false
    end
    return true
end

--- Reserva o leito para o jogador
---@param bedIndex string
---@param playerId number
local function reserveBed(bedIndex, playerId)
    occupiedBeds[bedIndex] = {
        playerId  = playerId,
        expiresAt = GetGameTimer() + BED_TTL_MS,
    }
end

--- Libera o leito
---@param bedIndex string
---@param playerId number Quem está liberando (segurança)
local function freeBed(bedIndex, playerId)
    local session = occupiedBeds[bedIndex]
    if session and session.playerId == playerId then
        occupiedBeds[bedIndex] = nil
    end
end

--- Renova o TTL do leito (chamado a cada heartbeat do cliente)
---@param bedIndex string
---@param playerId number
local function renewBed(bedIndex, playerId)
    local session = occupiedBeds[bedIndex]
    if session and session.playerId == playerId then
        session.expiresAt = GetGameTimer() + BED_TTL_MS
    end
end

-- ── Callback: solicitar leito ─────────────────────────────────────────────

lib.callback.register("loki_prescriptions:server:requestBed", function(source, bedIndex)
    local src = source

    -- Valida parâmetro
    if type(bedIndex) ~= "string" or #bedIndex > 64 then return false end

    -- Verifica se o leito está disponível
    if isBedOccupied(bedIndex) then
        Bridge.Notify.showNotify(src, locale("bed_occupied"), "error")
        return false
    end

    -- Obtém configuração de preço do hospital a que o leito pertence
    local price = 0
    local hospitalKey = bedIndex:match("^(.+)_%d+$")

    if hospitalKey and Config.CheckIn and Config.CheckIn[hospitalKey] then
        local checkInCfg = Config.CheckIn[hospitalKey]
        price = (checkInCfg.price and (checkInCfg.price.bank or checkInCfg.price.money)) or 0
    else
        price = Config.HospitalBeds.defaultPrice or 250
    end

    -- Cobra taxa via aust_banking (sociedade ambulance) ou fallback banco direto
    if price > 0 then
        local charged = false

        -- Tenta débito via aust_banking
        if GetResourceState("aust_banking") == "started" then
            local ok = pcall(function()
                exports.aust_banking:removeBankMoney(src, price, "Internação hospitalar")
                charged = true
            end)
            if not ok then charged = false end
        end

        -- Fallback: débito direto via Bridge
        if not charged then
            local playerMoney = Bridge.Framework.getPlayerMoney(src, "bank")
            if playerMoney < price then
                Bridge.Notify.showNotify(src, locale("insufficientFunds"), "error")
                return false
            end
            Bridge.Framework.removePlayerMoney(src, price, "bank", "Internação hospitalar")
        end
    end

    -- Reserva o leito e notifica
    reserveBed(bedIndex, src)
    Bridge.Notify.showNotify(src, locale("bed_reserved", price), "success")

    return true
end)

-- ── Evento: tick de cura do cliente ──────────────────────────────────────

RegisterNetEvent("loki_prescriptions:server:hospitalBedTick")
AddEventHandler("loki_prescriptions:server:hospitalBedTick", function(bedIndex)
    local src = source

    -- Validações de segurança
    if type(bedIndex) ~= "string" or #bedIndex > 64 then return end

    local session = occupiedBeds[bedIndex]
    if not session or session.playerId ~= src then return end

    -- Proximity check (leito deve estar próximo do ped no servidor)
    -- Busca as coords do leito a partir da config
    local hospitalKey = bedIndex:match("^(.+)_%d+$")
    local bedIdxNum   = tonumber(bedIndex:match("_(%d+)$"))

    if hospitalKey and bedIdxNum and Config.CheckInBeds and Config.CheckInBeds[hospitalKey] then
        local bedCoords = Config.CheckInBeds[hospitalKey][bedIdxNum]
        if bedCoords then
            local playerPed = GetPlayerPed(src)
            local playerPos = GetEntityCoords(playerPed)
            local bedPos    = vec3(bedCoords.x, bedCoords.y, bedCoords.z)
            if #(playerPos - bedPos) > 4.0 then
                -- Jogador saiu da área do leito, libera
                freeBed(bedIndex, src)
                TriggerClientEvent("loki_prescriptions:client:forceExitBed", src)
                return
            end
        end
    end

    -- Renova TTL
    renewBed(bedIndex, src)

    -- Aplica tick de cura: +5 HP por tick (servidor autoriza, cliente aplica)
    local healAmount = Config.HospitalBeds.hpPerTick or 5
    TriggerClientEvent("loki_prescriptions:client:applyBedHeal", src, healAmount)

    -- Reduz nível de sangramento via state bag
    local playerState = Player(src).state
    if playerState.bleed_level and playerState.bleed_level > 0 then
        local newBleed = math.max(0, playerState.bleed_level - (Config.HospitalBeds.bleedReductionPerTick or 1))
        Player(src).state:set("bleed_level", newBleed, true)
    end

    -- Integração vp_needs: recuperação de estresse e hidratação gradual
    if VpNeedsBridge and VpNeedsBridge.IsActive then
        pcall(function()
            if VpNeedsBridge.IsActive() and exports.vp_needs and exports.vp_needs.AdjustNeed then
                exports.vp_needs:AdjustNeed(src, "thirst", 3)
                exports.vp_needs:AdjustNeed(src, "stress", -5)
            end
        end)
    end
end)

-- ── Evento: saída voluntária do leito ────────────────────────────────────

RegisterNetEvent("loki_prescriptions:server:exitHospitalBed")
AddEventHandler("loki_prescriptions:server:exitHospitalBed", function(bedIndex)
    local src = source
    if type(bedIndex) ~= "string" then return end
    freeBed(bedIndex, src)
end)

-- ── Cleanup em desconexão ────────────────────────────────────────────────

AddEventHandler("playerDropped", function()
    local src = source
    for bedIndex, session in pairs(occupiedBeds) do
        if session.playerId == src then
            occupiedBeds[bedIndex] = nil
        end
    end
end)

-- ── Export utilitário ─────────────────────────────────────────────────────
exports("GetOccupiedBeds", function()
    return occupiedBeds
end)
