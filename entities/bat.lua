-- Bat Entity (flying, erratic movement)
local JuiceManager = require("systems.juice_manager")
local StatusEffects = require("systems.status_effects")

local Bat = {}
Bat.__index = Bat

Bat.image = nil

local function loadBatImageOnce()
    if Bat.image then return end
    local success, img = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
    if success and img then
        Bat.image = img
        Bat.image:setFilter("nearest", "nearest")
    end
end

function Bat:new(x, y)
    loadBatImageOnce()
    local bat = {
        x = x or 0,
        y = y or 0,
        size = 14,
        speed = 70, -- Medium-fast
        maxHealth = 30, -- Low-medium HP
        health = 30,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,

        -- Erratic movement
        wobbleTimer = 0,
        wobbleAngle = math.random() * math.pi * 2,
        wobbleSpeed = 4,
        wobbleRadius = 30,

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
        statuses = {},
    }
    setmetatable(bat, Bat)
    return bat
end

function Bat:update(dt, playerX, playerY)
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
    
    -- AI: erratic movement towards player (disabled while rooted)
    if playerX and playerY and self.isAlive then
        if self.rootedTime and self.rootedTime > 0 then
            -- Still apply knockback drift while rooted
            self.x = self.x + (self.knockbackX * dt)
            self.y = self.y + (self.knockbackY * dt)
            return
        end

        if StatusEffects.isFrozen(self) then
            self.x = self.x + (self.knockbackX * dt)
            self.y = self.y + (self.knockbackY * dt)
            return
        end

        local speedMul = StatusEffects.getSpeedMul(self)
        local effectiveSpeed = self.speed * speedMul

        -- Update wobble
        self.wobbleTimer = self.wobbleTimer + dt
        self.wobbleAngle = self.wobbleAngle + (self.wobbleSpeed * dt)
        
        local dx = playerX - self.x
        local dy = playerY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            dx = dx / distance
            dy = dy / distance
            
            -- Add wobble perpendicular to direction
            local perpX = -dy
            local perpY = dx
            local wobbleOffset = math.sin(self.wobbleAngle) * self.wobbleRadius
            
            -- Move towards player with wobble (with knockback applied)
            self.x = self.x + (dx * effectiveSpeed * dt) + (perpX * wobbleOffset * dt) + (self.knockbackX * dt)
            self.y = self.y + (dy * effectiveSpeed * dt) + (perpY * wobbleOffset * dt) + (self.knockbackY * dt)
        end
    end
end

function Bat:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    local mul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
    self.health = self.health - (damage * mul)
    
    -- Flash effect
    self.flashTime = self.flashDuration
    
    -- Knockback
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = (knockbackForce or 120) * 1.0
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

function Bat:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Bat:draw()
    if not self.isAlive then return end

    if Bat.image then
        local img = Bat.image
        local w, h = img:getWidth(), img:getHeight()
        local scale = 1.0
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.75, 0.5, 1, 1)  -- Purple tint
        end
        love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Fallback: purple triangle
    local r, g, b = 0.7, 0.45, 1
    if self.flashTime > 0 then r, g, b = 1, 1, 1 end
    love.graphics.setColor(r, g, b, 1)
    local s = self.size
    love.graphics.polygon("fill", self.x, self.y - s, self.x - s, self.y + s, self.x + s, self.y + s)
    love.graphics.setColor(1, 1, 1, 1)
end

function Bat:getPosition()
    return self.x, self.y
end

function Bat:getSize()
    return self.size
end

function Bat:isDead()
    return not self.isAlive
end

function Bat:getHealth()
    return self.health
end

return Bat


