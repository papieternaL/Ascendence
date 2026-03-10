local SpellbladePrismRift = {}
SpellbladePrismRift.__index = SpellbladePrismRift

function SpellbladePrismRift:new(x, y, config)
    return setmetatable({
        x = x,
        y = y,
        radius = config.radius or 84,
        pullStrength = config.pullStrength or 220,
        duration = config.duration or 1.4,
        timeRemaining = config.duration or 1.4,
        collapseDamage = config.collapseDamage or 32,
        color = config.color or {0.48, 0.66, 1.0},
        collapseColor = config.collapseColor or {0.92, 0.72, 1.0},
        collapseFlash = 0,
        collapsed = false,
    }, SpellbladePrismRift)
end

function SpellbladePrismRift:update(dt)
    if not self.collapsed then
        self.timeRemaining = self.timeRemaining - dt
        if self.timeRemaining <= 0 then
            self.collapsed = true
            self.collapseFlash = 0.22
            return true
        end
        return false
    end

    self.collapseFlash = self.collapseFlash - dt
    return false
end

function SpellbladePrismRift:isAlive()
    return (not self.collapsed) or self.collapseFlash > 0
end

function SpellbladePrismRift:shouldPull()
    return not self.collapsed and self.timeRemaining > 0
end

function SpellbladePrismRift:draw()
    if not self:isAlive() then
        return
    end

    local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 6)
    if not self.collapsed then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.10 + pulse * 0.08)
        love.graphics.circle("fill", self.x, self.y, self.radius + 10)
        love.graphics.setBlendMode("alpha")

        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.18 + pulse * 0.08)
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.85)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.x, self.y, self.radius)
        love.graphics.circle("line", self.x, self.y, self.radius * 0.58)
        for i = 0, 5 do
            local angle = love.timer.getTime() * 2.6 + i * (math.pi * 2 / 6)
            local inner = self.radius * 0.3
            local outer = self.radius * 0.92
            local ix = self.x + math.cos(angle) * outer
            local iy = self.y + math.sin(angle) * outer
            local ox = self.x + math.cos(angle + math.pi) * inner
            local oy = self.y + math.sin(angle + math.pi) * inner
            love.graphics.line(ix, iy, ox, oy)
        end
        love.graphics.setLineWidth(1)
    else
        local alpha = math.max(0, self.collapseFlash / 0.22)
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(self.collapseColor[1], self.collapseColor[2], self.collapseColor[3], alpha * 0.45)
        love.graphics.circle("fill", self.x, self.y, self.radius * (1.0 + (1 - alpha) * 0.35))
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(self.collapseColor[1], self.collapseColor[2], self.collapseColor[3], alpha)
        love.graphics.circle("line", self.x, self.y, self.radius * (0.75 + (1 - alpha) * 0.45))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return SpellbladePrismRift
