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
    self.gameOver = false
    self.winner = nil

    -- Initialize fighters with unique characteristics
    self.fighter1 = Fighter:new(1, 100, 200, {
        left = 'a', right = 'd', jump = 'w',
        lightAttack = 'v', mediumAttack = 'b', heavyAttack = 'n'
    }, {
        light = {width = 100, height = 20, recovery = 0.4, damage = 5},
        medium = {width = 140, height = 25, recovery = 0.6, damage = 10},
        heavy = {width = 180, height = 30, recovery = 0.9, damage = 20}
    }, {
        light = {duration = 0.2, animationTime = 0.1},
        medium = {duration = 0.6, animationTime = 0.3},
        heavy = {duration = 1.2, animationTime = 0.6}
    }, 220)  -- fighter 1 with speed 220

    self.fighter2 = Fighter:new(2, 600, 200, {
        left = 'left', right = 'right', jump = 'up',
        lightAttack = 'kp1', mediumAttack = 'kp2', heavyAttack = 'kp3'
    }, {
        light = {width = 110, height = 20, recovery = 0.5, damage = 7},
        medium = {width = 160, height = 30, recovery = 0.8, damage = 12},
        heavy = {width = 200, height = 40, recovery = 1.1, damage = 25}
    }, {
        light = {duration = 0.3, animationTime = 0.15},
        medium = {duration = 0.7, animationTime = 0.35},
        heavy = {duration = 1.5, animationTime = 0.75}
    }, 180)  -- fighter 2 with speed 180
end

function Game:exit()
    -- Cleanup for the game state if necessary
end

function Game:update(dt)
    if self.gameOver then
        return
    end

    self.timer = self.timer + dt * SPEED

    -- Update fighters
    self.fighter1:update(dt)
    self.fighter2:update(dt)

    -- Check for collisions and apply damage
    if self.fighter1:isHit(self.fighter2) then
        self.fighter2:takeDamage(self.fighter1:getHitbox().damage)
    end
    if self.fighter2:isHit(self.fighter1) then
        self.fighter1:takeDamage(self.fighter2:getHitbox().damage)
    end

    -- Check for game over
    if self.fighter1.health <= 0 then
        self.gameOver = true
        self.winner = "Fighter 2 Wins!"
    elseif self.fighter2.health <= 0 then
        self.gameOver = true
        self.winner = "Fighter 1 Wins!"
    end
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

    -- Render health bars
    self:renderHealthBars()

    -- Render game over screen if game is over
    if self.gameOver then
        love.graphics.printf(self.winner, 0, SPRITE_HEIGHT / 2 - 20, SPRITE_WIDTH, 'center')
        love.graphics.printf("Press 'Enter' to return to Main Menu", 0, SPRITE_HEIGHT / 2 + 20, SPRITE_WIDTH, 'center')
    end
end

function Game:renderHealthBars()
    local barWidth = 300
    local barHeight = 20
    local padding = 10

    -- Fighter 1 health bar
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle('fill', padding, padding, barWidth, barHeight)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle('fill', padding, padding, barWidth * (self.fighter1.health / 100), barHeight)

    -- Fighter 2 health bar
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle('fill', SPRITE_WIDTH - barWidth - padding, padding, barWidth, barHeight)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle('fill', SPRITE_WIDTH - barWidth - padding, padding, barWidth * (self.fighter2.health / 100), barHeight)

    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function Game:keypressed(key)
    if self.gameOver and key == 'return' then
        gStateMachine:change('menu')
    end
end

return Game