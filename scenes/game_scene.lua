-- Game Scene - Main gameplay
local Player = require("entities.player")
local Tree = require("entities.tree")
local Enemy = require("entities.enemy")
local Lunger = require("entities.lunger")
local Treent = require("entities.treent")
local SmallTreent = require("entities.small_treent")
local Wizard = require("entities.wizard")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local Tilemap = require("systems.tilemap")
local ForestTilemap = require("systems.forest_tilemap")
local XpSystem = require("systems.xp_system")
local PlayerStats = require("systems.player_stats")
local RarityCharge = require("systems.rarity_charge")
local UpgradeRoll = require("systems.upgrade_roll")
local UpgradeUI = require("ui.upgrade_ui")
local StatsOverlay = require("ui.stats_overlay")
local DamageNumbers = require("systems.damage_numbers")

-- Load upgrade data
local ArcherUpgrades = require("data.upgrades_archer")
local AbilityPaths = require("data.ability_paths_archer")

local GameScene = {}
GameScene.__index = GameScene

function GameScene:new(gameState)
    local scene = {
        gameState = gameState,
        player = nil,
        particles = nil,
        screenShake = nil,
        tilemap = nil,
        arrows = {},
        trees = {},
        bushes = {},
        enemies = {},
        lungers = {},
        treents = {},
        smallTreents = {},
        wizards = {},
        barkProjectiles = {},
        fireCooldown = 0,
        -- Dash ability
        dashCooldown = 0,
        dashDuration = 0.15,
        dashSpeed = 600,
        isDashing = false,
        dashTime = 0,
        dashDirX = 0,
        dashDirY = 0,
        -- Upgrade systems
        xpSystem = nil,
        playerStats = nil,
        rarityCharge = nil,
        upgradeUI = nil,
        isPaused = false,  -- Pause during upgrade selection
        statsOverlay = nil,
        damageNumbers = nil,

        -- Mouse tracking for manual-aim abilities
        mouseX = 0,
        mouseY = 0,

        -- Frenzy ultimate (charge-based)
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        frenzyActive = false,
        frenzyCombatGainPerSec = 3.5,
        frenzyKillGain = 10,
    }
    setmetatable(scene, GameScene)
    return scene
end

function GameScene:load()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Get selected class stats
    local heroClass = self.gameState.selectedHeroClass
    local difficulty = self.gameState.selectedDifficulty
    local biome = self.gameState.selectedBiome
    
    -- Initialize player with class stats
    self.player = Player:new(screenWidth / 2, screenHeight / 2)
    self.mouseX, self.mouseY = screenWidth / 2, screenHeight / 2
    
    if heroClass then
        self.player.maxHealth = heroClass.baseHP
        self.player.health = heroClass.baseHP
        self.player.speed = heroClass.baseSpeed
        self.player.attackDamage = heroClass.baseATK
        self.player.attackRange = heroClass.attackRange
        self.player.attackSpeed = heroClass.attackSpeed
        self.player.heroClass = heroClass.id
    end
    
    -- Store difficulty multipliers
    self.difficultyMult = difficulty or {
        enemyDamageMult = 1,
        enemyHealthMult = 1,
        playerDamageMult = 1
    }
    
    -- Initialize systems
    self.particles = Particles:new()
    self.screenShake = ScreenShake:new()
    
    -- Use forest tilemap for lush forest biome
    self.forestTilemap = ForestTilemap:new()
    self.tilemap = Tilemap:new() -- Keep as fallback
    
    -- Initialize upgrade systems
    self.xpSystem = XpSystem:new()
    self.playerStats = PlayerStats:new({
        primary_damage = heroClass and heroClass.baseATK or 10,
        move_speed = heroClass and heroClass.baseSpeed or 200,
        attack_speed = heroClass and heroClass.attackSpeed or 1.0,
        range = heroClass and heroClass.attackRange or 350,
    })
    self.rarityCharge = RarityCharge:new()
    self.upgradeUI = UpgradeUI:new()
    self.statsOverlay = StatsOverlay:new()
    self.damageNumbers = DamageNumbers:new()
    
    -- Set ability unlock states for archer (abilities are already defined in player)
    if self.player and self.player.abilities then
        self.player.abilities.power_shot.unlocked = true
        self.player.abilities.entangle.unlocked = true
        self.player.abilities.frenzy.unlocked = true
        self.player.abilities.dash.unlocked = true

        -- Make Frenzy charge-based in HUD
        self.player.abilities.frenzy.charge = 0
        self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax
    end
    
    -- Initialize projectiles
    self.arrows = {}
    self.fireCooldown = 0
    self.fireRate = heroClass and heroClass.attackSpeed or 0.4
    self.attackRange = heroClass and heroClass.attackRange or 350
    
    -- Get biome colors for environment
    self.bgColor = biome and biome.bgColor or {0.1, 0.1, 0.15}
    self.accentColor = biome and biome.accentColor or {0.3, 0.3, 0.4}
    
    -- Trees and bushes are now handled by ForestTilemap
    -- Keep empty arrays for compatibility
    self.trees = {}
    self.bushes = {}
    
    -- Spawn enemies based on floor and difficulty
    self:spawnEnemies()
