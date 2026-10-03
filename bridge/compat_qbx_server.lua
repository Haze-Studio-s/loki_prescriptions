--[[
    ============================================================================
    QBox Medical Compatibility Bridge (Server)
    Provides exports, State Bags sync and events matching qbx_medical 1:1
    ============================================================================
]]

local function getDeathState(src)
    local player = exports.qbx_core and exports.qbx_core:GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.metadata then
        if player.PlayerData.metadata.isdead then return DeathStateEnum.DEAD end
        if player.PlayerData.metadata.inlaststand then return DeathStateEnum.LAST_STAND end
    end
    return DeathStateEnum.ALIVE
end

-- Inicialização de estado ao carregar o personagem
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local playerState = Player(src).state
    playerState:set(DEATH_STATE_STATE_BAG, getDeathState(src), true)
    playerState:set(BLEED_LEVEL_STATE_BAG, 0, true)
    playerState:set('isDead', false, true)
    playerState:set('inLastStand', false, true)
end)

-- Monitoramento e espelhamento bidirecional da State Bag de morte
AddStateBagChangeHandler(DEATH_STATE_STATE_BAG, nil, function(bagName, _, value)
    local playerId = GetPlayerFromStateBagName(bagName)
    if not playerId or playerId <= 0 then return end

    local isDead = (value == DeathStateEnum.DEAD)
    local inLastStand = (value == DeathStateEnum.LAST_STAND)

    local playerState = Player(playerId).state
    if playerState then
        playerState:set('isDead', isDead or inLastStand, true)
        playerState:set('inLastStand', inLastStand, true)
    end

    if exports.qbx_core then
        local player = exports.qbx_core:GetPlayer(playerId)
        if player and player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData('isdead', isDead)
            player.Functions.SetMetaData('inlaststand', inLastStand)
        end
    end
end)

-- Sincronização de fome/sede ao reviver
local function resetHungerAndThirst(player)
    local targetSrc = type(player) == 'number' and player or (player and player.PlayerData and player.PlayerData.source)
    if not targetSrc or targetSrc <= 0 then return end

    local qbxPlayer = exports.qbx_core and exports.qbx_core:GetPlayer(targetSrc)
    if qbxPlayer and qbxPlayer.Functions then
        qbxPlayer.Functions.SetMetaData('hunger', 100)
        qbxPlayer.Functions.SetMetaData('thirst', 100)
    end

    local playerState = Player(targetSrc).state
    if playerState then
        playerState:set('hunger', 100, true)
        playerState:set('thirst', 100, true)
        playerState:set('stress', 0, true)
    end

    TriggerClientEvent('hud:client:UpdateNeeds', targetSrc, 100, 100)
    if GetResourceState('vp_needs') == 'started' and exports.vp_needs and exports.vp_needs.ResetNeeds then
        pcall(function() exports.vp_needs:ResetNeeds(targetSrc) end)
    end
end

-- Função central de reviver jogador
local function revivePlayer(player)
    local targetSrc = type(player) == 'number' and player or (player and player.PlayerData and player.PlayerData.source)
    if not targetSrc or targetSrc <= 0 then return end

    local playerState = Player(targetSrc).state
    if playerState then
        playerState:set(DEATH_STATE_STATE_BAG, DeathStateEnum.ALIVE, true)
        playerState:set(BLEED_LEVEL_STATE_BAG, 0, true)
        playerState:set('isDead', false, true)
        playerState:set('inLastStand', false, true)
        playerState:set('damages', {}, true)
    end

    TriggerClientEvent('qbx_medical:client:playerRevived', targetSrc)
    TriggerClientEvent('p_ambulancejob/client/death/revive', targetSrc)
    TriggerClientEvent('loki_prescriptions:client:revive', targetSrc)

    resetHungerAndThirst(targetSrc)
end

-- Função de cura total
local function healPlayer(src)
    if not src or src <= 0 then return end
    revivePlayer(src)
    TriggerClientEvent('qbx_medical:client:heal', src, 'full')
end

-- Função de cura parcial
local function healPartially(src)
    if not src or src <= 0 then return end
    TriggerClientEvent('qbx_medical:client:heal', src, 'partial')
end

-- Status humano legível
local function getPlayerStatus(src)
    local state = Player(src).state
    local bleedLevel = state[BLEED_LEVEL_STATE_BAG] or 0
    local injuries = state.damages or {}

    local injuryStatuses = {}
    local i = 0
    for part, _ in pairs(injuries) do
        i = i + 1
        injuryStatuses[i] = tostring(part)
    end

    return {
        injuries = injuryStatuses,
        bleedLevel = bleedLevel,
        bleedState = 'Nível ' .. tostring(bleedLevel),
        damageCauses = {}
    }
end

-- ============================================================================
-- EXPORTS (Compatíveis com chamadas qbx_medical)
-- ============================================================================
exports('Revive', revivePlayer)
exports('Heal', healPlayer)
exports('HealPartially', healPartially)
exports('GetPlayerStatus', getPlayerStatus)

exports('IsDead', function(source)
    local state = Player(source).state
    return state[DEATH_STATE_STATE_BAG] == DeathStateEnum.DEAD or state.isDead == true
end)

exports('IsLaststand', function(source)
    local state = Player(source).state
    return state[DEATH_STATE_STATE_BAG] == DeathStateEnum.LAST_STAND or state.inLastStand == true
end)

-- Callbacks
lib.callback.register('qbx_medical:server:respawn', function(source)
    revivePlayer(source)
    TriggerEvent('qbx_medical:server:playerRespawned', source)
    return true
end)

lib.callback.register('qbx_medical:server:resetHungerAndThirst', resetHungerAndThirst)

lib.callback.register('qbx_medical:server:setArmor', function(source, amount)
    local player = exports.qbx_core and exports.qbx_core:GetPlayer(source)
    if player and player.Functions and player.Functions.SetMetaData then
        player.Functions.SetMetaData('armor', amount)
    end
end)

lib.callback.register('qbx_medical:server:log', function(_, event, message)
    if Bridge and Bridge.Debug then
        Bridge.Debug(('LOG [qbx_medical:%s]: %s'):format(event, message))
    end
end)

-- Compatibilidade txAdmin Menu
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' or type(eventData.id) ~= 'number' then
        return
    end
    revivePlayer(eventData.id)
    healPlayer(eventData.id)
end)

-- Comandos administrativos
lib.addCommand('revive', {
    help = 'Reviver jogador',
    restricted = 'group.admin',
    params = {
        { name = 'id', help = 'ID do jogador', type = 'playerId', optional = true }
    }
}, function(source, args)
    local target = args.id or source
    revivePlayer(target)
end)

lib.addCommand('aheal', {
    help = 'Curar jogador completamente',
    restricted = 'group.admin',
    params = {
        { name = 'id', help = 'ID do jogador', type = 'playerId', optional = true }
    }
}, function(source, args)
    local target = args.id or source
    healPlayer(target)
end)

lib.addCommand('kill', {
    help = 'Matar jogador',
    restricted = 'group.admin',
    params = {
        { name = 'id', help = 'ID do jogador', type = 'playerId', optional = true }
    }
}, function(source, args)
    local target = args.id or source
    TriggerClientEvent('qbx_medical:client:killPlayer', target)
end)
