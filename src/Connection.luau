--!strict

type callback = () -> ()

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable({} :: {
    isConnected: boolean,

    _callback: callback?,
    _disconnect: callback?,

    _next: Connection?,
    _previous: Connection?,
}, Connection))

local function isConnection(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Connection
end

local function createConnection(
    callback: callback,
    disconnect: callback
): Connection
    if type(callback) ~= "function" then
        error(`Invalid argument #1. (function expected, got {typeof(callback)})`, 2)
    elseif type(disconnect) ~= "function" then
        error(`Invalid argument #2. (function expected, got {typeof(disconnect)})`, 2)
    end

    return setmetatable({
        isConnected = true,

        _callback = callback,
        _disconnect = disconnect,

        _next = nil,
        _previous = nil,
    }, Connection)
end

function Connection.disconnect(self: Connection): ()
    if not isConnection(self) then
        error(`Invalid argument #1. (Connection expected, got {typeof(self)})`, 2)
    end

    if self.isConnected then
        self.isConnected = false

        -- I dislike this, it would work to do the following instead, but I don't like the risk.
        -- (self._disconnect :: callback)()
        local disconnect = self._disconnect
        if disconnect then
            disconnect()
        end

        -- Clear these references, otherwise we may experience a memory leak.
        self._callback = nil
        self._disconnect = nil
    end
end

return table.freeze({
    is = isConnection,
    new = createConnection,
})