end

function GameScene:spawnEnemies()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local floor = self.gameState.currentFloor
    
    -- Spawn counts (MCMs scale slower to keep them special)
    local numEnemies = 2 + math.floor(floor / 2)
    local numLungers = 1 + math.floor(floor / 4)  -- MCM: Wolf
    local numTreents = math.floor(floor / 3)
    local numSmallTreents = math.floor(floor / 5)  -- MCM: Bark Thrower
    local numWizards = math.floor(floor / 6)  -- MCM: Root Caster
    
    self.enemies = {}
    self.lungers = {}
    self.treents = {}
    self.smallTreents = {}
    self.wizards = {}
    self.barkProjectiles = {}
    
    -- Spawn regular enemies
    for i = 1, numEnemies do
        local angle = math.random() * math.pi * 2
        local distance = math.random(200, 400)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance
        
        local enemy = Enemy:new(x, y)
        -- Apply difficulty multipliers
        enemy.health = enemy.health * self.difficultyMult.enemyHealthMult
        enemy.maxHealth = enemy.health
        enemy.damage = (enemy.damage or 10) * self.difficultyMult.enemyDamageMult
        
        table.insert(self.enemies, enemy)
    end
    
    -- Spawn lungers (MCM - Wolf)
    for i = 1, numLungers do
        local angle = math.random() * math.pi * 2
        local distance = math.random(300, 500)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance
        
        local lunger = Lunger:new(x, y)
        lunger.health = lunger.health * self.difficultyMult.enemyHealthMult
        lunger.maxHealth = lunger.health
        
        table.insert(self.lungers, lunger)
    end

    -- Spawn treents (tanky elites)
    for i = 1, numTreents do
        local angle = math.random() * math.pi * 2
        local distance = math.random(350, 550)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance

        local treent = Treent:new(x, y)
        treent.health = treent.health * self.difficultyMult.enemyHealthMult
        treent.maxHealth = treent.health
        treent.damage = (treent.damage or 18) * self.difficultyMult.enemyDamageMult

        table.insert(self.treents, treent)
    end

    -- Spawn Small Treents (MCM - Bark Thrower)
    for i = 1, numSmallTreents do
        local angle = math.random() * math.pi * 2
        local distance = math.random(300, 500)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance

        local st = SmallTreent:new(x, y)
        st.health = st.health * self.difficultyMult.enemyHealthMult
        st.maxHealth = st.health

        table.insert(self.smallTreents, st)
    end

    -- Spawn Wizards (MCM - Root Caster)
    for i = 1, numWizards do
        local angle = math.random() * math.pi * 2
        local distance = math.random(280, 480)
        local x = screenWidth / 2 + math.cos(angle) * distance
        local y = screenHeight / 2 + math.sin(angle) * distance

        local wiz = Wizard:new(x, y)
        wiz.health = wiz.health * self.difficultyMult.enemyHealthMult
        wiz.maxHealth = wiz.health

        table.insert(self.wizards, wiz)
    end
end

