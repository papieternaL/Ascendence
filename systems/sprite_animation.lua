-- Sprite Animation System
-- Handles sprite sheet animations with configurable frame ranges

local SpriteAnimation = {}
SpriteAnimation.__index = SpriteAnimation

-- Create a new sprite animation
-- @param imagePath: path to the sprite sheet
-- @param gridCols: number of columns in the sprite sheet
-- @param gridRows: number of rows in the sprite sheet
-- @param startFrame: first frame to use (0-indexed, left-to-right, top-to-bottom)
-- @param endFrame: last frame to use (inclusive)
-- @param frameDuration: seconds per frame
-- @param loop: whether to loop the animation (default false)
function SpriteAnimation:new(imagePath, gridCols, gridRows, startFrame, endFrame, frameDuration, loop)
    local anim = {
        image = nil,
        quads = {},
        currentFrame = 1,
        frameTimer = 0,
        frameDuration = frameDuration or 0.1,
        loop = loop or false,
        finished = false,
        onComplete = nil,
    }
    
    -- Load the image
    local success, result = pcall(love.graphics.newImage, imagePath)
    if success then
        anim.image = result
        anim.image:setFilter("nearest", "nearest")
    else
        print("SpriteAnimation: Failed to load image: " .. imagePath)
        return nil
    end
    
    -- Calculate frame dimensions
    local imgWidth = anim.image:getWidth()
    local imgHeight = anim.image:getHeight()
    local frameWidth = imgWidth / gridCols
    local frameHeight = imgHeight / gridRows
    
    anim.frameWidth = frameWidth
    anim.frameHeight = frameHeight
    
    -- Create quads for the specified frame range
    for frame = startFrame, endFrame do
        local col = frame % gridCols
        local row = math.floor(frame / gridCols)
        local quad = love.graphics.newQuad(
            col * frameWidth,
            row * frameHeight,
            frameWidth,
            frameHeight,
            imgWidth,
            imgHeight
        )
        table.insert(anim.quads, quad)
    end
    
    anim.totalFrames = #anim.quads
    
    setmetatable(anim, SpriteAnimation)
    return anim
end

-- Update the animation
function SpriteAnimation:update(dt)
    if self.finished then return end
    
    self.frameTimer = self.frameTimer + dt
    
    if self.frameTimer >= self.frameDuration then
        self.frameTimer = self.frameTimer - self.frameDuration
        self.currentFrame = self.currentFrame + 1
        
        if self.currentFrame > self.totalFrames then
            if self.loop then
                self.currentFrame = 1
            else
                self.currentFrame = self.totalFrames
                self.finished = true
                if self.onComplete then
                    self.onComplete()
                end
            end
        end
    end
end

-- Draw the current frame
-- @param x, y: position (center of the sprite)
-- @param scale: scale factor (default 1)
-- @param rotation: rotation in radians (default 0)
-- @param color: optional {r, g, b, a} table
function SpriteAnimation:draw(x, y, scale, rotation, color)
    if not self.image or #self.quads == 0 then return end
    
    scale = scale or 1
    rotation = rotation or 0
    
    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    local quad = self.quads[self.currentFrame]
    local ox = self.frameWidth / 2
    local oy = self.frameHeight / 2
    
    love.graphics.draw(
        self.image,
        quad,
        x,
        y,
        rotation,
        scale,
        scale,
        ox,
        oy
    )
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Check if animation is finished
function SpriteAnimation:isFinished()
    return self.finished
end

-- Reset the animation
function SpriteAnimation:reset()
    self.currentFrame = 1
    self.frameTimer = 0
    self.finished = false
end

-- Set completion callback
function SpriteAnimation:setOnComplete(callback)
    self.onComplete = callback
end

-- Get current frame index (1-based)
function SpriteAnimation:getCurrentFrame()
    return self.currentFrame
end

-- Get total number of frames
function SpriteAnimation:getTotalFrames()
    return self.totalFrames
end

return SpriteAnimation


