-- Falling Tree Trunk Entity
-- Phase 2 boss mechanic: Trunks fall from sky with telegraph -> fall -> impact phases
-- Player must dodge the impact zone

local FallingTrunk = {}
FallingTrunk.__index = FallingTrunk

function FallingTrunk:new(targetX, targetY, damage)
    local trunk = {
        x = targetX,
        y = targetY,
        damage = damage or 60,

        -- State machine: "telegraph" -> "falling" -> "impact" -> "finished"
        state = "telegraph",

        -- Telegraph phase (warning indicator on ground)
        telegraphDuration = 1.2,
        telegraphTimer = 0,
        telegraphRadius = 45,

        -- Falling phase (trunk descends from sky)
        fallingDuration = 0.4,
        fallingTimer = 0,
        fallingStartY = -100,  -- Above screen
        fallingEndY = targetY,
        currentY = -100,

        -- Impact phase (damage dealt, particles spawn)
        impactDuration = 0.3,
        impactTimer = 0,
        impactRadius = 50,

        -- Visual
        trunkWidth = 30,
        trunkHeight = 80,
        rotation = math.random() * math.pi * 2,

        isFinished = false,
    }

    setmetatable(trunk, FallingTrunk)
    return trunk
end

function FallingTrunk:update(dt)
    if self.isFinished then return end

    if self.state == "telegraph" then
        self.telegraphTimer = self.telegraphTimer + dt
        if self.telegraphTimer >= self.telegraphDuration then
            -- Transition to falling
            self.state = "falling"
            self.fallingTimer = 0
            self.currentY = self.fallingStartY
        end

    elseif self.state == "falling" then
        self.fallingTimer = self.fallingTimer + dt
        local progress = self.fallingTimer / self.fallingDuration

        -- Ease-in fall (accelerating)
        progress = progress * progress
        self.currentY = self.fallingStartY + (self.fallingEndY - self.fallingStartY) * progress

        if self.fallingTimer >= self.fallingDuration then
            -- Transition to impact
            self.state = "impact"
            self.impactTimer = 0
            self.currentY = self.y
        end

    elseif self.state == "impact" then
        self.impactTimer = self.impactTimer + dt
        if self.impactTimer >= self.impactDuration then
            -- Finished
            self.state = "finished"
            self.isFinished = true
        end
    end
end

function FallingTrunk:draw()
    if self.isFinished then return end

    if self.state == "telegraph" then
        -- Draw ground target indicator (red circle with pulsing)
        local pulse = math.sin(self.telegraphTimer * 10) * 0.3 + 0.7
        local alpha = math.min(1.0, self.telegraphTimer / 0.3)  -- Fade in

        -- Danger zone (red glow)
        love.graphics.setColor(1, 0.2, 0.2, 0.2 * alpha * pulse)
        love.graphics.circle("fill", self.x, self.y, self.telegraphRadius * 1.5)

        -- Inner circle (brighter)
        love.graphics.setColor(1, 0.3, 0.3, 0.5 * alpha * pulse)
        love.graphics.circle("fill", self.x, self.y, self.telegraphRadius)

        -- Border ring
        love.graphics.setColor(1, 0.5, 0.2, 0.9 * alpha * pulse)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", self.x, self.y, self.telegraphRadius)

        -- Crosshair
        love.graphics.setColor(1, 1, 0.3, 0.8 * alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(self.x - 10, self.y, self.x + 10, self.y)
        love.graphics.line(self.x, self.y - 10, self.x, self.y + 10)

        love.graphics.setLineWidth(1)

    elseif self.state == "falling" then
        -- Draw falling trunk (brown log descending)
        love.graphics.push()
        love.graphics.translate(self.x, self.currentY)
        love.graphics.rotate(self.rotation)

        -- Trunk shadow (gets larger as it gets closer)
        local scale = 1 - (self.currentY - self.y) / (self.fallingStartY - self.y)
        scale = math.max(0.3, scale)

        love.graphics.setColor(0, 0, 0, 0.4 * scale)
        love.graphics.rectangle("fill", -self.trunkWidth/2, -self.trunkHeight/2, self.trunkWidth, self.trunkHeight, 4, 4)

        -- Trunk body (dark brown)
        love.graphics.setColor(0.3, 0.2, 0.1, 1)
        love.graphics.rectangle("fill", -self.trunkWidth/2 - 2, -self.trunkHeight/2 - 2, self.trunkWidth, self.trunkHeight, 3, 3)

        -- Trunk main (brown)
        love.graphics.setColor(0.45, 0.3, 0.2, 1)
        love.graphics.rectangle("fill", -self.trunkWidth/2, -self.trunkHeight/2, self.trunkWidth, self.trunkHeight, 3, 3)

        -- Bark texture (lines)
        love.graphics.setColor(0.3, 0.2, 0.15, 0.7)
        love.graphics.setLineWidth(2)
        for i = -3, 3 do
            local yOffset = i * 12
            love.graphics.line(-self.trunkWidth/2, yOffset, self.trunkWidth/2, yOffset)
        end

        -- Highlight
        love.graphics.setColor(0.6, 0.4, 0.25, 0.5)
        love.graphics.rectangle("fill", -self.trunkWidth/2 + 3, -self.trunkHeight/2 + 3, self.trunkWidth / 3, self.trunkHeight - 6, 2, 2)

        love.graphics.pop()
        love.graphics.setLineWidth(1)

        -- Ground target still visible (faded)
        love.graphics.setColor(1, 0.3, 0.3, 0.2)
        love.graphics.circle("fill", self.x, self.y, self.telegraphRadius)

    elseif self.state == "impact" then
        -- Draw impact effect (expanding ring and particles)
        local impactProgress = self.impactTimer / self.impactDuration
        local ringRadius = self.impactRadius * (1 + impactProgress * 2)
        local alpha = 1 - impactProgress

        -- Impact shockwave (expanding circle)
        love.graphics.setColor(1, 0.6, 0.2, alpha * 0.6)
        love.graphics.circle("fill", self.x, self.y, ringRadius)

        -- Impact ring
        love.graphics.setColor(1, 0.8, 0.3, alpha * 0.9)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", self.x, self.y, ringRadius)

        -- Draw embedded trunk on ground
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.rotation)

        -- Trunk (partially embedded)
        love.graphics.setColor(0.35, 0.25, 0.15, 0.9)
        love.graphics.rectangle("fill", -self.trunkWidth/2, -self.trunkHeight/4, self.trunkWidth, self.trunkHeight/2, 3, 3)

        love.graphics.pop()
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Check if player position is in danger zone during impact
function FallingTrunk:isPlayerInDanger(px, py)
    if self.state ~= "impact" then return false end

    local dx = px - self.x
    local dy = py - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    return dist <= self.impactRadius
end

-- Get impact damage
function FallingTrunk:getDamage()
    return self.damage
end

function FallingTrunk:isInImpactPhase()
    return self.state == "impact" and self.impactTimer < 0.1  -- Only damage in first 0.1s of impact
end

return FallingTrunk
