-- Skeleton Entity (medium stats, steady pace)
local JuiceManager = require("systems.juice_manager")
local StatusEffects = require("systems.status_effects")

local Skeleton = {}
Skeleton.__index = Skeleton

Skeleton.image = nil

local function loadSkeletonImageOnce()
    if Skeleton.image then return end
    local success, img = pcall(love.graphics.newImage, "assets/32x32/fb500.png")
    if success and img then
        Skeleton.image = img
        Skeleton.image:setFilter("nearest", "nearest")
    end
end

function Skeleton:new(x, y)
    loadSkeletonImageOnce()
    local skeleton = {
        x = x or 0,
        y = y or 0,
        size = 15,
        speed = 55, -- Medium speed
        maxHealth = 40, -- Medium HP
        health = 40,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
        statuses = {},

        -- Sword swing animation (tied to contact attack)
        swingPhase = 0,
        swingCooldown = 0,
        lastPlayerX = 0,
        lastPlayerY = 0,
    }
    setmetatable(skeleton, Skeleton)
    return skeleton
end

function Skeleton:update(dt, playerX, playerY)
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
        self.lastPlayerX, self.lastPlayerY = playerX, playerY
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

        local effectiveSpeed = self.speed * StatusEffects.getSpeedMul(self)
        local dx = playerX - self.x
        local dy = playerY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            dx = dx / distance
            dy = dy / distance

            -- Move towards player (with knockback applied)
            self.x = self.x + (dx * effectiveSpeed * dt) + (self.knockbackX * dt)
            self.y = self.y + (dy * effectiveSpeed * dt) + (self.knockbackY * dt)
        end

        -- Sword swing: when in attack range, animate swing
        local attackRange = self.size + 25
        if self.swingCooldown > 0 then
            self.swingCooldown = self.swingCooldown - dt
        end
        if distance < attackRange and self.swingCooldown <= 0 then
            self.swingPhase = self.swingPhase + dt
            if self.swingPhase >= 0.35 then
                self.swingPhase = 0
                self.swingCooldown = 0.6
            end
        else
            self.swingPhase = 0
        end
    end
end

function Skeleton:takeDamage(damage, hitX, hitY, knockbackForce)
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
            local k = knockbackForce or 120
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

function Skeleton:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Skeleton:draw()
    if not self.isAlive then return end

    if Skeleton.image then
        local img = Skeleton.image
        local w, h = img:getWidth(), img:getHeight()
        local scale = 1.0
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
        end
        love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
        love.graphics.setColor(1, 1, 1, 1)
    else
        -- Fallback: gray square
        local r, g, b = 0.6, 0.6, 0.6
        if self.flashTime > 0 then r, g, b = 1, 1, 1 end
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", self.x - self.size, self.y - self.size, self.size * 2, self.size * 2)
    end

    -- Sword overlay (procedural)
    local px = self.lastPlayerX or self.x + 1
    local py = self.lastPlayerY or self.y
    local dx = px - self.x
    local dy = py - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        dx, dy = dx / dist, dy / dist
    else
        dx, dy = 1, 0
    end
    local baseAngle = math.atan2(dy, dx)
    local swingProgress = math.min(1, (self.swingPhase or 0) / 0.35)
    local swingOffset = (math.pi / 3) - swingProgress * (math.pi * 2 / 3)
    local swordAngle = baseAngle + swingOffset
    local swordLen = 18
    local sx = self.x + math.cos(swordAngle) * swordLen * 0.5
    local sy = self.y + math.sin(swordAngle) * swordLen * 0.5
    local ex = self.x + math.cos(swordAngle) * swordLen
    local ey = self.y + math.sin(swordAngle) * swordLen
    love.graphics.setColor(0.7, 0.7, 0.8, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(sx, sy, ex, ey)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Skeleton:getPosition()
    return self.x, self.y
end

function Skeleton:getSize()
    return self.size
end

function Skeleton:isDead()
    return not self.isAlive
end

function Skeleton:getHealth()
    return self.health
end

return Skeleton



