-- Arrow Projectile
local UpgradeApplication = require("systems.upgrade_application")

local Arrow = {}
Arrow.__index = Arrow

-- Static image (loaded once)
Arrow.image = nil

-- opts:
--   damage, speed, size, lifetime
--   pierce (number of additional targets allowed after the first)
--   alwaysCrit (bool)
--   kind ("primary" | "power_shot" | etc)
--   knockback (number) - optional knockback force hint for enemies
function Arrow:new(x, y, targetX, targetY, opts)
    -- Load image if not loaded (use Arrowv1 from Archer folder)
    if not Arrow.image then
        local success, result = pcall(love.graphics.newImage, "assets/Archer/Arrowv1.png")
        if success then
            Arrow.image = result
            Arrow.image:setFilter("nearest", "nearest")
        else
            -- Fallback to old asset
            success, result = pcall(love.graphics.newImage, "assets/32x32/fb1097.png")
            if success then
                Arrow.image = result
                Arrow.image:setFilter("nearest", "nearest")
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
        size = opts.size or 12,
        speed = speed, -- faster than fireballs
        vx = (dx / distance) * speed,
        vy = (dy / distance) * speed,
        angle = angle,
        damage = opts.damage or 15, -- slightly more damage than fireball
        lifetime = opts.lifetime or 4,
        age = 0,
        pierce = opts.pierce or 0,
        alwaysCrit = opts.alwaysCrit == true,
        kind = opts.kind or "primary",
        knockback = opts.knockback,
        hit = {}, -- set of entities already hit (avoid double-hit across frames)
        
        -- Ricochet (bounce to another enemy after hit)
        ricochetBounces = opts.ricochetBounces or 0,
        ricochetRange = opts.ricochetRange or 220,
        
        -- Ability mod fields
        eliteMcmDamageMul = opts.eliteMcmDamageMul,  -- Bonus damage vs elite/MCM enemies
        appliesStatus = opts.appliesStatus,          -- Status to apply on hit (e.g., shattered_armor)
        ghosting = opts.ghosting == true,            -- Ghost Quiver: pierce all (no damage/hit) until expiry
        
        -- Trail effect
        trail = {},  -- Stores recent positions {x, y}
        trailMaxLength = 6,
    }
    setmetatable(arrow, Arrow)
    return arrow
end

function Arrow:update(dt)
    -- Store current position in trail before moving
    table.insert(self.trail, 1, {x = self.x, y = self.y})
    
    -- Keep trail limited
    while #self.trail > self.trailMaxLength do
        table.remove(self.trail)
    end
    
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update lifetime
    self.age = self.age + dt
end

function Arrow:draw()
    local alpha = 1 - (self.age / self.lifetime) * 0.3 -- Slight fade over time
    
    -- Tint/scale by kind so abilities don't look identical
    local r, g, b = 1, 1, 1
    local scale = 0.055  -- Slightly larger for readability
    if self.kind == "power_shot" then
        r, g, b = 1, 0.9, 0.25
        scale = 0.075  -- Larger for power shot
    end
    
    -- Draw the arrow sprite rotated to face direction
    local img = Arrow.image
    if not img then
        -- Fallback: draw a simple circle if image failed to load
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", self.x, self.y, 4)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    local imgW = img:getWidth()
    local imgH = img:getHeight()
    
    -- Draw trail (afterimages)
    for i, pos in ipairs(self.trail) do
        local trailAlpha = alpha * (1 - i / self.trailMaxLength) * 0.4
        love.graphics.setColor(r, g, b, trailAlpha)
        love.graphics.draw(
            img,
            pos.x,
            pos.y,
            self.angle - math.pi / 2,  -- Rotate: sprite points UP, angle 0 = RIGHT
            scale * 0.8, scale * 0.8,
            imgW / 2, imgH / 2
        )
    end
    
    -- Draw main arrow
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.draw(
        img,
        self.x,
        self.y,
        self.angle - math.pi / 2,  -- Rotate: sprite points UP, angle 0 = RIGHT
        scale, scale,
        imgW / 2, imgH / 2 -- center origin
    )
    
    -- Reset color
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
    if self.pierce and self.pierce > 0 then
        self.pierce = self.pierce - 1
        return true
    end
    return false
end

return Arrow



