require 'dependencies'

local Menu, Game, Loading, StateMachine, love, SoundManager = _G.Menu, _G.Game, _G.Loading, _G.StateMachine, _G.love, _G.SoundManager
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
            ['loading'] = Loading
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
    print('Key Pressed: ', key) -- Debugging statement to check keypresses
    if key == 'space' then
        if gStateMachine.currentStateName == 'menu' then
            gStateMachine:change(
                'loading',
                {
                    songs = {
                        {path = 'assets/game1.mp3', fftDataPath = 'assets/fft_data_game1.json'},
                        {path = 'assets/game2.mp3', fftDataPath = 'assets/fft_data_game2.json'},
                        {path = 'assets/game3.mp3', fftDataPath = 'assets/fft_data_game3.json'}
                    }
                }
            )
            print('Switched to loading')
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
