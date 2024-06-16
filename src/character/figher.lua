local Fighter = Class:extend()

function Fighter:init(id, x, y, controls, hitboxes, attackDurations, speed)
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

    self.state = 'idle'  -- Possible states: idle, attacking, recovering
    self.attackType = nil
    self.attackEndTime = 0
    self.recoveryEndTime = 0
    self.damageApplied = false  -- Track if damage has been applied for the current attack

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
end

function Fighter:validateHitboxes()
    for attackType, hitbox in pairs(self.hitboxes) do
        assert(hitbox.width, "Width must be defined for hitbox: " .. attackType)
        assert(hitbox.height, "Height must be defined for hitbox: " .. attackType)
        assert(hitbox.recovery, "Recovery time must be defined for hitbox: " .. attackType)
        assert(hitbox.damage, "Damage must be defined for hitbox: " .. attackType)
    end
end

function Fighter:update(dt)
    self:handleMovement(dt)
    self:handleJumping(dt)
    self:handleAttacks(dt)
end

function Fighter:handleMovement(dt)
    if love.keyboard.isDown(self.controls.left) then
        self.x = self.x - self.speed * dt
    end
    if love.keyboard.isDown(self.controls.right) then
        self.x = self.x + self.speed * dt
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
        end
    elseif love.keyboard.isDown(self.controls.jump) then
        self.dy = self.jumpStrength
        self.isJumping = true
    end
end

function Fighter:handleAttacks(dt)
    -- Handle attack initiation
    if self.state == 'idle' then
        if love.keyboard.wasPressed(self.controls.lightAttack) then
            self:startAttack('light')
        elseif love.keyboard.wasPressed(self.controls.mediumAttack) then
            self:startAttack('medium')
        elseif love.keyboard.wasPressed(self.controls.heavyAttack) then
            self:startAttack('heavy')
        end
    end

    -- Update attack and recovery states
    local currentTime = love.timer.getTime()
    if self.state == 'attacking' and currentTime >= self.attackEndTime then
        self:startRecovery()
    elseif self.state == 'recovering' and currentTime >= self.recoveryEndTime then
        self:endRecovery()
    end
end

function Fighter:startAttack(attackType)
    self.state = 'attacking'
    self.attackType = attackType
    self.damageApplied = false  -- Reset damage applied flag
    local attackDuration = self.attackDurations[attackType].duration
    self.attackEndTime = love.timer.getTime() + attackDuration
end

function Fighter:startRecovery()
    self.state = 'recovering'
    self.recoveryEndTime = love.timer.getTime() + self.hitboxes[self.attackType].recovery
    self.attackType = nil
end

function Fighter:endRecovery()
    self.state = 'idle'
end

function Fighter:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)

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
    end
end

return Fighter
