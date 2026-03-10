local SpellbladeMirror = {}
SpellbladeMirror.__index = SpellbladeMirror

function SpellbladeMirror:new(x, y, facingAngle, duration, color)
    return setmetatable({
        x = x,
        y = y,
        facingAngle = facingAngle or 0,
        timeRemaining = duration or 0.6,
        color = color or {0.72, 0.58, 1.0},
        size = 18,
    }, SpellbladeMirror)
end

function SpellbladeMirror:update(dt)
    self.timeRemaining = self.timeRemaining - dt
end

function SpellbladeMirror:isAlive()
    return self.timeRemaining > 0
end

function SpellbladeMirror:draw()
    if not self:isAlive() then
        return
    end

    local alpha = math.max(0, math.min(1, self.timeRemaining / 0.6)) * 0.42
    local color = self.color
    local bladeX = self.x + math.cos(self.facingAngle) * 18
    local bladeY = self.y + math.sin(self.facingAngle) * 18

    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
    love.graphics.circle("fill", self.x, self.y, self.size + 8)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(color[1], color[2], color[3], alpha * 1.5)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, alpha * 1.35)
    love.graphics.circle("fill", self.x, self.y - 4, self.size * 0.4)
    love.graphics.setColor(color[1], color[2], color[3], alpha * 1.2)
    love.graphics.setLineWidth(3)
    love.graphics.line(self.x, self.y, bladeX, bladeY)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return SpellbladeMirror
