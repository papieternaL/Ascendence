-- Game Scene - Main gameplay
local Player = require("entities.player")
local Tree = require("entities.tree")
local Enemy = require("entities.enemy")
local Lunger = require("entities.lunger")
local Treent = require("entities.treent")
local SmallTreent = require("entities.small_treent")
local Wizard = require("entities.wizard")
local Healer = require("entities.healer")
local Imp = require("entities.imp")
local Slime = require("entities.slime")
local Bat = require("entities.bat")
local Wolf = require("entities.wolf")
local Skeleton = require("entities.skeleton")
local DruidTreent = require("entities.druid_treent")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")
local ArrowVolley = require("entities.arrow_volley")
local Config = require("data.config")
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
local JuiceManager = require("systems.juice_manager")
local AbilityHUD = require("ui.ability_hud")

-- Load upgrade data
local ArcherUpgrades = require("data.upgrades_archer")
local AbilityPaths = require("data.ability_paths_archer")

-- New systems
local EnemySpawner = require("systems.enemy_spawner")
local BossPortal = require("entities.boss_portal")
local RunTimer = require("ui.run_timer")
local BuffBar = require("ui.buff_bar")
local UpgradeApplication = require("systems.upgrade_application")
local EnemyManager = require("systems.enemy_manager")
local TargetingSystem = require("systems.targeting_system")
local CollisionSystem = require("systems.collision_system")

local GameScene = {}
GameScene.__index = GameScene

function GameScene:new(gameState)
    local pCfg = Config.Player
    local scene = {
        gameState = gameState,
        player = nil,
        particles = nil,
        screenShake = nil,
        tilemap = nil,
        arrows = {},
        trees = {},
        bushes = {},
        -- Legacy enemy tables (kept for backwards compatibility during migration)
        enemies = {},
        lungers = {},
        treents = {},
        smallTreents = {},
        wizards = {},
        healers = {},
        imps = {},
        slimes = {},
        bats = {},
        wolves = {},
        skeletons = {},
        druids = {},
        -- New unified systems
        enemyManager = nil,
        targetingSystem = nil,
        collisionSystem = nil,
        barkProjectiles = {},
        arrowVolleys = {},
        fireCooldown = 0,
        -- Dash ability
        dashCooldown = 0,
        dashDuration = pCfg.dashDuration,
        dashSpeed = pCfg.dashSpeed,
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
        
        -- Run timer
        timeAlive = 0,

        -- Chain lightning visual (Chain Reaction)
        chainLightningSegments = {},
    }
    setmetatable(scene, GameScene)
    return scene
end

function GameScene:load()
    local Config = require("data.config")
    local Camera = require("systems.camera")
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local worldWidth = Config.World and Config.World.width or screenWidth
    local worldHeight = Config.World and Config.World.height or screenHeight
    
    -- Get selected class stats
    local heroClass = self.gameState.selectedHeroClass
    local difficulty = self.gameState.selectedDifficulty
    local biome = self.gameState.selectedBiome
    
    -- Initialize player with class stats (spawn in center of world)
    self.player = Player:new(worldWidth / 2, worldHeight / 2)
    self.mouseX, self.mouseY = worldWidth / 2, worldHeight / 2
    
    -- Initialize camera
    self.camera = Camera:new(0, 0, worldWidth, worldHeight)
    self.camera:setPosition(self.player.x - screenWidth / 2, self.player.y - screenHeight / 2)
    
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
    
    -- Set JuiceManager screen shake reference
    JuiceManager.setScreenShake(self.screenShake)
    
    -- Use forest tilemap for lush forest biome
    self.forestTilemap = ForestTilemap:new()
    self.tilemap = Tilemap:new() -- Keep as fallback
    
    -- Initialize upgrade systems
    self.xpSystem = XpSystem:new()
    self.playerStats = PlayerStats:new({
        max_health = heroClass and heroClass.baseHP or 100,
        primary_damage = heroClass and heroClass.baseATK or 10,
        move_speed = heroClass and heroClass.baseSpeed or 200,
        attack_speed = heroClass and heroClass.attackSpeed or 1.0,
        range = heroClass and heroClass.attackRange or 350,
    })
    self.rarityCharge = RarityCharge:new()
    self.upgradeUI = UpgradeUI:new()
    self.statsOverlay = StatsOverlay:new()
    self.damageNumbers = DamageNumbers:new()
    self.abilityHUD = AbilityHUD:new()
    
    -- Initialize new systems
    self.enemySpawner = EnemySpawner:new(self)
    self.runTimer = RunTimer:new()
    self.buffBar = BuffBar:new()
    self.bossPortal = nil  -- Spawned at level 10
    
    -- Initialize unified enemy systems
    self.enemyManager = EnemyManager:new()
    self.targetingSystem = TargetingSystem:new(self.enemyManager)
    self.collisionSystem = CollisionSystem:new(self.enemyManager, self.particles, self.damageNumbers, self.screenShake, self.playerStats, self.player)
    
    -- Ability unlock states are set in player.lua (all start locked)
    -- Players choose abilities at levels 1, 2, and 5
    if self.player and self.player.abilities then
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
    
    -- Always unlock Dash (utility ability)
    self.player.abilities.dash.unlocked = true
    
    -- Track starting ability selection for Level 3 auto-unlock
    self.selectedStartingAbility = nil
    
    -- Show ability selection BEFORE spawning enemies (Level 0 selection)
    self.awaitingAbilitySelection = true
    self:showStartingAbilitySelection()
end

-- Show Level 0 ability selection (before enemies spawn)
function GameScene:showStartingAbilitySelection()
    local abilityOptions = {
        {
            id = "ability_power_shot",
            name = "Power Shot",
            description = "[Q] Auto-fires a powerful piercing shot at nearest enemy.\n\n300% damage, guaranteed crit, infinite pierce.\n\nCooldown: 6s",
            rarity = "rare",
            type = "ability_unlock",
            abilityId = "power_shot",
            icon = self.player.abilities.power_shot.icon,
        },
        {
            id = "ability_arrow_volley",
            name = "Arrow Volley",
            description = "[E] Rains arrows at target location, dealing damage in an area.\n\n150% damage, 60 radius AOE.\n\nCooldown: 8s",
            rarity = "rare",
            type = "ability_unlock",
            abilityId = "arrow_volley",
            icon = self.player.abilities.arrow_volley.icon,
        },
    }
    
    self.upgradeUI:show(abilityOptions, function(upgrade)
        if upgrade.type == "ability_unlock" then
            -- Unlock the selected ability
            self.player.abilities[upgrade.abilityId].unlocked = true
            self.selectedStartingAbility = upgrade.abilityId
            print("Starting ability selected: " .. upgrade.name)
            
            -- Now spawn enemies and start the game
            self.awaitingAbilitySelection = false
            self:spawnEnemies()
        end
    end)
end

