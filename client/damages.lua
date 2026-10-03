-- =====================================================
--  decrypted by https://discord.gg/6NCbAv2VNK 𝐀𝐤 𝐋𝐞𝐚𝐤𝐬 
--      Cleaned By Said Ak Using Claude Sonnet 4.6
-- =====================================================

-- Damages module - tracks injuries, visual effects, healing UI, and CPR

local localState = LocalPlayer.state

-- Initialize Damages state table
Damages = {
  damages          = {},
  bones            = {
    head     = 31086,
    torso    = 24817,
    leftArm  = 18905,
    rightArm = 57005,
    leftLeg  = 14201,
    rightLeg = 52301,
    mouth    = 20279,
  },
  antiSpam          = GetGameTimer(),
  pulseChecked      = false,
  temperatureChecked= false,
  effects           = { blackOut = 0, shakeAim = 0 },
  damagesUiState    = false,
  knockouts         = 0,
  resolution        = { x = 1920, y = 1080 },
  effectTimer       = nil,
  activeCPR         = false,
}

-- NUI callback: update screen resolution from the client browser
RegisterNUICallback("getResolution", function(data, cb)
  Damages.resolution = data.res
  cb(1)
end)

-- initEffects: spawn a loop that applies aim-shake and blackout NUI effects
function Damages.initEffects(self)
  Citizen.CreateThread(function()
    while true do
      -- Aim shake: apply camera shake when free-aiming if shakeAim > 0
      if self.effects.shakeAim > 0 then
        if IsPlayerFreeAiming(cache.playerId) then
          if not IsGameplayCamShaking() then
            ShakeGameplayCam("DRUNK_SHAKE", self.effects.shakeAim / 100)
          end
        else
          StopGameplayCamShaking(false)
        end
      else
        StopGameplayCamShaking(false)
      end

      -- Blackout: fade NUI overlay in/out based on blackOut effect level
      if self.effects.blackOut > 0 then
        if not self.blackOut then
          self.blackOut = true
          SendNUIMessage({ action = "setVisibleBlackout", data = true })
        end
        -- Tick blackOut value down by 5 each second, clamp to 0
        self.effects.blackOut = math.max(0, self.effects.blackOut - 5)
        -- Opacity sent to NUI is inverted (100 = fully visible, 0 = fully black)
        SendNUIMessage({ action = "setBlackout", data = 100 - self.effects.blackOut })
      else
        if self.blackOut then
          self.blackOut = false
          SendNUIMessage({ action = "setVisibleBlackout", data = false })
        end
      end

      -- Traumatologia Dinâmica de Fraturas (LockSteering & Staggering)
      local leftArmDmg = (self.damages.leftArm and self.damages.leftArm.damage) or 0
      local rightArmDmg = (self.damages.rightArm and self.damages.rightArm.damage) or 0
      local leftLegDmg = (self.damages.leftLeg and self.damages.leftLeg.damage) or 0
      local rightLegDmg = (self.damages.rightLeg and self.damages.rightLeg.damage) or 0

      -- 1. LockSteering: Espasmo muscular e perda temporária de direção ao volante com braço fraturado
      if leftArmDmg > 40 or rightArmDmg > 40 then
        local veh = GetVehiclePedIsIn(cache.ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == cache.ped and GetEntitySpeed(veh) > 6.0 then
          if not self.lastSteerSpasm or (GetGameTimer() - self.lastSteerSpasm) > 18000 then
            self.lastSteerSpasm = GetGameTimer()
            local bias = (math.random() > 0.5 and 0.45 or -0.45)
            SetVehicleSteerBias(veh, bias)
            SendNUIMessage({ action = "playSound", sound = "fracture1", volume = 0.5 })
            Bridge.Notify.showNotify("Dor aguda na fratura do braço! Você perdeu o controle momentâneo da direção.", "error")
          end
        end
      end

      -- 2. Staggering: Tropeço e queda involuntária ao correr com perna fraturada sem muleta
      if leftLegDmg > 40 or rightLegDmg > 40 then
        local isUsingCrutch = exports['loki_prescriptions']:isCrutchEnabled()
        if not isUsingCrutch and IsPedSprinting(cache.ped) then
          if not self.lastStagger or (GetGameTimer() - self.lastStagger) > 12000 then
            self.lastStagger = GetGameTimer()
            SetPedToRagdoll(cache.ped, 1200, 1200, 0, false, false, false)
            SendNUIMessage({ action = "playSound", sound = "fracture2", volume = 0.5 })
            Bridge.Notify.showNotify("Sua perna fraturada cedeu com o impacto! Utilize uma muleta ortopédica.", "error")
          end
        end
      end

      Citizen.Wait(1000)
    end
  end)
end

-- Boot: start effects loop immediately
Citizen.CreateThread(function()
  Damages.initEffects(Damages)
end)

-- getInjuriesAmount: count total injury entries across all body parts
function Damages.getInjuriesAmount(self)
  local count = 0
  for _, bodyPart in pairs(self.damages) do
    for _ in pairs(bodyPart.injuries) do
      count = count + 1
    end
  end
  return count
end

-- getAllHealingItems: populate self.healingItems from Config weapon/temperature item lists
function Damages.getAllHealingItems(self)
  Citizen.Wait(2000)

  local healingItems = {}

  -- Helper: register an item if found in inventory, else log an error
  local function registerItem(itemName)
    local itemData = Bridge.Inventory.getItemData(itemName)
    if itemData then
      healingItems[itemName] = {
        item        = itemName,
        label       = itemData.label,
        image       = itemData.image,
        description = itemData.description or "Generic Medical Item",
      }
    else
      lib.print.error(("Item %s not found in your inventory items!"):format(itemName))
    end
  end

  -- Collect items from each weapon's injuries and advancedInjuries tables
  for _, weaponCfg in pairs(Config.Damages.weapons) do
    for _, injury in pairs(weaponCfg.injuries) do
      if injury.items then
        for itemName in pairs(injury.items) do
          registerItem(itemName)
        end
      end
    end

    if weaponCfg.advancedInjuries then
      for _, boneGroup in pairs(weaponCfg.advancedInjuries) do
        for _, injury in pairs(boneGroup) do
          if injury.items then
            for itemName in pairs(injury.items) do
              registerItem(itemName)
            end
          end
        end
      end
    end
  end

  -- Collect items from the Temperature module if enabled
  if Config.Temperature.enabled and Config.Temperature.items then
    for itemName in pairs(Config.Temperature.items) do
      registerItem(itemName)
    end
  end

  self.healingItems = healingItems
end

-- getHealingItems: send available healing items (with stock count) to the NUI
function Damages.getHealingItems(self)
  local available = {}
  for itemName, itemData in pairs(self.healingItems) do
    local count = Bridge.Inventory.getItemCount(itemName)
    if count and count > 0 then
      available[#available + 1] = {
        name        = itemName,
        label       = itemData.label,
        image       = itemData.image,
        description = itemData.description,
        count       = count,
      }
    end
  end
  SendNUIMessage({ action = "setHealingItems", data = available })
end

-- Boot: initialise local state bag damages entry and pre-load healing items
Citizen.CreateThread(function()
  localState:set("damages", {}, true)
  Damages.getAllHealingItems(Damages)
end)

-- findBone: resolve a raw bone ID to the named body-part key (e.g. "head")
function Damages.findBone(self, boneId)
  for partName, boneMap in pairs(Config.Damages.bones) do
    if boneMap[tostring(boneId)] then
      return partName
    end
  end
  return nil
end

-- effect: accumulate a random visual effect value onto self.effects for a given bone
function Damages.effect(self, boneName, randomValue)
  local roll = math.random(1, 100)
  if roll <= Config.Damages.effects.chance then
    local boneCfg = Config.Damages.effects.bones[boneName]
    if boneCfg then
      local effectKey = boneCfg.effect
      if self.effects[effectKey] then
        local addValue = boneCfg.value or randomValue
        self.effects[effectKey] = self.effects[effectKey] + addValue
      end
    end
  end
end

-- clear: reset all damage tracking fields and update the state bag
function Damages.clear(self)
  self.knockouts = 0
  self.damages   = {}
  self.effects   = { blackOut = 0, shakeAim = 0 }
  localState:set("damages", self.damages, true)
end

-- new: register a new hit on a body part for a given weapon hash
function Damages.new(self, boneId, weaponHash)
  if not boneId then return end

  local boneName = self.findBone(self, boneId)
  if not boneName then return end

  local weaponCfg = Config.Damages.weapons[weaponHash]
  if not weaponCfg then return end

  -- Optional server-side hook to block injury registration
  if Config.Damages.preventRegister and Config.Damages.preventRegister(weaponHash) then
    return
  end

  -- Ensure body-part entry exists
  if not self.damages[boneName] then
    self.damages[boneName] = { bodyPart = boneName, injuries = {} }
  end

  local injuries   = self.damages[boneName].injuries
  local weaponKey  = tostring(weaponHash)
  local existingHit = injuries[weaponKey]

  if existingHit then
    -- Increment hit count and escalate injury data if a next tier exists
    local newHitCount = existingHit.hits + 1
    local nextInjury  = weaponCfg.injuries[newHitCount]

    if not nextInjury and weaponCfg.advancedInjuries then
      local advBone = weaponCfg.advancedInjuries[boneName]
      nextInjury = advBone and advBone[newHitCount]
    end

    if nextInjury then
      injuries[weaponKey] = {
        hits   = newHitCount,
        data   = nextInjury,
        weapon = weaponHash,
      }
    else
      -- Max tier reached: just increment the hit counter
      injuries[weaponKey].hits = newHitCount
    end
  else
    -- First hit: pick initial injury (advanced per-bone, or generic)
    local firstInjury
    if weaponCfg.advancedInjuries then
      local advBone = weaponCfg.advancedInjuries[boneName]
      firstInjury = advBone and advBone[1]
    end
    if not firstInjury then
      firstInjury = weaponCfg.injuries[1] or {}
    end

    injuries[weaponKey] = {
      hits   = 1,
      data   = firstInjury,
      weapon = weaponHash,
    }
  end

  -- Play damage sound after 5 hits with the same weapon
  if Sounds then
    local hits = injuries[weaponKey] and injuries[weaponKey].hits or 0
    if hits >= 5 then
      Sounds.preset(Sounds, "damage")
    end
  end

  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.info(self.damages[boneName].injuries)
  end

  -- Apply random visual effect to self.effects
  if Config.Damages.effects.enabled then
    self.effect(self, boneName, math.random(1, 10))
  end

  -- Propagate pulse degradation
  if Pulse and Pulse.add then
    Pulse.add(Pulse, math.random(1, 3))
  end

  -- Sync damage state to local state bag
  localState:set("damages", self.damages, true)
end

-- getBoneData: find the highest-hit injury entry across all injuries for a body-part slot
function Damages.getBoneData(self, injuries)
  local best = nil

  for _, entry in pairs(injuries) do
    if entry.data and entry.data.items then
      -- Keep the entry with the most hits (most severe injury)
      local bestHits = best and (best.hits or 0) or 0
      if best == nil or bestHits < entry.hits then
        best = lib.table.deepclone(entry.data)
        best.weapon = entry.weapon
      end
    end
  end

  if not best then return nil end

  -- Enrich item entries with inventory metadata (label, image)
  if best.items then
    for itemName, itemCount in pairs(best.items) do
      local itemData = Bridge.Inventory.getItemData(itemName)
      best.items[itemName] = {
        name  = itemName,
        label = (itemData and itemData.label) or itemName,
        count = itemCount,
        image = (itemData and itemData.image) or nil,
      }
    end
  end

  return best
end

-- gameEventTriggered: detect damage events for the local player and register injuries
AddEventHandler("gameEventTriggered", function(eventName, eventArgs)
  if eventName ~= "CEventNetworkEntityDamage" then return end

  local victim     = eventArgs[1]
  local isFatal    = eventArgs[4]
  local weaponHash = eventArgs[7]

  if not IsPedAPlayer(victim) then return end
  if NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end

  if Death and Death.deathType == "death" then return end

  local boneHit, boneId = GetPedLastDamageBone(victim)
  if boneHit and boneId then
    Damages.new(Damages, boneId, weaponHash)

    -- General blood-spatter NUI effect on hit
    if Config.Damages.effects.generalEffect then
      -- Cancel any existing blood timer and start a new one
      if Damages.effectTimer then
        Damages.effectTimer:forceEnd()
        Citizen.Wait(1)
      end
      SendNUIMessage({ action = "setVisibleBlood", data = true })
      Damages.effectTimer = lib.timer(100, function()
        SendNUIMessage({ action = "setVisibleBlood", data = false })
      end, true)
    end
  end
end)

-- menu: open the healing UI for a target player (medic-only, with camera and animations)
function Damages.menu(self, targetServerId)
  -- Anti-spam guard
  if self.antiSpam > GetGameTimer() then return end
  if self.isOpened then return end

  -- Resolve target ped from server ID
  local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
  if not (targetPed and targetPed ~= 0 and cache.ped ~= targetPed) then return end

  -- Wait if NUI is focused before proceeding
  if IsNuiFocused() then
    Citizen.Wait(300)
  end

  -- Check that the local player has a permitted job
  local job = Bridge.Framework.fetchPlayerJob()
  if not (job and Editable.allJobs[job.name]) then
    Bridge.Notify.showNotify(locale("no_access"), "error")
    return
  end

  -- Populate available healing items in the NUI list
  self.getHealingItems(self)

  self.isOpened          = true
  self.pulseChecked      = false
  self.temperatureChecked= false
  self.targetId          = targetServerId

  -- Fetch medic animation dict
  local animDict = lib.requestAnimDict("amb@medic@standing@tendtodead@base")

  -- Position camera: above the target's head if dead, otherwise at standing level
  local targetState = Player(targetServerId).state
  local camOffset
  if targetState.isDead then
    camOffset = GetOffsetFromEntityInWorldCoords(targetPed, 0.1, 0.05, 1.5)
  else
    camOffset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 2.65, 0.4)
  end

  -- Create and set up scripted camera
  self.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  SetCamCoord(self.camera, camOffset)
  SetCamFov(self.camera, 42.0)
  PointCamAtEntity(self.camera, targetPed, 0.0, 0.0, 0.0, true)
  SetCamActive(self.camera, true)
  RenderScriptCams(true, true, 1000, true, true)

  SetNuiFocus(true, true)
  SendNUIMessage({ action = "setVisibleHealing", data = true })

  -- Play medic standing animation on local ped
  TaskPlayAnim(cache.ped, animDict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)

  -- Fetch target player's damage state
  local targetDamages = targetState.damages or {}

  -- Count damage entries for debug logging
  local damageCount = 0
  for _ in pairs(targetDamages) do damageCount = damageCount + 1 end

  -- Auto-resolve any open alert for this player
  if Config.Alerts and Config.Alerts.enabled and Config.Alerts.autoResolveAlert then
    if GetResourceState('p_ambulancejob') == 'started' then
      pcall(function() exports.p_ambulancejob:resolvePlayerAlert(targetServerId) end)
    end
  end

  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.info(("[Damages] Opening damages menu for player %s with %s damages"):format(targetServerId, damageCount))
    print(targetState.isDead and "Player is dead" or "Player is alive")
  end

  -- If target has no injuries but is dead, initiate CPR instead
  if damageCount < 1 and targetState.isDead then
    self.isOpened = false
    TriggerServerEvent("p_ambulancejob/server/damages/performCPR", targetServerId)
    return
  end

  -- Notify the server to freeze the target player during treatment
  if Config.Damages.informAndFreeze then
    TriggerServerEvent("p_ambulancejob/server/damages/treatedPlayer", {
      player = targetServerId,
      state  = true,
    })
  end

  -- Per-frame state tracking (previous bone list and injury snapshot)
  local prevBones    = {}
  local prevInjuries = {}

  -- Main poll loop: refresh bone positions and injury data in the NUI
  while self.isOpened do
    Citizen.Wait(Config.Damages.refreshRate or 500)

    local bonePosData    = {}
    local currentInjuries= {}
    local playerState    = Player(targetServerId).state
    local stateDamages   = playerState.damages or {}

    -- Map each bone to its screen position and injury data
    for boneName, boneHash in pairs(self.bones) do
      local boneIndex = GetPedBoneIndex(targetPed, boneHash)
      if boneIndex and boneIndex ~= -1 then
        local worldPos = GetWorldPositionOfEntityBone(targetPed, boneIndex)
        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)

        local resX = Damages.resolution.x
        local resY = Damages.resolution.y

        -- Resolve injury data for this bone (nil if no damage)
        local injurySlot = stateDamages[boneName]
        local injuryData = nil
        if injurySlot then
          injuryData = self.getBoneData(self, injurySlot.injuries or {})
          if injuryData then
            -- lbl_302 equivalent: add this bone to the NUI bone list
            table.insert(currentInjuries, {
              bone      = boneName,
              boneLabel = locale(boneName) or boneName,
              weapon    = (injuryData and injuryData.weapon) or "unknown",
              items     = (injuryData and injuryData.items) or {},
              label     = (injuryData and injuryData.label) or boneName,
              color     = (injuryData and injuryData.color) or "red",
            })
          end
        end

        bonePosData[boneName] = {
          injury   = injuryData,
          position = {
            x = onScreen and (screenX * resX) or 0,
            y = onScreen and (screenY * resY) or 0,
          },
        }
      end
    end

    if Bridge and Bridge.Config and Bridge.Config.Debug then
      lib.print.info("[Damages] Sending player bones:", bonePosData)
    end

    SendNUIMessage({ action = "setPlayerBones", data = bonePosData or {} })

    -- Only resend injuries to NUI when the set has changed
    if not lib.table.matches(prevBones, currentInjuries) then
      prevBones = currentInjuries
      if Bridge and Bridge.Config and Bridge.Config.Debug then
        lib.print.info("[Damages] Sending player injuries:", currentInjuries)
      end
      SendNUIMessage({ action = "setPlayerInjuries", data = currentInjuries or {} })
    end

    -- Send pulse / temperature readings (only if the medic has checked them)
    if Bridge and Bridge.Config and Bridge.Config.Debug then
      lib.print.info("Sending player pulse and temperature")
    end
    SendNUIMessage({
      action = "setPlayerData",
      data   = {
        pulse       = (self.pulseChecked and playerState.pulse) or nil,
        temperature = (self.temperatureChecked and playerState.temperature) or nil,
      },
    })
  end
