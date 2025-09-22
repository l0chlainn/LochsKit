--!strict

local Signal = require(script.Parent:FindFirstChild("Signal"))

type Signal = Signal.Signal

type callback = () -> ()
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

	return setmetatable({
		state = initial,
		_statesMap = statesMap,
		_listenersMap = listenersMap,

		stateChanged = Signal.new(),
	}, Automaton)
end

function Automaton.destroy(self: Automaton): ()
	self.stateChanged:destroy()
end

function Automaton.change(self: Automaton, state: string): ()
	local current = self.state
	if state == current then
		return
	end

	local statesMap = self._statesMap
	local currentState = statesMap[current]
	local targetState = statesMap[state]
	if not targetState then
		error(`Invalid target state '{state}'.`, 2)
	end

	local exit = currentState.exit
	if exit then
		exit()
	end
	self.state = state
	local enter = targetState.enter
	if enter then
		enter()
	end
	self.stateChanged:send(state, current)
end

function Automaton.execute(self: Automaton, action: string, ...: any): ()
	local currentState = self._statesMap[self.state]
	local callback = currentState[action]
	if callback then
		callback(...)
	end
end

function Automaton.send(self: Automaton, event: string, ...: any): ()
	local listeners = self._listenersMap[event]
	if listeners then
		local current = self.state
		for _, transition in listeners do
			if not table.find(transition.from, current) then
				continue
			end

			local target = transition.to
			local condition = transition.condition
			if condition and not condition(event, target, current, ...) then
				continue
			end

			self:change(target)
			break
		end
	end
end

table.freeze(Automaton)

return table.freeze({
	is = isAutomaton,
	new = createAutomaton,
})
