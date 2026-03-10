local SpellbladeWave = {}
SpellbladeWave.__index = SpellbladeWave

function SpellbladeWave:new(x, y, dirX, dirY, config)
    local mag = math.sqrt(dirX * dirX + dirY * dirY)
    if mag <= 0 then
        dirX, dirY, mag = 1, 0, 1
    end

    local wave = {
        x = x,
        y = y,
        dirX = dirX / mag,
        dirY = dirY / mag,
        width = config.width or 32,
        length = config.length or 88,
        speed = config.speed or 700,
        damage = config.damage or 18,
        knockback = config.knockback or 100,
        maxDistance = config.maxDistance or 300,
        lifetime = config.lifetime or 0.45,
        color = config.color or {0.35, 0.9, 1.0},
        edgeColor = config.edgeColor or {0.9, 0.98, 1.0},
        hitTargets = {},
        distanceTravelled = 0,
        alive = true,
    }

    return setmetatable(wave, SpellbladeWave)
end

function SpellbladeWave:update(dt)
    if not self.alive then
        return
    end

    local step = self.speed * dt
    self.x = self.x + self.dirX * step
    self.y = self.y + self.dirY * step
    self.distanceTravelled = self.distanceTravelled + step
    self.lifetime = self.lifetime - dt

    if self.distanceTravelled >= self.maxDistance or self.lifetime <= 0 then
        self.alive = false
    end
end

function SpellbladeWave:isAlive()
    return self.alive
end

function SpellbladeWave:getPosition()
    return self.x, self.y
end

function SpellbladeWave:getSize()
    return math.max(self.width, self.length) * 0.5
end

function SpellbladeWave:canHit(target)
    return self.hitTargets[target] ~= true
end

function SpellbladeWave:markHit(target)
    self.hitTargets[target] = true
end

function SpellbladeWave:intersectsCircle(cx, cy, radius)
    local relX = cx - self.x
    local relY = cy - self.y
    local tangentX = -self.dirY
    local tangentY = self.dirX

    local forward = relX * self.dirX + relY * self.dirY
    local lateral = relX * tangentX + relY * tangentY
    local halfWidth = self.width * 0.5

    return forward >= -radius
        and forward <= self.length + radius
        and math.abs(lateral) <= halfWidth + radius
end

function SpellbladeWave:draw()
    if not self.alive then
        return
    end

    local angle = math.atan2(self.dirY, self.dirX)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)

    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.24)
    love.graphics.rectangle("fill", -4, -self.width * 0.58, self.length + 8, self.width * 1.16, self.width * 0.18, self.width * 0.18)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.92)
    love.graphics.rectangle("fill", 0, -self.width * 0.5, self.length, self.width, self.width * 0.18, self.width * 0.18)
    love.graphics.setColor(self.edgeColor[1], self.edgeColor[2], self.edgeColor[3], 0.72)
    love.graphics.rectangle("line", 0, -self.width * 0.5, self.length, self.width, self.width * 0.18, self.width * 0.18)
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.rectangle("fill", self.length * 0.08, -self.width * 0.16, self.length * 0.72, self.width * 0.32, self.width * 0.12, self.width * 0.12)

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return SpellbladeWave