end

-- close: tear down camera, release NUI focus, clear tasks, and unfreeze target
function Damages.close(self)
  self.antiSpam = GetGameTimer() + 1500

  -- Destroy scripted camera if active
  if self.camera and DoesCamExist(self.camera) then
    RenderScriptCams(false, true, 1000, true, true)
    DestroyCam(self.camera, false)
    self.camera = nil
  end

  -- Unfreeze target player on the server
  if Config.Damages.informAndFreeze then
    TriggerServerEvent("p_ambulancejob/server/damages/treatedPlayer", {
      player = self.targetId,
      state  = false,
    })
  end

  SetNuiFocus(false, false)
  SendNUIMessage({ action = "setVisibleHealing", data = false })
  ClearPedTasks(cache.ped)
  self.isOpened = false
end

-- NUI callback: heal a specific bone using a selected item
RegisterNUICallback("damages/healBone", function(data, cb)
  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.info("Received healBone callback with data:", data)
  end

  -- Validate required fields
  if not (data and data.bone and data.item) then
    cb(false)
    return
  end

  -- Block healing non-mouth bones if target has critical pulse/temperature
  local targetState = Player(Damages.targetId).state
  if (targetState.criticalPulse or targetState.criticalTemperature) and data.bone ~= "mouth" then
    Bridge.Notify.showNotify(locale("stabilize_player_pulse_or_temperature"), "error")
    cb(false)
    return
  end

  -- Validate that the bone actually has damage before playing progress bar
  local targetState = Player(Damages.targetId).state
  local damages = targetState.damages
  local isTempItem = Config.Temperature and Config.Temperature.items and Config.Temperature.items[data.item]

  if not isTempItem and data.bone ~= "mouth" then
    if not (damages and damages[data.bone]) then
      Bridge.Notify.showNotify(locale("no_injuries_on_bone"), "error")
      cb(false)
      return
    end
  end

  -- Interactive Minigames Branch (Pluto & Lation Engine)
  if Config.InteractiveMinigames and Config.InteractiveMinigames.enabled then
    local itemStr = tostring(data.item):lower()
    local isBulletWound = damages and damages[data.bone] and damages[data.bone].bullet

    if isBulletWound and Config.InteractiveMinigames.bullet then
      exports.loki_prescriptions:StartBulletMinigame(Damages.targetId, data.bone)
      cb(true)
      return
    elseif (itemStr:find("suture") or itemStr:find("surgical")) and Config.InteractiveMinigames.suture then
      exports.loki_prescriptions:StartSutureMinigame(Damages.targetId, data.bone)
      cb(true)
      return
    elseif (itemStr:find("clamp") or itemStr:find("artery")) and Config.InteractiveMinigames.clamp then
      exports.loki_prescriptions:StartClampMinigame(Damages.targetId, data.bone)
      cb(true)
      return
    elseif (itemStr:find("bandage") or itemStr:find("dressing") or itemStr:find("gauze")) and Config.InteractiveMinigames.bandage then
      exports.loki_prescriptions:StartBandageMinigame(Damages.targetId, data.bone)
      cb(true)
      return
    end
  end

  -- Fallback: Play progress bar and animation BEFORE the server call
  local clipOptions = { "idle_a", "idle_b", "idle_c" }
  local itemData = Bridge.Inventory.getItemData(data.item)

  local progressOpts = {
    duration  = 5000,
    label     = locale("using_item", (itemData and itemData.label) or data.item or ""),
    canCancel = false,
    anim      = {
      dict = "amb@medic@standing@tendtodead@idle_a",
      clip = clipOptions[math.random(1, 3)],
    },
    disable = { move = false, combat = true, mouse = false, car = true },
  }

  local completed = Bridge.Progress.Start(progressOpts)

  if not completed then
    cb(false)
    return
  end

  -- Server callback: attempt to heal the bone
  local result = lib.callback.await("p_ambulancejob/server/damages/healBone", false, Damages.targetId, data)

  if Bridge and Bridge.Config and Bridge.Config.Debug then
    lib.print.info("Heal bone result:", result)
  end

  -- On success: play idle anim and sound
  if result then
    TaskPlayAnim(cache.ped, "amb@medic@standing@tendtodead@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    if Sounds then
      Sounds.preset(Sounds, "heal")
    end
  end

  cb(result)
end)

-- NUI callback: check target's pulse (Launches BP Minigame or fallback progress bar)
RegisterNUICallback("damages/checkPulse", function(_, _)
  if Damages.antiSpam > GetGameTimer() then return end

  Damages.antiSpam = GetGameTimer() + 4000

  if Config.InteractiveMinigames and Config.InteractiveMinigames.enabled and Config.InteractiveMinigames.bp then
    exports.loki_prescriptions:StartBPMinigame(Damages.targetId, "rightArm")
    Damages.pulseChecked = true
    return
  end

  local done = Bridge.Progress.StartCircle({
    duration = 5000,
    label    = locale("checking_pulse"),
    position = "bottom",
  })
  if done then
    Damages.pulseChecked = true
  end
end)

-- NUI callback: check target's temperature (5-second progress bar, sets temperatureChecked flag)
RegisterNUICallback("damages/checkTemperature", function(_, _)
  if Damages.antiSpam > GetGameTimer() then return end

  Damages.antiSpam = GetGameTimer() + 5000

  local done = Bridge.Progress.StartCircle({
    duration = 5000,
    label    = locale("checking_temperature"),
    position = "bottom",
  })
  if done then
    Damages.temperatureChecked = true
  end
end)

-- NUI callback: close the healing frame when the NUI hides itself
RegisterNUICallback("hideFrame", function(data, _)
  if data.name == "setVisibleHealing" then
    Damages.close(Damages)
  end
end)

-- reviveClips: animation sequence used during CPR/revive
Damages.reviveClips = {
  { "cpr_def",  "cpr_intro",    14000 },
  { "cpr_str",  "cpr_pumpchest",10000 },
  { "cpr_str",  "cpr_success",  33000 },
}

-- playRevive: play the CPR animation sequence on the local medic ped
function Damages.playRevive(self, opts)
  if not Config.Damages.reviveAnimation then return end

  self.activeCPR = true

  -- Determine which ped is being revived (target or self)
  local targetPed
  if opts.isRevived then
    targetPed = GetPlayerPed(GetPlayerFromServerId(opts.targetId))
  end
  targetPed = targetPed or cache.ped

  -- Determine which ped performs CPR (the medic)
  local medicPed
  if opts.isRevived then
    medicPed = cache.ped
  else
    medicPed = GetPlayerPed(GetPlayerFromServerId(opts.targetId))
  end

  -- Position medic next to target, rotated 90°
  local offsetPos = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.8, 0.0)
  SetEntityCoordsNoOffset(medicPed, offsetPos.x, offsetPos.y, offsetPos.z, true, true, true)
  SetEntityHeading(medicPed, GetEntityHeading(targetPed) + 90.0)
  Citizen.Wait(100)

  -- Load appropriate anim dicts based on whether this ped is the one being revived
  local charSuffix  = opts.isRevived and "char_b" or "char_a"
  local defDict = lib.requestAnimDict(("mini@cpr@%s@cpr_def"):format(charSuffix))
  local strDict = lib.requestAnimDict(("mini@cpr@%s@cpr_str"):format(charSuffix))

  -- Play each clip in the sequence
  for i = 1, #self.reviveClips do
    local clip       = self.reviveClips[i]
    local clipName   = clip[1]  -- e.g. "cpr_def"
    local animation  = clip[2]  -- e.g. "cpr_intro"
    local duration   = clip[3]

    -- Select dict: cpr_def clips use defDict, all others use strDict
    local animDict = (clipName == "cpr_def" and defDict) and defDict or strDict

    TaskPlayAnim(cache.ped, animDict, animation, 8.0, -8.0, duration, 1, 0, false, false, false)

    -- Last clip: close the menu and wait the reduced remainder
    if i == 3 then
      self.close(self)
      Citizen.Wait(duration - 3000)
    else
      Citizen.Wait(duration)
    end
  end

  RemoveAnimDict(defDict)
  RemoveAnimDict(strDict)

  -- If this was a revive sequence, trigger the revive event
  if opts.isRevived then
    TriggerEvent("p_ambulancejob/client/death/revive")
    Citizen.Wait(500)
  end

  self.activeCPR = false
