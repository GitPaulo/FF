local love = _G.love
local Menu = {}

local TITLE_TEXT = 'Tiny Fighting Game'
local BUTTON_TEXT = 'Start Game'
local BUTTON_WIDTH = 160
local BUTTON_HEIGHT = 40
local WINDOW_WIDTH = 425
local WINDOW_HEIGHT = 281
local BUTTON_X = (WINDOW_WIDTH - BUTTON_WIDTH) / 2
local BUTTON_Y = WINDOW_HEIGHT / 2

local FRAMES = 120
local SPEED = 10

local buttonHover = false

function Menu:enter()
    -- Background
    self.background = love.graphics.newImage('assets/background_menu_spritesheet.png')
    self:buildBackground()

    -- Set size
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    -- Load font
    self.titleFont = love.graphics.newFont(32)
    self.buttonFont = love.graphics.newFont(20)
    -- Initialize timer and titleScale
    self.timer = 0
    self.titleScale = 1

    -- Load background music
    self.backgroundMusic = love.audio.newSource('assets/menu.mp3', 'stream')
    self.backgroundMusic:setLooping(true)
    love.audio.play(self.backgroundMusic)

    -- Set custom cursor
    self.cursor = love.graphics.newImage('assets/cursor.png')
    love.mouse.setVisible(false)
end

function Menu:exit()
    -- Cleanup
    love.audio.stop(self.backgroundMusic)
end

function Menu:update(dt)
    self.timer = self.timer + dt * SPEED
    -- Update the button hover state
    local mouseX, mouseY = love.mouse.getPosition()
    if
        mouseX >= BUTTON_X and mouseX <= BUTTON_X + BUTTON_WIDTH and mouseY >= BUTTON_Y and
            mouseY <= BUTTON_Y + BUTTON_HEIGHT
     then
        buttonHover = true
    else
        buttonHover = false
    end

    -- Update the title animation
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
    love.graphics.translate(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 4)
    love.graphics.scale(self.titleScale, self.titleScale)
    love.graphics.printf(TITLE_TEXT, -WINDOW_WIDTH / 2, 0, WINDOW_WIDTH, 'center')
    love.graphics.pop()

    -- Draw the button with hover effect
    love.graphics.setFont(self.buttonFont)
    if buttonHover then
        love.graphics.setColor(1, 1, 1, 0.8) -- Slightly transparent white for hover
    else
        love.graphics.setColor(1, 1, 1, 1) -- Solid white for normal
    end
    love.graphics.rectangle('line', BUTTON_X, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.printf(BUTTON_TEXT, BUTTON_X, BUTTON_Y + (BUTTON_HEIGHT / 4), BUTTON_WIDTH, 'center')

    -- Reset color
    love.graphics.setColor(1, 1, 1)

    -- Draw custom cursor
    love.graphics.draw(self.cursor, love.mouse.getX(), love.mouse.getY())
end

function Menu:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if x >= BUTTON_X and x <= BUTTON_X + BUTTON_WIDTH and y >= BUTTON_Y and y <= BUTTON_Y + BUTTON_HEIGHT then
            self.stateMachine:change(
                'loading',
                {
                    songs = {
                        {path = 'assets/game1.mp3', fftDataPath = 'assets/fft_data_game1.json'},
                        {path = 'assets/game2.mp3', fftDataPath = 'assets/fft_data_game2.json'},
                        {path = 'assets/game3.mp3', fftDataPath = 'assets/fft_data_game3.json'}
                    }
                }
            )
        end
    end
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
