-- Game Scene - Main gameplay
local Player = require("entities.player")
local Tree = require("entities.tree")
local Enemy = require("entities.enemy")
local Lunger = require("entities.lunger")
local Treent = require("entities.treent")
local Slime = require("entities.slime")
local Bat = require("entities.bat")
local Skeleton = require("entities.skeleton")
local Imp = require("entities.imp")
local Wolf = require("entities.wolf")
local Wizard = require("entities.wizard")
local Healer = require("entities.healer")
local DruidTreent = require("entities.druid_treent")
local SmallTreent = require("entities.small_treent")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")
local ArrowVolley = require("entities.arrow_volley")
local FirePatch = require("entities.fire_patch")
local EnemySpawner = require("systems.enemy_spawner")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local Camera = require("systems.camera")
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
local ObstacleNav = require("systems.obstacle_navigation")
local SpellbladeRuntime = require("systems.spellblade_runtime")
local Config = require("data.config")
local BossPortal = require("entities.boss_portal")
local Core = require("entities.core")
local TreasureChest = require("entities.treasure_chest")

-- Load upgrade data
local ArcherUpgrades = require("data.upgrades_archer")
local AbilityPaths = require("data.ability_paths_archer")
local SpellbladeUpgrades = require("data.upgrades_spellblade")

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
        slimes = {},
        bats = {},
        skeletons = {},
        imps = {},
        wolves = {},
        smallTreents = {},
        wizards = {},
        healers = {},
        druidTreents = {},
        barkProjectiles = {},
        enemySpawner = nil,
        fireCooldown = 0,
        -- Dash ability (from config)
        dashCooldown = 0,
        dashDuration = Config.Player.dashDuration or 0.2,
        dashSpeed = Config.Player.dashSpeed or 800,
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
        pauseMenuVisible = false,
        pauseMenuIndex = 1,
        pauseSettingsVisible = false,
        pauseSettingsIndex = 1,
        statsOverlay = nil,
        damageNumbers = nil,

        -- Mouse tracking for manual-aim abilities
        mouseX = 0,
        mouseY = 0,

        -- Frenzy ultimate (charge-based)
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        frenzyActive = false,
        frenzyAuraTimer = 0,
        frenzyCombatGainPerSec = 3.5,
        frenzyKillGain = 10,

        -- Proc engine + combat tracking
        procEngine = nil,
        wasHitThisFrame = false,
        ghostQuiverTimer = 0, -- remaining duration of Ghost Quiver buff

        -- Hit-freeze (brief game pause on impact for juice)
        hitFreezeTime = 0,

        -- Arrow Volley (falling-arrow impact zones)
        arrowVolleys = {},
        firePatches = {},
        bossPortal = nil,
        bossPortalSpawned = false,

        -- Major progression bar (fills from kills + cores → boss portal)
        majorProgress = 0,
        majorProgressMax = 70,

        -- Cores objective (starts at 25% major progress)
        cores = {},
        coresTotal = 20,
        coresDestroyed = 0,
        coreObjectiveTimer = 0,
        coreObjectiveTimeLimit = 180, -- 3 minutes
        coreObjectiveComplete = false,
        coreObjectiveRewardGiven = false,
        coreObjectiveStarted = false,
        coreObjectiveStartPct = 0.25,
        coreObjectivePopupTimer = 0, -- popup display duration when objective starts
        coreObjectiveFailed = false,
        coreObjectiveFailPopupTimer = 0, -- popup when timer expires
        rewardChest = nil,
        xpMagnetDropChance = 0.025,
        spellblade = nil,

        -- Progress per event
        majorProgressPerKill = 0.35,
        majorProgressPerCore = 0.0,
        majorProgressPerCoreBonus = 5.6, -- 8% of the current 70-point boss bar
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
    
    -- Initialize player with class stats (spawn at world center)
    local worldW = Config.World and Config.World.width or screenWidth
    local worldH = Config.World and Config.World.height or screenHeight
    self.player = Player:new(worldW / 2, worldH / 2)
    self.mouseX, self.mouseY = worldW / 2, worldH / 2
    
    if heroClass then
        self.player.maxHealth = heroClass.baseHP
        self.player.health = heroClass.baseHP
        self.player.speed = heroClass.baseSpeed
        self.player.attackDamage = heroClass.baseATK
        self.player.attackRange = heroClass.attackRange
        self.player.attackSpeed = heroClass.attackSpeed
        self.player.heroClass = heroClass.id
    end

    if heroClass and heroClass.id == "spellblade" then
        self.spellblade = SpellbladeRuntime:new()
        self.spellblade:setupPlayer(self.player)
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
    
    -- Initialize camera (follows player, clamped to world bounds)
    local worldW = Config.World and Config.World.width or 2400
    local worldH = Config.World and Config.World.height or 1600
    self.camera = Camera:new(0, 0, worldW, worldH)
    if Config.World and Config.World.camera then
        self.camera.zoom = Config.World.camera.zoom or 1.0
        self.camera.followBiasY = Config.World.camera.followBiasY or 0
    end
    -- Snap camera to player spawn immediately (no lerp on first frame)
    do
        local viewW, viewH = self.camera:getViewportSize()
        local camX = math.max(0, math.min(self.player.x - viewW / 2, worldW - viewW))
        local camY = math.max(0, math.min(self.player.y - viewH / 2 + (self.camera.followBiasY or 0), worldH - viewH))
        self.camera:setPosition(camX, camY)
    end
    
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
    
    -- Set ability unlock states for class loadout
    if self.player and self.player.abilities and self.player.heroClass ~= "spellblade" then
        self.player.abilities.multi_shot.unlocked = true
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
    
    -- Continuous spawning
    self.enemySpawner = EnemySpawner:new(self)
    
    -- Apply stats (including 15% cooldown reduction) at run start
    self:applyStatsToPlayer()

    -- Run state for HUD (top bar)
    self.gameState.runTimer = 0
    self.gameState.runCurrency = 0

    -- Cores spawn when major progress reaches 25% (see addMajorProgress)
end

function GameScene:spawnEnemies()
    -- Clear all enemy lists
    self.enemies = {}
    self.lungers = {}
    self.treents = {}
    self.slimes = {}
    self.bats = {}
    self.skeletons = {}
    self.imps = {}
    self.wolves = {}
    self.smallTreents = {}
    self.wizards = {}
    self.healers = {}
    self.druidTreents = {}

    -- Initial enemies are now handled entirely by the EnemySpawner
    -- (no pre-placed lungers/treents)
    if self.enemySpawner then
        self.enemySpawner:syncCountFromScene()
    end
end

function GameScene:despawnCores()
    for _, core in ipairs(self.cores) do
        if core.isAlive then
            core.isAlive = false
        end
    end
    self.cores = {}
end

function GameScene:spawnCores()
    self.cores = {}
    self.coresDestroyed = 0
    self.coreObjectiveTimer = 0
    self.coreObjectiveComplete = false
    self.coreObjectiveRewardGiven = false
    self.coreObjectiveFailed = false
    self.rewardChest = nil
    local worldW = Config.World and Config.World.width or 2400
    local worldH = Config.World and Config.World.height or 1600
    local margin = 120
    local blockers = self:getMovementBlockers()

    for i = 1, self.coresTotal do
        local placed = false
        for attempt = 1, 30 do
            local cx = margin + math.random() * (worldW - margin * 2)
            local cy = margin + math.random() * (worldH - margin * 2)
            local blocked = false
            for _, blk in ipairs(blockers) do
                local dx = cx - blk.x
                local dy = cy - blk.y
                if math.sqrt(dx * dx + dy * dy) < (blk.radius or 30) + 30 then
                    blocked = true
                    break
                end
            end
            if not blocked then
                table.insert(self.cores, Core:new(cx, cy, { health = 60, majorProgress = self.majorProgressPerCore }))
                placed = true
                break
            end
        end
        if not placed then
            local cx = margin + math.random() * (worldW - margin * 2)
            local cy = margin + math.random() * (worldH - margin * 2)
            table.insert(self.cores, Core:new(cx, cy, { health = 60, majorProgress = self.majorProgressPerCore }))
        end
    end
end

function GameScene:getEnemyHpMultiplier()
    local cfg = Config.enemy_hp_scaling or {}
    if cfg.enabled == false then
        return (self.difficultyMult or {}).enemyHealthMult or 1
    end
    local base = (self.difficultyMult or {}).enemyHealthMult or 1
    local levelMult = 1
    if self.xpSystem and cfg.level_factor then
        levelMult = 1 + (self.xpSystem.level - 1) * cfg.level_factor
        levelMult = math.max(1, levelMult)
    end
    local floorMult = 1
    if self.gameState and self.gameState.currentFloor and cfg.floor_factor then
        floorMult = 1 + self.gameState.currentFloor * cfg.floor_factor
        floorMult = math.max(1, floorMult)
    end
    local timeMult = 1
    if self.enemySpawner and cfg.time_cap then
        timeMult = math.min(cfg.time_cap or 2.5, self.enemySpawner.difficulty_multiplier or 1)
    end
    return base * levelMult * floorMult * timeMult
end

function GameScene:applyEnemyScale(entity)
    if not entity or not entity.size then
        return
    end

    local scale = (Config.World and Config.World.enemyScale) or 1.0
    if scale ~= 1.0 then
        entity.size = entity.size * scale
    end
end

function GameScene:getMovementBlockers()
    if not self.forestTilemap then
        return {}
    end
    if self.forestTilemap.getCollisionBlockers then
        return self.forestTilemap:getCollisionBlockers()
    end
    return self.forestTilemap:getLargeBlockers()
end

function GameScene:spawnEnemyXpDrop(x, y, value)
    if not self.xpSystem then
        return
    end

    self.xpSystem:spawnOrb(x, y, value)
    if self.xpSystem.spawnMagnet and math.random() < (self.xpMagnetDropChance or 0) then
        self.xpSystem:spawnMagnet(x, y)
    end
end

function GameScene:spawnEnemy(enemy_type, x, y)
    local mult = self.difficultyMult or { enemyHealthMult = 1, enemyDamageMult = 1 }
    local hpMult = self:getEnemyHpMultiplier()
    local speedScale = 1.12 * ((Config.World and Config.World.enemyMoveSpeedScale) or 1.0)
    local entity
    
    if enemy_type == "slime" then
        entity = Slime:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = 8 * mult.enemyDamageMult
        entity.speed = (entity.speed or 30) * speedScale
        table.insert(self.slimes, entity)
    elseif enemy_type == "bat" then
        entity = Bat:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = 6 * mult.enemyDamageMult
        entity.speed = (entity.speed or 70) * speedScale
        table.insert(self.bats, entity)
    elseif enemy_type == "skeleton" then
        entity = Skeleton:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = 10 * mult.enemyDamageMult
        entity.speed = (entity.speed or 55) * speedScale
        table.insert(self.skeletons, entity)
    elseif enemy_type == "wolf" then
        entity = Wolf:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = (entity.damage or 12) * mult.enemyDamageMult
        entity.speed = (entity.speed or 80) * speedScale
        table.insert(self.wolves, entity)
    elseif enemy_type == "lunger" then
        entity = Lunger:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.speed = (entity.speed or 30) * speedScale
        entity.lungeSpeed = (entity.lungeSpeed or 500) * speedScale
        table.insert(self.lungers, entity)
    elseif enemy_type == "small_treent" then
        entity = SmallTreent:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = (entity.damage or 9) * mult.enemyDamageMult
        entity.speed = (entity.speed or 70) * speedScale
        table.insert(self.smallTreents, entity)
    elseif enemy_type == "wizard" then
        entity = Wizard:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = (entity.damage or 10) * mult.enemyDamageMult
        entity.speed = (entity.speed or 45) * speedScale
        table.insert(self.wizards, entity)
    elseif enemy_type == "treent" then
        entity = Treent:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = (entity.damage or 18) * mult.enemyDamageMult
        entity.speed = (entity.speed or 28) * speedScale
        table.insert(self.treents, entity)
    elseif enemy_type == "healer" then
        entity = Healer:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.speed = (entity.speed or 60) * speedScale
        table.insert(self.healers, entity)
    elseif enemy_type == "druid_treent" then
        entity = DruidTreent:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = (entity.damage or 8) * mult.enemyDamageMult
        entity.speed = (entity.speed or 50) * speedScale
        table.insert(self.druidTreents, entity)
    else
        -- Fallback to slime (enemy/imp removed from roster)
        entity = Slime:new(x, y)
        self:applyEnemyScale(entity)
        entity.health = entity.health * hpMult
        entity.maxHealth = entity.health
        entity.damage = 8 * mult.enemyDamageMult
        entity.speed = (entity.speed or 30) * speedScale
        table.insert(self.slimes, entity)
    end
end

