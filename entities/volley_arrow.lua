-- entities/volley_arrow.lua
-- Volley of Wrath arrow that falls from above in a circular AOE

local VolleyArrow = {}
VolleyArrow.__index = VolleyArrow

VolleyArrow.image = nil

function VolleyArrow:new(x, y, targetX, targetY, damage)
    -- Load image if not loaded
    if not VolleyArrow.image then
        local success, result = pcall(love.graphics.newImage, "assets/32x32/fb1100.png")
        if success then
            VolleyArrow.image = result
            VolleyArrow.image:setFilter("nearest", "nearest")
        else
            success, result = pcall(love.graphics.newImage, "images/32x32/fb1100.png")
            if success then
                VolleyArrow.image = result
                VolleyArrow.image:setFilter("nearest", "nearest")
            end
        end
    end
    
    local arrow = {
        startX = x,
        startY = y - 300, -- Start 300 pixels above
        x = x,
        y = y - 300,
        targetX = targetX,
        targetY = targetY,
        damage = damage or 20,
        speed = 600, -- Fall speed
        size = 8,
        hit = {},
        lifetime = 2.0,
        age = 0,
        hasLanded = false,
        impactRadius = 35,
        angle = math.pi / 2, -- Point downward
    }
    
    setmetatable(arrow, VolleyArrow)
    return arrow
end

function VolleyArrow:update(dt)
    self.age = self.age + dt
    
    if not self.hasLanded then
        -- Fall toward target
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 10 or self.y >= self.targetY then
            -- Land!
            self.hasLanded = true
            self.x = self.targetX
            self.y = self.targetY
            return true -- Signal impact
        else
            -- Continue falling
            self.x = self.x + (dx / dist) * self.speed * dt
            self.y = self.y + (dy / dist) * self.speed * dt
        end
    end
    
    -- Remove after lifetime
    return self.age > self.lifetime
end

function VolleyArrow:canHit(target)
    return not self.hit[target]
end

function VolleyArrow:markHit(target)
    self.hit[target] = true
end

function VolleyArrow:getPosition()
    return self.x, self.y
end

function VolleyArrow:draw()
    if not self.hasLanded then
        -- Draw falling arrow with shadow indicator
        local alpha = 1.0
        
        -- Shadow on ground
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.circle("fill", self.targetX, self.targetY, 12)
        love.graphics.setColor(1, 0.3, 0.3, 0.3)
        love.graphics.circle("line", self.targetX, self.targetY, self.impactRadius)
        
        -- Falling arrow
        love.graphics.setColor(1, 1, 1, alpha)
        if VolleyArrow.image then
            love.graphics.draw(
                VolleyArrow.image,
                self.x,
                self.y,
                self.angle,
                1.2, -- Scale
                1.2,
                VolleyArrow.image:getWidth() / 2,
                VolleyArrow.image:getHeight() / 2
            )
        else
            -- Fallback: draw a simple arrow
            love.graphics.push()
            love.graphics.translate(self.x, self.y)
            love.graphics.rotate(self.angle)
            love.graphics.setColor(1, 0.8, 0.2, alpha) -- Golden volley
            love.graphics.polygon("fill", 0, -10, -4, 4, 4, 4)
            love.graphics.pop()
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return VolleyArrow

