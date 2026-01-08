-- Game Scene (Vampire Survivor style - Archer Class)
local Scene = require("scenes.scene")
local Player = require("entities.player")
local Tree = require("entities.tree")
local Enemy = require("entities.enemy")
local Lunger = require("entities.lunger")
local Arrow = require("entities.arrow")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")

local EmptyScene = {}
EmptyScene.__index = EmptyScene
setmetatable(EmptyScene, Scene)

function EmptyScene:new()
    local scene = Scene:new()
    setmetatable(scene, EmptyScene)
    return scene
end

function EmptyScene:load()
    -- Initialize player at center of screen
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.player = Player:new(screenWidth / 2, screenHeight / 2)
    
    -- Initialize systems
    self.particles = Particles:new()
    self.screenShake = ScreenShake:new()
    
    -- Initialize projectiles (arrows instead of fireballs)
    self.arrows = {}
    self.fireCooldown = 0
    self.fireRate = 0.4 -- faster fire rate for archer
    self.attackRange = 350 -- slightly longer range for archer
    
    -- Initialize trees
    self.trees = {}
    local numTrees = 15
    for i = 1, numTrees do
        local x = math.random(50, screenWidth - 50)
        local y = math.random(50, screenHeight - 50)
        -- Make sure trees aren't too close to player start
        local distToPlayer = math.sqrt((x - screenWidth/2)^2 + (y - screenHeight/2)^2)
        if distToPlayer > 100 then
            table.insert(self.trees, Tree:new(x, y))
        end
    end
    
    -- Initialize enemies
    self.enemies = {}
    local numEnemies = 3
    for i = 1, numEnemies do
        local angle = math.random() * math.pi * 2
        local distance = math.random(200, 400)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance
        table.insert(self.enemies, Enemy:new(x, y))
    end
    
    -- Initialize lungers
    self.lungers = {}
    local numLungers = 2
    for i = 1, numLungers do
        local angle = math.random() * math.pi * 2
        local distance = math.random(300, 500)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance
        table.insert(self.lungers, Lunger:new(x, y))
    end
end

