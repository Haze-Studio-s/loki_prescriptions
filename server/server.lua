local activeRedeems = {}

local function notify(type, msg, heading, src)
    heading = heading or _U('pharmacy')
    if Config.Notification == 'lib' then
        TriggerClientEvent('loki_prescriptions:oxNotify', src, heading, msg, type)
    elseif Config.Notification == 'custom' then
        CustomNotify(type, msg, heading, src)
    elseif Config.Notification == 'okoknotify' then
        TriggerClientEvent('okokNotify:Alert', src, heading, msg, 5000, type, true)
    elseif Config.Notification == 'esx' then
        TriggerClientEvent('esx:showNotification', src, msg, type, 5000)
    elseif Config.Notification == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, msg, type == 'error' and 'error' or 'success', 5000)
    elseif Config.Notification == 'wasabi_notify' then
        TriggerClientEvent('wasabi_notify:notify', src, heading, msg, 5000, type, true)
    else
        TriggerClientEvent('loki_prescriptions:oxNotify', src, heading, msg, type)
    end
end

local function hasInsurance(src)
    local ident = GetPlayerIdentifier(src)
    if not ident then return false end
    local rs = SQL("SELECT date FROM prescription_insurance WHERE identifier = ? LIMIT 1", {ident})
    if not rs or not rs[1] then
        return false
    else
        if not Config.Insurance.duration then return true end
        local time = os.time() * 1000
        local recordDate = tonumber(rs[1].date) or 0
        if time - recordDate < Config.Insurance.duration * 1000 then
            return true
        else
            return false
        end
    end
end
exports('hasInsurance', hasInsurance)

