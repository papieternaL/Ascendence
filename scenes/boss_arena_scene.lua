-- Boss Arena Scene
-- Sealed combat arena for Treent Overlord encounter

local TreentOverlord = require("entities.treent_overlord")
local Root = require("entities.root")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")

local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local DamageNumbers = require("systems.damage_numbers")

local BossArenaScene = {}
BossArenaScene.__index = BossArenaScene

function BossArenaScene:new(player, playerStats, gameState, xpSystem, rarityCharge)
    local scene = {
        player = player,
        playerStats = playerStats,
        gameState = gameState,
        xpSystem = xpSystem,
        rarityCharge = rarityCharge,
        
        -- Boss
        boss = nil,
        
        -- Projectiles
        arrows = {},
        barkProjectiles = {},
        
        -- Phase 2 mechanics
        roots = {}, -- Root entities player must destroy
        safeZones = {}, -- Safe zones for earthquake
        earthquakeActive = false,
        earthquakeDamageTimer = 0,
        
        -- Systems
        particles = Particles:new(),
        screenShake = ScreenShake:new(),
        damageNumbers = DamageNumbers:new(),
        
        -- Combat state
        fireCooldown = 0,
        fireRate = 0.4,
        attackRange = 400,
        isPaused = false,
        
        -- Dash
        isDashing = false,
        dashTime = 0,
        dashDuration = 0.2,
        dashSpeed = 800,
        dashCooldown = 0,
        dashCooldownMax = 1.0,
        dashDirX = 0,
        dashDirY = 0,
        
        -- Frenzy
        frenzyActive = false,
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        
        -- Victory/Defeat
        victoryTimer = 0,
        defeatTimer = 0,
    }
    
    setmetatable(scene, BossArenaScene)
    scene:initialize()
    return scene
end

function BossArenaScene:initialize()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Spawn boss in center
    self.boss = TreentOverlord:new(screenWidth / 2, screenHeight / 2)
    
    -- Position player at bottom
    if self.player then
        self.player.x = screenWidth / 2
        self.player.y = screenHeight - 100
    end
    
    -- Wire player abilities
    if self.player then
        self.player.abilities = self.player.abilities or {}
        self.player.abilities.frenzy = { cooldown = 0, cooldownMax = 1 }
        self.player.abilities.power_shot = { cooldown = 0, cooldownMax = 6 }
        self.player.abilities.entangle = { cooldown = 0, cooldownMax = 8 }
    end
end

