-- Player Animator System
-- Strip-based archer animations from assets/Archer/
-- Sprites face right; flip horizontally when facing left.

local PlayerAnimator = {}
PlayerAnimator.__index = PlayerAnimator

local ARCHER_PATH = "assets/Archer/"
local STRIPS = {
    idle   = "spr_ArcherIdle_strip_NoBkg.png",
    run    = "spr_ArcherRun_strip_NoBkg.png",
    attack = "spr_ArcherAttack_strip_NoBkg.png",
    dash   = "spr_ArcherDash_strip_NoBkg.png",
}

-- Animation speeds (seconds per frame)
local ANIMATION_SPEEDS = {
    idle   = 0.12,
    run    = 0.06,
    attack = 0.04,
    dash   = 0.05,
}

function PlayerAnimator:new()
    local animator = {
        strips = {},
        quads = {},
        frameCounts = {},
        frameSizes = {},
        
        state = "idle",
        currentFrame = 0,
        frameTimer = 0,
        
        isAttacking = false,
        onAttackComplete = nil,
        
        facingRight = true,
    }
    
    for state, filename in pairs(STRIPS) do
        local path = ARCHER_PATH .. filename
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then
            img:setFilter("nearest", "nearest")
            animator.strips[state] = img
            local w, h = img:getWidth(), img:getHeight()
            if h > 0 then
                local count = math.max(1, math.floor(w / h))
                animator.frameCounts[state] = count
                animator.frameSizes[state] = { w = h, h = h }
                animator.quads[state] = {}
                for i = 0, count - 1 do
                    animator.quads[state][i] = love.graphics.newQuad(i * h, 0, h, h, w, h)
                end
            end
        end
    end
    
    setmetatable(animator, PlayerAnimator)
    return animator
end

function PlayerAnimator:update(dt)
    local count = self.frameCounts[self.state] or 1
    local speed = ANIMATION_SPEEDS[self.state] or 0.1
    
    self.frameTimer = self.frameTimer + dt
    
    if self.frameTimer >= speed then
        self.frameTimer = self.frameTimer - speed
        self.currentFrame = self.currentFrame + 1
        
        if self.currentFrame >= count then
            if self.state == "attack" then
                self.isAttacking = false
                self.state = "idle"
                self.currentFrame = 0
                if self.onAttackComplete then
                    self.onAttackComplete()
                end
            elseif self.state == "dash" then
                self.state = "idle"
                self.currentFrame = 0
            else
                self.currentFrame = 0
            end
        end
    end
end

function PlayerAnimator:draw(x, y, scale)
    scale = scale or 1
    local strip = self.strips[self.state] or self.strips.idle
    if not strip then return end
    
    local quads = self.quads[self.state] or self.quads.idle
    local idx = math.min(self.currentFrame, (self.frameCounts[self.state] or 1) - 1)
    local quad = quads and quads[idx]
    if not quad then return end
    
    local sz = self.frameSizes[self.state] or self.frameSizes.idle
    local fw = sz and sz.w or 32
    local fh = sz and sz.h or 32
    
    love.graphics.setColor(1, 1, 1, 1)
    local sx = self.facingRight and scale or -scale
    love.graphics.draw(strip, quad, x, y, 0, sx, scale, fw / 2, fh)
end

function PlayerAnimator:setFacingRight(right)
    self.facingRight = right
end

function PlayerAnimator:setState(newState)
    if self.state == newState then return end
    if self.isAttacking and newState ~= "attack" then return end
    
    self.state = newState
    self.currentFrame = 0
    self.frameTimer = 0
end

function PlayerAnimator:attack(onComplete)
    if self.isAttacking then return end
    
    self.isAttacking = true
    self.state = "attack"
    self.currentFrame = 0
    self.frameTimer = 0
    self.onAttackComplete = onComplete
end

function PlayerAnimator:isAttackPlaying()
    return self.isAttacking
end

function PlayerAnimator:getFrameSize()
    local sz = self.frameSizes[self.state] or self.frameSizes.idle
    if sz then return sz.w, sz.h end
    return 32, 32
end

return PlayerAnimator
