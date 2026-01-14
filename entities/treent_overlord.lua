-- Treent Overlord Boss
-- Phase 1: Lunge + Bark Barrage
-- Phase 2 (50% HP): Encompass Root + Territory Control (vine lanes)

local Config = require("data.config")
local JuiceManager = require("systems.juice_manager")

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

    local cfg = Config.TreentOverlord
    local boss = {
        x = x or 0,
        y = y or 0,
        size = cfg.size,
        speed = cfg.speed,
        maxHealth = cfg.maxHealth,
        health = cfg.maxHealth,
        isAlive = true,
        damage = cfg.damage,
        isBoss = true,
        isInvulnerable = false,  -- Set true during phase 2 earthquake mechanic
        
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
        lungeChargeDuration = cfg.lungeChargeDuration,
        lungeDuration = cfg.lungeDuration,
        lungeCooldown = cfg.lungeCooldown,
        lungeRange = 500,
        lungeTargetX = 0,
        lungeTargetY = 0,
        lungeDirX = 0,
        lungeDirY = 0,
        lungeSpeed = cfg.lungeSpeed,
        
        -- Phase 1: Bark Barrage
        barkBarrageTimer = 0,
        barkBarrageCooldown = cfg.barkBarrageCooldown,
        barkBarrageCount = cfg.barkBarrageCount,
        barkBarrageDelay = cfg.barkBarrageDelay,
        barkBarrageIndex = 0,  -- Current projectile being fired
        barkBarrageActive = false,
        barkBarrageInternalTimer = 0,
        
        -- Phase 2: Root status
        rootDuration = 0,
        rootedAt = 0,
        isRooted = false,
        damageTakenMultiplier = 1.0,
        
        -- Phase 2: Encompass Root (boss roots the player)
        encompassRootActive = false,
        encompassRootDuration = cfg.encompassRootDuration,
        encompassRootTimer = 0,
        rootEntities = {}, -- Roots the player must destroy
        
        -- Phase 2: Territory Control (earthquake)
        earthquakeTimer = 0,
        earthquakeCooldown = cfg.earthquakeCooldown,
        earthquakeDuration = cfg.earthquakeDuration,
        earthquakeCastTime = cfg.earthquakeCastTime,
        earthquakeCasting = false,
        earthquakeCastProgress = 0,
        earthquakeActive = false,
        earthquakeElapsed = 0,
        safeZones = {}, -- Array of safe zone positions
    }
    
    setmetatable(boss, TreentOverlord)
    return boss
end

function TreentOverlord:update(dt, playerX, playerY, onBarkShoot, onPhaseTransition, onEncompassRoot, onVineLanes)
    if not self.isAlive then return end
    
    -- Check for phase transition (50% HP)
    if self.phase == 1 and self.health <= self.maxHealth * 0.5 and not self.phaseTransitionTriggered then
        self.phase = 2
        self.phaseTransitionTriggered = true
        self.lungeState = "idle"
        self.lungeTimer = 0
        self.barkBarrageTimer = 0
        self.barkBarrageActive = false
        
        -- Teleport to center of arena
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        self.x = screenWidth / 2
        self.y = screenHeight / 2
        
        if onPhaseTransition then
            onPhaseTransition()
        end
    end
    
    -- Update visuals
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Apply knockback friction
    self.knockbackX = self.knockbackX * Config.Vfx.knockbackFriction
    self.knockbackY = self.knockbackY * Config.Vfx.knockbackFriction
    
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
        self:updatePhase2(dt, playerX, playerY, onEncompassRoot, onVineLanes)
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
    
    -- Bark Barrage attack (ONLY when not lunging)
    if self.lungeState == "idle" then
        if not self.barkBarrageActive then
            self.barkBarrageTimer = self.barkBarrageTimer + dt
            if self.barkBarrageTimer >= self.barkBarrageCooldown then
                -- Start barrage
                self.barkBarrageActive = true
                self.barkBarrageIndex = 0
                self.barkBarrageInternalTimer = 0
                self.barkBarrageTimer = 0
            end
        else
            -- Fire projectiles in sequence (CONE ATTACK toward player)
            self.barkBarrageInternalTimer = self.barkBarrageInternalTimer + dt
            if self.barkBarrageInternalTimer >= self.barkBarrageDelay and self.barkBarrageIndex < self.barkBarrageCount then
                self.barkBarrageInternalTimer = 0
                self.barkBarrageIndex = self.barkBarrageIndex + 1
                
                -- Fire one projectile in cone toward player
                if onBarkShoot then
                    -- Calculate base angle toward player
                    local dx = playerX - self.x
                    local dy = playerY - self.y
                    local baseAngle = math.atan2(dy, dx)
                    
                    -- Cone spread: 60 degrees total (30 degrees each side)
                    local coneSpread = math.rad(60)
                    local spreadOffset = (self.barkBarrageIndex / self.barkBarrageCount - 0.5) * coneSpread
                    local angle = baseAngle + spreadOffset
                    
                    local targetX = self.x + math.cos(angle) * 500
                    local targetY = self.y + math.sin(angle) * 500
                    onBarkShoot(self.x, self.y, targetX, targetY)
                end
            end
            
            -- End barrage when all projectiles fired
            if self.barkBarrageIndex >= self.barkBarrageCount then
                self.barkBarrageActive = false
            end
        end
    end
