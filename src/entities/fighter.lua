local Anim8 = require 'lib.anim8'

local Class, love, SoundManager, isDebug = _G.Class, _G.love, _G.SoundManager, _G.isDebug
local Fighter = Class:extend()

function Fighter:init(id, name, startingX, startingY, scale, controls, traits, hitboxes, spriteConfig, soundFXConfig)
    -- Character Properties
    self.id = id
    self.name = name
    self.x = startingX
    self.y = startingY
    self.scale = scale
    self.width = scale.width
    self.height = scale.height
    self.controls = controls
    self.speed = traits.speed or 200
    self.health = traits.health or 100
    self.maxHealth = traits.health or 100
    self.stamina = traits.stamina or 100
    self.maxStamina = traits.stamina or 100
    self.jumpStrength = -(traits.jumpStrength or 600)
    self.dashSpeed = traits.dashSpeed or 500
    self.hitboxes =
        hitboxes or
        {
            light = {width = 100, height = 20, recovery = 0.5, damage = 5},
            medium = {width = 150, height = 30, recovery = 0.7, damage = 10},
            heavy = {width = 200, height = 40, recovery = 1.0, damage = 20}
        }

    -- Helps a lot
    self:validateFighterParameters()

    -- Character State
    self.dy = 0
    self.direction = (id == 2) and -1 or 1 -- Set direction to right for player 1 and left for player 2
    self.state = 'idle'
    self.gravity = 1000
    self.attackType = nil
    self.lastAttackType = nil
    self.attackEndTime = 0
    self.recoveryEndTime = 0
    self.hitEndTime = 0
    self.damageApplied = false
    self.isBlocking = false
    self.isBlockingDamage = false
    self.isJumping = false
    self.isDashing = false
    self.lastTapTime = {left = 0, right = 0}
    self.dashDuration = 0.25
    self.dashEndTime = 0
    self.dashStaminaCost = 25
    self.deathAnimationFinished = false

    -- Animation and Sprites
    self.spritesheets = self:loadSpritesheets(spriteConfig)
    self.animations = self:loadAnimations(spriteConfig)
    self.sounds = self:loadSoundFX(soundFXConfig)

    self.currentAnimation = self.animations.idle
end

function Fighter:validateFighterParameters()
    assert(self.id, 'ID must be defined for fighter')
    assert(self.name, 'Name must be defined for fighter')
    assert(self.x, 'Starting X position must be defined for fighter')
    assert(self.y, 'Starting Y position must be defined for fighter')
    assert(self.scale, 'Scale must be defined for fighter')
    assert(self.width, 'Width must be defined for fighter')
    assert(self.height, 'Height must be defined for fighter')
    assert(self.controls, 'Controls must be defined for fighter')

    for attackType, hitbox in pairs(self.hitboxes) do
        assert(hitbox.width, 'Width must be defined for hitbox: ' .. attackType)
        assert(hitbox.height, 'Height must be defined for hitbox: ' .. attackType)
        assert(hitbox.recovery, 'Recovery time must be defined for hitbox: ' .. attackType)
        assert(hitbox.damage, 'Damage must be defined for hitbox: ' .. attackType)
    end
end

function Fighter:loadSpritesheets(configs)
    local spritesheets = {}

    for key, config in pairs(configs) do
        spritesheets[key] = love.graphics.newImage(config[1])
        print(
            'Loaded spritesheet for',
            key,
            'from',
            config[1],
            'with frame count:',
            config[2],
            'and dimensions:',
            spritesheets[key]:getDimensions()
        )
    end

    return spritesheets
end

function Fighter:loadAnimations(configs)
    local animations = {}

    for key, config in pairs(configs) do
        local path = config[1]
        local frameCount = config[2]
        local spritesheet = self.spritesheets[key]
        local frameWidth = math.floor(spritesheet:getWidth() / frameCount)
        local frameHeight = spritesheet:getHeight()

        animations[key] = self:createAnimation(spritesheet, frameWidth, frameHeight, frameCount, 0.1)
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
        print('Error: Image for animation is nil')
        return nil
    end
    local grid = Anim8.newGrid(frameWidth, frameHeight, image:getWidth(), image:getHeight())
    return Anim8.newAnimation(grid('1-' .. frameCount, 1), duration)
