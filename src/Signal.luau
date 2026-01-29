--!strict

local LochsKit = script.Parent
local Connection = require(LochsKit.Connection)

type Connection = Connection.Connection

type callback = (...any) -> ()

-- Cache a caller to avoid thread creation overhead.
local idleCaller: thread? = nil

local function call(callback: callback, ...: any): ()
	local busyCaller = idleCaller :: thread
	idleCaller = nil
	callback(...)
	idleCaller = busyCaller
end

local function caller(): ()
	while true do
		call(coroutine.yield())
	end
end

local function spawner(connection: Connection?, ...: any): ()
	-- It's possible for a disconnect to occur in a thread, destroying our navigation.
	-- By cacheing our connections first, we avoid this navigation issue.
	local connections = {}
	while connection do
		table.insert(connections, connection)
		connection = connection._nextConnection
	end

	for _, conn in connections do
		if conn.isConnected then
			if not idleCaller then
				idleCaller = task.spawn(caller)
			end
			task.spawn(idleCaller :: thread, conn._callback, ...)
		end
	end
end

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable(
	{} :: {
		_headConnection: Connection?,
	},
	Signal
))

local function isSignal(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Signal
end

local function createSignal(): Signal
	local self = setmetatable({
		_headConnection = nil,
	}, Signal)

	return self
end

function Signal.destroy(self: Signal): ()
	self:disconnectAll()
end

function Signal.connect(self: Signal, callback: callback): Connection
	local newConnection = Connection.new(self :: any, callback)
	local headConnection = self._headConnection
	if headConnection then
		newConnection._nextConnection = headConnection
		headConnection._previousConnection = newConnection
	end
	self._headConnection = newConnection

	return newConnection
end

function Signal.disconnectAll(self: Signal): ()
	local connection = self._headConnection
	while connection do
		connection.isConnected = false

		connection._signal = nil
		connection._callback = nil

		local nextConnection = connection._nextConnection
		connection._nextConnection = nil
		connection._previousConnection = nil

		connection = nextConnection
	end
	self._headConnection = nil
end

function Signal.fire(self: Signal, ...: any): ()
	local connection = self._headConnection
	if connection then
		task.defer(spawner, connection, ...)
	end
end

table.freeze(Signal)

return table.freeze({
	is = isSignal,
	new = createSignal,
})