function GameScene:update(dt)
    -- Update upgrade UI (always, even when paused)
    if self.upgradeUI then
        self.upgradeUI:update(dt)
    end

    -- Keep forest ambience/particles moving even during modal pauses.
    if self.forestTilemap and self.forestTilemap.update then
        self.forestTilemap:update(dt)
    end

    -- Pause gameplay while stats overlay is open
    self.isPaused = ((self.statsOverlay and self.statsOverlay:isVisible()) or false) or self.pauseMenuVisible
    
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
    
    -- Continuous enemy spawning
    if self.enemySpawner then
        self.enemySpawner:update(dt)
    end
    
    -- Update XP orbs
    if self.xpSystem and self.player then
        local pickupRadius = self.playerStats and self.playerStats:get("xp_pickup_radius") or 63
        self.xpSystem:update(dt, self.player.x, self.player.y, pickupRadius)
    end

    -- Update core objective timer
    if self.coreObjectiveStarted and not self.coreObjectiveComplete and not self.coreObjectiveFailed then
        self.coreObjectiveTimer = self.coreObjectiveTimer + dt
        -- Timer expired: despawn cores, mark failed, show popup
        if self.coreObjectiveTimer >= self.coreObjectiveTimeLimit then
            self.coreObjectiveFailed = true
            self.coreObjectiveComplete = true
            self:despawnCores()
            self.coreObjectiveFailPopupTimer = 3.0
            if _G.audio then _G.audio:playSFX("hit_heavy") end
        end
    end

    -- Update core objective popup (fade-out display when objective starts)
    if self.coreObjectivePopupTimer and self.coreObjectivePopupTimer > 0 then
        self.coreObjectivePopupTimer = self.coreObjectivePopupTimer - dt
    end
    if self.coreObjectiveFailPopupTimer and self.coreObjectiveFailPopupTimer > 0 then
        self.coreObjectiveFailPopupTimer = self.coreObjectiveFailPopupTimer - dt
    end

    -- Run timer for top bar
    if self.gameState then
        self.gameState.runTimer = (self.gameState.runTimer or 0) + dt
    end

    -- Update cores
    for _, core in ipairs(self.cores) do
        if core.isAlive then
            core:update(dt)
        end
    end

    if self.rewardChest and self.rewardChest.isAlive then
        self.rewardChest:update(dt)
    end

    -- Major progression bar → boss portal at 100%
    if self.majorProgress >= self.majorProgressMax and not self.bossPortalSpawned and self.player then
        self.bossPortal = BossPortal:new(self.player.x + 150, self.player.y)
        self.bossPortalSpawned = true
        if _G.audio then _G.audio:playSFX("portal_open") end
    end

    -- Update boss portal and check activation
    if self.bossPortal and self.player then
        self.bossPortal:update(dt, self.player)
        if self.bossPortal:canActivate(self.player) and self.bossPortal:activate() then
            if _G.audio then _G.audio:playSFX("portal_open") end
            self.gameState:enterBossFight()
        end
    end
    
    -- Update player stats (tick buff durations)
    if self.playerStats then
        -- Keep frenzy flag in sync with buff presence
        self.frenzyActive = self.playerStats:hasBuff("frenzy")
        if self.player then
            self.player.isFrenzyActive = self.frenzyActive
        end
        -- Emit frenzy aura particles periodically
        if self.frenzyActive and self.player then
            self.frenzyAuraTimer = (self.frenzyAuraTimer or 0) - dt
            if self.frenzyAuraTimer <= 0 then
                local px, py = self.player:getPosition()
                self.particles:createFrenzyAura(px, py)
                self.frenzyAuraTimer = 0.08
            end
        end

        -- Always-on HP regen
        if self.player and not self.player:isDead() then
            local regen = self.playerStats:get("hp_regen_per_sec") or 0
            if regen > 0 then
                self.player.health = math.min(self.player.maxHealth, self.player.health + regen * dt)
            end
        end

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
                local bleedBase = 2
                local burnBase = 2
                if self.playerStats then
                    burnBase = burnBase * (self.playerStats:getElementMod("fire", "burn_damage_mul", 1.0) or 1.0)
                end
                local ticks, expiredChillEntity = StatusEffects.update(e, dt, bleedBase, burnBase)
                -- Ice attunement: chill expiry triggers ice burst at entity position
                if expiredChillEntity and self.playerStats and self.playerStats.activePrimaryElement == "ice" then
                    local ex, ey = expiredChillEntity:getPosition()
                    self:iceDissolveBlast(ex, ey)
                end
                for _, tick in ipairs(ticks) do
                    if tick.entity.isAlive then
                        local died = tick.entity:takeDamage(tick.damage, nil, nil, 0)
                        self:applyFrenzyLifesteal(tick.damage)
                        local ex, ey = tick.entity:getPosition()
                        if self.damageNumbers then
                            local dmgColor = (tick.status == "burn") and {1.0, 0.5, 0.1} or {0.8, 0.2, 0.2}
                            self.damageNumbers:add(ex, ey - tick.entity:getSize(), tick.damage, { isCrit = false, color = dmgColor })
                        end
                        if tick.status == "burn" then
                            self.particles:createBurnFlare(ex, ey - tick.entity:getSize() * 0.2, 1.0 + StatusEffects.getStacks(tick.entity, "burn") * 0.18)
                        else
                            self.particles:createBleedDrip(ex, ey)
                        end
                        if died then
                            if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                            self.particles:createExplosion(ex, ey, {0.8, 0.1, 0.1})
                            self.screenShake:add(3, 0.12)
                            self:spawnEnemyXpDrop(ex, ey, 8 + math.random(0, 5))
                            self:addMajorProgress(self.majorProgressPerKill)
                            self:triggerKillActions(tick.entity, false)
                        end
                    end
                end
            end
        end
    end
    
    -- Update camera to follow player
    if self.camera and self.player then
        self.camera:update(dt, self.player.x, self.player.y)
    end
    
    -- Update player
    if self.player then
        self.player.isDashing = self.isDashing
        if self.isDashing then
            self.player:update(dt)
            self.dashTime = self.dashTime - dt
            if self.dashTime <= 0 then
                self.isDashing = false
            else
                self.player.x = self.player.x + self.dashDirX * self.dashSpeed * dt
                self.player.y = self.player.y + self.dashDirY * self.dashSpeed * dt
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            self.player:update(dt)
        end
        self:resolvePlayerBlockers()

        local playerX, playerY = self.player:getPosition()

        if self.spellblade and self.spellblade:isActive(self.player) then
            self.player.activeElement = nil
            self.spellblade:update(self, dt)
        else
            -- Drive bow attunement VFX from current element
            self.player.activeElement = self.playerStats and self.playerStats.activePrimaryElement or nil

            -- Find nearest enemy for targeting (all types)
            local nearestEnemy, nearestDistance = self:findNearestPriorityTargetTo(playerX, playerY, self.attackRange)

            -- Aim bow at nearest enemy for presentation + primary targeting
            if nearestEnemy then
                local ex, ey = nearestEnemy:getPosition()
                self.player:aimAt(ex, ey)

                if self.fireCooldown <= 0 and not self.isDashing then
                    local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
                    local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                    local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY

                    local ricBounces = (self.playerStats and self.playerStats.weaponMods.ricochet_bounces) or 0
                    local ricRange = (self.playerStats and self.playerStats.weaponMods.ricochet_range) or 220
                    local isGhosting = self.ghostQuiverTimer > 0
                    local activeElement = self.playerStats and self.playerStats.activePrimaryElement or nil

                    local arrow = Arrow:new(sx, sy, ex, ey, {
                        damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140,
                        ricochetBounces = ricBounces, ricochetRange = ricRange,
                        ghosting = isGhosting,
                        iceAttuned = activeElement == "ice",
                        element = activeElement,
                    })
                    table.insert(self.arrows, arrow)
                    if _G.audio then _G.audio:playSFX("shoot_arrow") end
                    if self.player.playAttackAnimation then self.player:playAttackAnimation() end

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
                                iceAttuned = activeElement == "ice",
                                element = activeElement,
                            })
                            table.insert(self.arrows, bonusArrow)
                            if _G.audio then _G.audio:playSFX("shoot_arrow") end
                        end
                    end

                    self.fireCooldown = self.fireRate
                    if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
                end
            end

            -- Multi Shot (Q): auto-cast at nearest enemy when off cooldown
            if self.player and self.player:isAbilityReady("multi_shot") and not self.isDashing then
                local msTarget = self:findNearestPriorityTargetTo(playerX, playerY, self.attackRange)
                if msTarget then
                    local tx, ty = msTarget:getPosition()
                    self:fireMultiShot(tx, ty)
                end
            end

            -- Entangle (Arrow Volley): ground circle AOE at nearest enemy (2s falling-arrows field)
            if self.player and self.player:isAbilityReady("entangle") and not self.isDashing then
                local px, py = playerX, playerY
                local entangleRange = 260
                if self.playerStats then
                    entangleRange = entangleRange + (self.playerStats:getAbilityValue("entangle", "range_add", 0) or 0)
                end
                local target = self:findBestClusterTarget(px, py, entangleRange)
                if target then
                    self.player:useAbility("entangle")
                    local tx, ty = target:getPosition()
                    self.player:aimAt(tx, ty)

                    local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * 0.35
                    if self.playerStats then
                        baseDmg = baseDmg * self.playerStats:getAbilityValue("entangle", "damage_mul", 1.0)
                    end
                    local duration = 2.0
                    local tickInterval = 0.15
                    local numTicks = math.ceil(duration / tickInterval)
                    local totalDamage = baseDmg * numTicks
                    local extraZones = self.playerStats and self.playerStats:getAbilityValue("entangle", "extra_zone_add", 0) or 0
                    local arrowCountAdd = self.playerStats and self.playerStats:getAbilityValue("entangle", "arrow_count_add", 0) or 0
                    local doubleVolley = self.playerStats and self.playerStats:getAbilityMod("entangle", "double_volley")
                    local volleyLine = self.playerStats and self.playerStats:getAbilityMod("entangle", "volley_line")

                    if volleyLine then
                        -- Volley Line: 3 smaller circles in vertical line OOO
                        local lineRadius, lineDamage = 40, totalDamage * 0.6
                        for _, oy in ipairs({ ty - 60, ty, ty + 60 }) do
                            local volley = ArrowVolley:new(tx, oy, lineDamage, lineRadius, arrowCountAdd)
                            table.insert(self.arrowVolleys, volley)
                        end
                    else
                        local volleyCount = (doubleVolley and 2 or 1) + extraZones
                        for z = 0, volleyCount - 1 do
                            local ox, oy = tx, ty
                            if z == 1 and doubleVolley then
                                ox, oy = tx + 35, ty
                            elseif z > (doubleVolley and 1 or 0) then
                                local angle = (z - (doubleVolley and 2 or 1)) * (math.pi * 2 / math.max(1, extraZones)) + math.random() * 0.5
                                ox = tx + math.cos(angle) * 110
                                oy = ty + math.sin(angle) * 110
                            end
                            local volley = ArrowVolley:new(ox, oy, totalDamage, 80, arrowCountAdd)
                            table.insert(self.arrowVolleys, volley)
                        end
                    end

                    if _G.audio then _G.audio:playSFX("shoot_arrow") end
                    self.particles:createRootBurst(px, py)
                    self.particles:createCastBurst(tx, ty, {0.95, 0.38, 0.24}, 1.0)
                    self.screenShake:add(3, 0.12)
                    self:hitFreeze(0.04)
                    if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
                    if _G.triggerScreenFlash then
                        _G.triggerScreenFlash({0.8, 0.2, 0.2, 0.2}, 0.08)
                    end
                end
            end
        end

        -- Frenzy is USER-ACTIVATED (press R). We only build charge here.
        
        -- Update arrows
        local arrowBlockers = self.forestTilemap and self.forestTilemap:getLargeBlockers() or {}
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            arrow:update(dt)
            
            local ax, ay = arrow:getPosition()
            local hitEnemy = false

            -- Projectile LOS: block arrows that hit terrain
            if #arrowBlockers > 0 and ObstacleNav.isPointBlocked(ax, ay, arrow:getSize() or 10, arrowBlockers) then
                self.particles:createHitSpark(ax, ay, {0.6, 0.6, 0.5})
                table.remove(self.arrows, i)
                goto continue_arrow
            end

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
                { list = self.enemies,   deathColor = {1, 0.3, 0.1}, deathShake = {5, 0.2},  xpBase = 15, xpRand = 10, killGainBonus = 0, kbScale = 1.0 },
                { list = self.lungers,   deathColor = {0.8, 0.3, 0.8}, deathShake = {6, 0.25}, xpBase = 25, xpRand = 15, killGainBonus = 5, kbScale = 1.0, isMCM = true, mcmCharge = 2 },
                { list = self.treents,  deathColor = {0.5, 0.4, 0.3}, deathShake = {8, 0.3},  xpBase = 60, xpRand = 25, killGainBonus = 8, kbScale = 0.75 },
                { list = self.slimes,   deathColor = {0.35, 0.6, 0.4}, deathShake = {5, 0.2},  xpBase = 18, xpRand = 6, killGainBonus = 0, kbScale = 0.7 },
                { list = self.bats,     deathColor = {0.5, 0.4, 0.6}, deathShake = {4, 0.15}, xpBase = 12, xpRand = 6, killGainBonus = 0, kbScale = 1.0 },
                { list = self.skeletons, deathColor = {0.7, 0.7, 0.8}, deathShake = {5, 0.18}, xpBase = 14, xpRand = 8, killGainBonus = 0, kbScale = 1.0 },
                { list = self.imps,     deathColor = {0.9, 0.2, 0.2}, deathShake = {4, 0.15}, xpBase = 16, xpRand = 6, killGainBonus = 0, kbScale = 1.0 },
                { list = self.wolves,   deathColor = {0.6, 0.5, 0.4}, deathShake = {5, 0.2},  xpBase = 35, xpRand = 12, killGainBonus = 0, kbScale = 1.0 },
                { list = self.smallTreents, deathColor = {0.45, 0.38, 0.28}, deathShake = {6, 0.22}, xpBase = 45, xpRand = 18, killGainBonus = 5, kbScale = 0.8, isMCM = true, mcmCharge = 2 },
                { list = self.wizards,  deathColor = {0.6, 0.3, 0.8}, deathShake = {6, 0.22}, xpBase = 45, xpRand = 18, killGainBonus = 5, kbScale = 0.85, isMCM = true, mcmCharge = 2 },
                { list = self.healers,  deathColor = {0.4, 0.7, 0.5}, deathShake = {4, 0.15}, xpBase = 18, xpRand = 6, killGainBonus = 0, kbScale = 1.0 },
                { list = self.druidTreents, deathColor = {0.48, 0.42, 0.32}, deathShake = {6, 0.22}, xpBase = 60, xpRand = 25, killGainBonus = 8, kbScale = 0.85, isMCM = true, mcmCharge = 2 },
            }
            for _, group in ipairs(allEnemyData) do
                if hitEnemy then break end
                for _, enemy in ipairs(group.list) do
                    if enemy.isAlive then
                        local ex2, ey2 = enemy:getPosition()
                        local dx2 = ax - ex2
                        local dy2 = ay - ey2
                        local sumR = enemy:getSize() + arrow:getSize()
                        if dx2 * dx2 + dy2 * dy2 < sumR * sumR and arrow:canHit(enemy) then
                            arrow:markHit(enemy)

                            -- Apply per-hit conditional procs (Marked Prey damage, Tactical Spacing, etc.)
                            local hitDmgMul = 1.0
                            if self.procEngine then
                                hitDmgMul = self.procEngine:getOnHitDamageMultiplier(self.playerStats, {
                                    target = enemy,
                                    arrow = arrow,
                                    playerX = playerX,
                                    playerY = playerY,
                                    maxRange = self.attackRange,
                                })
                            end

                            local dmg, isCrit = rollDamage(arrow.damage * hitDmgMul, arrow.alwaysCrit)
                            -- Throttle VFX/SFX for piercing arrows (Power Shot) to reduce lag on multi-hit
                            local hitCount = (arrow.cosmeticHitCount or 0) + 1
                            arrow.cosmeticHitCount = hitCount
                            local doCosmetic = hitCount <= 4 or (arrow.kind ~= "multi_shot" and arrow.kind ~= "arrowstorm")
                            if doCosmetic then
                                self.particles:createHitSpark(ex2, ey2, isCrit and {1, 1, 0.2} or {1, 1, 0.6})
                                if _G.audio then
                                    local sfx = math.random() > 0.5 and "hit_light" or "hit_light_alt"
                                    _G.audio:playSFX(sfx, { pitch = isCrit and 1.15 or (0.95 + math.random() * 0.12) })
                                end
                            end

                            local kbForce = arrow.knockback and (arrow.knockback * group.kbScale) or nil
                            local died = enemy:takeDamage(dmg, ax, ay, kbForce)
                            if self.damageNumbers and (doCosmetic or died) then
                                self.damageNumbers:add(ex2, ey2 - enemy:getSize(), dmg, { isCrit = isCrit })
                            end
                            self:applyFrenzyLifesteal(dmg)

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
                                if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                                self.particles:createExplosion(ex2, ey2, group.deathColor)
                                self.screenShake:add(group.deathShake[1], group.deathShake[2])
                                self:hitFreeze(isCrit and 0.045 or 0.03)

                                local xpValue = group.xpBase + math.random(0, group.xpRand)
                                self:spawnEnemyXpDrop(ex2, ey2, xpValue)
                                self:addMajorProgress(self.majorProgressPerKill)

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
                                self:triggerKillActions(enemy, isCrit)
                            elseif doCosmetic then
                                self.screenShake:add(2, 0.1)
                            end

                            -- Ricochet: redirect arrow to nearest un-hit enemy
                            if not died or arrow.ricochetBounces > 0 then
                                if arrow.ricochetBounces > 0 then
                                    local nextTarget = self:findNearestPriorityTargetTo(ex2, ey2, arrow.ricochetRange, arrow.hit)
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
                -- Ice attunement: dissolve blast on expire (primary arrows only)
                if arrow.iceAttuned and arrow.kind == "primary" and arrow:isExpired() then
                    self:iceDissolveBlast(ax, ay)
                end
                table.remove(self.arrows, i)
            end
            ::continue_arrow::
        end

        -- Update Arrow Volleys (impact-timed damage, remove when finished)
        for i = #self.arrowVolleys, 1, -1 do
            local volley = self.arrowVolleys[i]
            volley:update(dt)
            if volley:shouldApplyDamage() then
                local dmg = volley:getDamage()
                local vx, vy = volley:getPosition()
                local radius = volley:getDamageRadius()
                for _, list in ipairs(self:getAllEnemyLists()) do
                    for _, enemy in ipairs(list) do
                        if enemy.isAlive then
                            local ex, ey = enemy:getPosition()
                            local dx = ex - vx
                            local dy = ey - vy
                            if dx * dx + dy * dy <= radius * radius then
                                local died = enemy:takeDamage(dmg, vx, vy, nil)
                                self:applyFrenzyLifesteal(dmg)
                                if self.damageNumbers then
                                    self.damageNumbers:add(ex, ey - (enemy.getSize and enemy:getSize() or 16), dmg, { isCrit = false })
                                end
                                -- Explosion Volley: apply burn on hit
                                if self.playerStats and self.playerStats:getAbilityMod("entangle", "explosion_volley") then
                                    StatusEffects.apply(enemy, "burn", 1, 2.5)
                                end
                                if died then
                                    if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                                    self:spawnEnemyXpDrop(ex, ey, 12 + math.random(0, 8))
                                    self:addMajorProgress(self.majorProgressPerKill)
                                    self:triggerKillActions(enemy, false)
                                end
                            end
                        end
                    end
                end

                for _, target in ipairs(self:getObjectiveTargets(true)) do
                    if target.isAlive then
                        local tx, ty = target:getPosition()
                        local dx = tx - vx
                        local dy = ty - vy
                        if dx * dx + dy * dy <= radius * radius then
                            self:damageObjectiveTarget(target, dmg, vx, vy)
                        end
                    end
                end
            end
            if volley:isFinished() then
                table.remove(self.arrowVolleys, i)
            end
        end

        -- Objective collision with arrows (cores + reward chest)
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            if arrow then
                local ax, ay = arrow:getPosition()
                for _, target in ipairs(self:getObjectiveTargets(true)) do
                    if target.isAlive then
                        local tx, ty = target:getPosition()
                        local dx = ax - tx
                        local dy = ay - ty
                        local sumR = target:getSize() + arrow:getSize()
                        if dx * dx + dy * dy < sumR * sumR and arrow:canHit(target) then
                            arrow:markHit(target)
                            self:damageObjectiveTarget(target, arrow.damage or 10, ax, ay)
                            if not arrow:consumePierce() then
                                table.remove(self.arrows, i)
                                break
                            end
                        end
                    end
                end
            end
        end

        self:updateWildfireSpread(dt)
        self:updateFirePatches(dt)

        -- Build Frenzy charge from "being in combat" (simple: any living enemies)
        if not self.frenzyActive then
            local inCombat = false
            for _, list in ipairs(self:getAllEnemyLists()) do
                for _, e in ipairs(list) do
                    if e.isAlive then inCombat = true break end
                end
                if inCombat then break end
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
        
        -- Wizard cone callback: damage only, no root (per AGENTS.md)
        local function onWizardCone(wx, wy, angleToPlayer, coneAngle, coneRange, rootDuration)
            if not self.player or not self.player.getPosition then return end
            local px, py = self.player:getPosition()
            local dx = px - wx
            local dy = py - wy
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > coneRange then return end
            local angleToP = math.atan2(dy, dx)
            local angleDiff = math.abs(angleToP - angleToPlayer)
            while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
            if math.abs(angleDiff) <= coneAngle / 2 then
                local dmg = 12 * self.difficultyMult.enemyDamageMult
                if self.frenzyActive then dmg = dmg * 1.15 end
                self.player:takeDamage(dmg)
                self.wasHitThisFrame = true
                if self.playerStats then self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive }) end
            end
        end
        -- Small treent bark callback
        local function onSmallTreentShoot(sx, sy, tx, ty)
            local bark = BarkProjectile:new(sx, sy, tx, ty, 180)
            bark.damage = 9 * (self.difficultyMult.enemyDamageMult or 1)
            table.insert(self.barkProjectiles, bark)
        end
        
        -- Update and collide all enemies with player
        local blockers = self:getMovementBlockers()
        local enemyUpdateData = {
            { list = self.enemies,      getDmg = function(e) return (e.damage or 10) end, shake = {4, 0.15}, melee = true },
            { list = self.lungers,      getDmg = function(e) local d = e.getDamage and e:getDamage() or e.damage or 15; if e.isLunging and e:isLunging() then d = d * 1.5 end; return d end, shake = {6, 0.2}, melee = true },
            { list = self.treents,      getDmg = function(e) return (e.damage or 18) end, shake = {7, 0.22}, melee = true },
            { list = self.slimes,       getDmg = function(e) return (e.damage or 8) end,  shake = {5, 0.18}, melee = true },
            { list = self.bats,        getDmg = function(e) return (e.damage or 6) end,  shake = {4, 0.14}, melee = true },
            { list = self.skeletons,   getDmg = function(e) return (e.damage or 10) end, shake = {5, 0.16}, melee = true },
            { list = self.imps,        getDmg = function(e) return (e.damage or 12) end, shake = {4, 0.14}, melee = true },
            { list = self.wolves,      getDmg = function(e) return (e.damage or 12) end, shake = {5, 0.18}, melee = true },
            { list = self.smallTreents, getDmg = function(e) return (e.damage or 9) end,  shake = {5, 0.18}, melee = true, updateExtra = function(e) e:update(dt, playerX, playerY, onSmallTreentShoot) end },
            { list = self.wizards,      getDmg = function(e) return (e.damage or 10) end, shake = {5, 0.18}, updateExtra = function(e) e:update(dt, playerX, playerY, onWizardCone) end },
            { list = self.healers,      getDmg = function() return 0 end, shake = {2, 0.1}, updateExtra = function(e) e:update(dt, playerX, playerY, self:getFlattenedEnemies()) end },
            { list = self.druidTreents, getDmg = function(e) return (e.damage or 8) end, shake = {5, 0.18}, melee = true, updateExtra = function(e) e:update(dt, playerX, playerY, self:getFlattenedEnemies()) end },
        }
        for _, group in ipairs(enemyUpdateData) do
            for _, enemy in ipairs(group.list) do
                if enemy.isAlive then
                    local prevX, prevY = enemy:getPosition()
                    if group.updateExtra then
                        group.updateExtra(enemy)
                    else
                        enemy:update(dt, playerX, playerY)
                    end
                    -- Resolve position against large blockers
                    if #blockers > 0 then
                        local ex, ey = enemy:getPosition()
                        local er = enemy:getSize() or 16
                        local nx, ny = ObstacleNav.resolvePosition(ex, ey, er, blockers)
                        enemy.x, enemy.y = nx, ny
                    end
                    -- Melee turn-lock: 0.25s no-attack when reorienting
                    if group.melee then
                        enemy.turnLockRemaining = (enemy.turnLockRemaining or 0) - dt
                        if enemy.turnLockRemaining < 0 then enemy.turnLockRemaining = 0 end
                        local ex, ey = enemy:getPosition()
                        local moveDx = ex - prevX
                        local moveDy = ey - prevY
                        local moveLenSq = moveDx * moveDx + moveDy * moveDy
                        if moveLenSq > 4 then
                            local angle = math.atan2(moveDy, moveDx)
                            local last = enemy.lastFacingAngle
                            if last ~= nil then
                                local diff = angle - last
                                while diff > math.pi do diff = diff - math.pi * 2 end
                                while diff < -math.pi do diff = diff + math.pi * 2 end
                                if math.abs(diff) > math.rad(45) then
                                    enemy.turnLockRemaining = 0.25
                                end
                            end
                            enemy.lastFacingAngle = angle
                        end
                    end

                    if not self.isDashing then
                        local ex2, ey2 = enemy:getPosition()
                        local dx2 = playerX - ex2
                        local dy2 = playerY - ey2
                        local distance2 = math.sqrt(dx2 * dx2 + dy2 * dy2)
                        local turnLocked = group.melee and (enemy.turnLockRemaining or 0) > 0
                        if distance2 < self.player:getSize() + enemy:getSize() and not turnLocked then
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
        
        -- Update bark projectiles (from small treents)
        local barkBlockers = self.forestTilemap and self.forestTilemap:getLargeBlockers() or {}
        for i = #self.barkProjectiles, 1, -1 do
            local bark = self.barkProjectiles[i]
            bark:update(dt)
            if bark:isExpired() then
                table.remove(self.barkProjectiles, i)
            else
                local bx, by = bark:getPosition()
                if #barkBlockers > 0 and ObstacleNav.isPointBlocked(bx, by, bark:getSize() or 8, barkBlockers) then
                    self.particles:createHitSpark(bx, by, {0.5, 0.4, 0.2})
                    table.remove(self.barkProjectiles, i)
                else
                    local dist = math.sqrt((playerX - bx)^2 + (playerY - by)^2)
                    if dist < self.player:getSize() + bark:getSize() and not self.isDashing then
                        local barkDmg = bark.damage or 9
                        if self.frenzyActive then barkDmg = barkDmg * 1.15 end
                        self.player:takeDamage(barkDmg)
                        self.wasHitThisFrame = true
                        if self.playerStats then self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive }) end
                        self.screenShake:add(4, 0.12)
                        table.remove(self.barkProjectiles, i)
                    end
                end
            end
        end
        
        -- Check if all enemies dead - advance floor
        local allDead = true
        for _, list in ipairs(self:getAllEnemyLists()) do
            for _, e in ipairs(list) do
                if e.isAlive then allDead = false break end
            end
            if not allDead then break end
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
        -- Reset arrows and bark projectiles
        self.arrows = {}
        self.barkProjectiles = {}
    end
