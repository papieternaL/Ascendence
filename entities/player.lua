-- Player Entity (Archer Class)
local Player = {}
Player.__index = Player

-- Static bow image (loaded once)
Player.bowImage = nil

function Player:new(x, y)
    -- Load bow image if not loaded (Tiny Town tile_0118)
    if not Player.bowImage then
        local paths = {
            "assets/2D assets/Tiny Town/Tiles/tile_0118.png",
            "assets/32x32/fb1100.png",
            "images/32x32/fb1100.png",
        }
        for _, p in ipairs(paths) do
            local success, result = pcall(love.graphics.newImage, p)
            if success and result then
                Player.bowImage = result
                Player.bowImage:setFilter("nearest", "nearest")
                break
            end
        end
    end
    
    local player = {
        x = x or 0,
        y = y or 0,
        speed = 200, -- pixels per second
        size = 20, -- radius of the player circle
        bobOffset = 0, -- current bobbing offset
        bobSpeed = 8, -- bobbing animation speed
        bobAmount = 3, -- how much the player bobs (in pixels)
        isMoving = false,
        bobTime = 0, -- time accumulator for bobbing
        -- Health system
        maxHealth = 100,
        health = 100,
        invincibleTime = 0, -- invincibility frames after taking damage
        invincibleDuration = 0.5, -- seconds of invincibility after hit
        -- Combat stats
        attackDamage = 15,
        attackRange = 350,
        attackSpeed = 0.4,
        heroClass = "archer",
        -- Bow aiming
        bowAngle = 0, -- angle the bow is pointing
        lastMoveX = 1, -- last movement direction x
        lastMoveY = 0, -- last movement direction y

        -- Bow presentation / feel
        bowScale = 1.2,
        bowOffsetDist = 25,
        bowRecoilTime = 0,
        bowRecoilDuration = 0.08,
        -- Abilities with cooldowns
        abilities = {
            multi_shot = {
                name = "Multi Shot",
                key = "Q",
                icon = "➶",
                cooldown = 2.25,
                currentCooldown = 0,
                unlocked = true,
                description = "Fires a cone of 3 arrows at the nearest enemy. Auto-casts when ready.",
                castType = "auto",
            },
            entangle = {
                name = "Arrow Volley",
                key = "E",
                icon = "V",
                cooldown = 7.2,
                currentCooldown = 0,
                unlocked = true,
                description = "Rains arrows on the largest enemy cluster. Auto-casts when ready.",
                castType = "auto",
            },
            frenzy = {
                name = "Frenzy",
                key = "R",
                icon = "🔥",
                cooldown = 13.5,
                currentCooldown = 0,
                unlocked = true,
                description = "Press R to activate. Grants bonus crit chance and move speed. Charges from combat and kills.",
                castType = "manual",
            },
            dash = {
                name = "Dash",
                key = "SPACE",
                icon = "💨",
                cooldown = 0.9,
                currentCooldown = 0,
                unlocked = true,
                description = "Press SPACE to dash in your movement direction. Grants invincibility frames.",
                castType = "manual",
            },
        },
        -- Ability order for display
        abilityOrder = { "multi_shot", "dash", "entangle", "frenzy" },
        
        animator = nil, -- Disabled: archer strip sprite; kept for future re-enable
        isDashing = false,
        isRooted = false,
        rootDuration = 0,
    }
    setmetatable(player, Player)
    return player
end

function Player:update(dt)
    -- Update invincibility
    if self.invincibleTime > 0 then
        self.invincibleTime = self.invincibleTime - dt
    end

    -- Bow recoil decay
    if self.bowRecoilTime and self.bowRecoilTime > 0 then
        self.bowRecoilTime = math.max(0, self.bowRecoilTime - dt)
    end
    
    -- Update root duration
    if self.rootDuration and self.rootDuration > 0 then
        self.rootDuration = math.max(0, self.rootDuration - dt)
        if self.rootDuration <= 0 then
            self.isRooted = false
        end
    end

    -- Update ability cooldowns
    for _, ability in pairs(self.abilities) do
        if ability.currentCooldown > 0 then
            ability.currentCooldown = ability.currentCooldown - dt
            if ability.currentCooldown < 0 then
                ability.currentCooldown = 0
            end
        end
    end
    
    -- Skip movement when rooted (e.g. boss phase 2 typing test)
    if self.isRooted or (self.rootDuration and self.rootDuration > 0) then
        self.isMoving = false
        self.bobTime = 0
        self.bobOffset = 0
        return
    end

    -- Get input
    local dx, dy = 0, 0
    
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
    
    -- When dashing, scene handles movement (no animator update)
    if self.isDashing then
        return
    end
    
    -- Update bobbing animation when moving
    if self.isMoving then
        self.bobTime = self.bobTime + dt * self.bobSpeed
        self.bobOffset = math.sin(self.bobTime) * self.bobAmount
    else
        -- Reset bobbing when not moving
        self.bobTime = 0
        self.bobOffset = 0
    end
    
    -- Keep player within world bounds
    local Config = require("data.config")
    local worldW = Config.World and Config.World.width or love.graphics.getWidth()
    local worldH = Config.World and Config.World.height or love.graphics.getHeight()
    self.x = math.max(self.size, math.min(worldW - self.size, self.x))
    self.y = math.max(self.size, math.min(worldH - self.size, self.y))
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
        
        if self.health <= 0 then
            self.health = 0
            return true -- Player died
        end
    end
    return false
