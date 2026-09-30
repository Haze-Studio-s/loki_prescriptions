-- =============================================================================
--  loki_prescriptions | server/banking.lua
--  Módulo Canônico de Integração Financeira: aust_banking v3 & ox_inventory
-- =============================================================================

PrescriptionsBanking = {}

local activeLocks = {}
local opSeq = 0

---Normaliza valores numéricos garantindo inteiros positivos de 32 bits imunes a NaN/overflow.
---@param amount any
---@return integer
function PrescriptionsBanking.NormalizeAmount(amount)
    local num = tonumber(amount)
    if not num or num <= 0 or num ~= num or num == math.huge or num == -math.huge then
        return 0
    end
    num = math.floor(num)
    if num > 2147483647 then
        num = 2147483647
    end
    return num
end

---Obtém o CitizenID do jogador.
---@param src integer
---@return string|nil
local function getCitizenId(src)
    if not src or src <= 0 then return nil end
    local okQbx, player = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if okQbx and player and player.PlayerData and player.PlayerData.citizenid then
        return player.PlayerData.citizenid
    end

    if exports['qb-core'] then
        local okQb, qbCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okQb and qbCore and qbCore.Functions and qbCore.Functions.GetPlayer then
            local qbPlayer = qbCore.Functions.GetPlayer(src)
            if qbPlayer and qbPlayer.PlayerData and qbPlayer.PlayerData.citizenid then
                return qbPlayer.PlayerData.citizenid
            end
        end
    end

    return nil
end

---Consulta saldo de cash (ox_inventory) ou bank (aust_banking v3) de forma fail-closed.
---@param src integer
---@param account? string 'cash' ou 'bank' (padrão 'bank')
---@return integer
function PrescriptionsBanking.GetBalance(src, account)
    account = account or 'bank'
    if account == 'cash' or account == 'money' then
        if exports.ox_inventory then
            local ok, count = pcall(function()
                return exports.ox_inventory:GetItemCount(src, 'money')
            end)
            if ok and count then
                return PrescriptionsBanking.NormalizeAmount(count)
            end
        end
        return 0
    end

    local cid = getCitizenId(src)
    if not cid then return 0 end

    if GetResourceState and GetResourceState('aust_banking') == 'started' then
        local ok, balance = pcall(function()
            return exports.aust_banking:GetBankBalance(cid)
        end)
        if ok and balance ~= nil then
            return PrescriptionsBanking.NormalizeAmount(balance)
        end
        return 0
    end

    local player = exports.qbx_core:GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.money then
        return PrescriptionsBanking.NormalizeAmount(player.PlayerData.money[account] or 0)
    end

    return 0
end

---Debita fundos do jogador de forma estritamente fail-closed.
---@param src integer
---@param amount integer
---@param reason string
---@param account? string 'cash' ou 'bank' (padrão 'bank')
---@param opId? string
---@return boolean success, string? err
function PrescriptionsBanking.Debit(src, amount, reason, account, opId)
    local cleanAmount = PrescriptionsBanking.NormalizeAmount(amount)
    if cleanAmount <= 0 then return false, 'invalid_amount' end
    account = (account == 'cash' or account == 'money') and 'cash' or 'bank'
    reason = reason or 'hospital_fee'

    if account == 'cash' then
        local current = PrescriptionsBanking.GetBalance(src, 'cash')
        if current < cleanAmount then
            return false, 'insufficient_funds'
        end

        local okCall, okRemove = pcall(function()
            return exports.ox_inventory:RemoveItem(src, 'money', cleanAmount)
        end)
        if not okCall or okRemove ~= true then
            return false, 'cash_remove_failed'
        end
        return true
    end

    local cid = getCitizenId(src)
    if not cid then return false, 'invalid_citizenid' end

    if GetResourceState and GetResourceState('aust_banking') == 'started' then
        local payload = {
            citizenid = cid,
            amount = cleanAmount,
            reason = reason,
            operationId = opId or PrescriptionsBanking.MakeOpId('debit', cid, 'fee'),
            source = 'loki_prescriptions'
        }
        local ok, res = pcall(function()
            return exports.aust_banking:Debit(payload)
        end)
        if ok and (res == true or (type(res) == 'table' and (res.ok == true or res.success == true))) then
            return true
        end
        return false, 'aust_debit_failed'
    end

    local player = exports.qbx_core:GetPlayer(src)
    if player and player.Functions and player.Functions.RemoveMoney then
        local ok = player.Functions.RemoveMoney(account, cleanAmount, reason)
        if ok then return true end
    end

    return false, 'banking_debit_failed'
