-- Fireball Projectile
local Fireball = {}
Fireball.__index = Fireball

function Fireball:new(x, y, targetX, targetY)
    local dx = targetX - x
    local dy = targetY - y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    local fireball = {
        x = x,
        y = y,
        size = 8,
        speed = 400, -- pixels per second
        vx = (dx / distance) * 400, -- velocity x
        vy = (dy / distance) * 400, -- velocity y
        damage = 10,
        lifetime = 3, -- seconds before it despawns
        age = 0
    }
    setmetatable(fireball, Fireball)
    return fireball
end

function Fireball:update(dt)
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update lifetime
    self.age = self.age + dt
end

function Fireball:draw()
    -- Draw fireball with orange/red gradient effect
    local alpha = 1 - (self.age / self.lifetime)
    
    -- Outer glow
    love.graphics.setColor(1, 0.6, 0.1, alpha * 0.5)
    love.graphics.circle("fill", self.x, self.y, self.size + 3)
    
    -- Main fireball
    love.graphics.setColor(1, 0.3, 0.1, alpha)
    love.graphics.circle("fill", self.x, self.y, self.size)
    
    -- Inner core
    love.graphics.setColor(1, 0.9, 0.3, alpha)
    love.graphics.circle("fill", self.x, self.y, self.size * 0.6)
end

function Fireball:getPosition()
    return self.x, self.y
end

function Fireball:getSize()
    return self.size
end

function Fireball:isExpired()
    return self.age >= self.lifetime
end

return Fireball

