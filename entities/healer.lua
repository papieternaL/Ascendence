-- Healer Enemy - Support enemy that heals nearby wounded allies
local JuiceManager = require("systems.juice_manager")
local StatusComponent = require("systems.status_component")
local StatusEffects = require("systems.status_effects")

local Healer = {}
Healer.__index = Healer

Healer.image = nil

local function loadImageOnce()
    if Healer.image then return end
    local paths = {
        "assets/2D assets/Tiny Dungeon/Tiles/tile_0074.png",
        "assets/32x32/fb31.png",
    }
    for _, p in ipairs(paths) do
        local success, img = pcall(love.graphics.newImage, p)
        if success and img then
            Healer.image = img
            Healer.image:setFilter("nearest", "nearest")
            break
        end
    end
end

function Healer:new(x, y)
    loadImageOnce()
    local healer = {
        x = x or 0,
        y = y or 0,
        size = 14,
        speed = 60,  -- Slow movement
        maxHealth = 35,  -- Fragile
        health = 35,
        isAlive = true,
        damage = 0,  -- Does not attack player
        
        -- Healing properties
        healRange = 150,
        healAmount = 5,  -- HP per second
        healCooldown = 0.5,  -- Time between heal ticks
        healTimer = 0,
        currentTarget = nil,  -- Currently healing this enemy
        isHealing = false,
        
        -- Visual/animation
        flashTime = 0,
        flashDuration = 0.12,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 7,
        glowPhase = 0,  -- For pulsing glow effect
        
        -- Status Component
        statusComponent = StatusComponent:new(),
        statuses = {},
    }
    setmetatable(healer, Healer)
    return healer
end

function Healer:update(dt, playerX, playerY, allEnemies)
    if not self.isAlive then return end
    
    -- Update status component
    if self.statusComponent then
        self.statusComponent:update(dt, self)
    end
    
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
    
    -- Update glow animation
    self.glowPhase = self.glowPhase + dt * 3
    
    -- Update heal cooldown
    if self.healTimer > 0 then
        self.healTimer = self.healTimer - dt
    end
    
    -- Find wounded allies to heal
    local targetToHeal = nil
    local closestDist = math.huge
    
    if allEnemies then
        for _, enemy in ipairs(allEnemies) do
            if enemy ~= self and enemy.isAlive and enemy.health < enemy.maxHealth then
                local dx = enemy.x - self.x
                local dy = enemy.y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < self.healRange and dist < closestDist then
                    targetToHeal = enemy
                    closestDist = dist
                end
            end
        end
    end
    
    self.currentTarget = targetToHeal
    self.isHealing = (targetToHeal ~= nil and closestDist <= self.healRange)
    
    -- Perform healing
    if self.isHealing and self.healTimer <= 0 then
        self.healTimer = self.healCooldown
        local healAmount = self.healAmount * self.healCooldown
        self.currentTarget.health = math.min(self.currentTarget.maxHealth, self.currentTarget.health + healAmount)
    end
    
    -- Movement AI
    -- #region agent log
    local f = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a"); if f then f:write('{"location":"healer.lua:107","message":"healer_movement_check","data":{"hasStatusComponent":'..(self.statusComponent ~= nil and "true" or "false")..'},"hypothesisId":"H1","timestamp":'..os.time()..'}\n'); f:close(); end
    -- #endregion
    local isRooted = self.statusComponent and self.statusComponent:hasStatus("rooted")
    if not isRooted then
        local targetX, targetY
        
        if targetToHeal and closestDist > self.healRange * 0.7 then
            -- Move toward wounded ally
            targetX, targetY = targetToHeal.x, targetToHeal.y
        elseif playerX and playerY then
            -- No wounded allies, slowly approach player
            targetX, targetY = playerX, playerY
        end
        
        if StatusEffects.isFrozen(self) then
            self.x = self.x + self.knockbackX * dt
            self.y = self.y + self.knockbackY * dt
        elseif targetX and targetY then
            local dx = targetX - self.x
            local dy = targetY - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance > 0 then
                local effectiveSpeed = self.speed * StatusEffects.getSpeedMul(self)
                dx = dx / distance
                dy = dy / distance
                
                -- Move with knockback applied
                self.x = self.x + (dx * effectiveSpeed + self.knockbackX) * dt
                self.y = self.y + (dy * effectiveSpeed + self.knockbackY) * dt
            end
        else
            -- Just apply knockback
            self.x = self.x + self.knockbackX * dt
            self.y = self.y + self.knockbackY * dt
        end
    else
        -- Rooted, only apply knockback
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
    end
