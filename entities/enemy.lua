-- Enemy Entity (red square)
local JuiceManager = require("systems.juice_manager")
local StatusComponent = require("systems.status_component")

local Enemy = {}
Enemy.__index = Enemy

Enemy.image = nil

local function loadEnemyImageOnce()
    if Enemy.image then return end
    local success, img = pcall(love.graphics.newImage, "assets/32x32/fb1.png")
    if success and img then
        Enemy.image = img
        Enemy.image:setFilter("nearest", "nearest")
    end
end

function Enemy:new(x, y)
    loadEnemyImageOnce()
    local enemy = {
        x = x or 0,
        y = y or 0,
        size = 12, -- size of the square (half-width/height)
        speed = 90, -- pixels per second (fast!)
        maxHealth = 25,
        health = 25,
        isAlive = true,
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8, -- how fast knockback fades

        -- Status Component
        statusComponent = StatusComponent:new(),
    }
    setmetatable(enemy, Enemy)
    return enemy
end

function Enemy:update(dt, playerX, playerY)
    -- Update status component
    if self.statusComponent then
        self.statusComponent:update(dt, self)
    end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end

    -- Update root (legacy - now handled by statusComponent)
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

function Enemy:applyRoot(duration, damageTakenMul)
    -- Apply via status component if available
    if self.statusComponent then
        self.statusComponent:applyStatus("rooted", 1, duration, { damage_taken_multiplier = damageTakenMul or 1.15 })
    end
    
    -- Legacy support
    self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
    self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Enemy:isRooted()
    if self.statusComponent and self.statusComponent:hasStatus("rooted") then
        return true
    end
    return self.rootedTime and self.rootedTime > 0
end

function Enemy:draw()
    if not self.isAlive then return end

    -- Check for JuiceManager flash (Power Shot impact) or regular flash
    local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
    
    if Enemy.image then
        local img = Enemy.image
        local w, h = img:getWidth(), img:getHeight()
        local scale = 1.2
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0.75, 0.75, 1)
        end
        love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Fallback: red square
    local r, g, b = 0.9, 0.1, 0.1
    if isFlashing then r, g, b = 1, 1, 1 end
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

