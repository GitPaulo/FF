local Fighter = Class:extend()

function Fighter:init(id, x, y, controls)
    self.id = id
    self.x = x
    self.y = y
    self.width = 50
    self.height = 100
    self.speed = 200
    self.controls = controls
    self.dy = 0
    self.jumpStrength = -400
    self.gravity = 1000
    self.isJumping = false
end

function Fighter:update(dt)
    if love.keyboard.isDown(self.controls.left) then
        self.x = self.x - self.speed * dt
    end
    if love.keyboard.isDown(self.controls.right) then
        self.x = self.x + self.speed * dt
    end
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

function Fighter:render()
    print("Rendering", self.id, "at", self.x, self.y, self.width, self.height)
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end

return Fighter