end

local function hasTag(upgrade, wanted)
    if not upgrade or not upgrade.tags then return false end
    for _, t in ipairs(upgrade.tags) do
        if t == wanted then return true end
    end
    return false
end

-- Core attunements are integral to Archer kit; exempt from strict path gating so they appear early
local CORE_ATTUNEMENT_IDS = {
    arch_c_fire_attunement = true,
    arch_c_ice_attunement = true,
    arch_c_lightning_attunement = true,
}

function GameScene:isCoreAttunement(upgrade)
    return upgrade and upgrade.id and CORE_ATTUNEMENT_IDS[upgrade.id]
end

function GameScene:getBuildPathStage()
    if not self.playerStats then return 0 end
    if self.playerStats:hasUpgrade("arch_c_ice_attunement") then return 4 end
    if self.playerStats:hasUpgrade("arch_c_lightning_attunement") then return 3 end
    if self.playerStats:hasUpgrade("arch_c_fire_attunement") then return 2 end
    return 0
end

function GameScene:getUpgradePathTier(upgrade)
    if not upgrade then return nil end
    if hasTag(upgrade, "bleed") then return 1 end
    if hasTag(upgrade, "element") and hasTag(upgrade, "fire") then return 2 end
    if hasTag(upgrade, "element") and hasTag(upgrade, "lightning") then return 3 end
    if hasTag(upgrade, "element") and hasTag(upgrade, "ice") then return 4 end
    return nil
