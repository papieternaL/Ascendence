-- Base Enemy Class
-- Provides common functionality for all enemy types
-- Reduces code duplication and ensures consistent interface

local StatusComponent = require("systems.status_component")
local JuiceManager = require("systems.juice_manager")

local BaseEnemy = {}
BaseEnemy.__index = BaseEnemy

function BaseEnemy:new(x, y, config)
    -- config should contain: size, speed, health, damage, etc.
    config = config or {}
    
    local enemy = {
        -- Position
        x = x or 0,
        y = y or 0,
        
        -- Stats (from config or defaults)
        size = config.size or 16,
        speed = config.speed or 80,
        maxHealth = config.health or 50,
        health = config.health or 50,
        damage = config.damage or 10,
        
        -- Visual
        flashTime = 0,
        flashDuration = config.flashDuration or 0.1,
        
        -- Physics
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = config.knockbackDecay or 8,
        
        -- Status
        isAlive = true,
        statusComponent = StatusComponent:new(),
        
        -- Legacy root support (for compatibility)
        rootedTime = 0,
        rootedDamageTakenMul = 1.0,
        
        -- Metadata
        isElite = config.isElite or false,
        isMCM = config.isMCM or false,
        enemyType = config.enemyType or "unknown",
    }
    
    setmetatable(enemy, self)
    return enemy
end

-- Update common systems (status, flash, knockback)
function BaseEnemy:updateCommon(dt)
    if not self.isAlive then return end
    
    -- Update status component
    if self.statusComponent then
        self.statusComponent:update(dt, self)
    end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Update legacy root
    if self.rootedTime and self.rootedTime > 0 then
        self.rootedTime = math.max(0, self.rootedTime - dt)
        if self.rootedTime <= 0 then
            self.rootedDamageTakenMul = 1.0
        end
    end
    
    -- Update knockback decay
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
end

-- Standard damage handler (can be overridden)
function BaseEnemy:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    -- Apply damage multipliers from status effects
    local statusMul = self.statusComponent and self.statusComponent:getDamageMultiplier() or 1.0
    local legacyMul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
    local totalMul = statusMul * legacyMul
    
    self.health = self.health - (damage * totalMul)
    
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

-- Apply knockback manually
function BaseEnemy:applyKnockback(dx, dy, force)
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 0 then
        self.knockbackX = (dx / distance) * force
        self.knockbackY = (dy / distance) * force
    end
end

-- Root application (status component + legacy)
function BaseEnemy:applyRoot(duration, damageTakenMul)
    -- Apply via status component if available
    if self.statusComponent then
        self.statusComponent:applyStatus("rooted", 1, duration, { damage_taken_multiplier = damageTakenMul or 1.15 })
    end
    
    -- Legacy support
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function BaseEnemy:isRooted()
    if self.statusComponent and self.statusComponent:hasStatus("rooted") then
        return true
    end
    return self.rootedTime and self.rootedTime > 0
end

-- Standard movement towards player (can be overridden)
function BaseEnemy:moveTowardsPlayer(dt, playerX, playerY)
    if not self.isAlive or not playerX or not playerY then return end
    
    -- Don't move if rooted
    if self:isRooted() then
        -- Still apply knockback drift
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

-- Standard update (calls updateCommon, then moveTowardsPlayer)
-- Subclasses should override this and call updateCommon themselves
function BaseEnemy:update(dt, playerX, playerY)
    self:updateCommon(dt)
    self:moveTowardsPlayer(dt, playerX, playerY)
end

-- Standard draw (fallback - subclasses should override)
function BaseEnemy:draw()
    if not self.isAlive then return end
    
    local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
    local r, g, b = 0.9, 0.1, 0.1
    if isFlashing then r, g, b = 1, 1, 1 end
    
    love.graphics.setColor(r, g, b, 1)
    love.graphics.circle("fill", self.x, self.y, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Required interface methods (for collision/targeting)
function BaseEnemy:getPosition()
    return self.x, self.y
end

function BaseEnemy:getSize()
    return self.size
end

function BaseEnemy:isDead()
    return not self.isAlive
end

function BaseEnemy:getHealth()
    return self.health
end

return BaseEnemy
