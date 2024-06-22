local love = _G.love
local Menu = {}

local TITLE_TEXT = 'Tiny Fighting Game'
local PLAY_BUTTON_TEXT = 'Play'
local CHARACTER_SELECT_TEXT = 'Characters'
local SETTINGS_TEXT = 'Settings'

local BUTTON_WIDTH = 140
local BUTTON_HEIGHT = 35
local WINDOW_WIDTH = 425
local WINDOW_HEIGHT = 281
local BUTTON_X = (WINDOW_WIDTH - BUTTON_WIDTH) / 2

local SETTINGS_BUTTON_Y = WINDOW_HEIGHT / 1.36 - 2 * BUTTON_HEIGHT - 20
local CHARACTER_BUTTON_Y = SETTINGS_BUTTON_Y + BUTTON_HEIGHT + 10
local PLAY_BUTTON_Y = CHARACTER_BUTTON_Y + BUTTON_HEIGHT + 10

local FRAMES = 120
local SPEED = 10

local playButtonHover = false
local characterButtonHover = false
local settingsButtonHover = false

function Menu:enter(params)
    -- For first open
    params = params or {}

    -- Settings
    self.settings =
        params.settings or
        {
            useAI = false,
            muteSound = false
        }

    -- Selected Fighters
    self.selectedFighters = params.selectedFighters or {'Samurai1', 'Samurai2'}

    -- Background
    self.background = love.graphics.newImage('assets/background_menu_spritesheet.png')
    self:buildBackground()

    -- Set window size
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Load fonts
    self.titleFont = love.graphics.newFont(32)
    self.buttonFont = love.graphics.newFont(20)

    -- Initialize timer and titleScale
    self.timer = 0
    self.titleScale = 1

    -- Load background music
    self.backgroundMusic = love.audio.newSource('assets/menu.mp3', 'stream')
    self.backgroundMusic:setLooping(true)
    love.audio.stop() -- stop current music
    love.audio.play(self.backgroundMusic)

    -- Button hover sound
    self.hoverSound = love.audio.newSource('assets/hover.mp3', 'static')
    self.clickSound = love.audio.newSource('assets/click.mp3', 'static')

    -- Set custom cursor
    self.cursor = love.graphics.newImage('assets/cursor.png')
    love.mouse.setVisible(false)
end

function Menu:exit()
    -- Cleanup
    love.audio.stop(self.backgroundMusic)
end

function Menu:update(dt)
    local mouseX, mouseY = love.mouse.getPosition()

    -- Function to handle hover sound
    local function handleHoverSound(hoverState, newHoverState)
        if newHoverState and not hoverState then
            love.audio.play(self.hoverSound:clone())
        end
        return newHoverState
    end

    -- Check for hover on play button
    playButtonHover =
        handleHoverSound(
        playButtonHover,
        mouseX >= BUTTON_X and mouseX <= BUTTON_X + BUTTON_WIDTH and mouseY >= PLAY_BUTTON_Y and
            mouseY <= PLAY_BUTTON_Y + BUTTON_HEIGHT
    )

    -- Check for hover on character button
    characterButtonHover =
        handleHoverSound(
        characterButtonHover,
        mouseX >= BUTTON_X and mouseX <= BUTTON_X + BUTTON_WIDTH and mouseY >= CHARACTER_BUTTON_Y and
            mouseY <= CHARACTER_BUTTON_Y + BUTTON_HEIGHT
    )

    -- Check for hover on settings button
    settingsButtonHover =
        handleHoverSound(
        settingsButtonHover,
        mouseX >= BUTTON_X and mouseX <= BUTTON_X + BUTTON_WIDTH and mouseY >= SETTINGS_BUTTON_Y and
            mouseY <= SETTINGS_BUTTON_Y + BUTTON_HEIGHT
    )

    -- Update the title animation
    self.timer = self.timer + dt * SPEED
    self.titleScale = 1 + 0.1 * math.sin(love.timer.getTime() * 3) -- Oscillating scale
end

