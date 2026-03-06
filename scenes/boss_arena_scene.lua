-- Boss Arena Scene
-- Sealed combat arena for Treent Overlord encounter
-- Phase 2: Typing Test Mechanic (replaces root entities)

local TreentOverlord = require("entities.treent_overlord")
local BarkProjectile = require("entities.bark_projectile")
local Arrow = require("entities.arrow")
local ArrowVolley = require("entities.arrow_volley")
local Lunger = require("entities.lunger")
local Wizard = require("entities.wizard")
local Config = require("data.config")
local UIUtils = require("ui.ui_utils")

local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local StatusEffects = require("systems.status_effects")
local DamageNumbers = require("systems.damage_numbers")
local JuiceManager = require("systems.juice_manager")
local VineLane = require("entities.vine_lane")
local FallingTrunk = require("entities.falling_trunk")
local BarkVolleyAOE = require("entities.bark_volley_aoe")
local AbilityHUD = require("ui.ability_hud")
local BuffBar = require("ui.buff_bar")
local StatsOverlay = require("ui.stats_overlay")
local ProcEngine = require("systems.proc_engine")

local BossArenaScene = {}
BossArenaScene.__index = BossArenaScene

function BossArenaScene:new(player, playerStats, gameState, xpSystem, rarityCharge, initialFrenzyCharge)
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

        -- Falling trunks (Phase 1 lighter, Phase 2 heavier)
        fallingTrunks = {},           -- Array of FallingTrunk entities
        trunkSpawnTimer = 0,         -- Timer for continuous spawning
        trunksEnabled = true,        -- Spawn in both phases (phase-aware interval/damage)

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
        
        -- Frenzy (carry charge from main game; gain from time + boss hits)
        frenzyActive = false,
        frenzyAuraTimer = 0,
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        frenzyCombatGainPerSec = 3.5,
        frenzyBossHitGain = 2.5,
        
        -- Victory/Defeat
        victoryTimer = 0,
        defeatTimer = 0,
        
        -- Phase-aware adds (lungers, wizards) - disabled (no adds during boss fight)
        bossAdds = {},
        addSpawnTimer = 0,
        addSpawnInterval = 10,
        maxAddsPhase1 = 0,
        maxAddsPhase2 = 0,
        
        -- Arena dressing
        arenaDecor = {},
        arenaLeafClusters = {},
        arenaRoots = {},

        -- Arrow Volley (falling arrows, impact-timed)
        arrowVolleys = {},

        -- Bark Volley AOE (circular zones near player)
        barkVolleyAoEs = {},
        barkVolleySpawnTimer = 0,

        -- Mouse position (fallback for fireMultiShot when no target)
        mouseX = 0,
        mouseY = 0,

        -- Proc engine (for on_kill procs like Ice Blast)
        procEngine = ProcEngine:new(),
    }
    
    setmetatable(scene, BossArenaScene)
    
    -- Set JuiceManager screen shake reference
    JuiceManager.setScreenShake(scene.screenShake)
    
    scene.initialFrenzyCharge = initialFrenzyCharge
    scene:initialize()
    return scene
end

function BossArenaScene:initialize()
    JuiceManager.reset()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Spawn boss in center
    self.boss = TreentOverlord:new(screenWidth / 2, screenHeight / 2)
    
    -- Scale boss HP by player level at entry: +6% per level above 10, cap +120%
    local playerLevel = self.xpSystem and self.xpSystem.level or 10
    local levelScale = 1.0 + math.min(1.20, (playerLevel - 10) * 0.06)
    if playerLevel <= 10 then levelScale = 1.0 end
    self.boss.maxHealth = self.boss.maxHealth * levelScale
    self.boss.health = self.boss.maxHealth
    
    -- Position player at bottom
    if self.player then
        self.player.x = screenWidth / 2
        self.player.y = screenHeight - 100
    end

    -- Initialize mouse aim (center of screen)
    self.mouseX = screenWidth / 2
    self.mouseY = screenHeight / 2
    
    -- Wire player abilities (15% base cooldown reduction)
    local baseCDMul = (Config.game_balance and Config.game_balance.player and Config.game_balance.player.base_cooldown_mul) or 0.85
    if self.player then
        self.player.abilities = self.player.abilities or {}
        local aCfg = Config.Abilities
        
        -- Ensure frenzy exists with defaults if not present
        if not self.player.abilities.frenzy then
            self.player.abilities.frenzy = { name = "Frenzy", key = "R", icon = "🔥", unlocked = true }
        end
        self.player.abilities.frenzy.currentCooldown = 0
        self.player.abilities.frenzy.cooldown = 15.0 * baseCDMul
        
        -- Ensure multi_shot exists
        if not self.player.abilities.multi_shot then
            self.player.abilities.multi_shot = { name = "Multi Shot", key = "Q", icon = "➶", unlocked = true }
        end
        self.player.abilities.multi_shot.currentCooldown = 0
        self.player.abilities.multi_shot.cooldown = (aCfg.multiShot and aCfg.multiShot.cooldown or 2.5) * baseCDMul
        
        -- Ensure arrow_volley exists
        if not self.player.abilities.arrow_volley then
            self.player.abilities.arrow_volley = { name = "Arrow Volley", key = "E", icon = "🏹", unlocked = true }
        end
        self.player.abilities.arrow_volley.currentCooldown = 0
        self.player.abilities.arrow_volley.cooldown = 8.0 * baseCDMul
        self.player.abilities.entangle = self.player.abilities.arrow_volley
        
        -- Ensure dash exists
        if not self.player.abilities.dash then
            self.player.abilities.dash = { name = "Dash", key = "SPACE", icon = "💨", unlocked = true }
        end
        self.player.abilities.dash.currentCooldown = 0
        self.player.abilities.dash.cooldown = Config.Player.dashCooldown * baseCDMul
    end

    -- Apply full run upgrades to player (carryover from game scene)
    self:applyStatsToPlayer()
    
    -- Carry over Frenzy charge from main game so ultimate is usable in boss room
    local carried = (self.initialFrenzyCharge and type(self.initialFrenzyCharge) == "number") and self.initialFrenzyCharge or 0
    self.frenzyCharge = math.min(self.frenzyChargeMax, math.max(0, carried))
    
    self:generateArenaDecor()
end

