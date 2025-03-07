--!strict

local Signal = require(script.Parent:FindFirstChild("Signal"))

type Signal = Signal.Signal

type condition = (fromState: string, ...any) -> boolean
type transition = {
    event: string,
    toState: string,
    fromStates: {string},
    condition: condition?,
}

local Automaton = {}
Automaton.__index = Automaton

export type Automaton = typeof(setmetatable({} :: {
    state: string,
    _states: {string},
    _listenersMap: {[string]: {transition}},

    stateChanging: Signal,
    stateChanged: Signal,
}, Automaton))

local function isAutomaton(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Automaton
end

local function createAutomaton(initial: string, transitions: {transition}): Automaton
    local states = {initial}
    local listenersMap = {}
    for index, transition in transitions do
        local toState = transition.toState
        if not table.find(states, toState) then
            table.insert(states, toState)
        end

        local event = transition.event
        local listeners = listenersMap[event]
        if listeners then
            table.insert(listeners, transition)
        else
            listenersMap[event] = {transition}
        end
    end

    return setmetatable({
        state = initial,
        _states = states,
        _listenersMap = listenersMap,

        stateChanging = Signal.new(),
        stateChanged = Signal.new(),
    }, Automaton)
end

function Automaton.change(self: Automaton, toState: string): ()
    if table.find(self._states, toState) then
        local fromState = self.state
        self.stateChanging:fire(toState, fromState)
        self.state = toState
        self.stateChanged:fire(toState, fromState)
    end
end

function Automaton.fire(self: Automaton, event: string, ...: any): ()
    local listeners = self._listenersMap[event]
    if listeners then
        local fromState = self.state
        for _, transition in listeners do
            local condition = transition.condition
            if
                table.find(transition.fromStates, fromState)
                and (not condition or condition(fromState, ...))
            then
                self:change(transition.toState)
                break
            end
        end
    end
end

return table.freeze({
    is = isAutomaton,
    new = createAutomaton,
})
