-- Wizard Enemy - Cone Attack + Root (MCM)
-- Teaches positioning and root escape for boss Phase 2
local JuiceManager = require("systems.juice_manager")
local StatusEffects = require("systems.status_effects")

local Wizard = {}
Wizard.__index = Wizard

Wizard.image = nil

function Wizard:new(x, y)
    -- Load sprite (Tiny Dungeon mage, then fallback)
    if not Wizard.image then
        local paths = {
            "assets/2D assets/Tiny Dungeon/Tiles/tile_0072.png",
            "assets/32x32/fb1400.png",
        }
        for _, p in ipairs(paths) do
            local success, result = pcall(love.graphics.newImage, p)
            if success and result then
                Wizard.image = result
                Wizard.image:setFilter("nearest", "nearest")
                break
            end
        end
    end
    
    local wizard = {
        x = x or 0,
        y = y or 0,
        size = 16,
        speed = 45, -- Moderate movement
        maxHealth = 45, -- Medium tankiness
        health = 45,
        isAlive = true,
        isMCM = true, -- Mechanic-Carrying Minion
        damage = 10,
        
        -- Cone attack behavior
        coneCooldown = 0,
        coneInterval = 5.0, -- Cone attack every 5s (slower for dodge window)
        coneRange = 280, -- Max range for cone
        coneAngle = math.pi / 3, -- 60-degree cone
        rootDuration = 1.5, -- How long root lasts
        
        -- Visual feedback
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,
        
        -- Cast animation
        isCasting = false,
        castTime = 0,
        castDuration = 1.15, -- Telegraph before cone fires (0.2s longer for visibility)
        coneFiredAt = nil,
        coneFiredAngle = 0,
        statuses = {},
        glowPhase = 0,
    }
    setmetatable(wizard, Wizard)
    return wizard
end

function Wizard:update(dt, playerX, playerY, onConeAttack)
    if not self.isAlive then return end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end

    self.glowPhase = (self.glowPhase or 0) + dt * 3

    -- Update knockback
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
    
    -- Calculate distance to player
    local dx = playerX - self.x
    local dy = playerY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Casting animation
    if self.isCasting then
        self.castTime = self.castTime + dt
        if self.castTime >= self.castDuration then
            -- Fire cone attack
            self.isCasting = false
            self.castTime = 0
            if onConeAttack then
                local angleToPlayer = math.atan2(dy, dx)
                self.coneFiredAt = love.timer.getTime()
                self.coneFiredAngle = angleToPlayer
                onConeAttack(self.x, self.y, angleToPlayer, self.coneAngle, self.coneRange, self.rootDuration)
            end
        end
        -- Don't move while casting
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        return
    end

    if StatusEffects.isFrozen(self) then
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        return
    end

    local effectiveSpeed = self.speed * StatusEffects.getSpeedMul(self)
    
    -- Behavior: stay at medium range
    if distance > self.coneRange * 0.7 then
        -- Move closer
        local normDx = dx / distance
        local normDy = dy / distance
        self.x = self.x + normDx * effectiveSpeed * dt + self.knockbackX * dt
        self.y = self.y + normDy * effectiveSpeed * dt + self.knockbackY * dt
    elseif distance < self.coneRange * 0.4 then
        -- Back away
        local normDx = dx / distance
        local normDy = dy / distance
        self.x = self.x - normDx * effectiveSpeed * dt + self.knockbackX * dt
        self.y = self.y - normDy * effectiveSpeed * dt + self.knockbackY * dt
    else
        -- In range: prepare to cast
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
    end
    
    -- Cone attack cooldown
    self.coneCooldown = self.coneCooldown - dt
    if self.coneCooldown <= 0 and distance < self.coneRange and not self.isCasting then
        self.coneCooldown = self.coneInterval
        self.isCasting = true
        self.castTime = 0
    end
end

