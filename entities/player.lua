local Config = require("data.config")
local PlayerAnimator = require("systems.player_animator")
local StatusComponent = require("systems.status_component")

-- Player Entity (Archer Class)
local Player = {}
Player.__index = Player

-- Static bow image (loaded once)
Player.bowImage = nil

function Player:new(x, y)
    -- Load bow image if not loaded
    if not Player.bowImage then
        local success, result = pcall(love.graphics.newImage, "assets/32x32/fb1705.png")
        if success then
            Player.bowImage = result
            Player.bowImage:setFilter("nearest", "nearest")
        end
    end

    
    local cfg = Config.Player
    local aCfg = Config.Abilities
    local player = {
        x = x or 0,
        y = y or 0,
        speed = cfg.baseSpeed, -- pixels per second
        size = 20, -- radius of the player circle
        bobOffset = 0, -- current bobbing offset
        bobSpeed = 8, -- bobbing animation speed
        bobAmount = 3, -- how much the player bobs (in pixels)
        isMoving = false,
        bobTime = 0, -- time accumulator for bobbing
        -- Health system
        maxHealth = cfg.baseHealth,
        health = cfg.baseHealth,
        invincibleTime = 0, -- invincibility frames after taking damage
        invincibleDuration = 0.5, -- seconds of invincibility after hit
        -- Root status (boss mechanic)
        isRooted = false,
        rootDuration = 0,
        rootedAt = 0,
        -- Combat stats
        attackDamage = cfg.baseAttack,
        attackRange = cfg.attackRange,
        attackSpeed = cfg.fireRate,
        heroClass = "archer",
        -- Bow aiming
        bowAngle = 0, -- angle the bow is pointing
        lastMoveX = 1, -- last movement direction x
        lastMoveY = 0, -- last movement direction y

        -- Bow presentation / feel
        bowScale = 0.6,      -- Smaller bow
        bowOffsetDist = 10,  -- Much closer to body
        bowRecoilTime = 0,
        bowRecoilDuration = 0.08,
        bowShotTime = 0,
        bowShotDuration = 0.06,
        -- Abilities with cooldowns
        -- Unlock order: Dash (always), Power Shot OR Arrow Volley (Level 0 choice),
        --               the other at Level 3 (auto), Frenzy at Level 6 (auto)
        abilities = {
            power_shot = {
                name = "Power Shot",
                key = "Q",
                icon = "⚡",
                cooldown = aCfg.powerShot.cooldown,
                currentCooldown = 0,
                unlocked = false,  -- Level 0 choice OR auto-unlock at Level 3
                unlockLevel = 0,
            },
            arrow_volley = {
                name = "Arrow Volley",
                key = "E",
                icon = "🏹",
                cooldown = 8.0,
                currentCooldown = 0,
                unlocked = false,  -- Level 0 choice OR auto-unlock at Level 3
                unlockLevel = 0,
            },
            frenzy = {
                name = "Frenzy",
                key = "R",
                icon = "🔥",
                cooldown = 15.0,
                currentCooldown = 0,
                unlocked = false,  -- Auto-unlock at Level 6 (ultimate)
                unlockLevel = 6,
            },
            dash = {
                name = "Dash",
                key = "SPACE",
                icon = "💨",
                cooldown = cfg.dashCooldown,
                currentCooldown = 0,
                unlocked = false,  -- Always unlocked (utility ability)
                unlockLevel = 0,
            },
        },
        -- Ability order for display
        abilityOrder = { "power_shot", "dash", "arrow_volley", "frenzy" },
        
        -- Animation
        animator = nil,
        facingDirection = "down",  -- down, right, up, left
        
        -- Status Component
        statusComponent = StatusComponent:new(),
        
        -- Upgrade tracking
        ownedUpgrades = {},
        procs = {},
        weaponMods = {},
        
        -- Frenzy VFX
        isFrenzyActive = false,
    }
    
    -- Initialize animator
    player.animator = PlayerAnimator:new()
    if player.animator then
        player.animator:setDirection("down")
    end
    
    setmetatable(player, Player)
    return player
end

