--[[ CustomEnum Class ]]--
local CustomEnum = {}
CustomEnum.__index = function(_, key)
    error(`{key} is not a valid member of CustomEnum`, 2)
end

function CustomEnum.new(enumMap)
    if typeof(enumMap) ~= "table" then
        error("enumMap must be a table!", 2)
    end

    return setmetatable(enumMap, CustomEnum)
end

return CustomEnum
