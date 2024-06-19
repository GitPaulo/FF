local Anim8 = require 'lib.anim8'

local Class, love, SoundManager = _G.Class, _G.love, _G.SoundManager
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
    self.hitboxes = hitboxes or {}
    self:validateFighterParameters()

    -- Character State
    self.dy = 0
    self.direction = (id == 2) and -1 or 1 -- Set direction to right for player 1 and left for player 2
    self.state = 'idle'
    self.isBlocking = false
    self.isBlockingDamage = false
    self.isAirborne = false
    self.isDashing = false
    self.isRecovering = false
    self.isClashing = false
    -- Character State: attack
    self.attackType = nil
    self.lastAttackType = nil
    self.attackEndTime = 0
    self.recoveryEndTime = 0
    -- Character State: dash
    self.lastTapTime = {left = 0, right = 0}
    self.dashDuration = 0.25
    self.dashEndTime = 0
    self.dashStaminaCost = 25
    self.deathAnimationFinished = false
    -- Character State: clash
    self.opponentAttackType = nil
    self.opponentAttackEndTime = 0
    self.clashTime = 0
    self.knockbackTargetX = self.x
    self.knockbackSpeed = 400
    self.knockbackActive = false
    self.knockbackDelay = 0.5
    self.knockbackDelayTimer = 0
    -- Character State: hit
    self.hitEndTime = 0
    self.damageApplied = false
    -- Other
    self.gravity = 1000

    -- Animation, Sprites and sound
    self.spritesheets = self:loadSpritesheets(spriteConfig)
    self.animations = self:loadAnimations(spriteConfig)
    self.animationDurations = self:loadAnimationDurations(spriteConfig)
    self.sounds = self:loadSoundFX(soundFXConfig)

    -- Set the default animation to idle
    self.currentAnimation = self.animations.idle

    -- Font
    self.eventFont = love.graphics.newFont(20)
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
        spritesheets[key] = love.graphics.newImage(config.path)
        print(
            'Loaded spritesheet for',
            key,
            'from',
            config.path,
            'with frame count:',
            config.frames,
            'and dimensions:',
            spritesheets[key]:getDimensions()
        )
    end

    return spritesheets
end

function Fighter:loadAnimations(configs)
    local animations = {}

    for key, config in pairs(configs) do
        local path = config.path
        local frameCount = config.frames
        local frameDuration = config.frameDuration
        local spritesheet = self.spritesheets[key]
        local frameWidth = math.floor(spritesheet:getWidth() / frameCount)
        local frameHeight = spritesheet:getHeight()

        animations[key] = self:createAnimation(spritesheet, frameWidth, frameHeight, frameCount, frameDuration)
    end

    return animations
end

function Fighter:loadAnimationDurations(configs)
    local durations = {}
    for stateOrAttack, config in pairs(configs) do
        local totalDuration = 0
        for _, duration in ipairs(config.frameDuration) do
            totalDuration = totalDuration + duration
        end
        durations[stateOrAttack] = totalDuration
    end
    return durations
end

function Fighter:loadSoundFX(configs)
    local sounds = {}
    for key, filePath in pairs(configs) do
        sounds[key] = SoundManager:loadSound(filePath)
    end
    return sounds
end

function Fighter:createAnimation(image, frameWidth, frameHeight, frameCount, frameDuration)
    if not image then
        print('Error: Image for animation is nil')
        return nil
    end
    local grid = Anim8.newGrid(frameWidth, frameHeight, image:getWidth(), image:getHeight())
    return Anim8.newAnimation(grid('1-' .. frameCount, 1), frameDuration)
end

function Fighter:update(dt, other)
    if self.state ~= 'death' then
        -- Handle all actions except death
        self:updateActions(dt, other)
        -- Update the state of the fighter after handling actions
        self:updateState(dt, other)
    else
        -- Handle death animation
        self:checkDeathAnimationFinished()
    end

    -- Always update the current animation
    self.currentAnimation:update(dt)
end

