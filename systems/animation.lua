-- Animation System for Sprite Sheets
local Animation = {}
Animation.__index = Animation

function Animation:new(image, frameWidth, frameHeight, frameCount, fps)
    -- Check if image is valid
    if not image then
        error("Animation:new requires a valid image")
    end
    
    -- If frameWidth not provided, calculate from image dimensions and frameCount
    if not frameWidth or frameWidth <= 0 then
        frameWidth = image:getWidth() / (frameCount or 1)
    end
    if not frameHeight or frameHeight <= 0 then
        frameHeight = image:getHeight()
    end
    
    -- Ensure they are numbers
    frameWidth = tonumber(frameWidth) or 64
    frameHeight = tonumber(frameHeight) or 64
    
    local anim = {
        image = image,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        frameCount = frameCount or math.floor(image:getWidth() / frameWidth),
        fps = fps or 10,
        currentFrame = 1,  -- Always start at frame 1 (integer)
        drawFrame = 1,     -- Frame to draw (locked during draw call)
        time = 0,
        playing = false,
        quads = {} -- Cache quads for better performance
    }
    
    -- Ensure currentFrame is an integer
    anim.currentFrame = math.floor(anim.currentFrame)
    
    -- Pre-calculate all quads
    -- Ensure frameWidth and frameHeight are integers and valid
    frameWidth = math.floor(frameWidth)
    frameHeight = math.floor(frameHeight)
    
    -- Verify these are valid numbers
    if frameWidth <= 0 or frameHeight <= 0 then
        error("Invalid frame dimensions: " .. frameWidth .. "x" .. frameHeight)
    end
    
    anim.frameWidth = frameWidth
    anim.frameHeight = frameHeight
    
    -- Verify image dimensions
    local imgW = image:getWidth()
    local imgH = image:getHeight()
    
    print("Creating quads: image=" .. imgW .. "x" .. imgH .. ", frame=" .. frameWidth .. "x" .. frameHeight .. ", count=" .. anim.frameCount)
    
    for i = 1, anim.frameCount do
        local x = (i - 1) * frameWidth
        -- Create quad for each frame (384px / 6 frames = 64px per frame)
        -- Make absolutely sure the quad only covers ONE frame
        -- Verify bounds before creating quad
        if x + frameWidth <= imgW then
            -- Create quad with exact bounds - ensure width is exactly frameWidth
            anim.quads[i] = love.graphics.newQuad(
                x,              -- Start X of this frame
                0,              -- Start Y (always 0 for horizontal sprite sheets)
                frameWidth,     -- Width of ONE frame only
                frameHeight,    -- Height of ONE frame only
                imgW,           -- Total image width
                imgH            -- Total image height
            )
            
            -- Verify the quad was created correctly
            local qx, qy, qw, qh = anim.quads[i]:getViewport()
            if qw ~= frameWidth or qh ~= frameHeight then
                print("WARNING: Quad " .. i .. " has wrong size! Expected " .. frameWidth .. "x" .. frameHeight .. ", got " .. qw .. "x" .. qh)
            end
        else
            -- If bounds exceeded, use the last valid frame's quad
            anim.quads[i] = anim.quads[i - 1] or anim.quads[1]
        end
    end
    
    setmetatable(anim, Animation)
    return anim
end

function Animation:update(dt)
    if self.playing and self.frameCount > 1 then
        self.time = self.time + dt
        local frameTime = 1 / self.fps
        if self.time >= frameTime then
            self.time = self.time - frameTime
            -- Advance to next frame - ensure it's always an integer
            self.currentFrame = math.floor(self.currentFrame) + 1
            if self.currentFrame > self.frameCount then
                self.currentFrame = 1
            end
            -- Double-check it's an integer
            self.currentFrame = math.floor(self.currentFrame)
        end
    end
    -- Always ensure currentFrame is an integer after update
    self.currentFrame = math.floor(self.currentFrame)
    if self.currentFrame < 1 then self.currentFrame = 1 end
    if self.currentFrame > self.frameCount then self.currentFrame = self.frameCount end
    
    -- Lock the frame for drawing (snapshot at end of update)
    self.drawFrame = self.currentFrame
end

function Animation:play()
    self.playing = true
end

function Animation:stop()
    self.playing = false
    self.currentFrame = 1
    self.drawFrame = 1
    self.time = 0
    -- Ensure frames are integers
    self.currentFrame = math.floor(self.currentFrame)
    self.drawFrame = math.floor(self.drawFrame)
end

function Animation:draw(x, y, scale)
    scale = scale or 1
    -- Use the locked drawFrame (snapshot from update) to prevent mid-draw changes
    local frame = math.floor(self.drawFrame)
    
    -- Clamp to valid range
    if frame < 1 then frame = 1 end
    if frame > self.frameCount then frame = self.frameCount end
    
    -- CRITICAL: Verify frameWidth and frameHeight are valid
    if not self.frameWidth or self.frameWidth <= 0 then
        print("ERROR: frameWidth is invalid: " .. tostring(self.frameWidth))
        return
    end
    if not self.frameHeight or self.frameHeight <= 0 then
        print("ERROR: frameHeight is invalid: " .. tostring(self.frameHeight))
        return
    end
    
    -- Create quad on the fly to ensure correct dimensions
    -- This guarantees we're using the exact frameWidth and frameHeight
    local quadX = (frame - 1) * self.frameWidth
    local imgW = self.image:getWidth()
    local imgH = self.image:getHeight()
    
    -- Verify bounds
    if quadX + self.frameWidth > imgW then
        print("ERROR: Quad would exceed image bounds! frame=" .. frame .. " quadX=" .. quadX .. " width=" .. self.frameWidth .. " imgW=" .. imgW)
        return
    end
    
    local quad = love.graphics.newQuad(
        quadX,              -- Start X of this frame
        0,                  -- Start Y
        self.frameWidth,    -- Width: exactly one frame
        self.frameHeight,   -- Height: exactly one frame
        imgW,               -- Total image width
        imgH                -- Total image height
    )
    
    -- Verify quad was created
    if not quad then
        print("ERROR: Failed to create quad!")
        return
    end
    
    -- Draw only once with the exact quad for this frame
    love.graphics.draw(
        self.image,
        quad,
        x,
        y,
        0,
        scale,
        scale,
        self.frameWidth / 2,
        self.frameHeight / 2
    )
end

return Animation

