--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local LochsKit = require(Packages.LochsKit)

local Automaton = LochsKit.Automaton

return function()
	local colour = "red"
	local machine = Automaton.new(colour, {
		{
			name = "green",
			enter = function()
				colour = "green"
			end,
		},
		{
			name = "yellow",
			enter = function()
				colour = "yellow"
			end,
		},
		{
			name = "red",
			enter = function()
				colour = "red"
			end,
		},
		{
			name = "emergency",
			enter = function()
				colour = "emergency"
			end,
			say = function(...)
				print(...)
			end,
		},
	}, {
		{
			event = "go",
			to = "green",
			from = { "red" },
		},
		{
			event = "yield",
			to = "yellow",
			from = { "green" },
		},
		{
			event = "stop",
			to = "red",
			from = { "yellow" },
		},
		{
			event = "panic",
			to = "emergency",
			from = { "green", "yellow", "red" },
			condition = function(_, _, _, code)
				return code == 123
			end,
		},
	})

	machine.stateChanged:connect(function(to)
		print(`colour changed to {to}, colour is {colour}`)
	end)

	print(`initial: {machine.state}`)
	machine:send("go")
	print(`go: {machine.state}`)
	machine:send("yield")
	print(`yield: {machine.state}`)
	machine:send("stop")
	print(`stop: {machine.state}`)

	machine:send("panic", 0)
	print(`panic: {machine.state}`)
	machine:send("panic", 123)
	print(`panic: {machine.state}`)

	machine:execute("say", "Hello, Panicked World!")

	machine:destroy()
end
