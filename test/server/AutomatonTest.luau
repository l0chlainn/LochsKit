--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Common = ReplicatedStorage:FindFirstChild("Common")
local Packages = Common:FindFirstChild("Packages")

local LochsKit = require(Packages:FindFirstChild("LochsKit"))

local Automaton = LochsKit.Automaton

return function()
	local colour = "red"
	local machine = Automaton.new(colour, {
		{
			event = "panic",
			toState = "emergency",
			fromStates = { "green", "yellow", "red" },
			condition = function(_, code)
				return code == 123
			end,
		},
		{
			event = "go",
			toState = "green",
			fromStates = { "red" },
		},
		{
			event = "yield",
			toState = "yellow",
			fromStates = { "green" },
		},
		{
			event = "stop",
			toState = "red",
			fromStates = { "yellow" },
		},
	})
	print(`machine is an Automaton: {Automaton.is(machine)}`)

	machine.stateChanging:connect(function(toState)
		colour = toState
		print(`colour changed to {colour}`)
	end)

	machine:changeState("purple")

	print(`initial: {machine:getState()}`)
	machine:fire("go")
	print(`go: {machine:getState()}`)
	machine:fire("yield")
	print(`yield: {machine:getState()}`)
	machine:fire("stop")
	print(`stop: {machine:getState()}`)

	machine:fire("panic", 0)
	print(`panic: {machine:getState()}`)
	machine:fire("panic", 123)
	print(`panic: {machine:getState()}`)

	machine:destroy()
end
