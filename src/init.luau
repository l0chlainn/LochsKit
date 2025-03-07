--!strict

local Automaton = require(script:FindFirstChild("Automaton"))
local Connection = require(script:FindFirstChild("Connection"))
local Signal = require(script:FindFirstChild("Signal"))

export type Automaton = Automaton.Automaton
export type Connection = Connection.Connection
export type Signal = Signal.Signal

return table.freeze({
    Automaton = Automaton,
    Connection = Connection,
    Signal = Signal,
})
