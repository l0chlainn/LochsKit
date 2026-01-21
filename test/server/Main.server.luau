--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local LochsKit = require(Shared.LochsKit)

local Automaton = LochsKit.Automaton
local Signal = LochsKit.Signal

local signal = Signal.new()
signal:fire("test", 1, 2, 3)

signal:connect(function(...)
	print("forever!", ...)
end)
local connection = signal:connect(function(...)
	print("once!", ...)
end)
signal:fire("test", 1, 2, 3)

signal:connect(function(...)
	connection:disconnect()
	print("replace!", ...)
end)
signal:fire("test", 1, 2, 3)

print(signal)
task.wait()
print(signal)

local automaton = Automaton.new("start", {
	{
		name = "start",
		enter = function(): ()
			print("Entering start...")
		end,
		exit = function(): ()
			print("Exiting start...")
		end,
		speak = function(...): ()
			print("Start said:", ...)
		end,
	},
	{
		name = "end",
		enter = function(): ()
			print("Entering end...")
		end,
		exit = function(): ()
			print("Exiting end...")
		end,
		speak = function(...): ()
			print("End said:", ...)
		end,
	},
	{
		name = "trap",
		enter = function(): ()
			print("Entering trap...")
		end,
		exit = function(): ()
			print("Exiting trap...")
		end,
	},
}, {
	{
		trigger = "transition",
		target = "end",
		sources = { "start" },
		condition = function(value: any): boolean
			return type(value) == "number"
		end,
	},
	{
		trigger = "fall",
		target = "trap",
		sources = { "start", "end" },
	},
})

automaton:invoke("speak", "Hello, World!")

automaton:trigger("transition", "text")
print(automaton.state)
automaton:trigger("transition", 123)
print(automaton.state)

automaton:invoke("speak", "Goodbye, World!")
automaton:trigger("fall")
automaton:change("start")
