-- Wolf Lunger Entity
-- Aggressive ground-based charger with telegraphed lunge attack
-- State machine: idle -> charging -> lunging -> cooldown

local BaseEnemy = require("entities.base_enemy")
local EnemyData = require("data.enemies")
local StatusEffects = require("systems.status_effects")

local Wolf = setmetatable({}, {__index = BaseEnemy})
Wolf.__index = Wolf
Wolf.TYPE_ID = "wolf"
Wolf.image = nil

function Wolf:new(x, y)
    -- Load sprite once (Tiny Ski wolf idle frames)
    if not Wolf.image then
        local paths = {
            "assets/2D assets/Tiny Ski/Tiles/tile_0078.png",
            "assets/2D assets/Tiny Ski/Tiles/tile_0079.png",
        }
        for _, p in ipairs(paths) do
            local success, result = pcall(love.graphics.newImage, p)
            if success and result then
                Wolf.image = result
                Wolf.image:setFilter("nearest", "nearest")
                break
            end
        end
    end

    local config = EnemyData.wolf
    local wolf = BaseEnemy.new(self, x, y, {
        size = config.size,
        speed = config.speed,
        health = config.health,
        damage = config.damage,
        knockbackDecay = config.knockbackDecay,
        flashDuration = config.flashDuration,
        isElite = config.isElite,
        isMCM = config.isMCM,
        enemyType = "wolf",
    })
    
    -- Wolf-specific properties
    wolf.state = "idle"  -- idle, charging, lunging, cooldown
    wolf.chargeTime = 0
    wolf.chargeDuration = config.chargeDuration
    wolf.lungeTime = 0
    wolf.lungeDuration = config.lungeDuration
    wolf.cooldownTime = 0
    wolf.cooldownDuration = config.cooldownDuration
    wolf.lungeRange = config.lungeRange
    wolf.lungeVx = 0
    wolf.lungeVy = 0
    wolf.lungeSpeed = config.lungeSpeed
    wolf.glowPhase = 0
    
    setmetatable(wolf, Wolf)
    return wolf
end

function Wolf:update(dt, playerX, playerY)
    -- Update common systems (status, flash, knockback)
    self:updateCommon(dt)
    
    if not self.isAlive then return end
    
    -- Update visual timer
    self.glowPhase = self.glowPhase + dt * 3

    -- Check if rooted or frozen
    local isRooted = self:isRooted()
    if self:isFrozen() then
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        return
    end

    local effectiveSpeed = self:getEffectiveSpeed()

    -- State machine logic
    if self.state == "idle" then
        -- Pursue player
        if not isRooted then
            local dx = playerX - self.x
            local dy = playerY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 0 then
                local dirX = dx / dist
                local dirY = dy / dist
                self.x = self.x + dirX * effectiveSpeed * dt + self.knockbackX * dt
                self.y = self.y + dirY * effectiveSpeed * dt + self.knockbackY * dt
            end

            -- Check if in range to start charging
            if dist <= self.lungeRange then
                self.state = "charging"
                self.chargeTime = 0
                -- Lock direction toward player
                self.lungeVx = dx / dist
                self.lungeVy = dy / dist
            end
        end

    elseif self.state == "charging" then
        -- Wind-up phase with visual telegraph
        self.chargeTime = self.chargeTime + dt

        if self.chargeTime >= self.chargeDuration then
            -- Start lunging
            self.state = "lunging"
            self.lungeTime = 0
        end

    elseif self.state == "lunging" then
        -- Fast dash in locked direction
        self.lungeTime = self.lungeTime + dt

        if not isRooted then
            local lungeSpd = self.lungeSpeed * StatusEffects.getSpeedMul(self)
            self.x = self.x + self.lungeVx * lungeSpd * dt + self.knockbackX * dt
            self.y = self.y + self.lungeVy * lungeSpd * dt + self.knockbackY * dt
        end

        if self.lungeTime >= self.lungeDuration then
            -- Enter cooldown
            self.state = "cooldown"
            self.cooldownTime = 0
        end

    elseif self.state == "cooldown" then
        -- Recovery period
        self.cooldownTime = self.cooldownTime + dt

        -- Resume idle movement during cooldown
        if not isRooted then
            local dx = playerX - self.x
            local dy = playerY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 0 then
                local dirX = dx / dist
                local dirY = dy / dist
                self.x = self.x + dirX * effectiveSpeed * dt + self.knockbackX * dt
                self.y = self.y + dirY * effectiveSpeed * dt + self.knockbackY * dt
            end
        end

        if self.cooldownTime >= self.cooldownDuration then
            -- Return to idle
            self.state = "idle"
        end
    end
end

