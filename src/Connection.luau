--!strict

type list = {
	_headConnection: Connection?,
}
type callback = (...any) -> ()

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
	{} :: {
		isConnected: boolean,

		_list: list,
		_callback: callback,

		_nextConnection: Connection?,
		_previousConnection: Connection?,
	},
	Connection
))

local function isConnection(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Connection
end

local function createConnection(list: list, callback: callback): Connection
	local self = setmetatable({
		isConnected = true,

		_list = list,
		_callback = callback,

		_nextConnection = nil,
		_previousConnection = nil,
	}, Connection)

	return self
end

function Connection.disconnect(self: Connection): ()
	if not self.isConnected then
		return
	end
	self.isConnected = false

	local nextConnection = self._nextConnection
	local previousConnection = self._previousConnection
	if nextConnection then
		nextConnection._previousConnection = previousConnection
	end
	if previousConnection then
		previousConnection._nextConnection = nextConnection
	else
		local list = self._list
		list._headConnection = nextConnection
	end
end

table.freeze(Connection)

return table.freeze({
	is = isConnection,
	new = createConnection,
})
