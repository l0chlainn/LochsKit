--!strict

local LochsKit = script.Parent
local Signal = require(LochsKit.Signal)

type Signal = Signal.Signal

type callback = (...any) -> ...any
type state = {
	name: string,
	enter: callback?,
	exit: callback?,
	[string]: callback?,
}

type condition = (...any) -> boolean
type transition = {
	trigger: string,
	target: string,
	sources: { string },
	condition: condition?,
}

local Automaton = {}
Automaton.__index = Automaton

export type Automaton = typeof(setmetatable(
	{} :: {
		state: string,
		_statesMap: { [string]: state? },
		_transitionsMap: { [string]: { transition }? },

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
		error(`Initial state '{initial}' is not a valid state.`, 2)
	end

	local transitionsMap = {}
	for index, transition in transitions do
		local target = transition.target
		if not statesMap[target] then
			error(`Transition target '{target}' at index #{index} is not a valid state.`, 2)
		end

		local sources = transition.sources
		for _, source in sources do
			if not statesMap[source] then
				error(`Transition source '{source}' at index #{index} is not a valid state.`, 2)
			end
		end

		local trigger = transition.trigger
		local group = transitionsMap[trigger]
		if group then
			table.insert(group, transition)
		else
			transitionsMap[trigger] = { transition }
		end
	end

	local self = setmetatable({
		state = initial,
		_statesMap = statesMap,
		_transitionsMap = transitionsMap,

		stateChanged = Signal.new(),
	}, Automaton)

	return self
end

function Automaton.change(self: Automaton, target: string): ()
	local statesMap = self._statesMap
	local source = self.state

	local sourceState = statesMap[source] :: state
	local targetState = statesMap[target]
	if not targetState then
		error(`Target state '{target}' is not a valid state.`, 2)
	end

	local exit = sourceState.exit
	if exit then
		exit()
	end
	local enter = targetState.enter
	if enter then
		enter()
	end

	self.state = target
	self.stateChanged:fire(target, source)
end

function Automaton.trigger(self: Automaton, trigger: string, ...: any): ()
	local transitionsMap = self._transitionsMap
	local transitions = transitionsMap[trigger]
	if not transitions then
		return
	end

	local source = self.state
	for _, transition in transitions do
		if not table.find(transition.sources, source) then
			continue
		end

		local condition = transition.condition
		if condition and not condition(...) then
			continue
		end

		self:change(transition.target)

		break
	end
end

function Automaton.invoke(self: Automaton, action: string, ...: any): ...any
	local statesMap = self._statesMap
	local state = statesMap[self.state] :: state

	local callback = state[action]
	if callback then
		return callback(...)
	end
end

table.freeze(Automaton)

return table.freeze({
	is = isAutomaton,
	new = createAutomaton,
})