function BossArenaScene:applyStatsToPlayer()
    if not self.player or not self.playerStats then return end
    local baseCDMul = (Config.game_balance and Config.game_balance.player and Config.game_balance.player.base_cooldown_mul) or 0.85

    self.player.attackDamage = self.playerStats:get("primary_damage")
    self.player.speed = self.playerStats:get("move_speed")
    self.attackRange = self.playerStats:get("range")
    local attackSpeed = self.playerStats:get("attack_speed")
    self.fireRate = 0.4 / attackSpeed

    if self.player.abilities then
        local aCfg = Config.Abilities
        if self.player.abilities.multi_shot then
            local baseMS = (aCfg.multiShot and aCfg.multiShot.cooldown or 2.5) * baseCDMul
            baseMS = self.playerStats:getAbilityValue("multi_shot", "cooldown_add", baseMS)
            baseMS = self.playerStats:getAbilityValue("multi_shot", "cooldown_mul", baseMS)
            self.player.abilities.multi_shot.cooldown = math.max(0.5, baseMS)
        end
        if self.player.abilities.arrow_volley then
            local baseAV = 8.0 * baseCDMul
            baseAV = self.playerStats:getAbilityValue("entangle", "cooldown_add", baseAV)
            baseAV = self.playerStats:getAbilityValue("entangle", "cooldown_mul", baseAV)
            self.player.abilities.arrow_volley.cooldown = math.max(1.0, baseAV)
        end
        if self.player.abilities.dash then
            local rollCD = self.playerStats:get("roll_cooldown") * baseCDMul
            self.player.abilities.dash.cooldown = math.max(0.3, rollCD)
            self.dashCooldownMax = self.player.abilities.dash.cooldown
        end
    end
end

function BossArenaScene:generateArenaDecor()
    self.arenaDecor = {}
    self.arenaLeafClusters = {}
    self.arenaRoots = {}

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cx = screenWidth * 0.5
    local cy = screenHeight * 0.5
    local outerRx = math.min(screenWidth * 0.44, 460)
    local outerRy = math.min(screenHeight * 0.34, 250)

    for i = 1, 18 do
        local a = (i / 18) * math.pi * 2
        local rrX = outerRx + math.random(-20, 24)
        local rrY = outerRy + math.random(-16, 16)
        self.arenaDecor[#self.arenaDecor + 1] = {
            x = cx + math.cos(a) * rrX,
            y = cy + math.sin(a) * rrY,
            size = 14 + math.random() * 12,
            kind = (i % 4 == 0) and "stump" or "stone",
        }
    end

    for i = 1, 24 do
        local a = (i / 24) * math.pi * 2
        self.arenaRoots[#self.arenaRoots + 1] = {
            x = cx + math.cos(a) * (outerRx - 18 + math.random(-10, 10)),
            y = cy + math.sin(a) * (outerRy - 10 + math.random(-8, 8)),
            len = 18 + math.random() * 20,
            angle = a + math.pi * 0.5 + math.random() * 0.35,
        }
    end

    for i = 1, 36 do
        local x = math.random(48, screenWidth - 48)
        local y = math.random(48, screenHeight - 48)
        local dx = x - cx
        local dy = y - cy
        if dx * dx + dy * dy > (outerRx * 0.82) * (outerRx * 0.82) then
            self.arenaLeafClusters[#self.arenaLeafClusters + 1] = {
                x = x,
                y = y,
                size = 8 + math.random() * 10,
                tint = 0.22 + math.random() * 0.08,
            }
        end
    end
end