end

-- Net event: trigger CPR/revive animation from server
RegisterNetEvent("p_ambulancejob/client/damages/playRevive", function(opts)
  Damages.playRevive(Damages, opts)
end)

-- Net event: clear pending ped tasks (called when CPR is interrupted)
RegisterNetEvent("p_ambulancejob/client/damages/clearAnim", function()
  ClearPedTasks(cache.ped)
end)

-- damagesUI: toggle the body-damage NUI overlay on/off
function Damages.damagesUI(self)
  -- Only available when Damages is enabled and the damagesUI feature is on
  if not (Config.Damages.enabled and Config.Damages.damagesUI) then return end

  self.damagesUiState = not self.damagesUiState

  if not self.damagesUiState then
    SendNUIMessage({ action = "setVisibleBody", data = false })
    return
  end

  -- Build per-body-part damage flags for the NUI
  local bodyParts = {}
  local index = 1
  for partName, partData in pairs(self.damages) do
    -- hasInjury = true if the injuries table has at least one entry
    local hasInjury = false
    for _ in pairs(partData.injuries) do
      hasInjury = true
      break
    end
    bodyParts[index] = {
      part   = partName,
      damage = hasInjury and 1 or 0,
    }
    index = index + 1
  end

  SendNUIMessage({ action = "setVisibleBody", data = true })
  SendNUIMessage({ action = "setBodyDamages", data = bodyParts })
