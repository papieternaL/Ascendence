-- Enemy Entity (basic melee)
-- NOTE: Sprite visuals intentionally removed. Will be re-implemented
-- in the visual overhaul phase to match Ember Knights pixel art direction.
local StatusEffects = require("systems.status_effects")

local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y)
    local enemy = {
        x = x or 0,
        y = y or 0,
        size = 15, -- size of the square (half-width/height)
        speed = 50, -- pixels per second
        maxHealth = 45,
        health = 45,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8, -- how fast knockback fades

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
        statuses = {},
    }
    setmetatable(enemy, Enemy)
    return enemy
end

function Enemy:update(dt, playerX, playerY)
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end

    -- Update root
    if self.rootedTime and self.rootedTime > 0 then
        self.rootedTime = math.max(0, self.rootedTime - dt)
        if self.rootedTime <= 0 then
            self.rootedDamageTakenMul = 1.0
        end
    end
    
    -- Update knockback
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
    
    -- Simple AI: move towards player (disabled while rooted)
    if playerX and playerY and self.isAlive then
        if self.rootedTime and self.rootedTime > 0 then
            -- Still apply knockback drift while rooted
            self.x = self.x + (self.knockbackX * dt)
            self.y = self.y + (self.knockbackY * dt)
            return
        end

        local dx = playerX - self.x
        local dy = playerY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            -- Normalize direction
            dx = dx / distance
            dy = dy / distance
            
            -- Move towards player (with knockback applied)
            self.x = self.x + (dx * self.speed * dt) + (self.knockbackX * dt)
            self.y = self.y + (dy * self.speed * dt) + (self.knockbackY * dt)
        end
    end
end

function Enemy:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    local mul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
    mul = mul * StatusEffects.getDamageTakenMul(self)
    self.health = self.health - (damage * mul)
    
    -- Flash effect
    self.flashTime = self.flashDuration
    
    -- Knockback
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = knockbackForce or 120
            self.knockbackX = (dx / distance) * k
            self.knockbackY = (dy / distance) * k
        end
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true -- Return true if enemy died
    end
    
    return false
end

function Enemy:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Enemy:draw()
    if not self.isAlive then return end

    -- Placeholder shape (sprite to be added in visual overhaul)
    local r, g, b = 0.9, 0.1, 0.1
    if self.flashTime > 0 then r, g, b = 1, 1, 1 end
    if self.rootedTime and self.rootedTime > 0 then
        r, g, b = r * 0.6, g + 0.3, b * 0.6
    end
    -- Status tints
    if StatusEffects.has(self, "bleed") then
        r = math.min(1, r + 0.2)
        g = g * 0.5
        b = b * 0.5
    end
    if StatusEffects.has(self, "marked") then
        r = r * 0.8; g = g * 0.8; b = math.min(1, b + 0.4)
    end
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", self.x - self.size, self.y - self.size, self.size * 2, self.size * 2)
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:getPosition()
    return self.x, self.y
end

function Enemy:getSize()
    return self.size
end

function Enemy:isDead()
    return not self.isAlive
end

function Enemy:getHealth()
    return self.health
end

return Enemy

