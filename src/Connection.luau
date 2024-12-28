--!strict

type callback = (...any) -> ()
type disconnect = () -> ()

type ConnectionClass = {
    __index: ConnectionClass,

    is: (value: any) -> boolean,
    new: (callback: callback, disconnect: disconnect) -> Connection,

    call: (self: Connection, ...any) -> (),
    disconnect: (self: Connection) -> (),
}
export type Connection = typeof(setmetatable({} :: {
    isConnected: boolean,

    _nextConnection: Connection?,
    _previousConnection: Connection?,

    _callback: callback,
    _disconnect: disconnect,
}, {} :: ConnectionClass))

local idleRunnerThread: thread? = nil

local function acquireRunnerThreadAndRunCallback(callback: callback, ...: any): ()
    local acquiredRunnerThread = idleRunnerThread :: thread
    idleRunnerThread = nil
    callback(...)
    idleRunnerThread = acquiredRunnerThread
end

local function persistentRunnerThread(): ()
    while true do
        acquireRunnerThreadAndRunCallback(coroutine.yield())
    end
end

--[ Connection Class ]--
local Connection = {} :: ConnectionClass
Connection.__index = Connection

function Connection.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Connection
end

function Connection.new(callback: callback, disconnect: disconnect): Connection
    if type(callback) ~= "function" then
        error(`expected function for callback, got '{typeof(callback)}'`, 2)
    elseif type(disconnect) ~= "function" then
        error(`expected function for disconnect, got '{typeof(disconnect)}'`, 2)
    end

    return setmetatable({
        isConnected = true,

        _nextConnection = nil,
        _previousConnection = nil,

        _callback = callback,
        _disconnect = disconnect,
    }, Connection)
end

function Connection.call(self: Connection, ...: any): ()
    if not Connection.is(self) then
        error(`expected Connection for self, got '{typeof(self)}'`, 2)
    end

    if not idleRunnerThread then
        idleRunnerThread = task.spawn(persistentRunnerThread)
    end
    task.spawn(
        idleRunnerThread :: thread,
        self._callback,
        ...
    )
end

function Connection.disconnect(self: Connection): ()
    if not Connection.is(self) then
        error(`expected Connection for self, got '{typeof(self)}'`, 2)
    end

    if self.isConnected then
        self.isConnected = false
        self._disconnect()
    end
end

return Connection
