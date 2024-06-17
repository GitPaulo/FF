local Anim8 = require 'lib.anim8'

local Class, love, SoundManager = _G.Class, _G.love, _G.SoundManager
local Fighter = Class:extend()
local isDebug = false;

function Fighter:init(id, x, y, controls, traits, hitboxes, spriteConfig, soundFXConfig)
    -- Character Properties
    self.id = id
    self.x = x
    self.y = y
    self.controls = controls
    self.width = traits.width or 50
    self.height = traits.height or 100
    self.speed = traits.speed or 200
    self.health = traits.health or 100
    self.hitboxes = hitboxes or {
        light = {width = 100, height = 20, recovery = 0.5, damage = 5},
        medium = {width = 150, height = 30, recovery = 0.7, damage = 10},
        heavy = {width = 200, height = 40, recovery = 1.0, damage = 20}
    }
    self:validateHitboxes()

    -- Character State
    self.dy = 0
    self.direction = (id == 2) and -1 or 1 -- Set direction to right for player 1 and left for player 2
    self.state = 'idle'
    self.gravity = 1000
    self.jumpStrength = -525
    self.attackType = nil
    self.lastAttackType = nil
    self.attackEndTime = 0
    self.recoveryEndTime = 0
    self.hitEndTime = 0
    self.damageApplied = false
    self.isBlocking = false
    self.isBlockingDamage = false
    self.isJumping = false

    -- Animation and Sprites
    self.spritesheets = self:loadSpritesheets(spriteConfig)
    self.animations = self:loadAnimations(spriteConfig)
    self.sounds = self:loadSoundFX(soundFXConfig)

    self.currentAnimation = self.animations.idle
end

function Fighter:validateHitboxes()
    for attackType, hitbox in pairs(self.hitboxes) do
        assert(hitbox.width, "Width must be defined for hitbox: " .. attackType)
        assert(hitbox.height, "Height must be defined for hitbox: " .. attackType)
        assert(hitbox.recovery, "Recovery time must be defined for hitbox: " .. attackType)
        assert(hitbox.damage, "Damage must be defined for hitbox: " .. attackType)
    end
end

function Fighter:loadSpritesheets(configs)
    local spritesheets = {}

    for key, config in pairs(configs) do
        spritesheets[key] = love.graphics.newImage(config[1])
        print("Loaded spritesheet for", key, "from", config[1], "with frame count:", config[2], "and dimensions:", spritesheets[key]:getDimensions())
    end

    return spritesheets
end

function Fighter:loadAnimations(configs)
    local animations = {}

    for key, config in pairs(configs) do
        local path = config[1]
        local frameCount = config[2]
        animations[key] = self:createAnimation(
            self.spritesheets[key],
            200,
            200,
            frameCount,
            0.1
        )
    end

    return animations
end

function Fighter:loadSoundFX(configs)
    local sounds = {}
    for key, filePath in pairs(configs) do
        sounds[key] = SoundManager:loadSound(filePath)
    end
    return sounds
end

function Fighter:createAnimation(image, frameWidth, frameHeight, frameCount, duration)
    if not image then
        print("Error: Image for animation is nil")
        return nil
    end
    local grid = Anim8.newGrid(frameWidth, frameHeight, image:getWidth(), image:getHeight())
    return Anim8.newAnimation(grid('1-' .. frameCount, 1), duration)
end

function Fighter:update(dt, other)
    -- Movement
    self:handleMovement(dt, other)
    self:handleJumping(dt, other)

    -- Attacks
    if not self.isRecovering then
        self:handleAttacks(dt)
    end

    -- Update state
    self:updateState()
    -- Update animation
    self.currentAnimation:update(dt)
end

