--!strict

local Connection = require(script.Parent:FindFirstChild("Connection"))

type Connection = Connection.Connection

type callback = (...any) -> ()
type node = {
	nextNode: node?,
	previousNode: node?,
	callback: callback,
	connection: Connection,
}

-- Cache a runner thread here to avoid overhead of thread creation.
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

export type Signal = typeof(setmetatable(
	{} :: {
		_headNode: node?,
	},
	Signal
))

local function isSignal(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Signal
end

local function createSignal(): Signal
	return setmetatable({
		_headNode = nil,
	}, Signal)
end

function Signal.destroy(self: Signal): ()
	if not isSignal(self) then
		error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
	end

	local node = self._headNode
	while node do
		node.connection:disconnect()
		node = node.nextNode
	end
	self._headNode = nil
end

function Signal.connect(self: Signal, callback: callback): Connection
	if not isSignal(self) then
		error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
	elseif type(callback) ~= "function" then
		error(`Invalid argument #2. (function expected, got {typeof(callback)})`, 2)
	end

	local node = {
		nextNode = nil,
		previousNode = nil,
		callback = callback,
		connection = nil :: any,
	} :: node

	local headNode = self._headNode
	if headNode then
		node.nextNode = headNode
		headNode.previousNode = node
	end
	self._headNode = node

	local connection = Connection.new(self :: any, node)
	node.connection = connection

	return connection
end

function Signal.send(self: Signal, ...: any): ()
	if not isSignal(self) then
		error(`Invalid argument #1. (Signal expected, got {typeof(self)})`, 2)
	end

	local node = self._headNode
	while node do
		if node.connection.isConnected then
			if not idleRunner then
				idleRunner = task.spawn(runner)
			end
			task.spawn(idleRunner :: thread, node.callback, ...)
		end
		node = node.nextNode
	end
end

return table.freeze({
	is = isSignal,
	new = createSignal,
})
