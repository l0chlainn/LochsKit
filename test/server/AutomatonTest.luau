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
            fromStates = {"green", "yellow", "red",},
            condition = function(_, code)
                return code == 123
            end,
        },
        {
            event = "go",
            toState = "green",
            fromStates = {"red",},
        },
        {
            event = "yield",
            toState = "yellow",
            fromStates = {"green",},
        },
        {
            event = "stop",
            toState = "red",
            fromStates = {"yellow",},
        },
    })
    print(`machine is an Automaton: {Automaton.is(machine)}`)

    machine.stateChanging:connect(function(toState)
        colour = toState
        print(`colour changed to {colour}`)
    end)

    machine:change("purple")

    print(`initial: {machine.state}`)
    machine:fire("go")
    print(`go: {machine.state}`)
    machine:fire("yield")
    print(`yield: {machine.state}`)
    machine:fire("stop")
    print(`stop: {machine.state}`)

    machine:fire("panic", 0)
    print(`panic: {machine.state}`)
    machine:fire("panic", 123)
    print(`panic: {machine.state}`)

    machine:destroy()
end
