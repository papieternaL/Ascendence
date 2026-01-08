-- Imp Entity (fast, low HP melee)
local JuiceManager = require("systems.juice_manager")

local Imp = {}
Imp.__index = Imp

Imp.image = nil

local function loadImpImageOnce()
    if Imp.image then return end
    local success, img = pcall(love.graphics.newImage, "assets/32x32/fb1.png")
    if success and img then
        Imp.image = img
        Imp.image:setFilter("nearest", "nearest")
    end
end

function Imp:new(x, y)
    loadImpImageOnce()
    local imp = {
        x = x or 0,
        y = y or 0,
        size = 12, -- smaller than base enemy
        speed = 90, -- FAST!
        maxHealth = 25, -- Low HP
        health = 25,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
    }
    setmetatable(imp, Imp)
    return imp
end

function Imp:update(dt, playerX, playerY)
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

function Imp:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    local mul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
    self.health = self.health - (damage * mul)
    
    -- Flash effect
    self.flashTime = self.flashDuration
    
    -- Knockback (lighter knockback for imps)
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = (knockbackForce or 120) * 1.2 -- More knockback due to low mass
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

function Imp:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Imp:draw()
    if not self.isAlive then return end

    if Imp.image then
        local img = Imp.image
        local w, h = img:getWidth(), img:getHeight()
        local scale = 1.0
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0.85, 0.85, 1)
        end
        love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Fallback: small red circle
    local r, g, b = 0.9, 0.1, 0.1
    if self.flashTime > 0 then r, g, b = 1, 1, 1 end
    love.graphics.setColor(r, g, b, 1)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

function Imp:getPosition()
    return self.x, self.y
end

function Imp:getSize()
    return self.size
end

function Imp:isDead()
    return not self.isAlive
end

function Imp:getHealth()
    return self.health
end

return Imp