end

-- applyModifiers: apply weapon damage modifiers from Config
function Damages.applyModifiers(self)
  for weaponHash, modifier in pairs(Config.Damages.modifiers) do
    SetWeaponDamageModifier(weaponHash, modifier)
  end
end

-- Net event: freeze/unfreeze the local ped when being treated by a medic
RegisterNetEvent("p_ambulancejob/client/damages/setBeingHealed", function(state)
  FreezeEntityPosition(cache.ped, state)
  if state then
    Bridge.Notify.showNotify(locale("you_are_being_treated"), "inform")
  end
end)

-- Wait until Config.Damages is available before registering exports/keybinds
while not (Config and Config.Damages) do
  Citizen.Wait(100)
end

-- Export: toggle the damages body UI from external scripts
exports("damagesUI", function()
  Damages.damagesUI(Damages)
end)

-- Optional keybind to open the damages UI
if Config.Damages.damagesUI and Config.Damages.damagesUIKey then
  lib.addKeybind({
    name        = "damagesUI",
    description = locale("check_your_body_damages"),
    defaultKey  = Config.Damages.damagesUIKey,
    onPressed   = function()
      Damages.damagesUI(Damages)
    end,
  })
end

-- Boot: apply weapon damage modifiers on resource start
Citizen.CreateThread(function()
  Damages.applyModifiers(Damages)
end)

-- Handlers de evento para abertura do diagnóstico clínico
RegisterNetEvent("p_ambulancejob/client/damages/openDamages", function(targetServerId)
  Damages.menu(Damages, targetServerId)
end)

RegisterNetEvent("loki_prescriptions:client:openDamages", function(targetServerId)
  Damages.menu(Damages, targetServerId)
end)

exports("openDamages", function(targetServerId)
  Damages.menu(Damages, targetServerId)
end)