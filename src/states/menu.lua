local Menu = {}

local TITLE_TEXT = "Tiny Fighting Game"
local BUTTON_TEXT = "Start Game"
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50
local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 400
local BUTTON_X = (WINDOW_WIDTH - BUTTON_WIDTH) / 2
local BUTTON_Y = WINDOW_HEIGHT / 2

function Menu:enter()
    -- Set size
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    
    -- Load font
    self.titleFont = love.graphics.newFont(32)
    self.buttonFont = love.graphics.newFont(20)
end

function Menu:exit()
    -- Cleanup
end

function Menu:update(dt)
    -- Logic
end

function Menu:render()
    love.graphics.clear(0, 0, 0, 1)

    -- Draw the title
    love.graphics.setFont(self.titleFont)
    love.graphics.printf(TITLE_TEXT, 0, WINDOW_HEIGHT / 4, WINDOW_WIDTH, "center")

    -- Draw the button
    love.graphics.setFont(self.buttonFont)
    love.graphics.rectangle("line", BUTTON_X, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)
    love.graphics.printf(BUTTON_TEXT, BUTTON_X, BUTTON_Y + (BUTTON_HEIGHT / 4), BUTTON_WIDTH, "center")
end

function Menu:mousepressed(x, y, button)
    print('click')
    if button == 1 then -- Left mouse button
        print("clicked 1")
        if x >= BUTTON_X and x <= BUTTON_X + BUTTON_WIDTH and y >= BUTTON_Y and y <= BUTTON_Y + BUTTON_HEIGHT then
            gStateMachine:change("game")
        end
    end
end

return Menu