function GameScene:spawnEnemies()
    local Config = require("data.config")
    local worldWidth = Config.World and Config.World.width or love.graphics.getWidth()
    local worldHeight = Config.World and Config.World.height or love.graphics.getHeight()
    local floor = self.gameState.currentFloor
    
    -- Clear unified registry so we don't keep old floor's enemies
    if self.enemyManager then
        self.enemyManager:clear()
    end
    
    -- Floor-based HP scaling: +25% HP per floor
    local floorScale = 1.0 + (floor - 1) * 0.25
    -- Time-based scaling: harder as run goes on
    local timeScaleRate = (Config.enemy_time_scale and Config.enemy_time_scale.rate) or 0.012
    local timeScaleCap = (Config.enemy_time_scale and Config.enemy_time_scale.cap) or 2.5
    local timeScale = math.min(timeScaleCap, 1.0 + (self.timeAlive or 0) * timeScaleRate)
    
    -- Spawn counts: low at floor 1, steady increase with floor (minute 1 has less monsters)
    local numEnemies = math.max(0, math.floor(floor / 2))
    local numLungers = math.floor(floor / 3)  -- MCM
    local numTreents = math.floor(floor / 3)
    local numSmallTreents = math.floor(floor / 5)  -- MCM
    local numWizards = math.floor(floor / 6)  -- MCM
    local numImps = 1 + math.floor(floor / 3)
    local numSlimes = math.floor(floor / 4)
    local numBats = math.floor(floor / 4)
    local numWolves = 1 + math.floor(floor / 2)
    local numSkeletons = math.floor(floor / 3)
    local numHealers = math.max(0, math.floor((floor - 2) / 2))
    local numDruids = math.floor(floor / 6)  -- MCM
    
    self.enemies = {}
    self.lungers = {}
    self.treents = {}
    self.smallTreents = {}
    self.wizards = {}
    self.healers = {}
    self.imps = {}
    self.slimes = {}
    self.bats = {}
    self.wolves = {}
    self.skeletons = {}
    self.druids = {}
    self.barkProjectiles = {}
    
    -- Spawn regular enemies (off-screen; they move into view)
    for i = 1, numEnemies do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local enemy = Enemy:new(x, y)
        -- Apply difficulty, floor, and time-based scaling
        enemy.health = enemy.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        enemy.maxHealth = enemy.health
        enemy.damage = (enemy.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale
        
        table.insert(self.enemies, enemy)
        self.enemyManager:register(enemy, "enemy")
    end
    
    -- Spawn lungers (MCM - Wolf)
    for i = 1, numLungers do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local lunger = Lunger:new(x, y)
        lunger.health = lunger.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        lunger.maxHealth = lunger.health
        lunger.damage = (lunger.damage or 15) * self.difficultyMult.enemyDamageMult * timeScale
        
        table.insert(self.lungers, lunger)
        self.enemyManager:register(lunger, "lunger")
    end

    -- Spawn treents (tanky elites)
    for i = 1, numTreents do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local treent = Treent:new(x, y)
        treent.health = treent.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        treent.maxHealth = treent.health
        treent.damage = (treent.damage or 18) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.treents, treent)
        self.enemyManager:register(treent, "treent")
    end

    -- Spawn Small Treents (MCM - Bark Thrower)
    for i = 1, numSmallTreents do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local st = SmallTreent:new(x, y)
        st.health = st.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        st.maxHealth = st.health
        st.damage = (st.damage or 9) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.smallTreents, st)
    end

    -- Spawn Wizards (MCM - Root Caster)
    for i = 1, numWizards do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local wiz = Wizard:new(x, y)
        wiz.health = wiz.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        wiz.maxHealth = wiz.health
        wiz.damage = (wiz.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.wizards, wiz)
        self.enemyManager:register(wiz, "wizard")
    end

    -- Spawn Imps (fast swarmers)
    for i = 1, numImps do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local imp = Imp:new(x, y)
        imp.health = imp.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        imp.maxHealth = imp.health
        imp.damage = (imp.damage or 8) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.imps, imp)
        self.enemyManager:register(imp, "imp")
    end

    -- Spawn Slimes (tanks)
    for i = 1, numSlimes do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local slime = Slime:new(x, y)
        slime.health = slime.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        slime.maxHealth = slime.health
        slime.damage = (slime.damage or 12) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.slimes, slime)
        self.enemyManager:register(slime, "slime")
    end

    -- Spawn Bats (erratic flyers)
    for i = 1, numBats do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local bat = Bat:new(x, y)
        bat.health = bat.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        bat.maxHealth = bat.health
        bat.damage = (bat.damage or 8) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.bats, bat)
        self.enemyManager:register(bat, "bat")
    end

    -- Spawn Wolves (lunging chargers)
    for i = 1, numWolves do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local wolf = Wolf:new(x, y)
        wolf.health = wolf.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        wolf.maxHealth = wolf.health
        wolf.damage = (wolf.damage or 12) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.wolves, wolf)
        self.enemyManager:register(wolf, "wolf")
    end

    -- Spawn Skeletons (steady threat)
    for i = 1, numSkeletons do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local skel = Skeleton:new(x, y)
        skel.health = skel.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        skel.maxHealth = skel.health
        skel.damage = (skel.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.skeletons, skel)
        self.enemyManager:register(skel, "skeleton")
    end
    
    -- Spawn Healers (support units that heal wounded allies)
    for i = 1, numHealers do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local healer = Healer:new(x, y)
        healer.health = healer.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        healer.maxHealth = healer.health

        table.insert(self.healers, healer)
        self.enemyManager:register(healer, "healer")
    end

    -- Spawn Druid Treents (MCM - healing support)
    for i = 1, numDruids do
        local x, y = self.enemySpawner:getRandomSpawnPosition()
        local druid = DruidTreent:new(x, y)
        druid.health = druid.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        druid.maxHealth = druid.health
        druid.damage = (druid.damage or 8) * self.difficultyMult.enemyDamageMult * timeScale

        table.insert(self.druids, druid)
        self.enemyManager:register(druid, "druid_treent")
    end
    
    -- Sync spawner count so time-based spawner knows how many exist
    if self.enemySpawner then
        self.enemySpawner.current_enemy_count = #self.enemies + #self.lungers + #self.treents + #self.smallTreents
            + #self.wizards + #self.imps + #self.slimes + #self.bats + #self.wolves
            + #self.skeletons + #self.healers + #self.druids
    end
end

-- Spawn a single enemy at (x,y) - used by time-based EnemySpawner
function GameScene:spawnEnemy(enemy_type, x, y)
    local floor = self.gameState.currentFloor
    local floorScale = 1.0 + (floor - 1) * 0.25
    local timeScaleRate = (Config.enemy_time_scale and Config.enemy_time_scale.rate) or 0.012
    local timeScaleCap = (Config.enemy_time_scale and Config.enemy_time_scale.cap) or 2.5
    local timeScale = math.min(timeScaleCap, 1.0 + (self.timeAlive or 0) * timeScaleRate)
    
    local e
    if enemy_type == "enemy" then
        e = Enemy:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.enemies, e)
    elseif enemy_type == "lunger" then
        e = Lunger:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 15) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.lungers, e)
    elseif enemy_type == "wolf" then
        e = Wolf:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 12) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.wolves, e)
    elseif enemy_type == "treent" then
        e = Treent:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 18) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.treents, e)
    elseif enemy_type == "small_treent" then
        e = SmallTreent:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 9) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.smallTreents, e)
    elseif enemy_type == "wizard" then
        e = Wizard:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.wizards, e)
    elseif enemy_type == "imp" then
        e = Imp:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 8) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.imps, e)
    elseif enemy_type == "slime" then
        e = Slime:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 12) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.slimes, e)
    elseif enemy_type == "bat" then
        e = Bat:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 8) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.bats, e)
    elseif enemy_type == "skeleton" then
        e = Skeleton:new(x, y)
        e.health = e.health * self.difficultyMult.enemyHealthMult * floorScale * timeScale
        e.maxHealth = e.health
        e.damage = (e.damage or 10) * self.difficultyMult.enemyDamageMult * timeScale
        table.insert(self.skeletons, e)
    else
        return
    end
    if e then
        self.enemyManager:register(e, enemy_type)
    end
end

-- Helper: Handle frenzy charge/extension on enemy kill
function GameScene:onEnemyKill(bonusCharge)
    if self.enemySpawner then
        self.enemySpawner:onEnemyDeath()
    end
    bonusCharge = bonusCharge or 0
    local baseGain = self.frenzyKillGain + bonusCharge
    
    if self.frenzyActive then
        -- During Frenzy: check for extend_on_kill mod
        local extendMod = self.playerStats:getAbilityMod("frenzy", "extend_on_kill")
        if extendMod and extendMod.value then
            local maxExtend = extendMod.max_extend or 2.0
            self.frenzyExtendedTime = self.frenzyExtendedTime or 0
            if self.frenzyExtendedTime < maxExtend then
                local extend = math.min(extendMod.value, maxExtend - self.frenzyExtendedTime)
                self.frenzyExtendedTime = self.frenzyExtendedTime + extend
                -- Extend the buff duration
                local buff = self.playerStats.buffs["frenzy"]
                if buff then
                    buff.timeRemaining = buff.timeRemaining + extend
                end
            end
        end
    else
        -- Not in Frenzy: build charge (with charge_gain_mul mod)
        local chargeGainMul = self.playerStats:getAbilityModValue("frenzy", "charge_gain_mul", 1.0)
        local finalGain = baseGain * chargeGainMul
        self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + finalGain)
    end
end