function Player:update(dt, particles)
    -- Update status component
    if self.statusComponent then
        self.statusComponent:update(dt, self)
    end
    
    -- Spawn Frenzy mist particles when active and moving
    if self.isFrenzyActive and particles then
        self.frenzyMistTimer = (self.frenzyMistTimer or 0) + dt
        if self.frenzyMistTimer >= 0.05 then  -- Spawn every 0.05 seconds
            particles:createFrenzyMist(self.x, self.y)
            self.frenzyMistTimer = 0
        end
    end
    
    -- Update invincibility
    if self.invincibleTime > 0 then
        self.invincibleTime = self.invincibleTime - dt
    end

    -- Update root status
    if self.isRooted then
        self.rootDuration = self.rootDuration - dt
        if self.rootDuration <= 0 then
            self.isRooted = false
        end
    end

    -- Bow recoil decay
    if self.bowRecoilTime and self.bowRecoilTime > 0 then
        self.bowRecoilTime = math.max(0, self.bowRecoilTime - dt)
    end
    if self.bowShotTime and self.bowShotTime > 0 then
        self.bowShotTime = math.max(0, self.bowShotTime - dt)
    end
    
    -- Update ability cooldowns
    for _, ability in pairs(self.abilities) do
        if ability.currentCooldown and ability.currentCooldown > 0 then
            ability.currentCooldown = ability.currentCooldown - dt
            if ability.currentCooldown < 0 then
                ability.currentCooldown = 0
            end
        end
    end
    
    -- Get input (skip if rooted)
    local dx, dy = 0, 0
    
    if not self.isRooted then
        -- Check for arrow keys or WASD
        if love.keyboard.isDown("left", "a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right", "d") then
        dx = dx + 1
    end
    if love.keyboard.isDown("up", "w") then
        dy = dy - 1
    end
    if love.keyboard.isDown("down", "s") then
        dy = dy + 1
    end
    
    -- Store last movement direction for bow aim
    if dx ~= 0 or dy ~= 0 then
        self.lastMoveX = dx
        self.lastMoveY = dy
        
        -- Update facing direction based on primary movement axis
        -- Prioritize horizontal/vertical based on which is dominant
        if math.abs(dx) > math.abs(dy) then
            self.facingDirection = dx > 0 and "right" or "left"
        else
            self.facingDirection = dy > 0 and "down" or "up"
        end
        
        -- Update animator direction
        if self.animator then
            self.animator:setDirection(self.facingDirection)
        end
    end
    
    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.707 -- 1/sqrt(2) for diagonal normalization
        dy = dy * 0.707
    end
    
    -- Update position
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
    
    -- Check if moving
    self.isMoving = (dx ~= 0 or dy ~= 0)
    end -- End of "if not self.isRooted" block
    
    -- Update bobbing animation when moving
    if self.isMoving then
        self.bobTime = self.bobTime + dt * self.bobSpeed
        self.bobOffset = math.sin(self.bobTime) * self.bobAmount
    else
        -- Reset bobbing when not moving
        self.bobTime = 0
        self.bobOffset = 0
    end
    
    -- Update animator state and frame
    if self.animator then
        if self.isMoving then
            self.animator:setState("walk")
        else
            self.animator:setState("idle")
        end
        self.animator:update(dt)
    end
    
    -- Keep player within world bounds
    local worldWidth = Config.World and Config.World.width or love.graphics.getWidth()
    local worldHeight = Config.World and Config.World.height or love.graphics.getHeight()
    self.x = math.max(self.size, math.min(worldWidth - self.size, self.x))
    self.y = math.max(self.size, math.min(worldHeight - self.size, self.y))
end

function Player:aimAt(targetX, targetY)
    -- Update bow angle to aim at target
    local dx = targetX - self.x
    local dy = targetY - self.y
    self.bowAngle = math.atan2(dy, dx)
end

function Player:takeDamage(amount)
    -- Only take damage if not invincible
    if self.invincibleTime <= 0 then
        self.health = self.health - amount
        self.invincibleTime = self.invincibleDuration
        
        -- Break buffs that break on hit taken
        if self.statusComponent then
            self.statusComponent:checkBreakConditions("hit_taken")
        end
        
        if self.health <= 0 then
            self.health = 0
            return true -- Player died
        end
    end
    return false
end

