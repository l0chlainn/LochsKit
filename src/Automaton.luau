--!strict

local LochsKit = script.Parent
local Signal = require(LochsKit.Signal)

type Signal = Signal.Signal

type callback = (...any) -> ...any
type state = {
	name: string,
	[string]: callback?,
}

type condition = (event: string, to: string, from: string, ...any) -> boolean
type transition = {
	event: string,
	to: string,
	from: { string },
	condition: condition?,
}

local Automaton = {}
Automaton.__index = Automaton

export type Automaton = typeof(setmetatable(
	{} :: {
		state: string,
		_statesMap: { [string]: state },
		_listenersMap: { [string]: { transition } },

		stateChanged: Signal,
	},
	Automaton
))

local function isAutomaton(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Automaton
end

local function createAutomaton(initial: string, states: { state }, transitions: { transition }): Automaton
	local statesMap = {}
	for _, state in states do
		statesMap[state.name] = state
	end

	if not statesMap[initial] then
		error(`Invalid initial state '{initial}'.`, 2)
	end

	local listenersMap = {}
	for index, transition in transitions do
		local to = transition.to
		if not statesMap[to] then
			error(`Invalid target state '{to}' in transition #{index}.`, 2)
		end

		local event = transition.event
		local listeners = listenersMap[event]
		if listeners then
			table.insert(listeners, transition)
		else
			listenersMap[event] = { transition }
		end
	end

	local stateChanged = Signal.new()

	return setmetatable({
		state = initial,
		_statesMap = statesMap,
		_listenersMap = listenersMap,

		stateChanged = stateChanged,
	}, Automaton)
end

function Automaton.destroy(self: Automaton): ()
	self.stateChanged:destroy()
end

function Automaton.change(self: Automaton, to: string): ()
	local from = self.state
	local statesMap = self._statesMap

	local fromState = statesMap[from]
	local toState = statesMap[to]
	if not toState then
		error(`Invalid target state '{to}'.`, 2)
	end

	local exit = fromState.exit
	if exit then
		exit()
	end
	self.state = to
	local enter = toState.enter
	if enter then
		enter()
	end
	self.stateChanged:send(to, from)
end

function Automaton.execute(self: Automaton, action: string, ...: any): ...any
	local currentState = self._statesMap[self.state]
	local callback = currentState[action]
	if callback then
		return callback(...)
	end
end

function Automaton.send(self: Automaton, event: string, ...: any): ()
	local listeners = self._listenersMap[event]
	if listeners then
		local from = self.state
		for _, transition in listeners do
			if table.find(transition.from, from) then
				local to = transition.to
				local condition = transition.condition
				if not condition or condition(event, to, from, ...) then
					self:change(to)
					break
				end
			end
		end
	end
end

table.freeze(Automaton)

return table.freeze({
	is = isAutomaton,
	new = createAutomaton,
})