function BossArenaScene:update(dt)
    if self.isPaused then return end
    
    -- Update systems
    self.particles:update(dt)
    self.screenShake:update(dt)
    if self.damageNumbers then
        self.damageNumbers:update(dt)
    end
    
    -- Update player stats
    if self.playerStats then
        self.frenzyActive = self.playerStats:hasBuff("frenzy")
        self.playerStats:update(dt, {
            wasHit = false,
            didRoll = self.isDashing,
            inFrenzy = self.frenzyActive,
        })
    end
    
    -- Update cooldowns
    self.fireCooldown = math.max(0, self.fireCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    
    -- Update player
    if self.player then
        if self.isDashing then
            self.dashTime = self.dashTime - dt
            if self.dashTime <= 0 then
                self.isDashing = false
            else
                -- Apply dash movement
                local moveX = self.dashDirX * self.dashSpeed * dt
                local moveY = self.dashDirY * self.dashSpeed * dt
                print(string.format("Dash moving: dx=%.2f, dy=%.2f (dir: %.2f, %.2f)", moveX, moveY, self.dashDirX, self.dashDirY))
                self.player.x = self.player.x + moveX
                self.player.y = self.player.y + moveY
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            self.player:update(dt)
        end
        
        local playerX, playerY = self.player:getPosition()
        
        -- Find best target (prioritize roots in Phase 2)
        local targetX, targetY = nil, nil
        local bestTarget = nil
        
        -- Phase 2: Prioritize roots heavily
        if self.boss and self.boss.phase == 2 and #self.roots > 0 then
            local nearestRootDist = 999999
            for _, root in ipairs(self.roots) do
                if root.isAlive then
                    local rx, ry = root:getPosition()
                    local dx = rx - playerX
                    local dy = ry - playerY
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < nearestRootDist then
                        nearestRootDist = dist
                        targetX = rx
                        targetY = ry
                        bestTarget = root
                    end
                end
            end
        end
        
        -- Fallback to boss if no roots
        if not targetX and self.boss and self.boss.isAlive then
            targetX, targetY = self.boss:getPosition()
            bestTarget = self.boss
        end
        
        -- Aim at target
        if targetX and targetY then
            self.player:aimAt(targetX, targetY)
            
            -- Auto-fire primary
            if self.fireCooldown <= 0 and not self.isDashing then
                local baseDmg = (self.player.attackDamage or 10) * 1.0
                local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
                local arrow = Arrow:new(sx, sy, targetX, targetY, { damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140 })
                table.insert(self.arrows, arrow)
                self.fireCooldown = self.fireRate
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
            end
        end
        
        -- Auto-cast Power Shot (also prioritizes roots in Phase 2)
        if self.player and self.player:isAbilityReady("power_shot") and not self.isDashing then
            local psTargetX, psTargetY = nil, nil
            
            -- Phase 2: Prioritize roots
            if self.boss and self.boss.phase == 2 and #self.roots > 0 then
                local nearestRootDist = 999999
                for _, root in ipairs(self.roots) do
                    if root.isAlive then
                        local rx, ry = root:getPosition()
                        local dx = rx - playerX
                        local dy = ry - playerY
                        local dist = math.sqrt(dx*dx + dy*dy)
                        if dist < nearestRootDist then
                            nearestRootDist = dist
                            psTargetX = rx
                            psTargetY = ry
                        end
                    end
                end
            end
            
            -- Fallback to boss
            if not psTargetX and self.boss and self.boss.isAlive then
                psTargetX, psTargetY = self.boss:getPosition()
            end
            
            if psTargetX and psTargetY then
                self.player:aimAt(psTargetX, psTargetY)
                self.player:useAbility("power_shot")
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
                local base = (self.player.attackDamage or 10) * 3.0
                local ps = Arrow:new(sx, sy, psTargetX, psTargetY, {
                    damage = base,
                    speed = 760,
                    size = 12,
                    lifetime = 1.8,
                    pierce = 999,
                    alwaysCrit = true,
                    kind = "power_shot",
                    knockback = 260,
                })
                table.insert(self.arrows, ps)
                self.screenShake:add(3, 0.12)
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
            end
        end
        
        -- Auto-cast Entangle (prioritizes roots in Phase 2)
        if self.player and self.player:isAbilityReady("entangle") then
            local px, py = playerX, playerY
            local entangleRange = 260
            local best, bestDist = nil, entangleRange
            local function considerTarget(t, bonus)
                local ex, ey = t:getPosition()
                local dx = ex - px
                local dy = ey - py
                local d = math.sqrt(dx*dx + dy*dy) - (bonus or 0)
                if d < bestDist then
                    best = t
                    bestDist = d
                end
            end
            
            -- Prioritize roots (Phase 2)
            for _, root in ipairs(self.roots) do
                if root.isAlive then considerTarget(root, 50) end -- Big priority bonus
            end
            
            -- Fallback: boss
            if self.boss and self.boss.isAlive then
                considerTarget(self.boss, 0)
            end
            
            if best and best.applyRoot then
                self.player:useAbility("entangle")
                local dur = 1.5
                best:applyRoot(dur, 1.15)
                local tx, ty = best:getPosition()
                self.particles:createExplosion(tx, ty, {0.2, 1, 0.3})
                self.screenShake:add(2, 0.1)
            end
        end
        
        -- Update boss
        if self.boss and self.boss.isAlive then
            local onBarkShoot = function(sx, sy, tx, ty)
                local bark = BarkProjectile:new(sx, sy, tx, ty)
                bark.damage = 25 -- Boss bark does more damage
                table.insert(self.barkProjectiles, bark)
            end
            
            local onPhaseTransition = function()
                self.screenShake:add(12, 0.5)
                self.particles:createExplosion(self.boss.x, self.boss.y, {1, 0.3, 0.3})
            end
            
            local onEncompassRoot = function(px, py)
                -- Root the player
                if self.player and self.player.applyRoot then
                    self.player:applyRoot(self.boss.encompassRootDuration)
                end
                
                -- Spawn root entities around the arena
                self.roots = {}
                local screenWidth = love.graphics.getWidth()
                local screenHeight = love.graphics.getHeight()
                for i = 1, 6 do
                    local angle = (i / 6) * math.pi * 2
                    local distance = 200
                    local rx = screenWidth / 2 + math.cos(angle) * distance
                    local ry = screenHeight / 2 + math.sin(angle) * distance
                    table.insert(self.roots, Root:new(rx, ry))
                end
                
                self.screenShake:add(8, 0.3)
            end
            
            local onEarthquake = function(phase)
                if phase == "start" then
                    self.earthquakeActive = true
                    self.earthquakeDamageTimer = 0
                    -- Spawn 3 safe zones
                    self.safeZones = {}
                    local screenWidth = love.graphics.getWidth()
                    local screenHeight = love.graphics.getHeight()
                    for i = 1, 3 do
                        local angle = (i / 3) * math.pi * 2
                        local distance = 180
                        local sx = screenWidth / 2 + math.cos(angle) * distance
                        local sy = screenHeight / 2 + math.sin(angle) * distance
                        table.insert(self.safeZones, { x = sx, y = sy, radius = 60 })
                    end
                    self.screenShake:add(15, 0.6)
                elseif phase == "end" then
                    self.earthquakeActive = false
                    self.safeZones = {}
                end
            end
            
            self.boss:update(dt, playerX, playerY, onBarkShoot, onPhaseTransition, onEncompassRoot, onEarthquake)
            
            -- Boss collision with player
            if not self.isDashing then
                local bx, by = self.boss:getPosition()
                local dx = playerX - bx
                local dy = playerY - by
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < self.player:getSize() + self.boss:getSize() then
                    local damage = self.boss.damage
                    if self.frenzyActive then damage = damage * 1.15 end
                    local before = self.player.health
                    self.player:takeDamage(damage)
                    local wasHit = self.player.health < before
                    if wasHit and self.playerStats then
                        self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                    end
                    if not self.player:isInvincible() then
                        self.screenShake:add(8, 0.25)
                    end
                end
            end
        end
        
        -- Update roots (Phase 2)
        for _, root in ipairs(self.roots) do
            if root.isAlive then
                root:update(dt)
            end
        end
        
        -- Update bark projectiles
        for i = #self.barkProjectiles, 1, -1 do
            local bark = self.barkProjectiles[i]
            bark:update(dt)
            
            if bark:isExpired() then
                table.remove(self.barkProjectiles, i)
            else
                local bx, by = bark:getPosition()
                local dx = playerX - bx
                local dy = playerY - by
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < self.player:getSize() + bark:getSize() and not self.isDashing then
                    local barkDmg = bark.damage
                    if self.frenzyActive then barkDmg = barkDmg * 1.15 end
                    self.player:takeDamage(barkDmg)
                    if not self.player:isInvincible() then
                        self.screenShake:add(3, 0.12)
                    end
                    table.remove(self.barkProjectiles, i)
                end
            end
        end
        
        -- Earthquake damage (tick every 0.5s if not in safe zone)
        if self.earthquakeActive then
            self.earthquakeDamageTimer = self.earthquakeDamageTimer + dt
            if self.earthquakeDamageTimer >= 0.5 then
                self.earthquakeDamageTimer = 0
                -- Check if player is in a safe zone
                local inSafeZone = false
                for _, zone in ipairs(self.safeZones) do
                    local dx = playerX - zone.x
                    local dy = playerY - zone.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < zone.radius then
                        inSafeZone = true
                        break
                    end
                end
                
                if not inSafeZone then
                    -- Deal earthquake damage
                    local eqDmg = 30
                    if self.frenzyActive then eqDmg = eqDmg * 1.15 end
                    self.player:takeDamage(eqDmg)
                    self.screenShake:add(6, 0.2)
                    self.particles:createExplosion(playerX, playerY, {0.6, 0.3, 0})
                end
            end
        end
        
        -- Update arrows
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            arrow:update(dt)
            
            if arrow:isExpired() then
                table.remove(self.arrows, i)
            else
                local ax, ay = arrow:getPosition()
                local hitEnemy = false
                
                -- Crit roll helper
                local function rollDamage(baseDmg, forceCrit)
                    local isCrit = forceCrit or (math.random() < (self.playerStats and self.playerStats:get("crit_chance") or 0.15))
                    local dmg = baseDmg
                    if isCrit then
                        dmg = dmg * (self.playerStats and self.playerStats:get("crit_damage") or 2.0)
                    end
                    return dmg, isCrit
                end
                
                -- Check boss
                if not hitEnemy and self.boss and self.boss.isAlive then
                    local bx, by = self.boss:getPosition()
                    local dx = ax - bx
                    local dy = ay - by
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < self.boss:getSize() + arrow:getSize() and arrow:canHit(self.boss) then
                        arrow:markHit(self.boss)
                        local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                        self.particles:createHitSpark(bx, by, {1, 1, 0.6})
                        if self.damageNumbers then
                            self.damageNumbers:add(bx, by - self.boss:getSize(), dmg, { isCrit = isCrit })
                        end
                        local died = self.boss:takeDamage(dmg, ax, ay, arrow.knockback)
                        
                        if died then
                            self.particles:createExplosion(bx, by, {0.2, 1, 0.2})
                            self.screenShake:add(15, 0.8)
                            self.victoryTimer = 3.0 -- Start victory countdown
                        else
                            self.screenShake:add(2, 0.08)
                        end
                        
                        if arrow:consumePierce() then
                            hitEnemy = false
                        else
                            hitEnemy = true
                        end
                    end
                end
                
                -- Check roots (Phase 2)
                if not hitEnemy then
                    for _, root in ipairs(self.roots) do
                        if root.isAlive then
                            local rx, ry = root:getPosition()
                            local dx = ax - rx
                            local dy = ay - ry
                            local distance = math.sqrt(dx * dx + dy * dy)
                            
                            if distance < root:getSize() + arrow:getSize() and arrow:canHit(root) then
                                arrow:markHit(root)
                                local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                                self.particles:createHitSpark(rx, ry, {1, 1, 0.6})
                                if self.damageNumbers then
                                    self.damageNumbers:add(rx, ry - root:getSize(), dmg, { isCrit = isCrit })
                                end
                                local died = root:takeDamage(dmg, ax, ay, arrow.knockback)
                                
                                if died then
                                    self.particles:createExplosion(rx, ry, {0.8, 0.4, 0})
                                    self.screenShake:add(4, 0.15)
                                else
                                    self.screenShake:add(1, 0.05)
                                end
                                
                                if arrow:consumePierce() then
                                    hitEnemy = false
                                else
                                    hitEnemy = true
                                end
                                if hitEnemy then break end
                            end
                        end
                    end
                end
                
                if hitEnemy then
                    table.remove(self.arrows, i)
                end
            end
        end
        
        -- Check victory
        if self.victoryTimer > 0 then
            self.victoryTimer = self.victoryTimer - dt
            if self.victoryTimer <= 0 then
                -- Victory!
                self.gameState:transitionTo(self.gameState.States.VICTORY)
            end
        end
        
        -- Check defeat
        if self.player and self.player:isDead() then
            self.defeatTimer = self.defeatTimer + dt
            if self.defeatTimer >= 2.0 then
                self.gameState:transitionTo(self.gameState.States.GAME_OVER)
            end
        end
    end
end

function BossArenaScene:draw()
    -- Background
    love.graphics.setColor(0.15, 0.1, 0.08, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Apply screen shake
    love.graphics.push()
    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw particles (background layer)
    self.particles:draw()
    
    -- Draw safe zones (if earthquake active)
    if self.earthquakeActive then
        -- Pulsing effect for visibility
        local pulse = 0.5 + math.sin(love.timer.getTime() * 6) * 0.3
        
        for _, zone in ipairs(self.safeZones) do
            -- Outer glow
            love.graphics.setColor(0.2, 1, 0.2, 0.2)
            love.graphics.circle("fill", zone.x, zone.y, zone.radius + 10)
            
            -- Main safe zone (bright green, pulsing)
            love.graphics.setColor(0.2, 1, 0.2, 0.4 + pulse * 0.3)
            love.graphics.circle("fill", zone.x, zone.y, zone.radius)
            
            -- Border (solid, very visible)
            love.graphics.setColor(0, 1, 0, 0.9)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", zone.x, zone.y, zone.radius)
        end
        love.graphics.setLineWidth(1)
    end
    
    -- Y-sort drawing
    local drawables = {}
    
    -- Add boss
    if self.boss and self.boss.isAlive then
        table.insert(drawables, { entity = self.boss, y = self.boss.y, type = "boss" })
    end
    
    -- Add roots
    for _, root in ipairs(self.roots) do
        if root.isAlive then
            table.insert(drawables, { entity = root, y = root.y, type = "root" })
        end
    end
    
    -- Add player
    if self.player then
        table.insert(drawables, { entity = self.player, y = self.player.y, type = "player", isDashing = self.isDashing })
    end
    
    -- Sort by Y
    table.sort(drawables, function(a, b) return a.y < b.y end)
    
    -- Draw sorted entities
    for _, drawable in ipairs(drawables) do
        if drawable.type == "player" then
            if drawable.isDashing then
                love.graphics.setColor(0.5, 0.5, 1, 0.6)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
        drawable.entity:draw()
    end
    
    -- Draw projectiles (always on top)
    for _, arrow in ipairs(self.arrows) do
        arrow:draw()
    end
    
    for _, bark in ipairs(self.barkProjectiles) do
        bark:draw()
    end
    
    -- Draw damage numbers
    if self.damageNumbers then
        self.damageNumbers:draw()
    end
    
    love.graphics.pop()
    
    -- UI (not affected by shake)
    self:drawUI()
end

function BossArenaScene:drawUI()
    if not self.player then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Player health
    local hpPercent = self.player.health / self.player.maxHealth
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 20, love.graphics.getHeight() - 40, 200, 20)
    
    if hpPercent > 0.5 then
        love.graphics.setColor(0, 1, 0, 1)
    elseif hpPercent > 0.25 then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 0, 0, 1)
    end
    love.graphics.rectangle("fill", 20, love.graphics.getHeight() - 40, 200 * hpPercent, 20)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("HP: %d / %d", math.floor(self.player.health), math.floor(self.player.maxHealth)), 25, love.graphics.getHeight() - 38)
    
    -- DEBUG: Show dash direction
    if self.isDashing and self.player then
        local lineLen = 100
        local endX = self.player.x + self.dashDirX * lineLen
        local endY = self.player.y + self.dashDirY * lineLen
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.line(self.player.x, self.player.y, endX, endY)
        love.graphics.setLineWidth(1)
        
        -- Show direction values
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print(string.format("Dash Dir: %.2f, %.2f", self.dashDirX, self.dashDirY), 20, 60)
    end
    
    -- Boss title
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.setNewFont(24)
    love.graphics.printf("TREENT OVERLORD", 0, 30, love.graphics.getWidth(), "center")
    love.graphics.setNewFont(12)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BossArenaScene:keypressed(key)
    -- Manual abilities
    if key == "r" and self.player and self.player:isAbilityReady("frenzy") and self.frenzyCharge >= self.frenzyChargeMax then
        self.player:useAbility("frenzy")
        self.frenzyCharge = self.frenzyCharge - self.frenzyChargeMax
        self.playerStats:addBuff("frenzy", 8.0, {
            { stat = "move_speed", mul = 1.25 },
            { stat = "crit_chance", add = 0.25 },
        }, { break_on_hit_taken = true, damage_taken_multiplier = 1.15 })
        self.frenzyActive = true
        self.screenShake:add(4, 0.15)
        return true
    end
    
    if key == "space" then
        self:startDash()
        return true
    end
    
    return false
end

function BossArenaScene:startDash()
    -- Can't dash while rooted!
    if self.player and self.player.isRooted then
        print("Cannot dash: player is rooted!")
        return
    end
    
    if self.dashCooldown <= 0 and not self.isDashing and self.player then
        local mouseX, mouseY = love.mouse.getPosition()
        local dx = mouseX - self.player.x
        local dy = mouseY - self.player.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        print("=== DASH DEBUG ===")
        print("Player pos:", self.player.x, self.player.y)
        print("Mouse pos:", mouseX, mouseY)
        print("Delta:", dx, dy)
        print("Distance:", distance)
        
        if distance > 0 then
            self.dashDirX = dx / distance
            self.dashDirY = dy / distance
            print("Dash direction:", self.dashDirX, self.dashDirY)
            self.isDashing = true
            self.dashTime = self.dashDuration
            self.dashCooldown = self.dashCooldownMax
            
            if self.player.startDash then
                self.player:startDash()
            end
        end
    end
end

return BossArenaScene

