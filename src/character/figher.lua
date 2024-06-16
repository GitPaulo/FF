local Anim8 = require 'lib.anim8'
local Fighter = Class:extend()

function Fighter:init(id, x, y, controls, hitboxes, attackDurations, speed, spriteConfigs)
    self.id = id
    self.x = x
    self.y = y
    self.width = 50
    self.height = 100
    self.speed = speed or 200
    self.controls = controls
    self.dy = 0
    self.jumpStrength = -400
    self.gravity = 1000
    self.isJumping = false
    self.health = 100  -- Initial health for the fighter

    self.state = 'idle'  -- Possible states: idle, attacking, recovering, running, jumping, falling, hit, dead
    self.attackType = nil
    self.attackEndTime = 0
    self.recoveryEndTime = 0
    self.damageApplied = false  -- Track if damage has been applied for the current attack

    self.direction = (id == 2) and -1 or 1  -- Fighter 2 faces the other way

    self.hitboxes = hitboxes or {
        light = {width = 100, height = 20, recovery = 0.5, damage = 5},
        medium = {width = 150, height = 30, recovery = 0.7, damage = 10},
        heavy = {width = 200, height = 40, recovery = 1.0, damage = 20}
    }

    self.attackDurations = attackDurations or {
        light = {duration = 0.3, animationTime = 0.15},
        medium = {duration = 0.8, animationTime = 0.4},
        heavy = {duration = 1.5, animationTime = 0.75}
    }

    self:validateHitboxes()

    -- Load spritesheets and set up animations
    self.spritesheets = self:loadSpritesheets(spriteConfigs)
    self.animations = self:loadAnimations(spriteConfigs)
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
        print("Loaded spritesheet for", key, "from", config[1])
    end

    return spritesheets
end

function Fighter:loadAnimations(configs)
    local animations = {}

    for key, config in pairs(configs) do
        local path = config[1]
        local frameCount = config[2]
        animations[key] = self:createAnimation(self.spritesheets[key], 200, 200, frameCount, 0.1)
    end

    return animations
end

function Fighter:createAnimation(image, frameWidth, frameHeight, frameCount, duration)
    if not image then
        print("Error: Image for animation is nil")
        return nil
    end
    local grid = Anim8.newGrid(frameWidth, frameHeight, image:getWidth(), image:getHeight())
    return Anim8.newAnimation(grid('1-' .. frameCount, 1), duration)
end

function Fighter:update(dt)
    if self.state ~= 'attacking' and self.state ~= 'recovering' then
        self:handleMovement(dt)
        self:handleJumping(dt)
        self:handleAttacks(dt)
    end

    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end

    self:updateState()
end

function Fighter:handleMovement(dt)
    if love.keyboard.isDown(self.controls.left) then
        self.x = self.x - self.speed * dt
        if not self.isJumping then
            self:setState('run')
        end
    elseif love.keyboard.isDown(self.controls.right) then
        self.x = self.x + self.speed * dt
        if not self.isJumping then
            self:setState('run')
        end
    elseif not self.isJumping then
        self:setState('idle')
    end
end

function Fighter:handleJumping(dt)
    if self.isJumping then
        self.dy = self.dy + self.gravity * dt
        self.y = self.y + self.dy * dt
        if self.y >= 200 then -- assuming 200 is the ground level
            self.y = 200
            self.isJumping = false
            self.dy = 0
            self:setState('idle')
        end
    elseif love.keyboard.wasPressed(self.controls.jump) then
        self.dy = self.jumpStrength
        self.isJumping = true
        self:setState('jump')
    end
end

function Fighter:handleAttacks(dt)
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
    self.damageApplied = false  -- Reset damage applied flag
    local attackDuration = self.attackDurations[attackType].duration
    self.attackEndTime = love.timer.getTime() + attackDuration
    self.currentAnimation = self.animations[attackType]
end

function Fighter:startRecovery()
    self.state = 'recovering'
    self.recoveryEndTime = love.timer.getTime() + self.hitboxes[self.attackType].recovery
    self.attackType = nil
    self.currentAnimation = self.animations.idle
end

function Fighter:endRecovery()
    self.state = 'idle'
    self.currentAnimation = self.animations.idle
end

function Fighter:updateState()
    local currentTime = love.timer.getTime()
    if self.state == 'attacking' and currentTime >= self.attackEndTime then
        self:startRecovery()
    elseif self.state == 'recovering' and currentTime >= self.recoveryEndTime then
        self:endRecovery()
    end
end

function Fighter:setState(state)
    if self.state ~= state then
        self.state = state
        self.currentAnimation = self.animations[state] or self.animations.idle
        if self.currentAnimation then
            self.currentAnimation:gotoFrame(1)
        end
    end
end

function Fighter:render()
    -- Ensure the correct spritesheet is used for the current state
    local spritesheet = self.spritesheets[self.state] or self.spritesheets.idle
    print("Rendering state:", self.state, "using spritesheet:", spritesheet)
    if self.currentAnimation then
        -- Adjust these values to change the size of the sprite
        local scaleX = self.width / 35 * self.direction
        local scaleY = self.height / 80

        -- Ensure the sprite is centered within the rectangle
        local offsetX = (self.width - (200 * scaleX)) / 2
        local offsetY = (self.height - (200 * scaleY)) / 2

        -- Draw the animation with scaling and positioning adjustments
        self.currentAnimation:draw(spritesheet, self.x + offsetX, self.y + offsetY, 0, scaleX, scaleY)
    else
        print("Error: No current animation to draw for state:", self.state)
    end

    -- Draw debug rectangle
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)

    if self.state == 'attacking' and self.attackType then
        self:renderHitbox()
    end
end

function Fighter:renderHitbox()
    local hitbox = self.hitboxes[self.attackType]
    local animationTime = self.attackDurations[self.attackType].animationTime
    local currentTime = love.timer.getTime()

    if currentTime <= self.attackEndTime - (self.attackDurations[self.attackType].duration - animationTime) then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle('line', self.x + self.width, self.y + (self.height - hitbox.height) / 2, hitbox.width, hitbox.height)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

function Fighter:getHitbox()
    if self.state == 'attacking' and self.attackType then
        local hitbox = self.hitboxes[self.attackType]
        local animationTime = self.attackDurations[self.attackType].animationTime
        local currentTime = love.timer.getTime()

        if currentTime <= self.attackEndTime - (self.attackDurations[self.attackType].duration - animationTime) then
            return {
                x = self.x + self.width,
                y = self.y + (self.height - hitbox.height) / 2,
                width = hitbox.width,
                height = hitbox.height,
                damage = hitbox.damage
            }
        end
    end
    return nil
end

function Fighter:isHit(other)
    local hitbox = self:getHitbox()
    if hitbox and not self.damageApplied then
        if hitbox.x < other.x + other.width and
           hitbox.x + hitbox.width > other.x and
           hitbox.y < other.y + other.height and
           hitbox.y + hitbox.height > other.y then
            self.damageApplied = true  -- Mark damage as applied
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
    end
end

return Fighter