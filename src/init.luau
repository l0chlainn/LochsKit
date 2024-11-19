--!strict

local Exception = require(script:FindFirstChild("Exception"))
local Signal = require(script:FindFirstChild("Signal"))
local Connection = require(script:FindFirstChild("Connection"))

export type Exception = Exception.Exception
export type Signal = Signal.Signal
export type Connection = Connection.Connection

--[ LochsKit Library ]--
local LochsKit = {
    Exception = Exception,
    Signal = Signal,
    Connection = Connection,
}

return LochsKit
