-- Player Entity (Archer Class)
local Player = {}
Player.__index = Player

-- Static bow image (loaded once)
Player.bowImage = nil

function Player:new(x, y)
    -- Load bow image if not loaded
    if not Player.bowImage then
        local success, result = pcall(love.graphics.newImage, "assets/32x32/fb1100.png")
        if success then
            Player.bowImage = result
            Player.bowImage:setFilter("nearest", "nearest")
        else
            -- Try fallback path
            success, result = pcall(love.graphics.newImage, "images/32x32/fb1100.png")
            if success then
                Player.bowImage = result
                Player.bowImage:setFilter("nearest", "nearest")
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
        -- Root status (boss mechanic)
        isRooted = false,
        rootDuration = 0,
        rootedAt = 0,
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
            power_shot = {
                name = "Power Shot",
                key = "Q",
                icon = "⚡",
                cooldown = 6.0,
                currentCooldown = 0,
                unlocked = true,
            },
            entangle = {
                name = "Entangle",
                key = "E",
                icon = "🌿",
                cooldown = 8.0,
                currentCooldown = 0,
                unlocked = true,
            },
            frenzy = {
                name = "Frenzy",
                key = "R",
                icon = "🔥",
                cooldown = 15.0,
                currentCooldown = 0,
                unlocked = true,
            },
            dash = {
                name = "Dash",
                key = "SPACE",
                icon = "💨",
                cooldown = 1.0,
                currentCooldown = 0,
                unlocked = true,
            },
        },
        -- Ability order for display
        abilityOrder = { "power_shot", "dash", "entangle", "frenzy" },
    }
    setmetatable(player, Player)
    return player
end

function Player:update(dt)
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
    
    -- Keep player within screen bounds
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.x = math.max(self.size, math.min(screenWidth - self.size, self.x))
    self.y = math.max(self.size, math.min(screenHeight - self.size, self.y))
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

function Player:draw()
    -- Draw player as a simple circle with bobbing effect
    local drawY = self.y + self.bobOffset
    
    -- Flash when invincible
    if self.invincibleTime > 0 then
        -- Blink effect
        if math.floor(self.invincibleTime * 10) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
        else
            love.graphics.setColor(0.2, 0.6, 1, 1) -- Blue player color
        end
    else
        love.graphics.setColor(0.2, 0.6, 1, 1) -- Blue player color
    end
    
    love.graphics.circle("fill", self.x, drawY, self.size)
    
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
    
    -- Draw eyes
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", self.x - 5, drawY - 5, 4)
    love.graphics.circle("fill", self.x + 5, drawY - 5, 4)
    
    -- Draw pupils
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", self.x - 5, drawY - 5, 2)
    love.graphics.circle("fill", self.x + 5, drawY - 5, 2)
    
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

function Player:applyRoot(duration)
    -- Root the player (prevent movement for duration)
    self.isRooted = true
    self.rootDuration = duration
    self.rootedAt = love.timer.getTime()
end

function Player:isDead()
    return self.health <= 0
end

return Player
