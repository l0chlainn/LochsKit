local availableThread = nil

-- aquire current thread so it's clear it's in use
-- and return the thread when finished
local function aquireThreadAndExecuteHandler(handler, ...)
    local aquiredThread = availableThread
    availableThread = nil
    handler(...)
    availableThread = aquiredThread
end

-- persistant coroutines are faster than making a new one,
-- so we use a loop to keep the thread active and ready to
-- execute again
local function persistantHandlerExecutorThread()
    while true do
        aquireThreadAndExecuteHandler(coroutine.yield())
    end
end

--[[ Connection Class ]]--
local Connection = {}
Connection.__index = Connection

function Connection.new(handler)
    if typeof(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    return setmetatable({
        connected = true,
        handler = handler,
    }, Connection)
end

function Connection:disconnect()
    self.connected = false
end

--[[ Signal Class ]]--
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
    -- execute regular connections
    local regularConnections = self._regularConnections
    local keptIndex = 1
    for loopIndex, connection in regularConnections do
        -- if the connection is connected, execute the handler
        -- else remove from the list
        if connection.connected then
            -- if a previous connection was removed, the index
            -- will mismatch and so we shift the list down
            if loopIndex ~= keptIndex then
                regularConnections[keptIndex] = connection
                regularConnections[loopIndex] = nil
            end
            keptIndex += 1

            if not availableThread then
                availableThread = task.spawn(persistantHandlerExecutorThread)
            end
            task.spawn(availableThread, connection.handler, ...)
        else
            regularConnections[loopIndex] = nil
        end
    end

    -- execute once connections
    local onceConnections = self._onceConnections
    for loopIndex, connection in onceConnections do
        -- if the connection is connected, execute the handler
        -- regardless, remove from the list
        if connection.connected then
            if not availableThread then
                availableThread = task.spawn(persistantHandlerExecutorThread)
            end
            task.spawn(availableThread, connection.handler, ...)
        end
        onceConnections[loopIndex] = nil
    end
end

function Signal:connect(handler)
    if typeof(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    local connection = Connection.new(handler)
    table.insert(self._regularConnections, connection)

    return connection
end

function Signal:once(handler)
    if typeof(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    local connection = Connection.new(handler)
    table.insert(self._onceConnections, connection)

    return connection
end

return Signal
