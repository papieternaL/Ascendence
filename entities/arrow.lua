-- Arrow Projectile
local Arrow = {}
Arrow.__index = Arrow

-- Static image (loaded once)
Arrow.image = nil

-- opts:
--   damage, speed, size, lifetime
--   pierce (number of additional targets allowed after the first)
--   alwaysCrit (bool)
--   kind ("primary" | "multi_shot" | etc)
--   knockback (number) - optional knockback force hint for enemies
function Arrow:new(x, y, targetX, targetY, opts)
    -- Load image if not loaded (Tiny Town tile_0119)
    if not Arrow.image then
        local paths = {
            "assets/2D assets/Tiny Town/Tiles/tile_0119.png",
            "assets/32x32/fb1097.png",
            "images/32x32/fb1097.png",
        }
        for _, p in ipairs(paths) do
            local success, result = pcall(love.graphics.newImage, p)
            if success and result then
                Arrow.image = result
                Arrow.image:setFilter("nearest", "nearest")
                break
            end
        end
    end
    
    opts = opts or {}

    local dx = targetX - x
    local dy = targetY - y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= 0 then
        distance = 1
        dx, dy = 1, 0
    end
    
    -- Calculate angle from velocity
    local angle = math.atan2(dy, dx)
    
    local speed = opts.speed or 500
    local arrow = {
        x = x,
        y = y,
        size = opts.size or 10,
        speed = speed, -- faster than fireballs
        vx = (dx / distance) * speed,
        vy = (dy / distance) * speed,
        angle = angle,
        damage = opts.damage or 15, -- slightly more damage than fireball
        lifetime = opts.lifetime or 4,
        age = 0
        ,
        pierce = opts.pierce or 0,
        alwaysCrit = opts.alwaysCrit == true,
        kind = opts.kind or "primary",
        knockback = opts.knockback,
        hit = {}, -- set of entities already hit (avoid double-hit across frames)

        -- Ricochet
        ricochetBounces = opts.ricochetBounces or 0,
        ricochetRange = opts.ricochetRange or 220,

        -- Ghost Quiver (infinite pierce)
        ghosting = opts.ghosting == true,

        -- Ice attunement: dissolve blast on expire
        iceAttuned = opts.iceAttuned == true,

        -- Elemental attunement VFX
        element = opts.element or nil,
    }
    setmetatable(arrow, Arrow)
    return arrow
end

function Arrow:update(dt)
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update lifetime
    self.age = self.age + dt
end