end

function GameScene:isUtilityUpgrade(upgrade)
    return hasTag(upgrade, "crit") or hasTag(upgrade, "regen")
end

function GameScene:getActiveUpgradePool()
    if self.player and self.player.heroClass == "spellblade" then
        return SpellbladeUpgrades.list, nil
    end
    return ArcherUpgrades.list, AbilityPaths
end

function GameScene:showUpgradeSelection()
    if not self.xpSystem:hasPendingLevelUp() then return end
    
    -- Consume the level-up
    self.xpSystem:consumeLevelUp()
    
    local classUpgrades, abilityPaths = self:getActiveUpgradePool()
    local result
    local nextStage = nil

    if self.player and self.player.heroClass == "spellblade" then
        result = UpgradeRoll.rollOptions({
            rng = function() return love.math.random() end,
            now = love.timer.getTime(),
            player = self.player,
            classUpgrades = classUpgrades,
            abilityPaths = abilityPaths,
            rarityCharge = self.rarityCharge,
            count = 3,
            isAllowed = function(_ctx, upgrade)
                return self:isUpgradeAllowedForRun(upgrade, nil)
            end,
        })
    else
        -- Roll upgrade options with controlled path gating:
        -- bleed -> fire -> lightning -> ice, while crit/regen stays always available.
        local stage = self:getBuildPathStage()
        nextStage = math.min(4, stage + 1)
        local pickBias = {}
        for _, u in ipairs(classUpgrades) do
            if self:isUtilityUpgrade(u) then
                pickBias[u.id] = 1.35
            elseif self:isCoreAttunement(u) then
                pickBias[u.id] = 1.6
            else
                local tier = self:getUpgradePathTier(u)
                if tier == nextStage then
                    pickBias[u.id] = 1.8
                elseif tier and tier < nextStage then
                    pickBias[u.id] = 1.15
                end
            end
        end

        result = UpgradeRoll.rollOptions({
            rng = function() return love.math.random() end,
            now = love.timer.getTime(),
            player = self.player,
            classUpgrades = classUpgrades,
            abilityPaths = abilityPaths,
            rarityCharge = self.rarityCharge,
            count = 3,
            pickBias = pickBias,
            isAllowed = function(_ctx, upgrade)
                return self:isUpgradeAllowedForRun(upgrade, nextStage)
            end,
        })
    end
    
    -- Show the upgrade UI (pass playerStats for current->next preview on repeat picks)
    self.upgradeUI:show(result.options, function(upgrade)
        -- Apply the selected upgrade
        self.playerStats:applyUpgrade(upgrade)
        
        -- Apply stat changes to player entity
        self:applyStatsToPlayer()
        if self.player and self.particles then
            local px, py = self.player:getPosition()
            local rarityColors = {
                common = {0.78, 0.82, 0.9},
                rare = {0.45, 0.82, 1.0},
                epic = {0.7, 0.52, 1.0},
            }
            self.particles:createUpgradeBurst(px, py, rarityColors[upgrade.rarity] or rarityColors.common)
        end
        self.screenShake:add(4, 0.12)
        self:hitFreeze(0.04)
        if _G.triggerScreenFlash then
            _G.triggerScreenFlash({0.65, 0.95, 1.0, 0.22}, 0.1)
        end
        
        print("Selected upgrade: " .. upgrade.name .. " (" .. upgrade.rarity .. ")")
    end, self.playerStats)
end

function GameScene:isUpgradeAllowedForRun(upgrade, nextStage)
    if upgrade.non_repeat and self.playerStats and self.playerStats:hasUpgrade(upgrade.id) then
        return false
    end
    if self.player and self.player.heroClass == "spellblade" then
        if upgrade.requires_upgrade and self.playerStats and not self.playerStats:hasUpgrade(upgrade.requires_upgrade) then
            return false
        end
        return true
    end
    if upgrade.requires_upgrade and self.playerStats then
        if not self.playerStats:hasUpgrade(upgrade.requires_upgrade) then
            return false
        end
    end
    if self:isUtilityUpgrade(upgrade) then
        return true
    end
    if self:isCoreAttunement(upgrade) and self.playerStats then
        local active = self.playerStats.activePrimaryElement
        local elemFor = (upgrade.id == "arch_c_fire_attunement" and "fire")
            or (upgrade.id == "arch_c_ice_attunement" and "ice")
            or (upgrade.id == "arch_c_lightning_attunement" and "lightning")
        if elemFor and active == elemFor then
            return false
        end
        return true
    end
    local tier = self:getUpgradePathTier(upgrade)
    if tier and nextStage and tier > nextStage then
        return false
    end
    return true
end

function GameScene:applyStatsToPlayer()
    if not self.player or not self.playerStats then return end

    if self.spellblade and self.spellblade:isActive(self.player) then
        self.spellblade:applyStats(self)
        return
    end

    -- Update player with computed stats
    self.player.attackDamage = self.playerStats:get("primary_damage")
    local playerMoveScale = (Config.World and Config.World.playerMoveSpeedScale) or 1.0
    self.player.speed = self.playerStats:get("move_speed") * playerMoveScale
    self.attackRange = self.playerStats:get("range")

    -- Attack speed affects fire rate (higher = faster)
    local attackSpeed = self.playerStats:get("attack_speed")
    self.fireRate = 0.4 / attackSpeed  -- Base 0.4s cooldown, modified by attack speed

    -- Apply ability mods to player ability cooldowns (base 15% reduction)
    local baseCDMul = (Config.game_balance and Config.game_balance.player and Config.game_balance.player.base_cooldown_mul) or 0.85
    if self.player.abilities then
        -- Multi Shot cooldown mods
        local baseMSCooldown = 2.25 * baseCDMul
        if self.player.abilities.multi_shot then
            baseMSCooldown = self.playerStats:getAbilityValue("multi_shot", "cooldown_add", baseMSCooldown)
            baseMSCooldown = self.playerStats:getAbilityValue("multi_shot", "cooldown_mul", baseMSCooldown)
            self.player.abilities.multi_shot.cooldown = math.max(0.5, baseMSCooldown)
        end

        -- Entangle cooldown mods
        local baseEntCooldown = 7.2 * baseCDMul
        baseEntCooldown = self.playerStats:getAbilityValue("entangle", "cooldown_add", baseEntCooldown)
        baseEntCooldown = self.playerStats:getAbilityValue("entangle", "cooldown_mul", baseEntCooldown)
        self.player.abilities.entangle.cooldown = math.max(1.0, baseEntCooldown)

        -- Roll cooldown from stats
        local rollCD = self.playerStats:get("roll_cooldown") * baseCDMul
        self.player.abilities.dash.cooldown = math.max(0.3, rollCD)
    end
end

---------------------------------------------------------------------------
-- HELPER: grant core objective reward (rare/epic upgrade card)
---------------------------------------------------------------------------
function GameScene:grantCoreObjectiveReward()
    local classUpgrades = self:getActiveUpgradePool()
    local stage = self:getBuildPathStage()
    local nextStage = math.min(4, stage + 1)
    local rareOnly = {}
    for _, upgrade in ipairs(classUpgrades) do
        if upgrade.rarity == "rare" and self:isUpgradeAllowedForRun(upgrade, self.player and self.player.heroClass == "spellblade" and nil or nextStage) then
            table.insert(rareOnly, upgrade)
        end
    end

    local result = UpgradeRoll.rollOptions({
        rng = function() return love.math.random() end,
        now = love.timer.getTime(),
        player = self.player,
        classUpgrades = rareOnly,
        abilityPaths = nil,
        rarityCharge = nil,
        count = 3,
        minRarity = "rare",
        isAllowed = function(_ctx, upgrade)
            return self:isUpgradeAllowedForRun(upgrade, nextStage)
        end,
    })
    self.upgradeUI:show(result.options, function(upgrade)
        self.playerStats:applyUpgrade(upgrade)
        self:applyStatsToPlayer()
        if self.player and self.particles then
            local px, py = self.player:getPosition()
            local rewardColors = {
                rare = {1.0, 0.82, 0.38},
            }
            self.particles:createUpgradeBurst(px, py, rewardColors[upgrade.rarity] or {1.0, 0.82, 0.38})
        end
        self.screenShake:add(4, 0.12)
        self:hitFreeze(0.04)
        print("Rare Chest Reward: " .. upgrade.name .. " (" .. upgrade.rarity .. ")")
    end, self.playerStats)
end

function GameScene:spawnRewardChest(x, y)
    if self.rewardChest or self.coreObjectiveRewardGiven then
        return
    end
    self.rewardChest = TreasureChest:new(x, y, { health = 100, size = 22 })
    self.particles:createUpgradeBurst(x, y, {1.0, 0.82, 0.34})
    self.screenShake:add(5, 0.16)
    self:hitFreeze(0.05)
    if _G.audio then _G.audio:playSFX("portal_open") end
end

function GameScene:completeCoreObjective(x, y)
    if self.coreObjectiveComplete then
        return
    end
    self.coreObjectiveComplete = true
    if self.coreObjectiveTimer <= self.coreObjectiveTimeLimit then
        self:spawnRewardChest(x, y)
    end
    self:addMajorProgress(self.majorProgressPerCoreBonus)
end

---------------------------------------------------------------------------
-- HELPER: add progress to the major boss progression bar
---------------------------------------------------------------------------
function GameScene:addMajorProgress(amount)
    self.majorProgress = math.min(self.majorProgressMax, self.majorProgress + (amount or 0))

    -- Start core objective when progress crosses 25% threshold
    if not self.coreObjectiveStarted then
        local threshold = self.majorProgressMax * (self.coreObjectiveStartPct or 0.25)
        if self.majorProgress >= threshold then
            self.coreObjectiveStarted = true
            self:spawnCores()
            self.coreObjectivePopupTimer = 3.0
            if _G.audio then _G.audio:playSFX("portal_open") end
            if _G.triggerScreenFlash then
                _G.triggerScreenFlash({0.3, 0.6, 1.0, 0.25}, 0.12)
            end
            if self.screenShake then self.screenShake:add(4, 0.15) end
        end
    end
end

---------------------------------------------------------------------------
-- HELPER: fire Multi Shot (3-arrow cone toward target)
-- targetX/targetY: auto-aim target coords (falls back to mouse if nil)
---------------------------------------------------------------------------
function GameScene:fireMultiShot(targetX, targetY)
    if not self.player or not self.player:isAbilityReady("multi_shot") or self.isDashing then return end
    local cfg = Config.Abilities and Config.Abilities.multiShot or {}
    local arrowCount = cfg.arrowCount or 3
    local baseConeDeg = cfg.coneSpreadDeg or 15
    if self.playerStats then
        baseConeDeg = self.playerStats:getAbilityValue("multi_shot", "cone_spread_add", baseConeDeg)
    end
    local coneSpreadDeg = baseConeDeg * (math.pi / 180)
    local speed = cfg.speed or 500
    local knockback = cfg.knockback or 100

    local px, py = self.player:getPosition()
    local mx, my = targetX or self.mouseX or px, targetY or self.mouseY or py
    local dx = mx - px
    local dy = my - py
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then dist, dx, dy = 1, 1, 0 end
    local baseAngle = math.atan2(dy, dx)

    local sx, sy = self.player.getBowTip and self.player:getBowTip() or px, py
    local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
    if self.playerStats then
        baseDmg = baseDmg * (self.playerStats:getAbilityValue("multi_shot", "damage_mul", 1.0) or 1.0)
    end

    self.player:aimAt(mx, my)
    self.player:useAbility("multi_shot")

    local offsets = {}
    if arrowCount == 1 then
        offsets = { 0 }
    elseif arrowCount == 2 then
        offsets = { -coneSpreadDeg / 2, coneSpreadDeg / 2 }
    else
        local step = coneSpreadDeg / math.max(1, arrowCount - 1)
        for i = 0, arrowCount - 1 do
            offsets[i + 1] = -coneSpreadDeg / 2 + step * i
        end
    end

    for _, off in ipairs(offsets) do
        local a = baseAngle + off
        local tdist = 400
        local tx = sx + math.cos(a) * tdist
        local ty = sy + math.sin(a) * tdist
        local arr = Arrow:new(sx, sy, tx, ty, {
            damage = baseDmg,
            speed = speed,
            size = 10,
            lifetime = 1.5,
            pierce = 0,
            kind = "multi_shot",
            knockback = knockback,
        })
        table.insert(self.arrows, arr)
    end

    if _G.audio then _G.audio:playSFX("shoot_arrow") end
    if self.particles then
        self.particles:createCastBurst(sx, sy, {0.55, 0.82, 1.0}, 0.95)
    end
    if self.player.playAttackAnimation then self.player:playAttackAnimation() end
    self.screenShake:add(2, 0.08)
    if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
