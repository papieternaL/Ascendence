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
        zoom = 1.0,
        followBiasY = 0,
    }
    setmetatable(camera, Camera)
    return camera
end

function Camera:getViewportSize()
    local zoom = math.max(0.01, self.zoom or 1.0)
    return love.graphics.getWidth() / zoom, love.graphics.getHeight() / zoom
end

function Camera:update(dt, targetX, targetY)
    local viewportWidth, viewportHeight = self:getViewportSize()
    
    local desiredX = targetX - viewportWidth / 2
    local desiredY = targetY - viewportHeight / 2 + (self.followBiasY or 0)
    
    -- Bottom-edge look-ahead: shift camera down when player nears lower map boundary
    local cfg = require("data.config").World
    local camCfg = cfg and cfg.camera
    if camCfg and self.worldHeight and viewportHeight then
        local startFrac = camCfg.bottomThresholdStart or 0.65
        local endFrac = camCfg.bottomThresholdEnd or 0.88
        local maxOffsetFrac = camCfg.maxDownwardOffset or 0.25
        local thresholdStart = self.worldHeight * startFrac
        local thresholdEnd = self.worldHeight * endFrac
        local maxOffset = viewportHeight * maxOffsetFrac
        if targetY > thresholdStart then
            local progress = math.min(1.0, (targetY - thresholdStart) / (thresholdEnd - thresholdStart))
            desiredY = desiredY + maxOffset * progress
        end
    end
    
    self.x = self.x + (desiredX - self.x) * self.smoothing
    self.y = self.y + (desiredY - self.y) * self.smoothing
    
    local maxX = math.max(0, (self.worldWidth or viewportWidth) - viewportWidth)
    local maxY = math.max(0, (self.worldHeight or viewportHeight) - viewportHeight)
    self.x = math.max(0, math.min(self.x, maxX))
    self.y = math.max(0, math.min(self.y, maxY))
end

function Camera:attach()
    love.graphics.push()
    local zoom = self.zoom or 1.0
    love.graphics.scale(zoom, zoom)
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
    local zoom = math.max(0.01, self.zoom or 1.0)
    return screenX / zoom + self.x, screenY / zoom + self.y
end

-- Convert world coordinates to screen coordinates
function Camera:toScreen(worldX, worldY)
    local zoom = self.zoom or 1.0
    return (worldX - self.x) * zoom, (worldY - self.y) * zoom
end

return Camera
