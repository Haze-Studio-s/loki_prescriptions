-- =============================================================================
--  loki_prescriptions | tests/prescriptions_banking_spec.lua
--  Suíte de Testes Unitários: PrescriptionsBanking, aust_banking v3 & ox_inventory
-- =============================================================================

local passed = 0
local failed = 0

local function assertEqual(name, actual, expected)
    if actual == expected then
        passed = passed + 1
        print(('  [PASS] %s'):format(name))
    else
        failed = failed + 1
        print(('  [FAIL] %s - Esperado: %s, Obtido: %s'):format(name, tostring(expected), tostring(actual)))
    end
end

local function assertTrue(name, condition)
    if condition then
        passed = passed + 1
        print(('  [PASS] %s'):format(name))
    else
        failed = failed + 1
        print(('  [FAIL] %s - Condição não satisfeita'):format(name))
    end
end

-- Mocks FiveM / QBox
_G.GetGameTimer = function() return 100000 end
_G.GetResourceState = function(res)
    if res == 'aust_banking' then return 'started' end
    if res == 'ox_inventory' then return 'started' end
    if res == 'qbx_core' then return 'started' end
    return 'missing'
end

local eventHandlers = {}
_G.AddEventHandler = function(event, cb)
    eventHandlers[event] = cb
end

local mockItems = {}
local mockCarry = true
local mockAustBalance = 15000
local mockAustDebitOk = true
local mockAustCreditOk = true
local mockSocietyOk = true
local lastAustPayload = nil
local lastSocietyAccount = nil
local lastSocietyAmount = nil
local lastTransaction = nil

_G.exports = {
    ox_inventory = {
        GetItemCount = function(self, src, item)
            if type(self) ~= 'table' then item = src; src = self end
            return mockItems[item] or 0
        end,
        CanCarryItem = function(self, src, item, count)
            if type(self) ~= 'table' then count = item; item = src; src = self end
            return mockCarry
        end,
        AddItem = function(self, src, item, count, metadata)
            if type(self) ~= 'table' then metadata = count; count = item; item = src; src = self end
            if not mockCarry then return false end
            mockItems[item] = (mockItems[item] or 0) + count
            return true
        end,
        RemoveItem = function(self, src, item, count)
            if type(self) ~= 'table' then count = item; item = src; src = self end
            local current = mockItems[item] or 0
            if current >= count then
                mockItems[item] = current - count
                return true
            end
            return false
        end,
    },
    aust_banking = {
        GetBankBalance = function(self, cid)
            if type(self) ~= 'table' then cid = self end
            return mockAustBalance
        end,
        Debit = function(self, payload)
            if type(self) ~= 'table' then payload = self end
            lastAustPayload = payload
            return mockAustDebitOk and { ok = true } or { ok = false, error = 'fail' }
        end,
        Credit = function(self, payload)
            if type(self) ~= 'table' then payload = self end
            lastAustPayload = payload
            return mockAustCreditOk and { ok = true } or { ok = false, error = 'fail' }
        end,
        addAccountMoney = function(self, account, amount)
            if type(self) ~= 'table' then amount = account; account = self end
            lastSocietyAccount = account
            lastSocietyAmount = amount
            return mockSocietyOk
        end,
        handleTransaction = function(self, account, title, amount, desc, emitter, target, ttype)
            lastTransaction = { account = account, title = title, amount = amount, desc = desc }
            return true
        end
    },
    qbx_core = {
        GetPlayer = function(self, src)
            if type(self) ~= 'table' then src = self end
            return {
                PlayerData = {
                    citizenid = 'DOC_PATIENT_99',
                    charinfo = { firstname = 'Gregory', lastname = 'House' },
                    money = { cash = 200, bank = 5000 }
                }
            }
        end
    }
}

-- Carregar o módulo PrescriptionsBanking
dofile('resources/[standalone]/loki_prescriptions/server/banking.lua')

print('--- [SUÍTE LOKI_PRESCRIPTIONS: PrescriptionsBanking Unit Tests] ---')

