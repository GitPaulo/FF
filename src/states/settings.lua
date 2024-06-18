local love = _G.love
local Settings = {}

local WINDOW_WIDTH = 425
local WINDOW_HEIGHT = 281
local CHECKBOX_SIZE = 20
local PADDING = 10

function Settings:enter(params)
    -- Load fonts
    self.titleFont = love.graphics.newFont(32)
    self.instructionFont = love.graphics.newFont(16)
    self.smallFont = love.graphics.newFont(10)

    -- Set custom cursor
    self.cursor = love.graphics.newImage('assets/cursor.png')
    love.mouse.setVisible(false)

    -- Load background music
    self.backgroundMusic = love.audio.newSource('assets/characterselect.mp3', 'stream')
    self.backgroundMusic:setLooping(true)
    love.audio.play(self.backgroundMusic)

    -- Checkbox states
    self.useAI = params and params.useAI or false
    self.useDebugMode = _G.isDebug
    self.muteSound = params and params.muteSound or false

    -- Mouse state
    self.mousePressed = false

    -- Calculate positions
    local aiTextWidth = self.instructionFont:getWidth('Use AI for Fighter2')
    local debugTextWidth = self.instructionFont:getWidth('Use Debug Mode')
    local muteTextWidth = self.instructionFont:getWidth('Mute Sound')

    self.aiCheckboxX = (WINDOW_WIDTH - (CHECKBOX_SIZE + PADDING + aiTextWidth)) / 2
    self.aiCheckboxY = WINDOW_HEIGHT / 2 - 60

    self.debugCheckboxX = (WINDOW_WIDTH - (CHECKBOX_SIZE + PADDING + debugTextWidth)) / 2
    self.debugCheckboxY = self.aiCheckboxY + CHECKBOX_SIZE + PADDING

    self.muteCheckboxX = (WINDOW_WIDTH - (CHECKBOX_SIZE + PADDING + muteTextWidth)) / 2
    self.muteCheckboxY = self.debugCheckboxY + CHECKBOX_SIZE + PADDING
end

function Settings:exit()
    love.mouse.setVisible(true)
end

function Settings:update(dt)
    -- Update checkbox states based on mouse input
    local mouseX, mouseY = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        if not self.mousePressed then
            if
                mouseX >= self.aiCheckboxX and mouseX <= self.aiCheckboxX + CHECKBOX_SIZE and mouseY >= self.aiCheckboxY and
                    mouseY <= self.aiCheckboxY + CHECKBOX_SIZE
             then
                self.useAI = not self.useAI
            elseif
                mouseX >= self.debugCheckboxX and mouseX <= self.debugCheckboxX + CHECKBOX_SIZE and
                    mouseY >= self.debugCheckboxY and
                    mouseY <= self.debugCheckboxY + CHECKBOX_SIZE
             then
                self.useDebugMode = not self.useDebugMode
            elseif
                mouseX >= self.muteCheckboxX and mouseX <= self.muteCheckboxX + CHECKBOX_SIZE and
                    mouseY >= self.muteCheckboxY and
                    mouseY <= self.muteCheckboxY + CHECKBOX_SIZE
             then
                self.muteSound = not self.muteSound
                if self.muteSound then
                    love.audio.pause(self.backgroundMusic)
                else
                    love.audio.play(self.backgroundMusic)
                end
            end
            self.mousePressed = true
        end
    else
        self.mousePressed = false
    end
end

function Settings:render()
    love.graphics.clear(0, 0, 0, 1)

    -- Draw the title
    love.graphics.setFont(self.titleFont)
    love.graphics.printf('Settings', 0, WINDOW_HEIGHT / 9, WINDOW_WIDTH, 'center')

    -- Draw the checkboxes and labels
    love.graphics.setFont(self.instructionFont)

    -- Use AI for Fighter2
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', self.aiCheckboxX, self.aiCheckboxY, CHECKBOX_SIZE, CHECKBOX_SIZE)
    if self.useAI then
        love.graphics.line(
            self.aiCheckboxX,
            self.aiCheckboxY,
            self.aiCheckboxX + CHECKBOX_SIZE,
            self.aiCheckboxY + CHECKBOX_SIZE
        )
        love.graphics.line(
            self.aiCheckboxX + CHECKBOX_SIZE,
            self.aiCheckboxY,
            self.aiCheckboxX,
            self.aiCheckboxY + CHECKBOX_SIZE
        )
    end
    love.graphics.printf(
        'Use AI for Fighter2',
        self.aiCheckboxX + CHECKBOX_SIZE + PADDING,
        self.aiCheckboxY,
        WINDOW_WIDTH,
        'left'
    )

    -- Use Debug Mode
    love.graphics.rectangle('line', self.debugCheckboxX, self.debugCheckboxY, CHECKBOX_SIZE, CHECKBOX_SIZE)
    if self.useDebugMode then
        love.graphics.line(
            self.debugCheckboxX,
            self.debugCheckboxY,
            self.debugCheckboxX + CHECKBOX_SIZE,
            self.debugCheckboxY + CHECKBOX_SIZE
        )
        love.graphics.line(
            self.debugCheckboxX + CHECKBOX_SIZE,
            self.debugCheckboxY,
            self.debugCheckboxX,
            self.debugCheckboxY + CHECKBOX_SIZE
        )
    end
    love.graphics.printf(
        'Use Debug Mode',
        self.debugCheckboxX + CHECKBOX_SIZE + PADDING,
        self.debugCheckboxY,
        WINDOW_WIDTH,
        'left'
    )

    -- Mute Sound
    love.graphics.rectangle('line', self.muteCheckboxX, self.muteCheckboxY, CHECKBOX_SIZE, CHECKBOX_SIZE)
    if self.muteSound then
        love.graphics.line(
            self.muteCheckboxX,
            self.muteCheckboxY,
            self.muteCheckboxX + CHECKBOX_SIZE,
            self.muteCheckboxY + CHECKBOX_SIZE
        )
        love.graphics.line(
            self.muteCheckboxX + CHECKBOX_SIZE,
            self.muteCheckboxY,
            self.muteCheckboxX,
            self.muteCheckboxY + CHECKBOX_SIZE
        )
    end
    love.graphics.printf(
        'Mute Sound',
        self.muteCheckboxX + CHECKBOX_SIZE + PADDING,
        self.muteCheckboxY,
        WINDOW_WIDTH,
        'left'
    )

    -- Game by Paulo
    love.graphics.setFont(self.smallFont)
    love.graphics.printf('Game by Paulo', 10, WINDOW_HEIGHT - 20, WINDOW_WIDTH, 'left')

    -- Draw custom cursor
    love.graphics.draw(self.cursor, love.mouse.getX(), love.mouse.getY())
end

function Settings:keypressed(key)
    if key == 'escape' then
        _G.isDebug = self.useDebugMode -- Update global debug mode
        self.stateMachine:change(
            'menu',
            {
                settings = {
                    useAI = self.useAI,
                    muteSound = self.muteSound
                }
            }
        )
    end
end

return Settings