end

---------------------------------------------------------------------------
-- HELPER: hit-freeze (brief game pause for impact feel)
---------------------------------------------------------------------------
function GameScene:hitFreeze(duration)
    self.hitFreezeTime = math.max(self.hitFreezeTime, duration or 0.035)
end

---------------------------------------------------------------------------
-- HELPER: apply Frenzy lifesteal from outgoing damage
---------------------------------------------------------------------------
function GameScene:applyFrenzyLifesteal(damageDealt)
    if not self.frenzyActive or not self.player then return end
    if not damageDealt or damageDealt <= 0 then return end
    local lifeSteal = (Config.Abilities and Config.Abilities.frenzy and Config.Abilities.frenzy.lifeSteal) or 0.10
    if lifeSteal <= 0 then return end
    local healAmount = damageDealt * lifeSteal
    self.player.health = math.min(self.player.maxHealth, self.player.health + healAmount)
end

---------------------------------------------------------------------------
-- HELPER: resolve player position against large terrain blockers
---------------------------------------------------------------------------
function GameScene:resolvePlayerBlockers()
    if not self.player or not self.forestTilemap then return end
    local blockers = self:getMovementBlockers()
    if #blockers == 0 then return end
    local px, py = self.player.x, self.player.y
    local pr = self.player.size or 20
    for _, blk in ipairs(blockers) do
        local dx = px - blk.x
        local dy = py - blk.y
        local dist = math.sqrt(dx * dx + dy * dy)
        local minDist = pr + blk.radius
        if dist < minDist and dist > 0 then
            local nx = dx / dist
            local ny = dy / dist
            self.player.x = blk.x + nx * minDist
            self.player.y = blk.y + ny * minDist
            px, py = self.player.x, self.player.y
        end
    end
end

function GameScene:triggerKillActions(target, isCrit)
    if not self.procEngine or not self.playerStats or not target then
        return
    end
    local killActions = self.procEngine:onKill(self.playerStats, { isCrit = isCrit or false, target = target })
    for _, action in ipairs(killActions) do
        self:executeAction(action)
    end
end

function GameScene:spawnFirePatch(x, y, radius, damage, duration, tickInterval)
    self.firePatches[#self.firePatches + 1] = FirePatch:new(x, y, radius, damage, duration, tickInterval)
end

function GameScene:fireDeathExplosion(target, radius, primaryDamageMul)
    if not target then return end
    local tx, ty = target:getPosition()
    local damage = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * (primaryDamageMul or 2.5)
    self:aoeDamage(tx, ty, radius or 92, damage)
    self.particles:createExplosion(tx, ty, {1.0, 0.42, 0.12})
    self.screenShake:add(7, 0.22)
    self:hitFreeze(0.05)
end

function GameScene:updateWildfireSpread(dt)
    if not self.playerStats or self.playerStats.activePrimaryElement ~= "fire" then return end
    if not self.playerStats:getElementMod("fire", "wildfire_enabled", false) then return end

    local all = self:getFlattenedEnemies()
    local spreadDuration = 3.0 * (self.playerStats:getElementMod("fire", "wildfire_duration_mul", 0.5) or 0.5)
    local spreadDamageMul = self.playerStats:getElementMod("fire", "wildfire_damage_mul", 0.5) or 0.5

    for _, source in ipairs(all) do
        if source.isAlive and StatusEffects.has(source, "burn") then
            source._wildfireSpreadCooldown = math.max(0, (source._wildfireSpreadCooldown or 0) - dt)
            if source._wildfireSpreadCooldown <= 0 then
                local sx, sy = source:getPosition()
                local sr = source:getSize()
                for _, other in ipairs(all) do
                    if other ~= source and other.isAlive and not StatusEffects.has(other, "burn") then
                        local ox, oy = other:getPosition()
                        local dx = ox - sx
                        local dy = oy - sy
                        local touchR = sr + other:getSize()
                        if dx * dx + dy * dy <= touchR * touchR then
                            StatusEffects.apply(other, "burn", 1, spreadDuration, { damageMul = spreadDamageMul })
                            source._wildfireSpreadCooldown = 0.18
                            self.particles:createBurnFlare(ox, oy - other:getSize() * 0.2, 0.9)
                            break
                        end
                    end
                end
            end
        end
    end
end

function GameScene:updateFirePatches(dt)
    for i = #self.firePatches, 1, -1 do
        local patch = self.firePatches[i]
        patch:update(dt)
        if patch:isAlive() then
            local px, py = patch.x, patch.y
            for _, list in ipairs(self:getAllEnemyLists()) do
                for _, enemy in ipairs(list) do
                    if enemy.isAlive and patch:canHit(enemy) then
                        local ex, ey = enemy:getPosition()
                        local dx = ex - px
                        local dy = ey - py
                        local r = patch.radius + enemy:getSize()
                        if dx * dx + dy * dy <= r * r then
                            patch:markHit(enemy)
                            local died = enemy:takeDamage(patch.damage, px, py, 40)
                            self:applyFrenzyLifesteal(patch.damage)
                            if self.damageNumbers then
                                self.damageNumbers:add(ex, ey - enemy:getSize(), patch.damage, { isCrit = false, color = {1.0, 0.52, 0.14} })
                            end
                            self.particles:createBurnFlare(ex, ey - enemy:getSize() * 0.2, 0.9)
                            if died then
                                if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                                self:spawnEnemyXpDrop(ex, ey, 8 + math.random(0, 5))
                                self:addMajorProgress(self.majorProgressPerKill)
                                self:triggerKillActions(enemy, false)
                            end
                        end
                    end
                end
            end
        end
        if not patch:isAlive() then
            table.remove(self.firePatches, i)
        end
    end
end

---------------------------------------------------------------------------
-- HELPER: get all enemy lists for iteration
---------------------------------------------------------------------------
function GameScene:getAllEnemyLists()
    return {
        self.enemies, self.lungers, self.treents,
        self.slimes, self.bats, self.skeletons, self.imps, self.wolves,
        self.smallTreents, self.wizards, self.healers, self.druidTreents,
    }
end

---------------------------------------------------------------------------
-- HELPER: flattened list of living enemies (for healer/druid target selection)
---------------------------------------------------------------------------
function GameScene:getFlattenedEnemies()
    local flat = {}
    for _, list in ipairs(self:getAllEnemyLists()) do
        for _, e in ipairs(list) do
            if e.isAlive then table.insert(flat, e) end
        end
    end
    return flat
end

function GameScene:getObjectiveTargets(includeChest)
    local targets = {}
    for _, core in ipairs(self.cores) do
        if core.isAlive then
            table.insert(targets, core)
        end
    end
    if includeChest and self.rewardChest and self.rewardChest.isAlive then
        table.insert(targets, self.rewardChest)
    end
    return targets
end

function GameScene:findNearestObjectiveTargetTo(x, y, maxRange, excludeSet, includeChest)
    local best, bestDistSq = nil, maxRange * maxRange
    for _, target in ipairs(self:getObjectiveTargets(includeChest)) do
        if target.isAlive and (not excludeSet or not excludeSet[target]) then
            local tx, ty = target:getPosition()
            local dx = tx - x
            local dy = ty - y
            local distSq = dx * dx + dy * dy
            if distSq < bestDistSq then
                best = target
                bestDistSq = distSq
            end
        end
    end
    return best, math.sqrt(bestDistSq)
end

function GameScene:findNearestPriorityTargetTo(x, y, maxRange, excludeSet)
    local objectiveTarget, objectiveDist = self:findNearestObjectiveTargetTo(x, y, maxRange, excludeSet, true)
    if objectiveTarget then
        return objectiveTarget, objectiveDist
    end
    return self:findNearestEnemyTo(x, y, maxRange, excludeSet)
end

---------------------------------------------------------------------------
-- HELPER: find best target for Arrow Volley - prefer clusters of 2-3+ enemies
---------------------------------------------------------------------------
function GameScene:findBestClusterTarget(px, py, maxRange, clusterRadius)
    clusterRadius = clusterRadius or 80
    local objectiveTarget = self:findNearestObjectiveTargetTo(px, py, maxRange, nil, true)
    if objectiveTarget then
        return objectiveTarget
    end
    local all = self:getFlattenedEnemies()
    local bestTarget, bestScore, bestDist = nil, 0, maxRange
    for _, e in ipairs(all) do
        if not e.isAlive then goto continue end
        local ex, ey = e:getPosition()
        local dx = ex - px
        local dy = ey - py
        local d = math.sqrt(dx * dx + dy * dy)
        if d > maxRange then goto continue end
        local count = 0
        for _, o in ipairs(all) do
            if o.isAlive and o ~= e then
                local ox, oy = o:getPosition()
                local odx = ox - ex
                local ody = oy - ey
                if odx * odx + ody * ody <= clusterRadius * clusterRadius then
                    count = count + 1
                end
            end
        end
        local clusterSize = count + 1
        if clusterSize > bestScore or (clusterSize == bestScore and d < bestDist) then
            bestScore = clusterSize
            bestTarget = e
            bestDist = d
        end
        ::continue::
    end
    if bestTarget and bestScore >= 2 then return bestTarget end
    return self:findNearestEnemyTo(px, py, maxRange)
end

---------------------------------------------------------------------------
-- HELPER: find nearest living enemy to a point, optionally excluding a set
---------------------------------------------------------------------------
function GameScene:findNearestEnemyTo(x, y, maxRange, excludeSet)
    local best, bestDistSq = nil, maxRange * maxRange
    for _, list in ipairs(self:getAllEnemyLists()) do
        for _, e in ipairs(list) do
            if e.isAlive and (not excludeSet or not excludeSet[e]) then
                local ex, ey = e:getPosition()
                local dx = ex - x
                local dy = ey - y
                local distSq = dx * dx + dy * dy
                if distSq < bestDistSq then
                    best = e
                    bestDistSq = distSq
                end
            end
        end
    end
    return best, math.sqrt(bestDistSq)
end

function GameScene:damageObjectiveTarget(target, dmg, _sourceX, _sourceY)
    if not target or not target.isAlive then return false end

    local tx, ty = target:getPosition()
    local died = target:takeDamage(dmg)
    self:applyFrenzyLifesteal(dmg)
    local isChest = target == self.rewardChest
    local hitColor = isChest and {1.0, 0.8, 0.35} or {0.4, 0.7, 1.0}
    local burstColor = isChest and {1.0, 0.72, 0.24} or {0.3, 0.6, 1.0}

    self.particles:createHitSpark(tx, ty, hitColor)
    if self.damageNumbers then
        self.damageNumbers:add(tx, ty - target:getSize(), dmg, { isCrit = false, color = hitColor })
    end

    if not died then
        return false
    end

    self.screenShake:add(isChest and 6 or 5, isChest and 0.22 or 0.18)
    self:hitFreeze(isChest and 0.06 or 0.05)
    self.particles:createExplosion(tx, ty, burstColor)

    if isChest then
        self.coreObjectiveRewardGiven = true
        self:grantCoreObjectiveReward()
        if _G.triggerScreenFlash then
            _G.triggerScreenFlash({1.0, 0.82, 0.35, 0.28}, 0.12)
        end
        return true
    end

    self.coresDestroyed = self.coresDestroyed + 1
    self.xpSystem:spawnOrb(tx, ty, 20 + math.random(0, 10))
    if _G.triggerScreenFlash then
        _G.triggerScreenFlash({0.4, 0.7, 1.0, 0.3}, 0.1)
    end
    if self.coresDestroyed >= self.coresTotal then
        self:completeCoreObjective(tx, ty)
    end

    return true
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
                    self:applyFrenzyLifesteal(damage)
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - e:getSize(), damage, { isCrit = false })
                    end
                    if died then
                        if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                        self.particles:createExplosion(ex, ey, {1, 0.5, 0.1})
                        self.screenShake:add(4, 0.15)
                        local xpValue = 10 + math.random(0, 5)
                        self:spawnEnemyXpDrop(ex, ey, xpValue)
                        self:addMajorProgress(self.majorProgressPerKill)
                        self:triggerKillActions(e, false)
                    end
                end
            end
        end
    end

    for _, target in ipairs(self:getObjectiveTargets(true)) do
        if target.isAlive then
            local tx, ty = target:getPosition()
            local dx = tx - cx
            local dy = ty - cy
            if math.sqrt(dx * dx + dy * dy) <= radius then
                self:damageObjectiveTarget(target, damage, cx, cy)
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
    local didJump = false
    for i = 1, jumps do
        local cx, cy = current:getPosition()
        local next = self:findNearestPriorityTargetTo(cx, cy, jumpRange, hit)
        if not next then break end
        didJump = true
        hit[next] = true
        local nx, ny = next:getPosition()
        if i <= 3 then
            self.particles:createLightningArc(cx, cy, nx, ny, {0.55, 0.8, 1.0})
        elseif self.particles and self.particles.createHitSpark then
            self.particles:createHitSpark(nx, ny, {0.55, 0.8, 1.0})
        end
        if next == self.rewardChest or next.majorProgress then
            self:damageObjectiveTarget(next, damage, cx, cy)
        else
            if self.damageNumbers and i <= 3 then
                self.damageNumbers:add(nx, ny - next:getSize(), damage, { isCrit = false })
            end
            local died = next:takeDamage(damage, cx, cy, 60)
            self:applyFrenzyLifesteal(damage)
            if died then
                if self.enemySpawner then self.enemySpawner:onEnemyDeath() end
                self.particles:createExplosion(nx, ny, {0.35, 0.6, 1.0})
                self.screenShake:add(4, 0.14)
                self:spawnEnemyXpDrop(nx, ny, 10 + math.random(0, 5))
                self:addMajorProgress(self.majorProgressPerKill)
                self:triggerKillActions(next, false)
            end
        end
        current = next
    end
    -- Freeze for chain lightning payoff (no screen flash)
    if didJump then
        self:hitFreeze(0.04)
    end