end

function Player:isDead()
    return self.health <= 0
end

function Player:draw()
    -- Draw player as a simple circle with bobbing effect
    local drawY = self.y + self.bobOffset
    
    -- Frenzy aura glow (soft outer ring)
    if self.isFrenzyActive then
        local pulse = 0.5 + 0.35 * math.sin(love.timer.getTime() * 6)
        love.graphics.setColor(1, 0.5, 0.15, pulse * 0.4)
        love.graphics.circle("fill", self.x, drawY, self.size + 14)
        love.graphics.setColor(1, 0.55, 0.2, pulse * 0.25)
        love.graphics.circle("fill", self.x, drawY, self.size + 8)
    end
    
    -- Procedural player body (archer sprite disabled)
    if self.invincibleTime > 0 then
        if math.floor(self.invincibleTime * 10) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
        else
            love.graphics.setColor(0.2, 0.6, 1, 1)
        end
    else
        love.graphics.setColor(0.2, 0.6, 1, 1)
    end
    love.graphics.circle("fill", self.x, drawY, self.size)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", self.x - 5, drawY - 5, 4)
    love.graphics.circle("fill", self.x + 5, drawY - 5, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", self.x - 5, drawY - 5, 2)
    love.graphics.circle("fill", self.x + 5, drawY - 5, 2)
    
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw bow
    love.graphics.setColor(1, 1, 1, 1)
    local bowImg = Player.bowImage
    if bowImg then
        local imgW = bowImg:getWidth()
        local imgH = bowImg:getHeight()
        -- Tiny pack sprites are 16x16; scale up for visibility (old were 32x32)
        local bowScale = (imgW <= 18) and 2.0 or (self.bowScale or 1.2)
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

        -- Bow attunement VFX (Fire/Ice/Lightning)
        local elem = self.activeElement
        if elem then
            local t = love.timer.getTime()
            if elem == "fire" then
                local flicker = 0.5 + 0.35 * math.sin(t * 14)
                love.graphics.setColor(1.0, 0.45, 0.1, flicker * 0.45)
                love.graphics.circle("fill", bowX, bowY, 18)
                love.graphics.setColor(1.0, 0.7, 0.2, flicker * 0.6)
                love.graphics.circle("fill", bowX, bowY, 10)
                love.graphics.setColor(1.0, 0.9, 0.4, flicker * 0.5)
                love.graphics.circle("fill", bowX + math.cos(self.bowAngle) * 12, bowY + math.sin(self.bowAngle) * 12, 4)
            elseif elem == "ice" then
                local shimmer = 0.5 + 0.3 * math.sin(t * 10)
                love.graphics.setColor(0.5, 0.85, 1.0, shimmer * 0.45)
                love.graphics.circle("fill", bowX, bowY, 18)
                love.graphics.setColor(0.7, 0.95, 1.0, shimmer * 0.6)
                love.graphics.circle("fill", bowX, bowY, 10)
                for k = 0, 2 do
                    local a = t * 4 + k * (math.pi * 2 / 3)
                    local r = 14
                    love.graphics.setColor(0.85, 0.95, 1.0, shimmer * 0.7)
                    love.graphics.rectangle("fill", bowX + math.cos(a) * r - 1.5, bowY + math.sin(a) * r - 1.5, 3, 3)
                end
            elseif elem == "lightning" then
                local pulse = 0.5 + 0.35 * math.sin(t * 18)
                love.graphics.setColor(0.4, 0.7, 1.0, pulse * 0.45)
                love.graphics.circle("fill", bowX, bowY, 18)
                love.graphics.setColor(0.7, 0.9, 1.0, pulse * 0.6)
                love.graphics.circle("fill", bowX, bowY, 10)
                for k = 0, 1 do
                    local sparkA = t * 12 + k * math.pi + self.bowAngle
                    local sr = 12 + 3 * math.sin(t * 15 + k)
                    love.graphics.setColor(0.8, 0.95, 1.0, pulse * 0.85)
                    love.graphics.circle("fill", bowX + math.cos(sparkA) * sr, bowY + math.sin(sparkA) * sr, 3)
                end
            end
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    -- Draw health bar above player
    local barWidth = 40
    local barHeight = 6
    local barX = self.x - barWidth / 2
    local barY = drawY - self.size - 15
    
    -- Background (red)
    love.graphics.setColor(0.3, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Health (green)
    local healthPercent = self.health / self.maxHealth
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    
    -- Border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
end

function Player:triggerBowRecoil()
    self.bowRecoilTime = self.bowRecoilDuration or 0.08
end

-- Returns a good arrow spawn point (near the bow, in aim direction).
function Player:getBowTip()
    local offset = math.max(self.size + 8, (self.bowOffsetDist or (self.size + 5)) + 6)
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

function Player:useAbility(abilityId)
    local ability = self.abilities[abilityId]
    if ability and ability.unlocked and ability.currentCooldown <= 0 then
        ability.currentCooldown = ability.cooldown
        return true
    end
    return false
end

function Player:isAbilityReady(abilityId)
    local ability = self.abilities[abilityId]
    return ability and ability.unlocked and ability.currentCooldown <= 0
end

function Player:getAbilityCooldown(abilityId)
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

function Player:playAttackAnimation()
    if self.animator then
        self.animator:attack()
    end
end

function Player:applyRoot(duration)
    self.isRooted = true
    self.rootDuration = duration or 0
end

return Player