end

function Fighter:update(dt, other)
    if self.state ~= 'death' then
        -- Movement
        self:handleMovement(dt, other)
        self:handleJumping(dt, other)

        -- Attacks
        if not self.isRecovering then
            self:handleAttacks(dt)
        end

        -- Update state
        self:updateState()
        -- Recover stamina if idle
        self:recoverStamina(dt)
    else
        -- Check if the death animation is complete
        self:checkDeathAnimationFinished()
    end

    -- Always update animation
    self.currentAnimation:update(dt)
end

function Fighter:handleMovement(dt, other)
    local windowWidth = love.graphics.getWidth()
    local currentTime = love.timer.getTime()

    if self.state == 'attacking' or self.state == 'hit' then
        return
    end

    -- Handle dashing
    if self.isDashing then
        if currentTime < self.dashEndTime then
            local dashSpeed = self.direction * self.dashSpeed * dt
            local newX = self.x + dashSpeed
            if newX < 0 then
                newX = 0
            elseif newX + self.width > windowWidth then
                newX = windowWidth - self.width
            end
            if not self:checkXCollision(newX, self.y, other) then
                self.x = newX
            end
            return -- Exit movement handling while dashing
        else
            self.isDashing = false
        end
    end

    -- Detect double-tap for dashing
    if love.keyboard.wasPressed(self.controls.left) then
        if currentTime - (self.lastTapTime.left or 0) < 0.3 then
            self:startDash(-1)
        end
        self.lastTapTime.left = currentTime
    elseif love.keyboard.wasPressed(self.controls.right) then
        if currentTime - (self.lastTapTime.right or 0) < 0.3 then
            self:startDash(1)
        end
        self.lastTapTime.right = currentTime
    end

    -- Handle normal movement
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

function Fighter:startDash(direction)
    if self.stamina >= self.dashStaminaCost then
        self.isDashing = true
        self.direction = direction
        self.dashEndTime = love.timer.getTime() + self.dashDuration
        self.stamina = self.stamina - self.dashStaminaCost -- Consume stamina
        -- play sound
        SoundManager:playSound(self.sounds.dash)
    end
end

function Fighter:recoverStamina(dt)
    if self.state == 'idle' and self.stamina < self.maxStamina then
        self.stamina = self.stamina + self.dashStaminaCost * dt
        if self.stamina > self.maxStamina then
            self.stamina = self.maxStamina
        end
    end
end

function Fighter:checkXCollision(newX, newY, other)
    return not (newX + self.width <= other.x or newX >= other.x + other.width or newY + self.height <= other.y or
        newY >= other.y + other.height)
end

function Fighter:handleJumping(dt, other)
    local windowHeight = love.graphics.getHeight()
    local groundLevel = windowHeight - 10 -- from the bottom

    -- Update vertical position due to gravity
    self.dy = self.dy + self.gravity * dt
    local newY = self.y + self.dy * dt

    if newY >= groundLevel - self.height then
        self.y = groundLevel - self.height
        self.isJumping = false
        self.dy = 0
        if
            not love.keyboard.isDown(self.controls.left) and not love.keyboard.isDown(self.controls.right) and
                self.state ~= 'attacking' and
                not self.isRecovering and
                self.state ~= 'hit'
         then
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
    if
        not self.isJumping and self.state ~= 'attacking' and self.state ~= 'hit' and not self.isRecovering and
            love.keyboard.wasPressed(self.controls.jump) and
            self.y >= groundLevel - self.height
     then
        self.dy = self.jumpStrength
        self.isJumping = true
        self:setState('jump')
        SoundManager:playSound(self.sounds.jump)
    end
end

