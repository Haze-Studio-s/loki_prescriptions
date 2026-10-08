--[[
    ============================================================================
    TV Terminal - Hospital incoming-patient board (Server)
    Absorbed from p_ambulancejob/client/tv.lua + server/tv.lua
    ============================================================================
]]

local tvState = {}

GlobalState['loki_prescriptions/tv'] = tvState

RegisterNetEvent('loki_prescriptions:server:setTvTerminal', function(data)
    if type(data) ~= 'table' or not data.hospital or not data.tv then return end

    local src = source
    local job = Bridge.Framework.getPlayerJob(src)
    if not job or not Editable.allJobs[job.name] then
        Bridge.Notify.showNotify(src, locale('no_access'), 'error')
        return
    end

    if not tvState[data.hospital] then
        tvState[data.hospital] = {}
    end

    if data.clear then
        tvState[data.hospital][data.tv] = nil
    else
        tvState[data.hospital][data.tv] = {
            name      = data.name,
            age       = data.age,
            gender    = data.gender,
            condition = data.condition,
            eta       = data.eta,
        }
    end

    GlobalState['loki_prescriptions/tv'] = tvState
end)