function Wolf:draw()
    if not self.isAlive then return end

    -- State-based coloring
    local r, g, b, a = 0.7, 0.7, 0.8, 1  -- Default gray/white

    if self.state == "charging" then
        -- Red pulsing glow
        local pulse = 0.5 + math.sin(self.glowPhase * 6) * 0.5
        r, g, b = 1, 0.4 + pulse * 0.3, 0.4 + pulse * 0.3
    elseif self.state == "lunging" then
        -- Bright red
        r, g, b = 1, 0.3, 0.3
    elseif self.state == "cooldown" then
        -- Dim gray
        r, g, b, a = 0.6, 0.6, 0.7, 0.7
    end

    -- Flash white on hit
    if self.flashTime > 0 then
        r, g, b = 1, 1, 1
    end

    -- Draw charge telegraph (growing red line with danger zone)
    if self.state == "charging" then
        local chargeProgress = self.chargeTime / self.chargeDuration
        local lineLength = 50 + (chargeProgress * 80)  -- Grows from 50 to 130 pixels
        local lungeAngle = math.atan2(self.lungeVy, self.lungeVx)

        -- Danger cone area (shows lunge path)
        local coneWidth = 20 + chargeProgress * 10
        love.graphics.setColor(1, 0.2, 0.2, 0.15 + chargeProgress * 0.15)
        love.graphics.polygon("fill",
            self.x, self.y,
            self.x + math.cos(lungeAngle - 0.3) * lineLength, self.y + math.sin(lungeAngle - 0.3) * lineLength,
            self.x + math.cos(lungeAngle + 0.3) * lineLength, self.y + math.sin(lungeAngle + 0.3) * lineLength
        )

        -- Center line (brighter)
        love.graphics.setColor(1, 0.3, 0.3, 0.9)
        love.graphics.setLineWidth(4 + chargeProgress * 3)
        love.graphics.line(
            self.x,
            self.y,
            self.x + math.cos(lungeAngle) * lineLength,
            self.y + math.sin(lungeAngle) * lineLength
        )

        -- Outer glow
        love.graphics.setColor(1, 0.4, 0.4, 0.4)
        love.graphics.setLineWidth(8 + chargeProgress * 4)
        love.graphics.line(
            self.x,
            self.y,
            self.x + math.cos(lungeAngle) * lineLength,
            self.y + math.sin(lungeAngle) * lineLength
        )
        love.graphics.setLineWidth(1)

        -- Glowing impact point at end of line
        love.graphics.setColor(1, 0.3, 0.3, 0.7 + chargeProgress * 0.3)
        love.graphics.circle("fill",
            self.x + math.cos(lungeAngle) * lineLength,
            self.y + math.sin(lungeAngle) * lineLength,
            8 + chargeProgress * 6
        )

        -- Inner bright core
        love.graphics.setColor(1, 0.9, 0.9, 0.9)
        love.graphics.circle("fill",
            self.x + math.cos(lungeAngle) * lineLength,
            self.y + math.sin(lungeAngle) * lineLength,
            3 + chargeProgress * 2
        )
    end

    -- Motion blur during lunge
    if self.state == "lunging" then
        for i = 1, 3 do
            local offset = i * 8
            love.graphics.setColor(1, 0.4, 0.4, 0.3 - i * 0.08)
            love.graphics.circle(
                "fill",
                self.x - self.lungeVx * offset,
                self.y - self.lungeVy * offset,
                self.size * (1 - i * 0.15)
            )
        end
    end

    -- Main wolf body: sprite when available, else procedural circles
    if Wolf.image then
        local imgW = Wolf.image:getWidth()
        local scale = (imgW <= 18) and 1.5 or 1.0
        love.graphics.setColor(r, g, b, a)
        local imgH = Wolf.image:getHeight()
        love.graphics.draw(Wolf.image, self.x, self.y, 0, scale, scale, imgW / 2, imgH / 2)
    else
        -- Procedural fallback
        love.graphics.setColor(r * 0.4, g * 0.4, b * 0.4, a * 0.8)
        love.graphics.circle("fill", self.x + 3, self.y + 3, self.size)
        love.graphics.setColor(r, g, b, a)
        love.graphics.circle("fill", self.x, self.y, self.size)
        love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, a * 0.9)
        love.graphics.circle("fill", self.x - 4, self.y - 2, 4)
        love.graphics.circle("fill", self.x + 4, self.y + 3, 5)
        love.graphics.circle("fill", self.x - 2, self.y + 4, 3)
        love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, a)
        love.graphics.circle("fill", self.x, self.y + 6, 5)
        if self.state == "charging" or self.state == "lunging" then
            love.graphics.setColor(1, 0.1, 0.1, 1)
            love.graphics.circle("fill", self.x - 5, self.y - 4, 3)
            love.graphics.circle("fill", self.x + 5, self.y - 4, 3)
        else
            love.graphics.setColor(0.9, 0.9, 0.2, 1)
            love.graphics.circle("fill", self.x - 5, self.y - 4, 2.5)
            love.graphics.circle("fill", self.x + 5, self.y - 4, 2.5)
        end
        love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, a)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.x, self.y, self.size)
        love.graphics.setLineWidth(1)
    end

    -- Charging aura particles
    if self.state == "charging" then
        local numParticles = math.floor(self.chargeTime / self.chargeDuration * 8)
        for i = 1, numParticles do
            local angle = (i / 8) * math.pi * 2 + self.glowPhase * 3
            local dist = self.size + 8 + math.sin(self.glowPhase * 5 + i) * 4
            local px = self.x + math.cos(angle) * dist
            local py = self.y + math.sin(angle) * dist
            love.graphics.setColor(1, 0.4, 0.4, 0.7)
            love.graphics.circle("fill", px, py, 2)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Wolf:takeDamage(damage, hitX, hitY, knockbackForce)
    -- Call base damage handler
    local died = BaseEnemy.takeDamage(self, damage, hitX, hitY, knockbackForce or 140)
    
    -- Interrupt charge if taking damage
    if self.state == "charging" then
        self.state = "cooldown"
        self.cooldownTime = 0
    end
    
    return died
end

function Wolf:getKnockbackForce()
    if self.state == "lunging" then
        return 180  -- Strong knockback during lunge
    else
        return 140  -- Normal knockback
    end
end

return Wolf
