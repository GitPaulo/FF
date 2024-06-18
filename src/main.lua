require 'dependencies'

local Menu, Game, CharacterSelect, Loading, Settings, StateMachine, love, SoundManager =
    _G.Menu,
    _G.Game,
    _G.CharacterSelect,
    _G.Loading,
    _G.Settings,
    _G.StateMachine,
    _G.love,
    _G.SoundManager -- Do not add _G.isDebug as it is changes by Settings
local gStateMachine

function love.load()
    local customCursor = love.mouse.newCursor('assets/cursor.png', 0, 0)
    love.mouse.setCursor(customCursor)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Initialize state machine with separate state files
    gStateMachine =
        StateMachine:new(
        {
            ['menu'] = Menu,
            ['game'] = Game,
            ['loading'] = Loading,
            ['characterselect'] = CharacterSelect,
            ['settings'] = Settings
        }
    )
    gStateMachine:change('menu')

    love.keyboard.keysPressed = {}
end

function love.update(dt)
    SoundManager:update()
    gStateMachine:update(dt)

    -- keep it after the state machine update
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
    if _G.isDebug then
        print('Key Pressed: ', key) -- Debugging statement to check keypresses
    end
    gStateMachine:keypressed(key)
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end
