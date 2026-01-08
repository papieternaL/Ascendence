-- Boss Arena Scene
-- Sealed combat arena for Treent Overlord encounter
-- Phase 2: Typing Test Mechanic (replaces root entities)

local TreentOverlord = require("entities.treent_overlord")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")
local Config = require("data.config")
local UIUtils = require("ui.ui_utils")

local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local DamageNumbers = require("systems.damage_numbers")
local JuiceManager = require("systems.juice_manager")
local VineLane = require("entities.vine_lane")

local BossArenaScene = {}
BossArenaScene.__index = BossArenaScene

function BossArenaScene:new(player, playerStats, gameState, xpSystem, rarityCharge)
    local pCfg = Config.Player
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
        vineLanes = {},           -- Vine lane entities
        vineLanesActive = false,
        vineDamageTimer = 0,
        safeLaneIndex = nil,      -- Which lane (1-5) is safe
        dangerLinesBlink = 0,     -- Timer for blinking effect
        dangerLinesVisible = true, -- Toggle for blink
        
        -- Typing test (Phase 2 mechanic)
        typingTestActive = false,
        typingSequence = {},  -- 6 random letters to type
        typingProgress = 0,   -- How many letters typed correctly
        typingStartTime = 0,
        
        -- Systems
        particles = Particles:new(),
        screenShake = ScreenShake:new(),
        damageNumbers = DamageNumbers:new(),
        
        -- Combat state
        fireCooldown = 0,
        fireRate = pCfg.fireRate,
        attackRange = pCfg.attackRange,
        isPaused = false,
        
        -- Dash
        isDashing = false,
        dashTime = 0,
        dashDuration = pCfg.dashDuration,
        dashSpeed = pCfg.dashSpeed,
        dashCooldown = 0,
        dashCooldownMax = pCfg.dashCooldown,
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
    
    -- Set JuiceManager screen shake reference
    JuiceManager.setScreenShake(scene.screenShake)
    
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
        local aCfg = Config.Abilities
        
        -- Ensure frenzy exists with defaults if not present
        if not self.player.abilities.frenzy then
            self.player.abilities.frenzy = { name = "Frenzy", key = "R", icon = "🔥", unlocked = true }
        end
        self.player.abilities.frenzy.currentCooldown = 0
        self.player.abilities.frenzy.cooldown = 15.0 -- Ultimate CD
        
        -- Ensure power_shot exists
        if not self.player.abilities.power_shot then
            self.player.abilities.power_shot = { name = "Power Shot", key = "Q", icon = "⚡", unlocked = true }
        end
        self.player.abilities.power_shot.currentCooldown = 0
        self.player.abilities.power_shot.cooldown = aCfg.powerShot.cooldown
        
        -- Ensure arrow_volley exists
        if not self.player.abilities.arrow_volley then
            self.player.abilities.arrow_volley = { name = "Arrow Volley", key = "E", icon = "🏹", unlocked = true }
        end
        self.player.abilities.arrow_volley.currentCooldown = 0
        self.player.abilities.arrow_volley.cooldown = 8.0
        
        -- Ensure dash exists
        if not self.player.abilities.dash then
            self.player.abilities.dash = { name = "Dash", key = "SPACE", icon = "💨", unlocked = true }
        end
        self.player.abilities.dash.currentCooldown = 0
        self.player.abilities.dash.cooldown = Config.Player.dashCooldown
    end
end

