-- Game Scene - Main gameplay
local Player = require("entities.player")
local Tree = require("entities.tree")
local Enemy = require("entities.enemy")
local Lunger = require("entities.lunger")
local Treent = require("entities.treent")
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
local StatusEffects = require("systems.status_effects")
local ProcEngine = require("systems.proc_engine")

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

        -- Proc engine + combat tracking
        procEngine = nil,
        wasHitThisFrame = false,
        ghostQuiverTimer = 0, -- remaining duration of Ghost Quiver buff

        -- Hit-freeze (brief game pause on impact for juice)
        hitFreezeTime = 0,
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
    self.procEngine = ProcEngine:new()
    
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
    
    -- More enemies on higher floors
    local numEnemies = 2 + math.floor(floor / 2)
    local numLungers = 1 + math.floor(floor / 4)
    local numTreents = math.floor(floor / 3)
    
    self.enemies = {}
    self.lungers = {}
    self.treents = {}
    
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
    
    -- Spawn lungers
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

    -- Hit-freeze: brief pause on big impacts for juice
    if self.hitFreezeTime > 0 then
        self.hitFreezeTime = self.hitFreezeTime - dt
        return -- Skip this frame entirely
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

    -- Tick ghost quiver
    if self.ghostQuiverTimer > 0 then
        self.ghostQuiverTimer = self.ghostQuiverTimer - dt
    end

    -- Tick status effects on all enemies (bleed DoT, duration expiry)
    self.wasHitThisFrame = false
    for _, list in ipairs(self:getAllEnemyLists()) do
        for _, e in ipairs(list) do
            if e.isAlive then
                local ticks = StatusEffects.update(e, dt)
                for _, tick in ipairs(ticks) do
                    if tick.entity.isAlive then
                        local died = tick.entity:takeDamage(tick.damage, nil, nil, 0)
                        local ex, ey = tick.entity:getPosition()
                        if self.damageNumbers then
                            self.damageNumbers:add(ex, ey - tick.entity:getSize(), tick.damage, { isCrit = false, color = {0.8, 0.2, 0.2} })
                        end
                        self.particles:createBleedDrip(ex, ey)
                        if died then
                            self.particles:createExplosion(ex, ey, {0.8, 0.1, 0.1})
                            self.screenShake:add(3, 0.12)
                            self.xpSystem:spawnOrb(ex, ey, 8 + math.random(0, 5))
                            -- Check hemorrhage proc on bleed-kill
                            local killActions = self.procEngine:onKill(self.playerStats, { isCrit = false, target = tick.entity })
                            for _, action in ipairs(killActions) do
                                self:executeAction(action)
                            end
                        end
                    end
                end
            end
        end
    end
    
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
        
        -- Aim at nearest enemy for bow presentation + primary targeting
        if nearestEnemy then
            local ex, ey = nearestEnemy:getPosition()
            self.player:aimAt(ex, ey)
            
            if self.fireCooldown <= 0 and not self.isDashing then
                -- Create primary projectile (auto-target)
                local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
                local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY

                -- Ricochet params from weapon mods
                local ricBounces = (self.playerStats and self.playerStats.weaponMods.ricochet_bounces) or 0
                local ricRange = (self.playerStats and self.playerStats.weaponMods.ricochet_range) or 220

                -- Ghost quiver: infinite pierce on primary while active
                local isGhosting = self.ghostQuiverTimer > 0

                local arrow = Arrow:new(sx, sy, ex, ey, {
                    damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140,
                    ricochetBounces = ricBounces, ricochetRange = ricRange,
                    ghosting = isGhosting,
                })
                table.insert(self.arrows, arrow)

                -- Bonus projectiles from weapon mods
                local bonusProj = (self.playerStats and self.playerStats:getWeaponMod("bonus_projectiles")) or 0

                -- Check proc-on-fire actions (every_n_primary_shots)
                if self.procEngine then
                    local fireActions = self.procEngine:onPrimaryFired(self.playerStats)
                    for _, action in ipairs(fireActions) do
                        local a = action.apply
                        if a and a.kind == "weapon_mod" and a.mod == "bonus_projectiles" then
                            bonusProj = bonusProj + (a.value or 0)
                        elseif a and a.kind == "aoe_projectile_burst" then
                            self:spawnArrowstorm(a.count or 12, a.damage_mul or 0.40, a.speed_mul or 0.90)
                        else
                            self:executeAction(action)
                        end
                    end
                end

                if bonusProj > 0 then
                    local spreadDeg = (self.playerStats and self.playerStats.weaponMods.projectile_spread) or 10
                    local spreadRad = math.rad(spreadDeg)
                    local baseAngle = math.atan2(ey - sy, ex - sx)
                    for p = 1, bonusProj do
                        local offset = spreadRad * p * (p % 2 == 0 and 1 or -1)
                        local bx = sx + math.cos(baseAngle + offset) * 10
                        local by = sy + math.sin(baseAngle + offset) * 10
                        local tx = sx + math.cos(baseAngle + offset) * 300
                        local ty = sy + math.sin(baseAngle + offset) * 300
                        local bonusArrow = Arrow:new(bx, by, tx, ty, {
                            damage = baseDmg * 0.7,
                            pierce = pierce,
                            kind = "primary",
                            knockback = 100,
                            ricochetBounces = ricBounces, ricochetRange = ricRange,
                            ghosting = isGhosting,
                        })
                        table.insert(self.arrows, bonusArrow)
                    end
                end

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
            local baseDmgMul = 3.0
            if self.playerStats then
                baseDmgMul = self.playerStats:getAbilityValue("power_shot", "damage_mul", baseDmgMul)
            end
            local base = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * baseDmgMul
            local psRange = 1.0
            if self.playerStats then
                psRange = self.playerStats:getAbilityValue("power_shot", "range_mul", psRange)
            end
            local ps = Arrow:new(sx, sy, ex, ey, {
                damage = base,
                speed = 760,
                size = 12,
                lifetime = 1.8 * psRange,
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
            -- Apply radius_add ability mod
            if self.playerStats then
                entangleRange = self.playerStats:getAbilityValue("entangle", "radius_add", entangleRange)
            end
            local best, bestDist = nil, entangleRange
            local function considerTarget(t, bonus)
                if t.isBoss then return end -- Entangle does NOT affect bosses
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
            for _, treent in ipairs(self.treents) do
                if treent.isAlive then considerTarget(treent, 0) end
            end
            if best and best.applyRoot then
                self.player:useAbility("entangle")
                local dur = (best.state ~= nil) and 1.0 or 1.8
                -- Apply damage_taken_mul from Thorned Bind
                local rootDmgMul = 1.15
                if self.playerStats then
                    rootDmgMul = self.playerStats:getAbilityValue("entangle", "damage_taken_mul", rootDmgMul)
                end
                best:applyRoot(dur, rootDmgMul)
                local tx, ty = best:getPosition()
                self.particles:createRootBurst(tx, ty)
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
            
            -- Unified collision check against all enemy lists
            local allEnemyData = {
                { list = self.enemies,  deathColor = {1, 0.3, 0.1}, deathShake = {5, 0.2},  xpBase = 15, xpRand = 10, killGainBonus = 0, kbScale = 1.0 },
                { list = self.lungers,  deathColor = {0.8, 0.3, 0.8}, deathShake = {6, 0.25}, xpBase = 25, xpRand = 15, killGainBonus = 5, kbScale = 1.0, isMCM = true, mcmCharge = 2 },
                { list = self.treents,  deathColor = {0.2, 0.9, 0.2}, deathShake = {8, 0.3},  xpBase = 60, xpRand = 25, killGainBonus = 8, kbScale = 0.75 },
            }
            for _, group in ipairs(allEnemyData) do
                if hitEnemy then break end
                for _, enemy in ipairs(group.list) do
                    if enemy.isAlive then
                        local ex2, ey2 = enemy:getPosition()
                        local dx2 = ax - ex2
                        local dy2 = ay - ey2
                        local distance2 = math.sqrt(dx2 * dx2 + dy2 * dy2)

                        if distance2 < enemy:getSize() + arrow:getSize() and arrow:canHit(enemy) then
                            arrow:markHit(enemy)

                            -- Apply per-hit conditional procs (Marked Prey damage, Tactical Spacing, etc.)
                            local hitDmgMul = 1.0
                            if self.procEngine then
                                local hitActions = self.procEngine:onHit(self.playerStats, {
                                    isCrit = false, -- set after roll below
                                    target = enemy,
                                    arrow = arrow,
                                    playerX = playerX,
                                    playerY = playerY,
                                    maxRange = self.attackRange,
                                })
                                -- We'll re-run after we know isCrit; for now collect conditional dmg boosts
                                for _, ha in ipairs(hitActions) do
                                    if ha.conditional and ha.apply and ha.apply.kind == "stat_mul" and ha.apply.stat == "primary_damage" then
                                        hitDmgMul = hitDmgMul * (ha.apply.value or 1)
                                    end
                                end
                            end

                            local dmg, isCrit = rollDamage(arrow.damage * hitDmgMul, arrow.alwaysCrit)
                            self.particles:createHitSpark(ex2, ey2, isCrit and {1, 1, 0.2} or {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(ex2, ey2 - enemy:getSize(), dmg, { isCrit = isCrit })
                            end

                            local kbForce = arrow.knockback and (arrow.knockback * group.kbScale) or nil
                            local died = enemy:takeDamage(dmg, ax, ay, kbForce)

                            -- On-hit procs (status apply, chain damage, etc.)
                            if self.procEngine then
                                local hitActions = self.procEngine:onHit(self.playerStats, {
                                    isCrit = isCrit,
                                    target = enemy,
                                    arrow = arrow,
                                    playerX = playerX,
                                    playerY = playerY,
                                    maxRange = self.attackRange,
                                })
                                for _, ha in ipairs(hitActions) do
                                    if not ha.conditional then
                                        self:executeAction(ha)
                                    end
                                end
                            end

                            if died then
                                self.particles:createExplosion(ex2, ey2, group.deathColor)
                                self.screenShake:add(group.deathShake[1], group.deathShake[2])
                                self:hitFreeze(isCrit and 0.045 or 0.03)

                                local xpValue = group.xpBase + math.random(0, group.xpRand)
                                self.xpSystem:spawnOrb(ex2, ey2, xpValue)

                                if enemy.isMCM or group.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), group.mcmCharge or 1)
                                end

                                -- Frenzy charge on kill
                                if not self.frenzyActive then
                                    local killGain = self.frenzyKillGain + (group.killGainBonus or 0)
                                    if self.playerStats then
                                        killGain = self.playerStats:getAbilityValue("frenzy", "charge_gain_mul", killGain)
                                    end
                                    self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + killGain)
                                end

                                -- On-kill procs (hemorrhage, crit-kill buffs)
                                if self.procEngine then
                                    local killActions = self.procEngine:onKill(self.playerStats, { isCrit = isCrit, target = enemy })
                                    for _, ka in ipairs(killActions) do
                                        self:executeAction(ka)
                                    end
                                end
                            else
                                self.screenShake:add(2, 0.1)
                            end

                            -- Ricochet: redirect arrow to nearest un-hit enemy
                            if not died or arrow.ricochetBounces > 0 then
                                if arrow.ricochetBounces > 0 then
                                    local nextTarget = self:findNearestEnemyTo(ex2, ey2, arrow.ricochetRange, arrow.hit)
                                    if nextTarget then
                                        local ntx, nty = nextTarget:getPosition()
                                        arrow:bounceToward(ntx, nty)
                                        -- Don't consume the arrow - it bounced
                                        hitEnemy = false
                                        break
                                    end
                                end
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

        -- Evaluate passive/conditional procs each frame
        if self.procEngine and self.playerStats then
            local passiveActions = self.procEngine:updatePassive(dt, self.playerStats, {
                enemyLists = self:getAllEnemyLists(),
                playerX = playerX,
                playerY = playerY,
                wasFiring = self.procEngine.isFiring,
                wasHit = self.wasHitThisFrame,
            })
            for _, action in ipairs(passiveActions) do
                self:executeAction(action)
            end
        end
        
        -- Update trees (for swaying animation)
        for i, tree in ipairs(self.trees) do
            tree:update(dt)
        end
        
        -- Update bushes
        for i, bush in ipairs(self.bushes) do
            bush:update(dt)
        end
        
        -- Update and collide all enemies with player
        local enemyUpdateData = {
            { list = self.enemies, getDmg = function(e) return (e.damage or 10) end, shake = {4, 0.15} },
            { list = self.lungers, getDmg = function(e) local d = e:getDamage(); if e:isLunging() then d = d * 1.5 end; return d end, shake = {6, 0.2} },
            { list = self.treents, getDmg = function(e) return (e.damage or 18) end, shake = {7, 0.22} },
        }
        for _, group in ipairs(enemyUpdateData) do
            for _, enemy in ipairs(group.list) do
                if enemy.isAlive then
                    enemy:update(dt, playerX, playerY)

                    if not self.isDashing then
                        local ex2, ey2 = enemy:getPosition()
                        local dx2 = playerX - ex2
                        local dy2 = playerY - ey2
                        local distance2 = math.sqrt(dx2 * dx2 + dy2 * dy2)
                        if distance2 < self.player:getSize() + enemy:getSize() then
                            local damage = group.getDmg(enemy) * self.difficultyMult.enemyDamageMult
                            if self.frenzyActive then damage = damage * 1.15 end
                            local before = self.player.health
                            self.player:takeDamage(damage)
                            local wasHit = self.player.health < before
                            if wasHit then
                                self.wasHitThisFrame = true
                                if self.playerStats then
                                    self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                                end
                                if self.procEngine then
                                    self.procEngine.noDamageTakenTime = 0
                                end
                            end
                            if not self.player:isInvincible() then
                                self.screenShake:add(group.shake[1], group.shake[2])
                            end
                        end
                    end
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

    -- Apply ability mods to player ability cooldowns
    if self.player.abilities then
        -- Power Shot cooldown mods
        local basePSCooldown = 6.0
        basePSCooldown = self.playerStats:getAbilityValue("power_shot", "cooldown_add", basePSCooldown)
        basePSCooldown = self.playerStats:getAbilityValue("power_shot", "cooldown_mul", basePSCooldown)
        self.player.abilities.power_shot.cooldown = math.max(1.0, basePSCooldown)

        -- Entangle cooldown mods
        local baseEntCooldown = 8.0
        baseEntCooldown = self.playerStats:getAbilityValue("entangle", "cooldown_add", baseEntCooldown)
        baseEntCooldown = self.playerStats:getAbilityValue("entangle", "cooldown_mul", baseEntCooldown)
        self.player.abilities.entangle.cooldown = math.max(1.0, baseEntCooldown)

        -- Roll cooldown from stats
        local rollCD = self.playerStats:get("roll_cooldown")
        self.player.abilities.dash.cooldown = math.max(0.3, rollCD)
    end
end

---------------------------------------------------------------------------
-- HELPER: hit-freeze (brief game pause for impact feel)
---------------------------------------------------------------------------
function GameScene:hitFreeze(duration)
    self.hitFreezeTime = math.max(self.hitFreezeTime, duration or 0.035)
end

---------------------------------------------------------------------------
-- HELPER: get all enemy lists for iteration
---------------------------------------------------------------------------
function GameScene:getAllEnemyLists()
    return { self.enemies, self.lungers, self.treents }
end

---------------------------------------------------------------------------
-- HELPER: find nearest living enemy to a point, optionally excluding a set
---------------------------------------------------------------------------
function GameScene:findNearestEnemyTo(x, y, maxRange, excludeSet)
    local best, bestDist = nil, maxRange
    for _, list in ipairs(self:getAllEnemyLists()) do
        for _, e in ipairs(list) do
            if e.isAlive and (not excludeSet or not excludeSet[e]) then
                local ex, ey = e:getPosition()
                local dx = ex - x
                local dy = ey - y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < bestDist then
                    best = e
                    bestDist = d
                end
            end
        end
    end
    return best, bestDist
end

---------------------------------------------------------------------------
-- HELPER: deal damage to all enemies within radius of a point
---------------------------------------------------------------------------
function GameScene:aoeDamage(cx, cy, radius, damage)
    for _, list in ipairs(self:getAllEnemyLists()) do
        for _, e in ipairs(list) do
            if e.isAlive then
                local ex, ey = e:getPosition()
                local dx = ex - cx
                local dy = ey - cy
                if math.sqrt(dx * dx + dy * dy) <= radius then
                    local died = e:takeDamage(damage, cx, cy, 80)
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - e:getSize(), damage, { isCrit = false })
                    end
                    if died then
                        self.particles:createExplosion(ex, ey, {1, 0.5, 0.1})
                        self.screenShake:add(4, 0.15)
                        local xpValue = 10 + math.random(0, 5)
                        self.xpSystem:spawnOrb(ex, ey, xpValue)
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- HELPER: chain damage (lightning jumps from a starting enemy)
---------------------------------------------------------------------------
function GameScene:chainDamage(startEnemy, jumps, jumpRange, damage)
    local current = startEnemy
    local hit = { [startEnemy] = true }
    for i = 1, jumps do
        local cx, cy = current:getPosition()
        local next = self:findNearestEnemyTo(cx, cy, jumpRange, hit)
        if not next then break end
        hit[next] = true
        local nx, ny = next:getPosition()
        -- Lightning arc VFX between current and next target
        self.particles:createLightningArc(cx, cy, nx, ny, {0.4, 0.6, 1.0})
        if self.damageNumbers then
            self.damageNumbers:add(nx, ny - next:getSize(), damage, { isCrit = false })
        end
        local died = next:takeDamage(damage, cx, cy, 60)
        if died then
            self.particles:createExplosion(nx, ny, {0.3, 0.5, 1.0})
            self.screenShake:add(3, 0.12)
            self.xpSystem:spawnOrb(nx, ny, 10 + math.random(0, 5))
        end
        current = next
    end
    -- Flash + freeze for chain lightning
    self:hitFreeze(0.03)
    if _G.triggerScreenFlash then
        _G.triggerScreenFlash({0.5, 0.7, 1.0, 0.25}, 0.08)
    end
