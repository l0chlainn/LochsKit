--!strict

local LochsKit = script.Parent
local Signal = require(LochsKit:FindFirstChild("Signal"))

type Signal = Signal.Signal

type action = (...any) -> ...any
type condition = () -> ()

type state = {
    name: string,
    actionMap: {[string]: action},
}
type transition = {
    event: string,
    toState: string,
    fromStates: {string},
    condition: condition?,
}

type AutomatonClass = {
    __index: AutomatonClass,

    is: (value: any) -> boolean,
    new: () -> Automaton,

    addState: (
        self: Automaton,
        name: string,
        actionMap: {[string]: action}
    ) -> (),
    addTransition: (
        self: Automaton,
        event: string,
        toState: string,
        fromStates: {string}
    ) -> (),
    changeState: (self: Automaton, name: string) -> (),
    triggerEvent: (self: Automaton, event: string, ...any) -> (),
    executeAction: (self: Automaton, name: string, ...any) -> ...any,
}
export type Automaton = typeof(setmetatable({} :: {
    state: string,
    _stateMap: {[string]: state},
    _eventListenersMap: {[string]: {transition}},

    stateChanged: Signal,
}, {} :: AutomatonClass))

--[ Automaton Class ]--
local Automaton = {} :: AutomatonClass
Automaton.__index = Automaton

function Automaton.new(): Automaton
    return setmetatable({
        state = "",
        _stateMap = {},
        _eventListenersMap = {},

        stateChanged = Signal.new(),
    }, Automaton)
end

function Automaton.addState(
    self: Automaton,
    name: string,
    actionMap: {[string]: action}
): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(name) ~= "string" then
        error(`expected string for self, got '{typeof(name)}'`, 2)
    elseif type(actionMap) ~= "table" then
        error(`expected table for self, got '{typeof(actionMap)}'`, 2)
    end

    for key, action in actionMap do
        if type(key) ~= "string" then
            error(`expected string for actionMap key, got '{typeof(key)}'`, 2)
        elseif type(action) ~= "function" then
            error(`expected function for actionMap[{key}], got '{typeof(action)}'`, 2)
        end
    end

    self._stateMap[name] = {
        name = name,
        actionMap = actionMap,
    }
end

function Automaton.addTransition(
    self: Automaton,
    event: string,
    toState: string,
    fromStates: {string}
): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(event) ~= "string" then
        error(`expected string for event, got '{typeof(event)}'`, 2)
    elseif type(toState) ~= "string" then
        error(`expected string for toState, got '{typeof(toState)}'`, 2)
    elseif type(fromStates) ~= "table" then
        error(`expected table for fromStates, got '{typeof(fromStates)}'`, 2)
    end

    for index, fromState in fromStates do
        if type(index) ~= "number" then
            error(`expected number for index in fromStates, got '{typeof(index)}'`, 2)
        elseif type(fromState) ~= "string" then
            error(`expected string for fromStates[{index}], got '{typeof(fromState)}'`, 2)
        end
    end

    local transition = {
        event = event,
        toState = toState,
        fromStates = fromStates,
    }
    local eventListenersMap = self._eventListenersMap
    local eventListeners = eventListenersMap[event]
    if eventListeners then
        table.insert(eventListeners, transition)
    else
        eventListenersMap[event] = {transition}
    end
end

function Automaton.changeState(self: Automaton, name: string): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(name) ~= "string" then
        error(`expected string for name, got '{typeof(name)}'`, 2)
    end

    local oldState = self._stateMap[self.state]
    local newState = self._stateMap[name]
    if not newState then
        error(`name '{name}', does not map to a State!`, 2)
    end

    local exitAction = oldState.actionMap["exit"]
    if exitAction then
        exitAction()
    end
    local enterAction = newState.actionMap["enter"]
    if enterAction then
        enterAction()
    end

    self.state = newState.name
    self.stateChanged:trigger(oldState.name, newState.name)
end

function Automaton.triggerEvent(self: Automaton, event: string, ...: any): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(event) ~= "string" then
        error(`expected string for event, got '{typeof(event)}'`, 2)
    end

    local eventListeners = self._eventListenersMap[event]
    if eventListeners then
        local state = self.state
        for _, transition in eventListeners do
            local toState = transition.toState
            local condition = transition.condition
            if
                self._stateMap[toState]
                and table.find(transition.fromStates, state)
                and (not condition or condition(...))
            then
                self:changeState(toState)
                break
            end
        end
    end
end

function Automaton.executeAction(self: Automaton, name: string, ...: any): ...any
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(name) ~= "string" then
        error(`expected string for name, got '{typeof(name)}'`, 2)
    end

    local currentState = self._stateMap[self.state]
    local action = currentState.actionMap[name]
    if action then
        return action(...)
    end
end

return Automaton
