--!strict

local Automaton = require(script:FindFirstChild("Automaton"))
local Exception = require(script:FindFirstChild("Exception"))
local Relay = require(script:FindFirstChild("Relay"))
local Signal = require(script:FindFirstChild("Signal"))
local Connection = require(script:FindFirstChild("Connection"))

export type Automaton = Automaton.Automaton
export type Exception = Exception.Exception
export type Relay = Relay.Relay
export type Signal = Signal.Signal
export type Connection = Connection.Connection

--[ LochsKit Library ]--
local LochsKit = {
    Automaton = Automaton,
    Exception = Exception,
    Relay = Relay,
    Signal = Signal,
    Connection = Connection,
}

return LochsKit
