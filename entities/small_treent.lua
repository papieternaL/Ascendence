-- Small Treent Enemy - Bark Thrower (MCM)
-- Teaches projectile dodging for boss Bark Barrage
local JuiceManager = require("systems.juice_manager")

local SmallTreent = {}
SmallTreent.__index = SmallTreent

SmallTreent.image = nil

function SmallTreent:new(x, y)
    -- Load sprite
    if not SmallTreent.image then
        local success, result = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
        if success then
            SmallTreent.image = result
            SmallTreent.image:setFilter("nearest", "nearest")
        end
    end
    
    local treent = {
        x = x or 0,
        y = y or 0,
        size = 14, -- Smaller, flying enemy
        speed = 70, -- Fast erratic movement
        maxHealth = 30, -- Low-medium HP
        health = 30,
        isAlive = true,
        isMCM = true, -- Mechanic-Carrying Minion
        damage = 9,
        
        -- Erratic movement behavior
        wobbleTimer = 0,
        wobbleAngle = math.random() * math.pi * 2,
        wobbleSpeed = 4,
        wobbleRadius = 30,
        
        -- Visual feedback
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,
    }
    setmetatable(treent, SmallTreent)
    return treent
end

function SmallTreent:update(dt, playerX, playerY, onShoot)
    if not self.isAlive then return end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Update knockback
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
    
    -- Update wobble
    self.wobbleTimer = self.wobbleTimer + dt
    self.wobbleAngle = self.wobbleAngle + (self.wobbleSpeed * dt)
    
    -- Calculate distance to player
    local dx = playerX - self.x
    local dy = playerY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Erratic movement: move towards player with wobble
    if distance > 0 then
        dx = dx / distance
        dy = dy / distance
        
        -- Add wobble perpendicular to direction
        local perpX = -dy
        local perpY = dx
        local wobbleOffset = math.sin(self.wobbleAngle) * self.wobbleRadius
        
        -- Move with wobble and knockback
        self.x = self.x + (dx * self.speed * dt) + (perpX * wobbleOffset * dt) + (self.knockbackX * dt)
        self.y = self.y + (dy * self.speed * dt) + (perpY * wobbleOffset * dt) + (self.knockbackY * dt)
    end
end

function SmallTreent:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    self.health = self.health - damage
    self.flashTime = self.flashDuration
    
    -- Knockback
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local force = knockbackForce or 100
            self.knockbackX = (dx / distance) * force
            self.knockbackY = (dy / distance) * force
        end
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true -- Enemy died
    end
    
    return false
end

function SmallTreent:draw()
    if not self.isAlive then return end
    
    -- MCM glow (subtle to indicate importance)
    love.graphics.setColor(0.6, 0.4, 0.2, 0.15)
    love.graphics.circle("fill", self.x, self.y, self.size + 8)
    
    -- Draw sprite
    local img = SmallTreent.image
    if img then
        local scale = 1.0
        local imgW = img:getWidth()
        local imgH = img:getHeight()
        
        -- Flash effect or normal color (check JuiceManager too)
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.8, 0.6, 0.4, 1)
        end
        
        love.graphics.draw(
            img,
            self.x,
            self.y,
            0,
            scale, scale,
            imgW / 2, imgH / 2
        )
    else
        -- Fallback: brown triangle
        if self.flashTime > 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.6, 0.4, 0.2, 1)
        end
        local s = self.size
        love.graphics.polygon("fill", self.x, self.y - s, self.x - s, self.y + s, self.x + s, self.y + s)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function SmallTreent:getPosition()
    return self.x, self.y
end

function SmallTreent:getSize()
    return self.size
end

function SmallTreent:isDead()
    return not self.isAlive
end

function SmallTreent:applyRoot(duration, damageMultiplier)
    -- Small Treent is immune to roots (it's a tree!)
end

return SmallTreent