function BossArenaScene:drawArenaBackdrop()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cx = screenWidth * 0.5
    local cy = screenHeight * 0.5
    local outerRx = math.min(screenWidth * 0.44, 460)
    local outerRy = math.min(screenHeight * 0.34, 250)
    local innerRx = outerRx * 0.76
    local innerRy = outerRy * 0.72

    love.graphics.setColor(0.15, 0.28, 0.14, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    love.graphics.setColor(0.10, 0.18, 0.10, 0.30)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 80)
    love.graphics.rectangle("fill", 0, screenHeight - 80, screenWidth, 80)
    love.graphics.rectangle("fill", 0, 0, 64, screenHeight)
    love.graphics.rectangle("fill", screenWidth - 64, 0, 64, screenHeight)

    love.graphics.setColor(0.22, 0.38, 0.18, 0.22)
    love.graphics.ellipse("fill", cx, cy, outerRx + 46, outerRy + 28)
    love.graphics.setColor(0.28, 0.44, 0.20, 0.34)
    love.graphics.ellipse("fill", cx, cy, innerRx, innerRy)
    love.graphics.setColor(0.34, 0.50, 0.24, 0.16)
    love.graphics.ellipse("fill", cx, cy, innerRx * 0.62, innerRy * 0.56)

    for _, cluster in ipairs(self.arenaLeafClusters or {}) do
        love.graphics.setColor(cluster.tint, cluster.tint + 0.08, cluster.tint, 0.16)
        love.graphics.ellipse("fill", cluster.x, cluster.y, cluster.size, cluster.size * 0.52)
    end

    for _, root in ipairs(self.arenaRoots or {}) do
        local ex = root.x + math.cos(root.angle) * root.len
        local ey = root.y + math.sin(root.angle) * root.len * 0.45
        love.graphics.setColor(0.18, 0.12, 0.08, 0.55)
        love.graphics.setLineWidth(3)
        love.graphics.line(root.x, root.y, ex, ey)
        love.graphics.setColor(0.32, 0.24, 0.14, 0.28)
        love.graphics.setLineWidth(1)
        love.graphics.line(root.x, root.y, ex, ey)
    end

    for _, prop in ipairs(self.arenaDecor or {}) do
        love.graphics.setColor(0.08, 0.10, 0.08, 0.24)
        love.graphics.ellipse("fill", prop.x, prop.y + 4, prop.size * 0.9, 5)
        if prop.kind == "stump" then
            love.graphics.setColor(0.34, 0.25, 0.15, 0.95)
            love.graphics.rectangle("fill", prop.x - prop.size * 0.32, prop.y - prop.size * 0.35, prop.size * 0.64, prop.size * 0.8, 3, 3)
            love.graphics.setColor(0.56, 0.44, 0.24, 0.82)
            love.graphics.ellipse("fill", prop.x, prop.y - prop.size * 0.16, prop.size * 0.42, prop.size * 0.22)
        else
            love.graphics.setColor(0.34, 0.38, 0.34, 0.92)
            love.graphics.polygon("fill",
                prop.x - prop.size * 0.7, prop.y + prop.size * 0.2,
                prop.x - prop.size * 0.3, prop.y - prop.size * 0.6,
                prop.x + prop.size * 0.4, prop.y - prop.size * 0.48,
                prop.x + prop.size * 0.74, prop.y + prop.size * 0.08,
                prop.x + prop.size * 0.18, prop.y + prop.size * 0.54,
                prop.x - prop.size * 0.46, prop.y + prop.size * 0.48
            )
            love.graphics.setColor(0.54, 0.58, 0.54, 0.45)
            love.graphics.polygon("fill",
                prop.x - prop.size * 0.12, prop.y - prop.size * 0.32,
                prop.x + prop.size * 0.18, prop.y - prop.size * 0.42,
                prop.x + prop.size * 0.32, prop.y - prop.size * 0.06,
                prop.x, prop.y
            )
        end
    end

    love.graphics.setColor(0.48, 0.62, 0.36, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", cx, cy, innerRx, innerRy)
    love.graphics.setColor(0.22, 0.18, 0.10, 0.55)
    love.graphics.setLineWidth(4)
    love.graphics.ellipse("line", cx, cy, outerRx, outerRy)
    love.graphics.setLineWidth(1)
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
    
    -- Run timer for top bar
    if self.gameState then
        self.gameState.runTimer = (self.gameState.runTimer or 0) + dt
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
        
        -- Sync frenzy VFX to player and emit aura particles
        if self.player then
            self.player.isFrenzyActive = self.frenzyActive
            if self.frenzyActive then
                self.frenzyAuraTimer = (self.frenzyAuraTimer or 0) - dt
                if self.frenzyAuraTimer <= 0 then
                    local px, py = self.player:getPosition()
                    self.particles:createFrenzyAura(px, py)
                    self.frenzyAuraTimer = 0.08
                end
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
            wasHit = false,
            didRoll = self.isDashing,
            inFrenzy = self.frenzyActive,
        })
    end
    
    -- Update cooldowns
    self.fireCooldown = math.max(0, self.fireCooldown - dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    
    -- Frenzy charge gain: time in combat (so ultimate is usable in boss room)
    if not self.frenzyActive and self.boss and self.boss.isAlive and self.player and not self.player:isDead() then
        local gain = (self.frenzyCombatGainPerSec or 3.5) * dt
        if self.playerStats then
            gain = self.playerStats:getAbilityValue("frenzy", "charge_gain_mul", gain)
        end
        self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + gain)
    end

    if self.player and self.player.abilities and self.player.abilities.frenzy then
        self.player.abilities.frenzy.charge = self.frenzyCharge
        self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax
    end

    -- Tick status effects on boss and adds (bleed/burn DoT, chill expiry)
    local function tickStatusOn(entity)
        if not entity or not entity.isAlive then return end
        local bleedBase, burnBase = 2, 2
        if self.playerStats then
            burnBase = burnBase * (self.playerStats:getElementMod("fire", "burn_damage_mul", 1.0) or 1.0)
        end
        local ticks, expiredChillEntity = StatusEffects.update(entity, dt, bleedBase, burnBase)
        if expiredChillEntity and self.playerStats and self.playerStats.activePrimaryElement == "ice" then
            local ex, ey = expiredChillEntity:getPosition()
            self:iceDissolveBlast(ex, ey)
        end
        for _, tick in ipairs(ticks) do
            if tick.entity.isAlive then
                tick.entity:takeDamage(tick.damage, nil, nil, 0)
                self:applyFrenzyLifesteal(tick.damage)
                local ex, ey = tick.entity:getPosition()
                if tick.status == "burn" and self.particles then
                    self.particles:createBurnFlare(ex, ey - tick.entity:getSize() * 0.2, 1.0 + StatusEffects.getStacks(tick.entity, "burn") * 0.18)
                end
            end
        end
    end
    if self.boss and self.boss.isAlive then tickStatusOn(self.boss) end
    for _, add in ipairs(self.bossAdds or {}) do tickStatusOn(add) end
    
    -- Update player
    if self.player then
        self.player.isDashing = self.isDashing
        if self.isDashing then
            self.player:update(dt)
            self.dashTime = self.dashTime - dt
            if self.dashTime <= 0 then
                self.isDashing = false
            else
                local moveX = self.dashDirX * self.dashSpeed * dt
                local moveY = self.dashDirY * self.dashSpeed * dt
                self.player.x = self.player.x + moveX
                self.player.y = self.player.y + moveY
                self.particles:createDashTrail(self.player.x, self.player.y)
            end
        else
            -- Skip movement during phase 2 typing test (player is rooted)
            if not self.typingTestActive then
                self.player:update(dt)
            end
        end
        
        local playerX, playerY = self.player:getPosition()

        -- Sync mouse position every frame (in case mousemoved was missed, e.g. after transition)
        local rawMx, rawMy = love.mouse.getPosition()
        self.mouseX = rawMx
        self.mouseY = rawMy

        -- Drive bow attunement VFX from current element
        self.player.activeElement = self.playerStats and self.playerStats.activePrimaryElement or nil

        -- Auto-aim at nearest target (boss or adds), matching main game behavior
        local nearestTarget = self:findNearestBossTargetTo(playerX, playerY, self.attackRange)
        if nearestTarget then
            local tx, ty = nearestTarget.getPosition and nearestTarget:getPosition() or nearestTarget.x, nearestTarget.y
            self.player:aimAt(tx, ty)

            -- Auto-fire primary at target (blocked during typing test - boss is invulnerable)
            if self.fireCooldown <= 0 and not self.isDashing and not self.typingTestActive then
                local baseDmg = (self.player.attackDamage or 10) * 1.0
                local pierce = (self.playerStats and self.playerStats:getWeaponMod("pierce")) or 0
                local ricBounces = (self.playerStats and self.playerStats:getWeaponMod("ricochet_bounces")) or 0
                local ricRange = (self.playerStats and self.playerStats:getWeaponMod("ricochet_range")) or 220
                local sx, sy = self.player.getBowTip and self.player:getBowTip() or playerX, playerY
                local activeElement = self.playerStats and self.playerStats.activePrimaryElement or nil

                local arrow = Arrow:new(sx, sy, tx, ty, {
                    damage = baseDmg, pierce = pierce, kind = "primary", knockback = 140,
                    ricochetBounces = ricBounces, ricochetRange = ricRange,
                    iceAttuned = activeElement == "ice",
                    element = activeElement,
                })
                table.insert(self.arrows, arrow)
                if _G.audio then _G.audio:playSFX("shoot_arrow") end
                if self.player.playAttackAnimation then self.player:playAttackAnimation() end

                -- Bonus projectiles from weapon mods (matches main game)
                local bonusProj = (self.playerStats and self.playerStats:getWeaponMod("bonus_projectiles")) or 0
                if bonusProj > 0 then
                    local spreadDeg = (self.playerStats and self.playerStats.weaponMods and self.playerStats.weaponMods.projectile_spread) or 10
                    local spreadRad = math.rad(spreadDeg)
                    local baseAngle = math.atan2(ty - sy, tx - sx)
                    for p = 1, bonusProj do
                        local offset = spreadRad * p * (p % 2 == 0 and 1 or -1)
                        local bx = sx + math.cos(baseAngle + offset) * 10
                        local by = sy + math.sin(baseAngle + offset) * 10
                        local btx = sx + math.cos(baseAngle + offset) * 300
                        local bty = sy + math.sin(baseAngle + offset) * 300
                        local bonusArrow = Arrow:new(bx, by, btx, bty, {
                            damage = baseDmg * 0.7, pierce = pierce, kind = "primary", knockback = 100,
                            ricochetBounces = ricBounces, ricochetRange = ricRange,
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

        -- Multi Shot (Q): auto-cast at nearest target when off cooldown (matches main game)
        if self.player and self.player:isAbilityReady("multi_shot") and not self.isDashing and not self.typingTestActive then
            local msTarget = self:findNearestBossTargetTo(playerX, playerY, self.attackRange)
            if msTarget then
                local tx, ty = msTarget.getPosition and msTarget:getPosition() or msTarget.x, msTarget.y
                self:fireMultiShot(tx, ty)
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
                    local baseDmg = self.playerStats and self.playerStats:get("primary_damage") or 25
                    local damageMul = self.playerStats:getAbilityValue("arrow_volley", "damage_mul", 1.0)
                    local damage = baseDmg * 1.5 * damageMul
                    local doubleVolley = self.playerStats and self.playerStats:getAbilityMod("entangle", "double_volley")
                    local volleyLine = self.playerStats and self.playerStats:getAbilityMod("entangle", "volley_line")

                    local function spawnVolleyAt(vx, vy, vdmg, vradius)
                        local v = ArrowVolley:new(vx, vy, vdmg, vradius, 0)
                        table.insert(self.arrowVolleys, { volley = v, targetBoss = true })
                    end

                    if volleyLine then
                        local lineRadius, lineDamage = 40, damage * 0.6
                        for _, oy in ipairs({ by - 60, by, by + 60 }) do
                            spawnVolleyAt(bx, oy, lineDamage, lineRadius)
                        end
                    elseif doubleVolley then
                        spawnVolleyAt(bx, by, damage, 80)
                        spawnVolleyAt(bx + 35, by, damage, 80)
                    else
                        spawnVolleyAt(bx, by, damage, 80)
                    end

                    if _G.audio then _G.audio:playSFX("shoot_arrow") end
                    if self.particles then
                        self.particles:createCastBurst(bx, by, {0.95, 0.38, 0.24}, 1.0)
                    end
                    self.screenShake:add(3, 0.15)

                    -- Double_strike: spawn second volley after delay
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
                    -- Extra_zone_add: additional volleys after delay
                    local extraZones = self.playerStats and self.playerStats:getAbilityValue("arrow_volley", "extra_zone_add", 0) or 0
                    for _ = 1, extraZones do
                        self.pendingArrowVolleys = self.pendingArrowVolleys or {}
                        table.insert(self.pendingArrowVolleys, {
                            timer = 0.5,
                            tx = bx, ty = by,
                            damage = damage * 0.7,
                        })
                    end
                end
            end
        end
        
        -- Process pending arrow volleys (spawn volley when timer fires)
        if self.pendingArrowVolleys then
            for i = #self.pendingArrowVolleys, 1, -1 do
                local pending = self.pendingArrowVolleys[i]
                pending.timer = pending.timer - dt
                if pending.timer <= 0 then
                    local volley = ArrowVolley:new(pending.tx, pending.ty, pending.damage, 80, 0)
                    table.insert(self.arrowVolleys, { volley = volley, targetBoss = true })
                    table.remove(self.pendingArrowVolleys, i)
                end
            end
        end

        -- Update Arrow Volleys (impact-timed damage on boss)
        for i = #self.arrowVolleys, 1, -1 do
            local entry = self.arrowVolleys[i]
            local volley = entry.volley
            volley:update(dt)
            if volley:shouldApplyDamage() and entry.targetBoss and self.boss and self.boss.isAlive then
                local dmg = volley:getDamage()
                local bx, by = self.boss:getPosition()
                self.boss:takeDamage(dmg)
                self:applyFrenzyLifesteal(dmg)
                if self.playerStats and self.playerStats:getAbilityMod("entangle", "explosion_volley") then
                    StatusEffects.apply(self.boss, "burn", 1, 2.5)
                end
                self.particles:createExplosion(bx, by, {1, 0.8, 0.2})
                if self.damageNumbers then
                    self.damageNumbers:add(bx, by - 30, dmg, { isCrit = false })
                end
            end
            if volley:isFinished() then
                table.remove(self.arrowVolleys, i)
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
                -- Trunks already enabled in Phase 1; Phase 2 uses faster/heavier config
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

                    -- Start vine cast timer immediately (race condition with typing test).
                    -- If the player fails to finish in time, vine attack resolves while still rooted.
                    if self.boss then
                        self.boss.earthquakeCasting = true
                        self.boss.earthquakeCastProgress = 0
                        self.boss.earthquakeCastTime = (self.boss.baseEarthquakeCastTime or self.boss.earthquakeCastTime or 0) * 1.15
                        self.boss.earthquakeTimer = 0
                        self.boss.earthquakeActive = false
                    end

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

            -- Phase 2 fail condition: typing test did not finish before vine attack resolved.
            if self.typingTestActive and self.vineLanesActive and self.player and not self.player:isDead() then
                local lethal = Config.TreentOverlord.vineLaneDamage or 9999
                if self.frenzyActive then
                    lethal = lethal * (Config.Abilities.frenzy.damageTakenMult or 1.15)
                end
                self.player:takeDamage(lethal)
                self.typingTestActive = false
                self.player.isRooted = false
                self.player.rootDuration = 0
                self.screenShake:add(10, 0.3)
                self.particles:createExplosion(playerX, playerY, {0.7, 0.2, 0.2})
            end
            
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

        -- Update falling trunks (Phase 1 lighter, Phase 2 heavier; paused during typing test)
        if self.trunksEnabled and not self.typingTestActive then
            local cfg = Config.TreentOverlord or {}
            local phase = (self.boss and self.boss.phase) or 1
            local interval = (phase == 2) and (cfg.trunkPhase2Interval or 1.5) or (cfg.trunkPhase1Interval or 2.2)
            local damage = (phase == 2) and (cfg.trunkPhase2Damage or 60) or (cfg.trunkPhase1Damage or 40)

            self.trunkSpawnTimer = self.trunkSpawnTimer + dt
            if self.trunkSpawnTimer >= interval then
                self.trunkSpawnTimer = 0

                local screenWidth = love.graphics.getWidth()
                local screenHeight = love.graphics.getHeight()
                local margin = 100
                local targetX = margin + math.random() * (screenWidth - margin * 2)
                local targetY = margin + math.random() * (screenHeight - margin * 2)

                local trunk = FallingTrunk:new(targetX, targetY, damage)
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

        -- Bark Volley AOE (circular zones near player; runs during lunge/bark loop)
        if self.boss and self.boss.isAlive and not self.typingTestActive then
            local cfg = Config.TreentOverlord or {}
            local cooldown = cfg.barkVolleyCooldown or 3.5
            local phase = self.boss.phase or 1
            if phase == 2 then
                cooldown = cooldown * (cfg.barkVolleyPhase2CooldownMul or 0.75)
            end

            self.barkVolleySpawnTimer = (self.barkVolleySpawnTimer or 0) + dt
            if self.barkVolleySpawnTimer >= cooldown then
                self.barkVolleySpawnTimer = 0
                local placementRadius = cfg.barkVolleyPlacementRadius or 120
                local angle = math.random() * math.pi * 2
                local dist = math.random() * placementRadius
                local cx = playerX + math.cos(angle) * dist
                local cy = playerY + math.sin(angle) * dist
                local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                cx = math.max(60, math.min(sw - 60, cx))
                cy = math.max(60, math.min(sh - 60, cy))
                local aoe = BarkVolleyAOE:new(
                    cx, cy,
                    cfg.barkVolleyRadius or 55,
                    cfg.barkVolleyDamage or 25,
                    cfg.barkVolleyTelegraphDuration or 0.9,
                    cfg.barkVolleyImpactDuration or 0.25
                )
                table.insert(self.barkVolleyAoEs, aoe)
            end

            for i = #self.barkVolleyAoEs, 1, -1 do
                local aoe = self.barkVolleyAoEs[i]
                aoe:update(dt)
                if aoe:isInImpactPhase() and self.player then
                    if aoe:isPlayerInDanger(playerX, playerY) then
                        local dmg = aoe:getDamage()
                        if self.frenzyActive then dmg = dmg * Config.Abilities.frenzy.damageTakenMult end
                        self.player:takeDamage(dmg)
                        self.screenShake:add(8, 0.25)
                        self.particles:createExplosion(playerX, playerY, {0.9, 0.5, 0.15})
                    end
                end
                if aoe.isFinished then
                    table.remove(self.barkVolleyAoEs, i)
                end
            end
        end
        
        -- Phase-aware add spawning (no adds during typing test)
        if self.boss and self.boss.isAlive and not self.typingTestActive then
            local phase = self.boss.phase or 1
            local maxAdds = (phase == 2) and self.maxAddsPhase2 or self.maxAddsPhase1
            local interval = (phase == 2) and 6 or 10
            local addCount = 0
            for _, a in ipairs(self.bossAdds) do
                if a.isAlive then addCount = addCount + 1 end
            end
            self.addSpawnTimer = (self.addSpawnTimer or 0) + dt
            if self.addSpawnTimer >= interval and addCount < maxAdds then
                self.addSpawnTimer = 0
                local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                local side = math.random(1, 4)
                local x, y
                if side == 1 then x = math.random(50, sw - 50); y = 40
                elseif side == 2 then x = sw - 40; y = math.random(50, sh - 50)
                elseif side == 3 then x = math.random(50, sw - 50); y = sh - 40
                else x = 40; y = math.random(50, sh - 50) end
                local add
                if math.random() < 0.6 then
                    add = Lunger:new(x, y)
                else
                    add = Wizard:new(x, y)
                end
                table.insert(self.bossAdds, add)
            end
        end
        
        -- Update boss adds (AI) - wizard cone deals damage, no root
        local function onBossWizardCone(wx, wy, angleToPlayer, coneAngle, coneRange, rootDuration)
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
                local dmg = 12
                if self.frenzyActive then dmg = dmg * 1.15 end
                self.player:takeDamage(dmg)
                if self.playerStats then self.playerStats:update(0, { wasHit = true, didRoll = false, inFrenzy = self.frenzyActive }) end
            end
        end
        for _, add in ipairs(self.bossAdds) do
            if add.isAlive then
                if add.update then
                    add:update(dt, playerX, playerY, onBossWizardCone)
                end
                if not self.isDashing and add.getPosition and add.getSize then
                    local ax, ay = add:getPosition()
                    local dist = math.sqrt((playerX - ax)^2 + (playerY - ay)^2)
                    if dist < self.player:getSize() + add:getSize() then
                        local dmg = (add.damage or (add.getDamage and add:getDamage()) or 10) * 1.0
                        if self.frenzyActive then dmg = dmg * 1.15 end
                        self.player:takeDamage(dmg)
                        self.screenShake:add(5, 0.15)
                    end
                end
            end
        end

        -- Update arrows
        for i = #self.arrows, 1, -1 do
            local arrow = self.arrows[i]
            arrow:update(dt)
            
            if arrow:isExpired() then
                -- Ice attunement: dissolve blast on expire (primary arrows only)
                if arrow.iceAttuned and arrow.kind == "primary" then
                    local ax, ay = arrow:getPosition()
                    self:iceDissolveBlast(ax, ay)
                end
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
                
                -- Check boss adds first
                if not hitEnemy then
                    for _, add in ipairs(self.bossAdds) do
                        if add.isAlive and add.getPosition and add.getSize then
                            local adx, ady = add:getPosition()
                            local dx = ax - adx
                            local dy = ay - ady
                            local sumR = add:getSize() + arrow:getSize()
                            if dx * dx + dy * dy < sumR * sumR and arrow:canHit(add) then
                                arrow:markHit(add)
                                local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                                self.particles:createHitSpark(adx, ady, isCrit and {1, 1, 0.2} or {1, 1, 0.6})
                                if _G.audio then
                                    local sfx = math.random() > 0.5 and "hit_light" or "hit_light_alt"
                                    _G.audio:playSFX(sfx, { pitch = isCrit and 1.15 or (0.95 + math.random() * 0.12) })
                                end
                                if self.damageNumbers then
                                    self.damageNumbers:add(adx, ady - add:getSize(), dmg, { isCrit = isCrit })
                                end
                                local died = add:takeDamage(dmg, ax, ay, arrow.knockback)
                                self:applyFrenzyLifesteal(dmg)
                                if died then
                                    local killActions = self.procEngine:onKill(self.playerStats, { isCrit = isCrit, target = add })
                                    for _, action in ipairs(killActions) do
                                        self:executeAction(action)
                                    end
                                    self.particles:createExplosion(adx, ady, {0.6, 0.3, 0.8})
                                    self.screenShake:add(4, 0.12)
                                    self.xpSystem:spawnOrb(adx, ady, 25 + math.random(0, 15))
                                end
                                -- Ricochet: redirect to nearest un-hit target
                                if arrow.ricochetBounces and arrow.ricochetBounces > 0 then
                                    local nextTarget = self:findNearestBossTargetTo(adx, ady, arrow.ricochetRange or 220, arrow.hit)
                                    if nextTarget then
                                        local ntx, nty = nextTarget.getPosition and nextTarget:getPosition() or nextTarget.x, nextTarget.y
                                        arrow:bounceToward(ntx, nty)
                                        hitEnemy = false
                                        break
                                    end
                                end
                                if arrow:consumePierce() then hitEnemy = false else hitEnemy = true end
                                break
                            end
                        end
                    end
                end
                
                -- Check boss
                if not hitEnemy and self.boss and self.boss.isAlive then
                    local bx, by = self.boss:getPosition()
                    local dx = ax - bx
                    local dy = ay - by
                    local sumR = self.boss:getSize() + arrow:getSize()
                    if dx * dx + dy * dy < sumR * sumR and arrow:canHit(self.boss) then
                        arrow:markHit(self.boss)
                        local dmg, isCrit = rollDamage(arrow.damage, arrow.alwaysCrit)
                        
                        -- Multi Shot impact juice (freeze, shake, flash)
                        if arrow.kind == "multi_shot" then
                            JuiceManager.impact(self.boss, 0.04, 8, 0.12, 0.08)
                        end
                        
                        self.particles:createHitSpark(bx, by, {1, 1, 0.6})
                        if _G.audio then
                            local sfx = math.random() > 0.5 and "hit_light" or "hit_light_alt"
                            _G.audio:playSFX(sfx, { pitch = isCrit and 1.15 or (0.95 + math.random() * 0.12) })
                        end
                        if self.damageNumbers then
                            self.damageNumbers:add(bx, by - self.boss:getSize(), dmg, { isCrit = isCrit })
                        end
                        local died = self.boss:takeDamage(dmg, ax, ay, arrow.knockback)
                        self:applyFrenzyLifesteal(dmg)
                        -- Frenzy charge gain on boss hit (so ultimate is usable in boss room)
                        if not self.frenzyActive then
                            local hitGain = self.frenzyBossHitGain or 2.5
                            if self.playerStats then
                                hitGain = self.playerStats:getAbilityValue("frenzy", "charge_gain_mul", hitGain)
                            end
                            self.frenzyCharge = math.min(self.frenzyChargeMax, self.frenzyCharge + hitGain)
                        end
                        
                        if died then
                            self.particles:createExplosion(bx, by, {0.2, 1, 0.2})
                            self.screenShake:add(15, 0.8)
                            self.victoryTimer = 3.0 -- Start victory countdown
                        else
                            self.screenShake:add(2, 0.08)
                        end
                        
                        -- Ricochet: redirect to nearest un-hit target
                        if arrow.ricochetBounces and arrow.ricochetBounces > 0 then
                            local nextTarget = self:findNearestBossTargetTo(bx, by, arrow.ricochetRange or 220, arrow.hit)
                            if nextTarget then
                                local ntx, nty = nextTarget.getPosition and nextTarget:getPosition() or nextTarget.x, nextTarget.y
                                arrow:bounceToward(ntx, nty)
                                hitEnemy = false
                            else
                                if arrow:consumePierce() then hitEnemy = false else hitEnemy = true end
                            end
                        else
                            if arrow:consumePierce() then hitEnemy = false else hitEnemy = true end
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
                if _G.audio then _G.audio:playMenuMusic() end
                self.gameState:transitionTo(self.gameState.States.VICTORY)
            end
        end
        
        -- Check defeat
        if self.player and self.player:isDead() then
            self.defeatTimer = self.defeatTimer + dt
            if self.defeatTimer >= 2.0 then
                if _G.audio then _G.audio:playGameOverMusic() end
                self.gameState:transitionTo(self.gameState.States.GAME_OVER)
            end
        end
    end
end

function BossArenaScene:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    self:drawArenaBackdrop()
    
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

    -- Draw Arrow Volleys (falling arrows)
    for _, entry in ipairs(self.arrowVolleys) do
        if entry.volley then
            entry.volley:draw()
        end
    end

    -- Draw falling trunks (ground telegraphs first, then falling trunks later)
    -- Draw telegraphs on ground (before entities)
    for _, trunk in ipairs(self.fallingTrunks) do
        if trunk.state == "telegraph" or trunk.state == "falling" then
            trunk:draw()
        end
    end

    -- Draw bark volley AOE telegraphs and impacts
    for _, aoe in ipairs(self.barkVolleyAoEs) do
        aoe:draw()
    end

    -- Y-sort drawing
    local drawables = {}
    
    -- Add boss
    if self.boss and self.boss.isAlive then
        table.insert(drawables, { entity = self.boss, y = self.boss.y, type = "boss" })
    end
    
    -- Add boss adds
    for _, add in ipairs(self.bossAdds) do
        if add.isAlive and add.y then
            table.insert(drawables, { entity = add, y = add.y, type = "add" })
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

        -- Marked status: gold outline
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

        -- Freeze status: icy cyan ring
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

        -- Chill/slow status: lighter blue aura
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

        -- Title (vibrant red with glow) - use UI font for readability
        if _G.PixelFonts and _G.PixelFonts.uiSmall then
            love.graphics.setFont(_G.PixelFonts.uiSmall)
        else
            love.graphics.setNewFont(24)
        end
        love.graphics.setColor(1, 0.1, 0.1, 0.8)
        love.graphics.printf("TYPE TO ESCAPE!", 0, panelY - 5, screenWidth, "center")
        love.graphics.setColor(1, 0.4, 0.2, 1)
        love.graphics.printf("TYPE TO ESCAPE!", 0, panelY - 8, screenWidth, "center")

        -- Letters (much larger and more vibrant)
        if _G.PixelFonts and _G.PixelFonts.uiLarge then
            love.graphics.setFont(_G.PixelFonts.uiLarge)
        else
            love.graphics.setNewFont(54)
        end
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

        -- Countdown to vine impact while typing (race condition feedback)
        local remaining = nil
        if self.boss and self.boss.earthquakeCasting then
            remaining = math.max(0, (self.boss.earthquakeCastTime or 0) - (self.boss.earthquakeCastProgress or 0))
        elseif self.vineLanesActive then
            remaining = 0
        end
        if remaining ~= nil then
            if _G.PixelFonts and _G.PixelFonts.uiTiny then
                love.graphics.setFont(_G.PixelFonts.uiTiny)
            end
            love.graphics.setColor(1, 0.45, 0.2, 1)
            love.graphics.printf(string.format("VINES IN %.1fs", remaining), 0, panelY + 112, screenWidth, "center")
        end

        if _G.PixelFonts then love.graphics.setFont(_G.PixelFonts.body) end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Ice dissolve blast (when ice-attuned primary arrow expires)
function BossArenaScene:iceDissolveBlast(x, y)
    if not self.playerStats or self.playerStats.activePrimaryElement ~= "ice" then return end
    local baseRadius = 70
    local radiusAdd = self.playerStats:getElementMod("ice", "ice_blast_radius_add", 0)
    local radius = baseRadius + radiusAdd
    local baseDmg = (self.player and self.player.attackDamage or 10) * 1.6
    -- Damage boss and adds in radius
    local function damageInRadius()
        for _, add in ipairs(self.bossAdds or {}) do
            if add.isAlive and add.getPosition and add.getSize then
                local ex, ey = add:getPosition()
                local dx = ex - x
                local dy = ey - y
                if math.sqrt(dx * dx + dy * dy) <= radius then
                    local died = add:takeDamage(baseDmg, x, y, 80)
                    self:applyFrenzyLifesteal(baseDmg)
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - add:getSize(), baseDmg, { isCrit = false })
                    end
                    if died then
                        self.particles:createExplosion(ex, ey, {1, 0.5, 0.1})
                        self.screenShake:add(4, 0.15)
                        self.xpSystem:spawnOrb(ex, ey, 25 + math.random(0, 15))
                    end
                end
            end
        end
        if self.boss and self.boss.isAlive then
            local bx, by = self.boss:getPosition()
            local dx = bx - x
            local dy = by - y
            if math.sqrt(dx * dx + dy * dy) <= radius then
                local died = self.boss:takeDamage(baseDmg, x, y, 80)
                self:applyFrenzyLifesteal(baseDmg)
                if self.damageNumbers then
                    self.damageNumbers:add(bx, by - self.boss:getSize(), baseDmg, { isCrit = false })
                end
                if died then
                    self.particles:createExplosion(bx, by, {0.2, 1, 0.2})
                    self.screenShake:add(15, 0.8)
                    self.victoryTimer = 3.0
                else
                    self.screenShake:add(2, 0.08)
                end
            end
        end
    end
    damageInRadius()
    -- Freeze spread
    if self.playerStats:hasUpgrade("arch_r_freeze_spread") then
        local duration = 1.5 + (self.playerStats:getElementMod("ice", "chill_duration_add", 0) or 0)
        local slowMul = self.playerStats:getElementMod("ice", "slow_mul", 1.0) or 1.0
        for _, add in ipairs(self.bossAdds or {}) do
            if add.isAlive and add.getPosition then
                local ex, ey = add:getPosition()
                local dx = ex - x
                local dy = ey - y
                if math.sqrt(dx * dx + dy * dy) <= radius then
                    StatusEffects.apply(add, "freeze", 1, duration, slowMul ~= 1.0 and { slowMul = slowMul } or nil)
                end
            end
        end
        if self.boss and self.boss.isAlive then
            local bx, by = self.boss:getPosition()
            local dx = bx - x
            local dy = by - y
            if math.sqrt(dx * dx + dy * dy) <= radius then
                StatusEffects.apply(self.boss, "chill", 1, duration, slowMul ~= 1.0 and { slowMul = slowMul } or nil)
            end
        end
    end
    self.particles:createIceBlast(x, y, radius)
    self.screenShake:add(5, 0.12)
    JuiceManager.freezeTime(0.04)
end

-- Ice blast on death (AOE when enemy with chill dies)
function BossArenaScene:iceBlastOnDeath(target, radius, damageMultOfMaxHP)
    local tx, ty = target:getPosition()
    local damage = (target.maxHealth or 50) * (damageMultOfMaxHP or 0.05)
    local radiusAdd = self.playerStats and self.playerStats:getElementMod("ice", "ice_blast_radius_add", 0) or 0
    radius = (radius or 70) + radiusAdd
    -- Damage boss and adds in radius
    for _, add in ipairs(self.bossAdds or {}) do
        if add.isAlive and add.getPosition and add.getSize then
            local ax, ay = add:getPosition()
            local dx = ax - tx
            local dy = ay - ty
            if math.sqrt(dx * dx + dy * dy) <= radius then
                add:takeDamage(damage, tx, ty, 80)
                self:applyFrenzyLifesteal(damage)
                if self.damageNumbers then
                    self.damageNumbers:add(ax, ay - add:getSize(), damage, { isCrit = false })
                end
            end
        end
    end
    if self.boss and self.boss.isAlive then
        local bx, by = self.boss:getPosition()
        local dx = bx - tx
        local dy = by - ty
        if math.sqrt(dx * dx + dy * dy) <= radius then
            local died = self.boss:takeDamage(damage, tx, ty, 80)
            self:applyFrenzyLifesteal(damage)
            if self.damageNumbers then
                self.damageNumbers:add(bx, by - self.boss:getSize(), damage, { isCrit = false })
            end
        end
    end
    self.particles:createIceBlast(tx, ty, radius)
    self.screenShake:add(5, 0.12)
    JuiceManager.freezeTime(0.04)
end

-- Execute proc action (ice_blast, aoe_explosion)
function BossArenaScene:executeAction(action)
    local apply = action.apply
    if not apply then return end
    if apply.kind == "ice_blast" and action.target then
        self:iceBlastOnDeath(action.target, apply.radius or 70, apply.damage_mul_of_target_maxhp or 0.05)
    elseif apply.kind == "aoe_explosion" and action.target then
        -- Hemorrhage: would need hemorrhageExplosion helper; skip for boss arena (no bleed on adds typically)
    end
end

-- Find nearest boss or add to a point (for ricochet retarget)
function BossArenaScene:findNearestBossTargetTo(x, y, maxRange, excludeSet)
    local best, bestDist = nil, maxRange
    for _, e in ipairs(self.bossAdds or {}) do
        if e.isAlive and (not excludeSet or not excludeSet[e]) then
            local ex, ey = (e.getPosition and e:getPosition()) or e.x, e.y
            local dx = ex - x
            local dy = ey - y
            local d = math.sqrt(dx * dx + dy * dy)
            if d < bestDist then
                best = e
                bestDist = d
            end
        end
    end
    if self.boss and self.boss.isAlive and (not excludeSet or not excludeSet[self.boss]) then
        local bx, by = (self.boss.getPosition and self.boss:getPosition()) or self.boss.x, self.boss.y
        local dx = bx - x
        local dy = by - y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < bestDist then
            best = self.boss
            bestDist = d
        end
    end
    return best
end

-- Apply Frenzy lifesteal from outgoing player damage.
function BossArenaScene:applyFrenzyLifesteal(damageDealt)
    if not self.frenzyActive or not self.player then return end
    if not damageDealt or damageDealt <= 0 then return end
    local lifeSteal = (Config.Abilities and Config.Abilities.frenzy and Config.Abilities.frenzy.lifeSteal) or 0.10
    if lifeSteal <= 0 then return end
    local healAmount = damageDealt * lifeSteal
    self.player.health = math.min(self.player.maxHealth, self.player.health + healAmount)
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
                -- SUCCESS! Unroot player; vine cast timer is already running.
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
    
    -- Manual abilities (blocked during typing test)
    if key == "r" and self.player and self.player:isAbilityReady("frenzy") and self.frenzyCharge >= self.frenzyChargeMax and not self.typingTestActive then
        self.player:useAbility("frenzy", self.playerStats)
        self.frenzyCharge = self.frenzyCharge - self.frenzyChargeMax
        local fCfg = Config.Abilities.frenzy
        
        -- Apply ability mods
        local durationAdd = self.playerStats:getAbilityValue("frenzy", "duration_add", 0)
        local critChanceAdd = self.playerStats:getAbilityValue("frenzy", "crit_chance_add", 0)
        local moveSpeedMul = self.playerStats:getAbilityValue("frenzy", "move_speed_mul", 1.0)
        local rollCooldownMul = self.playerStats:getAbilityValue("frenzy", "roll_cooldown_mul", 1.0)
        
        local finalDuration = fCfg.duration + durationAdd
        local finalCritAdd = fCfg.critChanceAdd + critChanceAdd
        local finalMoveSpeedMul = fCfg.moveSpeedMult * moveSpeedMul
        
        self.playerStats:addBuff("frenzy", finalDuration, {
            { stat = "move_speed", mul = finalMoveSpeedMul },
            { stat = "attack_speed", mul = fCfg.attackSpeedMult },
            { stat = "crit_chance", add = finalCritAdd },
            { stat = "roll_cooldown", mul = rollCooldownMul },
        }, { damage_taken_multiplier = fCfg.damageTakenMult })
        self.frenzyActive = true
        self.frenzyKillsThisActivation = 0
        self.frenzyExtendedTime = 0
        if _G.audio then _G.audio:playSFX("hit_heavy") end
        self.screenShake:add(4, 0.15)
        if self.player and self.particles then
            local px, py = self.player:getPosition()
            self.particles:createFrenzyBurst(px, py)
            self.particles:createCastBurst(px, py, {1, 0.62, 0.15}, 1.15)
        end
        return true
    end
    
    if key == "space" then
        self:startDash()
        return true
    end
    
    return false
end

---------------------------------------------------------------------------
-- HELPER: fire Multi Shot (3-arrow cone toward target)
-- targetX/targetY: auto-aim target coords (falls back to mouse if nil)
---------------------------------------------------------------------------
function BossArenaScene:fireMultiShot(targetX, targetY)
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
    local baseDmg = (self.player.attackDamage or 10)
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
    self.screenShake:add(2, 0.08)
    if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
    if self.player.playAttackAnimation then self.player:playAttackAnimation() end
end

function BossArenaScene:mousemoved(x, y)
    self.mouseX = x
    self.mouseY = y
end

function BossArenaScene:startDash()
    -- Can't dash while rooted (phase 2 typing test) or during typing test
    if self.typingTestActive or (self.player and self.player.isRooted) then
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
            if _G.audio then _G.audio:playSFX("hit_light") end
            
            if self.player.startDash then
                self.player:startDash()
            end
        end
    end
end

function BossArenaScene:drawBossHealthBar()
    if not self.boss then return end

    local w = love.graphics.getWidth()
    local t = love.timer.getTime()
    local healthPercent = math.max(0, math.min(1, self.boss.health / self.boss.maxHealth))
    local phase = self.boss.phase or 1

    local barWidth = 356
    local barHeight = 12
    local barX = (w - barWidth) / 2
    local barY = 74
    local fillW = barWidth * healthPercent
    local barColor = phase == 2 and {0.92, 0.32, 0.28} or {0.34, 0.86, 0.42}

    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.rectangle("fill", barX - 10, barY - 12, barWidth + 20, barHeight + 28, 12, 12)
    love.graphics.setColor(0.07, 0.08, 0.11, 0.94)
    love.graphics.rectangle("fill", barX - 6, barY - 8, barWidth + 12, barHeight + 20, 10, 10)
    love.graphics.setColor(barColor[1], barColor[2], barColor[3], 0.16)
    love.graphics.rectangle("line", barX - 6, barY - 8, barWidth + 12, barHeight + 20, 10, 10)

    love.graphics.setColor(0.06, 0.08, 0.1, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 3, 3)

    if fillW > 0 then
        love.graphics.setColor(barColor[1], barColor[2], barColor[3], 1)
        love.graphics.rectangle("fill", barX, barY, fillW, barHeight, 3, 3)
        love.graphics.setColor(1, 0.96, 0.9, 0.34)
        love.graphics.rectangle("fill", barX, barY, fillW, barHeight * 0.4, 3, 3)
        love.graphics.setColor(1, 0.96, 0.9, 0.32 + 0.18 * math.sin(t * 4))
        love.graphics.rectangle("fill", barX + fillW - 4, barY, 4, barHeight, 2, 2)
    end

    love.graphics.setColor(barColor[1], barColor[2], barColor[3], 0.72)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 3, 3)

    local labelFont = _G.PixelFonts and _G.PixelFonts.uiTiny or love.graphics.getFont()
    love.graphics.setFont(labelFont)
    local bossName = "TREENT OVERLORD"
    local nameW = labelFont:getWidth(bossName)
    love.graphics.setColor(0.96, 0.97, 1.0, 0.96)
    love.graphics.print(bossName, barX + barWidth / 2 - nameW / 2, barY - 12)

    local hpText = string.format("%d / %d", math.floor(self.boss.health), math.floor(self.boss.maxHealth))
    local hpW = labelFont:getWidth(hpText)
    love.graphics.setColor(0.94, 0.96, 1.0, 0.9)
    love.graphics.print(hpText, barX + barWidth + 10, barY - 1)

    if _G.PixelFonts then love.graphics.setFont(_G.PixelFonts.body) end
    love.graphics.setColor(1, 1, 1, 1)
end

return BossArenaScene