end

function TreentOverlord:updatePhase2(dt, playerX, playerY, onEncompassRoot, onVineLanes)
    -- Encompass Root: Boss roots the player and starts earthquake sequence
    if not self.encompassRootActive then
        self.encompassRootTimer = self.encompassRootTimer + dt
        if self.encompassRootTimer >= 3.0 then -- Every 3s, attempt sequence
            self.encompassRootActive = true
            self.encompassRootTimer = 0
            
            -- SYNC EARTHQUAKE START (Pressure!)
            self.earthquakeCasting = true
            self.earthquakeCastProgress = 0
            self.earthquakeTimer = 0
            self.earthquakeActive = false
            self.isInvulnerable = true  -- Boss is invulnerable during earthquake mechanic
            
            if onEncompassRoot then
                onEncompassRoot(playerX, playerY)
            end
        end
    else
        -- Sequence is active, count down duration (boss can lunge/bark during this)
        self.encompassRootTimer = self.encompassRootTimer + dt
        if self.encompassRootTimer >= self.encompassRootDuration then
            self.encompassRootActive = false
            self.encompassRootTimer = 0
            self.isInvulnerable = false  -- End invulnerability when mechanic ends
        end
    end
    
    -- Territory Control: Vine Lanes attack with cast time
    if self.earthquakeCasting then
        -- Casting vine attack (show cast bar)
        self.earthquakeCastProgress = self.earthquakeCastProgress + dt
        if self.earthquakeCastProgress >= self.earthquakeCastTime then
            -- Cast complete, start vine lanes!
            self.earthquakeCasting = false
            self.earthquakeActive = true
            self.earthquakeElapsed = 0
            if onVineLanes then
                onVineLanes("start")
            end
        end
    elseif self.earthquakeActive then
        -- Vine lanes are active
        self.earthquakeElapsed = self.earthquakeElapsed + dt
        if self.earthquakeElapsed >= self.earthquakeDuration then
            self.earthquakeActive = false
            self.earthquakeTimer = 0
            if onVineLanes then
                onVineLanes("end")
            end
        end
    end
end

function TreentOverlord:draw()
    if not self.isAlive then return end
    
    -- Draw boss with size scaling and phase color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Flash white when hit (check both local flash and JuiceManager flash)
    local isFlashing = self.flashTime > 0 or JuiceManager.isFlashing(self)
    if isFlashing then
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
    
    -- Cast bar (VINE ATTACK TELEGRAPH)
    if self.earthquakeCasting then
        local castPercent = self.earthquakeCastProgress / self.earthquakeCastTime
        local barWidth = 140
        local barHeight = 12
        local barY = self.y - self.size - 50
        
        -- Background
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth, barHeight)
        
        -- Cast progress (green = vine attack!)
        love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", self.x - barWidth/2, barY, barWidth * castPercent, barHeight)
        
        -- Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x - barWidth/2, barY, barWidth, barHeight)
        love.graphics.setLineWidth(1)
        
        -- Text
        love.graphics.setColor(0.3, 1, 0.3, 1)
        love.graphics.print("VINE ATTACK!", self.x - 40, barY - 15)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function TreentOverlord:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    -- Boss is invulnerable during phase 2 earthquake mechanic
    if self.isInvulnerable then
        return false  -- No damage taken
    end
    
    -- Apply damage taken multiplier (rooted = more damage)
    local finalDamage = damage * self.damageTakenMultiplier
    self.health = self.health - finalDamage
    self.flashTime = Config.Vfx.hitFlashDuration
    
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
