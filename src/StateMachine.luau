local LochsKit = script.Parent
local CustomEnum = require(LochsKit.CustomEnum)
local Exception = require(LochsKit.Exception)

local Exceptions = CustomEnum.new({
    UNDEFINED_TRANSITION = 0,
    INVALID_TRANSITION = 1,
    UNDEFINED_SOURCE_STATE = 2,
    UNDEFINED_DESTINATION_STATE = 3,
})

--[[ StateMachine Class ]]--
local StateMachine = {}
StateMachine.__index = StateMachine

StateMachine.Exceptions = Exceptions

function StateMachine.new()
    -- construct an instance of StateMachine
    local self = {
        currentState = "initial",
        _states = {},
        _transitions = {},
    }
    setmetatable(self, StateMachine)

    return self
end

function StateMachine:addState(name, enterHandler, exitHandler)
    if typeof(name) ~= "string" then
        error("name must be a string!", 2)
    elseif typeof(enterHandler) ~= "function" then
        error("enterHandler must be a function!", 2)
    elseif typeof(exitHandler) ~= "function" then
        error("exitHandler must be a function!", 2)
    end

    self._states[name] = {
        enter = enterHandler,
        exit = exitHandler,
    }
end

function StateMachine:addTransition(name, toState, fromStates)
    if typeof(name) ~= "string" then
        error("name must be a string!", 2)
    elseif typeof(toState) ~= "string" then
        error("toState must be a string!", 2)
    elseif typeof(fromStates) ~= "table" then
        error("fromStates must be a table!", 2)
    end

    self._transitions[name] = {
        toState = toState,
        fromStates = fromStates,
    }
end

function StateMachine:canTriggerTransition(name)
    if typeof(name) ~= "string" then
        error("name must be a string!", 2)
    end

    local transition = self._transition[name]
    if transition and table.find(transition.fromStates, self.currentState) then
        return true
    else
        return false
    end
end

function StateMachine:triggerTransition(name)
    if typeof(name) ~= "string" then
        error("name must be a string!", 2)
    end

    local transition = self._transition[name]
    if not transition then
        return false, Exception.new(
            Exceptions.UNDEFINED_TRANSITION,
            `transition does not exist!`
        )
    elseif not table.find(transition.fromStates, self.currentState) then
        return false, Exception.new(
            Exceptions.INVALID_TRANSITION,
            "unable to transition from current state!"
        )
    end

    local currentState = self._states[self.currentState]
    local nextState = self._states[transition.toState]
    if not currentState and self.currentState ~= "initial" then
        return false, Exception.new(
            Exceptions.UNDEFINED_SOURCE_STATE,
            "current state is not a valid state!"
        )
    elseif not nextState then
        return false, Exception.new(
            Exceptions.UNDEFINED_DESTINATION_STATE,
            "destination state is not a valid state!"
        )
    end

    currentState.exit()
    nextState.enter()

    self.currentState = transition.toState

    return true
end

return StateMachine
