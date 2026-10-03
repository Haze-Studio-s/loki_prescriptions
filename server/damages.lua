-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK 𝐀𝐤 𝐋𝐞𝐚𝐤𝐬 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

-- Helper: log info message if debug mode is enabled
local function debugInfo(msg)
  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.info(msg)
  end
end

-- Helper: log warning message if debug mode is enabled
local function debugWarn(msg)
  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.warn(msg)
  end
end

local registerCallback = lib.callback.register
local callbackName = "p_ambulancejob/server/damages/healBone"

local healCooldowns = {}
local healingLocks  = {}

local function validatePlayerId(id)
  return type(id) == "number"
    and id >= 1
    and id == math.floor(id)
    and GetPlayerPed(id) > 0
end

local function _executeHealBone(source, targetId, data)
  -- Log incoming request
  debugInfo(("[HealBone] Source: %s, TargetId: %s, Data: %s"):format(source, targetId, json.encode(data)))

  -- Validate required fields and types
  if not (validatePlayerId(targetId) and data and data.item and data.bone) then
    debugWarn(("[HealBone] Failed initial validation - targetId: %s, data: %s, item: %s, bone: %s"):format(
      targetId,
      data and "exists" or "nil",
      data and data.item or "nil",
      data and data.bone or "nil"
    ))
    return false
  end

  -- Job authorization check
  local plyJob = Bridge.Framework.getPlayerJob(source)
  if not (plyJob and Editable.allJobs[plyJob.name]) then
    debugWarn(("[HealBone] Player %s job check failed - plyJob: %s"):format(source, plyJob and plyJob.name or "nil"))
    Bridge.Notify.showNotify(source, locale("no_access"), "error")
    return false
  end

  -- Convert weapon to string if present
  if data.weapon then
    data.weapon = tostring(data.weapon)
  end

  -- Get peds
  local plyPed    = GetPlayerPed(source)
  local targetPed = GetPlayerPed(targetId)

  debugInfo(("[HealBone] Ped check - plyPed: %s, targetPed: %s"):format(plyPed, targetPed))

  -- Validate peds are valid and distinct
  if plyPed == 0 or targetPed == 0 or plyPed == targetPed then
    debugWarn(("[HealBone] Ped validation failed - plyPed: %s, targetPed: %s, same: %s"):format(plyPed, targetPed, plyPed == targetPed))
    return false
  end

  -- Distance check between healer and target
  local distance = #(GetEntityCoords(plyPed) - GetEntityCoords(targetPed))
  debugInfo(("[HealBone] Distance check - distance: %.2f"):format(distance))

  if distance > 6.0 then
    debugWarn(("[HealBone] Distance too far - distance: %.2f, max: 6.0"):format(distance))
    return false
  end

  -- Handle temperature (mouth bone) items separately
  if data.bone == "mouth" then
    local tempItem = Config.Temperature.items[data.item]
    if tempItem then
      debugInfo(("[HealBone] Using temperature item - item: %s"):format(data.item))
      Bridge.Inventory.removeItem(source, data.item, 1)
      TriggerClientEvent("p_ambulancejob/client/temperature/usedItem", targetId, data.item)
      return true
    end
  end

  -- Get target's damage state
  local damages = Player(targetId).state.damages
  debugInfo(("[HealBone] Target damages exist: %s"):format(damages and "yes" or "no"))

  -- Validate bone has recorded damage
  if not (damages and damages[data.bone]) then
    debugWarn(("[HealBone] No damages for bone - bone: %s, hasTargetDamages: %s, hasBoneDamages: %s"):format(
      data.bone,
      damages and "yes" or "no",
      damages and damages[data.bone] and "yes" or "no"
    ))
    return false
  end

  -- Get injuries for this bone
  local boneInjuries = damages[data.bone].injuries
  if not boneInjuries then
    debugWarn(("[HealBone] No bone injuries found for bone: %s"):format(data.bone))
    return false
  end

  -- Weapon must be specified
  if not data.weapon then
    debugWarn("[HealBone] No weapon specified in data")
    return false
  end

  -- Look up item count for this weapon/item pair
  local weaponEntry = boneInjuries[data.weapon]
  local itemCount
  if weaponEntry and weaponEntry.data and weaponEntry.data.items then
    itemCount = weaponEntry.data.items[data.item]
  end

  debugInfo(("[HealBone] Item check - weapon: %s, item: %s, itemCount: %s"):format(
    data.weapon, data.item, itemCount or "nil"
  ))

  local jobName = plyJob.name

  if not itemCount then
    debugWarn(("[HealBone] Item count is nil or zero - weapon: %s, item: %s"):format(data.weapon, data.item))
    return false
  end

  -- Log heal start
  debugInfo(("[HealBone] Starting healing process - bone: %s, weapon: %s, item: %s"):format(data.bone, data.weapon, data.item))

  -- Blood bag handling (requires matching blood type)
  if data.item:find("blood_bag", 1, true) then
    if Config.BloodTypes and Config.BloodTypes.enabled then
      local bloodType  = Player(targetId).state.bloodType
      local bloodCount = Bridge.Inventory.getItemCount(source, data.item, { bloodType = bloodType })

      debugInfo(("[HealBone] Blood bag check - bloodType: %s, hasItem: %s"):format(bloodType, bloodCount))

      if bloodCount < 1 then
        Bridge.Notify.showNotify(source, locale("you_need_blood_bag", bloodType), "error")
        return false
      end

      Bridge.Inventory.removeItem(source, data.item, 1, { bloodType = bloodType })
      if VpNeedsBridge then
        VpNeedsBridge.ApplyBloodTransfusion(targetId)
      end
    end
  else
    -- Standard item removal
    Bridge.Inventory.removeItem(source, data.item, 1)
  end

  -- Decrement item use count
  itemCount = itemCount - 1
  debugInfo(("[HealBone] Item used - remaining count: %s"):format(itemCount))

  -- Helper: pay society and medic for an injury heal
  local function payHealingReward()
    if Config.Damages.moneyIntoSociety then
      if Config.Damages.moneyforHealing.perInjury and Bridge.Society then
        local amount      = Config.Damages.moneyforHealing.amount
        local medicShare  = amount * (Config.Damages.moneyforHealing.medicPercent / 100)
        if Bridge.Society then
          Bridge.Society.addMoney(source, jobName, amount - medicShare)
        end
        Bridge.Framework.addMoney(source, "bank", medicShare)
      end
    end
  end

  if itemCount < 1 then
    -- Injury fully healed: remove item entry
    boneInjuries[data.weapon].data.items[data.item] = nil
    debugInfo(("[HealBone] Injury healed completely for bone: %s, weapon: %s"):format(data.bone, data.weapon))
    payHealingReward()
  else
    -- Update remaining item count
    boneInjuries[data.weapon].data.items[data.item] = itemCount
  end

  -- Clear weapon entry if no items remain
  if not next(boneInjuries[data.weapon].data.items) then
    boneInjuries[data.weapon] = nil
    debugInfo(("[HealBone] Weapon injuries cleared for weapon: %s"):format(data.weapon))
  end

  -- Clear bone entry if no weapons remain
  if not next(boneInjuries) then
    damages[data.bone] = nil
    debugInfo(("[HealBone] All injuries cleared for bone: %s"):format(data.bone))
  end

  -- Persist updated damage state
  Player(targetId).state:set("damages", damages, true)
  debugInfo("[HealBone] Updated target damages state")

  -- Count remaining damage entries
  local remainingCount = 0
  for _ in pairs(damages) do
    remainingCount = remainingCount + 1
  end
  debugInfo(("[HealBone] Total remaining damages: %s"):format(remainingCount))

  -- If all damages are cleared, handle revive/full-heal flow
  if remainingCount < 1 then
    debugInfo(("[HealBone] All damages healed! isDead: %s"):format(Player(targetId).state.isDead))

    if Player(targetId).state.isDead then
      -- Delay revive animation (longer for advanced healing)
      local delay = Config.Damages.advancedHealing and 6000 or 100
      SetTimeout(delay, function()
        if GetPlayerPed(source) > 0 and GetPlayerPed(targetId) > 0 then
          TriggerClientEvent("p_ambulancejob/client/damages/playRevive", source,   { isRevived = false, targetId = targetId })
          TriggerClientEvent("p_ambulancejob/client/damages/playRevive", targetId, { isRevived = true,  targetId = source })
        end
      end)
    else
      TriggerClientEvent("p_ambulancejob/client/death/revive", targetId)
    end

    -- Full-heal society payment (non-per-injury)
    if Config.Damages.moneyIntoSociety and not Config.Damages.moneyforHealing.perInjury and Bridge.Society then
      local amount     = Config.Damages.moneyforHealing.amount
      local medicShare = amount * (Config.Damages.moneyforHealing.medicPercent / 100)
      if Bridge.Society then
        Bridge.Society.addMoney(source, jobName, amount - medicShare, "Healing payment")
      end
      Bridge.Framework.addMoney(source, "bank", medicShare, "Healing payment")
    end

    -- Send heal log
    local playerName = Bridge.Framework.getPlayerName(targetId)
    Bridge.Logs.Send(
      source,
      "Player Injuries Healed",
      ("Player %s ALL injuries has been healed"):format(playerName),
      Webhooks and Webhooks.damages or nil
    )

    return true
  end

  return true
