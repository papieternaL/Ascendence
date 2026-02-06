-- Collision System
-- Handles all projectile vs enemy collisions
-- Uses EnemyManager so ALL enemies are automatically checked

local CollisionSystem = {}
CollisionSystem.__index = CollisionSystem

function CollisionSystem:new(enemyManager, particles, damageNumbers, screenShake, playerStats, player)
    local system = {
        enemyManager = enemyManager,
        particles = particles,
        damageNumbers = damageNumbers,
        screenShake = screenShake,
        playerStats = playerStats,
        player = player,
    }
    setmetatable(system, CollisionSystem)
    return system
end

-- Check collision between two entities
function CollisionSystem:checkCollision(entity1, entity2)
    local x1, y1 = entity1:getPosition()
    local x2, y2 = entity2:getPosition()
    local dx = x1 - x2
    local dy = y1 - y2
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (entity1:getSize() + entity2:getSize())
end

-- Process arrow collisions with all enemies
-- Returns true if arrow hit something and should stop (no pierce remaining)
function CollisionSystem:processArrowCollisions(arrow, rollDamageFunc, onHitCallback)
    local ax, ay = arrow:getPosition()
    local hitEnemy = false
    
    -- Get all alive enemies from manager
    local enemies = self.enemyManager:getAlive()
    
    for _, enemy in ipairs(enemies) do
        if self:checkCollision(arrow, enemy) and arrow:canHit(enemy) then
            arrow:markHit(enemy)
            
            local ex, ey = enemy:getPosition()
            local dmg, isCrit = rollDamageFunc(arrow.damage, arrow.alwaysCrit)
            
            -- Apply elite/MCM damage bonus if applicable
            if arrow.eliteMcmDamageMul and (enemy.isElite or enemy.isMCM) then
                dmg = dmg * arrow.eliteMcmDamageMul
            end
            
            -- Call custom hit handler if provided
            if onHitCallback then
                onHitCallback(arrow, enemy, dmg, isCrit, ex, ey, ax, ay)
            end
            
            -- Apply damage
            local died = enemy:takeDamage(dmg, ax, ay, arrow.knockback)
            
            -- Apply status effect if applicable
            if arrow.appliesStatus and enemy.statusComponent then
                local statusData = arrow.appliesStatus
                enemy.statusComponent:applyStatus(
                    statusData.status,
                    1,
                    statusData.duration,
                    { damage = arrow.damage }
                )
            end
            
            -- Trigger upgrade procs
            if arrow.kind == "primary" and self.playerStats then
                local UpgradeApplication = require("systems.upgrade_application")
                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = enemy, damage = dmg, is_crit = isCrit })
                if isCrit then
                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", { target = enemy, damage = dmg, is_crit = isCrit })
                end
            end
            
            -- Handle death
            if died then
                if onHitCallback then
                    onHitCallback(arrow, enemy, dmg, isCrit, ex, ey, ax, ay, true) -- died = true
                end
            end
            
            -- Check pierce
            if arrow:consumePierce() then
                hitEnemy = false -- Can continue
            else
                hitEnemy = true -- Stop checking
                break
            end
        end
    end
    
    return hitEnemy
end

return CollisionSystem