function GameScene:update(dt)
    -- Update upgrade UI (always, even when paused)
    if self.upgradeUI then
        self.upgradeUI:update(dt)
    end

    -- Pause gameplay while stats overlay is open
    self.isPaused = (self.statsOverlay and self.statsOverlay:isVisible()) or false
    
    -- Pause while awaiting starting ability selection (Level 0)
    if self.awaitingAbilitySelection then
        return
    end
    
    -- Check for pending level-ups
    if self.xpSystem and self.xpSystem:hasPendingLevelUp() and not self.upgradeUI:isVisible() then
        self:showUpgradeSelection()
    end
    
    -- Pause gameplay during upgrade selection
    if self.isPaused or (self.upgradeUI and self.upgradeUI:isVisible()) then
        return
    end
    
    -- Hit-stop freeze (JuiceManager) - skip game logic but still update visuals
    if JuiceManager.isFrozen() then
        -- Still update particles during freeze for visual continuity
        self.particles:update(dt)
        return
    end
    
    -- Update systems
    self.particles:update(dt)
    self.screenShake:update(dt)
    -- Expire chain lightning segments
    local now = love.timer.getTime()
    if self.chainLightningSegments and #self.chainLightningSegments > 0 then
        local kept = {}
        for _, seg in ipairs(self.chainLightningSegments) do
            if seg.untilTime and seg.untilTime > now then
                table.insert(kept, seg)
            end
        end
        self.chainLightningSegments = kept
    end
    if self.damageNumbers then
        self.damageNumbers:update(dt)
    end

    -- Spawn ambient leaf particles occasionally (forest atmosphere)
    if math.random() < 0.05 then  -- 5% chance per frame
        local playerX = self.player.x
        local playerY = self.player.y
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        -- Spawn near edges of screen
        local spawnX = playerX + (math.random() - 0.5) * screenWidth
        local spawnY = playerY - screenHeight / 2 + math.random() * 100
        self.particles:createAmbientLeaves(spawnX, spawnY)
    end
    
    -- Update new systems
    if self.enemySpawner then
        self.enemySpawner:update(dt)
    end
    if self.runTimer then
        self.runTimer:update(dt)
    end
    if self.buffBar then
        self.buffBar:update(dt, self.player)
    end
    if self.bossPortal then
        self.bossPortal:update(dt, self.player)

        -- Auto-teleport when player walks over portal (collision-based)
        local dx = self.player.x - self.bossPortal.x
        local dy = self.player.y - self.bossPortal.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < self.bossPortal.radius and self.bossPortal.spawn_animation >= 0.9 then
            if self.bossPortal:activate() then
                -- Transition to boss fight
                self.gameState:enterBossFight()
            end
        end
    end

    -- Update run time
    self.timeAlive = self.timeAlive + dt
    
    -- Update camera to follow player
    if self.camera and self.player then
        self.camera:update(dt, self.player.x, self.player.y)
    end
    
    -- Update XP orbs
    if self.xpSystem and self.player then
        local pickupRadius = self.playerStats and self.playerStats:get("xp_pickup_radius") or 60
        self.xpSystem:update(dt, self.player.x, self.player.y, pickupRadius)
    end
    
    -- Spawn boss portal at level 15
    if self.xpSystem and self.xpSystem.level >= Config.boss_progression.level_required and not self.bossPortal then
        local portalX = self.player.x + 200
        local portalY = self.player.y
        self.bossPortal = BossPortal:new(portalX, portalY)
        
        -- Pause enemy spawner when portal appears
        if self.enemySpawner then
            self.enemySpawner:pause()
        end
    end
    
    -- Update player stats (tick buff durations)
    if self.playerStats then
        -- Keep frenzy flag in sync with buff presence
        self.frenzyActive = self.playerStats:hasBuff("frenzy")
        
        -- Sync frenzy VFX to player
        if self.player then
            self.player.isFrenzyActive = self.frenzyActive
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
    
    -- Update player
    if self.player then
        -- Handle dash
        if self.isDashing then
            self.dashTime = self.dashTime - dt
            if self.dashTime <= 0 then
                self.isDashing = false
                UpgradeApplication.checkProcs(self.player, "after_roll", {})
            else
                -- Move in dash direction
                self.player.x = self.player.x + self.dashDirX * self.dashSpeed * dt
                self.player.y = self.player.y + self.dashDirY * self.dashSpeed * dt
                
                -- Create dash trail particles
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            self.player:update(dt, self.particles)
        end
        
        local playerX, playerY = self.player:getPosition()
        
        -- Find nearest enemy using unified targeting system (includes ALL enemies automatically!)
        local nearestEnemy, nearestDistance = self.targetingSystem:findNearest(playerX, playerY, self.attackRange)
        
        -- Aim at nearest enemy for bow presentation + primary targeting
        if nearestEnemy then
            local ex, ey = nearestEnemy:getPosition()
            self.player:aimAt(ex, ey)
            
            if self.fireCooldown <= 0 and not self.isDashing then
                -- Create primary projectile (auto-target)
                local statMods = (self.player.statusComponent and self.player.statusComponent:getStatModifications()) or {}
                local dmgMul = (statMods.primary_damage and statMods.primary_damage.mul) or 1
                local baseDmg = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * dmgMul
                local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY

                -- Check for on_primary_hit procs (e.g., Barbed Shafts bleed)
                local statusToApply = nil
                local procs = self.playerStats and self.playerStats.weaponMods and self.playerStats.weaponMods.procs
                if procs then
                    for _, proc in ipairs(procs) do
                        if proc.trigger == "on_primary_hit" and proc.apply and proc.apply.kind == "status_apply" then
                            -- Check chance (default 1.0 = 100%)
                            local chance = proc.chance or 1.0
                            if math.random() <= chance then
                                statusToApply = {
                                    status = proc.apply.status,
                                    duration = proc.apply.duration
                                }
                                break  -- Only apply first matching proc
                            end
                        end
                    end
                end

                local ricochetBounces = (self.playerStats and self.playerStats:getWeaponMod("ricochet_bounces")) or 0
                local ricochetRange = (self.playerStats and self.playerStats.weaponMods and self.playerStats.weaponMods.ricochet_range) or 220
                local ghosting = (self.player.statusComponent and (self.player.statusComponent:getWeaponModifications().primary_ghosting or 0) > 0)

                -- every_n_primary_shots context (Light Quiver, Split Shot, Arrowstorm)
                local procContext = {
                    sx = sx, sy = sy, ex = ex, ey = ey,
                    baseDmg = baseDmg, pierce = pierce, statusToApply = statusToApply,
                    ricochetBounces = ricochetBounces, ricochetRange = ricochetRange,
                    apply_weapon_mod = function(apply)
                        if apply.mod == "bonus_projectiles" then
                            local n = math.max(1, apply.value or 1)
                            local spreadDegRad = (apply.spread_deg or 6) * (math.pi / 180)
                            local dx, dy = ex - sx, ey - sy
                            local dist = math.sqrt(dx * dx + dy * dy)
                            if dist < 1 then dist = 1 end
                            local baseAngle = math.atan2(dy, dx)
                            for i = 1, n do
                                local offset = (n > 1) and (i - (n + 1) / 2) * spreadDegRad / math.max(1, n - 1) or 0
                                local angle = baseAngle + offset
                                local tx = sx + math.cos(angle) * 400
                                local ty = sy + math.sin(angle) * 400
                                local extra = Arrow:new(sx, sy, tx, ty, {
                                    damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140,
                                    appliesStatus = statusToApply, ricochetBounces = ricochetBounces, ricochetRange = ricochetRange,
                                })
                                table.insert(self.arrows, extra)
                            end
                        end
                    end,
                    spawn_projectile_burst = function(apply, ctx)
                        local count = apply.count or 12
                        local damageMul = apply.damage_mul or 0.4
                        local speedMul = apply.speed_mul or 0.9
                        local dmg = (ctx.baseDmg or baseDmg) * damageMul
                        local spd = 500 * speedMul
                        for i = 0, count - 1 do
                            local angle = (i / count) * 2 * math.pi
                            local tx = sx + math.cos(angle) * 400
                            local ty = sy + math.sin(angle) * 400
                            local arr = Arrow:new(sx, sy, tx, ty, {
                                damage = dmg, speed = spd, pierce = pierce, kind = "primary", knockback = 140,
                                appliesStatus = statusToApply, ricochetBounces = ricochetBounces, ricochetRange = ricochetRange,
                            })
                            table.insert(self.arrows, arr)
                        end
                    end,
                }
                UpgradeApplication.checkProcs(self.player, "every_n_primary_shots", procContext)

                local arrow = Arrow:new(sx, sy, ex, ey, {
                    damage = baseDmg,
                    pierce = pierce,
                    kind = "primary",
                    knockback = 140,
                    appliesStatus = statusToApply,
                    ricochetBounces = ricochetBounces,
                    ricochetRange = ricochetRange,
                    ghosting = ghosting,
                })
                table.insert(self.arrows, arrow)
                local atkSpd = (self.playerStats and self.playerStats:get("attack_speed")) or 1
                local atkSpdMul = (statMods.attack_speed and statMods.attack_speed.mul) or 1
                self.fireCooldown = 0.4 / (atkSpd * atkSpdMul)
                if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
                if self.player.playAttackAnimation then self.player:playAttackAnimation() end
            end
        end

        -- Auto-cast Power Shot: fires at nearest enemy when ready
        if nearestEnemy and self.player and self.player:isAbilityReady("power_shot") and not self.isDashing then
            local ex, ey = nearestEnemy:getPosition()
            local psCfg = Config.Abilities.powerShot
            self.player:aimAt(ex, ey)
            self.player:useAbility("power_shot", self.playerStats)
            local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
            
            -- Apply ability mods
            local damageMul = self.playerStats:getAbilityModValue("power_shot", "damage_mul", 1.0)
            local base = (self.player.attackDamage or 10) * self.difficultyMult.playerDamageMult * psCfg.damageMult * damageMul
            
            -- Check for elite/MCM bonus damage mod
            local eliteMcmMod = self.playerStats:getAbilityMod("power_shot", "bonus_damage_vs_elite_mcm")
            local appliesStatus = self.playerStats:getAbilityMod("power_shot", "applies_status")
            
            local ps = Arrow:new(sx, sy, ex, ey, {
                damage = base,
                speed = psCfg.speed,
                size = 12,
                lifetime = 1.8,
                pierce = 999,
                alwaysCrit = true,
                kind = "power_shot",
                knockback = psCfg.knockback,
                eliteMcmDamageMul = eliteMcmMod and eliteMcmMod.value or nil,
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
                    sx = sx, sy = sy, ex = ex, ey = ey,
                    damage = base * secondDamageMul,
                    speed = psCfg.speed,
                    knockback = psCfg.knockback,
                    eliteMcmDamageMul = eliteMcmMod and eliteMcmMod.value or nil,
                    appliesStatus = appliesStatus,
                })
            end
        end

        -- Arrow Volley: auto-cast AOE at nearest enemy when ready
        if self.player and self.player:isAbilityReady("arrow_volley") then
            local volleyRange = 300  -- Range to find targets
            local best, bestDist = self.targetingSystem:findNearest(playerX, playerY, volleyRange)
            if best then
                self.player:useAbility("arrow_volley", self.playerStats)
                local tx, ty = best:getPosition()
                -- Spawn Arrow Volley at target location
                local baseDmg = self.playerStats and self.playerStats:get("primary_damage") or 25
                
                -- Apply ability mods
                local damageMul = self.playerStats:getAbilityModValue("arrow_volley", "damage_mul", 1.0)
                local radiusAdd = self.playerStats:getAbilityModValue("arrow_volley", "radius_add", 0)
                local arrowCountAdd = self.playerStats:getAbilityModValue("arrow_volley", "arrow_count_add", 0)
                
                local finalDamage = baseDmg * 1.5 * damageMul
                local finalRadius = 60 + radiusAdd
                
                local volley = ArrowVolley:new(tx, ty, finalDamage, finalRadius, arrowCountAdd)
                if volley then
                    table.insert(self.arrowVolleys, volley)
                end
                self.screenShake:add(3, 0.15)
                
                -- Handle double_strike mod: spawn second volley after delay
                local doubleStrikeMod = self.playerStats:getAbilityMod("arrow_volley", "double_strike")
                if doubleStrikeMod then
                    local delay = doubleStrikeMod.delay or 0.3
                    local secondVolleyDamageMul = doubleStrikeMod.second_volley_damage_mul or 1.0
                    self.pendingArrowVolleys = self.pendingArrowVolleys or {}
                    table.insert(self.pendingArrowVolleys, {
                        timer = delay,
                        tx = tx, ty = ty,
                        damage = finalDamage * secondVolleyDamageMul,
                        radius = finalRadius,
                        arrowCountAdd = arrowCountAdd,
                    })
                end
            end
        end

        -- Frenzy is USER-ACTIVATED (press R). We only build charge here.
        
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
                        eliteMcmDamageMul = pending.eliteMcmDamageMul,
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
                    local volley = ArrowVolley:new(pending.tx, pending.ty, pending.damage, pending.radius, pending.arrowCountAdd)
                    if volley then
                        table.insert(self.arrowVolleys, volley)
                    end
                    table.remove(self.pendingArrowVolleys, i)
                end
            end
        end
        
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
                        if arrow.ghosting then
                            -- Ghost Quiver: arrow passes through, no damage/hit
                        else
                            arrow:markHit(enemy)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (enemy.isElite or enemy.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                -- Power Shot: full impact (freeze, shake, flash)
                                JuiceManager.impact(enemy, 0.05, 10, 0.15, 0.1)
                                -- Big particle burst for power shot
                                self.particles:createHitSpark(ex, ey, {1, 0.9, 0.3})
                                self.particles:createExplosion(ex, ey, {1, 0.8, 0.2})
                            elseif isCrit then
                                -- Critical hit: mini impact (smaller freeze, shake, flash)
                                JuiceManager.impact(enemy, 0.02, 4, 0.08, 0.06)
                                -- Medium particle burst for crit
                                self.particles:createHitSpark(ex, ey, {1, 1, 0.3})
                            else
                                -- Normal hit: just flash + small particles
                                JuiceManager.flash(enemy, 0.04)
                                self.particles:createHitSpark(ex, ey, {1, 1, 0.6})
                            end
                            if self.damageNumbers then
                                self.damageNumbers:add(ex, ey - enemy:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = enemy:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable (e.g., bleed, shattered_armor)
                            if arrow.appliesStatus and enemy.statusComponent then
                                local statusData = arrow.appliesStatus
                                enemy.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }  -- Pass damage for DoT calculations
                                )
                            end
                            
                            -- Trigger upgrade procs on hit
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = enemy, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(enemy, dmg, isCrit))
                                end
                            end
                            
                            if died then
                                if enemy.statusComponent and enemy.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(enemy, "bleed"))
                                end
                                self.particles:createExplosion(ex, ey, {1, 0.3, 0.1})
                                -- Death juice: bigger shake
                                JuiceManager.shake(6, 0.15)
                                
                                -- Notify spawner of death
                                
                                -- Drop XP orbs
                                local baseXP = 5 + math.random(0, 5)
                                local xpValue = enemy.isMCM and (baseXP * 5) or baseXP  -- MCM bonus!
                                self.xpSystem:spawnOrb(ex, ey, xpValue)
                                
                                -- Add rarity charge for special enemies
                                if enemy.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), 1)
                                end

                                -- Frenzy charge on kill (or extend if active)
                                self:onEnemyKill(0)
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, ex, ey)
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
            
            -- Check lungers
            if not hitEnemy then
                for j, lunger in ipairs(self.lungers) do
                    if lunger.isAlive then
                        local lx, ly = lunger:getPosition()
                        local dx = ax - lx
                        local dy = ay - ly
                        local distance = math.sqrt(dx * dx + dy * dy)
                        
                        if distance < lunger:getSize() + arrow:getSize() and arrow:canHit(lunger) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(lunger)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (lunger.isElite or lunger.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(lunger, 0.05, 10, 0.15, 0.1)
                                -- Big particle burst
                                self.particles:createHitSpark(lx, ly, {1, 0.9, 0.3})
                                self.particles:createExplosion(lx, ly, {1, 0.8, 0.2})
                            elseif isCrit then
                                JuiceManager.impact(lunger, 0.02, 4, 0.08, 0.06)
                                -- Medium particle burst
                                self.particles:createHitSpark(lx, ly, {1, 1, 0.3})
                            else
                                JuiceManager.flash(lunger, 0.04)
                            end
                            
                            self.particles:createHitSpark(lx, ly, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(lx, ly - lunger:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = lunger:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and lunger.statusComponent then
                                local statusData = arrow.appliesStatus
                                lunger.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end
                            
                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = lunger, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(lunger, dmg, isCrit))
                                end
                            end
                            
                            if died then
                                if lunger.statusComponent and lunger.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(lunger, "bleed"))
                                end
                                self.particles:createExplosion(lx, ly, {0.8, 0.3, 0.8})
                                -- MCM death: bigger impact
                                JuiceManager.impact(lunger, 0.03, 8, 0.2, 0.12)
                                
                                -- Drop XP orbs (lungers are MCM - massive XP!)
                                local baseXP = 10 + math.random(0, 5)
                                local xpValue = lunger.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(lx, ly, xpValue)
                                
                                -- Lungers are MCM-type enemies, add rarity charge
                                self.rarityCharge:add(love.timer.getTime(), 2)

                                -- Frenzy charge on kill (lungers count as bigger kills)
                                self:onEnemyKill(5)
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, lx, ly)
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
                            if arrow.ghosting then
                            else
                            arrow:markHit(treent)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (treent.isElite or treent.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(treent, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(treent, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(treent, 0.04)
                            end
                            
                            self.particles:createHitSpark(tx, ty, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(tx, ty - treent:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = treent:takeDamage(dmg, ax, ay, arrow.knockback and (arrow.knockback * 0.75) or nil)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and treent.statusComponent then
                                local statusData = arrow.appliesStatus
                                treent.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = treent, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(treent, dmg, isCrit))
                                end
                            end

                            if died then
                                if treent.statusComponent and treent.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(treent, "bleed"))
                                end
                                self.particles:createExplosion(tx, ty, {0.2, 0.9, 0.2})
                                -- Elite death: big shake
                                JuiceManager.impact(treent, 0.04, 10, 0.25, 0.15)
                                local xpValue = 25 + math.random(0, 10)
                                self.xpSystem:spawnOrb(tx, ty, xpValue)
                            else
                                self.screenShake:add(3, 0.12)
                            end
                            self:tryRicochet(arrow, tx, ty)
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
                            if arrow.ghosting then
                            else
                            arrow:markHit(st)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (st.isElite or st.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(st, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(st, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(st, 0.04)
                            end
                            
                            self.particles:createHitSpark(stx, sty, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(stx, sty - st:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = st:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and st.statusComponent then
                                local statusData = arrow.appliesStatus
                                st.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = st, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(st, dmg, isCrit))
                                end
                            end

                            if died then
                                if st.statusComponent and st.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(st, "bleed"))
                                end
                                self.particles:createExplosion(stx, sty, {0.3, 1, 0.3})
                                -- MCM death: bigger impact
                                JuiceManager.impact(st, 0.03, 8, 0.2, 0.12)
                                -- MCM: 5x XP!
                                local baseXP = 14 + math.random(0, 6)
                                local xpValue = st.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(stx, sty, xpValue)
                                -- Also grant rarity charge
                                if st.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), 2)
                                end
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, stx, sty)
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
                            if arrow.ghosting then
                            else
                            arrow:markHit(wiz)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (wiz.isElite or wiz.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(wiz, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(wiz, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(wiz, 0.04)
                            end
                            
                            self.particles:createHitSpark(wx, wy, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(wx, wy - wiz:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = wiz:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and wiz.statusComponent then
                                local statusData = arrow.appliesStatus
                                wiz.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = wiz, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(wiz, dmg, isCrit))
                                end
                            end

                            if died then
                                if wiz.statusComponent and wiz.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(wiz, "bleed"))
                                end
                                self.particles:createExplosion(wx, wy, {0.7, 0.4, 1})
                                -- MCM death: bigger impact
                                JuiceManager.impact(wiz, 0.03, 8, 0.2, 0.12)
                                -- MCM: 5x XP!
                                local baseXP = 12 + math.random(0, 6)
                                local xpValue = wiz.isMCM and (baseXP * 5) or baseXP
                                self.xpSystem:spawnOrb(wx, wy, xpValue)
                                -- Also grant rarity charge
                                if wiz.isMCM then
                                    self.rarityCharge:add(love.timer.getTime(), 2)
                                end
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, wx, wy)
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
            end

            -- Check Imps
            if not hitEnemy then
                for _, imp in ipairs(self.imps) do
                    if imp.isAlive then
                        local ix, iy = imp:getPosition()
                        local dx = ax - ix
                        local dy = ay - iy
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < imp:getSize() + arrow:getSize() and arrow:canHit(imp) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(imp)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (imp.isElite or imp.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(imp, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(imp, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(imp, 0.04)
                            end
                            
                            self.particles:createHitSpark(ix, iy, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(ix, iy - imp:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = imp:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and imp.statusComponent then
                                local statusData = arrow.appliesStatus
                                imp.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = imp, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(imp, dmg, isCrit))
                                end
                            end

                            if died then
                                if imp.statusComponent and imp.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(imp, "bleed"))
                                end
                                self.particles:createExplosion(ix, iy, {1, 0.2, 0.2})
                                JuiceManager.shake(4, 0.12)
                                local xpValue = 3 + math.random(0, 3)
                                self.xpSystem:spawnOrb(ix, iy, xpValue)
                            else
                                self.screenShake:add(1, 0.08)
                            end
                            self:tryRicochet(arrow, ix, iy)
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
            end

            -- Check Slimes
            if not hitEnemy then
                for _, slime in ipairs(self.slimes) do
                    if slime.isAlive then
                        local sx, sy = slime:getPosition()
                        local dx = ax - sx
                        local dy = ay - sy
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < slime:getSize() + arrow:getSize() and arrow:canHit(slime) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(slime)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (slime.isElite or slime.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(slime, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(slime, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(slime, 0.04)
                            end
                            
                            self.particles:createHitSpark(sx, sy, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(sx, sy - slime:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = slime:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and slime.statusComponent then
                                local statusData = arrow.appliesStatus
                                slime.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = slime, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(slime, dmg, isCrit))
                                end
                            end

                            if died then
                                if slime.statusComponent and slime.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(slime, "bleed"))
                                end
                                self.particles:createExplosion(sx, sy, {0.5, 0.5, 0.5})
                                JuiceManager.shake(5, 0.15)
                                local xpValue = 7 + math.random(0, 4)
                                self.xpSystem:spawnOrb(sx, sy, xpValue)
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, sx, sy)
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
            end

            -- Check Bats
            if not hitEnemy then
                for _, bat in ipairs(self.bats) do
                    if bat.isAlive then
                        local bx, by = bat:getPosition()
                        local dx = ax - bx
                        local dy = ay - by
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < bat:getSize() + arrow:getSize() and arrow:canHit(bat) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(bat)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                            
                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (bat.isElite or bat.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end
                            
                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(bat, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(bat, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(bat, 0.04)
                            end
                            
                            self.particles:createHitSpark(bx, by, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(bx, by - bat:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = bat:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and bat.statusComponent then
                                local statusData = arrow.appliesStatus
                                bat.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = bat, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(bat, dmg, isCrit))
                                end
                            end

                            if died then
                                if bat.statusComponent and bat.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(bat, "bleed"))
                                end
                                self.particles:createExplosion(bx, by, {0.6, 0.4, 0.2})
                                JuiceManager.shake(4, 0.12)
                                local xpValue = 4 + math.random(0, 3)
                                self.xpSystem:spawnOrb(bx, by, xpValue)
                            else
                                self.screenShake:add(1, 0.08)
                            end
                            self:tryRicochet(arrow, bx, by)
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

            -- Check Wolves
            if not hitEnemy then
                for _, wolf in ipairs(self.wolves) do
                    if wolf.isAlive then
                        local wx, wy = wolf.x, wolf.y
                        local dx = ax - wx
                        local dy = ay - wy
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < wolf:getSize() + arrow:getSize() and arrow:canHit(wolf) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(wolf)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)

                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (wolf.isElite or wolf.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end

                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(wolf, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(wolf, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(wolf, 0.04)
                            end

                            self.particles:createHitSpark(wx, wy, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(wx, wy - wolf:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = wolf:takeDamage(dmg, ax, ay, arrow.knockback)

                            -- Apply status effect if applicable
                            if arrow.appliesStatus and wolf.statusComponent then
                                local statusData = arrow.appliesStatus
                                wolf.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = wolf, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(wolf, dmg, isCrit))
                                end
                            end

                            if died then
                                if wolf.statusComponent and wolf.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(wolf, "bleed"))
                                end
                                self.particles:createExplosion(wx, wy, {0.7, 0.7, 0.8})
                                JuiceManager.shake(5, 0.14)
                                local xpValue = 12 + math.random(0, 4)
                                self.xpSystem:spawnOrb(wx, wy, xpValue)
                                self:onEnemyKill()
                            else
                                self.screenShake:add(2, 0.10)
                            end
                            self:tryRicochet(arrow, wx, wy)
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
            end

            -- Check Skeletons
            if not hitEnemy then
                for _, skel in ipairs(self.skeletons) do
                    if skel.isAlive then
                        local skx, sky = skel:getPosition()
                        local dx = ax - skx
                        local dy = ay - sky
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < skel:getSize() + arrow:getSize() and arrow:canHit(skel) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(skel)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)

                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (skel.isElite or skel.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end

                            -- Juice effects based on hit type
                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(skel, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(skel, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(skel, 0.04)
                            end
                            
                            self.particles:createHitSpark(skx, sky, {1, 1, 0.6})
                            if self.damageNumbers then
                                self.damageNumbers:add(skx, sky - skel:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = skel:takeDamage(dmg, ax, ay, arrow.knockback)
                            
                            -- Apply status effect if applicable
                            if arrow.appliesStatus and skel.statusComponent then
                                local statusData = arrow.appliesStatus
                                skel.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            -- Trigger upgrade procs
                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = skel, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(skel, dmg, isCrit))
                                end
                            end

                            if died then
                                if skel.statusComponent and skel.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(skel, "bleed"))
                                end
                                self.particles:createExplosion(skx, sky, {0.6, 0.6, 0.6})
                                JuiceManager.shake(5, 0.15)
                                local xpValue = 6 + math.random(0, 4)
                                self.xpSystem:spawnOrb(skx, sky, xpValue)
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, skx, sky)
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
            end

            -- Check Healers
            if not hitEnemy then
                for _, healer in ipairs(self.healers) do
                    if healer.isAlive then
                        local hx, hy = healer:getPosition()
                        local dx = ax - hx
                        local dy = ay - hy
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < healer:getSize() + arrow:getSize() and arrow:canHit(healer) then
                            arrow:markHit(healer)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)

                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (healer.isElite or healer.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end

                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(healer, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(healer, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(healer, 0.04)
                            end

                            self.particles:createHitSpark(hx, hy, {0.5, 1, 0.7})
                            if self.damageNumbers then
                                self.damageNumbers:add(hx, hy - healer:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = healer:takeDamage(dmg, ax, ay, arrow.knockback)

                            -- Apply status effect if applicable
                            if arrow.appliesStatus and healer.statusComponent then
                                local statusData = arrow.appliesStatus
                                healer.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = healer, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(healer, dmg, isCrit))
                                end
                            end

                            if died then
                                if healer.statusComponent and healer.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(healer, "bleed"))
                                end
                                self.particles:createExplosion(hx, hy, {0.5, 1, 0.7})
                                JuiceManager.shake(4, 0.12)
                                local xpValue = 8 + math.random(0, 4)
                                self.xpSystem:spawnOrb(hx, hy, xpValue)
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, hx, hy)
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
            end

            -- Check Druid Treents
            if not hitEnemy then
                for _, druid in ipairs(self.druids) do
                    if druid.isAlive then
                        local dx2 = ax - druid.x
                        local dy2 = ay - druid.y
                        local distance = math.sqrt(dx2 * dx2 + dy2 * dy2)

                        if distance < druid:getSize() + arrow:getSize() and arrow:canHit(druid) then
                            if arrow.ghosting then
                            else
                            arrow:markHit(druid)
                            local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)

                            -- Apply elite/MCM damage bonus if applicable
                            if arrow.eliteMcmDamageMul and (druid.isElite or druid.isMCM) then
                                dmg = dmg * arrow.eliteMcmDamageMul
                            end

                            if arrow.kind == "power_shot" then
                                JuiceManager.impact(druid, 0.05, 10, 0.15, 0.1)
                            elseif isCrit then
                                JuiceManager.impact(druid, 0.02, 4, 0.08, 0.06)
                            else
                                JuiceManager.flash(druid, 0.04)
                            end

                            self.particles:createHitSpark(druid.x, druid.y, {0.4, 0.9, 0.5})
                            if self.damageNumbers then
                                self.damageNumbers:add(druid.x, druid.y - druid:getSize(), dmg, { isCrit = isCrit })
                            end
                            local died = druid:takeDamage(dmg, ax, ay, arrow.knockback)

                            -- Apply status effect if applicable
                            if arrow.appliesStatus and druid.statusComponent then
                                local statusData = arrow.appliesStatus
                                druid.statusComponent:applyStatus(
                                    statusData.status,
                                    1,
                                    statusData.duration,
                                    { damage = arrow.damage }
                                )
                            end

                            if arrow.kind == "primary" then
                                UpgradeApplication.checkProcs(self.player, "on_primary_hit", { target = druid, damage = dmg, is_crit = isCrit })
                                if isCrit then
                                    UpgradeApplication.checkProcs(self.player, "on_crit_hit", self:buildOnCritHitContext(druid, dmg, isCrit))
                                end
                            end

                            if died then
                                if druid.statusComponent and druid.statusComponent:hasStatus("bleed") then
                                    UpgradeApplication.checkProcs(self.player, "on_kill_target_with_status", self:buildOnKillWithStatusContext(druid, "bleed"))
                                end
                                self.particles:createExplosion(druid.x, druid.y, {0.4, 0.75, 0.3})
                                JuiceManager.shake(5, 0.14)
                                local xpValue = 18 + math.random(0, 6)
                                self.xpSystem:spawnOrb(druid.x, druid.y, xpValue)
                                self:onEnemyKill()
                            else
                                self.screenShake:add(2, 0.1)
                            end
                            self:tryRicochet(arrow, druid.x, druid.y)
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
            if not inCombat then
                for _, e in ipairs(self.wolves) do if e.isAlive then inCombat = true break end end
            end
            if not inCombat then
                for _, e in ipairs(self.druids) do if e.isAlive then inCombat = true break end end
            end
            if inCombat then
                local chargeGainMul = self.playerStats:getAbilityModValue("frenzy", "charge_gain_mul", 1.0)
                self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + (self.frenzyCombatGainPerSec * dt * chargeGainMul))
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
                -- Update status component with bleed damage callback
                if enemy.statusComponent then
                    enemy.statusComponent:update(dt, enemy, function(owner, damage, statusName)
                        if statusName == "bleed" then
                            local ex, ey = owner:getPosition()

                            -- Spawn red damage number
                            if self.damageNumbers then
                                self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                    isCrit = false,
                                    damageType = "bleed",
                                    vy = -20,  -- Slower rise for DOT
                                })
                            end

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

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
                        if wasHit then
                            enemy.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
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
                -- Update status component with bleed damage callback
                if lunger.statusComponent then
                    lunger.statusComponent:update(dt, lunger, function(owner, damage, statusName)
                        if statusName == "bleed" then
                            local ex, ey = owner:getPosition()

                            -- Spawn red damage number
                            if self.damageNumbers then
                                self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                    isCrit = false,
                                    damageType = "bleed",
                                    vy = -20,
                                })
                            end

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

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
                        if wasHit then
                            lunger.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(6, 0.2)
                        end
                    end
                end
            end
        end

        -- Update treents (no vine attack on regular map)
        for _, treent in ipairs(self.treents) do
            if treent.isAlive then
                -- Update status component with bleed damage callback
                if treent.statusComponent then
                    treent.statusComponent:update(dt, treent, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                treent:update(dt, playerX, playerY, nil)

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
                        if wasHit then
                            treent.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
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

                -- Update status component with bleed damage callback
                if st.statusComponent then
                    st.statusComponent:update(dt, st, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
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
                        if wasHit then
                            st.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
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
                local onConeAttack = function(wx, wy, angleToPlayer, coneAngle, coneRange, _rootDur)
                    -- Check if player is in cone (no root on regular map; damage only)
                    local pdx = playerX - wx
                    local pdy = playerY - wy
                    local distToPlayer = math.sqrt(pdx * pdx + pdy * pdy)
                    if distToPlayer < coneRange then
                        local angleToP = math.atan2(pdy, pdx)
                        local angleDiff = math.abs(((angleToP - angleToPlayer + math.pi) % (2 * math.pi)) - math.pi)
                        if angleDiff < coneAngle / 2 then
                            -- Player hit by cone: damage only (root removed)
                            local coneDmg = 15 * self.difficultyMult.enemyDamageMult
                            if self.frenzyActive then coneDmg = coneDmg * 1.15 end
                            self.player:takeDamage(coneDmg)
                            self.screenShake:add(4, 0.15)
                            -- Visual feedback
                            self.particles:createExplosion(playerX, playerY, {0.8, 0.3, 1})
                        end
                    end
                end

                -- Update status component with bleed damage callback
                if wiz.statusComponent then
                    wiz.statusComponent:update(dt, wiz, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
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
                        if wasHit then
                            wiz.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(4, 0.15)
                        end
                    end
                end
            end
        end

        -- Update Imps
        for _, imp in ipairs(self.imps) do
            if imp.isAlive then
                -- Update status component with bleed damage callback
                if imp.statusComponent then
                    imp.statusComponent:update(dt, imp, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                imp:update(dt, playerX, playerY)

                if not self.isDashing then
                    local ix, iy = imp:getPosition()
                    local dx = playerX - ix
                    local dy = playerY - iy
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + imp:getSize() then
                        local damage = 8 * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit then
                            imp.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(3, 0.12)
                        end
                    end
                end
            end
        end

        -- Update Slimes
        for _, slime in ipairs(self.slimes) do
            if slime.isAlive then
                -- Update status component with bleed damage callback
                if slime.statusComponent then
                    slime.statusComponent:update(dt, slime, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                slime:update(dt, playerX, playerY)

                if not self.isDashing then
                    local sx, sy = slime:getPosition()
                    local dx = playerX - sx
                    local dy = playerY - sy
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + slime:getSize() then
                        local damage = 12 * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit then
                            slime.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(5, 0.18)
                        end
                    end
                end
            end
        end

        -- Update Bats
        for _, bat in ipairs(self.bats) do
            if bat.isAlive then
                -- Update status component with bleed damage callback
                if bat.statusComponent then
                    bat.statusComponent:update(dt, bat, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                bat:update(dt, playerX, playerY)

                if not self.isDashing then
                    local bx, by = bat:getPosition()
                    local dx = playerX - bx
                    local dy = playerY - by
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + bat:getSize() then
                        local damage = 9 * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit then
                            bat.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(3, 0.12)
                        end
                    end
                end
            end
        end

        -- Update Skeletons
        for _, skel in ipairs(self.skeletons) do
            if skel.isAlive then
                -- Update status component with bleed damage callback
                if skel.statusComponent then
                    skel.statusComponent:update(dt, skel, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                skel:update(dt, playerX, playerY)

                if not self.isDashing then
                    local skx, sky = skel:getPosition()
                    local dx = playerX - skx
                    local dy = playerY - sky
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + skel:getSize() then
                        local damage = 10 * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit then
                            skel.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(4, 0.15)
                        end
                    end
                end
            end
        end

        -- Update Wolves (lunging chargers)
        for _, wolf in ipairs(self.wolves) do
            if wolf.isAlive then
                -- Update status component with bleed damage callback
                if wolf.statusComponent then
                    wolf.statusComponent:update(dt, wolf, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                wolf:update(dt, playerX, playerY)

                if not self.isDashing then
                    local wx, wy = wolf.x, wolf.y
                    local dx = playerX - wx
                    local dy = playerY - wy
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + wolf:getSize() then
                        local damage = wolf.damage * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health

                        -- Apply knockback based on wolf state
                        local knockbackForce = wolf:getKnockbackForce()
                        local knockbackX = (dx / distance) * knockbackForce
                        local knockbackY = (dy / distance) * knockbackForce
                        self.player:takeDamage(damage)

                        local wasHit = self.player.health < before
                        if wasHit then
                            wolf.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            local shakeAmount = wolf.state == "lunging" and 6 or 4
                            self.screenShake:add(shakeAmount, 0.15)
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
        
        -- Update Healers
        for _, healer in ipairs(self.healers) do
            if healer.isAlive then
                -- Build list of all enemies for healer AI
                local allEnemies = {}
                for _, e in ipairs(self.enemies) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.lungers) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.treents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.smallTreents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wizards) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.healers) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.imps) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.slimes) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.bats) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wolves) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.skeletons) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.druids) do table.insert(allEnemies, e) end

                -- Update status component with bleed damage callback
                if healer.statusComponent then
                    healer.statusComponent:update(dt, healer, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                healer:update(dt, playerX, playerY, allEnemies)

                -- Healers don't attack player (support only)
            end
        end

        -- Update Druid Treents (MCM - healing support)
        for _, druid in ipairs(self.druids) do
            if druid.isAlive then
                -- Build list of all enemies for druid AI
                local allEnemies = {}
                for _, e in ipairs(self.enemies) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.lungers) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.treents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.smallTreents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wizards) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.healers) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.imps) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.slimes) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.bats) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wolves) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.skeletons) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.druids) do table.insert(allEnemies, e) end

                -- Update status component with bleed damage callback
                if druid.statusComponent then
                    druid.statusComponent:update(dt, druid, function(owner, damage, statusName)
                        if statusName == "bleed" and self.damageNumbers then
                            local ex, ey = owner:getPosition()
                            self.damageNumbers:add(ex, ey - owner:getSize(), damage, {
                                isCrit = false,
                                damageType = "bleed",
                                vy = -20,
                            })

                            -- Spawn bleed particle droplets
                            if self.particles then
                                self.particles:createBleedEffect(ex, ey)
                            end
                        end
                    end)
                end

                druid:update(dt, playerX, playerY, allEnemies)

                -- Druids have contact damage
                if not self.isDashing then
                    local dx = playerX - druid.x
                    local dy = playerY - druid.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < self.player:getSize() + druid:getSize() then
                        local damage = druid.damage * self.difficultyMult.enemyDamageMult
                        if self.frenzyActive then damage = damage * 1.15 end
                        local before = self.player.health
                        self.player:takeDamage(damage)
                        local wasHit = self.player.health < before
                        if wasHit then
                            druid.lastMeleeHitAt = love.timer.getTime()
                            if self.playerStats then
                                self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive })
                            end
                        end
                        if not self.player:isInvincible() then
                            self.screenShake:add(4, 0.15)
                        end
                    end
                end
            end
        end

        -- Update Arrow Volleys
        for i = #self.arrowVolleys, 1, -1 do
            local volley = self.arrowVolleys[i]
            volley:update(dt)
            
            -- Apply damage when animation reaches damage frame
            if volley:shouldApplyDamage() then
                local damage = volley:getDamage()
                -- Check all enemy types
                local allEnemies = {}
                for _, e in ipairs(self.enemies) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.lungers) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.treents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.smallTreents) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wizards) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.imps) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.slimes) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.bats) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.wolves) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.skeletons) do table.insert(allEnemies, e) end
                for _, e in ipairs(self.druids) do table.insert(allEnemies, e) end
                
                local hitEnemies = volley:getEnemiesInRadius(allEnemies)
                for _, enemy in ipairs(hitEnemies) do
                    local vx, vy = volley:getPosition()
                    local ex, ey = enemy:getPosition()
                    local died = enemy:takeDamage(damage, vx, vy, 80)
                    
                    -- Arrow Volley hit: flash and mini shake
                    JuiceManager.flash(enemy, 0.06)
                    
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - enemy:getSize(), damage, { isCrit = false })
                    end
                    self.particles:createHitSpark(ex, ey, {1, 0.8, 0.2})
                    
                    if died then
                        self.particles:createExplosion(ex, ey, {1, 0.5, 0.1})
                        -- Death during volley: shake
                        JuiceManager.shake(5, 0.12)
                        -- Drop XP
                        local xpValue = 10 + math.random(0, 10)
                        if enemy.isMCM then xpValue = xpValue * 5 end
                        self.xpSystem:spawnOrb(ex, ey, xpValue)
                        -- Frenzy charge (or extend if active)
                        self:onEnemyKill(0)
                    end
                end
                self.screenShake:add(4, 0.2)
            end
            
            -- Remove finished volleys
            if volley:isFinished() then
                table.remove(self.arrowVolleys, i)
            end
        end
    end
