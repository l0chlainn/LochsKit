--!strict

type list = {
	_headNode: node?,
}
type node = {
	nextNode: node?,
	previousNode: node?,
}

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
	{} :: {
		isConnected: boolean,

		_list: list?,
		_node: node?,
	},
	Connection
))

local function isConnection(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Connection
end

local function createConnection(list: list, node: node): Connection
	if type(list) ~= "table" then
		error(`Invalid argument #1. (table expected, got {typeof(list)})`, 2)
	elseif type(node) ~= "table" then
		error(`Invalid argument #2. (table expected, got {typeof(node)})`, 2)
	end

	return setmetatable({
		isConnected = true,

		_list = list,
		_node = node,
	}, Connection)
end

function Connection.disconnect(self: Connection): ()
	if not isConnection(self) then
		error(`Invalid argument #1. (Connection expected, got {typeof(self)})`, 2)
	end

	if self.isConnected then
		self.isConnected = false

		local node = self._node :: node
		local nextNode = node.nextNode
		local previousNode = node.previousNode
		if nextNode then
			nextNode.previousNode = previousNode
		end
		if previousNode then
			previousNode.nextNode = nextNode
		else
			local list = self._list :: list
			list._headNode = nextNode
		end

		self._list = nil
		self._node = nil
	end
end

return table.freeze({
	is = isConnection,
	new = createConnection,
})
