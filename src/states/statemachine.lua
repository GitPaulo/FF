local Class = _G.Class
local StateMachine = Class:extend()

function StateMachine:init(states)
    self.empty = {
        draw = function()
        end,
        update = function()
        end,
        enter = function()
        end,
        exit = function()
        end,
        mousepressed = function()
        end
    }
    self.states = states or {}

    -- Add reference to the state machine in each state
    for _, state in pairs(self.states) do
        state.stateMachine = self
    end

    self.current = self.empty
    self.currentStateName = nil
end

function StateMachine:change(stateName, enterParams)
    assert(self.states[stateName], 'State must exist!') -- state must exist!
    if self.current.exit then
        self.current:exit()
    end
    self.current = self.states[stateName]
    self.current:enter(enterParams)
    self.currentStateName = stateName -- Track the current state name
end

-- Hooks

function StateMachine:update(dt)
    if self.current.update then
        self.current:update(dt)
    end
end

function StateMachine:render()
    if self.current.render then
        self.current:render()
    end
end

function StateMachine:mousepressed(x, y, button)
    if self.current.mousepressed then
        self.current:mousepressed(x, y, button)
    end
end

function StateMachine:keypressed(key)
    if self.current.keypressed then
        self.current:keypressed(key)
    end
end

return StateMachine