end

---------------------------------------------------------------------------
-- HELPER: spawn arrowstorm (radial burst of arrows from player)
---------------------------------------------------------------------------
function GameScene:spawnArrowstorm(count, damageMul, speedMul)
    if not self.player then return end
    if self.player.playAttackAnimation then self.player:playAttackAnimation() end
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
        if _G.audio then _G.audio:playSFX("shoot_arrow") end
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
-- HELPER: ice dissolve blast (when ice-attuned primary arrow expires)
---------------------------------------------------------------------------
function GameScene:iceDissolveBlast(x, y)
    if not self.playerStats or self.playerStats.activePrimaryElement ~= "ice" then return end
    local baseRadius = 70
    local radiusAdd = self.playerStats:getElementMod("ice", "ice_blast_radius_add", 0)
    local radius = baseRadius + radiusAdd
    local baseDmg = (self.player and self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * 1.6
    self:aoeDamage(x, y, radius, baseDmg)
    -- Freeze spread: apply chill/freeze to enemies in radius (bosses get chill only)
    if self.playerStats:hasUpgrade("arch_r_freeze_spread") then
        local duration = 1.5 + (self.playerStats:getElementMod("ice", "chill_duration_add", 0) or 0)
        local slowMul = self.playerStats:getElementMod("ice", "slow_mul", 1.0) or 1.0
        for _, list in ipairs(self:getAllEnemyLists()) do
            for _, e in ipairs(list) do
                if e.isAlive then
                    local ex, ey = e:getPosition()
                    local dx = ex - x
                    local dy = ey - y
                    if math.sqrt(dx * dx + dy * dy) <= radius then
                        local status = (e.isBoss and "chill") or "freeze"
                        StatusEffects.apply(e, status, 1, duration, slowMul ~= 1.0 and { slowMul = slowMul } or nil)
                    end
                end
            end
        end
    end
    self.particles:createIceBlast(x, y, radius)
    self.screenShake:add(5, 0.12)
    self:hitFreeze(0.04)
end

---------------------------------------------------------------------------
-- HELPER: ice blast on death (AOE when enemy with chill dies)
---------------------------------------------------------------------------
function GameScene:iceBlastOnDeath(target, radius, damageMultOfMaxHP)
    local tx, ty = target:getPosition()
    local damage = (target.maxHealth or 50) * (damageMultOfMaxHP or 0.05)
    local radiusAdd = self.playerStats and self.playerStats:getElementMod("ice", "ice_blast_radius_add", 0) or 0
    radius = (radius or 70) + radiusAdd
    self:aoeDamage(tx, ty, radius, damage)
    self.particles:createIceBlast(tx, ty, radius)
    self.screenShake:add(5, 0.12)
    self:hitFreeze(0.04)
end

---------------------------------------------------------------------------
-- HELPER: hemorrhage explosion (AOE on killing bleeding target)
---------------------------------------------------------------------------
function GameScene:hemorrhageExplosion(target, damageMultOfMaxHP, radius)
    local tx, ty = target:getPosition()
    local damage = (target.maxHealth or 50) * damageMultOfMaxHP
    self:aoeDamage(tx, ty, radius, damage)
    -- Hemorrhage VFX: expanding blood ring + explosion + burst drips
    self.particles:createAoeRing(tx, ty, radius, {0.9, 0.1, 0.05})
    self.particles:createExplosion(tx, ty, {0.8, 0.1, 0.1})
    for _ = 1, 6 do
        local angle = love.math.random() * math.pi * 2
        local dist = love.math.random() * radius * 0.5
        self.particles:createBleedDrip(tx + math.cos(angle) * dist, ty + math.sin(angle) * dist, {0.9, 0.1, 0.05})
    end
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
            local status = apply.status
            -- Bosses: no hard freeze, use chill (slow) only
            if status == "freeze" and action.target.isBoss then
                status = "chill"
            end
            local duration = apply.duration or 2.0
            local options = nil
            if status == "chill" or status == "freeze" then
                duration = duration + (self.playerStats and self.playerStats:getElementMod("ice", "chill_duration_add", 0) or 0)
                local slowMul = self.playerStats and self.playerStats:getElementMod("ice", "slow_mul", 1.0) or 1.0
                if slowMul ~= 1.0 then options = { slowMul = slowMul } end
            end
            StatusEffects.apply(action.target, status, apply.stacks, duration, options)
        end

    elseif apply.kind == "chain_damage" then
        if action.target and action.target.isAlive then
            local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult
            local chainDmg = baseDmg * (apply.damage_mul or 0.35)
            local jumps = apply.jumps or 2
            if self.playerStats and self.playerStats.activePrimaryElement == "lightning" then
                jumps = jumps + (self.playerStats:getElementMod("lightning", "chain_jumps_add", 0) or 0)
            end
            self:chainDamage(action.target, jumps, apply.range or 180, chainDmg)
        end

    elseif apply.kind == "aoe_projectile_burst" then
        self:spawnArrowstorm(apply.count or 12, apply.damage_mul or 0.40, apply.speed_mul or 0.90)

    elseif apply.kind == "aoe_explosion" then
        if action.target then
            self:hemorrhageExplosion(action.target, apply.damage_mul_of_target_maxhp or 0.06, apply.radius or 90)
        end

    elseif apply.kind == "ice_blast" then
        if action.target then
            self:iceBlastOnDeath(action.target, apply.radius or 70, apply.damage_mul_of_target_maxhp or 0.05)
        end

    elseif apply.kind == "fire_patch" then
        if action.target then
            local tx, ty = action.target:getPosition()
            self:spawnFirePatch(tx, ty, apply.radius or 42, apply.damage or 8, apply.duration or 4.0, apply.tick_interval or 0.35)
        end

    elseif apply.kind == "fire_explosion" then
        if action.target then
            self:fireDeathExplosion(action.target, apply.radius or 92, apply.primary_damage_mul or 2.5)
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
    -- Apply camera transform (centers viewport on player)
    if self.camera then
        self.camera:attach()
    end
    
    -- Apply screen shake on top of camera
    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw forest tilemap background (grass, flowers, rocks)
    if self.forestTilemap then
        self.forestTilemap:draw()
    else
        self.tilemap:draw()
    end

    -- Draw Arrow Volleys (falling arrows + impact zones)
    for _, volley in ipairs(self.arrowVolleys) do
        volley:draw()
    end
    for _, firePatch in ipairs(self.firePatches) do
        firePatch:draw()
    end
    if self.spellblade then
        self.spellblade:drawGround(self)
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

    -- Add cores
    for _, core in ipairs(self.cores) do
        if core.isAlive then
            table.insert(drawables, {entity = core, y = core.y, type = "core"})
        end
    end
    if self.rewardChest and self.rewardChest.isAlive then
        table.insert(drawables, {entity = self.rewardChest, y = self.rewardChest.y, type = "reward_chest"})
    end
    
    -- Add forest tilemap small trees and rocks (Y-sorted with entities)
    if self.forestTilemap then
        if self.forestTilemap.getSmallTreesForSorting then
            for _, st in ipairs(self.forestTilemap:getSmallTreesForSorting()) do
                table.insert(drawables, {drawFunc = st.draw, y = st.y, type = "forest_small_tree"})
            end
        end
        if self.forestTilemap.getRocksForSorting then
            for _, rock in ipairs(self.forestTilemap:getRocksForSorting()) do
                table.insert(drawables, {drawFunc = rock.draw, y = rock.y, type = "forest_rock"})
            end
        end
        if self.forestTilemap.getLargeBlockersForSorting then
            for _, blk in ipairs(self.forestTilemap:getLargeBlockersForSorting()) do
                table.insert(drawables, {drawFunc = blk.draw, y = blk.y, type = "forest_large_blocker"})
            end
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
    
    for _, e in ipairs(self.slimes) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "slime"}) end
    end
    for _, e in ipairs(self.bats) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "bat"}) end
    end
    for _, e in ipairs(self.skeletons) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "skeleton"}) end
    end
    for _, e in ipairs(self.imps) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "imp"}) end
    end
    for _, e in ipairs(self.wolves) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "wolf"}) end
    end
    for _, e in ipairs(self.smallTreents) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "small_treent"}) end
    end
    for _, e in ipairs(self.wizards) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "wizard"}) end
    end
    for _, e in ipairs(self.healers) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "healer"}) end
    end
    for _, e in ipairs(self.druidTreents) do
        if e.isAlive then table.insert(drawables, {entity = e, y = e.y, type = "druid_treent"}) end
    end
    
    -- Add boss portal
    if self.bossPortal then
        table.insert(drawables, { drawFunc = function() self.bossPortal:draw() end, y = self.bossPortal.y, type = "portal" })
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

        -- Marked status: gold outline for readability
        if drawable.entity and drawable.entity.isAlive and StatusEffects.has(drawable.entity, "marked") then
            local ex, ey = drawable.entity:getPosition()
            local sz = (drawable.entity.getSize and drawable.entity:getSize()) or 16
            local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 4)
            love.graphics.setColor(1, 0.85, 0.2, pulse)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", ex, ey, sz + 4)
            love.graphics.setLineWidth(1)
        end

        if drawable.entity and drawable.entity.isAlive and StatusEffects.has(drawable.entity, "burn") then
            local ex, ey = drawable.entity:getPosition()
            local sz = (drawable.entity.getSize and drawable.entity:getSize()) or 16
            local stacks = StatusEffects.getStacks(drawable.entity, "burn")
            local pulse = 0.45 + 0.18 * math.sin(love.timer.getTime() * 9 + ey * 0.03)
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(1.0, 0.42, 0.12, 0.08 + pulse * 0.10 + math.min(0.08, stacks * 0.012))
            love.graphics.circle("fill", ex, ey, sz + 8)
            love.graphics.setColor(1.0, 0.78, 0.22, 0.05 + pulse * 0.08)
            love.graphics.circle("fill", ex, ey - 2, sz + 4)
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(1.0, 0.62, 0.18, 0.75)
            love.graphics.setLineWidth(1)
            love.graphics.arc("line", "open", ex, ey, sz + 3, math.pi * 0.12, math.pi * 0.88)
            love.graphics.arc("line", "open", ex, ey, sz + 1, math.pi * 1.1, math.pi * 1.9)
            for k = 0, 2 do
                local a = love.timer.getTime() * 3.2 + k * (math.pi * 2 / 3)
                local rr = sz + 2 + (k % 2) * 2
                local fx = ex + math.cos(a) * rr * 0.55
                local fy = ey - sz * 0.45 + math.sin(a) * 4
                love.graphics.setColor(1.0, 0.84, 0.35, 0.85)
                love.graphics.rectangle("fill", fx - 1, fy - 2, 2, 4)
            end
            love.graphics.setLineWidth(1)
        end

        -- Freeze status: icy cyan ring/glow
        if drawable.entity and drawable.entity.isAlive and StatusEffects.has(drawable.entity, "freeze") then
            local ex, ey = drawable.entity:getPosition()
            local sz = (drawable.entity.getSize and drawable.entity:getSize()) or 16
            local t = love.timer.getTime()
            local pulse = 0.55 + 0.25 * math.sin(t * 7 + ex * 0.05)
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(0.55, 0.9, 1.0, 0.12 + pulse * 0.10)
            love.graphics.circle("fill", ex, ey, sz + 11)
            love.graphics.setColor(0.8, 0.98, 1.0, 0.10 + pulse * 0.08)
            love.graphics.circle("fill", ex, ey, sz + 6)
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(0.65, 0.92, 1.0, 0.95)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", ex, ey, sz + 5)
            for k = 0, 3 do
                local a = t * 2.8 + k * (math.pi * 0.5)
                local rr = sz + 8
                local fx = ex + math.cos(a) * rr
                local fy = ey + math.sin(a) * rr
                love.graphics.rectangle("fill", fx - 1.5, fy - 1.5, 3, 3)
            end
            love.graphics.setLineWidth(1)
        end

        -- Chill/slow status: colder aura hugging the enemy body
        if drawable.entity and drawable.entity.isAlive and StatusEffects.has(drawable.entity, "chill") then
            local ex, ey = drawable.entity:getPosition()
            local sz = (drawable.entity.getSize and drawable.entity:getSize()) or 16
            local t = love.timer.getTime()
            local shimmer = 0.5 + 0.25 * math.sin(t * 5 + ey * 0.05)
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(0.5, 0.88, 1.0, 0.08 + shimmer * 0.08)
            love.graphics.circle("fill", ex, ey, sz + 8)
            love.graphics.setColor(0.72, 0.96, 1.0, 0.06 + shimmer * 0.06)
            love.graphics.circle("fill", ex, ey, sz + 4)
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(0.66, 0.93, 1.0, 0.65)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", ex, ey, sz + 3)
            for k = 0, 2 do
                local a = t * 2.2 + k * (math.pi * 2 / 3)
                local rr = sz + 5
                local fx = ex + math.cos(a) * rr
                local fy = ey + math.sin(a) * rr
                love.graphics.rectangle("fill", fx - 1, fy - 1, 2, 2)
            end
            love.graphics.setLineWidth(1)
        end

        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw arrows and bark projectiles (always on top of entities)
    for _, arrow in ipairs(self.arrows) do
        arrow:draw()
    end
    if self.spellblade then
        self.spellblade:drawForeground(self)
    end
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
    
    -- Detach camera before drawing HUD (HUD is in screen space)
    if self.camera then
        self.camera:detach()
    end

    -- Screen-space ambience pass for richer forest presentation.
    if self.forestTilemap and self.forestTilemap.drawScreenOverlay then
        self.forestTilemap:drawScreenOverlay()
    end
    
    -- Draw HUD (not affected by screen shake or camera)
    self:drawMajorProgressBar()
    if self.coreObjectiveStarted then
        self:drawObjectiveHUD()
    end
    if self.coreObjectivePopupTimer and self.coreObjectivePopupTimer > 0 then
        self:drawCoreObjectivePopup()
    end
    if self.coreObjectiveFailPopupTimer and self.coreObjectiveFailPopupTimer > 0 then
        self:drawCoreObjectiveFailPopup()
    end
    
    -- Draw upgrade UI (on top of everything)
    if self.upgradeUI then
        self.upgradeUI:draw()
    end