-- Emissão de Receita Médica com Sanitização Estrita e Carimbo de Autoridade
RegisterServerEvent('loki_prescriptions:createPrescription', function(rawPayload, targetServerId)
    local src = source
    if not src or src <= 0 then return end

    -- Verificação de cargo médico/farmacêutico
    if Config.PrescriptionJobs then
        local playerjob = GetPlayerJob(src)
        local allowed = false
        for _, v in ipairs(Config.PrescriptionJobs) do
            if v == playerjob then
                allowed = true
                break
            end
        end
        if not allowed then
            notify("error", _U("invalidJob"), _U("pharmacy"), src)
            return
        end
    end

    -- Verificação da posse física do bloco de receitas
    if not HasItem(src, Config.PrescriptionPadItem) then
        notify("error", _U("noPrescription"), _U("pharmacy"), src)
        return
    end

    if type(rawPayload) ~= 'table' then return end

    -- Sanitização dos medicamentos prescritos contra whitelist do servidor
    local sanitizedMeds = {}
    local rawMeds = rawPayload.medications
    if type(rawMeds) ~= 'table' then
        if rawPayload.medication and rawPayload.amount then
            rawMeds = {{ label = rawPayload.medication, amount = rawPayload.amount }}
        else
            return
        end
    end

    if #rawMeds == 0 or #rawMeds > (Config.MaxDifferentMeds or 4) then return end

    local minRefills = 99
    for _, rawMed in ipairs(rawMeds) do
        local medDef = nil
        for _, itemCfg in ipairs(Config.Medicine) do
            if itemCfg.label == rawMed.label or itemCfg.item == rawMed.item then
                medDef = itemCfg
                break
            end
        end

        local amount = tonumber(rawMed.amount)
        if medDef and amount and amount > 0 and amount % 1 == 0 then
            local maxAllowed = Config.MaxMedsPerPrescription or 5
            local validAmount = math.min(amount, maxAllowed)
            local medRefills = medDef.refills or 1
            if medRefills < minRefills then
                minRefills = medRefills
            end

            table.insert(sanitizedMeds, {
                item = medDef.item,
                label = medDef.label,
                cost = medDef.cost,
                amount = validAmount,
                refills_total = medRefills,
                refills_remaining = medRefills
            })
        end
    end

    if #sanitizedMeds == 0 then return end

    local currentTime = os.time()
    local expirationSeconds = (Config.ExpirationDays or 3) * 86400
    local canonicalDoctorCid = GetPlayerIdentifier(src)
    local canonicalDoctorName = GetCharacterName(src)
    local doctorRefills = tonumber(rawPayload.refills) or tonumber(rawPayload.days) or minRefills
    if doctorRefills < 1 then doctorRefills = 1 end
    if doctorRefills > 10 then doctorRefills = 10 end

    local rxToken = string.format("RX-%s-%04d", tostring(os.date("%m%d")), math.random(1000, 9999))

    local prescriptionMetadata = {
        data = {
            token = rxToken,
            patient = rawPayload.patient and tostring(rawPayload.patient):sub(1, 40) or "Paciente",
            doctor = canonicalDoctorName,
            doctor_cid = canonicalDoctorCid,
            medications = sanitizedMeds,
            notes = rawPayload.notes and tostring(rawPayload.notes):sub(1, 100) or "",
            refills_remaining = doctorRefills,
            refills_total = doctorRefills,
            created_at = currentTime,
            expires_at = currentTime + expirationSeconds,
        },
        date = currentTime,
        description = ("Dr(a). %s | Retiradas: %d | Código: %s | Válida até: %s"):format(
            canonicalDoctorName,
            doctorRefills,
            rxToken,
            os.date("%d/%m/%Y", currentTime + expirationSeconds)
        )
    }

    -- Suporte à entrega direta ao paciente próximo (se especificado)
    local recipientSrc = src
    if targetServerId and targetServerId > 0 and targetServerId ~= src then
        local doctorPed = GetPlayerPed(src)
        local targetPed = GetPlayerPed(targetServerId)
        if targetPed > 0 and #(GetEntityCoords(doctorPed) - GetEntityCoords(targetPed)) <= 3.5 then
            recipientSrc = targetServerId
        end
    end

    local given = GiveItem(recipientSrc, Config.PrescriptionItem, 1, prescriptionMetadata)
    if given then
        if recipientSrc ~= src then
            notify('info', _U('prescriptionGivenToPatient', GetCharacterName(recipientSrc)), _U('pharmacy'), src)
            notify('info', _U('prescriptionReceived', canonicalDoctorName), _U('pharmacy'), recipientSrc)
            if NexusBridge then
                NexusBridge.SendNotification(recipientSrc, 'LSMC Farmácia', ('Nova receita emitida pelo Dr(a). %s'):format(canonicalDoctorName), 'docs', { rx = true })
            end
            if VpPhoneBridge then
                VpPhoneBridge.SendNotification(recipientSrc, 'LSMC Farmácia', ('Receita médica emitida pelo Dr(a). %s. Retire na farmácia.'):format(canonicalDoctorName), 'Health')
            end
            if VpTabletBridge then
                local patientCid = GetPlayerIdentifier(recipientSrc)
                VpTabletBridge.RecordAmbulanceReport(patientCid, canonicalDoctorName, 'Receituário Emitido', ('Medicamentos controlados prescritos para %s.'):format(GetCharacterName(recipientSrc)))
            end
        else
            notify('info', _U('medsGiven'), _U('pharmacy'), src)
        end
    end
end)

function ShowPrescription(src, properties)
    TriggerClientEvent('loki_prescriptions:viewPrescription', src, properties)
end

function CreatePrescription(src)
    if not HasItem(src, Config.PrescriptionPadItem) then return end

    if Config.PrescriptionJobs then
        local playerjob = GetPlayerJob(src)
        local allowed = false
        for _, v in ipairs(Config.PrescriptionJobs) do
            if v == playerjob then
                allowed = true
                break
            end
        end
        if not allowed then
            notify("error", _U("invalidJob"), _U("pharmacy"), src)
            return
        end
    end

    TriggerClientEvent('loki_prescriptions:createPrescription', src)
end

-- Contratação do Plano de Saúde
RegisterServerEvent('loki_prescriptions:buyInsurance', function()
    local src = source
    if not src or src <= 0 then return end

    local npcPos = vector3(Config.Insurance.npc.position.x, Config.Insurance.npc.position.y, Config.Insurance.npc.position.z)
    if #(npcPos - GetEntityCoords(GetPlayerPed(src))) > 10.0 then return end

    local ident = GetPlayerIdentifier(src)
    if not ident then return end

    local rs = SQL("SELECT date FROM prescription_insurance WHERE identifier = ? LIMIT 1", {ident})
    if rs and rs[1] then
        local time = os.time() * 1000
        local recordDate = tonumber(rs[1].date) or 0
        if not Config.Insurance.duration or (time - recordDate < Config.Insurance.duration * 1000) then
            notify('info', _U('insuranceStillValid'), _U('insurancy'), src)
            return
        end
    end

    if RemovePlayerMoney(src, Config.Insurance.price) then
        if rs and rs[1] then
            SQL("UPDATE prescription_insurance SET date = CURRENT_TIMESTAMP() WHERE identifier = ? LIMIT 1", {ident})
        else
            SQL("INSERT INTO prescription_insurance (identifier) VALUES (?)", {ident})
        end
        notify('info', _U('insuranceBought'), _U('insurancy'), src)
    else
        notify('info', _U('insufficientFunds'), _U('insurancy'), src)
    end
end)

