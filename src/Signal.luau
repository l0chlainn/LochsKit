--!strict

local Connection = require(script.Parent:FindFirstChild("Connection"))

type Connection = Connection.Connection

type callback = (...any) -> ()

-- Cache a runner thread here to avoid overhead of thread creation.
-- It might be improved with a thread pool as it would logically follow
-- that if a thread yields the first call it's going to yield the next call.
local idleRunner: thread? = nil

local function runCallback(callback: callback, ...: any): ()
    local busyRunner = idleRunner :: thread
    idleRunner = nil
    callback(...)
    idleRunner = busyRunner
end

-- Runner thread keeps the thread from dying, allowing us to reuse it.
local function runner(): ()
    while true do
        runCallback(coroutine.yield())
    end
end

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: {
    isFiring: boolean,
    _headConnection: Connection?,
    _disconnections: {Connection},
}, Signal))

local function isSignal(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Signal
end

local function createSignal(): Signal
    return setmetatable({
        isFiring = false,
        _headConnection = nil,
        _disconnections = {},
    }, Signal)
end

function Signal.fire(self: Signal, ...: any): ()
    if not isSignal(self) then
        error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
    end

    self.isFiring = true

    local connection = self._headConnection
    while connection do
        if connection.isConnected then
            if not idleRunner then
                idleRunner = task.spawn(runner)
            end
            task.spawn(
                idleRunner :: thread,
                connection._callback :: callback,
                ...
            )
        end
        connection = connection._next
    end

    -- Disconnection attempts made while firing are safe to remove now.
    for _, disconnection in self._disconnections do
        disconnection._next = nil
        disconnection._previous = nil
    end
    table.clear(self._disconnections)

    self.isFiring = false
end

function Signal._disconnect(self: Signal, connection: Connection): ()
    if not isSignal(self) then
        error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
    elseif not Connection.is(connection) then
        error(`Invalid argument #2. (Connection expected, got {typeof(connection)})`, 2)
    end

    local nextConnection = connection._next
    local previousConnection = connection._previous
    if nextConnection then
        nextConnection._previous = previousConnection
    end
    if previousConnection then
        previousConnection._next = nextConnection
    else
        self._headConnection = nextConnection
    end

    -- We can't unlink a list while it's being used as it creates
    -- navigation issues. Instead queue it to be removed after the list is done.
    if self.isFiring then
        table.insert(self._disconnections, connection)
    else
        connection._next = nil
        connection._previous = nil
    end
end

function Signal.connect(self: Signal, callback: callback): Connection
    if not isSignal(self) then
        error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
    elseif type(callback) ~= "function" then
        error(`Invalid argument #2. (function expected, got {typeof(callback)})`, 2)
    end

    local connection
    connection = Connection.new(callback, function()
        self:_disconnect(connection)
    end)

    local headConnection = self._headConnection
    if headConnection then
        connection._next = headConnection
        headConnection._previous = connection
    end
    self._headConnection = connection

    return connection
end

function Signal.disconnectAll(self: Signal): ()
    if not isSignal(self) then
        error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
    end

    local isFiring = self.isFiring
    local disconnections = self._disconnections
    local connection = self._headConnection
    while connection do
        if connection.isConnected then
            connection.isConnected = false

            -- Clear these references, otherwise we may experience a memory leak.
            connection._callback = nil
            connection._disconnect = nil

            -- We can't unlink a list while it's being used as it creates
            -- navigation issues. Instead queue it to be removed after the list is done.
            if isFiring then
                table.insert(disconnections, connection)
            else
                connection._next = nil
                connection._previous = nil
            end
        end
        connection = connection._next
    end
    self._headConnection = nil
end

return table.freeze({
    is = isSignal,
    new = createSignal,
})
