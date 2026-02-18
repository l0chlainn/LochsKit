--!strict

local LochsKit = script.Parent
local Connection = require(LochsKit.Connection)

type Connection = Connection.Connection

type callback = (...any) -> ()

-- Cache a caller to avoid thread creation overhead.
local idleCaller = nil :: thread?

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
	while connection do
		if connection.isConnected then
			if not idleCaller then
				idleCaller = task.spawn(caller)
			end
			task.spawn(idleCaller :: thread, connection._callback, ...)
		end
		connection = connection._nextConnection
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

function Signal.disconnect(self: Signal): ()
	local currentConnection = self._headConnection
	while currentConnection do
		currentConnection.isConnected = false

		local nextConnection = currentConnection._nextConnection
		currentConnection._nextConnection = nil
		currentConnection._previousConnection = nil

		currentConnection = nextConnection
	end
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

function Signal.fire(self: Signal, ...: any): ()
	local headConnection = self._headConnection
	if headConnection then
		task.defer(spawner, headConnection, ...)
	end
end

table.freeze(Signal)

return table.freeze({
	is = isSignal,
	new = createSignal,
})
