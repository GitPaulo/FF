local love = _G.love
local Game = {}

local SPRITE_WIDTH = 800
local SPRITE_HEIGHT = 300
local FRAMES = 38
local SPEED = 10

function Game:enter(params)
    self.background = love.graphics.newImage("assets/background_game_spritesheet.png")
    self:buildBackground()

    -- Game state
    self.timer = 0
    self.gameOver = false
    self.winner = nil

    -- Fighter setup
    self.fighter1 = params.fighter1
    self.fighter2 = params.fighter2

    -- FFT visualizer setup
    self.fftBufferSize = 64
    self.fftData = {}
    self.fftAngleStep = (2 * math.pi) / self.fftBufferSize
    self.fftRadius = 25
    self.fftMaxHeight = 18

    -- Songs
    self.songs = params and params.songs
    self.currentSongIndex = 1
    self:playCurrentSong()
end

function Game:exit()
    self.music:stop()
end

function Game:playCurrentSong()
    local song = self.songs[self.currentSongIndex]
    self.music = love.audio.newSource(song.path, "stream")
    self.music:setLooping(false)
    self.music:play()

    -- Use preloaded FFT data
    self.fftData = song.fftData
    self.fftDataIndex = 1
end

function Game:update(dt)
    if self.gameOver then
        return
    end

    self.timer = self.timer + dt * SPEED

    -- Update fighters with the other fighter's state
    self.fighter1:update(dt, self.fighter2)
    self.fighter2:update(dt, self.fighter1)

    -- Check for collisions and apply damage
    if self.fighter1:isHit(self.fighter2) then
        local hitbox = self.fighter2:getHitbox()
        self.fighter1:takeDamage(hitbox.damage)
    end
    if self.fighter2:isHit(self.fighter1) then
        local hitbox = self.fighter1:getHitbox()
        self.fighter2:takeDamage(hitbox.damage)
    end

    -- Check for game over
    if self.fighter1.health <= 0 then
        self.gameOver = true
        self.winner = "Fighter 2 Wins!"
    elseif self.fighter2.health <= 0 then
        self.gameOver = true
        self.winner = "Fighter 1 Wins!"
    end

    -- Update FFT data index
    self.fftDataIndex = (self.fftDataIndex % #self.fftData) + 1

    -- Check if the current song has finished playing
    if not self.music:isPlaying() then
        self.currentSongIndex = self.currentSongIndex % #self.songs + 1
        self:playCurrentSong()
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

    -- Render FFT visualizer
    self:renderFFT()

    -- Render game over screen if game is over
    if self.gameOver then
        love.graphics.printf(self.winner, 0, SPRITE_HEIGHT / 2 - 20, SPRITE_WIDTH, 'center')
        love.graphics.printf("Press 'ESC' to return to Main Menu", 0, SPRITE_HEIGHT / 2 + 20, SPRITE_WIDTH, 'center')
    end
end

function Game:buildBackground()
   self.background_quads = {}

    local imgWidth, imgHeight = self.background:getWidth(), self.background:getHeight()

    for i = 0, FRAMES - 1 do
        local x = i * SPRITE_WIDTH
        table.insert(self.background_quads, love.graphics.newQuad(x, 0, SPRITE_WIDTH, SPRITE_HEIGHT, imgWidth, imgHeight))
    end

    -- Set the window size to match the dimensions of a single sprite
    love.window.setMode(SPRITE_WIDTH, SPRITE_HEIGHT)
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

    -- Fighter 1 stamina bar
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.rectangle('fill', padding, padding + barHeight + 3, barWidth * (self.fighter1.stamina / self.fighter1.maxStamina), barHeight / 4)

    -- Fighter 2 health bar
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle('fill', love.graphics.getWidth() - barWidth - padding, padding, barWidth, barHeight)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle('fill', love.graphics.getWidth() - barWidth - padding, padding, barWidth * (self.fighter2.health / 100), barHeight)

    -- Fighter 2 stamina bar
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.rectangle('fill', love.graphics.getWidth() - barWidth - padding, padding + barHeight + 3, barWidth * (self.fighter2.stamina / self.fighter2.maxStamina), barHeight / 4)

    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end


function Game:renderFFT()
    local centerX = SPRITE_WIDTH / 2
    local centerY = 40
    local fftData = self.fftData[self.fftDataIndex]
    if fftData then
        for i = 1, #fftData do
            local angle = self.fftAngleStep * (i - 1)
            local barHeight = fftData[i] * self.fftMaxHeight
            if barHeight then
                local x1 = centerX + self.fftRadius * math.cos(angle)
                local y1 = centerY + self.fftRadius * math.sin(angle)
                local x2 = centerX + (self.fftRadius + barHeight) * math.cos(angle)
                local y2 = centerY + (self.fftRadius + barHeight) * math.sin(angle)
                love.graphics.setColor(1, 1, 1)
                love.graphics.line(x1, y1, x2, y2)
            end
        end
    end
end

function Game:keypressed(key)
    if self.gameOver and key == 'return' then
        self.stateMachine:change('menu')
    end
end

return Game
