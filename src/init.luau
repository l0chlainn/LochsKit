--!strict

local Exception = require(script:FindFirstChild("Exception"))
local Signal = require(script:FindFirstChild("Signal"))
local Connection = require(script:FindFirstChild("Connection"))

type ExceptionClass = typeof(Exception)
export type Exception = Exception.Exception

type SignalClass = typeof(Signal)
export type Signal = Signal.Signal

type ConnectionClass = typeof(Connection)
export type Connection = Connection.Connection

type LochsKitLibrary = {
    Exception: ExceptionClass,
    Signal: SignalClass,
    Connection: ConnectionClass,
}

--[ LochsKit Library ]--
local LochsKit: LochsKitLibrary = {
    Exception = Exception,
    Signal = Signal,
    Connection = Connection,
}

return LochsKit
