--[[ Connection Class ]]--
local Connection = {}
Connection.__index = Connection

function Connection.new(handler)
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
