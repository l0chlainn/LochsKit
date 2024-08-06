--[ Exception Class ]--
local Exception = {}
Exception.__index = Exception
Exception.__tostring = function(exception)
    return `Error: '{exception.code}', Reason: '{exception.reason}'`
end

function Exception.new(code, reason)
    if
        type(code) ~= "number"
        or code < 0
        or code % 1 ~= 0
    then
        error("code must be a positive integer!", 2)
    elseif type(reason) ~= "string" then
        error("reason must be a string!", 2)
    end

    return setmetatable({
        code = code,
        reason = reason,
    }, Exception)
end

return Exception