-- Resgate de Medicamentos na Farmácia com Mutex, Distância e Fail-Closed
RegisterServerEvent('loki_prescriptions:redeemPrescription', function()
    local src = source
    if not src or src <= 0 then return end

    -- Trava atômica por jogador com timeout de 10s
    local now = os.time()
    if activeRedeems[src] and (now - activeRedeems[src]) < 10 then
        notify('error', _U('busyProcessing'), _U('pharmacy'), src)
        return
    end
    activeRedeems[src] = now

    local function releaseLock()
        activeRedeems[src] = nil
    end

    -- Validação de Proximidade Física do Balcão da Farmácia no Servidor (3D + Z check)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or IsEntityDead(ped) then
        releaseLock()
        return
    end

    local pedCoords = GetEntityCoords(ped)
    local isNearAnyPharmacy = false
    local maxDist = Config.MaxRedeemDistance or 4.0

    for _, pharmacy in ipairs(Config.Pharmacies) do
        local pPos = vector3(pharmacy.position.x, pharmacy.position.y, pharmacy.position.z)
        local dist = #(pedCoords - pPos)
        local zDiff = math.abs(pedCoords.z - pPos.z)
        if dist <= maxDist and zDiff <= 3.5 then
            isNearAnyPharmacy = true
            break
        end
    end

    if not isNearAnyPharmacy then
        releaseLock()
        notify('error', _U('tooFarFromPharmacy'), _U('pharmacy'), src)
        return
    end

    -- Obtenção do item no inventário
    local item = GetItem(src, Config.PrescriptionItem)
    if not item then
        releaseLock()
        notify('info', _U('noPrescription'), _U('pharmacy'), src)
        return
    end

    -- Fixação estrita do slot para evitar slot poisoning / swap exploits
    local fixedSlot = tonumber(item.slot)
    if not fixedSlot or fixedSlot < 1 or fixedSlot ~= math.floor(fixedSlot) then
        releaseLock()
        notify('error', 'Erro de integridade do inventário.', _U('pharmacy'), src)
        return
    end

    local metadata = item.metadata or item.info
    if not metadata or not metadata.data then
        releaseLock()
        notify('error', _U('noPrescription'), _U('pharmacy'), src)
        return
    end

    local pData = metadata.data

    -- Verificação de Expiração Temporal
    if pData.expires_at and now > tonumber(pData.expires_at) then
        releaseLock()
        notify('error', _U('prescriptionExpired'), _U('pharmacy'), src)
        return
    end

    -- Mapeamento dos medicamentos a serem concedidos
    local prescribed = pData.medications or {{
        label = pData.medication,
        amount = pData.amount
    }}

    local itemsToGive = {}
    local totalPrice = 0
    local maxAllowedPerMed = Config.MaxMedsPerPrescription or 10

    for _, prescriptionMed in ipairs(prescribed) do
        local medConfig = nil
        for _, v in ipairs(Config.Medicine) do
            if v.label == prescriptionMed.label or v.item == prescriptionMed.item then
                medConfig = v
                break
            end
        end

        local rawAmount = tonumber(prescriptionMed.amount)
        if not medConfig or not rawAmount or rawAmount < 1 then
            releaseLock()
            notify('error', 'Medicamento inválido na receita.', _U('pharmacy'), src)
            return
        end

        local amount = math.min(math.floor(rawAmount), maxAllowedPerMed)
        local unitCost = tonumber(medConfig.cost) or 0
        if unitCost < 0 then unitCost = 0 end

        table.insert(itemsToGive, { med = medConfig, amount = amount })
        totalPrice = totalPrice + (unitCost * amount)
    end

    if totalPrice > 1000000 or totalPrice < 0 then
        releaseLock()
        notify('error', 'Valor anômalo detectado.', _U('pharmacy'), src)
        return
    end

    -- Verificação Prévia de Capacidade de Inventário (Fail-Closed)
    for _, giveData in ipairs(itemsToGive) do
        if not CanCarryItem(src, giveData.med.item, giveData.amount) then
            releaseLock()
            notify('error', _U('inventoryFull'), _U('pharmacy'), src)
            return
        end
    end

    -- Aplicação do Desconto do Convênio Médico
    local hasHealthPlan = hasInsurance(src)
    if hasHealthPlan then
        totalPrice = math.floor(totalPrice * (Config.Insurance.reduction or 0.35))
    end

    -- Cobrança Financeira do Paciente (Fail-Closed antes da entrega)
    if totalPrice > 0 then
        if not RemovePlayerMoney(src, totalPrice) then
            releaseLock()
            notify('error', _U('insufficientFunds'), _U('pharmacy'), src)
            return
        end
        -- Depósito do faturamento na conta do hospital
        DepositHospitalMoney(totalPrice)
    end

    -- Controle de Vias e Retenção
    local currentRefills = tonumber(pData.refills_remaining) or 1
    if currentRefills > 1 then
        -- Decrementa 1 via e carimba nos metadados
        pData.refills_remaining = currentRefills - 1
        metadata.data = pData
        metadata.description = ("Dr(a). %s | Restam: %d retirada(s) | Código: %s | Válida até: %s"):format(
            pData.doctor or "Médico",
            pData.refills_remaining,
            pData.token or "RX",
            os.date("%d/%m/%Y", tonumber(pData.expires_at) or (os.time() + 86400 * 3))
        )

        local updated = UpdateItemMetadata(src, fixedSlot, metadata)
        if not updated then
            -- Se não conseguiu atualizar metadados no slot, remove a unidade
            RemoveItem(src, Config.PrescriptionItem, metadata, fixedSlot)
        end
        notify('info', _U('refillRemaining', pData.refills_remaining), _U('pharmacy'), src)
    else
        -- Última via: receita é retida e removida do inventário
        RemoveItem(src, Config.PrescriptionItem, metadata, fixedSlot)
        notify('info', _U('refillExhausted'), _U('pharmacy'), src)
    end

    -- Entrega dos medicamentos ao paciente
    for _, giveData in ipairs(itemsToGive) do
        GiveItem(src, giveData.med.item, giveData.amount)
    end

    notify('info', _U('medsGiven'), _U('pharmacy'), src)
    releaseLock()
end)

