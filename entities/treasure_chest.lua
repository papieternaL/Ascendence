local TreasureChest = {}
TreasureChest.__index = TreasureChest

function TreasureChest:new(x, y, opts)
    opts = opts or {}
    local chest = {
        x = x,
        y = y,
        size = opts.size or 20,
        maxHealth = opts.health or 90,
        health = opts.health or 90,
        isAlive = true,
        pulseTime = math.random() * math.pi * 2,
    }
    setmetatable(chest, TreasureChest)
    return chest
end

function TreasureChest:update(dt)
    if not self.isAlive then return end
    self.pulseTime = self.pulseTime + dt
end

function TreasureChest:takeDamage(amount)
    if not self.isAlive then return false end
    self.health = self.health - (amount or 0)
    if self.health <= 0 then
        self.health = 0
        self.isAlive = false
        return true
    end
    return false
end

function TreasureChest:draw()
    if not self.isAlive then return end

    local t = self.pulseTime
    local pulse = 0.55 + 0.45 * math.sin(t * 3.2)
    local r = self.size

    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(1.0, 0.8, 0.32, 0.09 + pulse * 0.06)
    love.graphics.circle("fill", self.x, self.y + 4, r + 18)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(0.16, 0.08, 0.03, 0.95)
    love.graphics.rectangle("fill", self.x - r, self.y - r * 0.15, r * 2, r * 1.2, 5, 5)
    love.graphics.setColor(0.46, 0.2, 0.06, 0.98)
    love.graphics.rectangle("fill", self.x - r + 3, self.y - r * 0.15 + 3, r * 2 - 6, r * 1.2 - 6, 4, 4)

    love.graphics.setColor(0.78, 0.56, 0.16, 0.98)
    love.graphics.rectangle("fill", self.x - r, self.y - r * 0.55, r * 2, r * 0.55 + 6, 6, 6)
    love.graphics.setColor(0.98, 0.86, 0.42, 0.95)
    love.graphics.rectangle("fill", self.x - r + 4, self.y - r * 0.55 + 3, r * 2 - 8, r * 0.55, 4, 4)

    love.graphics.setColor(0.32, 0.16, 0.04, 1)
    love.graphics.rectangle("fill", self.x - 3, self.y - r * 0.55, 6, r * 1.6, 2, 2)

    love.graphics.setColor(0.95, 0.9, 0.65, 0.95)
    love.graphics.rectangle("fill", self.x - 4, self.y + 2, 8, 10, 2, 2)
    love.graphics.setColor(0.45, 0.26, 0.06, 1)
    love.graphics.rectangle("line", self.x - 4, self.y + 2, 8, 10, 2, 2)

    love.graphics.setColor(0.98, 0.9, 0.58, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", self.x - r, self.y - r * 0.15, r * 2, r * 1.2, 5, 5)
    love.graphics.rectangle("line", self.x - r, self.y - r * 0.55, r * 2, r * 0.55 + 6, 6, 6)
    love.graphics.setLineWidth(1)

    if self.health < self.maxHealth then
        local hp = self.health / self.maxHealth
        local barW = 34
        local barH = 4
        local barX = self.x - barW / 2
        local barY = self.y - r - 16
        love.graphics.setColor(0.15, 0.06, 0.03, 0.92)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 2, 2)
        love.graphics.setColor(1.0, 0.8, 0.3, 1)
        love.graphics.rectangle("fill", barX, barY, barW * hp, barH, 2, 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TreasureChest:getPosition()
    return self.x, self.y
end

function TreasureChest:getSize()
    return self.size
end

return TreasureChest