end

-- Ricochet: after a primary arrow hits, bounce to nearest unhit enemy in range
function GameScene:tryRicochet(arrow, hitX, hitY)
    if arrow.kind ~= "primary" or not arrow.ricochetBounces or arrow.ricochetBounces <= 0 then return end
    local range = arrow.ricochetRange or 220
    local alive = self.enemyManager:getAlive()
    local best, bestDist = nil, range
    for _, e in ipairs(alive) do
        if not arrow.hit[e] then
            local ex, ey = e:getPosition()
            local dx = ex - hitX
            local dy = ey - hitY
            local d = math.sqrt(dx * dx + dy * dy)
            if d < bestDist and d > 0 then
                best = e
                bestDist = d
            end
        end
    end
    if not best then return end
    local tx, ty = best:getPosition()
    local child = Arrow:new(hitX, hitY, tx, ty, {
        damage = arrow.damage,
        pierce = arrow.pierce,
        kind = "primary",
        knockback = arrow.knockback or 140,
        appliesStatus = arrow.appliesStatus,
        ricochetBounces = arrow.ricochetBounces - 1,
        ricochetRange = arrow.ricochetRange,
    })
    for k in pairs(arrow.hit) do child.hit[k] = true end
    table.insert(self.arrows, child)
end

-- Build context for on_crit_hit procs (includes deal_chain_damage for Chain Reaction)
function GameScene:buildOnCritHitContext(target, damage, isCrit)
    local ctx = { target = target, damage = damage, is_crit = isCrit }
    ctx.deal_chain_damage = function(apply, innerCtx)
        local t = innerCtx.target
        local tx, ty = t:getPosition()
        local range = apply.range or 180
        local jumps = apply.jumps or 2
        local chainDmg = (innerCtx.damage or damage) * (apply.damage_mul or 0.35)
        local alive = self.enemyManager:getAlive()
        local candidates = {}
        for _, e in ipairs(alive) do
            if e ~= t and (e.isAlive == nil or e.isAlive) then
                local ex, ey = e:getPosition()
                local d = math.sqrt((ex - tx)^2 + (ey - ty)^2)
                if d <= range and d > 0 then
                    table.insert(candidates, { e = e, d = d })
                end
            end
        end
        table.sort(candidates, function(a, b) return a.d < b.d end)
        local now = love.timer.getTime()
        for i = 1, math.min(jumps, #candidates) do
            local ent = candidates[i].e
            local ex, ey = ent:getPosition()
            ent:takeDamage(chainDmg, tx, ty, 0)
            if self.damageNumbers then
                self.damageNumbers:add(ex, ey - (ent:getSize() or 16), chainDmg, { isCrit = false })
            end
            self.particles:createHitSpark(ex, ey, {0.6, 0.8, 1})
            table.insert(self.chainLightningSegments, { x1 = tx, y1 = ty, x2 = ex, y2 = ey, untilTime = now + 0.12 })
        end
    end
    return ctx
end

-- Build context for on_kill_target_with_status (Hemorrhage: trigger_aoe_explosion)
function GameScene:buildOnKillWithStatusContext(target, status)
    local tx, ty = target:getPosition()
    local ctx = { target = target, status = status }
    ctx.trigger_aoe_explosion = function(apply, innerCtx)
        local t = innerCtx.target
        local cx, cy = t:getPosition()
        local radius = apply.radius or 90
        local maxHp = t.maxHealth or t.hp or 100
        local dmg = maxHp * (apply.damage_mul_of_target_maxhp or 0.06)
        local alive = self.enemyManager:getAlive()
        for _, e in ipairs(alive) do
            if e ~= t and (e.isAlive == nil or e.isAlive) then
                local ex, ey = e:getPosition()
                local d = math.sqrt((ex - cx)^2 + (ey - cy)^2)
                if d <= radius then
                    e:takeDamage(dmg, cx, cy, 0)
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - (e:getSize() or 16), dmg, { isCrit = false })
                    end
                    self.particles:createHitSpark(ex, ey, {0.9, 0.2, 0.1})
                end
            end
        end
        self.particles:createExplosion(cx, cy, {0.8, 0.1, 0.1})
    end
    return ctx
