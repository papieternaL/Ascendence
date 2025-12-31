-- Treent Overlord Boss
-- Phase 1: Lunge + Bark Barrage
-- Phase 2 (50% HP): Encompass Root + Territory Control (earthquake)

local TreentOverlord = {}
TreentOverlord.__index = TreentOverlord
TreentOverlord.image = nil

function TreentOverlord:new(x, y)
    -- Load sprite (boss version of Treent)
    if not TreentOverlord.image then
        local success, img = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
        if success then
            TreentOverlord.image = img
        end
    end

    local boss = {
        x = x or 0,
        y = y or 0,
        size = 48, -- Much bigger than normal enemies
        speed = 35,
        maxHealth = 2000,
        health = 2000,
        isAlive = true,
        damage = 40,
        isBoss = true,
        
        -- Visual
        flashTime = 0,
        knockbackX = 0,
        knockbackY = 0,
        
        -- Phase tracking
        phase = 1,
        phaseTransitionTriggered = false,
        
        -- Phase 1: Lunge
        lungeState = "idle", -- idle, charging, lunging, cooldown
        lungeTimer = 0,
        lungeChargeDuration = 1.2,
        lungeDuration = 0.5,
        lungeCooldown = 2.0,
        lungeRange = 500,
        lungeTargetX = 0,
        lungeTargetY = 0,
        lungeDirX = 0,
        lungeDirY = 0,
        lungeSpeed = 800,
        
        -- Phase 1: Bark Barrage
        barkBarrageTimer = 0,
        barkBarrageCooldown = 4.0,
        barkBarrageCount = 8, -- Shoots 8 projectiles in a circle
        
        -- Phase 2: Root status
        rootDuration = 0,
        rootedAt = 0,
        isRooted = false,
        damageTakenMultiplier = 1.0,
        
        -- Phase 2: Encompass Root (boss roots the player)
        encompassRootActive = false,
        encompassRootDuration = 8.0,
        encompassRootTimer = 0,
        rootEntities = {}, -- Roots the player must destroy
        
        -- Phase 2: Territory Control (earthquake)
        earthquakeTimer = 0,
        earthquakeCooldown = 10.0,
        earthquakeDuration = 3.0,
        earthquakeActive = false,
        earthquakeElapsed = 0,
        safeZones = {}, -- Array of safe zone positions
    }
    
    setmetatable(boss, TreentOverlord)
    return boss
end

function TreentOverlord:update(dt, playerX, playerY, onBarkShoot, onPhaseTransition, onEncompassRoot, onEarthquake)
    if not self.isAlive then return end
    
    -- Check for phase transition (50% HP)
    if self.phase == 1 and self.health <= self.maxHealth * 0.5 and not self.phaseTransitionTriggered then
        self.phase = 2
        self.phaseTransitionTriggered = true
        self.lungeState = "idle"
        self.lungeTimer = 0
        self.barkBarrageTimer = 0
        if onPhaseTransition then
            onPhaseTransition()
        end
    end
    
    -- Update visuals
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Apply knockback friction
    self.knockbackX = self.knockbackX * 0.85
    self.knockbackY = self.knockbackY * 0.85
    
    -- Apply knockback movement
    self.x = self.x + self.knockbackX * dt
    self.y = self.y + self.knockbackY * dt
    
    -- Root status (only for Phase 2 mechanics)
    if self.isRooted then
        self.rootDuration = self.rootDuration - dt
        if self.rootDuration <= 0 then
            self.isRooted = false
            self.damageTakenMultiplier = 1.0
        end
    end
    
    -- === PHASE 1 LOGIC ===
    if self.phase == 1 then
        self:updatePhase1(dt, playerX, playerY, onBarkShoot)
    end
    
    -- === PHASE 2 LOGIC ===
    if self.phase == 2 then
        self:updatePhase2(dt, playerX, playerY, onEncompassRoot, onEarthquake)
    end
end

function TreentOverlord:updatePhase1(dt, playerX, playerY, onBarkShoot)
    -- Lunge attack
    if self.lungeState == "idle" then
        self.lungeTimer = self.lungeTimer + dt
        if self.lungeTimer >= self.lungeCooldown then
            -- Start charging lunge
            self.lungeState = "charging"
            self.lungeTimer = 0
            -- Set lunge target to player's current position
            self.lungeTargetX = playerX
            self.lungeTargetY = playerY
            local dx = self.lungeTargetX - self.x
            local dy = self.lungeTargetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                self.lungeDirX = dx / dist
                self.lungeDirY = dy / dist
            end
        end
    elseif self.lungeState == "charging" then
        self.lungeTimer = self.lungeTimer + dt
        if self.lungeTimer >= self.lungeChargeDuration then
            -- Execute lunge
            self.lungeState = "lunging"
            self.lungeTimer = 0
        end
    elseif self.lungeState == "lunging" then
        self.lungeTimer = self.lungeTimer + dt
        -- Move in lunge direction
        self.x = self.x + self.lungeDirX * self.lungeSpeed * dt
        self.y = self.y + self.lungeDirY * self.lungeSpeed * dt
        if self.lungeTimer >= self.lungeDuration then
            self.lungeState = "idle"
            self.lungeTimer = 0
        end
    end
    
    -- Bark Barrage attack
    self.barkBarrageTimer = self.barkBarrageTimer + dt
    if self.barkBarrageTimer >= self.barkBarrageCooldown then
        self.barkBarrageTimer = 0
        -- Shoot bark projectiles in all directions
        if onBarkShoot then
            for i = 1, self.barkBarrageCount do
                local angle = (i / self.barkBarrageCount) * math.pi * 2
                local targetX = self.x + math.cos(angle) * 500
                local targetY = self.y + math.sin(angle) * 500
                onBarkShoot(self.x, self.y, targetX, targetY)
            end
        end
    end