function Fighter:checkYCollision(newY, other)
    return not (self.x + self.width <= other.x or self.x >= other.x + other.width or newY + self.height <= other.y or
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
        SoundManager:playSound(self.sounds[attackType], {delay = totalDuration / 2})
    end
end

function Fighter:startRecovery()
    self.state = 'recovering'
    self.recoveryEndTime = love.timer.getTime() + self.hitboxes[self.attackType].recovery
    self.lastAttackType = self.attackType
    self.attackType = nil
    self.currentAnimation = self.animations.idle
    self.currentAnimation:gotoFrame(1)
    self.isRecovering = true
end

function Fighter:endRecovery()
    if self.state == 'recovering' then
        self.state = 'idle'
    end
    self.isRecovering = false -- garbage code because i don't want to separate state management
    self.currentAnimation = self.animations.idle
    self.currentAnimation:gotoFrame(1)
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
        self.currentAnimation:gotoFrame(1)
    end
end

function Fighter:render()
    -- Ensure the correct spritesheet is used for the current state
    local spriteName = self.state == 'attacking' and self.attackType or self.state
    local sprite = self.spritesheets[spriteName] or self.spritesheets.idle

    if isDebug and self.id == 1 then
        print(
            '[Fighter ' .. self.id .. ']:',
            spriteName,
            'x',
            self.x,
            'y',
            self.y,
            'state:',
            self.state,
            'attackType:',
            self.attackType
        )
    end

    if self.currentAnimation then
        -- Frame dimensions
        local frameWidth = self.currentAnimation:getDimensions()
        local frameHeight = self.currentAnimation:getDimensions()

        -- Adjust these values to change the size of the sprite
        local scaleX = self.scale.x * self.direction
        local scaleY = self.scale.y

        -- Ensure the sprite is centered within the rectangle
        local offsetX = (self.width - (frameWidth * scaleX)) / 2
        local offsetY = (self.height - (frameHeight * scaleY)) / 2

        -- Draw the animation with scaling and positioning adjustments
        local angle = 0
        local posX = self.x + offsetX + (self.scale.ox * self.direction)
        local posY = self.y + offsetY + self.scale.oy
        self.currentAnimation:draw(sprite, posX, posY, angle, scaleX, scaleY)

        if isDebug and self.id == 1 then
            print(self.scale.ox, self.scale.oy, posX, posY)
            print('[Sprite]:', posX, posY, '<- pos, scale ->', scaleX, scaleY)
        end
    else
        print('Error: No current animation to draw for state:', self.state)
    end

    -- Draw debug rectangle with dot
    -- Characters are really just a rectangle and the sprite gets centered inside it
    if isDebug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 0, 0, 1) -- Red color for the debug dot
        love.graphics.circle('fill', self.x, self.y, 5) -- Draw a small circle (dot) at (self.x, self.y)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    if self.state == 'attacking' and self.attackType and isDebug then
        self:renderHitbox()
    end

    -- Draw blocking text
    if self.isBlockingDamage then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print('Blocked!', self.x - 14, self.y - 20)
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
        love.graphics.rectangle(
            'line',
            hitboxX,
            self.y + (self.height - hitbox.height) / 2,
            hitbox.width,
            hitbox.height
        )
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
        if
            hitbox.x < self.x + self.width and hitbox.x + hitbox.width > self.x and hitbox.y < self.y + self.height and
                hitbox.y + hitbox.height > self.y
         then
            if self.isBlocking then
                self.isBlockingDamage = true
                -- Play block sound effect if available
                SoundManager:playSound(self.sounds.block)
                return false
            end
            other.damageApplied = true -- Mark damage as applied
            return true
        end
    end
    return false
end

function Fighter:takeDamage(damage)
    self.health = self.health - damage
    if self.health <= 0 then
        -- Dead
        self.health = 0
        self:setState('death')

        -- Play death animation
        self.currentAnimation = self.animations.death
        self.currentAnimation:gotoFrame(1)

        -- Play death sound
        SoundManager:playSound(self.sounds.death)

        -- Set the start time for the death animation
        self.deathAnimationStartTime = love.timer.getTime()
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

function Fighter:checkDeathAnimationFinished()
    if self.state == 'death' then
        local currentTime = love.timer.getTime()
        local elapsedTime = currentTime - self.deathAnimationStartTime
        local deathDuration = self.currentAnimation.totalDuration
        local padding = 0.2 -- make it a little longer to look better

        if elapsedTime >= deathDuration + padding then
            self.deathAnimationFinished = true
        end
    end
end

return Fighter
