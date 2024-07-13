--[ Enumeration Class ]--
local Enumeration = {}
Enumeration.__index = function(_, key)
    error(`{key} is not a valid member of Enum`, 2)
end

function Enumeration.new(enumItems)
    if typeof(enumItems) ~= "table" then
        error("enumItems must be a table!", 2)
    end

    local enum = {}
    for itemName, itemValue in enumItems do
        if typeof(itemName) ~= "string" then
            error("itemName must be a string!", 2)
        elseif typeof(itemValue) ~= "number" or itemValue % 1 ~= 0 then
            error("itemValue must be an integer!", 2)
        end

        enum[itemName] = {
            name = itemName,
            value = itemValue,
        }
    end

    return setmetatable(enum, Enumeration)
end

return Enumeration
