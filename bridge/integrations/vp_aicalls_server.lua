--[[
    LOKI MEDICAL SUITE - VP_AICALLS INTEGRATION (SERVER)
    Transbordo do atendimento EMS (chamado IA) para o prontuário clínico.
    Contrato: docs/integrations/STRETCHER_OWNERSHIP_SPIKE.md (Opção A)
]]

VpAiCallsBridge = {
    reports = {},
}

function VpAiCallsBridge.IsActive()
    return GetResourceState('vp_aicalls') == 'started'
end

--- Registra o relatório de atendimento de um chamado EMS do vp_aicalls.
--- Fail-closed: payload inválido ou reporter sem job de EMS é rejeitado.
---@param report table { schema=1, reporter=number, callId, callType, priority, details, hospital, times, crew }
---@return boolean ok, string|nil reason
function VpAiCallsBridge.RegisterCallReport(report)
    if type(report) ~= 'table' or report.schema ~= 1 or not report.callId or not report.reporter then
        return false, 'invalid_payload'
    end

    local job = Bridge.Framework.getPlayerJob(report.reporter)
    if not job or not Editable.allJobs[job.name] then
        return false, 'no_access'
    end

    local crewNames = {}
    for _, member in ipairs(report.crew or {}) do
        local name = Bridge.Framework.getPlayerName(member.id or member)
        crewNames[#crewNames + 1] = name or ('ID %s'):format(tostring(member.id or member))
    end

    VpAiCallsBridge.reports[report.callId] = {
        schema      = 1,
        callId      = report.callId,
        callType    = report.callType,
        priority    = report.priority,
        details     = report.details,
        hospital    = report.hospital,
        times       = report.times,
        crew        = crewNames,
        reportedBy  = report.reporter,
        receivedAt  = os.time(),
    }

    for _, member in ipairs(report.crew or {}) do
        local id = member.id or member
        if type(id) == 'number' and id > 0 then
            Bridge.Notify.showNotify(id, locale('call_report_registered'), 'success')
        end
    end

    return true
end

exports('RegisterCallReport', VpAiCallsBridge.RegisterCallReport)

exports('GetCallReports', function()
    return VpAiCallsBridge.reports
end)

exports('GetCallReport', function(callId)
    return VpAiCallsBridge.reports[callId]
end)