function Arrow:draw()
    local alpha = 1 - (self.age / self.lifetime) * 0.3

    -- Tint/scale by arrow kind
    local r, g, b = 1, 1, 1
    local scale = 1
    if self.kind == "multi_shot" then
        r, g, b = 1, 0.9, 0.25
        scale = 1.25
    elseif self.kind == "arrowstorm" then
        r, g, b = 1, 0.85, 0.3
        scale = 0.8
    elseif self.kind == "entangle" then
        r, g, b = 0.35, 0.5, 0.9
        scale = 0.9
    end

    -- Ghost quiver: translucent cyan glow
    if self.ghosting then
        r, g, b = 0.4, 0.85, 1.0
        alpha = alpha * 0.7
    end

    love.graphics.setColor(r, g, b, alpha)

    -- Draw the arrow sprite rotated to face direction
    local img = Arrow.image
    if img then
        local imgW = img:getWidth()
        local imgH = img:getHeight()
        -- Tiny pack sprites are 16x16; scale up for visibility
        local baseScale = (imgW <= 18) and 2.0 or 1.0
        local drawScale = scale * baseScale
        love.graphics.draw(
            img,
            self.x,
            self.y,
            self.angle + math.pi / 4,
            drawScale, drawScale,
            imgW / 2, imgH / 2
        )
    else
        -- Fallback: pixel rectangle if no sprite loaded
        local len = self.size * scale
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.rectangle("fill", -len, -1, len * 2, 3)
        love.graphics.pop()
    end

    -- Ghost quiver trailing glow
    if self.ghosting then
        love.graphics.setColor(0.3, 0.7, 1.0, alpha * 0.3)
        local gs = (self.size or 10) * 0.6
        love.graphics.rectangle("fill", self.x - gs, self.y - gs, gs * 2, gs * 2)
    end

    -- Elemental aura VFX
    local t = love.timer.getTime()
    if self.element == "lightning" then
        local pulse = 0.5 + 0.3 * math.sin(t * 18 + self.x * 0.1)
        -- Outer electric glow
        love.graphics.setColor(0.4, 0.7, 1.0, pulse * alpha * 0.5)
        love.graphics.circle("fill", self.x, self.y, 12)
        -- Inner bright core
        love.graphics.setColor(0.7, 0.9, 1.0, pulse * alpha * 0.8)
        love.graphics.circle("fill", self.x, self.y, 6)
        -- Tiny spark trails (2 orbiting sparks)
        for k = 0, 1 do
            local sparkAngle = t * 12 + k * math.pi + self.age * 8
            local sparkR = 8 + 3 * math.sin(t * 15 + k)
            local sx = self.x + math.cos(sparkAngle) * sparkR
            local sy = self.y + math.sin(sparkAngle) * sparkR
            love.graphics.setColor(0.8, 0.95, 1.0, alpha * 0.9)
            love.graphics.circle("fill", sx, sy, 2)
        end

    elseif self.element == "fire" then
        local flicker = 0.5 + 0.3 * math.sin(t * 14 + self.y * 0.15)
        -- Outer fire glow
        love.graphics.setColor(1.0, 0.4, 0.1, flicker * alpha * 0.4)
        love.graphics.circle("fill", self.x, self.y, 13)
        -- Inner bright ember
        love.graphics.setColor(1.0, 0.7, 0.2, flicker * alpha * 0.7)
        love.graphics.circle("fill", self.x, self.y, 7)
        -- Trailing ember particle behind arrow
        local trailX = self.x - math.cos(self.angle) * 10
        local trailY = self.y - math.sin(self.angle) * 10
        love.graphics.setColor(1.0, 0.5, 0.1, alpha * 0.5 * flicker)
        love.graphics.circle("fill", trailX, trailY, 4)

    elseif self.element == "ice" then
        local shimmer = 0.5 + 0.25 * math.sin(t * 10 + self.x * 0.12)
        -- Outer frost glow
        love.graphics.setColor(0.5, 0.85, 1.0, shimmer * alpha * 0.4)
        love.graphics.circle("fill", self.x, self.y, 12)
        -- Inner cold core
        love.graphics.setColor(0.7, 0.95, 1.0, shimmer * alpha * 0.6)
        love.graphics.circle("fill", self.x, self.y, 6)
        -- Small frost crystals (3 rotating)
        for k = 0, 2 do
            local crystalAngle = t * 5 + k * (math.pi * 2 / 3)
            local cr = 9
            local cx = self.x + math.cos(crystalAngle) * cr
            local cy = self.y + math.sin(crystalAngle) * cr
            love.graphics.setColor(0.85, 0.95, 1.0, alpha * 0.7 * shimmer)
            love.graphics.rectangle("fill", cx - 1.5, cy - 1.5, 3, 3)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Arrow:getPosition()
    return self.x, self.y
end

function Arrow:getSize()
    return self.size
end

function Arrow:isExpired()
    return self.age >= self.lifetime
end

function Arrow:canHit(target)
    return self.hit[target] ~= true
end

function Arrow:markHit(target)
    self.hit[target] = true
end

function Arrow:consumePierce()
    if self.ghosting then
        return true -- infinite pierce while ghosting
    end
    if self.pierce and self.pierce > 0 then
        self.pierce = self.pierce - 1
        return true
    end
    return false
end

-- Redirect this arrow towards a new target (for ricochet).
-- Returns true if bounce was consumed, false if no bounces remain.
function Arrow:bounceToward(targetX, targetY)
    if self.ricochetBounces <= 0 then return false end
    self.ricochetBounces = self.ricochetBounces - 1

    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0 then dist = 1 end

    self.vx = (dx / dist) * self.speed
    self.vy = (dy / dist) * self.speed
    self.angle = math.atan2(dy, dx)
    -- Refresh lifetime slightly so it can reach the next target
    self.age = math.max(0, self.age - 0.5)
    return true
end

return Arrow



