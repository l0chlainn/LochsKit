--!strict

type connectionCallback = (...any) -> ()
type signalCallback = () -> ()

type ConnectionClass = {
    __index: ConnectionClass,

    is: (value: any) -> boolean,
    new: (connectionCallback: connectionCallback, signalCallback: signalCallback) -> Connection,

    call: (self: Connection, ...any) -> (),
    disconnect: (self: Connection) -> (),
}
export type Connection = typeof(setmetatable({} :: {
    isConnected: boolean,

    _nextConnection: Connection?,
    _previousConnection: Connection?,

    _connectionCallback: connectionCallback,
    _signalCallback: signalCallback,
}, {} :: ConnectionClass))

--[ Connection Class ]--
local Connection = {} :: ConnectionClass
Connection.__index = Connection

function Connection.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Connection
end

function Connection.new(
    connectionCallback: connectionCallback,
    signalCallback: signalCallback
): Connection
    if type(connectionCallback) ~= "function" then
        error(`expected function for connectionCallback, got '{typeof(connectionCallback)}'`, 2)
    elseif type(signalCallback) ~= "function" then
        error(`expected function for signalCallback, got '{typeof(signalCallback)}'`, 2)
    end

    return setmetatable({
        isConnected = true,

        _nextConnection = nil,
        _previousConnection = nil,

        _connectionCallback = connectionCallback,
        _signalCallback = signalCallback,
    }, Connection)
end

function Connection.disconnect(self: Connection): ()
    if not Connection.is(self) then
        error(`expected Connection for self, got '{typeof(self)}'`, 2)
    end

    if self.isConnected then
        self.isConnected = false
        self._signalCallback()
    end
end

return table.freeze(Connection)
