-- Lunger Enemy - Charges at the player
-- NOTE: Sprite visuals intentionally removed. Will be re-implemented
-- in the visual overhaul phase to match Ember Knights pixel art direction.
local Lunger = {}
Lunger.__index = Lunger

function Lunger:new(x, y)
    local lunger = {
        x = x or 0,
        y = y or 0,
        size = 18, -- size of the lunger
        speed = 30, -- slow normal movement
        lungeSpeed = 500, -- fast lunge speed
        maxHealth = 40,
        health = 40,
        isAlive = true,
        damage = 15, -- damage dealt to player on contact
        
        -- Lunge behavior
        state = "idle", -- idle, charging, lunging, cooldown
        chargeTime = 0, -- time spent charging
        chargeDuration = 0.8, -- seconds to charge before lunging
        lungeTime = 0,
        lungeDuration = 0.45, -- seconds of lunging (tuned longer for lethality)
        cooldownTime = 0,
        cooldownDuration = 1.5, -- seconds between lunges
        lungeRange = 340, -- range at which lunger starts charging (tuned higher)
        
        -- Lunge direction
        lungeVx = 0,
        lungeVy = 0,
        
        -- Visual feedback
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,

        -- Status effects
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
    }
    setmetatable(lunger, Lunger)
    return lunger
end

function Lunger:update(dt, playerX, playerY)
    if not self.isAlive then return end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Update knockback
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)

    -- Update root
    if self.rootedTime and self.rootedTime > 0 then
        self.rootedTime = math.max(0, self.rootedTime - dt)
        if self.rootedTime <= 0 then
            self.rootedDamageTakenMul = 1.0
        end

        -- While rooted: apply knockback drift, but stop behavior
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        self.state = "idle"
        return
    end
    
    -- Calculate distance to player
    local dx = playerX - self.x
    local dy = playerY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- State machine
    if self.state == "idle" then
        -- Move slowly towards player
        if distance > 0 then
            local normDx = dx / distance
            local normDy = dy / distance
            self.x = self.x + normDx * self.speed * dt + self.knockbackX * dt
            self.y = self.y + normDy * self.speed * dt + self.knockbackY * dt
        end
        
        -- Start charging if in range
        if distance < self.lungeRange then
            self.state = "charging"
            self.chargeTime = 0
        end
        
    elseif self.state == "charging" then
        -- Stand still and charge up
        self.chargeTime = self.chargeTime + dt
        
        -- Lock onto player direction
        if distance > 0 then
            self.lungeVx = dx / distance
            self.lungeVy = dy / distance
        end
        
        -- Apply knockback during charging
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        
        -- Start lunging after charge time
        if self.chargeTime >= self.chargeDuration then
            self.state = "lunging"
            self.lungeTime = 0
        end
        
    elseif self.state == "lunging" then
        -- Lunge in the locked direction
        self.x = self.x + self.lungeVx * self.lungeSpeed * dt
        self.y = self.y + self.lungeVy * self.lungeSpeed * dt
        
        self.lungeTime = self.lungeTime + dt
        
        -- End lunge after duration
        if self.lungeTime >= self.lungeDuration then
            self.state = "cooldown"
            self.cooldownTime = 0
        end
        
    elseif self.state == "cooldown" then
        -- Recover after lunging
        self.cooldownTime = self.cooldownTime + dt
        
        -- Apply knockback during cooldown
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        
        -- Return to idle after cooldown
        if self.cooldownTime >= self.cooldownDuration then
            self.state = "idle"
        end
    end
    
    -- Keep within screen bounds
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.x = math.max(self.size, math.min(screenWidth - self.size, self.x))
    self.y = math.max(self.size, math.min(screenHeight - self.size, self.y))
end

function Lunger:takeDamage(damage, hitX, hitY, knockbackForce)
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
            local k = knockbackForce or 160
            self.knockbackX = (dx / distance) * k
            self.knockbackY = (dy / distance) * k
        end
    end
    
    -- Interrupt lunge if hit
    if self.state == "charging" or self.state == "lunging" then
        self.state = "cooldown"
        self.cooldownTime = 0
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true -- Enemy died
    end
    
    return false
end

function Lunger:applyRoot(duration, damageTakenMul)
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Lunger:draw()
    if not self.isAlive then return end

    -- Placeholder shape (sprite to be added in visual overhaul)
    -- Determine color based on state
    local r, g, b = 0.8, 0.4, 0.8 -- Purple for lunger

    if self.flashTime > 0 then
        r, g, b = 1, 1, 1
    elseif self.state == "charging" then
        local pulse = math.sin(self.chargeTime * 15) * 0.3 + 0.7
        r, g, b = 1, pulse * 0.3, pulse * 0.3
    elseif self.state == "lunging" then
        r, g, b = 1, 0.1, 0.1
    elseif self.state == "cooldown" then
        r, g, b = 0.5, 0.3, 0.5
    end

    if self.rootedTime and self.rootedTime > 0 then
        r, g, b = r * 0.6, g + 0.3, b * 0.6
    end

    love.graphics.setColor(r, g, b, 1)

    -- Draw as a diamond shape (rotated square)
    local size = self.size
    if self.state == "charging" then
        size = self.size * (1 + self.chargeTime / self.chargeDuration * 0.3)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(math.pi / 4)
    love.graphics.rectangle("fill", -size, -size, size * 2, size * 2)
    love.graphics.pop()

    -- Draw direction indicator when charging
    if self.state == "charging" then
        love.graphics.setColor(1, 0, 0, 0.5)
        local indicatorLength = 50 * (self.chargeTime / self.chargeDuration)
        love.graphics.line(
            self.x,
            self.y,
            self.x + self.lungeVx * indicatorLength,
            self.y + self.lungeVy * indicatorLength
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Lunger:getPosition()
    return self.x, self.y
end

function Lunger:getSize()
    return self.size
end

function Lunger:isDead()
    return not self.isAlive
end

function Lunger:isLunging()
    return self.state == "lunging"
end

function Lunger:getDamage()
    return self.damage
end

return Lunger




