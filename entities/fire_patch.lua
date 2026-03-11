local FirePatch = {}
FirePatch.__index = FirePatch

function FirePatch:new(x, y, radius, damage, duration, tickInterval)
    return setmetatable({
        x = x,
        y = y,
        radius = radius or 42,
        damage = damage or 8,
        duration = duration or 4.0,
        timeRemaining = duration or 4.0,
        tickInterval = tickInterval or 0.35,
        hitTimers = {},
    }, FirePatch)
end

function FirePatch:update(dt)
    self.timeRemaining = self.timeRemaining - dt
    for target, timer in pairs(self.hitTimers) do
        timer = timer - dt
        if timer <= 0 then
            self.hitTimers[target] = nil
        else
            self.hitTimers[target] = timer
        end
    end
end

function FirePatch:isAlive()
    return self.timeRemaining > 0
end

function FirePatch:canHit(target)
    return (self.hitTimers[target] or 0) <= 0
end

function FirePatch:markHit(target)
    self.hitTimers[target] = self.tickInterval
end

function FirePatch:draw()
    if not self:isAlive() then
        return
    end

    local alpha = math.max(0.18, math.min(1, self.timeRemaining / self.duration))
    local pulse = 0.72 + 0.28 * math.sin(love.timer.getTime() * 7 + self.x * 0.02)

    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(1.0, 0.42, 0.10, alpha * 0.18 * pulse)
    love.graphics.circle("fill", self.x, self.y, self.radius + 10)
    love.graphics.setColor(1.0, 0.72, 0.18, alpha * 0.12 * pulse)
    love.graphics.circle("fill", self.x, self.y, self.radius + 3)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(0.95, 0.32, 0.10, alpha * 0.28)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1.0, 0.76, 0.24, alpha * 0.65)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radius - 2)
    for i = 0, 5 do
        local angle = love.timer.getTime() * 2.4 + i * (math.pi * 2 / 6)
        local rx = self.x + math.cos(angle) * self.radius * 0.55
        local ry = self.y + math.sin(angle) * self.radius * 0.40
        love.graphics.rectangle("fill", rx - 1.5, ry - 3, 3, 6)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return FirePatch
