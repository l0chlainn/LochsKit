--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Common = ReplicatedStorage:FindFirstChild("Common")
local Packages = Common:FindFirstChild("Packages")

local LochsKit = require(Packages:FindFirstChild("LochsKit"))

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
	print(`connection is connected: {connection:isConnected()}`)

	event:fire("Hello, World!")
	connection:disconnect()
	event:fire("Goodbye, World!")

	event:connect(function(...)
		print(...)
	end)
	event:connect(function(...)
		print(...)
	end)
	event:fire("Fizz!")
	event:destroy()
	event:fire("Buzz!")

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
	event:fire()
	event:fire()

	print(a, b, c, d)
	print(event)

	for i = 1, 10 do
		event:connect(function()
			print(i)
		end)
	end
	event:fire()
	print(event)
	event:destroy()
	event:fire()

	for i = 1, 10 do
		event:connect(function()
			task.wait()
			print(i)
		end)
	end
	event:fire()
	event:destroy()
	event:fire()
end
