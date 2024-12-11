--!strict

type eventCallback = (...any) -> ()
type disconnectCallback = () -> ()

type ConnectionClass = {
    __index: ConnectionClass,

    is: (value: any) -> boolean,
    new: (eventCallback: eventCallback, disconnectCallback: disconnectCallback) -> Connection,

    disconnect: (self: Connection) -> (),
}
export type Connection = typeof(setmetatable({} :: {
    isConnected: boolean,

    _nextConnection: Connection?,
    _previousConnection: Connection?,

    _eventCallback: eventCallback,
    _disconnectCallback: disconnectCallback,
}, {} :: ConnectionClass))

--[ Connection Class ]--
local Connection = {} :: ConnectionClass
Connection.__index = Connection

function Connection.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Connection
end

function Connection.new(eventCallback: eventCallback, disconnectCallback: disconnectCallback): Connection
    if type(eventCallback) ~= "function" then
        error(`expected function for eventCallback, got '{typeof(eventCallback)}'`, 2)
    elseif type(disconnectCallback) ~= "function" then
        error(`expected function for disconnectCallback, got '{typeof(disconnectCallback)}'`, 2)
    end

    return setmetatable({
        isConnected = true,

        _nextConnection = nil,
        _previousConnection = nil,

        _eventCallback = eventCallback,
        _disconnectCallback = disconnectCallback,
    }, Connection)
end

function Connection.disconnect(self: Connection): ()
    if not Connection.is(self) then
        error(`expected Connection for self, got '{typeof(self)}'`, 2)
    end

    if not self.isConnected then
        return
    end
    self.isConnected = false
    self._disconnectCallback()
end

return Connection
