-- Slime Entity (slow, tanky)
local JuiceManager = require("systems.juice_manager")

local Slime = {}
Slime.__index = Slime

Slime.image = nil

local function loadSlimeImageOnce()
    if Slime.image then return end
    local success, img = pcall(love.graphics.newImage, "assets/32x32/fb50.png")
    if success and img then
        Slime.image = img
        Slime.image:setFilter("nearest", "nearest")
    end
end

function Slime:new(x, y)
    loadSlimeImageOnce()
    local slime = {
        x = x or 0,
        y = y or 0,
        size = 18, -- bigger than base enemy
        speed = 30, -- SLOW
        maxHealth = 80, -- High HP
        health = 80,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 12, -- More resistant to knockback

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
    }
    setmetatable(slime, Slime)
    return slime
end

function Slime:update(dt, playerX, playerY)
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
    
    -- AI: move towards player (disabled while rooted)
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
            dx = dx / distance
            dy = dy / distance
            
            -- Move towards player (with knockback applied)
            self.x = self.x + (dx * self.speed * dt) + (self.knockbackX * dt)
            self.y = self.y + (dy * self.speed * dt) + (self.knockbackY * dt)
        end
    end
end

function Slime:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    local mul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
    self.health = self.health - (damage * mul)
    
    -- Flash effect
    self.flashTime = self.flashDuration
    
    -- Knockback (reduced for slimes)
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = (knockbackForce or 120) * 0.6 -- Heavy = less knockback
            self.knockbackX = (dx / distance) * k
            self.knockbackY = (dy / distance) * k
        end
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true
    end
    
    return false
end

function Slime:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Slime:draw()
    if not self.isAlive then return end

    if Slime.image then
        local img = Slime.image
        local w, h = img:getWidth(), img:getHeight()
        local scale = 1.2
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.7, 1, 0.7, 1)
        end
        love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Fallback: gray circle
    local r, g, b = 0.5, 0.5, 0.5
    if self.flashTime > 0 then r, g, b = 1, 1, 1 end
    love.graphics.setColor(r, g, b, 1)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

function Slime:getPosition()
    return self.x, self.y
end

function Slime:getSize()
    return self.size
end

function Slime:isDead()
    return not self.isAlive
end

function Slime:getHealth()
    return self.health
end

return Slime