function Fighter:handleMovement(dt, other)
    local windowWidth = love.graphics.getWidth()

    if self.state == 'attacking' or self.state == 'hit' then
        return
    end

    if love.keyboard.isDown(self.controls.left) then
        self.direction = -1 -- Set direction to left
        local newX = self.x - self.speed * dt
        if newX < 0 then
            newX = 0
        end
        if not self:checkXCollision(newX, self.y, other) then
            self.x = newX
            if not self.isJumping then
                self:setState('run')
            end
        end
    elseif love.keyboard.isDown(self.controls.right) then
        self.direction = 1 -- Set direction to right
        local newX = self.x + self.speed * dt
        if newX + self.width > windowWidth then
            newX = windowWidth - self.width
        end
        if not self:checkXCollision(newX, self.y, other) then
            self.x = newX
            if not self.isJumping then
                self:setState('run')
            end
        end
    elseif not self.isJumping then
        self:setState('idle') -- Set state to idle if no movement keys are pressed
    end

    self.isBlocking = self.direction == other.direction
end


function Fighter:checkXCollision(newX, newY, other)
    return not (newX + self.width <= other.x or
                newX >= other.x + other.width or
                newY + self.height <= other.y or
                newY >= other.y + other.height)
end

function Fighter:handleJumping(dt, other)
    local windowHeight = love.graphics.getHeight()

    -- Update vertical position due to gravity
    self.dy = self.dy + self.gravity * dt
    local newY = self.y + self.dy * dt

    if newY >= windowHeight - self.height then
        self.y = windowHeight - self.height
        self.isJumping = false
        self.dy = 0
        if not love.keyboard.isDown(self.controls.left)
            and not love.keyboard.isDown(self.controls.right)
            and self.state ~= 'attacking'
            and not self.isRecovering
            and self.state ~= 'hit' then
            self:setState('idle')
        end
    elseif not self:checkYCollision(newY, other) then
        self.y = newY
    else
        if self.dy > 0 then
            self.y = other.y - self.height
        else
            self.y = other.y + other.height
        end
        self.dy = 0
        self.isJumping = false
        if self.state == 'jump' then
            self:setState('idle') -- Ensure state is set to idle when landing
        end
    end

    -- Only allow initiating a jump if not in hit, attacking, or recovering state
    if not self.isJumping
        and self.state ~= 'attacking'
        and self.state ~= 'hit'
        and not self.isRecovering
        and love.keyboard.wasPressed(self.controls.jump)
        and self.y >= windowHeight - self.height then
        self.dy = self.jumpStrength
        self.isJumping = true
        self:setState('jump')
        SoundManager:playSound(self.sounds.jump)
    end
end

function Fighter:checkYCollision(newY, other)
    return not (self.x + self.width <= other.x or
                self.x >= other.x + other.width or
                newY + self.height <= other.y or
                newY >= other.y + other.height)
end

function Fighter:handleAttacks(dt)
    if self.state == 'attacking' or self.state == 'hit' or self.isRecovering then
        return -- Prevent new attacks from starting if already attacking or recovering or hit
    end

    if love.keyboard.wasPressed(self.controls.lightAttack) then
        self:startAttack('light')
    elseif love.keyboard.wasPressed(self.controls.mediumAttack) then
        self:startAttack('medium')
    elseif love.keyboard.wasPressed(self.controls.heavyAttack) then
        self:startAttack('heavy')
    end
end

function Fighter:startAttack(attackType)
    self.state = 'attacking'
    self.attackType = attackType
    self.damageApplied = false
    local attackDuration = self.hitboxes[attackType].duration
    self.attackEndTime = love.timer.getTime() + attackDuration
    self.currentAnimation = self.animations[attackType]
    self.currentAnimation:gotoFrame(1)

    -- Calculate the duration of the attack animation
    local totalDuration = self.currentAnimation.totalDuration

    if self.sounds[attackType] then
        -- Delay sound to match halfway through the attack animation duration
        SoundManager:playSound(self.sounds[attackType], { delay = totalDuration / 2 })
    end
end

function Fighter:startRecovery()
    self.state = 'recovering'
    self.recoveryEndTime = love.timer.getTime() + self.hitboxes[self.attackType].recovery
    self.lastAttackType = self.attackType
    self.attackType = nil
    self.currentAnimation = self.animations.idle
    self.isRecovering = true
end