function Wizard:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    self.health = self.health - damage
    self.flashTime = self.flashDuration
    
    -- Interrupt casting if hit
    if self.isCasting then
        self.isCasting = false
        self.castTime = 0
        self.coneCooldown = 1.0 -- Short cooldown after interrupt
    end
    
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

function Wizard:draw()
    if not self.isAlive then return end
    
    -- MCM glow (subtle purple/blue to indicate importance)
    love.graphics.setColor(0.5, 0.3, 1, 0.15)
    love.graphics.circle("fill", self.x, self.y, self.size + 8)
    
    -- Cast telegraph (growing circle) - brighter for visibility
    if self.isCasting then
        local castProgress = self.castTime / self.castDuration
        love.graphics.setColor(1.0, 0.4, 1.0, 0.5 + castProgress * 0.4)
        love.graphics.circle("fill", self.x, self.y, self.size + castProgress * 20)
    end
    
    -- Cone just fired: draw cone hitbox so player sees what hit them (0.4s visibility)
    if self.coneFiredAt then
        local age = love.timer.getTime() - self.coneFiredAt
        if age >= 0.4 then
            self.coneFiredAt = nil
        else
            local half = self.coneAngle / 2
            local r = self.coneRange
            local x1 = self.x + math.cos(self.coneFiredAngle - half) * r
            local y1 = self.y + math.sin(self.coneFiredAngle - half) * r
            local x2 = self.x + math.cos(self.coneFiredAngle + half) * r
            local y2 = self.y + math.sin(self.coneFiredAngle + half) * r
            local alpha = 0.7 * (1 - age / 0.4)
            love.graphics.setColor(1.0, 0.4, 1.0, alpha)
            love.graphics.polygon("fill", self.x, self.y, x1, y1, x2, y2)
        end
    end
    
    -- Draw sprite
    local img = Wizard.image
    if img then
        local imgW = img:getWidth()
        local scale = (imgW <= 18) and 1.5 or 1.0  -- Tiny 16px sprites scale up
        local imgH = img:getHeight()
        
        -- Flash effect or normal color (check JuiceManager too)
        local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
        if isFlashing then
            love.graphics.setColor(1, 1, 1, 1)
        else
            -- Dark/purple tint for scorpion theme
            love.graphics.setColor(0.8, 0.6, 1, 1)
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
        -- Fallback: purple circle
        if self.flashTime > 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.6, 0.3, 0.9, 1)
        end
        love.graphics.circle("fill", self.x, self.y, self.size)
    end

    -- Staff overlay (procedural, cast animation)
    local staffLen = 22
    local staffAngle
    if self.isCasting then
        local castProgress = self.castTime / self.castDuration
        staffAngle = -math.pi / 2 + castProgress * (math.pi / 2)
    else
        staffAngle = -math.pi / 2 + math.sin(self.glowPhase or 0) * 0.1
    end
    local sx = self.x + math.cos(staffAngle) * staffLen * 0.4
    local sy = self.y + math.sin(staffAngle) * staffLen * 0.4
    local ex = self.x + math.cos(staffAngle) * staffLen
    local ey = self.y + math.sin(staffAngle) * staffLen
    love.graphics.setColor(0.5, 0.35, 0.2, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(sx, sy, ex, ey)
    if self.isCasting then
        local pulse = 0.6 + math.sin((self.glowPhase or 0) * 8) * 0.4
        love.graphics.setColor(1, 0.6, 1, pulse)
        love.graphics.circle("fill", ex, ey, 4)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1, 1)
end

function Wizard:getPosition()
    return self.x, self.y
end

function Wizard:getSize()
    return self.size
end

function Wizard:isDead()
    return not self.isAlive
end

function Wizard:applyRoot(duration, damageMultiplier)
    -- Wizard can be rooted (not immune)
    self.isRooted = true
    self.rootDuration = duration
    self.rootDamageMultiplier = damageMultiplier or 1.0
end

return Wizard

