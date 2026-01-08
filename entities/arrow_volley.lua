-- Arrow Volley Entity
-- AOE attack that deals damage in a radius

local ArrowVolley = {}
ArrowVolley.__index = ArrowVolley

-- Configuration
local DAMAGE_RADIUS = 60    -- AOE damage radius
local BASE_DAMAGE = 25      -- Damage per hit
local DURATION = 0.5        -- How long the effect lasts

function ArrowVolley:new(x, y, damage, damageRadius)
    local volley = {
        x = x,
        y = y,
        damage = damage or BASE_DAMAGE,
        damageRadius = damageRadius or DAMAGE_RADIUS,
        isActive = true,
        hasDamaged = false,  -- Track if damage has been applied
        timer = 0,
        duration = DURATION,
        pulseScale = 1.0,
    }
    
    setmetatable(volley, ArrowVolley)
    return volley
end

function ArrowVolley:update(dt)
    if not self.isActive then return end
    
    self.timer = self.timer + dt
    
    -- Pulsing effect
    self.pulseScale = 1.0 + math.sin(self.timer * 20) * 0.2
    
    -- Check if duration finished
    if self.timer >= self.duration then
        self.isActive = false
    end
end

-- Check if damage should be applied this frame
-- Returns true once on the first call
function ArrowVolley:shouldApplyDamage()
    if self.hasDamaged then return false end
    self.hasDamaged = true
    return true
end

-- Get enemies in damage radius
-- @param enemies: table of enemy entities
-- @return table of enemies within radius
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
    
    -- Calculate alpha fade based on time
    local fadeProgress = 1.0 - (self.timer / self.duration)
    
    -- Draw red circle (filled with pulse)
    love.graphics.setColor(1, 0.2, 0.2, 0.4 * fadeProgress)
    love.graphics.circle("fill", self.x, self.y, self.damageRadius * self.pulseScale)
    
    -- Draw red outline
    love.graphics.setColor(1, 0, 0, 0.8 * fadeProgress)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.x, self.y, self.damageRadius * self.pulseScale)
    love.graphics.setLineWidth(1)
    
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