function Fighter:endRecovery()
    if self.state == 'recovering' then
        self.state = 'idle'
    end
    self.isRecovering = false -- garbage code because i don't want to separate state management
    self.currentAnimation = self.animations.idle
end

function Fighter:updateState()
    local currentTime = love.timer.getTime()

    if self.state == 'attacking' and currentTime >= self.attackEndTime then
        self:startRecovery()
    elseif self.isRecovering and currentTime >= self.recoveryEndTime then
        self:endRecovery()
    elseif self.state == 'hit' and currentTime >= self.hitEndTime then
        self:setState('idle')
    end
end


function Fighter:setState(state)
    if self.state ~= state then
        self.state = state
        if self.animations[state] then
            self.currentAnimation = self.animations[state]
        else
            self.currentAnimation = self.animations.idle
        end
    end
end

function Fighter:render()
    print("Rendering fighter", self.id, "with state:", self.state)
    -- Ensure the correct spritesheet is used for the current state
    local spriteName = self.state == 'attacking' and self.attackType or self.state
    local sprite = self.spritesheets[spriteName] or self.spritesheets.idle
    if self.currentAnimation then
        -- Adjust these values to change the size of the sprite
        local scaleX = self.width / 35 * self.direction
        local scaleY = self.height / 80

        -- Ensure the sprite is centered within the rectangle
        local offsetX = (self.width - (200 * scaleX)) / 2
        local offsetY = (self.height - (200 * scaleY)) / 2

        -- Draw the animation with scaling and positioning adjustments
        self.currentAnimation:draw(sprite, self.x + offsetX, self.y + offsetY, 0, scaleX, scaleY)
    else
        print("Error: No current animation to draw for state:", self.state)
    end

    -- Draw debug rectangle
    if isDebug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    end

    if self.state == 'attacking' and self.attackType and isDebug then
        self:renderHitbox()
    end

    -- Draw blocking text
    if self.isBlockingDamage then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Blocked!", self.x - 14, self.y - 20)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

function Fighter:getHitbox()
    local hitbox = self.hitboxes[self.attackType]
    if not hitbox then
        return nil
    end
    local hitboxX = self.direction == 1 and (self.x + self.width) or (self.x - hitbox.width)
    return {
        x = hitboxX,
        y = self.y + (self.height - hitbox.height) / 2,
        width = hitbox.width,
        height = hitbox.height,
        damage = hitbox.damage
    }
end

function Fighter:renderHitbox()
    local hitbox = self.hitboxes[self.attackType]
    local currentTime = love.timer.getTime()

    if currentTime <= self.attackEndTime then
        love.graphics.setColor(1, 0, 0, 1)
        local hitboxX = self.direction == 1 and (self.x + self.width) or (self.x - hitbox.width)
        love.graphics.rectangle('line', hitboxX, self.y + (self.height - hitbox.height) / 2, hitbox.width, hitbox.height)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

function Fighter:isHit(other)
    self.isBlockingDamage = false

    if other.state ~= 'attacking' then
        return false
    end

    local hitbox = other:getHitbox()
    if hitbox and not other.damageApplied then
        if hitbox.x < self.x + self.width and
            hitbox.x + hitbox.width > self.x and
            hitbox.y < self.y + self.height and
            hitbox.y + hitbox.height > self.y then
            if self.isBlocking then
                self.isBlockingDamage = true
                -- Play block sound effect if available
                SoundManager:playSound(self.sounds.block)
                return false
            end
            other.damageApplied = true  -- Mark damage as applied
            return true
        end
    end
    return false
end

function Fighter:takeDamage(damage)
    self.health = self.health - damage
    if self.health <= 0 then
        self.health = 0
        self:setState('death')
    else
        self:setState('hit')

        -- Play hit animation
        self.currentAnimation = self.animations.hit
        self.currentAnimation:gotoFrame(1)

        -- Play hit sound effect if available
        SoundManager:playSound(self.sounds.hit)

        -- Set state back to idle after hit animation duration
        local hitDuration = self.currentAnimation.totalDuration
        self.hitEndTime = love.timer.getTime() + hitDuration
    end
end

return Fighter
