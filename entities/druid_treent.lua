-- Druid Treent Healer Entity
-- Tree-themed support unit that heals wounded allies
-- Forces player to prioritize as high-value target

local StatusComponent = require("systems.status_component")

local DruidTreent = {}
DruidTreent.__index = DruidTreent

function DruidTreent:new(x, y)
    local druid = {
        x = x,
        y = y,
        size = 20,
        speed = 50,
        maxHealth = 55,
        health = 55,
        damage = 8,
        isMCM = true,

        -- Healing properties
        healRange = 180,
        healAmount = 8,  -- HP per second
        healCooldown = 0.4,  -- Tick rate
        healTimer = 0,
        currentTarget = nil,
        isHealing = false,

        -- Movement AI
        minDistance = 100,   -- Stay at least this far from player
        maxDistance = 280,   -- Try to stay within this range

        -- Visual
        glowPhase = 0,
        flashTime = 0,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,
        healBeamPulse = 0,

        -- Particle effects
        particles = {},
        particleSpawnTimer = 0,

        -- Status
        isAlive = true,
        statusComponent = StatusComponent:new(),
    }

    setmetatable(druid, DruidTreent)
    return druid
end

function DruidTreent:update(dt, playerX, playerY, allEnemies)
    if not self.isAlive then return end

    -- Update visual timers
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    self.glowPhase = self.glowPhase + dt * 2
    self.healBeamPulse = self.healBeamPulse + dt * 5

    -- Apply knockback decay
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)

    -- Update status effects
    if self.statusComponent then
        self.statusComponent:update(dt)
    end

    -- Check if rooted
    local isRooted = self.statusComponent and self.statusComponent:hasStatus("rooted")

    -- Find wounded ally to heal
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
    self.isHealing = (targetToHeal ~= nil)

    -- Perform healing tick
    if self.isHealing and self.healTimer <= 0 then
        self.healTimer = self.healCooldown
        local healAmount = self.healAmount * self.healCooldown
        self.currentTarget.health = math.min(
            self.currentTarget.maxHealth,
            self.currentTarget.health + healAmount
        )
    end

    if self.healTimer > 0 then
        self.healTimer = self.healTimer - dt
    end

    -- Movement AI (stop when healing)
    if not self.isHealing and not isRooted then
        local dx = playerX - self.x
        local dy = playerY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 0 then
            local dirX = dx / dist
            local dirY = dy / dist

            -- Maintain distance from player
            if dist < self.minDistance then
                -- Back away
                self.x = self.x - dirX * self.speed * dt + self.knockbackX * dt
                self.y = self.y - dirY * self.speed * dt + self.knockbackY * dt
            elseif dist > self.maxDistance then
                -- Approach
                self.x = self.x + dirX * self.speed * dt + self.knockbackX * dt
                self.y = self.y + dirY * self.speed * dt + self.knockbackY * dt
            else
                -- Circle strafe
                local perpX = -dirY
                local perpY = dirX
                self.x = self.x + perpX * self.speed * 0.5 * dt + self.knockbackX * dt
                self.y = self.y + perpY * self.speed * 0.5 * dt + self.knockbackY * dt
            end
        end
    else
        -- Apply knockback even when healing
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
    end

    -- Update healing particles
    if self.isHealing then
        self.particleSpawnTimer = self.particleSpawnTimer + dt
        if self.particleSpawnTimer >= 0.08 then
            self.particleSpawnTimer = 0
            self:spawnHealParticle()
        end
    end

    -- Update particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        p.progress = p.progress + dt * 1.5

        if p.progress > 1.0 then
            p.progress = 1.0
        end

        -- Move particle along beam from druid to target
        if self.currentTarget then
            p.x = self.x + (self.currentTarget.x - self.x) * p.progress
            p.y = self.y + (self.currentTarget.y - self.y) * p.progress
        end

        p.alpha = (p.life / p.maxLife) * 0.8

        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function DruidTreent:spawnHealParticle()
    if not self.currentTarget then return end

    table.insert(self.particles, {
        x = self.x,
        y = self.y,
        size = math.random(2, 4),
        life = 0.6,
        maxLife = 0.6,
        alpha = 1.0,
        progress = 0,  -- 0 = at druid, 1 = at target
    })