-- 1. Normalização Numérica
assertEqual('NormalizeAmount: valor positivo', PrescriptionsBanking.NormalizeAmount(150), 150)
assertEqual('NormalizeAmount: float arredonda para baixo', PrescriptionsBanking.NormalizeAmount(150.9), 150)
assertEqual('NormalizeAmount: string numérica', PrescriptionsBanking.NormalizeAmount('300'), 300)
assertEqual('NormalizeAmount: string inválida retorna 0', PrescriptionsBanking.NormalizeAmount('abc'), 0)
assertEqual('NormalizeAmount: negativo retorna 0', PrescriptionsBanking.NormalizeAmount(-50), 0)
assertEqual('NormalizeAmount: zero retorna 0', PrescriptionsBanking.NormalizeAmount(0), 0)
assertEqual('NormalizeAmount: nil retorna 0', PrescriptionsBanking.NormalizeAmount(nil), 0)

-- 2. Geração e formato de OperationId
local opId = PrescriptionsBanking.MakeOpId('prescription', 'DOC_PATIENT_99', 'medication')
assertTrue('MakeOpId: prefixo correto', opId:find('^medhub:prescription:DOC_PATIENT_99') ~= nil)
assertTrue('MakeOpId: tamanho <= 64 caracteres', #opId <= 64)

-- 3. Consulta de Saldo (GetBalance)
mockItems['money'] = 450
assertEqual('GetBalance: cash via ox_inventory', PrescriptionsBanking.GetBalance(1, 'cash'), 450)
assertEqual('GetBalance: bank via aust_banking', PrescriptionsBanking.GetBalance(1, 'bank'), 15000)

-- 4. Débito Fail-Closed (Debit)
-- Débito Cash
local okDebitCash = PrescriptionsBanking.Debit(1, 100, 'remédio', 'cash')
assertTrue('Debit: cash com saldo suficiente tem sucesso', okDebitCash)
assertEqual('Debit: cash decrementa ox_inventory', mockItems['money'], 350)

local okDebitCashFail = PrescriptionsBanking.Debit(1, 1000, 'remédio caro', 'cash')
assertTrue('Debit: cash sem saldo suficiente falha', not okDebitCashFail)

-- Débito Bank
local okDebitBank = PrescriptionsBanking.Debit(1, 500, 'consulta médica', 'bank')
assertTrue('Debit: bank via aust_banking tem sucesso', okDebitBank)
assertEqual('Debit: bank payload citizenid correto', lastAustPayload.citizenid, 'DOC_PATIENT_99')
assertEqual('Debit: bank payload amount correto', lastAustPayload.amount, 500)
assertEqual('Debit: bank payload source loki_prescriptions', lastAustPayload.source, 'loki_prescriptions')

mockAustDebitOk = false
local okDebitBankFail = PrescriptionsBanking.Debit(1, 500, 'consulta', 'bank')
assertTrue('Debit: bank falha quando aust_banking recusa', not okDebitBankFail)
mockAustDebitOk = true

-- 5. Crédito (Credit)
mockCarry = true
local okCreditCash = PrescriptionsBanking.Credit(1, 200, 'reembolso', 'cash')
assertTrue('Credit: cash tem sucesso com espaço no inventário', okCreditCash)
assertEqual('Credit: cash incrementa saldo no inventário', mockItems['money'], 550)

mockCarry = false
local okCreditCashNoSpace, errCarry = PrescriptionsBanking.Credit(1, 200, 'reembolso', 'cash')
assertTrue('Credit: cash falha se inventário estiver cheio', not okCreditCashNoSpace and errCarry == 'inventory_full')
mockCarry = true

local okCreditBank = PrescriptionsBanking.Credit(1, 1200, 'pagamento médico', 'bank')
assertTrue('Credit: bank tem sucesso via aust_banking', okCreditBank)
assertEqual('Credit: bank payload citizenid correto', lastAustPayload.citizenid, 'DOC_PATIENT_99')
assertEqual('Credit: bank payload amount correto', lastAustPayload.amount, 1200)

-- 6. CreditWithOverflow (Cash -> Bank)
mockCarry = true
local okOverflow1, method1 = PrescriptionsBanking.CreditWithOverflow(1, 300, 'prêmio', 'cash')
assertTrue('CreditWithOverflow: entrega em cash quando cabe', okOverflow1 and method1 == 'cash')

mockCarry = false
local okOverflow2, method2 = PrescriptionsBanking.CreditWithOverflow(1, 300, 'prêmio', 'cash')
assertTrue('CreditWithOverflow: fallback para bank quando inventário cheio', okOverflow2 and method2 == 'bank')
mockCarry = true

-- 7. DepositSociety
local okSoc = PrescriptionsBanking.DepositSociety('ambulance', 1500, 'Taxa de Internação')
assertTrue('DepositSociety: tem sucesso via aust_banking', okSoc)
assertEqual('DepositSociety: conta da sociedade correta', lastSocietyAccount, 'ambulance')
assertEqual('DepositSociety: valor creditado na sociedade correto', lastSocietyAmount, 1500)
assertEqual('DepositSociety: handleTransaction registrou extrato corporativo', lastTransaction.account, 'ambulance')

local okSocInvalid = PrescriptionsBanking.DepositSociety('ambulance', -100)
assertTrue('DepositSociety: falha com valor inválido/negativo', not okSocInvalid)

-- 8. Concorrência e Locks por Token
local okLock1, token1 = PrescriptionsBanking.AcquireLock('patient:1', 5000, 1)
assertTrue('AcquireLock: primeiro lock concedido com token válido', okLock1 == true and type(token1) == 'string')

local okLock2, token2 = PrescriptionsBanking.AcquireLock('patient:1', 5000, 1)
assertTrue('AcquireLock: tentativa simultânea para a mesma chave é rejeitada', not okLock2 and token2 == nil)

local releasedWrong = PrescriptionsBanking.ReleaseLock('patient:1', 'token_invalido')
assertTrue('ReleaseLock: token incorreto não libera o lock', not releasedWrong)

local releasedCorrect = PrescriptionsBanking.ReleaseLock('patient:1', token1)
assertTrue('ReleaseLock: token correto libera com sucesso', releasedCorrect)

local okLock3, token3 = PrescriptionsBanking.AcquireLock('patient:1', 5000, 1)
assertTrue('AcquireLock: reaquisição permitida após liberação', okLock3 == true and token3 ~= nil)
PrescriptionsBanking.ReleaseLock('patient:1', token3)

-- 9. Expurgo em playerDropped
local okDrop, tokenDrop = PrescriptionsBanking.AcquireLock('patient:42', 5000, 42)
assertTrue('Locks: lock ativo para player 42', okDrop == true and tokenDrop ~= nil)
if eventHandlers['playerDropped'] then
    eventHandlers['playerDropped']() -- simula playerDropped do source 42
end
PrescriptionsBanking.CleanupPlayer(42)
local okAfterDrop, tokenAfterDrop = PrescriptionsBanking.AcquireLock('patient:42', 5000, 42)
assertTrue('CleanupPlayer: remove locks residuais após playerDropped', okAfterDrop == true and tokenAfterDrop ~= nil)
PrescriptionsBanking.ReleaseLock('patient:42', tokenAfterDrop)

-- 10. Validação da Bridge (bridge/server.lua)
Config = { HospitalAccount = 'ambulance' }
dofile('resources/[standalone]/loki_prescriptions/bridge/server.lua')
local bridgeSocOk = Bridge.Society.addMoney(1, 'ambulance', 800, 'Exame Laboratorial')
assertTrue('Bridge.Society.addMoney: delega com sucesso para PrescriptionsBanking.DepositSociety', bridgeSocOk == true)
assertEqual('Bridge.Society.addMoney: valor creditado corretamente', lastSocietyAmount, 800)

print(('-------------------------------------------------'))
print(('Testes Finalizados: %d PASS, %d FAIL'):format(passed, failed))
if failed > 0 then os.exit(1) end
