--!strict

local Automaton = require(script:FindFirstChild("Automaton"))
local Connection = require(script:FindFirstChild("Connection"))
local Exception = require(script:FindFirstChild("Exception"))
local Signal = require(script:FindFirstChild("Signal"))

type AutomatonClass = typeof(Automaton)
export type Automaton = Automaton.Automaton

type ConnectionClass = typeof(Connection)
export type Connection = Connection.Connection

type ExceptionClass = typeof(Exception)
export type Exception = Exception.Exception

type SignalClass = typeof(Signal)
export type Signal = Signal.Signal

type LochsKitLibrary = {
    Automaton: AutomatonClass,
    Connection: ConnectionClass,
    Exception: ExceptionClass,
    Signal: SignalClass,
}

--[ LochsKit Library ]--
local LochsKit: LochsKitLibrary = table.freeze({
    Automaton = Automaton,
    Exception = Exception,
    Signal = Signal,
    Connection = Connection,
})

return LochsKit
