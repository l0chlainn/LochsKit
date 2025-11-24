--!strict

local LochsKit = script
local Automaton = require(LochsKit.Automaton)
local Connection = require(LochsKit.Connection)
local Signal = require(LochsKit.Signal)

export type Automaton = Automaton.Automaton
export type Connection = Connection.Connection
export type Signal = Signal.Signal

return table.freeze({
	Automaton = Automaton,
	Connection = Connection,
	Signal = Signal,
})
