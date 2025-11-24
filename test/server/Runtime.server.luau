--!strict

-- TODO:
-- Very badly need to redo this entire test code.

local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService.Server

local AutomatonTest = require(Server.AutomatonTest)
local SignalTest = require(Server.AutomatonTest)

AutomatonTest()
SignalTest()
