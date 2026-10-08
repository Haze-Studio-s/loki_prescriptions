--[[
    ============================================================================
    TV Terminal - Hospital incoming-patient board (Client)
    Absorbed from p_ambulancejob/client/tv.lua
    Prop + DUI on ex_prop_ex_tv_flat_01, driven by GlobalState
    ============================================================================
]]

while not (Config and Config.TV) do
    Wait(1)
end

if not Config.TV.enabled then
    return
end

TV = {
    tvs          = {},
    currentPoint = nil,
}

local TV_MODEL       = 'ex_prop_ex_tv_flat_01'
local TV_TEXTURE     = 'script_rt_ex_tvscreen'

local function sendTerminal(dui, terminalData)
    if not dui then return end
    dui:sendMessage({
        action = 'setTerminal',
        value  = {
            data    = terminalData or nil,
            locales = lib.getLocales(),
        },
    })
end

function TV:create(hospitalId, tvId, tvData)
    self.tvs[hospitalId] = self.tvs[hospitalId] or {}
    self.tvs[hospitalId][tvId] = {
        coords = tvData.coords,
        rot    = tvData.rot,
    }

    local point = lib.points.new({
        coords   = vec3(tvData.coords.x, tvData.coords.y, tvData.coords.z),
        distance = 20.0,
    })

    function point:onEnter()
        local modelHash = lib.requestModel(TV_MODEL)
        local tvObject  = CreateObject(modelHash, tvData.coords.x, tvData.coords.y, tvData.coords.z, false, true, true)
        self.tvObject   = tvObject

        SetEntityRotation(tvObject, tvData.rot.x, tvData.rot.y, tvData.rot.z, 2, true)
        FreezeEntityPosition(tvObject, true)

        local terminalData = nil
        local tvState = GlobalState['loki_prescriptions/tv']
        if tvState and tvState[hospitalId] and tvState[hospitalId][tvId] then
            terminalData = tvState[hospitalId][tvId]
        end

        local dui = lib.dui:new({
            url    = ('nui://%s/web/tv.html'):format(cache.resource),
            width  = 1920,
            height = 1080,
            debug  = (Bridge and Bridge.Config and Bridge.Config.Debug) or false,
        })
        self.dui = dui

        Citizen.Wait(1000)
        sendTerminal(dui, terminalData)

        TV.currentPoint = {
            point    = self,
            hospital = hospitalId,
            tv       = tvId,
            dui      = dui,
        }

        Citizen.Wait(10)
        AddReplaceTexture(TV_MODEL, TV_TEXTURE, dui.dictName, dui.txtName)

        Bridge.Target.addEntity(tvObject, {
            {
                name     = 'loki_prescriptions/clearTerminal',
                label    = locale('clear_terminal'),
                icon     = 'fa-solid fa-trash',
                distance = 3.0,
                groups   = Editable.allJobs,
                onSelect = function()
                    TriggerServerEvent('loki_prescriptions:server:setTvTerminal', {
                        hospital = hospitalId,
                        tv       = tvId,
                        clear    = true,
                    })
                end,
            },
        })
    end

    function point:onExit()
        TV.currentPoint = nil
        RemoveReplaceTexture(TV_MODEL, TV_TEXTURE)

        if self.tvObject and DoesEntityExist(self.tvObject) then
            DeleteEntity(self.tvObject)
            self.tvObject = nil
        end

        if self.dui then
            pcall(function()
                self.dui:remove()
            end)
            self.dui = nil
        end
    end
end

AddStateBagChangeHandler('loki_prescriptions/tv', 'global', function(_, _, value)
    if not TV.currentPoint then return end

    local hospitalData = value and value[TV.currentPoint.hospital]
    if not hospitalData then return end

    sendTerminal(TV.currentPoint.dui, hospitalData[TV.currentPoint.tv])
end)

function TV:terminal()
    local job = Bridge.Framework.fetchPlayerJob()
    if not job or not Editable.allJobs[job.name] then
        Bridge.Notify.showNotify(locale('no_access'), 'error')
        return
    end

    local tvOptions = {}
    local optIdx    = 1

    for hospitalKey, hospitalTvs in pairs(Config.TV.points or {}) do
        local hospitalCfg = Config.Hospitals[hospitalKey]
        if hospitalCfg and hospitalCfg.jobs then
            for _, allowedJob in ipairs(hospitalCfg.jobs) do
                if allowedJob == job.name then
                    for tvKey in pairs(hospitalTvs) do
                        tvOptions[optIdx] = {
                            label    = tvKey,
                            value    = tvKey,
                            hospital = hospitalKey,
                        }
                        optIdx = optIdx + 1
                    end
                    break
                end
            end
        end
    end

    if #tvOptions < 1 then
        Bridge.Notify.showNotify(locale('not_founded_tvs'), 'error')
        return
    end

    local input = lib.inputDialog(locale('set_terminal'), {
        {
            type     = 'select',
            label    = locale('select_tv'),
            options  = tvOptions,
            required = true,
        },
        {
            type  = 'input',
            label = locale('set_name'),
        },
        {
            type  = 'number',
            label = locale('set_age'),
            min   = 0,
            max   = 100,
        },
        {
            type    = 'select',
            label   = locale('set_gender'),
            options = {
                { value = locale('male'),   label = locale('male')   },
                { value = locale('female'), label = locale('female') },
            },
        },
        {
            type    = 'select',
            label   = locale('set_condition'),
            options = {
                { value = locale('stable'),   label = locale('stable')   },
                { value = locale('critical'), label = locale('critical') },
            },
        },
        {
            type        = 'number',
            label       = locale('set_eta'),
            description = locale('set_eta_desc'),
            min         = 0,
            max         = 120,
        },
    })

    if not input then return end

    local selectedHospital = nil
    for _, opt in ipairs(tvOptions) do
        if opt.value == input[1] then
            selectedHospital = opt.hospital
            break
        end
    end

    TriggerServerEvent('loki_prescriptions:server:setTvTerminal', {
        hospital  = selectedHospital,
        tv        = input[1],
        name      = input[2],
        age       = input[3],
        gender    = input[4],
        condition = input[5],
        eta       = input[6],
    })
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)

    while not (Config.TV and Config.TV.points) do
        Wait(100)
    end

    for hospitalId, tvList in pairs(Config.TV.points) do
        for tvId, tvData in pairs(tvList) do
            TV:create(hospitalId, tvId, tvData)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end

    if TV.currentPoint and TV.currentPoint.point and TV.currentPoint.point.onExit then
        pcall(function()
            TV.currentPoint.point:onExit()
        end)
    end
end)
