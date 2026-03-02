-- Tutorial Dummy Entity
-- Invulnerable target for tutorial phases; never dies, still shows hit feedback.

local Slime = require("entities.slime")

local TutorialDummy = {}
TutorialDummy.__index = TutorialDummy

setmetatable(TutorialDummy, { __index = Slime })

function TutorialDummy:new(x, y)
    local slime = Slime:new(x, y)
    local dummy = setmetatable({}, TutorialDummy)
    for k, v in pairs(slime) do
        dummy[k] = v
    end
    dummy.isInvulnerable = true
    dummy.isTutorialDummy = true
    return dummy
end

-- Override: stay in place (no chase AI)
function TutorialDummy:update(dt, playerX, playerY)
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    self.knockbackX = self.knockbackX * (1 - (self.knockbackDecay or 12) * dt)
    self.knockbackY = self.knockbackY * (1 - (self.knockbackDecay or 12) * dt)
    self.x = self.x + self.knockbackX * dt
    self.y = self.y + self.knockbackY * dt
end

-- Override: never die; still apply flash and knockback for feedback
function TutorialDummy:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    -- Flash effect
    self.flashTime = self.flashDuration or 0.1

    -- Knockback (reduced)
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = (knockbackForce or 120) * 0.6
            self.knockbackX = (dx / distance) * k
            self.knockbackY = (dy / distance) * k
        end
    end

    -- Never die
    return false
end

return TutorialDummy
