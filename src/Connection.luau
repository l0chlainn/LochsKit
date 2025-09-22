--!strict

type list = {
	_headNode: node?,
}
type node = {
	next: node?,
	previous: node?,
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
	return setmetatable({
		isConnected = true,

		_list = list,
		_node = node,
	}, Connection)
end

function Connection.disconnect(self: Connection): ()
	if self.isConnected then
		self.isConnected = false

		local node = self._node :: node
		local nextNode = node.next
		local previousNode = node.previous
		if nextNode then
			nextNode.previous = previousNode
		end
		if previousNode then
			previousNode.next = nextNode
		else
			local list = self._list :: list
			list._headNode = nextNode
		end

		self._list = nil
		self._node = nil
	end
end

table.freeze(Connection)

return table.freeze({
	is = isConnection,
	new = createConnection,
})
