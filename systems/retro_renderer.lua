-- Retro Renderer System
-- Handles low-res canvas rendering, integer scaling, and shader effects
local Config = require("data.config")

local RetroRenderer = {}
RetroRenderer.__index = RetroRenderer

function RetroRenderer:new()
    local renderer = {
        enabled = Config.Retro.enabled,
        internalWidth = Config.Retro.internalWidth,
        internalHeight = Config.Retro.internalHeight,
        pixelScale = Config.Retro.pixelScale,
        
        -- Canvases
        gameCanvas = nil,      -- Low-res game rendering
        scaledCanvas = nil,    -- Scaled up canvas
        
        -- Shaders
        paletteShader = nil,
        scanlineShader = nil,
        
        -- State
        initialized = false,
    }
    setmetatable(renderer, RetroRenderer)
    return renderer
end

function RetroRenderer:initialize()
    if self.initialized then return end
    
    if not self.enabled then
        print("Retro renderer disabled")
        self.initialized = true
        return
    end
    
    print("Initializing retro renderer...")
    
    -- Create low-res canvas for game rendering
    self.gameCanvas = love.graphics.newCanvas(self.internalWidth, self.internalHeight)
    self.gameCanvas:setFilter("nearest", "nearest")
    
    -- Create scaled canvas
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.scaledCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
    self.scaledCanvas:setFilter("nearest", "nearest")
    
    -- Load shaders
    self:loadShaders()
    
    self.initialized = true
    print("Retro renderer initialized: " .. self.internalWidth .. "x" .. self.internalHeight)
end

function RetroRenderer:loadShaders()
    -- Load palette shader
    local paletteSuccess, paletteResult = pcall(love.graphics.newShader, "shaders/palette.glsl")
    if paletteSuccess then
        self.paletteShader = paletteResult
        print("Palette shader loaded")
    else
        print("Warning: Could not load palette shader: " .. tostring(paletteResult))
    end
    
    -- Load scanline shader
    local scanlineSuccess, scanlineResult = pcall(love.graphics.newShader, "shaders/scanline.glsl")
    if scanlineSuccess then
        self.scanlineShader = scanlineResult
        -- Set scanline intensity
        if self.scanlineShader then
            self.scanlineShader:send("intensity", Config.Retro.scanlineIntensity)
        end
        print("Scanline shader loaded")
    else
        print("Warning: Could not load scanline shader: " .. tostring(scanlineResult))
    end
end

function RetroRenderer:startDrawing()
    if not self.enabled or not self.initialized then
        return false
    end
    
    -- Set render target to low-res canvas
    love.graphics.setCanvas(self.gameCanvas)
    love.graphics.clear()
    
    return true
end

function RetroRenderer:finishDrawing()
    if not self.enabled or not self.initialized then
        return
    end
    
    -- Reset to screen
    love.graphics.setCanvas()
    
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate scaling to fit screen while maintaining aspect ratio
    local scaleX = screenWidth / self.internalWidth
    local scaleY = screenHeight / self.internalHeight
    local scale = math.min(scaleX, scaleY)
    
    -- Calculate position to center the game
    local drawWidth = self.internalWidth * scale
    local drawHeight = self.internalHeight * scale
    local offsetX = (screenWidth - drawWidth) / 2
    local offsetY = (screenHeight - drawHeight) / 2
    
    -- PASS 1: Draw game to scaledCanvas while applying the palette shader
    love.graphics.setCanvas(self.scaledCanvas)
    love.graphics.clear()
    
    if Config.Retro.paletteEnabled and self.paletteShader then
        love.graphics.setShader(self.paletteShader)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.gameCanvas,
        0, 0,
        0,
        scale, scale
    )
    love.graphics.setShader() -- Reset palette shader
    
    -- PASS 2: Draw the scaled/paletted result to the screen with scanlines
    love.graphics.setCanvas()
    
    if self.scanlineShader then
        love.graphics.setShader(self.scanlineShader)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.scaledCanvas,
        offsetX, offsetY
    )
    
    -- Reset shader
    love.graphics.setShader()
end

function RetroRenderer:isEnabled()
    return self.enabled and self.initialized
end

function RetroRenderer:getInternalDimensions()
    return self.internalWidth, self.internalHeight
end

function RetroRenderer:getScale()
    if not self.enabled then
        return 1, 1
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local scaleX = screenWidth / self.internalWidth
    local scaleY = screenHeight / self.internalHeight
    local scale = math.min(scaleX, scaleY)
    
    return scale, scale
end

return RetroRenderer