end

function TreentOverlord:updatePhase2(dt, playerX, playerY, onEncompassRoot, onEarthquake)
    -- Encompass Root: Boss roots the player and spawns root entities
    if not self.encompassRootActive then
        self.encompassRootTimer = self.encompassRootTimer + dt
        if self.encompassRootTimer >= 3.0 then -- Every 3s, attempt encompass root
            self.encompassRootActive = true
            self.encompassRootTimer = 0
            if onEncompassRoot then
                onEncompassRoot(playerX, playerY)
            end
        end
    else
        -- Encompass root is active, count down duration
        self.encompassRootTimer = self.encompassRootTimer + dt
        if self.encompassRootTimer >= self.encompassRootDuration then
            self.encompassRootActive = false
            self.encompassRootTimer = 0
        end
    end
    
    -- Territory Control: Earthquake with safe zones
    if not self.earthquakeActive then
        self.earthquakeTimer = self.earthquakeTimer + dt
        if self.earthquakeTimer >= self.earthquakeCooldown then
            self.earthquakeActive = true
            self.earthquakeTimer = 0
            self.earthquakeElapsed = 0
            if onEarthquake then
                onEarthquake("start")
            end
        end
    else
        self.earthquakeElapsed = self.earthquakeElapsed + dt
        if self.earthquakeElapsed >= self.earthquakeDuration then
            self.earthquakeActive = false
            self.earthquakeTimer = 0
            if onEarthquake then
                onEarthquake("end")
            end
        end
    end
end

function TreentOverlord:draw()
    if not self.isAlive then return end
    
    -- Draw boss with size scaling and phase color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Flash white when hit
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    else
        -- Phase 1: Green, Phase 2: Dark Red
        if self.phase == 1 then
            love.graphics.setColor(0.3, 1, 0.3, 1)
        else
            love.graphics.setColor(1, 0.3, 0.3, 1)
        end
    end
    
    -- Charging lunge: visual indicator
    if self.lungeState == "charging" then
        love.graphics.setColor(1, 0.5, 0, 1)
    end
    
    if TreentOverlord.image then
        local scale = self.size / 16
        love.graphics.draw(TreentOverlord.image, self.x, self.y, 0, scale, scale, 8, 8)
    else
        love.graphics.circle("fill", self.x, self.y, self.size)
    end
    
    -- Draw health bar (boss-specific, large and centered above)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x - 60, self.y - self.size - 20, 120, 10)
    
    local healthPercent = self.health / self.maxHealth
    if healthPercent > 0.5 then
        love.graphics.setColor(0, 1, 0, 1)
    elseif healthPercent > 0.25 then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 0, 0, 1)
    end
    love.graphics.rectangle("fill", self.x - 60, self.y - self.size - 20, 120 * healthPercent, 10)
    
    -- Phase indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("PHASE " .. self.phase, self.x - 30, self.y - self.size - 35)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function TreentOverlord:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    -- Apply damage taken multiplier (rooted = more damage)
    local finalDamage = damage * self.damageTakenMultiplier
    self.health = self.health - finalDamage
    self.flashTime = 0.1
    
    -- Knockback (reduced for boss)
    if hitX and hitY and knockbackForce then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            self.knockbackX = (dx / distance) * (knockbackForce * 0.3) -- Boss resists knockback
            self.knockbackY = (dy / distance) * (knockbackForce * 0.3)
        end
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true -- Died
    end
    return false
end

function TreentOverlord:getPosition()
    return self.x, self.y
end

function TreentOverlord:getSize()
    return self.size
end

function TreentOverlord:isDead()
    return not self.isAlive
end

function TreentOverlord:applyRoot(duration, damageTakenMultiplier)
    self.isRooted = true
    self.rootDuration = duration
    self.damageTakenMultiplier = damageTakenMultiplier or 1.15
end

function TreentOverlord:isCharging()
    return self.lungeState == "charging"
end

function TreentOverlord:isLunging()
    return self.lungeState == "lunging"
end

return TreentOverlord