function Fighter:updateActions(dt, other)
    -- Opponent
    self.opponentAttackType = other.attackType
    self.opponentAttackEndTime = other.attackEndTime

    -- Self
    self:handleMovement(dt, other)
    self:handleJumping(dt, other)
    self:handleAttacks()
end

function Fighter:updateState(dt, other)
    local currentTime = love.timer.getTime()
    local isAttacking = self.state == 'attacking'
    local isHit = self.state == 'hit'
    local isRecoveryPeriodOver = currentTime >= self.recoveryEndTime
    local isAttackPeriodOver = currentTime >= self.attackEndTime
    local isHitPeriodOver = currentTime >= self.hitEndTime
    local isIdle = self.state == 'idle'

    -- Check for clash
    if not self.isClashing then
        self:checkForClash(other)
    end

    -- Handle knockback
    if self.knockbackActive or self.knockbackDelayTimer > 0 then
        self:checkForKnockback(dt)
    end

    -- Transition from attacking to recovery if the attack period has ended
    if isAttacking and isAttackPeriodOver then
        self.attackType = nil
        if self.isAirborne then
            self:setState('jump')
        else
            self:setState('idle')
        end

        if not self.isRecovering then
            self:startRecovery()
        end
    end

    -- End recovery period if the recovery time has passed
    if self.isRecovering and isRecoveryPeriodOver then
        self:endRecovery()
    end

    -- Transition from hit to idle if the hit period has ended
    if isHit and isHitPeriodOver then
        self:setState('idle')
    end

    -- Recover stamina if the fighter is idle
    if isIdle then
        self:recoverStamina(dt)
    end
end

function Fighter:handleMovement(dt, other)
    if self.state == 'attacking' or self.state == 'hit' or self.isClashing or self.knockbackActive then
        return
    end

    local windowWidth = love.graphics.getWidth()
    local currentTime = love.timer.getTime()

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
            if not self.isAirborne then
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
            if not self.isAirborne then
                self:setState('run')
            end
        end
    elseif not self.isAirborne then
        self:setState('idle') -- Set state to idle if no movement keys are pressed
    end

    self.isBlocking = self.direction == other.direction
end

function Fighter:startDash(direction)
    if self.id > 2 then
        return -- ai doesn't dash
    end
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
    local groundLevel = windowHeight - 10 -- Define the ground level
    local skyLevel = 0 -- Define the top level (skybox)

    -- Boolean flags for readability
    local isAttacking = self.state == 'attacking'
    local isHit = self.state == 'hit'
    local isRecovering = self.isRecovering
    local isClashing = self.isClashing
    local isAirborne = self.isAirborne
    local isFalling = self.dy > 0
    local isAllowedToJump = not isAirborne and not isAttacking and not isHit and not isRecovering and not isClashing
    local isAllowedToChangeState = not isAttacking and not isHit and not isRecovering and not isClashing

    -- Update vertical position due to gravity
    self.dy = self.dy + self.gravity * dt

    -- Potential new position after applying gravity
    -- REMEMBER: y-axis is inverted in LOVE2D, BIGGER NUMBER = LOWER POSITION
    local newY = self.y + self.dy * dt
    local isOnOrBelowGround = newY >= groundLevel - self.height -- Check if the new position is on the ground

    -- Check for collision with the ground
    if isOnOrBelowGround then
        self.y = groundLevel - self.height
        self.isAirborne = false
        self.dy = 0
        if isAllowedToChangeState then
            if not love.keyboard.isDown(self.controls.left) and not love.keyboard.isDown(self.controls.right) then
                self:setState('idle') -- Set state to idle if no movement keys are pressed
            elseif isFalling then
                self:setState('jump') -- Set state to jump if the fighter is falling
            end
        end
    elseif newY <= skyLevel then
        -- Prevent fighter from moving above the top of the screen
        self.y = skyLevel
        self.dy = 0
    elseif self:checkYCollision(newY, other) then
        -- Check for collision with the other fighter
        if isFalling then
            self.y = other.y - self.height -- Adjust position if colliding while falling
            self.dy = 0
            self.isAirborne = false
        else
            self.y = self.y -- Keep current position if rising
            self.dy = 0
        end

        -- Set state to idle (standing on top)
        if isAllowedToChangeState then
            self:setState('idle') -- Set state to idle if conditions allow
        end
    else
        -- Update position if no collision with the opponent
        self.y = newY
        self.isAirborne = true
    end

    -- Only allow initiating a jump if certain conditions are met
    if isAllowedToJump and love.keyboard.wasPressed(self.controls.jump) then
        self.dy = self.jumpStrength
        self.isAirborne = true
        self:setState('jump')
        -- Play jump sound
        SoundManager:playSound(self.sounds.jump)
    end
