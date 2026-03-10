local SpellbladeArcaneSwords = {}
SpellbladeArcaneSwords.__index = SpellbladeArcaneSwords

function SpellbladeArcaneSwords:new(config)
    return setmetatable({
        swordCount = config.swordCount or 3,
        orbitRadius = config.orbitRadius or 48,
        orbitSpeed = config.orbitSpeed or 2.6,
        damage = config.damage or 10,
        duration = config.duration or 5,
        timeRemaining = config.duration or 5,
        hitInterval = config.hitInterval or 0.25,
        swordSize = config.swordSize or 16,
        color = config.color or {0.55, 0.9, 1.0},
        rotation = 0,
        hitTimers = {},
    }, SpellbladeArcaneSwords)
end

function SpellbladeArcaneSwords:update(dt)
    self.timeRemaining = self.timeRemaining - dt
    self.rotation = self.rotation + dt * self.orbitSpeed
end

function SpellbladeArcaneSwords:isAlive()
    return self.timeRemaining > 0
end

function SpellbladeArcaneSwords:getSwordPositions(player)
    local positions = {}
    if not player then
        return positions
    end

    for i = 1, self.swordCount do
        local angle = self.rotation + (i - 1) * ((math.pi * 2) / self.swordCount)
        positions[i] = {
            x = player.x + math.cos(angle) * self.orbitRadius,
            y = player.y + math.sin(angle) * self.orbitRadius,
            angle = angle,
        }
    end

    return positions
end

function SpellbladeArcaneSwords:canHit(target)
    return (self.hitTimers[target] or 0) <= 0
end

function SpellbladeArcaneSwords:markHit(target)
    self.hitTimers[target] = self.hitInterval
end

function SpellbladeArcaneSwords:tickHitTimers(dt)
    for target, timer in pairs(self.hitTimers) do
        timer = timer - dt
        if timer <= 0 then
            self.hitTimers[target] = nil
        else
            self.hitTimers[target] = timer
        end
    end
end

function SpellbladeArcaneSwords:draw(player)
    if not self:isAlive() or not player then
        return
    end

    local color = self.color
    for _, sword in ipairs(self:getSwordPositions(player)) do
        love.graphics.push()
        love.graphics.translate(sword.x, sword.y)
        love.graphics.rotate(sword.angle + math.pi * 0.5)

        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(color[1], color[2], color[3], 0.18)
        love.graphics.rectangle("fill", -self.swordSize * 0.35, -self.swordSize * 0.9, self.swordSize * 0.7, self.swordSize * 1.8, 4, 4)
        love.graphics.setBlendMode("alpha")

        love.graphics.setColor(color[1], color[2], color[3], 0.95)
        love.graphics.rectangle("fill", -self.swordSize * 0.18, -self.swordSize * 0.72, self.swordSize * 0.36, self.swordSize * 1.28, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", -self.swordSize * 0.08, -self.swordSize * 0.56, self.swordSize * 0.16, self.swordSize * 0.9, 2, 2)
        love.graphics.setColor(0.96, 0.86, 1.0, 0.9)
        love.graphics.rectangle("fill", -self.swordSize * 0.32, self.swordSize * 0.32, self.swordSize * 0.64, self.swordSize * 0.16, 2, 2)

        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return SpellbladeArcaneSwords