end

function DruidTreent:draw()
    if not self.isAlive then return end

    -- Draw healing beam
    if self.isHealing and self.currentTarget then
        -- Beam line
        love.graphics.setColor(0.3, 1, 0.5, 0.4)
        love.graphics.setLineWidth(3)
        love.graphics.line(
            self.x, self.y,
            self.currentTarget.x, self.currentTarget.y
        )
        love.graphics.setLineWidth(1)

        -- Endpoint glows
        local pulseAlpha = 0.5 + math.sin(self.healBeamPulse) * 0.5
        love.graphics.setColor(0.5, 1, 0.7, pulseAlpha * 0.6)
        love.graphics.circle("fill", self.x, self.y, 8)
        love.graphics.circle("fill", self.currentTarget.x, self.currentTarget.y, 6)
    end

    -- Draw healing particles
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(0.4, 1, 0.6, p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- Pulsing green aura when ready to heal
    if not self.isHealing then
        local pulse = 0.5 + math.sin(self.glowPhase) * 0.3
        love.graphics.setColor(0.3, 1, 0.5, pulse * 0.3)
        love.graphics.circle("fill", self.x, self.y, self.size + 12)
    end

    -- Main body color
    local r, g, b, a = 0.35, 0.55, 0.3, 1  -- Green/tree color

    if self.isHealing then
        -- Brighter green when healing
        r, g, b = 0.45, 0.75, 0.4
    end

    -- Flash white on hit
    if self.flashTime > 0 then
        r, g, b = 1, 1, 1
    end

    -- Draw druid body (shadow)
    love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5, a * 0.7)
    love.graphics.circle("fill", self.x + 2, self.y + 2, self.size)

    -- Main druid body
    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", self.x, self.y, self.size)

    -- Tree bark texture (darker lines)
    love.graphics.setColor(0.2, 0.3, 0.15, 0.8)
    love.graphics.setLineWidth(2)
    for i = 1, 4 do
        local angle = (i / 4) * math.pi * 2 + self.glowPhase * 0.1
        local x1 = self.x + math.cos(angle) * self.size * 0.4
        local y1 = self.y + math.sin(angle) * self.size * 0.4
        local x2 = self.x + math.cos(angle) * self.size * 0.9
        local y2 = self.y + math.sin(angle) * self.size * 0.9
        love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

    -- Leaves/foliage (small green circles)
    love.graphics.setColor(0.4, 0.9, 0.3, 0.9)
    for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2 + self.glowPhase * 0.2
        local dist = self.size * 0.7
        local x = self.x + math.cos(angle) * dist
        local y = self.y + math.sin(angle) * dist
        love.graphics.circle("fill", x, y, 3)
    end

    -- Highlight
    love.graphics.setColor(1, 1, 1, 0.3 * a)
    love.graphics.circle("fill", self.x - 4, self.y - 5, 5)

    -- Border
    love.graphics.setColor(r * 0.7, g * 0.7, b * 0.7, a)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.size)
    love.graphics.setLineWidth(1)

    -- MCM glow indicator (green pulsing ring)
    if self.isMCM then
        local pulse = 0.5 + math.sin(self.glowPhase * 1.5) * 0.5
        love.graphics.setColor(0.3, 1, 0.5, pulse * 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.x, self.y, self.size + 6 + pulse * 4)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DruidTreent:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end

    self.health = self.health - damage
    self.flashTime = 0.1

    -- Knockback calculation (away from hit source)
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local k = (knockbackForce or 140) * 1.0
            self.knockbackX = (dx / distance) * k
            self.knockbackY = (dy / distance) * k
        end
    end

    if self.health <= 0 then
        self.isAlive = false
        return true  -- Return true if died
    end

    return false  -- Return false if still alive
end

function DruidTreent:getSize()
    return self.size
end

function DruidTreent:getPosition()
    return self.x, self.y
end

return DruidTreent