end

local function drawTextWithShadow(text, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, x, y)
end

function GameScene:drawXPBar()
    local screenWidth = love.graphics.getWidth()
    local t = love.timer.getTime()

    local barWidth = 312
    local barHeight = 10
    local barX = (screenWidth - barWidth) / 2
    local barY = 54
    local progress = self.xpSystem:getProgress()

    -- Subtle backing panel
    love.graphics.setColor(0.04, 0.04, 0.08, 0.75)
    love.graphics.rectangle("fill", barX - 8, barY - 6, barWidth + 16, barHeight + 12, 8, 8)

    -- Bar track
    love.graphics.setColor(0.1, 0.08, 0.14, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 3, 3)

    -- XP fill (cyan-teal gradient feel, space-shooter inspired)
    local fillW = barWidth * progress
    if fillW > 0 then
        love.graphics.setColor(0.1, 0.55, 0.85, 1)
        love.graphics.rectangle("fill", barX, barY, fillW, barHeight, 3, 3)
        -- Bright top highlight
        love.graphics.setColor(0.25, 0.75, 1.0, 0.6)
        love.graphics.rectangle("fill", barX, barY, fillW, barHeight * 0.4, 3, 3)
        -- Leading-edge glow
        love.graphics.setColor(0.5, 0.9, 1.0, 0.5 + 0.2 * math.sin(t * 4))
        love.graphics.rectangle("fill", barX + fillW - 4, barY, 4, barHeight, 2, 2)
    end

    -- Frame (thin metallic)
    love.graphics.setColor(0.4, 0.5, 0.6, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 3, 3)

    -- Level badge (left of bar)
    local badgeFont = _G.PixelFonts and _G.PixelFonts.uiTiny or love.graphics.getFont()
    love.graphics.setFont(badgeFont)
    local levelText = "Lv " .. self.xpSystem.level
    local tw = badgeFont:getWidth(levelText)
    -- Badge background
    love.graphics.setColor(0.04, 0.04, 0.08, 0.85)
    love.graphics.rectangle("fill", barX - tw - 20, barY - 2, tw + 14, barHeight + 4, 4, 4)
    love.graphics.setColor(0.4, 0.5, 0.6, 0.5)
    love.graphics.rectangle("line", barX - tw - 20, barY - 2, tw + 14, barHeight + 4, 4, 4)
    -- Level text
    love.graphics.setColor(0.85, 0.9, 1.0, 1)
    love.graphics.print(levelText, barX - tw - 13, barY - 1)

    -- Rarity charges (right of bar)
    local charges = self.rarityCharge:getCharges()
    if charges > 0 then
        love.graphics.setColor(1, 0.8, 0.2, 1)
        local chargeFont = _G.PixelFonts and _G.PixelFonts.uiTiny or love.graphics.getFont()
        love.graphics.setFont(chargeFont)
        local chargeText = "★" .. charges
        love.graphics.print(chargeText, barX + barWidth + 10, barY - 1)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawProgressDiamond(mode, cx, cy, halfW, halfH)
    love.graphics.polygon(mode, cx, cy - halfH, cx + halfW, cy, cx, cy + halfH, cx - halfW, cy)
end

function GameScene:drawMajorProgressBar()
    if self.gameState and self.gameState:getState() == self.gameState.States.BOSS_FIGHT then
        return
    end

    local screenWidth = love.graphics.getWidth()
    local t = love.timer.getTime()

    local barWidth = 432
    local barHeight = 16
    local barX = (screenWidth - barWidth) / 2
    local barY = 46
    local progress = math.min(1, self.majorProgress / self.majorProgressMax)
    local objectivePct = self.coreObjectiveStartPct or 0.25
    local markerPcts = { objectivePct, 0.50, 0.75, 1.0 }

    local function drawCoreMarker(cx, cy, active)
        local glow = active and (0.22 + 0.14 * math.sin(t * 4)) or 0.08
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.72, 0.96, 1.0, glow)
        love.graphics.circle("fill", cx, cy, 18)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.09, 0.11, 0.15, 0.98)
        love.graphics.circle("fill", cx, cy, 13)
        love.graphics.setColor(active and 0.84 or 0.32, active and 0.96 or 0.56, active and 1.0 or 0.72, 0.95)
        love.graphics.circle("line", cx, cy, 13)
        love.graphics.setColor(0.92, 0.98, 1.0, active and 0.95 or 0.72)
        drawProgressDiamond("line", cx, cy, 5, 7)
        drawProgressDiamond("line", cx, cy, 9, 11)
    end

    local function drawSkullMarker(cx, cy, active)
        local glow = active and (0.24 + 0.14 * math.sin(t * 5)) or 0.08
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.95, 0.78, 0.48, glow)
        love.graphics.circle("fill", cx, cy, 19)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.12, 0.08, 0.07, 0.98)
        love.graphics.circle("fill", cx, cy, 14)
        love.graphics.setColor(active and 0.96 or 0.55, active and 0.82 or 0.46, active and 0.48 or 0.3, 0.95)
        love.graphics.circle("line", cx, cy, 14)
        love.graphics.setColor(0.95, 0.9, 0.82, active and 0.95 or 0.7)
        love.graphics.circle("fill", cx, cy - 1, 6.5)
        love.graphics.rectangle("fill", cx - 4.5, cy + 4, 9, 5.5, 2, 2)
        love.graphics.setColor(0.1, 0.08, 0.07, 1)
        love.graphics.circle("fill", cx - 2.5, cy - 1.5, 1.7)
        love.graphics.circle("fill", cx + 2.5, cy - 1.5, 1.7)
        love.graphics.polygon("fill", cx, cy + 1, cx - 1.5, cy + 3.5, cx + 1.5, cy + 3.5)
    end

    love.graphics.setColor(0, 0, 0, 0.24)
    love.graphics.rectangle("fill", barX - 16, barY - 16, barWidth + 32, barHeight + 36, 16, 16)
    love.graphics.setColor(0.07, 0.08, 0.11, 0.95)
    love.graphics.rectangle("fill", barX - 10, barY - 10, barWidth + 20, barHeight + 24, 14, 14)
    love.graphics.setColor(0.9, 0.95, 1.0, 0.08)
    love.graphics.rectangle("fill", barX - 8, barY - 8, barWidth + 16, 10, 12, 12)
    love.graphics.setColor(0.42, 0.56, 0.7, 0.18)
    love.graphics.rectangle("line", barX - 10, barY - 10, barWidth + 20, barHeight + 24, 14, 14)

    love.graphics.setColor(0.03, 0.05, 0.07, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 5, 5)
    love.graphics.setColor(0.12, 0.16, 0.2, 0.9)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 5, 5)

    for _, pct in ipairs(markerPcts) do
        local cutX = barX + barWidth * pct
        love.graphics.setColor(0.01, 0.02, 0.04, 0.95)
        love.graphics.rectangle("fill", cutX - 2, barY - 2, 4, barHeight + 4, 2, 2)
        love.graphics.setColor(0.92, 0.98, 1.0, 0.14)
        love.graphics.rectangle("fill", cutX - 1, barY, 2, barHeight, 1, 1)
    end

    local fillW = barWidth * progress
    if fillW > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.26, 0.9, 1.0, 0.16)
        love.graphics.rectangle("fill", barX - 2, barY - 2, fillW + 4, barHeight + 4, 6, 6)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.16, 0.78, 0.95, 1)
        love.graphics.rectangle("fill", barX, barY, fillW, barHeight, 5, 5)
        love.graphics.setColor(0.84, 0.98, 1.0, 0.46)
        love.graphics.rectangle("fill", barX + 2, barY + 2, math.max(0, fillW - 4), math.max(0, barHeight * 0.35), 4, 4)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.16)
        local sweepW = math.min(fillW, 52)
        if sweepW > 8 then
            love.graphics.rectangle("fill", barX + fillW - sweepW, barY + 1, sweepW, barHeight - 2, 4, 4)
        end
        love.graphics.setColor(0.94, 1.0, 1.0, 0.45 + 0.2 * math.sin(t * 4))
        love.graphics.rectangle("fill", barX + fillW - 5, barY - 1, 5, barHeight + 2, 2, 2)
    end

    love.graphics.setColor(0.64, 0.86, 0.98, 0.75)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 5, 5)

    local labelFont = _G.PixelFonts and _G.PixelFonts.uiTiny or love.graphics.getFont()
    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.9, 0.98, 1.0, 0.9)
    local pct = string.format("%d%%", math.floor(progress * 100))
    love.graphics.print(pct, barX + barWidth + 10, barY - 1)

    local objectiveX = barX + barWidth * objectivePct
    local bossX = barX + barWidth
    local markerY = barY - 18
    drawCoreMarker(objectiveX, markerY, progress >= objectivePct)
    drawSkullMarker(bossX, markerY, self.bossPortalSpawned or progress >= 1.0)

    if self.bossPortalSpawned then
        local readyText = "PORTAL READY"
        local readyW = labelFont:getWidth(readyText)
        love.graphics.setColor(0.95, 0.82, 0.45, 0.95)
        love.graphics.print(readyText, bossX - readyW / 2, barY + barHeight + 4)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:drawCoreObjectivePopup()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local t = love.timer.getTime()

    local duration = 3.0
    local alpha = math.min(1, (self.coreObjectivePopupTimer or 0) / 0.5)
    if self.coreObjectivePopupTimer < 0.5 then
        alpha = math.max(0, self.coreObjectivePopupTimer / 0.5)
    end

    local titleFont = _G.PixelFonts and _G.PixelFonts.uiLarge or love.graphics.getFont()
    local bodyFont = _G.PixelFonts and _G.PixelFonts.uiBody or love.graphics.getFont()

    love.graphics.setFont(titleFont)
    local title = "CORE OBJECTIVE!"
    local tw = titleFont:getWidth(title)
    love.graphics.setColor(0.3, 0.7, 1.0, alpha)
    love.graphics.print(title, screenWidth / 2 - tw / 2, screenHeight / 2 - 50)

    love.graphics.setFont(bodyFont)
    local body = "DESTROY 20 CORES"
    local bw = bodyFont:getWidth(body)
    love.graphics.setColor(0.9, 0.9, 0.95, alpha * 0.9)
    love.graphics.print(body, screenWidth / 2 - bw / 2, screenHeight / 2 - 10)

    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:drawCoreObjectiveFailPopup()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local timer = self.coreObjectiveFailPopupTimer or 0
    local alpha = math.min(1, timer / 0.5)
    if timer < 0.5 then
        alpha = math.max(0, timer / 0.5)
    end

    local titleFont = _G.PixelFonts and _G.PixelFonts.uiLarge or love.graphics.getFont()
    local bodyFont = _G.PixelFonts and _G.PixelFonts.uiBody or love.graphics.getFont()

    love.graphics.setFont(titleFont)
    local title = "TASK FAILED"
    local tw = titleFont:getWidth(title)
    love.graphics.setColor(1, 0.25, 0.2, alpha)
    love.graphics.print(title, screenWidth / 2 - tw / 2, screenHeight / 2 - 50)

    love.graphics.setFont(bodyFont)
    local body = "You ran out of time. Cores despawned."
    local bw = bodyFont:getWidth(body)
    love.graphics.setColor(0.95, 0.7, 0.65, alpha * 0.9)
    love.graphics.print(body, screenWidth / 2 - bw / 2, screenHeight / 2 - 10)

    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:drawObjectiveHUD()
    local screenWidth = love.graphics.getWidth()
    local t = love.timer.getTime()

    local font = _G.PixelFonts and _G.PixelFonts.uiSmall or love.graphics.getFont()
    local tinyFont = _G.PixelFonts and _G.PixelFonts.uiTiny or font
    love.graphics.setFont(font)

    -- Position: top-right area
    local panelW = 220
    local panelH = 52
    local panelX = screenWidth - panelW - 20
    local panelY = 56

    -- Panel background
    love.graphics.setColor(0.04, 0.04, 0.08, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 6, 6)
    love.graphics.setColor(0.35, 0.5, 0.7, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 6, 6)

    -- Objective title + count
    local coreText = string.format("CORES: %d/%d", self.coresDestroyed, self.coresTotal)
    if self.coreObjectiveFailed then
        love.graphics.setColor(1, 0.3, 0.25, 1)
        coreText = "TASK FAILED"
    elseif self.rewardChest and self.rewardChest.isAlive then
        love.graphics.setColor(1, 0.82, 0.34, 1)
        coreText = "RARE CHEST!"
    elseif self.coreObjectiveComplete then
        love.graphics.setColor(0.3, 1, 0.4, 1)
        coreText = "CORES COMPLETE!"
    else
        love.graphics.setColor(0.4, 0.8, 1.0, 1)
    end
    love.graphics.print(coreText, panelX + 10, panelY + 6)

    -- Timer
    love.graphics.setFont(tinyFont)
    local remaining = math.max(0, self.coreObjectiveTimeLimit - self.coreObjectiveTimer)
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    local timerText = string.format("TIME: %d:%02d", mins, secs)
    if self.coreObjectiveFailed then
        timerText = "TIME EXPIRED"
        love.graphics.setColor(1, 0.35, 0.3, 1)
    elseif self.rewardChest and self.rewardChest.isAlive then
        timerText = "BREAK FOR RARE CARDS"
        love.graphics.setColor(1, 0.85, 0.3, 1)
    elseif self.coreObjectiveComplete then
        timerText = "BONUS CLAIMED!"
        love.graphics.setColor(1, 0.85, 0.3, 1)
    elseif remaining <= 30 then
        local blink = 0.5 + 0.5 * math.sin(t * 6)
        love.graphics.setColor(1, 0.3, 0.2, blink)
    else
        love.graphics.setColor(0.7, 0.7, 0.65, 0.9)
    end
    love.graphics.print(timerText, panelX + 10, panelY + 28)

    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:keypressed(key)
    -- Handle upgrade UI input first
    if self.upgradeUI and self.upgradeUI:isVisible() then
        -- Always swallow gameplay inputs while the modal is open
        self.upgradeUI:keypressed(key)
        return true
    end

    -- Pause menu toggle
    if key == "escape" then
        if self.pauseSettingsVisible then
            self.pauseSettingsVisible = false
            return true
        end
        self.pauseMenuVisible = not self.pauseMenuVisible
        if self.pauseMenuVisible then
            self.pauseMenuIndex = 1
        end
        return true
    end

    -- Pause menu input
    if self.pauseMenuVisible then
        if self.pauseSettingsVisible then
            local settings = _G.settings
            local step = 0.05
            if key == "up" then
                self.pauseSettingsIndex = self.pauseSettingsIndex - 1
                if self.pauseSettingsIndex < 1 then self.pauseSettingsIndex = 4 end
                return true
            elseif key == "down" then
                self.pauseSettingsIndex = self.pauseSettingsIndex + 1
                if self.pauseSettingsIndex > 4 then self.pauseSettingsIndex = 1 end
                return true
            elseif key == "left" or key == "right" then
                local dir = (key == "right") and 1 or -1
                if settings then
                    local s = settings:get()
                    if self.pauseSettingsIndex == 1 then
                        settings:setMusicVolume((s.audio.musicVolume or 0.35) + step * dir)
                    elseif self.pauseSettingsIndex == 2 then
                        settings:setSFXVolume((s.audio.sfxVolume or 0.5) + step * dir)
                    elseif self.pauseSettingsIndex == 3 then
                        settings:setScreenShake((s.graphics.screenShake or 1.0) + step * dir)
                    end
                end
                return true
            elseif (key == "return" or key == "space") and self.pauseSettingsIndex == 4 then
                self.pauseSettingsVisible = false
                return true
            end
            return true
        else
            if key == "up" then
                self.pauseMenuIndex = self.pauseMenuIndex - 1
                if self.pauseMenuIndex < 1 then self.pauseMenuIndex = 3 end
                return true
            elseif key == "down" then
                self.pauseMenuIndex = self.pauseMenuIndex + 1
                if self.pauseMenuIndex > 3 then self.pauseMenuIndex = 1 end
                return true
            elseif key == "return" or key == "space" then
                if self.pauseMenuIndex == 1 then
                    self.pauseMenuVisible = false
                elseif self.pauseMenuIndex == 2 then
                    self.pauseSettingsVisible = true
                    self.pauseSettingsIndex = 1
                elseif self.pauseMenuIndex == 3 then
                    self.pauseMenuVisible = false
                    self.gameState:transitionTo(self.gameState.States.MENU)
                end
                return true
            end
            return true
        end
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

    if self.spellblade and self.spellblade:isActive(self.player) then
        if self.spellblade:keypressed(self, key) or key == "q" or key == "e" or key == "r" or key == "space" then
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
        })
        self.frenzyActive = true
        if _G.audio then _G.audio:playSFX("hit_heavy") end
        self.screenShake:add(4, 0.15)
        -- Frenzy VFX
        if self.player then
            local px, py = self.player:getPosition()
            self.particles:createFrenzyBurst(px, py)
            self.particles:createCastBurst(px, py, {1, 0.62, 0.15}, 1.15)
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
    if self.pauseMenuVisible then
        self:drawPauseOverlay()
    end
    if self.statsOverlay and self.statsOverlay:isVisible() then
        self.statsOverlay:draw(self.playerStats, self.xpSystem)
    end
