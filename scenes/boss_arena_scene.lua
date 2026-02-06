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
local FallingTrunk = require("entities.falling_trunk")
local AbilityHUD = require("ui.ability_hud")
local BuffBar = require("ui.buff_bar")
local StatsOverlay = require("ui.stats_overlay")

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

        -- Falling trunks (Phase 2 mechanic)
        fallingTrunks = {},           -- Array of FallingTrunk entities
        trunkSpawnTimer = 0,          -- Timer for continuous spawning
        trunkSpawnInterval = 1.5,     -- Spawn 1 trunk every 1.5 seconds
        trunksEnabled = false,        -- Only spawn in Phase 2

        -- Systems
        particles = Particles:new(),
        screenShake = ScreenShake:new(),
        damageNumbers = DamageNumbers:new(),
        
        -- UI Components (reuse from main game)
        abilityHUD = AbilityHUD:new(),
        buffBar = BuffBar:new(),
        statsOverlay = StatsOverlay:new(),
        
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
        
        -- Arena decorative props
        arenaProps = {},
        propImages = {},
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
    
    -- Load decorative props for arena edges
    self:loadArenaProps()
end

function BossArenaScene:loadArenaProps()
    local tilePath = "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Tiles/"
    
    -- Load tile images for props (trees, rocks, stumps, bushes)
    local propTiles = {
        tree1 = "tile_0003.png",    -- Tree
        tree2 = "tile_0004.png",    -- Tree variant
        rock1 = "tile_0018.png",    -- Rock
        rock2 = "tile_0019.png",    -- Rock variant
        stump = "tile_0020.png",    -- Stump
        bush1 = "tile_0021.png",    -- Bush
        bush2 = "tile_0022.png",    -- Bush variant
    }
    
    for name, file in pairs(propTiles) do
        local success, img = pcall(love.graphics.newImage, tilePath .. file)
        if success then
            self.propImages[name] = img
        end
    end
    
    -- Create prop positions around arena edges
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local margin = 60
    local propTypes = {"tree1", "tree2", "rock1", "rock2", "stump", "bush1", "bush2"}
    
    -- Top edge props
    for i = 1, 6 do
        local propType = propTypes[math.random(#propTypes)]
        table.insert(self.arenaProps, {
            image = propType,
            x = margin + (i - 1) * ((screenWidth - margin * 2) / 5) + math.random(-20, 20),
            y = margin + math.random(-10, 10),
            scale = 2.5 + math.random() * 0.5,
            tint = {0.7 + math.random() * 0.2, 0.8 + math.random() * 0.15, 0.6 + math.random() * 0.15}
        })
    end
    
    -- Bottom edge props
    for i = 1, 6 do
        local propType = propTypes[math.random(#propTypes)]
        table.insert(self.arenaProps, {
            image = propType,
            x = margin + (i - 1) * ((screenWidth - margin * 2) / 5) + math.random(-20, 20),
            y = screenHeight - margin + math.random(-10, 10),
            scale = 2.5 + math.random() * 0.5,
            tint = {0.7 + math.random() * 0.2, 0.8 + math.random() * 0.15, 0.6 + math.random() * 0.15}
        })
    end
    
    -- Left edge props
    for i = 1, 4 do
        local propType = propTypes[math.random(#propTypes)]
        table.insert(self.arenaProps, {
            image = propType,
            x = margin + math.random(-10, 10),
            y = margin * 2 + (i - 1) * ((screenHeight - margin * 4) / 3) + math.random(-15, 15),
            scale = 2.5 + math.random() * 0.5,
            tint = {0.7 + math.random() * 0.2, 0.8 + math.random() * 0.15, 0.6 + math.random() * 0.15}
        })
    end
    
    -- Right edge props
    for i = 1, 4 do
        local propType = propTypes[math.random(#propTypes)]
        table.insert(self.arenaProps, {
            image = propType,
            x = screenWidth - margin + math.random(-10, 10),
            y = margin * 2 + (i - 1) * ((screenHeight - margin * 4) / 3) + math.random(-15, 15),
            scale = 2.5 + math.random() * 0.5,
            tint = {0.7 + math.random() * 0.2, 0.8 + math.random() * 0.15, 0.6 + math.random() * 0.15}
        })
    end
    
    -- Corner accent props (larger trees in corners)
    local corners = {
        {x = 40, y = 40},
        {x = screenWidth - 40, y = 40},
        {x = 40, y = screenHeight - 40},
        {x = screenWidth - 40, y = screenHeight - 40},
    }
    
    for _, corner in ipairs(corners) do
        table.insert(self.arenaProps, {
            image = math.random() > 0.5 and "tree1" or "tree2",
            x = corner.x,
            y = corner.y,
            scale = 3.5,
            tint = {0.6, 0.75, 0.5}
        })
    end
end

function BossArenaScene:drawArenaProps()
    for _, prop in ipairs(self.arenaProps) do
        local img = self.propImages[prop.image]
        if img then
            love.graphics.setColor(prop.tint[1], prop.tint[2], prop.tint[3], 0.85)
            local imgW, imgH = img:getDimensions()
            love.graphics.draw(img, prop.x, prop.y, 0, prop.scale, prop.scale, imgW / 2, imgH / 2)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
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
    
    -- Pause while stats overlay is open
    if self.statsOverlay and self.statsOverlay:isVisible() then
        return
    end
    
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

            -- Auto-fire primary (blocked during typing test - boss is invulnerable)
            if self.fireCooldown <= 0 and not self.isDashing and not self.typingTestActive then
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

        -- Auto-cast Power Shot (blocked during typing test)
        if self.player and self.player:isAbilityReady("power_shot") and not self.isDashing and not self.typingTestActive then
            local psTargetX, psTargetY = nil, nil
            local psCfg = Config.Abilities.powerShot
            
            -- Target the boss
            if self.boss and self.boss.isAlive then
                psTargetX, psTargetY = self.boss:getPosition()
            end
            
            if psTargetX and psTargetY then
                self.player:aimAt(psTargetX, psTargetY)
                self.player:useAbility("power_shot", self.playerStats)
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
                
                -- Apply ability mods
                local damageMul = self.playerStats:getAbilityModValue("power_shot", "damage_mul", 1.0)
                local base = (self.player.attackDamage or 10) * psCfg.damageMult * damageMul
                
                -- Check for elite/MCM bonus damage mod (boss counts as elite)
                local eliteMcmMod = self.playerStats:getAbilityMod("power_shot", "bonus_damage_vs_elite_mcm")
                if eliteMcmMod then
                    base = base * eliteMcmMod.value
                end
                
                local appliesStatus = self.playerStats:getAbilityMod("power_shot", "applies_status")
                
                local ps = Arrow:new(sx, sy, psTargetX, psTargetY, {
                    damage = base,
                    speed = psCfg.speed,
                    size = 12,
                    lifetime = 1.8,
                    pierce = 999,
                    alwaysCrit = true,
                    kind = "power_shot",
                    knockback = psCfg.knockback,
                    appliesStatus = appliesStatus,
                })
                table.insert(self.arrows, ps)
                self.screenShake:add(3, 0.12)
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
                if self.player.playAttackAnimation then self.player:playAttackAnimation() end
                
                -- Handle fires_twice mod: spawn second arrow after delay
                local firesTwiceMod = self.playerStats:getAbilityMod("power_shot", "fires_twice")
                if firesTwiceMod then
                    local delay = firesTwiceMod.delay or 0.08
                    local secondDamageMul = firesTwiceMod.second_shot_damage_mul or 0.55
                    self.pendingPowerShots = self.pendingPowerShots or {}
                    table.insert(self.pendingPowerShots, {
                        timer = delay,
                        sx = sx, sy = sy, ex = psTargetX, ey = psTargetY,
                        damage = base * secondDamageMul,
                        speed = psCfg.speed,
                        knockback = psCfg.knockback,
                        appliesStatus = appliesStatus,
                    })
                end
            end
        end
        
        -- Auto-cast Arrow Volley (targets boss, blocked during typing test)
        if self.player and self.player:isAbilityReady("arrow_volley") and not self.typingTestActive then
            local volleyRange = 300
            
            -- Target boss
            if self.boss and self.boss.isAlive then
                local bx, by = self.boss:getPosition()
                local px, py = playerX, playerY
                local dx = bx - px
                local dy = by - py
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist <= volleyRange then
                    self.player:useAbility("arrow_volley", self.playerStats)
                    -- Deal damage to boss (Arrow Volley is damage, not root)
                    local baseDmg = self.playerStats and self.playerStats:get("attack") or 25
                    
                    -- Apply ability mods
                    local damageMul = self.playerStats:getAbilityModValue("arrow_volley", "damage_mul", 1.0)
                    local damage = baseDmg * 1.5 * damageMul
                    
                    self.boss:takeDamage(damage)
                    self.particles:createExplosion(bx, by, {1, 0.8, 0.2})
                    self.screenShake:add(3, 0.15)
                    
                    -- Handle double_strike mod: deal damage again after delay
                    local doubleStrikeMod = self.playerStats:getAbilityMod("arrow_volley", "double_strike")
                    if doubleStrikeMod then
                        local delay = doubleStrikeMod.delay or 0.3
                        local secondVolleyDamageMul = doubleStrikeMod.second_volley_damage_mul or 1.0
                        self.pendingArrowVolleys = self.pendingArrowVolleys or {}
                        table.insert(self.pendingArrowVolleys, {
                            timer = delay,
                            tx = bx, ty = by,
                            damage = damage * secondVolleyDamageMul,
                        })
                    end
                end
            end
        end
        
        -- Process pending power shots (fires_twice mod)
        if self.pendingPowerShots then
            for i = #self.pendingPowerShots, 1, -1 do
                local pending = self.pendingPowerShots[i]
                pending.timer = pending.timer - dt
                if pending.timer <= 0 then
                    local ps = Arrow:new(pending.sx, pending.sy, pending.ex, pending.ey, {
                        damage = pending.damage,
                        speed = pending.speed,
                        size = 12,
                        lifetime = 1.8,
                        pierce = 999,
                        alwaysCrit = true,
                        kind = "power_shot",
                        knockback = pending.knockback,
                        appliesStatus = pending.appliesStatus,
                    })
                    table.insert(self.arrows, ps)
                    table.remove(self.pendingPowerShots, i)
                end
            end
        end
        
        -- Process pending arrow volleys (double_strike mod)
        if self.pendingArrowVolleys then
            for i = #self.pendingArrowVolleys, 1, -1 do
                local pending = self.pendingArrowVolleys[i]
                pending.timer = pending.timer - dt
                if pending.timer <= 0 then
                    if self.boss and self.boss.isAlive then
                        self.boss:takeDamage(pending.damage)
                        self.particles:createExplosion(pending.tx, pending.ty, {1, 0.8, 0.2})
                    end
                    table.remove(self.pendingArrowVolleys, i)
                end
            end
        end
        
        -- Update boss
        if self.boss and self.boss.isAlive then
            local onBarkShoot = function(sx, sy, tx, ty, speed)
                local bark = BarkProjectile:new(sx, sy, tx, ty, speed)
                bark.damage = 25 -- Boss bark does more damage
                table.insert(self.barkProjectiles, bark)
            end
            
            local onPhaseTransition = function()
                self.screenShake:add(12, 0.5)
                self.particles:createExplosion(self.boss.x, self.boss.y, {1, 0.3, 0.3})

                -- Enable falling trunks in Phase 2 (enraged mode)
                self.trunksEnabled = true
                self.trunkSpawnTimer = 0
            end
            
            local onEncompassRoot = function(px, py)
                -- This is now UNUSED - typing test is handled by onTypingTest callback
                -- Kept for backwards compatibility but does nothing
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

            local onTypingTest = function(phase)
                if phase == "start" then
                    -- Start typing test
                    self.typingTestActive = true
                    self.typingProgress = 0
                    self.typingStartTime = love.timer.getTime()

                    -- ROOT THE PLAYER (they must type to escape)
                    if self.player and self.player.applyRoot then
                        self.player:applyRoot(999) -- Long duration, unlocked by typing
                    end

                    -- Teleport boss to center of arena and freeze
                    if self.boss then
                        local screenWidth = love.graphics.getWidth()
                        local screenHeight = love.graphics.getHeight()
                        self.boss.x = screenWidth / 2
                        self.boss.y = screenHeight / 2

                        -- Stop all boss movement
                        self.boss.lungeState = "idle"
                        self.boss.knockbackX = 0
                        self.boss.knockbackY = 0
                    end

                    -- Pick safe lane NOW so player knows where to go after typing
                    local cfg = Config.TreentOverlord
                    self.safeLaneIndex = math.random(1, cfg.vineLaneCount or 5)

                    -- Generate 6 random letters (only qwerasdf keys)
                    local letters = {"q", "w", "e", "r", "a", "s", "d", "f"}
                    self.typingSequence = {}
                    for i = 1, 6 do
                        table.insert(self.typingSequence, letters[math.random(#letters)])
                    end

                    self.screenShake:add(8, 0.3)
                    self.particles:createExplosion(self.player.x, self.player.y, {0.6, 0.3, 0.1})
                end
            end

            self.boss:update(dt, playerX, playerY, onBarkShoot, onPhaseTransition, onEncompassRoot, onVineLanes, onTypingTest)
            
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
        if self.vineLanesActive and not self.typingTestActive then
            -- Update all vine lanes (paused during typing test)
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

        -- Update falling trunks (Phase 2 mechanic, paused during typing test)
        if self.trunksEnabled and not self.typingTestActive then
            -- Spawn new trunks continuously
            self.trunkSpawnTimer = self.trunkSpawnTimer + dt
            if self.trunkSpawnTimer >= self.trunkSpawnInterval then
                self.trunkSpawnTimer = 0

                -- Spawn trunk at random position in arena
                local screenWidth = love.graphics.getWidth()
                local screenHeight = love.graphics.getHeight()
                local margin = 100
                local targetX = margin + math.random() * (screenWidth - margin * 2)
                local targetY = margin + math.random() * (screenHeight - margin * 2)

                local trunk = FallingTrunk:new(targetX, targetY, 60)
                table.insert(self.fallingTrunks, trunk)
            end

            -- Update all trunks
            for i = #self.fallingTrunks, 1, -1 do
                local trunk = self.fallingTrunks[i]
                trunk:update(dt)

                -- Check player collision during impact
                if trunk:isInImpactPhase() and self.player then
                    if trunk:isPlayerInDanger(playerX, playerY) then
                        local damage = trunk:getDamage()
                        if self.frenzyActive then damage = damage * Config.Abilities.frenzy.damageTakenMult end
                        self.player:takeDamage(damage)
                        self.screenShake:add(10, 0.3)
                        self.particles:createExplosion(playerX, playerY, {0.8, 0.5, 0.2})
                    end
                end

                -- Remove finished trunks
                if trunk.isFinished then
                    table.remove(self.fallingTrunks, i)
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
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background: Rich forest green floor (contrasts with brown boss)
    love.graphics.setColor(0.12, 0.22, 0.10, 1)  -- Dark forest green base
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Add subtle grass texture pattern
    love.graphics.setColor(0.15, 0.28, 0.12, 0.3)  -- Lighter green accents
    for row = 0, screenHeight / 32 do
        for col = 0, screenWidth / 32 do
            if (row + col) % 3 == 0 then
                love.graphics.rectangle("fill", col * 32, row * 32, 32, 32)
            end
        end
    end
    
    -- Arena border (darker edge gradient effect)
    love.graphics.setColor(0.06, 0.12, 0.05, 0.8)
    love.graphics.setLineWidth(20)
    love.graphics.rectangle("line", 10, 10, screenWidth - 20, screenHeight - 20)
    love.graphics.setLineWidth(1)
    
    -- Draw decorative props (behind entities)
    self:drawArenaProps()
    
    -- Apply screen shake
    love.graphics.push()
    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw particles (background layer)
    self.particles:draw()
    
    -- Draw DANGER ZONE indicators (red blinking zones where vines will be)
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
        
        -- Draw red danger zones for ALL lanes EXCEPT the safe one
        for i = 1, laneCount do
            local laneY = startY + (i - 1) * spacing
            
            if i ~= self.safeLaneIndex then
                -- DANGER LANE - bright red/orange warning (visible on green)
                love.graphics.setColor(1, 0.2, 0.1, blinkAlpha * 0.6)
                love.graphics.rectangle("fill", 0, laneY - 35, screenWidth, 70)
                
                -- Danger border (bright orange, pulsing - high contrast on green)
                love.graphics.setColor(1, 0.4, 0.1, blinkAlpha)
                love.graphics.setLineWidth(4)
                love.graphics.line(0, laneY - 35, screenWidth, laneY - 35)
                love.graphics.line(0, laneY + 35, screenWidth, laneY + 35)
            end
        end
        
        love.graphics.setLineWidth(1)
    end
    
    -- Draw vine lanes
    for _, vine in ipairs(self.vineLanes) do
        vine:draw()
    end

    -- Draw falling trunks (ground telegraphs first, then falling trunks later)
    -- Draw telegraphs on ground (before entities)
    for _, trunk in ipairs(self.fallingTrunks) do
        if trunk.state == "telegraph" or trunk.state == "falling" then
            trunk:draw()
        end
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

        -- Draw invulnerability shield on boss during typing test
        if drawable.type == "boss" and self.boss and self.boss.isInvulnerable then
            local bx, by = self.boss.x, self.boss.y
            local radius = self.boss.size * 1.3
            local pulse = math.sin(love.timer.getTime() * 5) * 0.2 + 0.8

            -- Shield glow
            love.graphics.setColor(0.9, 0.7, 0.2, 0.3 * pulse)
            love.graphics.circle("fill", bx, by, radius + 10)

            -- Shield ring
            love.graphics.setColor(1, 0.8, 0.3, 0.8 * pulse)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", bx, by, radius)

            -- Inner shield ring
            love.graphics.setColor(1, 0.9, 0.5, 0.5 * pulse)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", bx, by, radius - 8)

            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1, 1)
        end
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

    -- Draw trunk impact effects (on top of everything)
    for _, trunk in ipairs(self.fallingTrunks) do
        if trunk.state == "impact" then
            trunk:draw()
        end
    end

    love.graphics.pop()
    
    -- UI (not affected by shake)
    self:drawUI()
    
    -- Draw stats overlay on top of everything
    if self.statsOverlay and self.statsOverlay:isVisible() then
        self.statsOverlay:draw(self.playerStats, self.xpSystem, self.player)
    end
end

function BossArenaScene:drawUI()
    if not self.player then return end
    
    -- Draw boss health bar at top
    if self.boss and self.boss.isAlive then
        self:drawBossHealthBar()
    end
    
    -- Typing Test UI (center-lower screen for better visibility)
    if self.typingTestActive then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()

        -- Center position (lower third of screen)
        local panelY = screenHeight * 0.6

        -- Larger background panel with glow
        love.graphics.setColor(0.05, 0.05, 0.1, 0.95)
        love.graphics.rectangle("fill", screenWidth/2 - 280, panelY - 20, 560, 140, 15, 15)

        -- Outer glow (pulsing)
        local glowPulse = 0.3 + math.sin(love.timer.getTime() * 3) * 0.2
        love.graphics.setColor(1, 0.3, 0.3, glowPulse)
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", screenWidth/2 - 280, panelY - 20, 560, 140, 15, 15)
        love.graphics.setLineWidth(1)

        -- Title (vibrant red with glow)
        love.graphics.setNewFont(24)
        love.graphics.setColor(1, 0.1, 0.1, 0.8)
        love.graphics.printf("TYPE TO ESCAPE!", 0, panelY - 5, screenWidth, "center")
        love.graphics.setColor(1, 0.4, 0.2, 1)
        love.graphics.printf("TYPE TO ESCAPE!", 0, panelY - 8, screenWidth, "center")

        -- Letters (much larger and more vibrant)
        love.graphics.setNewFont(54)
        local letterSpacing = 70
        local startX = screenWidth/2 - (#self.typingSequence * letterSpacing / 2)
        local letterY = panelY + 45

        for i, letter in ipairs(self.typingSequence) do
            local x = startX + (i-1) * letterSpacing

            if i <= self.typingProgress then
                -- Completed letters (bright green with glow)
                love.graphics.setColor(0, 0.8, 0, 0.4)
                love.graphics.print(string.upper(letter), x + 2, letterY + 2)
                love.graphics.setColor(0.2, 1, 0.3, 1)
                love.graphics.print(string.upper(letter), x, letterY)

            elseif i == self.typingProgress + 1 then
                -- Current letter (bright cyan/yellow + strong pulse + glow)
                local pulse = 0.8 + math.sin(love.timer.getTime() * 12) * 0.2
                local colorShift = math.sin(love.timer.getTime() * 8) * 0.5 + 0.5

                -- Glow behind
                love.graphics.setColor(1, 1, 0, pulse * 0.6)
                love.graphics.circle("fill", x + 22, letterY + 30, 35)

                -- Shadow
                love.graphics.setColor(0.3, 0.3, 0, 0.8)
                love.graphics.print(string.upper(letter), x + 3, letterY + 3)

                -- Main letter (color shifts yellow -> cyan)
                love.graphics.setColor(1 - colorShift * 0.3, 1, colorShift * 0.5, 1)
                love.graphics.print(string.upper(letter), x, letterY)

            else
                -- Pending letters (dim white)
                love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
                love.graphics.print(string.upper(letter), x, letterY)
            end
        end

        love.graphics.setNewFont(12)
    end
    
    -- Draw ability HUD (corner-based layout: health bottom-left, abilities bottom-right)
    if self.abilityHUD then
        -- Update frenzy charge for display
        if self.player.abilities.frenzy then
            self.player.abilities.frenzy.charge = self.frenzyCharge
            self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax
        end
        self.abilityHUD:draw(self.player, self.xpSystem)
    end
    
    -- Draw active buffs
    if self.buffBar and self.playerStats then
        local buffs = self.playerStats:getActiveBuffs()
        self.buffBar:draw(buffs)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BossArenaScene:keypressed(key)
    -- Stats overlay (Tab key)
    if key == "tab" and self.statsOverlay then
        self.statsOverlay:toggle()
        return true
    end
    
    -- Stats overlay scroll
    if self.statsOverlay and self.statsOverlay:isVisible() then
        if key == "up" then
            self.statsOverlay:scroll(-1, #(self.playerStats:getUpgradeLog() or {}))
            return true
        elseif key == "down" then
            self.statsOverlay:scroll(1, #(self.playerStats:getUpgradeLog() or {}))
            return true
        end
    end
    
    -- Typing test input (Phase 2 mechanic)
    if self.typingTestActive then
        local expectedKey = self.typingSequence[self.typingProgress + 1]
        if key == expectedKey then
            -- Correct key!
            self.typingProgress = self.typingProgress + 1
            
            -- Check if completed
            if self.typingProgress >= #self.typingSequence then
                -- SUCCESS! Unroot player and trigger vine attack
                self.typingTestActive = false
                if self.player then
                    self.player.isRooted = false
                    self.player.rootDuration = 0
                end
                if self.boss then
                    self.boss.isInvulnerable = false

                    -- Trigger vine lane attack after short delay (player has time to move to safety)
                    self.boss.earthquakeCasting = true
                    self.boss.earthquakeCastProgress = 0
                    self.boss.earthquakeTimer = 0
                    self.boss.earthquakeActive = false
                    self.boss.isInvulnerable = true  -- Boss invulnerable during vine attack
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
    
    -- Manual abilities (blocked during typing test)
    if key == "r" and self.player and self.player:isAbilityReady("frenzy") and self.frenzyCharge >= self.frenzyChargeMax and not self.typingTestActive then
        self.player:useAbility("frenzy", self.playerStats)
        self.frenzyCharge = self.frenzyCharge - self.frenzyChargeMax
        local fCfg = Config.Abilities.frenzy
        
        -- Apply ability mods
        local durationAdd = self.playerStats:getAbilityModValue("frenzy", "duration_add", 0)
        local critChanceAdd = self.playerStats:getAbilityModValue("frenzy", "crit_chance_add", 0)
        local moveSpeedMul = self.playerStats:getAbilityModValue("frenzy", "move_speed_mul", 1.0)
        local rollCooldownMul = self.playerStats:getAbilityModValue("frenzy", "roll_cooldown_mul", 1.0)
        
        local finalDuration = fCfg.duration + durationAdd
        local finalCritAdd = fCfg.critChanceAdd + critChanceAdd
        local finalMoveSpeedMul = fCfg.moveSpeedMult * moveSpeedMul
        
        self.playerStats:addBuff("frenzy", finalDuration, {
            { stat = "move_speed", mul = finalMoveSpeedMul },
            { stat = "attack_speed", mul = fCfg.attackSpeedMult },
            { stat = "crit_chance", add = finalCritAdd },
            { stat = "roll_cooldown", mul = rollCooldownMul },
        }, { break_on_hit_taken = true, damage_taken_multiplier = fCfg.damageTakenMult })
        self.frenzyActive = true
        self.frenzyKillsThisActivation = 0
        self.frenzyExtendedTime = 0
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

function BossArenaScene:drawBossHealthBar()
    if not self.boss then return end
    
    local w = love.graphics.getWidth()
    
    -- Boss health bar dimensions
    local barWidth = 600
    local barHeight = 30
    local barX = (w - barWidth) / 2
    local barY = 40
    
    -- Boss name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setNewFont(18)
    local bossName = "TREENT OVERLORD"
    local nameWidth = love.graphics.getFont():getWidth(bossName)
    love.graphics.print(bossName, (w - nameWidth) / 2, barY - 25)
    
    -- Phase indicator
    local phase = self.boss.phase or 1
    local phaseText = "Phase " .. phase
    love.graphics.setNewFont(14)
    local phaseWidth = love.graphics.getFont():getWidth(phaseText)
    local phaseColor = phase == 1 and {0.3, 1, 0.5} or {1, 0.3, 0.3}
    love.graphics.setColor(phaseColor[1], phaseColor[2], phaseColor[3], 1)
    love.graphics.print(phaseText, (w - phaseWidth) / 2, barY - 8)
    
    -- Health percentage
    local healthPercent = self.boss.health / self.boss.maxHealth
    
    -- Dark background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", barX - 4, barY - 4, barWidth + 8, barHeight + 8, 6, 6)
    
    -- Health bar background (dark red)
    love.graphics.setColor(0.3, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4, 4)
    
    -- Health bar fill with color gradient based on HP
    local r, g, b
    if healthPercent > 0.6 then
        r, g, b = 0.3, 0.9, 0.3  -- Green
    elseif healthPercent > 0.3 then
        r, g, b = 0.9, 0.7, 0.2  -- Yellow
    else
        r, g, b = 0.9, 0.2, 0.2  -- Red
    end
    
    -- Pulse effect when low health
    if healthPercent < 0.25 then
        local pulse = 0.8 + math.sin(love.timer.getTime() * 6) * 0.2
        r, g, b = r * pulse, g * pulse, b * pulse
    end
    
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barWidth - 4) * healthPercent, barHeight - 4, 3, 3)
    
    -- Segmented overlay (shows damage chunks)
    love.graphics.setColor(0, 0, 0, 0.3)
    local segments = 10
    for i = 1, segments - 1 do
        local segX = barX + (barWidth / segments) * i
        love.graphics.rectangle("fill", segX - 1, barY, 2, barHeight)
    end
    
    -- Shine effect on top half
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barWidth - 4) * healthPercent, (barHeight - 4) / 2, 3, 3)
    
    -- Border
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 4, 4)
    love.graphics.setLineWidth(1)
    
    -- HP text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setNewFont(16)
    local hpText = string.format("%d / %d", math.floor(self.boss.health), math.floor(self.boss.maxHealth))
    local hpWidth = love.graphics.getFont():getWidth(hpText)
    love.graphics.print(hpText, (w - hpWidth) / 2, barY + 7)
    
    -- Reset font
    love.graphics.setNewFont(12)
end

return BossArenaScene