end

function Fighter:checkYCollision(newY, other)
    return not (self.x + self.width <= other.x or self.x >= other.x + other.width or newY + self.height < other.y or
        newY > other.y + other.height)
end


function Fighter:handleAttacks()
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
    self.state = 'attacking' -- Don't use self.setState() here
    self.attackType = attackType
    self.lastAttackType = attackType
    self.damageApplied = false

    -- Get the precomputed attack duration
    local attackDuration = self.animationDurations[attackType]
    self.attackEndTime = love.timer.getTime() + attackDuration

    -- Play the attack sound
    if self.sounds[attackType] then
        SoundManager:playSound(self.sounds[attackType])
    end

    -- Set the current animation to the attack animation
    self.currentAnimation = self.animations[attackType]
    self.currentAnimation:gotoFrame(1)
end

function Fighter:startRecovery()
    if _G.isDebug then
        print('Recovery started for', self.id, self.attackType, self.lastAttackType)
    end
    self.recoveryEndTime = love.timer.getTime() + self.hitboxes[self.lastAttackType].recovery
    self.isRecovering = true
end

function Fighter:endRecovery()
    if _G.isDebug then
        print('Recovery ended for', self.id)
    end
    self.isRecovering = false
end

function Fighter:checkForClash(other)
    if self.state == 'attacking' and other.state == 'attacking' and not self.isRecovering and not other.isRecovering then
        local myHitbox = self:getHitbox()
        local opponentHitbox = other:getHitbox()
        if self:checkHitboxOverlap(myHitbox, opponentHitbox) then
            self:resolveClash(other)
        end
    end
end

function Fighter:checkForKnockback(dt)
    if self.knockbackDelayTimer > 0 then
        self.knockbackDelayTimer = self.knockbackDelayTimer - dt
        if self.knockbackDelayTimer <= 0 then
            self.knockbackActive = true -- Activate knockback after delay
        end
        return
    end

    if self.knockbackActive then
        if math.abs(self.x - self.knockbackTargetX) < 1 then
            self.knockbackActive = false -- Stop knockback when close to target
        else
            local knockbackStep = self.knockbackSpeed * dt * self.direction * -1 -- Move in the opposite direction
            if math.abs(knockbackStep) > math.abs(self.knockbackTargetX - self.x) then
                self.x = self.knockbackTargetX -- Directly set to target if overshoot
            else
                self.x = self.x + knockbackStep -- Move incrementally towards target
            end
        end
    end
end

function Fighter:checkHitboxOverlap(hitbox1, hitbox2)
    return hitbox1.x < hitbox2.x + hitbox2.width and hitbox1.x + hitbox1.width > hitbox2.x and
        hitbox1.y < hitbox2.y + hitbox2.height and
        hitbox1.y + hitbox1.height > hitbox2.y
end

