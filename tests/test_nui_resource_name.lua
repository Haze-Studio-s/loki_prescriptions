-- tests/test_nui_resource_name.lua
-- Validação dinâmica do nome do resource no raio-X e cleanup de foco do haze_prescriptions
local selfPath = (((arg and arg[0]) or ''):gsub(string.char(92), '/'))
local ROOT = selfPath:match('^(.*)/tests/[^/]+$') or '.'
local function read(rel) local f = io.open(ROOT .. '/' .. rel, 'rb'); if not f then return nil end local s = f:read('*a'); f:close(); return s end
local passed, failed = 0, 0
local function check(n, c, d) if c then passed = passed + 1; print('  [PASS] ' .. n) else failed = failed + 1; print('  [FAIL] ' .. n .. ' - ' .. tostring(d or '')) end end

local appJs = read('web/xray/app.js') or ''
check('web/xray/app.js existe', appJs ~= '')
check('web/xray/app.js usa GetParentResourceName', appJs:find('GetParentResourceName', 1, true) ~= nil)
check('web/xray/app.js nao tem https://loki_prescriptions/', appJs:find('https://loki_prescriptions/', 1, true) == nil)

local xrayLua = read('client/xray.lua') or ''
check('client/xray.lua tem onResourceStop liberando foco', xrayLua:find('onResourceStop', 1, true) ~= nil and xrayLua:find('SetNuiFocus%(false,%s*false%)') ~= nil)

print(string.format('RESULTADO PRESCRIPTIONS NUI: %d PASS, %d FAIL', passed, failed))
os.exit(failed == 0 and 0 or 1)