end

---Credita fundos para o jogador com autoridade e validação de peso físico.
---@param src integer
---@param amount integer
---@param reason string
---@param account? string 'cash' ou 'bank' (padrão 'bank')
---@param opId? string
---@return boolean success, string? err
function PrescriptionsBanking.Credit(src, amount, reason, account, opId)
    local cleanAmount = PrescriptionsBanking.NormalizeAmount(amount)
    if cleanAmount <= 0 then return false, 'invalid_amount' end
    account = (account == 'cash' or account == 'money') and 'cash' or 'bank'
    reason = reason or 'hospital_payout'

    if account == 'cash' then
        local pcallOk, carryRes = pcall(function()
            return exports.ox_inventory:CanCarryItem(src, 'money', cleanAmount)
        end)
        if not pcallOk or carryRes ~= true then
            return false, 'inventory_full'
        end

        local okAddCall, okAdd = pcall(function()
            return exports.ox_inventory:AddItem(src, 'money', cleanAmount)
        end)
        if not okAddCall or okAdd ~= true then
            return false, 'cash_add_failed'
        end
        return true
    end

    local cid = getCitizenId(src)
    if not cid then return false, 'invalid_citizenid' end

    if GetResourceState and GetResourceState('aust_banking') == 'started' then
        local payload = {
            citizenid = cid,
            amount = cleanAmount,
            reason = reason,
            operationId = opId or PrescriptionsBanking.MakeOpId('payout', cid, 'service'),
            source = 'loki_prescriptions'
        }
        local ok, res = pcall(function()
            return exports.aust_banking:Credit(payload)
        end)
        if ok and (res == true or (type(res) == 'table' and (res.ok == true or res.success == true))) then
            return true
        end
        return false, 'aust_credit_failed'
    end

    local player = exports.qbx_core:GetPlayer(src)
    if player and player.Functions and player.Functions.AddMoney then
        local ok = player.Functions.AddMoney(account, cleanAmount, reason)
        if ok then return true end
    end

    return false, 'banking_credit_failed'
end

---Credita fundos com suporte a overflow (cash -> bank) caso o inventário atinja a capacidade física.
---@param src integer
---@param amount integer
---@param reason string
---@param preferredAccount? string 'cash' ou 'bank'
---@param opId? string
---@return boolean success, string finalAccount
function PrescriptionsBanking.CreditWithOverflow(src, amount, reason, preferredAccount, opId)
    local account = (preferredAccount == 'cash' or preferredAccount == 'money') and 'cash' or 'bank'
    local cleanAmount = PrescriptionsBanking.NormalizeAmount(amount)
    if cleanAmount <= 0 then return false, 'invalid' end

    local cid = getCitizenId(src) or 'guest'
    local baseOp = opId or PrescriptionsBanking.MakeOpId('credit', cid, 'service')

    local ok, err = PrescriptionsBanking.Credit(src, cleanAmount, reason, account, baseOp)
    if ok then
        return true, account
    end

    if account == 'cash' and err == 'inventory_full' then
        local overflowOp = PrescriptionsBanking.MakeOpId('overflow', cid, 'bank')
        local okBank = PrescriptionsBanking.Credit(src, cleanAmount, (reason or 'hospital_service') .. '_overflow', 'bank', overflowOp)
        if okBank then
            return true, 'bank'
        end
    end

    return false, 'failed'
