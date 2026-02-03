-- Bark Projectile (thrown by Small Treent and Treent Overlord)
local BarkProjectile = {}
BarkProjectile.__index = BarkProjectile

function BarkProjectile:new(x, y, targetX, targetY, customSpeed)
    local dx = targetX - x
    local dy = targetY - y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= 0 then
        distance = 1
        dx, dy = 1, 0
    end
    
    local angle = math.atan2(dy, dx)
    local speed = customSpeed or 180  -- Use custom speed if provided
    
    local bark = {
        x = x,
        y = y,
        size = 8,
        speed = speed,
        vx = (dx / distance) * speed,
        vy = (dy / distance) * speed,
        angle = angle,
        damage = 15,
        lifetime = 3.5,
        age = 0,
    }
    setmetatable(bark, BarkProjectile)
    return bark
end

function BarkProjectile:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.age = self.age + dt
end

function BarkProjectile:draw()
    local alpha = 1 - (self.age / self.lifetime) * 0.2
    
    -- Brown bark color
    love.graphics.setColor(0.6, 0.4, 0.2, alpha)
    love.graphics.circle("fill", self.x, self.y, self.size)
    
    -- Darker outline
    love.graphics.setColor(0.4, 0.3, 0.15, alpha)
    love.graphics.circle("line", self.x, self.y, self.size)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BarkProjectile:getPosition()
    return self.x, self.y
end

function BarkProjectile:getSize()
    return self.size
end

function BarkProjectile:isExpired()
    return self.age >= self.lifetime
end

return BarkProjectile