-- Limpeza de memória do rate limit e travas
AddEventHandler('playerDropped', function()
    activeRedeems[source] = nil
end)

RegisterServerEvent('loki_prescriptions:requestPrescribePad', function(targetServerId)
    local src = source
    if not src or src <= 0 then return end

    if Config.PrescriptionJobs then
        local playerjob = GetPlayerJob(src)
        local allowed = false
        for _, v in ipairs(Config.PrescriptionJobs) do
            if v == playerjob then
                allowed = true
                break
            end
        end
        if not allowed then
            notify("error", _U("invalidJob"), _U("pharmacy"), src)
            return
        end
    end

    if not HasItem(src, Config.PrescriptionPadItem) then
        notify("error", _U("noPrescription"), _U("pharmacy"), src)
        return
    end

    TriggerClientEvent('loki_prescriptions:client:openPadForPatient', src, targetServerId)
end)

-- Dispensação de Medicamentos via Token Digital (EHR / Farmácia Central)
RegisterServerEvent('loki_prescriptions:server:dispensePharmacyToken', function(token)
    local src = source
    if not src or src <= 0 then return end

    if Config.PrescriptionJobs then
        local playerjob = GetPlayerJob(src)
        local allowed = false
        for _, v in ipairs(Config.PrescriptionJobs) do
            if v == playerjob then
                allowed = true
                break
            end
        end
        if not allowed then
            notify("error", _U("invalidJob"), _U("pharmacy"), src)
            return
        end
    end

    local cleanToken = token and tostring(token):sub(1, 20) or "RX-DESCONHECIDO"
    notify("success", string.format("Prescrição %s dispensada com sucesso pelo farmacêutico/médico.", cleanToken), _U("pharmacy"), src)
end)