function GameScene:update(dt)
    -- Update upgrade UI (always, even when paused)
    if self.upgradeUI then
        self.upgradeUI:update(dt)
    end

    -- Pause gameplay while stats overlay is open
    self.isPaused = (self.statsOverlay and self.statsOverlay:isVisible()) or false
    
    -- Check for pending level-ups
    if self.xpSystem and self.xpSystem:hasPendingLevelUp() and not self.upgradeUI:isVisible() then
        self:showUpgradeSelection()
    end
    
    -- Pause gameplay during upgrade selection
    if self.isPaused or (self.upgradeUI and self.upgradeUI:isVisible()) then
        return
    end
    
    -- Update systems
    self.particles:update(dt)
    self.screenShake:update(dt)
    if self.damageNumbers then
        self.damageNumbers:update(dt)
    end
    
    -- Update XP orbs
    if self.xpSystem and self.player then
        local pickupRadius = self.playerStats and self.playerStats:get("xp_pickup_radius") or 60
        self.xpSystem:update(dt, self.player.x, self.player.y, pickupRadius)
    end
    
    -- Update player stats (tick buff durations)
    if self.playerStats then
        -- Keep frenzy flag in sync with buff presence
        self.frenzyActive = self.playerStats:hasBuff("frenzy")

        self.playerStats:update(dt, {
            wasHit = false,  -- Would be set by damage system
            didRoll = self.isDashing,
            inFrenzy = self.frenzyActive,
        })
    end
    
    -- Update cooldowns
    self.fireCooldown = math.max(0, self.fireCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    
    -- Update player
    if self.player then
        -- Handle dash
        if self.isDashing then
            self.dashTime = self.dashTime - dt
            if self.dashTime <= 0 then
                self.isDashing = false
            else
                -- Move in dash direction
                self.player.x = self.player.x + self.dashDirX * self.dashSpeed * dt
                self.player.y = self.player.y + self.dashDirY * self.dashSpeed * dt
                
                -- Create dash trail particles
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            self.player:update(dt)
        end
        
        local playerX, playerY = self.player:getPosition()
        
        -- Find nearest enemy for targeting
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

        -- Check treents
        for _, treent in ipairs(self.treents) do
            if treent.isAlive then
                local tx, ty = treent:getPosition()
                local dx = tx - playerX
                local dy = ty - playerY
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < nearestDistance then
                    nearestEnemy = treent
                    nearestDistance = distance
                end
            end
        end

        -- Check Small Treents (MCM)
        for _, st in ipairs(self.smallTreents) do
            if st.isAlive then
                local stx, sty = st:getPosition()
                local dx = stx - playerX
                local dy = sty - playerY
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < nearestDistance then
                    nearestEnemy = st
                    nearestDistance = distance
                end
            end
        end

        -- Check Wizards (MCM)
        for _, wiz in ipairs(self.wizards) do
            if wiz.isAlive then
                local wx, wy = wiz:getPosition()
                local dx = wx - playerX
                local dy = wy - playerY
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < nearestDistance then
                    nearestEnemy = wiz
                    nearestDistance = distance
                end
            end
        end
        
        -- Aim at nearest enemy for bow presentation + primary targeting
        if nearestEnemy then
            local ex, ey = nearestEnemy:getPosition()
            self.player:aimAt(ex, ey)
            
            if self.fireCooldown <= 0 and not self.isDashing then
                -- Create primary projectile (auto-target)
                local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
                local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
                local arrow = Arrow:new(sx, sy, ex, ey, { damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140 })
                table.insert(self.arrows, arrow)
                self.fireCooldown = self.fireRate
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
            end
        end

        -- AUTO-CAST abilities (no aiming required)
        -- Power Shot: fires at nearest enemy when ready
        if nearestEnemy and self.player and self.player:isAbilityReady("power_shot") and not self.isDashing then
            local ex, ey = nearestEnemy:getPosition()
            self.player:aimAt(ex, ey)
            self.player:useAbility("power_shot")
            local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
            local base = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * 3.0
            local ps = Arrow:new(sx, sy, ex, ey, {
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

        -- Entangle: picks nearest target in range when ready
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
            for _, lunger in ipairs(self.lungers) do
                if lunger.isAlive then considerTarget(lunger, 18) end
            end
            for _, enemy in ipairs(self.enemies) do
                if enemy.isAlive then considerTarget(enemy, 0) end
            end
            for _, st in ipairs(self.smallTreents) do
                if st.isAlive then considerTarget(st, 10) end
            end
            for _, wiz in ipairs(self.wizards) do
                if wiz.isAlive then considerTarget(wiz, 12) end
            end
            if best and best.applyRoot then
                self.player:useAbility("entangle")
                local dur = (best.state ~= nil) and 1.0 or 1.8
                best:applyRoot(dur, 1.15)
                local tx, ty = best:getPosition()
                self.particles:createExplosion(tx, ty, {0.2, 1, 0.3})
                self.screenShake:add(2, 0.1)
            end
        end

        -- Frenzy is USER-ACTIVATED (press R). We only build charge here.
        
        -- Update arrows
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            arrow:update(dt)
            
            local ax, ay = arrow:getPosition()
            local hitEnemy = false

            -- Crit calc (includes temporary buffs like Frenzy)
            local critChance = self.playerStats and self.playerStats:get("crit_chance") or 0
            local critDamage = self.playerStats and self.playerStats:get("crit_damage") or 1.5
            local function rollDamage(base, forceCrit)
                local isCrit = forceCrit == true
                if not isCrit then
                    isCrit = (love.math.random() < critChance)
                end
                if isCrit then
                    return base * critDamage, true
                end
                return base, false
            end
            
            -- Check collision with enemies
            for j, enemy in ipairs(self.enemies) do
                if enemy.isAlive then
                    local ex, ey = enemy:getPosition()
                    local dx = ax - ex
                    local dy = ay - ey
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < enemy:getSize() + arrow:getSize() and arrow:canHit(enemy) then
                        arrow:markHit(enemy)
                        local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                        self.particles:createHitSpark(ex, ey, {1, 1, 0.6})
                        if self.damageNumbers then
                            self.damageNumbers:add(ex, ey - enemy:getSize(), dmg, { isCrit = isCrit })
                        end
                        local died = enemy:takeDamage(dmg, ax, ay, arrow.knockback)
                        
                        if died then
                            self.particles:createExplosion(ex, ey, {1, 0.3, 0.1})
                            self.screenShake:add(5, 0.2)
                            
                            -- Drop XP orbs
                            local baseXP = 15 + math.random(0, 10)
                            local xpValue = enemy.isMCM and (baseXP * 5) or baseXP  -- MCM bonus!
                            self.xpSystem:spawnOrb(ex, ey, xpValue)
                            
                            -- Add rarity charge for special enemies
                            if enemy.isMCM then
                                self.rarityCharge:add(love.timer.getTime(), 1)
                            end

                            -- Frenzy charge on kill
                            if not self.frenzyActive then
                                self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + self.frenzyKillGain)
                            end
                        else
                            self.screenShake:add(2, 0.1)
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
            
            -- Check lungers
            if not hitEnemy then
                for j, lunger in ipairs(self.lungers) do
                    if lunger.isAlive then
                        local lx, ly = lunger:getPosition()
                        local dx = ax - lx
                        local dy = ay - ly
                        local distance = math.sqrt(dx * dx + dy * dy)
                        
                        if distance < lunger:getSize() + arrow:getSize() and arrow:canHit(lunger) then
                            arrow:markHit(lunger)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            self.particles:createHitSpark(lx, ly, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(lx, ly - lunger:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = lunger:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            if died then
                                self.particles:createExplosion(lx, ly, {0.8, 0.3, 0.8})
                                self.screenShake:add(6, 0.25)
                                
                                -- Drop XP orbs (lungers are MCM - massive XP!)
                                local baseXP = 25 + math.random(0, 15)
                                local xpValue = lunger.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(lx, ly, xpValue)
                                
                                -- Lungers are MCM-type enemies, add rarity charge
                                self.rarityCharge:add(love.timer.getTime(), 2)

                                -- Frenzy charge on kill (lungers count as bigger kills)
                                if not self.frenzyActive then
                                    self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + (self.frenzyKillGain + 5))
                                end
                            else
                                self.screenShake:add(2, 0.1)
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

            -- Check treents
            if not hitEnemy then
                for _, treent in ipairs(self.treents) do
                    if treent.isAlive then
                        local tx, ty = treent:getPosition()
                        local dx = ax - tx
                        local dy = ay - ty
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < treent:getSize() + arrow:getSize() and arrow:canHit(treent) then
                            arrow:markHit(treent)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            self.particles:createHitSpark(tx, ty, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(tx, ty - treent:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = treent:takeDamage(dmg, ax, ay, arrow.knockback and (arrow.knockback * 0.75) or nil)

                            if died then
                                self.particles:createExplosion(tx, ty, {0.2, 0.9, 0.2})
                                self.screenShake:add(8, 0.3)
                                local xpValue = 60 + math.random(0, 25)
                                self.xpSystem:spawnOrb(tx, ty, xpValue)
                            else
                                self.screenShake:add(3, 0.12)
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

            -- Check Small Treents (MCM)
            if not hitEnemy then
                for _, st in ipairs(self.smallTreents) do
                    if st.isAlive then
                        local stx, sty = st:getPosition()
                        local dx = ax - stx
                        local dy = ay - sty
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < st:getSize() + arrow:getSize() and arrow:canHit(st) then
                            arrow:markHit(st)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            self.particles:createHitSpark(stx, sty, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(stx, sty - st:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = st:takeDamage(dmg, ax, ay, arrow.knockback)

                            if died then
                                self.particles:createExplosion(stx, sty, {0.3, 1, 0.3})
                                self.screenShake:add(6, 0.25)
                                -- MCM: 5x XP!
                                local baseXP = 35 + math.random(0, 15)
                                local xpValue = st.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(stx, sty, xpValue)
                                -- Also grant rarity charge
                                if st.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), 2)
                                end
                            else
                                self.screenShake:add(2, 0.1)
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

            -- Check Wizards (MCM)
            if not hitEnemy then
                for _, wiz in ipairs(self.wizards) do
                    if wiz.isAlive then
                        local wx, wy = wiz:getPosition()
                        local dx = ax - wx
                        local dy = ay - wy
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < wiz:getSize() + arrow:getSize() and arrow:canHit(wiz) then
                            arrow:markHit(wiz)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            self.particles:createHitSpark(wx, wy, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(wx, wy - wiz:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = wiz:takeDamage(dmg, ax, ay, arrow.knockback)

                            if died then
                                self.particles:createExplosion(wx, wy, {0.7, 0.4, 1})
                                self.screenShake:add(6, 0.25)
                                -- MCM: 5x XP!
                                local baseXP = 30 + math.random(0, 15)
                                local xpValue = wiz.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(wx, wy, xpValue)
                                -- Also grant rarity charge
                                if wiz.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), 2)
                                end
                            else
                                self.screenShake:add(2, 0.1)
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
            
            if hitEnemy or arrow:isExpired() then
                table.remove(self.arrows, i)
            end
        end

        -- Build Frenzy charge from "being in combat" (simple: any living enemies)
        if not self.frenzyActive then
            local inCombat = false
            for _, e in ipairs(self.enemies) do if e.isAlive then inCombat = true break end end
            if not inCombat then
                for _, e in ipairs(self.lungers) do if e.isAlive then inCombat = true break end end
            end
            if inCombat then
                self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + (self.frenzyCombatGainPerSec * dt))
            end
        end

        -- Sync Frenzy charge to HUD ability object
        if self.player and self.player.abilities and self.player.abilities.frenzy then
            self.player.abilities.frenzy.charge = math.floor(self.frenzyCharge)
            self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax
        end
        
        -- Update trees (for swaying animation)
        for i, tree in ipairs(self.trees) do
            tree:update(dt)
        end
        
        -- Update bushes
        for i, bush in ipairs(self.bushes) do
            bush:update(dt)
        end
        
        -- Update enemies
        for i, enemy in ipairs(self.enemies) do
            if enemy.isAlive then
                enemy:update(dt, playerX, playerY)
                
                -- Check collision with player
                if not self.isDashing then
                    local ex, ey = enemy:getPosition()
                    local dx = playerX - ex
                    local dy = playerY - ey
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < self.player:getSize() + enemy:getSize() then
                        local damage = (enemy.damage or 10) * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit and self.playerStats then
                            self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(4, 0.15)
                        end
                    end
                end
            end
        end
        
        -- Update lungers
        for i, lunger in ipairs(self.lungers) do
            if lunger.isAlive then
                lunger:update(dt, playerX, playerY)
                
                if not self.isDashing then
                    local lx, ly = lunger:getPosition()
                    local dx = playerX - lx
                    local dy = playerY - ly
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < self.player:getSize() + lunger:getSize() then
                        local damage = lunger:getDamage()
                        if lunger:isLunging() then
                            damage = damage * 1.5
                        end
                        damage = damage * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit and self.playerStats then
                            self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(6, 0.2)
                        end
                    end
                end
            end
        end

        -- Update treents
        for _, treent in ipairs(self.treents) do
            if treent.isAlive then
                treent:update(dt, playerX, playerY)

                if not self.isDashing then
                    local tx, ty = treent:getPosition()
                    local dx = playerX - tx
                    local dy = playerY - ty
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + treent:getSize() then
                        local damage = (treent.damage or 18) * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit and self.playerStats then
                            self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(7, 0.22)
                        end
                    end
                end
            end
        end

        -- Update Small Treents (MCM - Bark Thrower)
        for _, st in ipairs(self.smallTreents) do
            if st.isAlive then
                local onShoot = function(sx, sy, tx, ty)
                    local bark = BarkProjectile:new(sx, sy, tx, ty)
                    table.insert(self.barkProjectiles, bark)
                end
                st:update(dt, playerX, playerY, onShoot)

                if not self.isDashing then
                    local stx, sty = st:getPosition()
                    local dx = playerX - stx
                    local dy = playerY - sty
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + st:getSize() then
                        local damage = (st.damage or 12) * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit and self.playerStats then
                            self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(5, 0.18)
                        end
                    end
                end
            end
        end

        -- Update Wizards (MCM - Root Caster)
        for _, wiz in ipairs(self.wizards) do
            if wiz.isAlive then
                local onConeAttack = function(wx, wy, angleToPlayer, coneAngle, coneRange, rootDur)
                    -- Check if player is in cone
                    local pdx = playerX - wx
                    local pdy = playerY - wy
                    local distToPlayer = math.sqrt(pdx * pdx + pdy * pdy)
                    if distToPlayer < coneRange then
                        local angleToP = math.atan2(pdy, pdx)
                        local angleDiff = math.abs(((angleToP - angleToPlayer + math.pi) % (2 * math.pi)) - math.pi)
                        if angleDiff < coneAngle / 2 then
                            -- Player hit by cone: root them
                            if self.player.applyRoot then
                                self.player:applyRoot(rootDur)
                            end
                            -- Also deal damage
                            local coneDmg = 15 * self.difficultyMult.enemyDamageMult
                            if self.frenzyActive then coneDmg = coneDmg * 1.15 end
                            self.player:takeDamage(coneDmg)
                            self.screenShake:add(4, 0.15)
                            -- Visual feedback
                            self.particles:createExplosion(playerX, playerY, {0.8, 0.3, 1})
                        end
                    end
                end
                wiz:update(dt, playerX, playerY, onConeAttack)

                if not self.isDashing then
                    local wx, wy = wiz:getPosition()
                    local dx = playerX - wx
                    local dy = playerY - wy
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + wiz:getSize() then
                        local damage = (wiz.damage or 10) * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit and self.playerStats then
                            self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(4, 0.15)
                        end
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
                -- Check collision with player
                local bx, by = bark:getPosition()
                local dx = playerX - bx
                local dy = playerY - by
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < self.player:getSize() + bark:getSize() and not self.isDashing then
                    local barkDmg = bark.damage * self.difficultyMult.enemyDamageMult
                    if self.frenzyActive then barkDmg = barkDmg * 1.15 end
                    self.player:takeDamage(barkDmg)
                    if not self.player:isInvincible() then
                        self.screenShake:add(3, 0.12)
                    end
                    table.remove(self.barkProjectiles, i)
                end
            end
        end
        
        -- Check if all enemies dead - advance floor
        local allDead = true
        for _, enemy in ipairs(self.enemies) do
            if enemy.isAlive then allDead = false break end
        end
        for _, lunger in ipairs(self.lungers) do
            if lunger.isAlive then allDead = false break end
        end
        for _, treent in ipairs(self.treents) do
            if treent.isAlive then allDead = false break end
        end
        for _, st in ipairs(self.smallTreents) do
            if st.isAlive then allDead = false break end
        end
        for _, wiz in ipairs(self.wizards) do
            if wiz.isAlive then allDead = false break end
        end
        
        if allDead then
            self:advanceFloor()
        end
    end
end

function GameScene:advanceFloor()
    local continued = self.gameState:nextFloor()
    if continued then
        -- Heal player slightly between floors
        self.player.health = math.min(self.player.maxHealth, self.player.health + 20)
        -- Spawn new enemies
        self:spawnEnemies()
        -- Reset arrows
        self.arrows = {}
    end
end

function GameScene:showUpgradeSelection()
    if not self.xpSystem:hasPendingLevelUp() then return end
    
    -- Consume the level-up
    self.xpSystem:consumeLevelUp()
    
    -- Roll upgrade options
    local result = UpgradeRoll.rollOptions({
        rng = function() return love.math.random() end,
        now = love.timer.getTime(),
        player = self.player,
        classUpgrades = ArcherUpgrades.list,
        abilityPaths = AbilityPaths,
        rarityCharge = self.rarityCharge,
        count = 3,
    })
    
    -- Show the upgrade UI
    self.upgradeUI:show(result.options, function(upgrade)
        -- Apply the selected upgrade
        self.playerStats:applyUpgrade(upgrade)
        
        -- Apply stat changes to player entity
        self:applyStatsToPlayer()
        
        print("Selected upgrade: " .. upgrade.name .. " (" .. upgrade.rarity .. ")")
    end)
end

function GameScene:applyStatsToPlayer()
    if not self.player or not self.playerStats then return end
    
    -- Update player with computed stats
    self.player.attackDamage = self.playerStats:get("primary_damage")
    self.player.speed = self.playerStats:get("move_speed")
    self.attackRange = self.playerStats:get("range")
    
    -- Attack speed affects fire rate (higher = faster)
    local attackSpeed = self.playerStats:get("attack_speed")
    self.fireRate = 0.4 / attackSpeed  -- Base 0.4s cooldown, modified by attack speed
    
    -- TODO: Apply weapon mods like pierce, ricochet, etc.
end

function GameScene:draw()
    -- Apply screen shake
    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw forest tilemap background (grass, flowers, rocks)
    if self.forestTilemap then
        self.forestTilemap:draw()
    else
        self.tilemap:draw()
    end
    
    -- Collect all drawable entities for Y-sorting
    local drawables = {}
    
    -- Add forest tilemap bushes
    if self.forestTilemap then
        for _, bush in ipairs(self.forestTilemap:getBushesForSorting()) do
            table.insert(drawables, {drawFunc = bush.draw, y = bush.y, type = "forest_bush"})
        end
    end
    
    -- Add forest tilemap trees
    if self.forestTilemap then
        for _, tree in ipairs(self.forestTilemap:getTreesForSorting()) do
            table.insert(drawables, {drawFunc = tree.draw, y = tree.y, type = "forest_tree"})
        end
    end
    
    -- Add old-style bushes (if any remain)
    for _, bush in ipairs(self.bushes) do
        table.insert(drawables, {entity = bush, y = bush.y, type = "bush"})
    end
    
    -- Add old-style trees (if any remain)
    for _, tree in ipairs(self.trees) do
        table.insert(drawables, {entity = tree, y = tree.y, type = "tree"})
    end
    
    -- Add enemies
    for _, enemy in ipairs(self.enemies) do
        if enemy.isAlive then
            table.insert(drawables, {entity = enemy, y = enemy.y, type = "enemy"})
        end
    end
    
    -- Add lungers
    for _, lunger in ipairs(self.lungers) do
        if lunger.isAlive then
            table.insert(drawables, {entity = lunger, y = lunger.y, type = "lunger"})
        end
    end

    -- Add treents
    for _, treent in ipairs(self.treents) do
        if treent.isAlive then
            table.insert(drawables, {entity = treent, y = treent.y, type = "treent"})
        end
    end

    -- Add Small Treents (MCM)
    for _, st in ipairs(self.smallTreents) do
        if st.isAlive then
            table.insert(drawables, {entity = st, y = st.y, type = "small_treent"})
        end
    end

    -- Add Wizards (MCM)
    for _, wiz in ipairs(self.wizards) do
        if wiz.isAlive then
            table.insert(drawables, {entity = wiz, y = wiz.y, type = "wizard"})
        end
    end
    
    -- Add player
    if self.player then
        table.insert(drawables, {entity = self.player, y = self.player.y, type = "player", isDashing = self.isDashing})
    end
    
    -- Sort by Y position (entities with lower Y are drawn first, appearing behind)
    table.sort(drawables, function(a, b)
        return a.y < b.y
    end)
    
    -- Draw all entities in Y-sorted order
    for _, drawable in ipairs(drawables) do
        if drawable.type == "player" and drawable.isDashing then
            love.graphics.setColor(1, 1, 1, 0.3)
        end
        
        -- Draw using function or entity method
        if drawable.drawFunc then
            drawable.drawFunc()
        elseif drawable.entity then
            drawable.entity:draw()
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw arrows (always on top of entities)
    for _, arrow in ipairs(self.arrows) do
        arrow:draw()
    end

    -- Draw bark projectiles
    for _, bark in ipairs(self.barkProjectiles) do
        bark:draw()
    end

    -- Draw floating damage numbers in world space
    if self.damageNumbers then
        self.damageNumbers:draw()
    end
    
    -- Draw XP orbs
    if self.xpSystem then
        self.xpSystem:draw()
    end
    
    -- Draw particles (on top of everything)
    self.particles:draw()
    
    love.graphics.pop()
    
    -- Draw HUD (not affected by screen shake)
    self:drawXPBar()
    
    -- Draw upgrade UI (on top of everything)
    if self.upgradeUI then
        self.upgradeUI:draw()
    end
end

function GameScene:drawXPBar()
    local screenWidth = love.graphics.getWidth()
    
    -- XP bar at top of screen
    local barWidth = 300
    local barHeight = 12
    local barX = (screenWidth - barWidth) / 2
    local barY = 10
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4, 4, 4)
    
    -- XP progress
    local progress = self.xpSystem:getProgress()
    love.graphics.setColor(0.3, 0.7, 1, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight, 2, 2)
    
    -- Border
    love.graphics.setColor(0.5, 0.7, 1, 0.8)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 2, 2)
    
    -- Level indicator
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local levelText = "Lv " .. self.xpSystem.level
    local textWidth = font:getWidth(levelText)
    love.graphics.print(levelText, barX - textWidth - 10, barY - 1)
    
    -- Rarity charges indicator (if any)
    local charges = self.rarityCharge:getCharges()
    if charges > 0 then
        love.graphics.setColor(1, 0.8, 0.2, 1)
        local chargeText = "★" .. charges
        love.graphics.print(chargeText, barX + barWidth + 10, barY - 1)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:keypressed(key)
    -- Handle upgrade UI input first
    if self.upgradeUI and self.upgradeUI:isVisible() then
        -- Always swallow gameplay inputs while the modal is open
        self.upgradeUI:keypressed(key)
        return true
    end

    -- Stats overlay (Tab)
    if key == "tab" and self.statsOverlay then
        self.statsOverlay:toggle()
        return true
    end
    if self.statsOverlay and self.statsOverlay:isVisible() then
        if key == "up" then
            self.statsOverlay:scroll(-1, #(self.playerStats:getUpgradeLog() or {}))
            return true
        elseif key == "down" then
            self.statsOverlay:scroll(1, #(self.playerStats:getUpgradeLog() or {}))
            return true
        end
    end

    -- Ultimate (Frenzy) is user-activated
    if key == "r" and self.playerStats and (not self.frenzyActive) and self.frenzyCharge >= self.frenzyChargeMax then
        self.frenzyCharge = self.frenzyCharge - self.frenzyChargeMax
        self.playerStats:addBuff("frenzy", 8.0, {
            { stat = "move_speed", mul = 1.25 },
            { stat = "crit_chance", add = 0.25 },
        }, { break_on_hit_taken = true })
        self.frenzyActive = true
        self.screenShake:add(4, 0.15)
        return true
    end
    
    if key == "space" then
        self:startDash()
    end
end

function GameScene:drawOverlays()
    if self.statsOverlay and self.statsOverlay:isVisible() then
        self.statsOverlay:draw(self.playerStats, self.xpSystem)
    end
end

function GameScene:hasOpenOverlay()
    return (self.statsOverlay and self.statsOverlay:isVisible()) == true
end

function GameScene:mousepressed(x, y, button)
    -- Handle upgrade UI input
    if self.upgradeUI and self.upgradeUI:isVisible() then
        if self.upgradeUI:mousepressed(x, y, button) then
            return true
        end
    end
    return false
end

function GameScene:mousemoved(x, y)
    self.mouseX, self.mouseY = x, y
    -- Handle upgrade UI hover
    if self.upgradeUI then
        self.upgradeUI:mousemoved(x, y)
    end
end

function GameScene:startDash()
    if self.dashCooldown <= 0 and not self.isDashing then
        self.isDashing = true
        self.dashTime = self.dashDuration
        self.dashCooldown = 1.0 -- 1 second cooldown
        
        -- Sync with player ability cooldown for HUD
        if self.player and self.player.abilities and self.player.abilities.dash then
            self.player.abilities.dash.currentCooldown = 1.0
        end
        
        -- Get dash direction from current movement or facing
        local dx, dy = 0, 0
        if love.keyboard.isDown("left", "a") then dx = dx - 1 end
        if love.keyboard.isDown("right", "d") then dx = dx + 1 end
        if love.keyboard.isDown("up", "w") then dy = dy - 1 end
        if love.keyboard.isDown("down", "s") then dy = dy + 1 end
        
        -- Normalize
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then
            self.dashDirX = dx / len
            self.dashDirY = dy / len
        else
            -- Dash in bow direction if not moving
            self.dashDirX = math.cos(self.player:getBowAngle())
            self.dashDirY = math.sin(self.player:getBowAngle())
        end
        
        -- Make player invincible during dash
        self.player.invincibleTime = self.dashDuration
        
        -- Screen effect
        self.screenShake:add(2, 0.1)
    end
end

return GameScene