end

local function healBoneCallback(source, targetId, data)
  -- Rate Limit por source (mínimo 1.2s entre ações médicas de curativo)
  local now = GetGameTimer()
  if healCooldowns[source] and (now - healCooldowns[source]) < 1200 then
    debugWarn(("[HealBone] Rate limit atingido para source: %s"):format(source))
    return false
  end
  healCooldowns[source] = now

  -- Concurrency Lock por targetId com TTL de 10 segundos (evita deadlock permanente por timeout/crash)
  if healingLocks[targetId] then
    local lockData = healingLocks[targetId]
    local lockTime = (type(lockData) == "table" and lockData.time) or 0
    if (now - lockTime) < 10000 then
      debugWarn(("[HealBone] Target %s já está sendo tratado por outra rotina"):format(targetId))
      return false
    else
      debugWarn(("[HealBone] Lock expirado por TTL para target %s, liberando..."):format(targetId))
      healingLocks[targetId] = nil
    end
  end
  healingLocks[targetId] = { healer = source, time = now }

  -- Execução protegida com liberação garantida de lock (fail-safe)
  local ok, res = pcall(_executeHealBone, source, targetId, data)
  healingLocks[targetId] = nil

  if not ok then
    debugWarn(("[HealBone] Erro inesperado na execução: %s"):format(tostring(res)))
    return false
  end

  return res == true