function EmptyScene:update(dt)
    -- Update systems
    self.particles:update(dt)
    self.screenShake:update(dt)
    
    -- Update fire cooldown
    self.fireCooldown = math.max(0, self.fireCooldown - dt)
    
    -- Update player
    if self.player then
        self.player:update(dt)
        
        local playerX, playerY = self.player:getPosition()
        
        -- Find nearest enemy for aiming
        local nearestEnemy = nil
        local nearestDistance = self.attackRange
        
        -- Check regular enemies
        for i, enemy in ipairs(self.enemies) do
            if enemy.isAlive then
                local ex, ey = enemy:getPosition()
                local dx = ex - playerX
                local dy = ey - playerY
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < nearestDistance then
                    nearestEnemy = enemy
                    nearestDistance = distance
                end
            end
        end
        
        -- Check lungers
        for i, lunger in ipairs(self.lungers) do
            if lunger.isAlive then
                local lx, ly = lunger:getPosition()
                local dx = lx - playerX
                local dy = ly - playerY
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < nearestDistance then
                    nearestEnemy = lunger
                    nearestDistance = distance
                end
            end
        end
        
        -- Aim bow at nearest enemy
        if nearestEnemy then
            local ex, ey = nearestEnemy:getPosition()
            self.player:aimAt(ex, ey)
            
            -- Auto-fire at nearest enemy in range
            if self.fireCooldown <= 0 then
                table.insert(self.arrows, Arrow:new(playerX, playerY, ex, ey))
                self.fireCooldown = self.fireRate
            end
        end
        
        -- Update arrows
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            arrow:update(dt)
            
            -- Check collision with enemies
            local ax, ay = arrow:getPosition()
            local hitEnemy = false
            
            -- Check regular enemies
            for j, enemy in ipairs(self.enemies) do
                if enemy.isAlive then
                    local ex, ey = enemy:getPosition()
                    local dx = ax - ex
                    local dy = ay - ey
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < enemy:getSize() + arrow:getSize() then
                        -- Hit enemy
                        local died = enemy:takeDamage(arrow.damage, ax, ay)
                        
                        if died then
                            -- Create explosion
                            self.particles:createExplosion(ex, ey, {1, 0.3, 0.1})
                            self.screenShake:add(5, 0.2)
                        else
                            -- Screen shake on hit
                            self.screenShake:add(2, 0.1)
                        end
                        
                        hitEnemy = true
                        break
                    end
                end
            end
            
            -- Check lungers
            if not hitEnemy then
                for j, lunger in ipairs(self.lungers) do
                    if lunger.isAlive then
                        local lx, ly = lunger:getPosition()
                        local dx = ax - lx
                        local dy = ay - ly
                        local distance = math.sqrt(dx * dx + dy * dy)
                        
                        if distance < lunger:getSize() + arrow:getSize() then
                            -- Hit lunger
                            local died = lunger:takeDamage(arrow.damage, ax, ay)
                            
                            if died then
                                -- Create purple explosion for lunger
                                self.particles:createExplosion(lx, ly, {0.8, 0.3, 0.8})
                                self.screenShake:add(6, 0.25)
                            else
                                -- Screen shake on hit
                                self.screenShake:add(2, 0.1)
                            end
                            
                            hitEnemy = true
                            break
                        end
                    end
                end
            end
            
            -- Remove arrow if it hit or expired
            if hitEnemy or arrow:isExpired() then
                table.remove(self.arrows, i)
            end
        end
        
        -- Update enemies (they move towards player)
        for i = #self.enemies, 1, -1 do
            local enemy = self.enemies[i]
            if enemy.isAlive then
                enemy:update(dt, playerX, playerY)
                
                -- Check collision with player
                local ex, ey = enemy:getPosition()
                local dx = playerX - ex
                local dy = playerY - ey
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < self.player:getSize() + enemy:getSize() then
                    -- Player takes damage
                    local died = self.player:takeDamage(10)
                    if not self.player:isInvincible() then
                        self.screenShake:add(4, 0.15)
                    end
                end
            end
        end
        
        -- Update lungers
        for i = #self.lungers, 1, -1 do
            local lunger = self.lungers[i]
            if lunger.isAlive then
                lunger:update(dt, playerX, playerY)
                
                -- Check collision with player (especially during lunge)
                local lx, ly = lunger:getPosition()
                local dx = playerX - lx
                local dy = playerY - ly
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < self.player:getSize() + lunger:getSize() then
                    -- Player takes damage (more if lunging)
                    local damage = lunger:getDamage()
                    if lunger:isLunging() then
                        damage = damage * 1.5 -- Extra damage during lunge
                    end
                    local died = self.player:takeDamage(damage)
                    if not self.player:isInvincible() then
                        self.screenShake:add(6, 0.2)
                    end
                end
            end
        end
    end
end

function EmptyScene:draw()
    -- Apply screen shake
    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.15, 1) -- Dark blue-gray background
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw trees
    for i, tree in ipairs(self.trees) do
        tree:draw()
    end
    
    -- Draw enemies
    for i, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    -- Draw lungers
    for i, lunger in ipairs(self.lungers) do
        lunger:draw()
    end
    
    -- Draw arrows
    for i, arrow in ipairs(self.arrows) do
        arrow:draw()
    end
    
    -- Draw player (on top)
    if self.player then
        self.player:draw()
    end
    
    -- Draw particles (on top of everything)
    self.particles:draw()
    
    love.graphics.pop()
    
    -- Draw UI (not affected by screen shake)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Archer Class", 10, 10)
    love.graphics.print("HP: " .. self.player.health .. "/" .. self.player.maxHealth, 10, 30)
end

function EmptyScene:keypressed(key)
    -- Handle key presses
end

function EmptyScene:mousepressed(x, y, button)
    -- Handle mouse presses
end

return EmptyScene
