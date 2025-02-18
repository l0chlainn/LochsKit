--!strict

local LochsKit = script.Parent
local Signal = require(LochsKit:FindFirstChild("Signal"))

type Signal = Signal.Signal

type action = (...any) -> ...any
type condition = (fromState: string, ...any) -> boolean
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

    change: (self: Automaton, name: string) -> (),
    trigger: (self: Automaton, event: string, ...any) -> (),
    execute: (self: Automaton, name: string, ...any) -> ...any,
}
export type Automaton = typeof(setmetatable({} :: {
    state: string,
    _stateMap: {[string]: state},
    _listenersMap: {[string]: {transition}},

    stateChanged: Signal,
}, {} :: AutomatonClass))

--[ Automaton Class ]--
local Automaton = {} :: AutomatonClass
Automaton.__index = Automaton

function Automaton.is(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Automaton
end

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
    for stateIndex, state in ipairs(states) do
        if type(state) ~= "table" then
            error(`expected table for states[{stateIndex}], got '{typeof(state)}'`, 2)
        end

        local name = state.name
        local actionMap = state.actionMap
        if type(name) ~= "string" then
            error(`expected string for states[{stateIndex}].name, got '{typeof(name)}'`, 2)
        elseif type(actionMap) ~= "table" then
            error(`expected table for states[{stateIndex}].actionMap, got '{typeof(actionMap)}'`, 2)
        end

        for actionKey, action in pairs(actionMap) do
            if type(actionKey) ~= "string" then
                error(`expected string for states[{stateIndex}].actionMap key, got '{typeof(actionKey)}'`, 2)
            elseif type(action) ~= "function" then
                error(`expected function for states[{stateIndex}].actionMap[{actionKey}], got '{typeof(action)}'`, 2)
            end
        end

        stateMap[name] = state
    end

    local listenersMap = {}
    for transitionIndex, transition in ipairs(transitions) do
        if type(transition) ~= "table" then
            error(`expected table for transitions[{transitionIndex}], got '{typeof(transition)}'`, 2)
        end

        local event = transition.event
        local toState = transition.toState
        local fromStates = transition.fromStates
        local condition = transition.condition
        if type(event) ~= "string" then
            error(`expected string for transitions[{transitionIndex}].event, got '{typeof(event)}'`, 2)
        elseif type(toState) ~= "string" then
            error(`expected string for transitions[{transitionIndex}].toState, got '{typeof(toState)}'`, 2)
        elseif type(fromStates) ~= "table" then
            error(`expected table for transitions[{transitionIndex}].fromStates, got '{typeof(fromStates)}'`, 2)
        elseif condition ~= nil and type(condition) ~= "function" then
            error(`expected function for transitions[{transitionIndex}].condition, got '{typeof(condition)}'`, 2)
        end

        for fromStateIndex, fromState in ipairs(fromStates) do
            if type(fromState) ~= "string" then
                error(`expected string for transitions[{transitionIndex}].fromStates[{fromStateIndex}], got '{typeof(fromState)}'`, 2)
            end
        end

        local listeners = listenersMap[event]
        if listeners then
            table.insert(listeners, transition)
        else
            listenersMap[event] = {transition}
        end
    end

    if not stateMap[initial] then
        error(`initial '{initial}' does not map to a valid state!`)
    end

    return setmetatable({
        state = initial,
        _stateMap = stateMap,
        _listenersMap = listenersMap,

        stateChanged = Signal.new(),
    }, Automaton)
end

function Automaton.change(self: Automaton, name: string): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(name) ~= "string" then
        error(`expected string for name, got '{typeof(name)}'`, 2)
    end

    local oldState = self._stateMap[self.state]
    local newState = self._stateMap[name]
    if not newState then
        error(`name '{name}', does not map to a valid state!`, 2)
    end

    local exit = oldState.actionMap["exit"]
    if exit then
        exit()
    end
    local enter = newState.actionMap["enter"]
    if enter then
        enter()
    end

    self.state = newState.name
    self.stateChanged:trigger(oldState.name, newState.name)
end

function Automaton.trigger(self: Automaton, event: string, ...: any): ()
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(event) ~= "string" then
        error(`expected string for event, got '{typeof(event)}'`, 2)
    end

    local listeners = self._listenersMap[event]
    if listeners then
        local fromState = self.state
        for _, transition in listeners do
            local toState = transition.toState
            local condition = transition.condition
            if
                self._stateMap[toState]
                and table.find(transition.fromStates, fromState)
                and (not condition or condition(fromState, ...))
            then
                self:change(toState)
                break
            end
        end
    end
end

function Automaton.execute(self: Automaton, name: string, ...: any): ...any
    if not Automaton.is(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(name) ~= "string" then
        error(`expected string for name, got '{typeof(name)}'`, 2)
    end

    local state = self._stateMap[self.state]
    local action = state.actionMap[name]
    if action then
        return action(...)
    end
end

return table.freeze(Automaton)