function Menu:render()
    love.graphics.clear(0, 0, 0, 1)

    -- Draw the background with animation
    local currentFrame = (math.floor(self.timer) % FRAMES) + 1
    love.graphics.draw(self.background, self.background_quads[currentFrame], 0, 0)

    -- Draw the title with animation
    love.graphics.setFont(self.titleFont)
    love.graphics.push()
    love.graphics.translate(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 5)
    love.graphics.scale(self.titleScale, self.titleScale)
    love.graphics.printf(TITLE_TEXT, -WINDOW_WIDTH / 2, 0, WINDOW_WIDTH, 'center')
    love.graphics.pop()

    -- Draw the settings button with hover effect
    love.graphics.setFont(self.buttonFont)
    if settingsButtonHover then
        love.graphics.setColor(1, 1, 0.8, 0.8) -- Slightly transparent white for hover
    else
        love.graphics.setColor(1, 1, 1, 1) -- Solid white for normal
    end
    love.graphics.rectangle('line', BUTTON_X, SETTINGS_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.printf(SETTINGS_TEXT, BUTTON_X, SETTINGS_BUTTON_Y + (BUTTON_HEIGHT / 5), BUTTON_WIDTH, 'center')

    -- Draw the character select button with hover effect
    if characterButtonHover then
        love.graphics.setColor(1, 1, 0.8, 0.8) -- Slightly transparent white for hover
    else
        love.graphics.setColor(1, 1, 1, 1) -- Solid white for normal
    end
    love.graphics.rectangle('line', BUTTON_X, CHARACTER_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.printf(
        CHARACTER_SELECT_TEXT,
        BUTTON_X,
        CHARACTER_BUTTON_Y + (BUTTON_HEIGHT / 5),
        BUTTON_WIDTH,
        'center'
    )

    -- Draw the play button with hover effect
    if playButtonHover then
        love.graphics.setColor(1, 1, 0.8, 0.8) -- Slightly transparent white for hover
    else
        love.graphics.setColor(1, 1, 1, 1) -- Solid white for normal
    end
    love.graphics.rectangle('line', BUTTON_X, PLAY_BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.printf(PLAY_BUTTON_TEXT, BUTTON_X, PLAY_BUTTON_Y + (BUTTON_HEIGHT / 5), BUTTON_WIDTH, 'center')

    -- Reset color
    love.graphics.setColor(1, 1, 1)

    -- Draw custom cursor
    love.graphics.draw(self.cursor, love.mouse.getX(), love.mouse.getY())
end

function Menu:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if x >= BUTTON_X and x <= BUTTON_X + BUTTON_WIDTH and y >= PLAY_BUTTON_Y and y <= PLAY_BUTTON_Y + BUTTON_HEIGHT then
            self:MoveToGame()
        elseif
            x >= BUTTON_X and x <= BUTTON_X + BUTTON_WIDTH and y >= CHARACTER_BUTTON_Y and
                y <= CHARACTER_BUTTON_Y + BUTTON_HEIGHT
         then
            love.audio.play(self.clickSound)
            self.stateMachine:change('characterselect')
        elseif
            x >= BUTTON_X and x <= BUTTON_X + BUTTON_WIDTH and y >= SETTINGS_BUTTON_Y and
                y <= SETTINGS_BUTTON_Y + BUTTON_HEIGHT
         then
            love.audio.play(self.clickSound)
            self.stateMachine:change('settings', self.settings)
        end
    end
end

function Menu:keypressed(key)
    if key == 'space' then
        self:MoveToGame()
    end
end

function Menu:MoveToGame() -- Move to the game state
    self.stateMachine:change(
        'loading',
        {
            useAI = self.settings.useAI,
            songs = {
                {path = 'assets/game1.mp3', fftDataPath = 'assets/fft_data_game1.msgpack'},
                {path = 'assets/game2.mp3', fftDataPath = 'assets/fft_data_game2.msgpack'},
                {path = 'assets/game3.mp3', fftDataPath = 'assets/fft_data_game3.msgpack'}
            },
            selectedFighters = self.selectedFighters
        }
    )
end

function Menu:buildBackground()
    self.background_quads = {}
    local imgWidth, imgHeight = self.background:getWidth(), self.background:getHeight()
    local frameWidth = WINDOW_WIDTH
    local frameHeight = WINDOW_HEIGHT
    local cols = 9
    local rows = 14

    for i = 0, FRAMES - 1 do
        local col = i % cols
        local row = math.floor(i / cols)
        local x = col * frameWidth
        local y = row * frameHeight
        table.insert(self.background_quads, love.graphics.newQuad(x, y, frameWidth, frameHeight, imgWidth, imgHeight))
    end
end

return Menu
