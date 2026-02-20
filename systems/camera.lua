-- Simple Camera System for following the player
local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, worldWidth, worldHeight)
    local camera = {
        x = x or 0,
        y = y or 0,
        worldWidth = worldWidth or 1280,
        worldHeight = worldHeight or 720,
        smoothing = 0.15,  -- Lower = smoother/slower follow (0.15 = responsive without snapping)
    }
    setmetatable(camera, Camera)
    return camera
end

function Camera:update(dt, targetX, targetY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local desiredX = targetX - screenWidth / 2
    local desiredY = targetY - screenHeight / 2
    
    -- Bottom-edge look-ahead: shift camera down when player nears lower map boundary
    local cfg = require("data.config").World
    local camCfg = cfg and cfg.camera
    if camCfg and self.worldHeight and screenHeight then
        local startFrac = camCfg.bottomThresholdStart or 0.65
        local endFrac = camCfg.bottomThresholdEnd or 0.88
        local maxOffsetFrac = camCfg.maxDownwardOffset or 0.25
        local thresholdStart = self.worldHeight * startFrac
        local thresholdEnd = self.worldHeight * endFrac
        local maxOffset = screenHeight * maxOffsetFrac
        if targetY > thresholdStart then
            local progress = math.min(1.0, (targetY - thresholdStart) / (thresholdEnd - thresholdStart))
            desiredY = desiredY + maxOffset * progress
        end
    end
    
    self.x = self.x + (desiredX - self.x) * self.smoothing
    self.y = self.y + (desiredY - self.y) * self.smoothing
    
    local maxOffset = 0
    if camCfg and screenHeight and camCfg.maxDownwardOffset then
        maxOffset = screenHeight * camCfg.maxDownwardOffset
    end
    self.x = math.max(0, math.min(self.x, self.worldWidth - screenWidth))
    self.y = math.max(0, math.min(self.y, self.worldHeight - screenHeight + maxOffset))
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:getPosition()
    return self.x, self.y
end

function Camera:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Convert screen coordinates to world coordinates
function Camera:toWorld(screenX, screenY)
    return screenX + self.x, screenY + self.y
end

-- Convert world coordinates to screen coordinates
function Camera:toScreen(worldX, worldY)
    return worldX - self.x, worldY - self.y
end

return Camera
