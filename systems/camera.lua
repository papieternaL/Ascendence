-- Simple Camera System for following the player
local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, worldWidth, worldHeight)
    local camera = {
        x = x or 0,
        y = y or 0,
        worldWidth = worldWidth or 1280,
        worldHeight = worldHeight or 720,
        smoothing = 0.1,  -- Lower = smoother/slower follow
    }
    setmetatable(camera, Camera)
    return camera
end

function Camera:update(dt, targetX, targetY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate desired camera position (centered on target)
    local desiredX = targetX - screenWidth / 2
    local desiredY = targetY - screenHeight / 2
    
    -- Smooth lerp to target
    self.x = self.x + (desiredX - self.x) * self.smoothing
    self.y = self.y + (desiredY - self.y) * self.smoothing
    
    -- Clamp camera to world bounds
    self.x = math.max(0, math.min(self.x, self.worldWidth - screenWidth))
    self.y = math.max(0, math.min(self.y, self.worldHeight - screenHeight))
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
