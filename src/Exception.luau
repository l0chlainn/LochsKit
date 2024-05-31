--[[ Exception Class ]]--
local Exception = {}
Exception.__index = Exception
Exception.__tostring = function(exception)
    return `Exception: {exception.code}, Reason: {exception.reason}`
end

function Exception.new(code, reason)
    if typeof(code) ~= "number" then
        error("code must be a number!", 2)
    elseif typeof(reason) ~= "string" then
        error("reason must be a string!", 2)
    end

    return setmetatable({
        code = code,
        reason = reason,
    }, Exception)
end

return Exception