end

function Healer:takeDamage(amount, sourceX, sourceY, knockbackForce)
    if not self.isAlive then return false end
    
    self.health = self.health - amount
    self.flashTime = self.flashDuration
    
    -- Apply knockback
    if sourceX and sourceY and knockbackForce then
        local dx = self.x - sourceX
        local dy = self.y - sourceY
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            self.knockbackX = (dx / dist) * knockbackForce
            self.knockbackY = (dy / dist) * knockbackForce
        end
    end
    
    if self.health <= 0 then
        self.health = 0
        self.isAlive = false
        return true  -- Died
    end
    
    return false  -- Still alive
end

function Healer:draw()
    if not self.isAlive then return end
    
    -- Draw healing beam if actively healing (vibrant layered beam + green crosses)
    if self.isHealing and self.currentTarget then
        local tx, ty = self.currentTarget.x, self.currentTarget.y
        local dx = tx - self.x
        local dy = ty - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            local nx, ny = dx / dist, dy / dist
            -- Outer glow (thick, soft)
            love.graphics.setColor(0.2, 1, 0.5, 0.25)
            love.graphics.setLineWidth(14)
            love.graphics.line(self.x, self.y, tx, ty)
            -- Mid glow
            love.graphics.setColor(0.35, 1, 0.6, 0.5)
            love.graphics.setLineWidth(8)
            love.graphics.line(self.x, self.y, tx, ty)
            -- Core beam (bright)
            local pulse = 0.7 + math.sin(self.glowPhase * 6) * 0.3
            love.graphics.setColor(0.4, 1, 0.65, pulse)
            love.graphics.setLineWidth(4)
            love.graphics.line(self.x, self.y, tx, ty)
            love.graphics.setLineWidth(1)

            -- Green crosses traveling along beam (healing indicator)
            local crossCount = 4
            for i = 1, crossCount do
                local t = ((self.glowPhase * 2 + (i - 1) / crossCount) % 1)
                local cx = self.x + dx * t
                local cy = self.y + dy * t
                local crossSize = 5
                local alpha = 0.9 * (1 - math.abs(t - 0.5) * 1.2)
                if alpha > 0 then
                    love.graphics.setColor(0.3, 1, 0.4, alpha)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(cx - crossSize, cy, cx + crossSize, cy)
                    love.graphics.line(cx, cy - crossSize, cx, cy + crossSize)
                    love.graphics.setLineWidth(1)
                end
            end
        end

        -- Endpoint glows
        local pulseAlpha = 0.6 + math.sin(self.glowPhase * 4) * 0.4
        love.graphics.setColor(0.4, 1, 0.6, pulseAlpha)
        love.graphics.circle("fill", self.x, self.y, 10)
        love.graphics.circle("fill", tx, ty, 8)
    end
    
    -- Draw glow aura (pulsing)
    local pulse = 0.5 + math.sin(self.glowPhase) * 0.3
    love.graphics.setColor(0.3, 1, 0.5, pulse * 0.4)
    love.graphics.circle("fill", self.x, self.y, self.size + 10)
    
    -- Flash when damaged
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw healer sprite
    if Healer.image then
        local imgW = Healer.image:getWidth()
        local scale = (imgW <= 18) and ((self.size * 2) / 16) or ((self.size * 2) / imgW)
        love.graphics.draw(Healer.image, self.x, self.y, 0, scale, scale, Healer.image:getWidth()/2, Healer.image:getHeight()/2)
    else
        -- Fallback circle (green/white)
        love.graphics.setColor(0.4, 1, 0.6, 1)
        love.graphics.circle("fill", self.x, self.y, self.size)
        
        -- Cross symbol to indicate healer
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(self.x - 6, self.y, self.x + 6, self.y)
        love.graphics.line(self.x, self.y - 6, self.x, self.y + 6)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Healer:getPosition()
    return self.x, self.y
end

function Healer:getSize()
    return self.size
end

function Healer:applyRoot(duration, damageTakenMul)
    if self.statusComponent then
        self.statusComponent:applyStatus("rooted", duration)
    end
end

return Healer
