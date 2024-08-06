local idleThread = nil

-- we use a seperate function here to make unpacking
-- the results of coroutine.yield a little easier
-- and we take control of the idle thread so that
-- it's clear that it's currently in use.
local function aquireIdleThreadAndRunHandler(handler, ...)
    local runningThread = idleThread
    runningThread = nil
    handler(...)
    idleThread = runningThread
end

-- persistant coroutines are faster than making a new one,
-- so we use a loop to keep the thread active and available.
local function idleThreadLoop()
    while true do
        aquireIdleThreadAndRunHandler(coroutine.yield())
    end
end

-- run the handler in a seperate thread so we can handle
-- yielding in the handler.
local function runHandlerInSeperateThread(handler, ...)
    if not idleThread then
        idleThread = task.spawn(idleThreadLoop)
    end
    task.spawn(idleThread, handler, ...)
end

--[ Connection Class ]--
local Connection = {}
Connection.__index = Connection

function Connection.new(handler)
    return setmetatable({
        connected = true,
        handler = handler,
    }, Connection)
end

function Connection:disconnect()
    self.connected = false
end

--[ Signal Class ]--
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _regularConnections = {},
        _onceConnections = {},
    }, Signal)
end

function Signal:destroy()
    table.clear(self._regularConnections)
    table.clear(self._onceConnections)
end

function Signal:fire(...)
    local regularConnections = self._regularConnections
    local keptIndex = 1
    for loopIndex, connection in regularConnections do
        if connection.connected then
            -- if a previous connection was removed, the index
            -- will mismatch and so we shift the list down
            if loopIndex ~= keptIndex then
                regularConnections[keptIndex] = connection
                regularConnections[loopIndex] = nil
            end
            keptIndex += 1

            runHandlerInSeperateThread(connection.handler, ...)
        else
            regularConnections[loopIndex] = nil
        end
    end

    local onceConnections = self._onceConnections
    for index, connection in onceConnections do
        if connection.connected then
            runHandlerInSeperateThread(connection.handler, ...)
        end
        onceConnections[index] = nil
    end
end

function Signal:connect(handler)
    if type(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    local connection = Connection.new(handler)
    table.insert(self._regularConnections, connection)

    return connection
end

function Signal:once(handler)
    if type(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    local connection = Connection.new(handler)
    table.insert(self._onceConnections, connection)

    return connection
end

return Signal