end

registerCallback("p_ambulancejob/server/damages/healBone", healBoneCallback)
registerCallback("loki_prescriptions:server:healBone", healBoneCallback)

RegisterNetEvent("p_ambulancejob/server/damages/performCPR")
AddEventHandler("p_ambulancejob/server/damages/performCPR", function(targetId)
  local src = source
  if not validatePlayerId(src) or not validatePlayerId(targetId) then return end

  local enoughDistance = Utils:checkDistance(src, targetId)
  debugInfo(("[Damages] Player %s is performing CPR on player %s (enoughDistance: %s)"):format(src, targetId, tostring(enoughDistance)))

  if not enoughDistance then return end

  -- Job check
  local plyJob = Bridge.Framework.getPlayerJob(src)
  debugInfo(("[Damages] Player %s job: %s"):format(src, plyJob and plyJob.name or "nil"))

  if not (plyJob and Editable.allJobs[plyJob.name]) then return end

  debugInfo(("[Damages] Performing CPR from player %s to player %s"):format(src, targetId))

  -- Notify both parties with revive animation data
  TriggerClientEvent("p_ambulancejob/client/damages/playRevive", src,      { isRevived = false, targetId = targetId })
  TriggerClientEvent("p_ambulancejob/client/damages/playRevive", targetId, { isRevived = true,  targetId = src })
end)

RegisterNetEvent("p_ambulancejob/server/damages/treatedPlayer")
AddEventHandler("p_ambulancejob/server/damages/treatedPlayer", function(data)
  local src = source
  if not validatePlayerId(src) or type(data) ~= "table" or not validatePlayerId(data.player) then return end

  local enoughDistance = Utils:checkDistance(src, data.player)
  if not enoughDistance then return end

  -- Job check
  local plyJob = Bridge.Framework.getPlayerJob(src)
  if not (plyJob and Editable.allJobs[plyJob.name]) then return end

  -- Notify client that target is being healed
  TriggerClientEvent("p_ambulancejob/client/damages/setBeingHealed", data.player, data.state == true)
end)

local knockoutCooldowns = {}

RegisterNetEvent("loki_prescriptions:server:recoverKnockout", function()
  local src = source
  if not validatePlayerId(src) then return end

  local now = GetGameTimer()
  if knockoutCooldowns[src] and (now - knockoutCooldowns[src]) < 15000 then
    return
  end
  knockoutCooldowns[src] = now

  local ped = GetPlayerPed(src)
  if ped and ped > 0 then
    local currentHp = GetEntityHealth(ped)
    local maxHp = GetEntityMaxHealth(ped)
    if currentHp > 100 and currentHp < 145 then
      local targetHp = math.min(maxHp, currentHp + 15)
      SetEntityHealth(ped, targetHp)
      debugInfo(("[Knockout] Player %s recuperou consciencia. HP ajustado para %d"):format(src, targetHp))
    end
  end
end)

-- Limpeza de memória e locks quando o jogador desconecta
AddEventHandler("playerDropped", function()
  local src = source
  healCooldowns[src] = nil
  healingLocks[src] = nil
  knockoutCooldowns[src] = nil
  for targetId, lockInfo in pairs(healingLocks) do
    local healer = type(lockInfo) == "table" and lockInfo.healer or lockInfo
    if healer == src or targetId == src then
      healingLocks[targetId] = nil
    end
  end
end)