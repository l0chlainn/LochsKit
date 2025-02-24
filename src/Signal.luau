--!strict

local LochsKit = script.Parent
local Connection = require(LochsKit:FindFirstChild("Connection"))

type Connection = Connection.Connection

type callback = (...any) -> ()

type SignalClass = {
    __index: SignalClass,

    is: (value: any) -> boolean,
    new: () -> Signal,

    _link: (self: Signal, connection: Connection) -> (),
    _unlink: (self: Signal, connection: Connection) -> (),

    trigger: (self: Signal, ...any) -> (),
    connect: (self: Signal, callback: callback) -> Connection,
    disconnectAll: (self: Signal) -> (),
}
export type Signal = typeof(setmetatable({} :: {
    _headConnection: Connection?,
}, {} :: SignalClass))

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

--[ Signal Class ]--
local Signal = {} :: SignalClass
Signal.__index = Signal

function Signal.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Signal
end

function Signal.new(): Signal
    return setmetatable({
        _headConnection = nil,
    }, Signal)
end

function Signal._link(self: Signal, connection: Connection): ()
    local headConnection = self._headConnection
    if headConnection then
        connection._nextConnection = headConnection
        headConnection._previousConnection = connection
    end
    self._headConnection = connection
end

function Signal._unlink(self: Signal, connection: Connection): ()
    local nextConnection = connection._nextConnection
    local previousConnection = connection._previousConnection
    if nextConnection then
        nextConnection._previousConnection = previousConnection
    end
    if previousConnection then
        previousConnection._nextConnection = nextConnection
    else
        self._headConnection = nextConnection
    end
end

function Signal.trigger(self: Signal, ...: any): ()
    if not Signal.is(self) then
        error(`expected Signal for self, got '{typeof(self)}'`, 2)
    end

    local connection = self._headConnection
    while connection do
        if not idleRunnerThread then
            idleRunnerThread = task.spawn(persistentRunnerThread)
        end
        task.spawn(
            idleRunnerThread :: thread,
            connection._connectionCallback,
            ...
        )
        connection = connection._nextConnection
    end
end

function Signal.connect(self: Signal, callback: callback): Connection
    if not Signal.is(self) then
        error(`expected Signal for self, got '{typeof(self)}'`, 2)
    elseif type(callback) ~= "function" then
        error(`expected function for callback, got '{typeof(callback)}'`, 2)
    end

    local connection
    connection = Connection.new(callback, function()
        self:_unlink(connection)
    end)
    self:_link(connection)

    return connection
end

function Signal.disconnectAll(self: Signal): ()
    if not Signal.is(self) then
        error(`expected Signal for self, got '{typeof(self)}'`, 2)
    end

    local connection = self._headConnection
    while connection do
        connection:disconnect()
        connection = connection._nextConnection
    end
    self._headConnection = nil
end

return table.freeze(Signal)
