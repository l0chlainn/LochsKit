--[ Action Class ]--
local Action = {}
Action.__index = Action

function Action.new()
    return setmetatable({
        _binds = {},
    }, Action)
end

function Action:bind(name, handler)
    if type(name) ~= "string" then
        error("name must be a string!", 2)
    elseif type(handler) ~= "function" then
        error("handler must be a function!", 2)
    end

    self:unbind(name)
    table.insert(self._binds, {
        name = name,
        handler = handler,
    })
end

function Action:unbind(name)
    if type(name) ~= "string" then
        error("name must be a string!", 2)
    end

    local binds = self._binds
    for index, bind in binds do
        if bind.name == name then
            table.remove(binds, index)
        end
    end
end

function Action:execute(...)
    for _, bind in self._binds do
        bind.handler(...)
    end
end

return Action
