AWRPUtils = AWRPUtils or {}

function AWRPUtils.Trim(s)
    if type(s) ~= 'string' then return s end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function AWRPUtils.DumpTable(o)
    return json.encode(o, {indent = true})
end

function AWRPUtils.Log(msg, level)
    local prefix = '^5[awrp_tuning]^7'
    if level == 'error' then
        prefix = '^1[awrp_tuning - BŁĄD]^7'
    elseif level == 'success' then
        prefix = '^2[awrp_tuning - SUKCES]^7'
    end
    print(prefix .. ' ' .. tostring(msg))
end

function AWRPUtils.IsMechanicJob(jobName)
    return jobName == 'mechanic' or jobName == 'tuner'
end