function Player:draw()
    -- Draw player with bobbing effect
    local drawY = self.y + self.bobOffset
    
    -- Draw Frenzy glow aura BEFORE the player sprite (additive blending)
    if self.isFrenzyActive then
        local time = love.timer.getTime()
        local slowPulse = 0.5 + math.sin(time * 2) * 0.5
        
        love.graphics.setBlendMode("add")
        
        -- Ground glow (beneath player)
        love.graphics.setColor(1.0, 0.5, 0.1, slowPulse * 0.4)
        love.graphics.circle("fill", self.x, self.y + 5, self.size + 15)
        
        -- Expanding aura rings (multiple) - keep these
        for i = 1, 3 do
            local ringPhase = (time * 2 + i * 0.5) % 2
            local ringRadius = self.size + 10 + (ringPhase * 25)
            local ringAlpha = (1 - ringPhase / 2) * 0.4
            
            love.graphics.setColor(1.0, 0.6, 0.1, ringAlpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", self.x, drawY, ringRadius)
        end
        
        -- Removed: Filled circle glow layers that clashed with mist particles
        -- The mist particles and expanding rings provide enough visual feedback
        
        love.graphics.setLineWidth(1)
        love.graphics.setBlendMode("alpha")
    end
    
    -- Flash when invincible
    if self.invincibleTime > 0 then
        -- Blink effect
        if math.floor(self.invincibleTime * 10) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw the archer using animator
    if self.animator then
        -- Scale to fit hitbox (target height ~64 pixels)
        local frameW, frameH = self.animator:getFrameSize()
        local targetHeight = 64
        local scale = targetHeight / frameH
        
        self.animator:draw(self.x, drawY, scale)
    else
        -- Fallback to circle if animator failed to load
        love.graphics.setColor(0.2, 0.6, 1, 1)
        love.graphics.circle("fill", self.x, drawY, self.size)
        
        -- Draw eyes (only for circle fallback)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", self.x - 5, drawY - 5, 4)
        love.graphics.circle("fill", self.x + 5, drawY - 5, 4)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", self.x - 5, drawY - 5, 2)
        love.graphics.circle("fill", self.x + 5, drawY - 5, 2)
    end
    
    -- Draw ROOTED indicator
    if self.isRooted then
        -- Pulsing red/brown roots around player
        local pulse = 0.5 + math.sin(love.timer.getTime() * 8) * 0.5
        love.graphics.setColor(0.6, 0.3, 0.1, 0.8 * pulse)
        love.graphics.setLineWidth(6)
        love.graphics.circle("line", self.x, drawY, self.size + 8)
        love.graphics.circle("line", self.x, drawY, self.size + 12)
        love.graphics.setLineWidth(1)
        
        -- ROOTED text above player
        love.graphics.setColor(1, 0.3, 0.3, 1)
        local text = "ROOTED!"
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(text)
        love.graphics.print(text, self.x - textWidth/2, drawY - self.size - 25)
        
        -- Duration bar
        if self.rootDuration > 0 then
            local barWidth = 40
            local barHeight = 4
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", self.x - barWidth/2, drawY - self.size - 15, barWidth, barHeight)
            love.graphics.setColor(0.8, 0.4, 0, 1)
            love.graphics.rectangle("fill", self.x - barWidth/2, drawY - self.size - 15, barWidth * (self.rootDuration / 8), barHeight)
        end
    end
    
    -- Draw eyes (removed pupils/eyes because we have a sprite now, but kept in fallback above)
    
    -- Draw bow
    love.graphics.setColor(1, 1, 1, 1)
    local bowImg = Player.bowImage
    if bowImg then
        local imgW = bowImg:getWidth()
        local imgH = bowImg:getHeight()
        local bowScale = self.bowScale or 1.2
        local bowOffsetDist = math.max(self.size + 5, self.bowOffsetDist or (self.size + 5))

        -- Simple recoil: pull bow slightly toward player for a few frames after shooting
        local recoilT = 0
        if self.bowRecoilDuration and self.bowRecoilDuration > 0 then
            recoilT = (self.bowRecoilTime or 0) / self.bowRecoilDuration
        end
        local recoilDist = 6 * recoilT
        
        -- Position bow in aiming direction
        local bowX = self.x + math.cos(self.bowAngle) * (bowOffsetDist - recoilDist)
        local bowY = drawY + math.sin(self.bowAngle) * (bowOffsetDist - recoilDist)
        
        love.graphics.draw(
            bowImg,
            bowX,
            bowY,
            self.bowAngle + math.pi/4, -- Rotate bow to aim direction (adjust for sprite orientation)
            bowScale, bowScale,
            imgW / 2, imgH / 2 -- Center origin
        )
    end

    -- Bow shot flash (short-lived) to sell arrow release
    if self.bowShotTime and self.bowShotTime > 0 then
        local t = self.bowShotTime / (self.bowShotDuration or 0.06)
        local flashSize = 6 + (1 - t) * 6
        local fx, fy = self:getBowTip()
        love.graphics.setColor(1, 0.85, 0.4, 0.7 * t)
        love.graphics.circle("fill", fx, fy, flashSize)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    --[[ Health bar moved to UI layer (ability_hud.lua)
    -- Draw health bar above player (stylized)
    -- #region agent log
    local logfile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
    if logfile then
        logfile:write(string.format('{"sessionId":"debug-session","runId":"spawn-debug","hypothesisId":"H5","location":"player.lua:draw","message":"Player health bar","data":{"barY":%d,"worldSpace":true},"timestamp":%d}\n', drawY - self.size - 18, os.time() * 1000))
        logfile:close()
    end
    -- #endregion
    
    local barWidth = 50
    local barHeight = 8
    local barX = self.x - barWidth / 2
    local barY = drawY - self.size - 18
    local healthPercent = self.health / self.maxHealth
    
    -- Low health pulse effect
    local pulse = 1.0
    if healthPercent < 0.25 then
        pulse = 0.8 + math.sin(love.timer.getTime() * 8) * 0.2
    end
    
    -- Dark background with rounded corners
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4, 3, 3)
    
    -- Health fill with gradient color (green -> yellow -> red)
    local r, g, b
    if healthPercent > 0.5 then
        -- Green to yellow
        local t = (healthPercent - 0.5) * 2
        r = 1 - t * 0.5
        g = 0.8
        b = 0.1
    else
        -- Yellow to red
        local t = healthPercent * 2
        r = 1.0
        g = 0.8 * t
        b = 0.1
    end
    love.graphics.setColor(r, g, b, pulse)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight, 2, 2)
    
    -- White border outline
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 2, 2)
    love.graphics.setLineWidth(1)
    ]]
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:triggerBowRecoil()
    self.bowRecoilTime = self.bowRecoilDuration or 0.08
    self.bowShotTime = self.bowShotDuration or 0.06
