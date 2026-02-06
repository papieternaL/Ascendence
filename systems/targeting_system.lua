-- Targeting System
-- Finds nearest enemies for auto-aim and ability targeting
-- Uses EnemyManager so ALL enemies are automatically included

local TargetingSystem = {}
TargetingSystem.__index = TargetingSystem

function TargetingSystem:new(enemyManager)
    local system = {
        enemyManager = enemyManager,
    }
    setmetatable(system, TargetingSystem)
    return system
end

-- Find nearest enemy to a point (for primary attacks, Power Shot, etc.)
function TargetingSystem:findNearest(x, y, maxDistance)
    return self.enemyManager:findNearest(x, y, maxDistance)
end

-- Find nearest enemy for ability targeting (Arrow Volley, etc.)
function TargetingSystem:findNearestForAbility(x, y, range)
    return self.enemyManager:findNearest(x, y, range)
end

-- Get all enemies in range (for AOE abilities)
function TargetingSystem:getInRange(x, y, range)
    return self.enemyManager:getInRange(x, y, range)
end

-- Find nearest enemy by type (for specific targeting needs)
function TargetingSystem:findNearestByType(x, y, typeId, maxDistance)
    maxDistance = maxDistance or math.huge
    local enemies = self.enemyManager:getByType(typeId)
    local nearest = nil
    local nearestDist = maxDistance
    
    for _, enemy in ipairs(enemies) do
        if enemy.isAlive then
            local ex, ey = enemy:getPosition()
            local dx = ex - x
            local dy = ey - y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
    end
    
    return nearest, nearestDist
end

return TargetingSystem
