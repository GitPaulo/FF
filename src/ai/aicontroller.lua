local AIController = {}

function AIController:new(fighter, opponent)
    local ai = {}
    setmetatable(ai, self)
    self.__index = self
    ai.fighter = fighter
    ai.opponent = opponent
    return ai
end

function AIController:update(dt)
    -- Basic decision-making logic
    local fighter = self.fighter
    local opponent = self.opponent

    -- Example: Move towards the opponent
    if fighter.x < opponent.x then
        love.keyboard.keysPressed[fighter.controls.right] = true
    else
        love.keyboard.keysPressed[fighter.controls.left] = true
    end

    -- Example: Jump if close to the opponent
    if math.abs(fighter.x - opponent.x) < 100 then
        love.keyboard.keysPressed[fighter.controls.jump] = true
    end

    -- Example: Attack if in range
    if math.abs(fighter.x - opponent.x) < 50 then
        love.keyboard.keysPressed[fighter.controls.lightAttack] = true
    end
end

return AIController
