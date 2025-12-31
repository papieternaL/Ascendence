-- Small Treent Enemy - Bark Thrower (MCM)
-- Teaches projectile dodging for boss Bark Barrage
local SmallTreent = {}
SmallTreent.__index = SmallTreent

SmallTreent.image = nil

function SmallTreent:new(x, y)
    -- Load sprite (pixel-clean style)
    if not SmallTreent.image then
        local success, result = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
        if success then
            SmallTreent.image = result
            SmallTreent.image:setFilter("nearest", "nearest")
        end
    end
    
    local treent = {
        x = x or 0,
        y = y or 0,
        size = 20, -- Larger collision than regular enemy
        speed = 35, -- Slow movement
        maxHealth = 80, -- Tankier than regular enemies
        health = 80,
        isAlive = true,
        isMCM = true, -- Mechanic-Carrying Minion
        damage = 12,
        
        -- Bark throw behavior
        shootCooldown = 0,
        shootInterval = 2.5, -- Shoots every 2.5 seconds
        shootRange = 320, -- Range to start shooting
        
        -- Visual feedback
        flashTime = 0,
        flashDuration = 0.1,
        knockbackX = 0,
        knockbackY = 0,
        knockbackDecay = 8,
    }
    setmetatable(treent, SmallTreent)
    return treent
end

function SmallTreent:update(dt, playerX, playerY, onShoot)
    if not self.isAlive then return end
    
    -- Update flash effect
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- Update knockback
    self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
    self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)
    
    -- Calculate distance to player
    local dx = playerX - self.x
    local dy = playerY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Behavior: stay at range and shoot
    if distance > self.shootRange + 40 then
        -- Move closer if too far
        local normDx = dx / distance
        local normDy = dy / distance
        self.x = self.x + normDx * self.speed * dt + self.knockbackX * dt
        self.y = self.y + normDy * self.speed * dt + self.knockbackY * dt
    elseif distance < self.shootRange - 40 then
        -- Back away if too close
        local normDx = dx / distance
        local normDy = dy / distance
        self.x = self.x - normDx * self.speed * dt + self.knockbackX * dt
        self.y = self.y - normDy * self.speed * dt + self.knockbackY * dt
    else
        -- In range: stand still and shoot
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
    end
    
    -- Shooting logic
    self.shootCooldown = self.shootCooldown - dt
    if self.shootCooldown <= 0 and distance < self.shootRange then
        self.shootCooldown = self.shootInterval
        -- Notify game scene to spawn a bark projectile
        if onShoot then
            onShoot(self.x, self.y, playerX, playerY)
        end
    end
end

function SmallTreent:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    self.health = self.health - damage
    self.flashTime = self.flashDuration
    
    -- Knockback
    if hitX and hitY then
        local dx = self.x - hitX
        local dy = self.y - hitY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance > 0 then
            local force = knockbackForce or 100
            self.knockbackX = (dx / distance) * force
            self.knockbackY = (dy / distance) * force
        end
    end
    
    if self.health <= 0 then
        self.isAlive = false
        return true -- Enemy died
    end
    
    return false
end

function SmallTreent:draw()
    if not self.isAlive then return end
    
    -- MCM glow (subtle green to indicate importance)
    love.graphics.setColor(0.3, 1, 0.3, 0.15)
    love.graphics.circle("fill", self.x, self.y, self.size + 8)
    
    -- Draw sprite
    local img = SmallTreent.image
    if img then
        local scale = 2.2
        local imgW = img:getWidth()
        local imgH = img:getHeight()
        
        -- Flash effect or normal color
        if self.flashTime > 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            -- Green tint for tree theme
            love.graphics.setColor(0.5, 0.9, 0.4, 1)
        end
        
        love.graphics.draw(
            img,
            self.x,
            self.y,
            0,
            scale, scale,
            imgW / 2, imgH / 2
        )
    else
        -- Fallback: green square
        if self.flashTime > 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.4, 0.7, 0.3, 1)
        end
        love.graphics.rectangle("fill", self.x - self.size, self.y - self.size, self.size * 2, self.size * 2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function SmallTreent:getPosition()
    return self.x, self.y
end

function SmallTreent:getSize()
    return self.size
end

function SmallTreent:isDead()
    return not self.isAlive
end

function SmallTreent:applyRoot(duration, damageMultiplier)
    -- Small Treent is immune to roots (it's a tree!)
end

return SmallTreent