end

function GameScene:advanceFloor()
    -- Check if boss floor (after clearing floor 4)
    if self.gameState.currentFloor == 4 then
        -- Transition to boss arena
        self.gameState:nextFloor()
        self.gameState:transitionTo(self.gameState.States.BOSS_FIGHT)
        return
    end
    
    local continued = self.gameState:nextFloor()
    if continued then
        -- Heal player slightly between floors
        self.player.health = math.min(self.player.maxHealth, self.player.health + 20)
        -- Spawn new enemies
        self:spawnEnemies()
        -- Reset arrows
        self.arrows = {}
        self.barkProjectiles = {}
    end
end

function GameScene:showUpgradeSelection()
    -- #region agent log
    local logFile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
    if logFile then logFile:write('{"hypothesisId":"H1","location":"game_scene.lua:showUpgradeSelection","message":"showUpgradeSelection called","data":{"hasPending":'..tostring(self.xpSystem:hasPendingLevelUp())..',"level":'..tostring(self.xpSystem.level)..'},"timestamp":'..os.time()..'}\n') logFile:close() end
    -- #endregion
    if not self.xpSystem:hasPendingLevelUp() then return end
    
    -- Consume the level-up
    self.xpSystem:consumeLevelUp()
    local currentLevel = self.xpSystem.level
    
    -- Apply per-level base stat gains (HP and attack)
    local gains = Config.level_up_base_gains or {}
    local hp_gain = gains.level_up_hp_gain or 10
    local atk_gain = gains.level_up_attack_gain or 1
    self.playerStats.base.max_health = (self.playerStats.base.max_health or self.player.maxHealth) + hp_gain
    self.playerStats.base.primary_damage = (self.playerStats.base.primary_damage or self.player.attackDamage) + atk_gain
    self:applyStatsToPlayer()
    
    -- #region agent log
    local logFile2 = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
    if logFile2 then logFile2:write('{"hypothesisId":"H1","location":"game_scene.lua:showUpgradeSelection","message":"level consumed","data":{"currentLevel":'..tostring(currentLevel)..'},"timestamp":'..os.time()..'}\n') logFile2:close() end
    -- #endregion
    
    -- Auto-unlock abilities at specific levels (no selection UI, just unlock + continue to regular upgrade)
    local abilityAutoUnlocked = nil
    
    if currentLevel == 3 then
        -- Level 3: Auto-unlock the ability NOT chosen at Level 0
        local otherAbility = nil
        if self.selectedStartingAbility == "power_shot" then
            otherAbility = "arrow_volley"
        elseif self.selectedStartingAbility == "arrow_volley" then
            otherAbility = "power_shot"
        end
        
        if otherAbility and not self.player.abilities[otherAbility].unlocked then
            self.player.abilities[otherAbility].unlocked = true
            abilityAutoUnlocked = self.player.abilities[otherAbility].name
            print("Level 3: Auto-unlocked " .. abilityAutoUnlocked)
        end
    elseif currentLevel == 6 then
        -- Level 6: Auto-unlock Frenzy (ultimate)
        if not self.player.abilities.frenzy.unlocked then
            self.player.abilities.frenzy.unlocked = true
            abilityAutoUnlocked = "Frenzy"
            print("Level 6: Auto-unlocked Frenzy")
        end
    end
    
    -- TODO: Could show a notification about the auto-unlocked ability here
    -- For now, we just continue to the regular upgrade selection
    
    -- Roll normal upgrade options for non-ability levels
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
        -- Apply the selected upgrade using new system
        UpgradeApplication.apply(self.player, upgrade, self.playerStats)
        
        -- Apply stat changes to player entity
        self:applyStatsToPlayer()
        
        print("Selected upgrade: " .. upgrade.name .. " (" .. upgrade.rarity .. ")")
    end)
