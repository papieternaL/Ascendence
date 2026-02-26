-- entities/core.lua
-- Destructible crystal core spread around the map as an objective target.

local Core = {}
Core.__index = Core

function Core:new(x, y, opts)
    opts = opts or {}
    local core = {
        x = x,
        y = y,
        size = opts.size or 18,
        maxHealth = opts.health or 60,
        health = opts.health or 60,
        isAlive = true,

        -- Visual
        pulseTime = math.random() * math.pi * 2,
        hue = opts.hue or math.random() * 0.3 + 0.5, -- 0.5-0.8 range (cyan-purple)

        -- XP/progress reward
        majorProgress = opts.majorProgress or 3.0,
    }
    setmetatable(core, Core)
    return core
end

function Core:update(dt)
    if not self.isAlive then return end
    self.pulseTime = self.pulseTime + dt
end

function Core:takeDamage(amount)
    if not self.isAlive then return false end
    self.health = self.health - (amount or 0)
    if self.health <= 0 then
        self.health = 0
        self.isAlive = false
        return true
    end
    return false
end

function Core:draw()
    if not self.isAlive then return end
    local t = self.pulseTime
    local pulse = 0.6 + 0.4 * math.sin(t * 2.5)
    local fastPulse = 0.5 + 0.5 * math.sin(t * 6)

    -- Outer glow ring
    love.graphics.setColor(0.3, 0.6, 1.0, 0.12 + 0.08 * pulse)
    love.graphics.circle("fill", self.x, self.y, self.size + 14)

    -- Mid glow
    love.graphics.setColor(0.4, 0.7, 1.0, 0.2 * pulse)
    love.graphics.circle("fill", self.x, self.y, self.size + 6)

    -- Crystal body (diamond shape)
    local r = self.size
    local hp = self.health / self.maxHealth
    love.graphics.setColor(0.15 + 0.3 * (1 - hp), 0.4 + 0.3 * hp, 0.9, 0.9)
    love.graphics.polygon("fill",
        self.x, self.y - r,
        self.x + r * 0.7, self.y,
        self.x, self.y + r,
        self.x - r * 0.7, self.y
    )

    -- Inner bright core
    love.graphics.setColor(0.6, 0.85, 1.0, 0.7 * fastPulse)
    local ir = r * 0.4
    love.graphics.polygon("fill",
        self.x, self.y - ir,
        self.x + ir * 0.7, self.y,
        self.x, self.y + ir,
        self.x - ir * 0.7, self.y
    )

    -- Diamond outline
    love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
    love.graphics.setLineWidth(1.5)
    love.graphics.polygon("line",
        self.x, self.y - r,
        self.x + r * 0.7, self.y,
        self.x, self.y + r,
        self.x - r * 0.7, self.y
    )
    love.graphics.setLineWidth(1)

    -- Health bar (only show when damaged)
    if self.health < self.maxHealth then
        local barW = 30
        local barH = 4
        local barX = self.x - barW / 2
        local barY = self.y - r - 10
        love.graphics.setColor(0.15, 0.05, 0.05, 0.9)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 1, 1)
        love.graphics.setColor(0.3, 0.7, 1.0, 1)
        love.graphics.rectangle("fill", barX, barY, barW * hp, barH, 1, 1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Core:getPosition()
    return self.x, self.y
end

function Core:getSize()
    return self.size
end

return Core