end

function GameScene:hasOpenOverlay()
    return ((self.statsOverlay and self.statsOverlay:isVisible()) == true) or self.pauseMenuVisible
end

-- Shared layout for pause overlay (draw and hit-test use identical coordinates)
function GameScene:getPauseOverlayLayout()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = 520, 320
    local panelX, panelY = (w - panelW) / 2, (h - panelH) / 2
    local optY0, optGap = panelY + 98, 56
    local btnW, btnH = 220, 56  -- btnH = optGap so each option spans full vertical space
    local y0 = panelY + 96
    local backY = y0 + optGap * 3
    local sliderX = panelX + 220
    local sliderW = 220
    local sliderH = 24  -- hit region height for easier clicking
    return {
        panelX = panelX, panelY = panelY, panelW = panelW, panelH = panelH,
        optY0 = optY0, optGap = optGap, btnW = btnW, btnH = btnH,
        y0 = y0, backY = backY,
        sliderX = sliderX, sliderW = sliderW, sliderH = sliderH,
    }
end

function GameScene:drawPauseSlider(label, value, x, y, width, isSelected)
    local v = math.max(0, math.min(1, value or 0))
    love.graphics.setColor(0.16, 0.16, 0.22, 0.95)
    love.graphics.rectangle("fill", x, y, width, 14, 4, 4)
    love.graphics.setColor(isSelected and 0.95 or 0.7, isSelected and 0.75 or 0.78, isSelected and 0.35 or 0.95, 1)
    love.graphics.rectangle("fill", x + 2, y + 2, (width - 4) * v, 10, 3, 3)
    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    local f = (_G.PixelFonts and _G.PixelFonts.uiTiny) or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.print(label, x - 190, y - 5)
    love.graphics.print(string.format("%d%%", math.floor(v * 100)), x + width + 12, y - 5)
end

function GameScene:drawPauseOverlay()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local L = self:getPauseOverlayLayout()
    local panelX, panelY = L.panelX, L.panelY
    local panelW, panelH = L.panelW, L.panelH
    local optY0, optGap = L.optY0, L.optGap

    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(0.08, 0.08, 0.12, 0.96)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12, 12)
    love.graphics.setColor(0.6, 0.6, 0.75, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12, 12)
    love.graphics.setLineWidth(1)

    local titleFont = (_G.PixelFonts and _G.PixelFonts.uiBody) or love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    local title = self.pauseSettingsVisible and "PAUSE - SETTINGS" or "PAUSED"
    love.graphics.print(title, panelX + panelW / 2 - titleFont:getWidth(title) / 2, panelY + 24)

    if self.pauseSettingsVisible then
        local settings = _G.settings and _G.settings:get() or nil
        local music = settings and settings.audio and settings.audio.musicVolume or 0.35
        local sfx = settings and settings.audio and settings.audio.sfxVolume or 0.5
        local shake = settings and settings.graphics and settings.graphics.screenShake or 1.0
        local sliderX = panelX + 220

        self:drawPauseSlider("Music Volume", music, sliderX, L.y0, 220, self.pauseSettingsIndex == 1)
        self:drawPauseSlider("Sound Volume", sfx, sliderX, L.y0 + optGap, 220, self.pauseSettingsIndex == 2)
        self:drawPauseSlider("Screen Shake", shake, sliderX, L.y0 + optGap * 2, 220, self.pauseSettingsIndex == 3)

        local backSelected = self.pauseSettingsIndex == 4
        love.graphics.setColor(backSelected and 0.95 or 0.45, backSelected and 0.75 or 0.45, backSelected and 0.35 or 0.5, 1)
        local body = (_G.PixelFonts and _G.PixelFonts.uiTiny) or love.graphics.getFont()
        love.graphics.setFont(body)
        local backText = "BACK"
        love.graphics.print(backText, panelX + panelW / 2 - body:getWidth(backText) / 2, L.backY)
    else
        local options = {"Resume", "Settings", "Quit to Menu"}
        local body = (_G.PixelFonts and _G.PixelFonts.uiBody) or love.graphics.getFont()
        love.graphics.setFont(body)
        for i, text in ipairs(options) do
            local selected = self.pauseMenuIndex == i
            love.graphics.setColor(selected and 1 or 0.8, selected and 0.85 or 0.8, selected and 0.5 or 0.75, 1)
            love.graphics.print(text, panelX + panelW / 2 - body:getWidth(text) / 2, optY0 + (i - 1) * optGap)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function GameScene:mousepressed(x, y, button)
    -- Handle pause overlay clicks (uses shared layout for exact draw/hit alignment)
    if self.pauseMenuVisible and button == 1 then
        local L = self:getPauseOverlayLayout()
        local panelX, panelW = L.panelX, L.panelW
        local btnX = panelX + (panelW - L.btnW) / 2

        if self.pauseSettingsVisible then
            local settings = _G.settings
            -- Slider hit-test: click on track to set value
            if settings then
                for i = 1, 3 do
                    local sy = L.y0 + (i - 1) * L.optGap
                    if x >= L.sliderX and x <= L.sliderX + L.sliderW and y >= sy and y <= sy + L.sliderH then
                        local v = math.max(0, math.min(1, (x - L.sliderX) / L.sliderW))
                        if i == 1 then settings:setMusicVolume(v)
                        elseif i == 2 then settings:setSFXVolume(v)
                        elseif i == 3 then settings:setScreenShake(v)
                        end
                        self.pauseSettingsIndex = i
                        return true
                    end
                end
            end
            -- BACK button: full optGap height for easy click
            local backBtnH = L.optGap
            if x >= btnX and x <= btnX + L.btnW and y >= L.backY and y <= L.backY + backBtnH then
                self.pauseSettingsVisible = false
                return true
            end
        else
            -- Main menu: Resume, Settings, Quit to Menu (btnH = optGap, no dead zones)
            for i = 1, 3 do
                local optTop = L.optY0 + (i - 1) * L.optGap
                if x >= btnX and x <= btnX + L.btnW and y >= optTop and y <= optTop + L.btnH then
                    if i == 1 then self.pauseMenuVisible = false
                    elseif i == 2 then self.pauseSettingsVisible = true; self.pauseSettingsIndex = 1
                    elseif i == 3 then self.pauseMenuVisible = false; self.gameState:transitionTo(self.gameState.States.MENU)
                    end
                    return true
                end
            end
        end
        -- Click on overlay but not on a button: consume to avoid accidental game input
        return true
    end

    -- Handle upgrade UI input
    if self.upgradeUI and self.upgradeUI:isVisible() then
        if self.upgradeUI:mousepressed(x, y, button) then
            return true
        end
    end
    return false
end

function GameScene:mousemoved(x, y)
    -- Convert screen coords to world coords for aiming
    if self.camera then
        self.mouseX, self.mouseY = self.camera:toWorld(x, y)
    else
        self.mouseX, self.mouseY = x, y
    end
    -- Handle upgrade UI hover (screen space)
    if self.upgradeUI then
        self.upgradeUI:mousemoved(x, y)
    end
end

function GameScene:startDash()
    if self.dashCooldown <= 0 and not self.isDashing then
        local dashCD = (self.player and self.player.abilities and self.player.abilities.dash and self.player.abilities.dash.cooldown) or 1.0
        self.isDashing = true
        self.dashTime = self.dashDuration
        self.dashCooldown = dashCD
        if _G.audio then _G.audio:playSFX("hit_light") end
        
        -- Sync with player ability cooldown for HUD
        if self.player and self.player.abilities and self.player.abilities.dash then
            self.player.abilities.dash.currentCooldown = dashCD
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

