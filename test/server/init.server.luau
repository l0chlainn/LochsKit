--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local LochsKit = require(Packages:FindFirstChild("LochsKit"))

local Automaton = LochsKit.Automaton

local machine = Automaton.new(
    "red",
    {
        {
            name = "red",
            actionMap = {
                enter = function()
                    print("The light is now RED. Stop!")
                end,
                exit = function()
                    print("The RED light is turning off.")
                end,
            },
        },
        {
            name = "yellow",
            actionMap = {
                enter = function()
                    print("The light is now YELLOW. Slow down!")
                end,
                exit = function()
                    print("The YELLOW light is turning off.")
                end,
            },
        },
        {
            name = "green",
            actionMap = {
                enter = function()
                    print("The light is now GREEN. Go!")
                end,
                exit = function()
                    print("The GREEN light is turning off.")
                end,
            },
        },
    },
    {
        {
            event = "yield",
            toState = "yellow",
            fromStates = {
                "green",
            },
            condition = function(a)
                return a == 3
            end
        },
        {
            event = "go",
            toState = "green",
            fromStates = {
                "red",
            },
        },
        {
            event = "stop",
            toState = "red",
            fromStates = {
                "yellow",
            },
        },
    }
)

for index, event in ipairs({
    "go",
    "yield",
    "yield",
    "stop",
}) do
    print(`triggering event '{event}'...`)
    machine:trigger(event, index)
end