end

-- Returns a good arrow spawn point (near the bow, in aim direction).
function Player:getBowTip()
    local offset = math.max(self.size + 10, (self.bowOffsetDist or (self.size + 5)) + 10)
    return self.x + math.cos(self.bowAngle) * offset,
           self.y + math.sin(self.bowAngle) * offset
end

function Player:getPosition()
    return self.x, self.y
end

function Player:setPosition(x, y)
    self.x = x
    self.y = y
end

function Player:getSize()
    return self.size
end

function Player:isInvincible()
    return self.invincibleTime > 0
end

function Player:getBowAngle()
    return self.bowAngle
end

function Player:useAbility(abilityId, playerStats)
    local ability = self.abilities[abilityId]
    if ability and ability.unlocked and ability.currentCooldown <= 0 then
        -- Calculate effective cooldown with mods
        local baseCooldown = ability.cooldown
        local effectiveCooldown = baseCooldown
        
        if playerStats then
            -- Apply cooldown_add (additive, reduces cooldown)
            local cdAdd = playerStats:getAbilityModValue(abilityId, "cooldown_add", 0)
            -- Apply cooldown_mul (multiplicative)
            local cdMul = playerStats:getAbilityModValue(abilityId, "cooldown_mul", 1.0)
            effectiveCooldown = (baseCooldown + cdAdd) * cdMul
            -- Ensure minimum cooldown
            effectiveCooldown = math.max(0.5, effectiveCooldown)
        end
        
        ability.currentCooldown = effectiveCooldown
        return true
    end
    return false
end

function Player:isAbilityReady(abilityId)
    local ability = self.abilities[abilityId]
    return ability and ability.unlocked and ability.currentCooldown <= 0
end

function Player:getAbilityCooldown(abilityId, playerStats)
    local ability = self.abilities[abilityId]
    if ability then
        return ability.currentCooldown, ability.cooldown
    end
    return 0, 0
end

function Player:setDashCooldown(cooldown)
    if self.abilities.dash then
        self.abilities.dash.currentCooldown = cooldown
    end
end

function Player:applyRoot(duration)
    -- Root the player (prevent movement for duration)
    self.isRooted = true
    self.rootDuration = duration
    self.rootedAt = love.timer.getTime()
end

function Player:isDead()
    return self.health <= 0
end

-- Trigger attack animation when shooting
function Player:playAttackAnimation(onComplete)
    if self.animator then
        self.animator:attack(onComplete)
    end
end

-- Check if currently playing attack animation
function Player:isAttacking()
    return self.animator and self.animator:isAttackPlaying()
end

return Player
