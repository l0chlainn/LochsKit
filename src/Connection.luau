--!strict

type Signal = {
	_headConnection: Connection?,
}

type callback = (...any) -> ()

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
	{} :: {
		isConnected: boolean,

		_signal: Signal?,
		_callback: callback?,

		_nextConnection: Connection?,
		_previousConnection: Connection?,
	},
	Connection
))

local function isConnection(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Connection
end

local function createConnection(signal: Signal, callback: callback): Connection
	local self = setmetatable({
		isConnected = true,

		_signal = signal,
		_callback = callback,

		_nextConnection = nil,
		_previousConnection = nil,
	}, Connection)

	return self
end

function Connection.disconnect(self: Connection): ()
	if self.isConnected then
		self.isConnected = false

		local nextConnection = self._nextConnection
		local previousConnection = self._previousConnection
		if nextConnection then
			nextConnection._previousConnection = previousConnection
		end
		if previousConnection then
			previousConnection._nextConnection = nextConnection
		else
			local signal = self._signal :: Signal
			signal._headConnection = nextConnection
		end

		self._signal = nil
		self._callback = nil

		self._nextConnection = nil
		self._previousConnection = nil
	end
end

table.freeze(Connection)

return table.freeze({
	is = isConnection,
	new = createConnection,
})
