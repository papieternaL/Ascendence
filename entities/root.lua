-- Root entity
-- Spawned during Treent Overlord Phase 2 "Encompass Root" mechanic
-- Player must destroy these to escape being rooted

local Root = {}
Root.__index = Root
Root.image = nil

function Root:new(x, y)
    -- Load sprite (reuse small treent sprite with brown tint)
    if not Root.image then
        local success, img = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
        if success then
            Root.image = img
        end
    end

    local root = {
        x = x or 0,
        y = y or 0,
        size = 16,
        maxHealth = 150,
        health = 150,
        isAlive = true,
        isRoot = true, -- Flag for auto-targeting priority
        
        -- Visual
        flashTime = 0,
        pulseTimer = 0, -- For pulsing animation
    }
    
    setmetatable(root, Root)
    return root
end

function Root:update(dt)
    if not self.isAlive then return end
    
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    self.pulseTimer = self.pulseTimer + dt
end

function Root:draw()
    if not self.isAlive then return end
    
    -- Pulsing brown root
    local pulse = 0.8 + math.sin(self.pulseTimer * 4) * 0.2
    
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.6 * pulse, 0.3 * pulse, 0.1 * pulse, 1)
    end
    
    if Root.image then
        local scale = self.size / 16
        love.graphics.draw(Root.image, self.x, self.y, 0, scale, scale, 8, 8)
    else
        love.graphics.circle("fill", self.x, self.y, self.size)
    end
    
    -- Health bar
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.x - 15, self.y - self.size - 10, 30, 4)
    
    local healthPercent = self.health / self.maxHealth
    love.graphics.setColor(0.8, 0.4, 0, 1)
    love.graphics.rectangle("fill", self.x - 15, self.y - self.size - 10, 30 * healthPercent, 4)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Root:takeDamage(damage, hitX, hitY, knockbackForce)
    if not self.isAlive then return false end
    
    self.health = self.health - damage
    self.flashTime = 0.08
    
    if self.health <= 0 then
        self.isAlive = false
        return true
    end
    return false
end

function Root:getPosition()
    return self.x, self.y
end

function Root:getSize()
    return self.size
end

function Root:isDead()
    return not self.isAlive
end

return Root

