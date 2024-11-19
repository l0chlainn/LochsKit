--!strict

type ExceptionClass = {
    __index: ExceptionClass,
    __tostring: (exception: Exception) -> string,

    is: (value: any) -> boolean,
    new: (id: string, message: string) -> Exception,
}
export type Exception = typeof(setmetatable({} :: {
    id: string,
    message: string,
}, {} :: ExceptionClass))

--[ Exception Class ]--
local Exception = {} :: ExceptionClass
Exception.__index = Exception
Exception.__tostring = function(exception: Exception): string
    return `Error: '{exception.id}', Reason: '{exception.message}'`
end

function Exception.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Exception
end

function Exception.new(id: string, message: string): Exception
    if type(id) ~= "number" then
        error("id must be a number!", 2)
    elseif type(message) ~= "string" then
        error("message must be a string!", 2)
    end

    return setmetatable({
        id = id,
        message = message,
    }, Exception)
end

return Exception