function BossArenaScene:generateTypingSequence()
    local letters = {"q","w","e","r","a","s","d","f","t","g"}
    local sequence = {}
    for i = 1, 6 do
        sequence[i] = letters[math.random(#letters)]
    end
    return sequence
end

function BossArenaScene:update(dt)
    if self.isPaused then return end
    
    -- Hit-stop freeze (JuiceManager) - skip game logic but still update visuals
    if JuiceManager.isFrozen() then
        self.particles:update(dt)
        return
    end
    
    -- Update systems
    self.particles:update(dt)
    self.screenShake:update(dt)
    if self.damageNumbers then
        self.damageNumbers:update(dt)
    end
    
    -- Update player stats
    if self.playerStats then
        self.frenzyActive = self.playerStats:hasBuff("frenzy")
        
        -- Sync frenzy VFX to player
        if self.player then
            self.player.isFrenzyActive = self.frenzyActive
        end
        
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
                self.player.x = self.player.x + moveX
                self.player.y = self.player.y + moveY
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            self.player:update(dt)
        end
        
        local playerX, playerY = self.player:getPosition()
        
        -- Find target (boss only - no root entities)
        local targetX, targetY = nil, nil
        
        -- Target the boss
        if self.boss and self.boss.isAlive then
            targetX, targetY = self.boss:getPosition()
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
                if self.player.playAttackAnimation then self.player:playAttackAnimation() end
            end
        end
        
        -- Auto-cast Power Shot
    if self.player and self.player:isAbilityReady("power_shot") and not self.isDashing then
        local psTargetX, psTargetY = nil, nil
        local psCfg = Config.Abilities.powerShot
        
        -- Target the boss
        if self.boss and self.boss.isAlive then
            psTargetX, psTargetY = self.boss:getPosition()
        end
        
        if psTargetX and psTargetY then
            self.player:aimAt(psTargetX, psTargetY)
            self.player:useAbility("power_shot")
            local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
            local base = (self.player.attackDamage or 10) * psCfg.damageMult
            local ps = Arrow:new(sx, sy, psTargetX, psTargetY, {
                damage = base,
                speed = psCfg.speed,
                size = 12,
                lifetime = 1.8,
                pierce = 999,
                alwaysCrit = true,
                kind = "power_shot",
                knockback = psCfg.knockback,
            })
                table.insert(self.arrows, ps)
                self.screenShake:add(3, 0.12)
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
                if self.player.playAttackAnimation then self.player:playAttackAnimation() end
            end
        end
        
        -- Auto-cast Arrow Volley (targets boss)
        if self.player and self.player:isAbilityReady("arrow_volley") then
            local volleyRange = 300
            
            -- Target boss
            if self.boss and self.boss.isAlive then
                local bx, by = self.boss:getPosition()
                local px, py = playerX, playerY
                local dx = bx - px
                local dy = by - py
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist <= volleyRange then
                    self.player:useAbility("arrow_volley")
                    -- Deal damage to boss (Arrow Volley is damage, not root)
                    local baseDmg = self.playerStats and self.playerStats:get("attack") or 25
                    local damage = baseDmg * 1.5
                    self.boss:takeDamage(damage)
                    self.particles:createExplosion(bx, by, {1, 0.8, 0.2})
                    self.screenShake:add(3, 0.15)
                end
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
                    self.player:applyRoot(999) -- Long duration, unlocked by typing
                end
                
                -- Start typing test
                self.typingTestActive = true
                self.typingSequence = self:generateTypingSequence()
                self.typingProgress = 0
                self.typingStartTime = love.timer.getTime()
                
                -- Pick safe lane NOW so player sees it during typing (1 out of 5 lanes)
                local cfg = Config.TreentOverlord
                self.safeLaneIndex = math.random(1, cfg.vineLaneCount or 5)
                
                self.screenShake:add(8, 0.3)
                self.particles:createExplosion(px, py, {0.6, 0.3, 0.1})
            end
            
            local onVineLanes = function(phase)
                if phase == "start" then
                    self.vineLanesActive = true
                    self.vineDamageTimer = 0
                    
                    -- Spawn vine lanes
                    local cfg = Config.TreentOverlord
                    local screenHeight = love.graphics.getHeight()
                    local laneCount = cfg.vineLaneCount or 5
                    local spacing = cfg.vineLaneSpacing or 100
                    local speed = cfg.vineLaneSpeed or 280
                    local damage = cfg.vineLaneDamage or 9999
                    
                    -- If safe lane not set yet, pick one now
                    if not self.safeLaneIndex then
                        self.safeLaneIndex = math.random(1, laneCount)
                    end
                    
                    -- Calculate vertical center for lanes
                    local totalHeight = (laneCount - 1) * spacing
                    local startY = (screenHeight - totalHeight) / 2
                    
                    -- Clear old lanes and spawn new ones
                    self.vineLanes = {}
                    for i = 1, laneCount do
                        if i ~= self.safeLaneIndex then
                            local laneY = startY + (i - 1) * spacing
                            local vine = VineLane:new(laneY, i, speed, damage)
                            table.insert(self.vineLanes, vine)
                        end
                    end
                    
                    self.screenShake:add(12, 0.5)
                elseif phase == "end" then
                    self.vineLanesActive = false
                    self.vineLanes = {}
                    self.safeLaneIndex = nil
                end
            end
            
            self.boss:update(dt, playerX, playerY, onBarkShoot, onPhaseTransition, onEncompassRoot, onVineLanes)
            
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
        
        -- Update vine lanes and check collision
        if self.vineLanesActive then
            -- Update all vine lanes
            for i = #self.vineLanes, 1, -1 do
                local vine = self.vineLanes[i]
                vine:update(dt)
                
                -- Remove finished vines
                if vine:isFinished() then
                    table.remove(self.vineLanes, i)
                end
            end
            
            -- Check vine damage (tick every 0.5s if in vine lane)
            self.vineDamageTimer = self.vineDamageTimer + dt
            if self.vineDamageTimer >= 0.5 then
                self.vineDamageTimer = 0
                
                -- Check if player is in any vine lane
                local inDanger = false
                for _, vine in ipairs(self.vineLanes) do
                    if vine:isPlayerInDanger(playerX, playerY) then
                        inDanger = true
                        break
                    end
                end
                
                if inDanger then
                    -- Deal vine damage (LETHAL)
                    local vineDmg = Config.TreentOverlord.vineLaneDamage or 9999
                    if self.frenzyActive then vineDmg = vineDmg * Config.Abilities.frenzy.damageTakenMult end
                    self.player:takeDamage(vineDmg)
                    self.screenShake:add(8, 0.25)
                    self.particles:createExplosion(playerX, playerY, {0.2, 0.8, 0.2})
                end
            end
            
            -- End vine lanes if all have passed
            if #self.vineLanes == 0 and self.vineLanesActive then
                self.vineLanesActive = false
                self.safeLaneIndex = nil
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
                        
                        -- Power Shot impact juice (freeze, shake, flash)
                        if arrow.kind == "power_shot" then
                            JuiceManager.impact(self.boss, 0.05, 12, 0.18, 0.1)
                        end
                        
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
    
    -- Draw DANGER ZONE indicators (red blinking lines where vines will be)
    -- Only show during casting phase (telegraph), not when vines are actually active
    if self.boss and self.boss.earthquakeCasting and self.safeLaneIndex then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        local cfg = Config.TreentOverlord
        local laneCount = cfg.vineLaneCount or 5
        local spacing = cfg.vineLaneSpacing or 100
        
        -- Calculate lane positions
        local totalHeight = (laneCount - 1) * spacing
        local startY = (screenHeight - totalHeight) / 2
        
        -- Blinking effect (fast blink)
        local blinkRate = love.timer.getTime() * 8 -- Fast blink
        local blinkAlpha = 0.3 + math.abs(math.sin(blinkRate)) * 0.7
        
        -- Draw red danger lines for ALL lanes EXCEPT the safe one
        for i = 1, laneCount do
            local laneY = startY + (i - 1) * spacing
            
            if i ~= self.safeLaneIndex then
                -- DANGER LANE - red blinking warning
                love.graphics.setColor(1, 0.1, 0.1, blinkAlpha * 0.4)
                love.graphics.rectangle("fill", 0, laneY - 35, screenWidth, 70)
                
                -- Danger border (bright red, pulsing)
                love.graphics.setColor(1, 0.2, 0.2, blinkAlpha)
                love.graphics.setLineWidth(4)
                love.graphics.line(0, laneY - 35, screenWidth, laneY - 35)
                love.graphics.line(0, laneY + 35, screenWidth, laneY + 35)
                
                -- Danger arrow indicators (pointing inward)
                local arrowSpacing = 120
                for ax = 50, screenWidth - 50, arrowSpacing do
                    love.graphics.setColor(1, 0.3, 0.3, blinkAlpha)
                    -- Draw simple ">" arrows pointing right (vine direction)
                    love.graphics.polygon("fill", 
                        ax, laneY - 8,
                        ax + 12, laneY,
                        ax, laneY + 8
                    )
                end
            end
        end
        
        -- Warning text at top
        love.graphics.setColor(1, 0.3, 0.3, blinkAlpha)
        love.graphics.setNewFont(18)
        love.graphics.printf("DANGER! AVOID RED ZONES!", 0, 120, screenWidth, "center")
        love.graphics.setNewFont(12)
        
        love.graphics.setLineWidth(1)
    end
    
    -- Draw vine lanes
    for _, vine in ipairs(self.vineLanes) do
        vine:draw()
    end
    
    -- Y-sort drawing
    local drawables = {}
    
    -- Add boss
    if self.boss and self.boss.isAlive then
        table.insert(drawables, { entity = self.boss, y = self.boss.y, type = "boss" })
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
    
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- Typing Test UI (top of screen)
    if self.typingTestActive then
        local screenWidth = love.graphics.getWidth()
        
        -- Background panel
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", screenWidth/2 - 200, 30, 400, 80, 10, 10)
        
        -- Title
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.setNewFont(20)
        love.graphics.printf("TYPE TO ESCAPE!", 0, 40, screenWidth, "center")
        
        -- Letters
        love.graphics.setNewFont(36)
        local letterSpacing = 50
        local startX = screenWidth/2 - (#self.typingSequence * letterSpacing / 2)
        
        for i, letter in ipairs(self.typingSequence) do
            local x = startX + (i-1) * letterSpacing
            
            if i <= self.typingProgress then
                -- Completed letters (green)
                love.graphics.setColor(0.2, 1, 0.3, 1)
            elseif i == self.typingProgress + 1 then
                -- Current letter (yellow + pulse)
                local pulse = 0.7 + math.sin(love.timer.getTime() * 10) * 0.3
                love.graphics.setColor(1, 1, 0, pulse)
            else
                -- Pending letters (white)
                love.graphics.setColor(1, 1, 1, 0.5)
            end
            
            love.graphics.print(string.upper(letter), x, 75)
        end
        
        love.graphics.setNewFont(12)
    end
    
    -- U-shaped HUD background (from main build)
    local hudWidth = 400
    local hudHeight = 90
    local hudX = (w - hudWidth) / 2
    local hudY = h - hudHeight - 10
    
    -- Draw curved background shape
    love.graphics.setColor(0, 0, 0, 0.7)
    -- Main rectangle
    love.graphics.rectangle("fill", hudX + 30, hudY + 20, hudWidth - 60, hudHeight - 20, 8, 8)
    -- Left curve
    love.graphics.arc("fill", hudX + 38, hudY + 28, 30, math.pi, math.pi * 1.5)
    love.graphics.rectangle("fill", hudX + 8, hudY + 28, 30, hudHeight - 28)
    -- Right curve
    love.graphics.arc("fill", hudX + hudWidth - 38, hudY + 28, 30, math.pi * 1.5, math.pi * 2)
    love.graphics.rectangle("fill", hudX + hudWidth - 38, hudY + 28, 30, hudHeight - 28)
    
    -- Health bar
    local healthBarWidth = hudWidth - 80
    local healthBarHeight = 16
    local healthBarX = hudX + 40
    local healthBarY = hudY + 25
    
    -- Health bar background
    love.graphics.setColor(0.2, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 4, 4)
    
    -- Health bar fill
    local healthPercent = self.player.health / self.player.maxHealth
    local healthColor = {0.2, 0.8, 0.2}
    if healthPercent < 0.3 then
        healthColor = {0.9, 0.2, 0.2}
    elseif healthPercent < 0.6 then
        healthColor = {0.9, 0.7, 0.2}
    end
    love.graphics.setColor(healthColor[1], healthColor[2], healthColor[3], 1)
    love.graphics.rectangle("fill", healthBarX + 2, healthBarY + 2, (healthBarWidth - 4) * healthPercent, healthBarHeight - 4, 3, 3)
    
    -- Health bar shine
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", healthBarX + 2, healthBarY + 2, (healthBarWidth - 4) * healthPercent, (healthBarHeight - 4) / 2, 3, 3)
    
    -- Health bar border
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 4, 4)
    love.graphics.setLineWidth(1)
    
    -- Health text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local healthText = math.floor(self.player.health) .. "/" .. self.player.maxHealth
    local textWidth = font:getWidth(healthText)
    love.graphics.print(healthText, healthBarX + healthBarWidth/2 - textWidth/2, healthBarY + 1)
    
    -- Draw abilities below health bar
    local abilitySize = 44
    local abilitySpacing = 12
    local numAbilities = #self.player.abilityOrder
    local abilitiesWidth = numAbilities * abilitySize + (numAbilities - 1) * abilitySpacing
    local abilitiesX = (w - abilitiesWidth) / 2
    local abilitiesY = healthBarY + healthBarHeight + 10
    
    for i, abilityId in ipairs(self.player.abilityOrder) do
        local ability = self.player.abilities[abilityId]
        if ability then
            local x = abilitiesX + (i - 1) * (abilitySize + abilitySpacing)
            UIUtils.drawAbilityIcon(ability, x, abilitiesY, abilitySize)
        end
    end
    
    -- Boss title at top
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.setNewFont(24)
    love.graphics.printf("TREENT OVERLORD", 0, 30, w, "center")
    love.graphics.setNewFont(12)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BossArenaScene:keypressed(key)
    -- Typing test input (Phase 2 mechanic)
    if self.typingTestActive then
        local expectedKey = self.typingSequence[self.typingProgress + 1]
        if key == expectedKey then
            -- Correct key!
            self.typingProgress = self.typingProgress + 1
            
            -- Check if completed
            if self.typingProgress >= #self.typingSequence then
                -- SUCCESS! Unroot player
                self.typingTestActive = false
                if self.player then
                    self.player.isRooted = false
                    self.player.rootDuration = 0
                end
                self.screenShake:add(4, 0.15)
                self.particles:createExplosion(self.player.x, self.player.y, {0.2, 1, 0.3})
            end
        else
            -- Wrong key! Reset progress (no death)
            self.typingProgress = 0
            self.screenShake:add(2, 0.1)
        end
        return true  -- Consume input
    end
    
    -- Manual abilities
    if key == "r" and self.player and self.player:isAbilityReady("frenzy") and self.frenzyCharge >= self.frenzyChargeMax then
        self.player:useAbility("frenzy")
        self.frenzyCharge = self.frenzyCharge - self.frenzyChargeMax
        local fCfg = Config.Abilities.frenzy
        self.playerStats:addBuff("frenzy", fCfg.duration, {
            { stat = "move_speed", mul = fCfg.moveSpeedMult },
            { stat = "attack_speed", mul = fCfg.attackSpeedMult },
            { stat = "crit_chance", add = fCfg.critChanceAdd },
        }, { break_on_hit_taken = true, damage_taken_multiplier = fCfg.damageTakenMult })
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
        return
    end
    
    if self.dashCooldown <= 0 and not self.isDashing and self.player then
        -- Use WASD input for dash direction
        local dx, dy = 0, 0
        
        if love.keyboard.isDown("w", "up") then dy = dy - 1 end
        if love.keyboard.isDown("s", "down") then dy = dy + 1 end
        if love.keyboard.isDown("a", "left") then dx = dx - 1 end
        if love.keyboard.isDown("d", "right") then dx = dx + 1 end
        
        -- Normalize diagonal movement
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            self.dashDirX = dx / distance
            self.dashDirY = dy / distance
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
