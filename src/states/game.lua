local Game = {}

local SPRITE_WIDTH = 800
local SPRITE_HEIGHT = 300
local FRAMES = 38
local SPEED = 10

function Game:enter()
    self.background = love.graphics.newImage("assets/background_game_spritesheet.png")
    self.background_quads = {}

    local imgWidth, imgHeight = self.background:getWidth(), self.background:getHeight()

    for i = 0, FRAMES - 1 do
        local x = i * SPRITE_WIDTH
        table.insert(self.background_quads, love.graphics.newQuad(x, 0, SPRITE_WIDTH, SPRITE_HEIGHT, imgWidth, imgHeight))
    end

    -- Set the window size to match the dimensions of a single sprite
    love.window.setMode(SPRITE_WIDTH, SPRITE_HEIGHT)

    self.timer = 0

    -- Initialize fighters
    self.fighter1 = Fighter:new("P1", 100, 300, {left = 'a', right = 'd', jump = 'w'})
    self.fighter2 = Fighter:new("P2", 600, 300, {left = 'left', right = 'right', jump = 'up'})
end

function Game:exit()
    -- Cleanup for the game state if necessary
end

function Game:update(dt)
    self.timer = self.timer + dt * SPEED

    -- Update fighters
    self.fighter1:update(dt)
    self.fighter2:update(dt)
end

function Game:render()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.print('Game State', 10, 10)
    -- Draw the background image
    local currentFrame = (math.floor(self.timer) % FRAMES) + 1
    love.graphics.draw(self.background, self.background_quads[currentFrame], 0, 0)

    -- Render fighters
    self.fighter1:render()
    self.fighter2:render()
end

return Game