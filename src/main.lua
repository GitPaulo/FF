require 'dependencies'

local Menu, Game, StateMachine, love = _G.Menu, _G.Game, _G.StateMachine, _G.love;
local gStateMachine;

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Initialize state machine with separate state files
    gStateMachine = StateMachine:new({
        ['menu'] = Menu,
        ['game'] = Game
    })
    gStateMachine:change('menu')

    love.keyboard.keysPressed = {}
end

function love.update(dt)
    gStateMachine:update(dt)

    -- Clear keysPressed table at the end of update
    love.keyboard.keysPressed = {}
end

function love.draw()
    gStateMachine:render()
end

function love.mousepressed(x, y, button)
    gStateMachine:mousepressed(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
    love.keyboard.keysPressed[key] = true
    print("Key Pressed: ", key)  -- Debugging statement to check keypresses

    -- Temporary state change for testing
    if key == 'space' then
        if gStateMachine.currentStateName == 'menu' then
            gStateMachine:change('game')
            print('Switched to game')
        end
    end
    if key == 'escape' then
        if gStateMachine.currentStateName == 'game' then
            gStateMachine:change('menu')
            print('Switched to menu')
        end
    end
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end