function Fighter:resolveClash(other)
    local currentTime = love.timer.getTime()

    -- Both fighters lose stamina during clash
    self.stamina = math.max(self.stamina - 10, 0)
    other.stamina = math.max(other.stamina - 10, 0)

    -- If both fighters have no stamina, no clash happens
    if self.stamina == 0 and other.stamina == 0 then
        self.isClashing = false
        other.isClashing = false
        return
    end

    if self.attackType == other.attackType then
        -- Both attacks are of the same type, both fighters are knocked back
        self:applyKnockback()
        other:applyKnockback()
        self.isClashing = true
        other.isClashing = true
        self.clashTime = currentTime
        other.clashTime = currentTime
    else
        -- Different attack types, the heavier one wins
        local myAttackWeight = self:getAttackWeight(self.attackType)
        local opponentAttackWeight = self:getAttackWeight(other.attackType)

        -- However if one of the fighters has no stamina, the other wins
        if myAttackWeight > opponentAttackWeight or other.stamina == 0 then
            self:winClash(other)
        elseif opponentAttackWeight > myAttackWeight or self.stamina == 0 then
            other:winClash(self)
        end

        self.isClashing = true
        other.isClashing = true
        self.clashTime = currentTime
        other.clashTime = currentTime
    end
end

function Fighter:getAttackWeight(attackType)
    local weights = {
        light = 1,
        medium = 2,
        heavy = 3
    }
    return weights[attackType] or 0
end

function Fighter:applyKnockback()
    local baseKnockbackDelay = self.knockbackDelay
    local attackType = self.attackType or 'light'

    -- Adjust knockback delay based on the attack type
    if attackType == 'medium' then
        baseKnockbackDelay = baseKnockbackDelay + 0.2
    elseif attackType == 'heavy' then
        baseKnockbackDelay = baseKnockbackDelay + 0.4
    end

    self.knockbackTargetX = self.x + (self.direction * -100) -- Set the target position for knockback
    self.knockbackActive = false -- Knockback will be active after delay
    self.knockbackDelayTimer = baseKnockbackDelay -- Set the delay timer
end

function Fighter:winClash(loser)
    loser:takeDamage(self.hitboxes[loser.attackType].damage / 2) -- Half damage
    loser:applyKnockback()
    loser:setState('idle')
    self:setState('idle')
end

function Fighter:setState(newState)
    -- Only change state if the new state is different from the current state
    if self.state == newState then
        return
    end
    self.state = newState

    -- Determine the appropriate animation for the new state
    local newAnimation = self.animations[newState] or self.animations.idle
    self.currentAnimation = newAnimation
    self.currentAnimation:gotoFrame(1)
end

function Fighter:render(other)
    -- Sprite config list includes states and attack types as key for animations
    -- self.attackType gets cleared on recovery start
    local spriteName = self.state == 'attacking' and self.lastAttackType or self.state
    local sprite = self.spritesheets[spriteName] or self.spritesheets.idle

    if _G.isDebug and self.id == 1 then
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
            self.attackType,
            'isRecovering:',
            self.isRecovering,
            'isClashing:',
            self.isClashing,
            'isKnockbackActive:',
            self.knockbackActive
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

        if _G.isDebug and self.id == 1 then
            print(self.scale.ox, self.scale.oy, posX, posY)
            print('[Sprite]:', posX, posY, '<- pos, scale ->', scaleX, scaleY)
        end
    else
        print('Error: No current animation to draw for state:', self.state)
    end

    -- Draw debug rectangle with dot
    -- Characters are really just a rectangle and the sprite gets centered inside it
    if _G.isDebug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 0, 0, 1) -- Red color for the debug dot
        love.graphics.circle('fill', self.x, self.y, 5) -- Draw a small circle (dot) at (self.x, self.y)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    if self.state == 'attacking' and self.attackType and _G.isDebug then
        self:renderHitbox()
    end

    -- Draw blocking text
    if self.isBlockingDamage then
        love.graphics.setFont(self.eventFont)
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print('Blocked!', self.x - 14, self.y - 20)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- Draw clashing
    local currentTime = love.timer.getTime()
    if self.isClashing and currentTime - self.clashTime < 1 then -- Display for 1 second
        love.graphics.setFont(self.eventFont)
        love.graphics.setColor(1, 1, 0, 1)
        local clashX = (self.x + other.x) / 2
        local clashY = math.min(self.y, other.y) - 20
        love.graphics.printf('Clash!', clashX - 50, clashY, 100, 'center')
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    else
        self.isClashing = false
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
