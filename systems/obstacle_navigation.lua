-- Obstacle Navigation - Simple steering and collision resolution for blockers
-- Used by enemies to route around large terrain structures at same speed

local ObstacleNav = {}
ObstacleNav.__index = ObstacleNav

-- Resolve circle position against blocker circles (push out, slide along)
-- Returns new x, y after resolution
function ObstacleNav.resolvePosition(x, y, radius, blockers)
    if not blockers or #blockers == 0 then return x, y end
    local px, py = x, y
    for _, blk in ipairs(blockers) do
        local dx = px - blk.x
        local dy = py - blk.y
        local dist = math.sqrt(dx * dx + dy * dy)
        local minDist = radius + blk.radius
        if dist < minDist and dist > 0 then
            local nx = dx / dist
            local ny = dy / dist
            px = blk.x + nx * minDist
            py = blk.y + ny * minDist
        end
    end
    return px, py
end

-- Check if a point (circle) intersects any blocker (for projectile LOS)
function ObstacleNav.isPointBlocked(x, y, radius, blockers)
    if not blockers or #blockers == 0 then return false end
    for _, blk in ipairs(blockers) do
        local dx = x - blk.x
        local dy = y - blk.y
        if dx * dx + dy * dy < (radius + blk.radius) * (radius + blk.radius) then
            return true
        end
    end
    return false
end

-- Steer desired velocity toward target, avoiding blockers (same speed)
-- Returns adjusted vx, vy that avoids immediate collision
function ObstacleNav.steerVelocity(x, y, radius, targetX, targetY, speed, blockers)
    if not blockers or #blockers == 0 then
        local dx = targetX - x
        local dy = targetY - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            return (dx / dist) * speed, (dy / dist) * speed
        end
        return 0, 0
    end
    local dx = targetX - x
    local dy = targetY - y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0 then return 0, 0 end
    local vx = (dx / dist) * speed
    local vy = (dy / dist) * speed
    -- Check if moving would put us inside a blocker
    local step = 0.5
    local nx = x + vx * step
    local ny = y + vy * step
    local blocked = false
    for _, blk in ipairs(blockers) do
        local bdx = nx - blk.x
        local bdy = ny - blk.y
        if bdx * bdx + bdy * bdy < (radius + blk.radius) * (radius + blk.radius) then
            blocked = true
            break
        end
    end
    if not blocked then return vx, vy end
    -- Try perpendicular directions (left/right) to steer around
    local perpX = -dy / dist
    local perpY = dx / dist
    local bestVx, bestVy = vx, vy
    local bestDist = math.huge
    for side = -1, 1, 2 do
        local tvx = (dx / dist + perpX * side * 0.6) * speed
        local tvy = (dy / dist + perpY * side * 0.6) * speed
        local len = math.sqrt(tvx * tvx + tvy * tvy)
        if len > 0 then
            tvx = tvx / len * speed
            tvy = tvy / len * speed
        end
        local tx = x + tvx * step
        local ty = y + tvy * step
        local hit = false
        for _, blk in ipairs(blockers) do
            local bdx = tx - blk.x
            local bdy = ty - blk.y
            if bdx * bdx + bdy * bdy < (radius + blk.radius) * (radius + blk.radius) then
                hit = true
                break
            end
        end
        if not hit then
            local dToTarget = (targetX - tx) * (targetX - tx) + (targetY - ty) * (targetY - ty)
            if dToTarget < bestDist then
                bestDist = dToTarget
                bestVx, bestVy = tvx, tvy
            end
        end
    end
    return bestVx, bestVy
end

return ObstacleNav