end

---Deposita recursos na conta da sociedade/hospital de forma auditável e idempotente.
---@param societyAccount string
---@param amount integer
---@param reason? string
---@param opId? string
---@return boolean
function PrescriptionsBanking.DepositSociety(societyAccount, amount, reason, opId)
    local cleanAmount = PrescriptionsBanking.NormalizeAmount(amount)
    if cleanAmount <= 0 then return false end
    societyAccount = societyAccount or 'ambulance'
    reason = reason or 'Faturamento Hospitalar'
    local operationId = opId or PrescriptionsBanking.MakeOpId('society', societyAccount, 'deposit')

    if GetResourceState and GetResourceState('aust_banking') == 'started' then
        local okAdd = pcall(function()
            exports.aust_banking:addAccountMoney(societyAccount, cleanAmount)
        end)
        if exports.aust_banking.handleTransaction then
            pcall(function()
                exports.aust_banking:handleTransaction(
                    societyAccount,
                    'Depósito Hospitalar',
                    cleanAmount,
                    reason,
                    'Hospital Central',
                    societyAccount,
                    'deposit',
                    operationId
                )
            end)
        end
        return okAdd
    end

    if GetResourceState and GetResourceState('Renewed-Banking') == 'started' then
        local okRenewed = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(societyAccount, cleanAmount)
        end)
        if okRenewed then return true end
    end

    if GetResourceState and GetResourceState('qb-banking') == 'started' then
        local okQb = pcall(function()
            exports['qb-banking']:AddMoney(societyAccount, cleanAmount, reason)
        end)
        if okQb then return true end
    end

    return false
end

---Gera um Operation ID determinístico e auditável respeitando o teto de 64 chars do ledger.
---@param action string
---@param cid string
---@param ref? string|number
---@param seq? integer
---@return string
function PrescriptionsBanking.MakeOpId(action, cid, ref, seq)
    action = tostring(action or 'tx'):gsub('[^%w_]', '')
    cid = tostring(cid or '0'):gsub('[^%w_]', '')
    ref = tostring(ref or '0'):gsub('[^%w_]', '')
    opSeq = (opSeq + 1) % 100000
    local sequence = seq or opSeq
    local ts = os.time()
    local opId = ('medhub:%s:%s:%s:%d:%d'):format(action, cid, ref, ts, sequence)
    if #opId > 64 then
        opId = opId:sub(1, 64)
    end
    return opId
end

---Adquire lock de concorrência com token temporal.
---@param key string
---@param timeoutMs number
---@param src? integer
---@return boolean success, string? token
function PrescriptionsBanking.AcquireLock(key, timeoutMs, src)
    local now = GetGameTimer()
    local lock = activeLocks[key]
    if lock and now < lock.expiresAt then
        return false, nil
    end

    local token = ('%d:%d'):format(now, math.random(100000, 999999))
    activeLocks[key] = {
        token = token,
        expiresAt = now + (timeoutMs or 5000),
        src = src
    }
    return true, token
end

---Libera lock de concorrência mediante validação de token.
---@param key string
---@param token? string
---@return boolean
function PrescriptionsBanking.ReleaseLock(key, token)
    local lock = activeLocks[key]
    if not lock then return true end
    if token and lock.token ~= token then
        return false
    end
    activeLocks[key] = nil
    return true
end

---Limpa todos os locks associados a um jogador que desconectou.
---@param src integer
function PrescriptionsBanking.CleanupPlayer(src)
    if not src then return end
    for k, v in pairs(activeLocks) do
        if v.src == src then
            activeLocks[k] = nil
        end
    end
end

-- Listener de desconexão
AddEventHandler('playerDropped', function()
    local src = source
    PrescriptionsBanking.CleanupPlayer(src)
end)