end

---------------------------------------------------------------------------
-- HELPER: spawn arrowstorm (radial burst of arrows from player)
---------------------------------------------------------------------------
function GameScene:spawnArrowstorm(count, damageMul, speedMul)
    if not self.player then return end
    local px, py = self.player:getPosition()
    local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * damageMul
    local baseSpeed = 500 * speedMul
    local angleStep = (math.pi * 2) / count
    for i = 1, count do
        local angle = angleStep * i
        local tx = px + math.cos(angle) * 300
        local ty = py + math.sin(angle) * 300
        local arrow = Arrow:new(px, py, tx, ty, {
            damage = baseDmg,
            speed = baseSpeed,
            kind = "arrowstorm",
            pierce = 1,
            knockback = 80,
            lifetime = 1.5,
        })
        table.insert(self.arrows, arrow)
    end
    self.screenShake:add(5, 0.18)
    self.particles:createAoeRing(px, py, 60, {1, 0.9, 0.3})
    self.particles:createExplosion(px, py, {1, 0.85, 0.2})
    self:hitFreeze(0.05)
    if _G.triggerScreenFlash then
        _G.triggerScreenFlash({1, 0.9, 0.3, 0.3}, 0.1)
    end
end

---------------------------------------------------------------------------
-- HELPER: hemorrhage explosion (AOE on killing bleeding target)
---------------------------------------------------------------------------
function GameScene:hemorrhageExplosion(target, damageMultOfMaxHP, radius)
    local tx, ty = target:getPosition()
    local damage = (target.maxHealth or 50) * damageMultOfMaxHP
    self:aoeDamage(tx, ty, radius, damage)
    -- Hemorrhage VFX: expanding blood ring + explosion
    self.particles:createAoeRing(tx, ty, radius, {0.9, 0.1, 0.05})
    self.particles:createExplosion(tx, ty, {0.8, 0.1, 0.1})
    self.screenShake:add(6, 0.2)
    self:hitFreeze(0.06)
    if _G.triggerScreenFlash then
        _G.triggerScreenFlash({0.9, 0.1, 0.05, 0.35}, 0.12)
    end
