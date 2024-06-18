local love = _G.love
local table = require 'lib.table'
local Anim8 = require 'lib.anim8'
local CharacterSelect = {}

local SPRITE_SCALE = 2
local PLAYER_COUNT = 2

function CharacterSelect:enter(params)
    self.currentPlayer = 1
    self.selectedFighters = {1, 2}
    self.characters = {}
    self.animations = {}

    -- Load character data from files
    local files = love.filesystem.getDirectoryItems('fighters')
    for _, file in ipairs(files) do
        if file:match('%.lua$') then
            local character = table.shallowcopy(require('fighters.' .. file:gsub('%.lua$', '')))
            table.insert(self.characters, character)
            local spriteSheet = love.graphics.newImage('assets/fighters/' .. character.name .. '/Idle.png')

            -- Use the number of frames from spriteConfig
            local frameWidth, frameHeight = 200, 200 -- Assuming fixed frame size
            local numFrames = character.spriteConfig.idle[2]
            local grid = Anim8.newGrid(frameWidth, frameHeight, spriteSheet:getWidth(), spriteSheet:getHeight())
            local animation = Anim8.newAnimation(grid('1-' .. numFrames, 1), 0.1)
            table.insert(self.animations, {spriteSheet = spriteSheet, animation = animation})
        end
    end

    -- Load fonts
    self.titleFont = love.graphics.newFont(32)
    self.instructionFont = love.graphics.newFont(16)
    self.statsFont = love.graphics.newFont(10)

    -- Set custom cursor
    self.cursor = love.graphics.newImage('assets/cursor.png')
    love.mouse.setVisible(false)


    -- Load background music
    self.backgroundMusic = love.audio.newSource('assets/characterselect.mp3', 'stream')
    self.backgroundMusic:setLooping(true)
    love.audio.play(self.backgroundMusic)
end

function CharacterSelect:exit()
    love.mouse.setVisible(true)
end

function CharacterSelect:update(dt)
    self.animations[self.selectedFighters[self.currentPlayer]].animation:update(dt)

    if love.keyboard.wasPressed('left') then
        self.selectedFighters[self.currentPlayer] = self.selectedFighters[self.currentPlayer] - 1
        if self.selectedFighters[self.currentPlayer] < 1 then
            self.selectedFighters[self.currentPlayer] = #self.characters
        end
    elseif love.keyboard.wasPressed('right') then
        self.selectedFighters[self.currentPlayer] = self.selectedFighters[self.currentPlayer] + 1
        if self.selectedFighters[self.currentPlayer] > #self.characters then
            self.selectedFighters[self.currentPlayer] = 1
        end
    elseif love.keyboard.wasPressed('return') then
        if self.currentPlayer < PLAYER_COUNT then
            self.currentPlayer = self.currentPlayer + 1
        else
            local selectedFighterNames = {}
            for i, index in ipairs(self.selectedFighters) do
                selectedFighterNames[i] = self.characters[index].name
            end
            self.stateMachine:change(
                'menu',
                {
                    selectedFighters = selectedFighterNames
                }
            )
        end
    elseif love.keyboard.wasPressed('escape') then
        self.stateMachine:change('menu')
    end
end

function CharacterSelect:render()
    love.graphics.clear(0.1, 0.1, 0.1) -- Clear the screen with a dark background

    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.printf('Select Your Fighter', 0, 10, love.graphics.getWidth(), 'center')
    love.graphics.printf('Player ' .. self.currentPlayer, 0, 60, love.graphics.getWidth(), 'center')

    -- Draw the selected character sprite
    local animationData = self.animations[self.selectedFighters[self.currentPlayer]]
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local spriteX = (windowWidth - (200 * SPRITE_SCALE)) / 2 -- Center based on frame size
    local spriteY = (windowHeight - (200 * SPRITE_SCALE)) / 2 + 20
    animationData.animation:draw(animationData.spriteSheet, spriteX, spriteY, 0, SPRITE_SCALE, SPRITE_SCALE)

    -- Draw stats next to the character sprite
    local character = self.characters[self.selectedFighters[self.currentPlayer]]
    local statsX = 280
    local statsY = 100
    local statsYGap = 14
    love.graphics.setFont(self.statsFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf('Speed: ' .. character.traits.speed, statsX, statsY + statsYGap, 200, 'left')
    love.graphics.printf('Health: ' .. character.traits.health, statsX, statsY + statsYGap * 2, 200, 'left')
    love.graphics.printf('Stamina: ' .. character.traits.stamina, statsX, statsY + statsYGap * 3, 200, 'left')
    love.graphics.printf(
        'Light Damage: ' .. character.hitboxes.light.damage,
        statsX,
        statsY + statsYGap * 4,
        200,
        'left'
    )
    love.graphics.printf(
        'Medium Damage: ' .. character.hitboxes.medium.damage,
        statsX,
        statsY + statsYGap * 5,
        200,
        'left'
    )
    love.graphics.printf(
        'Heavy Damage: ' .. character.hitboxes.heavy.damage,
        statsX,
        statsY + statsYGap * 6,
        200,
        'left'
    )

    -- Draw instructions
    love.graphics.setFont(self.instructionFont)
    love.graphics.printf("Use 'Arrow' keys to swap and 'Enter' to confirm", 0, windowHeight - 60, windowWidth, 'center')
    love.graphics.printf("Press 'Esc' to go back", 0, windowHeight - 30, windowWidth, 'center')

    -- Draw custom cursor
    love.graphics.draw(self.cursor, love.mouse.getX(), love.mouse.getY())
end

return CharacterSelect
