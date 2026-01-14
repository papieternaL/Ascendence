-- Arrow Volley Entity
-- AOE attack with falling arrow rain effect

local ArrowVolley = {}
ArrowVolley.__index = ArrowVolley

-- Configuration
local DAMAGE_RADIUS = 60      -- AOE damage radius
local BASE_DAMAGE = 25        -- Damage per hit
local FALL_DURATION = 0.4     -- Time for arrows to fall
local IMPACT_TIME = 0.4       -- When damage is applied
local FADE_OUT_TIME = 0.3     -- Fade out duration after impact
local ARROW_COUNT_MIN = 8     -- Minimum arrows in volley
local ARROW_COUNT_MAX = 12    -- Maximum arrows in volley
local ARROW_START_HEIGHT = 120 -- How far above the circle arrows start

function ArrowVolley:new(x, y, damage, damageRadius, arrowCountAdd)
    local volley = {
        x = x,
        y = y,
        damage = damage or BASE_DAMAGE,
        damageRadius = damageRadius or DAMAGE_RADIUS,
        isActive = true,
        hasDamaged = false,
        timer = 0,
        duration = FALL_DURATION + FADE_OUT_TIME,
        impactTime = IMPACT_TIME,
        arrows = {},
    }
    
    -- Generate falling arrow particles (with optional extra arrows from upgrades)
    local extraArrows = arrowCountAdd or 0
    local arrowCount = math.random(ARROW_COUNT_MIN, ARROW_COUNT_MAX) + extraArrows
    for i = 1, arrowCount do
        -- Random position within the circle
        local angle = math.random() * math.pi * 2
        local radius = math.random() * damageRadius * 0.8 -- Keep within 80% of radius
        local endX = x + math.cos(angle) * radius
        local endY = y + math.sin(angle) * radius
        
        -- Start position above the target
        local startX = endX + math.random(-20, 20) -- Slight horizontal offset
        local startY = y - ARROW_START_HEIGHT - math.random(0, 30)
        
        table.insert(volley.arrows, {
            startX = startX,
            startY = startY,
            endX = endX,
            endY = endY,
            currentX = startX,
            currentY = startY,
            rotation = math.pi / 2, -- Point downward
            size = 6 + math.random() * 3, -- Random size variation
        })
    end
    
    setmetatable(volley, ArrowVolley)
    return volley
end

function ArrowVolley:update(dt)
    if not self.isActive then return end
    
    self.timer = self.timer + dt
    
    -- Update arrow positions (falling animation)
    if self.timer < FALL_DURATION then
        local fallProgress = self.timer / FALL_DURATION
        -- Ease-in effect (accelerating fall)
        local eased = fallProgress * fallProgress
        
        for _, arrow in ipairs(self.arrows) do
            arrow.currentX = arrow.startX + (arrow.endX - arrow.startX) * eased
            arrow.currentY = arrow.startY + (arrow.endY - arrow.startY) * eased
        end
    end
    
    -- Check if duration finished
    if self.timer >= self.duration then
        self.isActive = false
    end
end

-- Check if damage should be applied this frame
function ArrowVolley:shouldApplyDamage()
    if self.hasDamaged then return false end
    if self.timer >= self.impactTime then
        self.hasDamaged = true
        return true
    end
    return false
end

-- Get enemies in damage radius
function ArrowVolley:getEnemiesInRadius(enemies)
    local hit = {}
    for _, enemy in ipairs(enemies) do
        if enemy.isAlive then
            local ex, ey = enemy:getPosition()
            local dx = ex - self.x
            local dy = ey - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= self.damageRadius then
                table.insert(hit, enemy)
            end
        end
    end
    return hit
end

function ArrowVolley:draw()
    if not self.isActive then return end
    
    local fadeProgress = 1.0
    
    -- After impact, fade out
    if self.timer > FALL_DURATION then
        local fadeTime = self.timer - FALL_DURATION
        fadeProgress = 1.0 - (fadeTime / FADE_OUT_TIME)
    end
    
    -- Draw static red target circle
    love.graphics.setColor(1, 0.2, 0.2, 0.3 * fadeProgress)
    love.graphics.circle("fill", self.x, self.y, self.damageRadius)
    
    -- Draw red outline
    love.graphics.setColor(1, 0, 0, 0.7 * fadeProgress)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.damageRadius)
    love.graphics.setLineWidth(1)
    
    -- Draw falling arrows
    for _, arrow in ipairs(self.arrows) do
        -- Calculate arrow alpha based on progress
        local arrowAlpha = fadeProgress
        if self.timer < 0.1 then
            -- Fade in at start
            arrowAlpha = arrowAlpha * (self.timer / 0.1)
        end
        
        love.graphics.setColor(0.8, 0.1, 0.1, arrowAlpha)
        
        -- Draw arrow as a triangle pointing down
        local size = arrow.size
        local x, y = arrow.currentX, arrow.currentY
        
        -- Triangle vertices (pointing down)
        local x1 = x
        local y1 = y - size
        local x2 = x - size * 0.4
        local y2 = y + size * 0.5
        local x3 = x + size * 0.4
        local y3 = y + size * 0.5
        
        love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3)
    end
    
    -- Impact flash effect
    if self.timer >= FALL_DURATION and self.timer < FALL_DURATION + 0.1 then
        local flashAlpha = 1.0 - ((self.timer - FALL_DURATION) / 0.1)
        love.graphics.setColor(1, 1, 1, 0.6 * flashAlpha)
        love.graphics.circle("fill", self.x, self.y, self.damageRadius * 1.2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function ArrowVolley:isFinished()
    return not self.isActive
end

function ArrowVolley:getPosition()
    return self.x, self.y
end

function ArrowVolley:getDamage()
    return self.damage
end

function ArrowVolley:getDamageRadius()
    return self.damageRadius
end

return ArrowVolley
