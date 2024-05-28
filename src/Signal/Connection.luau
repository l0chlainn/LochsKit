--[[ Connection Class ]]--
local Connection = {}
Connection.__index = Connection

function Connection.new(handler)
    if typeof(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    -- construct an instance of Connection
    local self = {
        connected = true,
        handler = handler,
    }
    setmetatable(self, Connection)

    return self
end

function Connection:disconnect()
    self.connected = false
end

return Connection
