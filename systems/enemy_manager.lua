-- Enemy Manager
-- Unified registry for all enemies
-- Solves the "wolf targeting bug" by ensuring all enemies are tracked in one place

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager:new()
    local manager = {
        -- Single unified registry
        all = {},
        
        -- Type-specific lookups (for backwards compatibility and performance)
        byType = {},
    }
    setmetatable(manager, EnemyManager)
    return manager
end

-- Register an enemy (called when enemy is spawned)
function EnemyManager:register(enemy, enemyType)
    enemy.enemyType = enemyType or "unknown"
    table.insert(self.all, enemy)
    
    -- Also add to type-specific lookup
    if not self.byType[enemyType] then
        self.byType[enemyType] = {}
    end
    table.insert(self.byType[enemyType], enemy)
end

-- Get all alive enemies
function EnemyManager:getAlive()
    local alive = {}
    for _, enemy in ipairs(self.all) do
        if enemy.isAlive then
            table.insert(alive, enemy)
        end
    end
    return alive
end

-- Get enemies by type
function EnemyManager:getByType(typeId)
    if not self.byType[typeId] then
        return {}
    end
    
    local alive = {}
    for _, enemy in ipairs(self.byType[typeId]) do
        if enemy.isAlive then
            table.insert(alive, enemy)
        end
    end
    return alive
end

-- Remove dead enemies (cleanup)
function EnemyManager:cleanup()
    local newAll = {}
    for _, enemy in ipairs(self.all) do
        if enemy.isAlive then
            table.insert(newAll, enemy)
        end
    end
    self.all = newAll
    
    -- Cleanup type-specific lookups
    for typeId, enemies in pairs(self.byType) do
        local newList = {}
        for _, enemy in ipairs(enemies) do
            if enemy.isAlive then
                table.insert(newList, enemy)
            end
        end
        self.byType[typeId] = newList
    end
end

-- Check if any enemies are alive
function EnemyManager:hasAlive()
    for _, enemy in ipairs(self.all) do
        if enemy.isAlive then
            return true
        end
    end
    return false
end

-- Get count of alive enemies
function EnemyManager:countAlive()
    local count = 0
    for _, enemy in ipairs(self.all) do
        if enemy.isAlive then
            count = count + 1
        end
    end
    return count
end

-- Clear all enemies (for new floor/restart)
function EnemyManager:clear()
    self.all = {}
    self.byType = {}
end

-- Find nearest enemy to a point
function EnemyManager:findNearest(x, y, maxDistance)
    maxDistance = maxDistance or math.huge
    local nearest = nil
    local nearestDist = maxDistance
    
    for _, enemy in ipairs(self.all) do
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

-- Get all enemies in range
function EnemyManager:getInRange(x, y, range)
    local inRange = {}
    for _, enemy in ipairs(self.all) do
        if enemy.isAlive then
            local ex, ey = enemy:getPosition()
            local dx = ex - x
            local dy = ey - y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= range then
                table.insert(inRange, enemy)
            end
        end
    end
    return inRange
end

return EnemyManager
