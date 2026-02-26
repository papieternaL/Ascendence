-- Bark Volley AOE
-- Circular telegraphed zone near player; detonates after windup and deals damage

local BarkVolleyAOE = {}
BarkVolleyAOE.__index = BarkVolleyAOE

function BarkVolleyAOE:new(centerX, centerY, radius, damage, telegraphDuration, impactDuration)
    local aoe = {
        x = centerX,
        y = centerY,
        radius = radius or 55,
        damage = damage or 25,
        telegraphDuration = telegraphDuration or 0.9,
        impactDuration = impactDuration or 0.25,

        state = "telegraph",
        telegraphTimer = 0,
        impactTimer = 0,
        isFinished = false,
    }
    setmetatable(aoe, BarkVolleyAOE)
    return aoe
end

function BarkVolleyAOE:update(dt)
    if self.isFinished then return end

    if self.state == "telegraph" then
        self.telegraphTimer = self.telegraphTimer + dt
        if self.telegraphTimer >= self.telegraphDuration then
            self.state = "impact"
            self.impactTimer = 0
        end
    elseif self.state == "impact" then
        self.impactTimer = self.impactTimer + dt
        if self.impactTimer >= self.impactDuration then
            self.state = "finished"
            self.isFinished = true
        end
    end
end

function BarkVolleyAOE:draw()
    if self.isFinished then return end

    if self.state == "telegraph" then
        local pulse = math.sin(self.telegraphTimer * 12) * 0.25 + 0.75
        local alpha = math.min(1.0, self.telegraphTimer / 0.2)

        love.graphics.setColor(0.8, 0.4, 0.1, 0.25 * alpha * pulse)
        love.graphics.circle("fill", self.x, self.y, self.radius * 1.2)

        love.graphics.setColor(0.9, 0.5, 0.15, 0.5 * alpha * pulse)
        love.graphics.circle("fill", self.x, self.y, self.radius)

        love.graphics.setColor(1, 0.6, 0.2, 0.9 * alpha * pulse)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", self.x, self.y, self.radius)
        love.graphics.setLineWidth(1)
    elseif self.state == "impact" then
        local progress = self.impactTimer / self.impactDuration
        local ringRadius = self.radius * (1 + progress * 0.5)
        local alpha = 1 - progress

        love.graphics.setColor(1, 0.5, 0.2, alpha * 0.6)
        love.graphics.circle("fill", self.x, self.y, ringRadius)
        love.graphics.setColor(1, 0.7, 0.3, alpha * 0.9)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", self.x, self.y, ringRadius)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function BarkVolleyAOE:isPlayerInDanger(px, py)
    if self.state ~= "impact" then return false end
    local dx = px - self.x
    local dy = py - self.y
    return (dx * dx + dy * dy) <= (self.radius * self.radius)
end

function BarkVolleyAOE:getDamage()
    return self.damage
end

function BarkVolleyAOE:isInImpactPhase()
    return self.state == "impact" and self.impactTimer < 0.12
end

return BarkVolleyAOE