end

---------------------------------------------------------------------------
-- HELPER: execute a single proc action
---------------------------------------------------------------------------
function GameScene:executeAction(action)
    local apply = action.apply
    if not apply then return end

    if apply.kind == "status_apply" then
        if action.target and action.target.isAlive then
            StatusEffects.apply(action.target, apply.status, apply.stacks, apply.duration)
        end

    elseif apply.kind == "chain_damage" then
        if action.target and action.target.isAlive then
            local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
            local chainDmg = baseDmg * (apply.damage_mul or 0.35)
            self:chainDamage(action.target, apply.jumps or 2, apply.range or 180, chainDmg)
        end

    elseif apply.kind == "aoe_projectile_burst" then
        self:spawnArrowstorm(apply.count or 12, apply.damage_mul or 0.40, apply.speed_mul or 0.90)

    elseif apply.kind == "aoe_explosion" then
        if action.target then
            self:hemorrhageExplosion(action.target, apply.damage_mul_of_target_maxhp or 0.06, apply.radius or 90)
        end

    elseif apply.kind == "buff" then
        if self.playerStats then
            local name = apply.name or "unnamed_buff"
            -- Check rules
            local rules = apply.rules or {}
            if rules.disabled_during_frenzy and self.frenzyActive then return end
            if rules.no_stack_in_frenzy and self.frenzyActive and self.playerStats:hasBuff(name) then return end
            self.playerStats:addBuff(name, apply.duration or 5.0, apply.stats or {}, rules)
        end

    elseif apply.kind == "stat_mul" then
        -- Per-hit conditional stat boost - apply as a very short buff
        if action.conditional and self.playerStats then
            -- These are frame-conditional, managed by passive update
        end

    elseif apply.kind == "weapon_mod" then
        -- Temporary weapon mod (e.g. bonus_projectiles from every_n proc)
        -- Handled by the firing code checking proc actions
    end
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

        -- Apply ability mods to Frenzy parameters
        local frenzyDuration = self.playerStats:getAbilityValue("frenzy", "duration_add", 8.0)
        local frenzyMoveMul = self.playerStats:getAbilityValue("frenzy", "move_speed_mul", 1.25)
        local frenzyCritAdd = self.playerStats:getAbilityValue("frenzy", "crit_chance_add", 0.25)

        self.playerStats:addBuff("frenzy", frenzyDuration, {
            { stat = "move_speed", mul = frenzyMoveMul },
            { stat = "crit_chance", add = frenzyCritAdd },
        }, { break_on_hit_taken = true })
        self.frenzyActive = true
        self.screenShake:add(4, 0.15)
        -- Frenzy VFX
        if self.player then
            local px, py = self.player:getPosition()
            self.particles:createFrenzyBurst(px, py)
        end
        self:hitFreeze(0.06)
        if _G.triggerScreenFlash then
            _G.triggerScreenFlash({1, 0.5, 0.1, 0.35}, 0.15)
        end
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

        -- Trigger after_roll procs (Ghost Quiver, Phase Roll: Focused)
        if self.procEngine and self.playerStats then
            local rollActions = self.procEngine:onRoll(self.playerStats)
            for _, action in ipairs(rollActions) do
                local a = action.apply
                if a and a.kind == "buff" and a.name == "ghost_quiver" then
                    -- Ghost Quiver: grant infinite pierce on primary arrows
                    self.ghostQuiverTimer = a.duration or 1.25
                end
                self:executeAction(action)
            end
        end
    end
end

return GameScene

