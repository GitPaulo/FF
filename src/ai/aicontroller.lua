local love = _G.love
local AIController = {}

function AIController:new(fighter, opponent)
    local ai = {}
    setmetatable(ai, self)
    self.__index = self
    ai.fighter = fighter
    ai.opponent = opponent
    ai.state = 'idle'
    ai.jumpCooldown = 0
    return ai
end

function AIController:update(dt)
    local fighter = self.fighter
    local opponent = self.opponent

    -- Cooldown to prevent constant jumping
    if self.jumpCooldown > 0 then
        self.jumpCooldown = self.jumpCooldown - dt
    end

    local distance = math.abs(fighter.x - opponent.x)
    print(distance)

    -- Determine action based on distance
    if distance < 100 then
        self:attack()
    elseif distance < 200 and self.jumpCooldown <= 0 then
        self:jump()
    else
        self:moveTowardsOpponent()
    end

    -- Turn around to face the opponent
    if fighter.x < opponent.x then
        fighter.direction = 1
    else
        fighter.direction = -1
    end
end

function AIController:moveTowardsOpponent()
    local fighter = self.fighter
    local opponent = self.opponent

    if fighter.x < opponent.x then
        love.keyboard.setKeyState(fighter.controls.right, true)
        love.keyboard.setKeyState(fighter.controls.left, false)
    else
        love.keyboard.setKeyState(fighter.controls.left, true)
        love.keyboard.setKeyState(fighter.controls.right, false)
    end

    -- Ensure the AI stops movement if close enough
    if math.abs(fighter.x - opponent.x) < 50 then
        love.keyboard.setKeyState(fighter.controls.right, false)
        love.keyboard.setKeyState(fighter.controls.left, false)
    end

    print("AI moving towards opponent")
end

function AIController:jump()
    local fighter = self.fighter
    love.keyboard.setKeyState(fighter.controls.jump, true)
    self.jumpCooldown = 1.0 -- 1 second cooldown
    print("AI jumping")
end

function AIController:attack()
    local fighter = self.fighter
    -- TODO improve
    if not fighter.state ~= 'attacking' then
        fighter:startAttack('light')
    end
    print("AI attacking")
end

return AIController