end

function GameScene:applyStatsToPlayer()
    if not self.player or not self.playerStats then return end
    
    -- Sync max health from stats and heal by gained amount when max increases
    local new_max_hp = self.playerStats:get("max_health")
    local old_max = self.player.maxHealth
    self.player.maxHealth = new_max_hp
    if new_max_hp > old_max then
        self.player.health = self.player.health + (new_max_hp - old_max)
    else
        self.player.health = math.min(self.player.health, new_max_hp)
    end
    
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
    
    -- Attach camera for world rendering
    if self.camera then
        self.camera:attach()
    end
    
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

    -- Add Imps
    for _, imp in ipairs(self.imps) do
        if imp.isAlive then
            table.insert(drawables, {entity = imp, y = imp.y, type = "imp"})
        end
    end

    -- Add Slimes
    for _, slime in ipairs(self.slimes) do
        if slime.isAlive then
            table.insert(drawables, {entity = slime, y = slime.y, type = "slime"})
        end
    end

    -- Add Bats
    for _, bat in ipairs(self.bats) do
        if bat.isAlive then
            table.insert(drawables, {entity = bat, y = bat.y, type = "bat"})
        end
    end

    -- Add Wolves
    for _, wolf in ipairs(self.wolves) do
        if wolf.isAlive then
            table.insert(drawables, {entity = wolf, y = wolf.y, type = "wolf"})
        end
    end

    -- Add Skeletons
    for _, skel in ipairs(self.skeletons) do
        if skel.isAlive then
            table.insert(drawables, {entity = skel, y = skel.y, type = "skeleton"})
        end
    end
    
    -- Add Healers
    for _, healer in ipairs(self.healers) do
        if healer.isAlive then
            table.insert(drawables, {entity = healer, y = healer.y, type = "healer"})
        end
    end

    -- Add Druid Treents
    for _, druid in ipairs(self.druids) do
        if druid.isAlive then
            table.insert(drawables, {entity = druid, y = druid.y, type = "druid"})
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
        
        -- Status indicators (bleed / marked) on enemies
        if drawable.entity and drawable.type and drawable.type ~= "player" and drawable.type ~= "bush" and drawable.type ~= "tree" then
            local ent = drawable.entity
            if ent.statusComponent then
                local ex, ey = ent.x, ent.y
                if ent.getPosition then ex, ey = ent:getPosition() end
                local r = (ent.getSize and ent:getSize()) or 16
                if ent.statusComponent:hasStatus("bleed") then
                    love.graphics.setColor(0.9, 0.1, 0.1, 0.9)
                    love.graphics.circle("fill", ex, ey - r - 4, 4)
                end
                if ent.statusComponent:hasStatus("marked") then
                    love.graphics.setColor(1, 0.9, 0.2, 0.95)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", ex, ey - r - 4, 6)
                    love.graphics.setLineWidth(1)
                end
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Chain lightning (Chain Reaction)
    if self.chainLightningSegments and #self.chainLightningSegments > 0 then
        local now = love.timer.getTime()
        love.graphics.setLineWidth(2)
        for _, seg in ipairs(self.chainLightningSegments) do
            if seg.untilTime and seg.untilTime > now then
                local alpha = (seg.untilTime - now) / 0.12
                love.graphics.setColor(0.6, 0.85, 1, alpha)
                love.graphics.line(seg.x1, seg.y1, seg.x2, seg.y2)
            end
        end
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Melee hit indicators: show which enemy just hit the player (red line, 0.15s)
    local MELEE_HIT_INDICATOR_DURATION = 0.15
    local now = love.timer.getTime()
    local playerX = self.player and self.player.x or 0
    local playerY = self.player and self.player.y or 0
    local function drawMeleeIndicators(list)
        for _, e in ipairs(list) do
            if e.isAlive and e.lastMeleeHitAt then
                local age = now - e.lastMeleeHitAt
                if age >= MELEE_HIT_INDICATOR_DURATION then
                    e.lastMeleeHitAt = nil
                else
                    local ex, ey = e.x, e.y
                    if e.getPosition then
                        ex, ey = e:getPosition()
                    end
                    local alpha = 0.7 * (1 - age / MELEE_HIT_INDICATOR_DURATION)
                    love.graphics.setColor(1, 0.2, 0.2, alpha)
                    love.graphics.setLineWidth(4)
                    love.graphics.line(ex, ey, playerX, playerY)
                end
            end
        end
    end
    drawMeleeIndicators(self.enemies or {})
    drawMeleeIndicators(self.lungers or {})
    drawMeleeIndicators(self.treents or {})
    drawMeleeIndicators(self.smallTreents or {})
    drawMeleeIndicators(self.wizards or {})
    drawMeleeIndicators(self.imps or {})
    drawMeleeIndicators(self.slimes or {})
    drawMeleeIndicators(self.bats or {})
    drawMeleeIndicators(self.wolves or {})
    drawMeleeIndicators(self.skeletons or {})
    drawMeleeIndicators(self.druids or {})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    
    -- Draw arrows (always on top of entities)
    for _, arrow in ipairs(self.arrows) do
        arrow:draw()
    end

    -- Draw bark projectiles
    for _, bark in ipairs(self.barkProjectiles) do
        bark:draw()
    end

    -- Draw Arrow Volleys
    for _, volley in ipairs(self.arrowVolleys) do
        volley:draw()
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
    
    -- Draw boss portal (in world space)
    if self.bossPortal then
        self.bossPortal:draw()
    end
    
    -- Detach camera before UI/HUD
    if self.camera then
        self.camera:detach()
    end
    
    -- Draw run timer at top center
    if self.runTimer then
        self.runTimer:draw(self.timeAlive or 0)
    end
    
    love.graphics.pop()
    
    -- Draw HUD (not affected by screen shake or camera)
    self:drawXPBar()
    
    -- Draw ability HUD
    if self.abilityHUD and self.player then
        self.abilityHUD:draw(self.player, self.xpSystem)
    end
    
    -- Draw buff bar above ability HUD
    if self.buffBar and self.player and self.abilityHUD then
        local abilityHudY = love.graphics.getHeight() - 100  -- Approximate ability HUD Y position
        self.buffBar:draw(self.player, abilityHudY)
    end
    
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

    -- Stats overlay (P for character Panel)
    if key == "p" and self.statsOverlay then
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
        self.frenzyKillsThisActivation = 0  -- Track kills for extend_on_kill
        self.frenzyExtendedTime = 0  -- Track how much we've extended
        self.screenShake:add(4, 0.15)
        return true
    end
    
    if key == "space" then
        self:startDash()
    end
end

function GameScene:drawOverlays()
    if self.statsOverlay and self.statsOverlay:isVisible() then
        self.statsOverlay:draw(self.playerStats, self.xpSystem, self.player)
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
    -- Convert screen coordinates to world coordinates
    if self.camera then
        self.mouseX, self.mouseY = self.camera:toWorld(x, y)
    else
        self.mouseX, self.mouseY = x, y
    end
    
    -- Handle upgrade UI hover (UI uses screen coordinates)
    if self.upgradeUI then
        self.upgradeUI:mousemoved(x, y)
    end
end

function GameScene:startDash()
    if self.dashCooldown <= 0 and not self.isDashing then
        self.isDashing = true
        self.dashTime = self.dashDuration
        self.dashCooldown = Config.Player.dashCooldown
        
        -- Sync with player ability cooldown for HUD
        if self.player and self.player.abilities and self.player.abilities.dash then
            self.player.abilities.dash.currentCooldown = Config.Player.dashCooldown
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
