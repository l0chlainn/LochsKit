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
    new: (
        initial: string,
        states: {state},
        transitions: {transition}
    ) -> Automaton,

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

function Automaton.new(
    initial: string,
    states: {state},
    transitions: {transition}
): Automaton
    if type(initial) ~= "string" then
        error(`expected string for initial, got '{typeof(initial)}'`, 2)
    elseif type(states) ~= "table" then
        error(`expected table for states, got '{typeof(states)}'`, 2)
    elseif type(transitions) ~= "table" then
        error(`expected table for transitions, got '{typeof(transitions)}'`, 2)
    end

    local stateMap = {}
    for i, state in ipairs(states) do
        if type(state) ~= "table" then
            error(`expected table for states[{i}], got '{typeof(state)}'`, 2)
        end

        local name = state.name
        local actionMap = state.actionMap
        if type(name) ~= "string" then
            error(`expected string for states[{i}].name, got '{typeof(name)}'`, 2)
        elseif type(actionMap) ~= "table" then
            error(`expected table for states[{i}].actionMap, got '{typeof(actionMap)}'`, 2)
        end

        for j, action in pairs(actionMap) do
            if type(j) ~= "string" then
                error(`expected string for states[{i}].actionMap key, got '{typeof(j)}'`, 2)
            elseif type(action) ~= "function" then
                error(`expected function for states[{i}].actionMap[{j}], got '{typeof(action)}'`, 2)
            end
        end

        stateMap[name] = state
    end

    local eventListenersMap = {}
    for i, transition in ipairs(transitions) do
        if type(transition) ~= "table" then
            error(`expected table for transitions[{i}], got '{typeof(transition)}'`, 2)
        end

        local event = transition.event
        local toState = transition.toState
        local fromStates = transition.fromStates
        local condition = transition.condition
        if type(event) ~= "string" then
            error(`expected string for transitions[{i}].event, got '{typeof(event)}'`, 2)
        elseif type(toState) ~= "string" then
            error(`expected string for transitions[{i}].toState, got '{typeof(toState)}'`, 2)
        elseif type(fromStates) ~= "table" then
            error(`expected table for transitions[{i}].fromStates, got '{typeof(fromStates)}'`, 2)
        elseif condition ~= nil and type(condition) ~= "function" then
            error(`expected function for transitions[{i}].condition, got '{typeof(condition)}'`, 2)
        end

        for j, fromState in ipairs(fromStates) do
            if type(fromState) ~= "string" then
                error(`expected string for transitions[{i}].fromStates[{j}], got '{typeof(fromState)}'`, 2)
            end
        end

        local eventListeners = eventListenersMap[event]
        if eventListeners then
            table.insert(eventListeners, transition)
        else
            eventListenersMap[event] = {transition}
        end
    end

    if not stateMap[initial] then
        error(`initial '{initial}' does map to a state!`)
    end

    return setmetatable({
        state = initial,
        _stateMap = stateMap,
        _eventListenersMap = eventListenersMap,

        stateChanged = Signal.new(),
    }, Automaton)
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
