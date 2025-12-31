-- Arrow Projectile
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
    -- Load image if not loaded
    if not Arrow.image then
        local success, result = pcall(love.graphics.newImage, "assets/32x32/fb1097.png")
        if success then
            Arrow.image = result
            Arrow.image:setFilter("nearest", "nearest")
        else
            -- Try fallback path
            success, result = pcall(love.graphics.newImage, "images/32x32/fb1097.png")
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
    local alpha = 1 - (self.age / self.lifetime) * 0.3 -- Slight fade over time
    
    -- Tint/scale by kind so abilities don't look identical
    local r, g, b = 1, 1, 1
    local scale = 1
    if self.kind == "power_shot" then
        r, g, b = 1, 0.9, 0.25
        scale = 1.25
    end
    love.graphics.setColor(r, g, b, alpha)
    
    -- Draw the arrow sprite rotated to face direction
    local img = Arrow.image
    local imgW = img:getWidth()
    local imgH = img:getHeight()
    
    love.graphics.draw(
        img,
        self.x,
        self.y,
        self.angle + math.pi/4, -- Adjust rotation (sprite is diagonal)
        scale, scale, -- scale
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



