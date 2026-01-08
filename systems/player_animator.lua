-- Player Animator System
-- Manages player animation states and directional sprite selection

local PlayerAnimator = {}
PlayerAnimator.__index = PlayerAnimator

-- Sprite sheet configuration
local SPRITE_PATH = "assets/Animations/archersprite.png"
local GRID_COLS = 14
local GRID_ROWS = 4

-- Direction row mapping (0-indexed rows)
local DIRECTION_ROWS = {
    down = 0,   -- Row 0: S key
    right = 1,  -- Row 1: D key
    up = 2,     -- Row 2: W key
    left = 3,   -- Row 3: A key
}

-- Frame ranges for each animation type (0-indexed)
local ANIMATIONS = {
    idle = { startFrame = 0, endFrame = 0 },      -- Frame 0 only
    walk = { startFrame = 1, endFrame = 9 },      -- Frames 1-9 (9 frames)
    attack = { startFrame = 10, endFrame = 13 },  -- Frames 10-13 (4 frames)
}

-- Animation speeds (seconds per frame)
local ANIMATION_SPEEDS = {
    idle = 0.1,
    walk = 0.05,   -- Faster walking animation
    attack = 0.04, -- Quick bow draw
}

function PlayerAnimator:new()
    local animator = {
        image = nil,
        quads = {},  -- 2D table: quads[row][col]
        frameWidth = 0,
        frameHeight = 0,
        
        -- Current state
        direction = "down",  -- down, right, up, left
        state = "idle",      -- idle, walk, attack
        
        -- Animation timing
        currentFrame = 0,
        frameTimer = 0,
        
        -- Attack animation tracking
        isAttacking = false,
        onAttackComplete = nil,
    }
    
    -- Load the sprite sheet
    local success, result = pcall(love.graphics.newImage, SPRITE_PATH)
    if success then
        animator.image = result
        animator.image:setFilter("nearest", "nearest")
    else
        print("PlayerAnimator: Failed to load sprite sheet: " .. SPRITE_PATH)
        return nil
    end
    
    -- Calculate frame dimensions
    local imgWidth = animator.image:getWidth()
    local imgHeight = animator.image:getHeight()
    animator.frameWidth = imgWidth / GRID_COLS
    animator.frameHeight = imgHeight / GRID_ROWS
    
    -- Create all quads
    for row = 0, GRID_ROWS - 1 do
        animator.quads[row] = {}
        for col = 0, GRID_COLS - 1 do
            animator.quads[row][col] = love.graphics.newQuad(
                col * animator.frameWidth,
                row * animator.frameHeight,
                animator.frameWidth,
                animator.frameHeight,
                imgWidth,
                imgHeight
            )
        end
    end
    
    setmetatable(animator, PlayerAnimator)
    return animator
end

function PlayerAnimator:update(dt)
    local anim = ANIMATIONS[self.state]
    local speed = ANIMATION_SPEEDS[self.state]
    
    self.frameTimer = self.frameTimer + dt
    
    if self.frameTimer >= speed then
        self.frameTimer = self.frameTimer - speed
        self.currentFrame = self.currentFrame + 1
        
        -- Check if animation finished
        local frameCount = anim.endFrame - anim.startFrame + 1
        if self.currentFrame >= frameCount then
            if self.state == "attack" then
                -- Attack animation finished, return to idle
                self.isAttacking = false
                self.state = "idle"
                self.currentFrame = 0
                if self.onAttackComplete then
                    self.onAttackComplete()
                end
            else
                -- Loop other animations
                self.currentFrame = 0
            end
        end
    end
end

function PlayerAnimator:draw(x, y, scale)
    if not self.image then return end
    
    scale = scale or 1
    
    local row = DIRECTION_ROWS[self.direction] or 0
    local anim = ANIMATIONS[self.state]
    local col = anim.startFrame + self.currentFrame
    
    -- Clamp to valid range
    col = math.min(col, anim.endFrame)
    
    local quad = self.quads[row][col]
    if not quad then return end
    
    -- Center the sprite
    local ox = self.frameWidth / 2
    local oy = self.frameHeight / 2
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.image,
        quad,
        x,
        y,
        0,  -- No rotation
        scale,
        scale,
        ox,
        oy
    )
end

-- Set movement direction based on WASD input
function PlayerAnimator:setDirection(dir)
    if DIRECTION_ROWS[dir] then
        self.direction = dir
    end
end

-- Set animation state
function PlayerAnimator:setState(newState)
    if self.state == newState then return end
    if self.isAttacking and newState ~= "attack" then return end  -- Don't interrupt attacks
    
    self.state = newState
    self.currentFrame = 0
    self.frameTimer = 0
end

-- Trigger attack animation
function PlayerAnimator:attack(onComplete)
    if self.isAttacking then return end
    
    self.isAttacking = true
    self.state = "attack"
    self.currentFrame = 0
    self.frameTimer = 0
    self.onAttackComplete = onComplete
end

-- Check if currently attacking
function PlayerAnimator:isAttackPlaying()
    return self.isAttacking
end

-- Get current direction
function PlayerAnimator:getDirection()
    return self.direction
end

-- Get frame dimensions for collision/positioning
function PlayerAnimator:getFrameSize()
    return self.frameWidth, self.frameHeight
end

return PlayerAnimator

