--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local LochsKit = require(Packages.LochsKit)

local Connection = LochsKit.Connection
local Signal = LochsKit.Signal

type Connection = LochsKit.Connection
type Signal = LochsKit.Signal

return function()
	local event = Signal.new()
	print(`event is a Signal: {Signal.is(event)}`)

	local connection = event:connect(function(...)
		print(...)
	end)
	print(`connection is a Connection: {Connection.is(connection)}`)
	print(`connection is connected: {connection.isConnected}`)

	event:send("Hello, World!")
	connection:disconnect()
	event:send("Goodbye, World!")

	event:connect(function(...)
		print(...)
	end)
	event:connect(function(...)
		print(...)
	end)
	event:send("Fizz!")
	event:destroy()
	event:send("Buzz!")

	local a, b, c, d
	d = event:connect(function()
		print("D")
	end)
	c = event:connect(function()
		print("C")
		b:disconnect()
		c:disconnect()
		d:disconnect()
	end)
	b = event:connect(function()
		print("B")
	end)
	a = event:connect(function()
		print("A")
		a:disconnect()
	end)
	event:send()
	event:send()

	print(a, b, c, d)
	print(event)

	for i = 1, 10 do
		event:connect(function()
			print(i)
		end)
	end
	event:send()
	print(event)
	event:destroy()
	event:send()

	for i = 1, 10 do
		event:connect(function()
			task.wait()
			print(i)
		end)
	end
	event:send()
	event:destroy()
	event:send()
end
