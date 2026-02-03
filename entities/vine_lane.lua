-- Vine Lane Entity
-- Phase 2 boss mechanic: horizontal wavy vines that snake across the arena
-- Player must stand in the safe lane to avoid lethal damage

local VineLane = {}
VineLane.__index = VineLane

function VineLane:new(y, laneIndex, speed, damage)
    local screenWidth = love.graphics.getWidth()
    
    local vine = {
        y = y,                           -- Base Y position of the lane
        laneIndex = laneIndex,           -- Which lane (1-5)
        speed = speed or 300,            -- Pixels per second (right to left)
        damage = damage or 50,           -- Damage per tick
        
        -- Animation state
        headX = screenWidth + 100,       -- Leading edge of the vine (starts off-screen right)
        tailX = screenWidth + 500,       -- Trailing edge (vine has length)
        waveTime = 0,                    -- Time accumulator for wave animation
        waveFrequency = 0.015,           -- How tight the waves are (lower = wider waves)
        waveAmplitude = 25,              -- How tall the waves are (pixels)
        waveSpeed = 4,                   -- How fast the wave moves
        
        -- Visual properties
        thickness = 16,                  -- Base thickness of the vine (thicker for root look)
        color = {0.35, 0.25, 0.15},      -- Brown/bark color for roots
        segments = 60,                   -- Number of line segments to draw
        
        -- State
        isActive = true,
        hasPassedScreen = false,         -- True when vine has fully crossed
        
        -- Hitbox
        hitboxHeight = 50,               -- Vertical area where player takes damage
    }
    
    setmetatable(vine, VineLane)
    return vine
end

function VineLane:update(dt)
    if not self.isActive then return end
    
    -- Move the vine left
    self.headX = self.headX - self.speed * dt
    self.tailX = self.tailX - self.speed * dt
    
    -- Update wave animation
    self.waveTime = self.waveTime + dt * self.waveSpeed
    
    -- Check if vine has fully passed the screen
    if self.tailX < -100 then
        self.isActive = false
        self.hasPassedScreen = true
    end
end

-- Check if player at (px, py) is being hit by this vine
function VineLane:isPlayerInDanger(px, py)
    if not self.isActive then return false end
    
    local screenWidth = love.graphics.getWidth()
    
    -- Check if player X is within the vine's current span
    local inXRange = px >= math.max(0, self.headX) and px <= math.min(screenWidth, self.tailX)
    if not inXRange then return false end
    
    -- Calculate the wave Y at player's X position
    local waveY = self:getWaveY(px)
    
    -- Check if player Y is within the hitbox of the wave at this X
    local halfHitbox = self.hitboxHeight / 2
    return py >= waveY - halfHitbox and py <= waveY + halfHitbox
end

-- Get the Y position of the wave at a given X
function VineLane:getWaveY(x)
    -- Sine wave that moves over time
    local waveOffset = math.sin(x * self.waveFrequency + self.waveTime) * self.waveAmplitude
    return self.y + waveOffset
end

function VineLane:draw()
    if not self.isActive then return end
    
    local screenWidth = love.graphics.getWidth()
    
    -- Calculate visible range
    local startX = math.max(0, self.headX)
    local endX = math.min(screenWidth, self.tailX)
    
    if startX >= endX then return end
    
    -- Draw the wavy vine as connected line segments
    local points = {}
    local step = (endX - startX) / self.segments
    
    for i = 0, self.segments do
        local x = startX + i * step
        local y = self:getWaveY(x)
        table.insert(points, x)
        table.insert(points, y)
    end
    
    if #points < 4 then return end

    -- Draw thick root shadow/depth (very dark brown)
    love.graphics.setColor(0.15, 0.10, 0.05, 0.95)
    love.graphics.setLineWidth(self.thickness + 6)
    love.graphics.line(points)

    -- Draw main root (brown/bark color)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.setLineWidth(self.thickness)
    love.graphics.line(points)

    -- Draw highlight (lighter bark texture)
    love.graphics.setColor(0.5, 0.38, 0.25, 0.7)
    love.graphics.setLineWidth(self.thickness / 2.5)
    love.graphics.line(points)

    -- Draw root nodes/knots at intervals (darker spots along root)
    love.graphics.setColor(0.2, 0.15, 0.1, 1)
    for i = 1, #points - 2, 12 do
        local px, py = points[i], points[i + 1]
        -- Oval-shaped knots on the root
        love.graphics.ellipse("fill", px, py, 6, 4)
        -- Small root tendrils
        local angleOffset = (i % 2 == 0) and -0.6 or 0.6
        local tendrilLength = 8
        love.graphics.line(px, py, px + math.cos(angleOffset) * tendrilLength, py + math.sin(angleOffset) * tendrilLength)
    end

    -- Draw leading edge (root tip - pointed and gnarled)
    local headY = self:getWaveY(self.headX)
    local pulse = 1 + math.sin(self.waveTime * 6) * 0.15

    -- Root tip shadow
    love.graphics.setColor(0.2, 0.15, 0.1, 0.9)
    love.graphics.circle("fill", self.headX, headY, (self.thickness + 2) * pulse)

    -- Root tip main
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.circle("fill", self.headX, headY, self.thickness * pulse)

    -- Root tip highlight
    love.graphics.setColor(0.55, 0.42, 0.28, 0.8)
    love.graphics.circle("fill", self.headX - 2, headY - 2, (self.thickness * 0.4) * pulse)
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function VineLane:getPosition()
    return self.headX, self.y
end

function VineLane:isFinished()
    return not self.isActive
end

return VineLane

