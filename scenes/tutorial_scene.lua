-- scenes/tutorial_scene.lua
-- Phased tutorial: introduces player to each ability in a small arena.
-- Self-paced with dummy enemy; ends with practice wave then transition to main game.

local Player = require("entities.player")
local Arrow = require("entities.arrow")
local ArrowVolley = require("entities.arrow_volley")
local Slime = require("entities.slime")
local TutorialDummy = require("entities.tutorial_dummy")
local BarkVolleyAOE = require("entities.bark_volley_aoe")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local Camera = require("systems.camera")
local DamageNumbers = require("systems.damage_numbers")
local Config = require("data.config")

local TutorialScene = {}
TutorialScene.__index = TutorialScene

local function fitText(font, text, maxWidth)
    text = tostring(text or "")
    if not font or font:getWidth(text) <= maxWidth then
        return text
    end

    local trimmed = text
    while #trimmed > 0 and font:getWidth(trimmed .. "...") > maxWidth do
        trimmed = trimmed:sub(1, -2)
    end

    if trimmed == "" then
        return "..."
    end
    return trimmed .. "..."
end

local function wrapText(font, text, maxWidth)
    local lines = {}
    local current = ""
    for word in tostring(text or ""):gmatch("%S+") do
        local test = current == "" and word or (current .. " " .. word)
        if not font or font:getWidth(test) <= maxWidth then
            current = test
        else
            if current ~= "" then
                table.insert(lines, current)
            end
            current = word
        end
    end
    if current ~= "" then
        table.insert(lines, current)
    end
    if #lines == 0 then
        lines[1] = ""
    end
    return lines
end

local function getTutorialKeyLabel(key)
    if key == "return" then
        return "ENTER"
    end
    if key == "space" then
        return "SPACE"
    end
    return string.upper(tostring(key or ""))
end

local function getRevealedText(text, elapsed, charsPerSecond, startDelay, revealAll)
    text = tostring(text or "")
    if revealAll or text == "" then
        return text
    end

    local visibleTime = math.max(0, (elapsed or 0) - (startDelay or 0))
    local visibleChars = math.floor(visibleTime * (charsPerSecond or 1))
    if visibleChars <= 0 then
        return ""
    end
    if visibleChars >= #text then
        return text
    end
    return text:sub(1, visibleChars)
end

local function getWrappedRevealLines(font, text, maxWidth, maxLines)
    local lines = wrapText(font, text, maxWidth)
    maxLines = maxLines or #lines
    if #lines <= maxLines then
        return lines
    end

    local limited = {}
    for i = 1, maxLines do
        limited[i] = lines[i] or ""
    end
    limited[maxLines] = fitText(font, limited[maxLines], maxWidth)
    return limited
end

-- Tutorial pacing (slower so player can observe)
local MIN_PHASE_DURATION = 6
local APPROACH_DISTANCE = 200
local DASH_PHASE_REQUIRED = 2
local PRACTICE_WAVE_KILLS = 3
local BARK_VOLLEY_SPAWN_INTERVAL = 2.8
local PHASE_COMPLETE_HOLD = 0.85
local DUMMY_OFFSET_X = 460
local TITLE_REVEAL_SPEED = 24
local BODY_REVEAL_SPEED = 40
local HINT_REVEAL_SPEED = 52

-- Phase definitions
local PHASES = {
    {
        id = "movement",
        title = "MOVEMENT",
        body = "Use WASD to move around the arena.",
        hint = "Move in all 4 directions to continue.",
        condition = "move_all_dirs",
        taskLabel = "Movement inputs",
    },
    {
        id = "primary",
        title = "PRIMARY ATTACK",
        body = "Walk toward the dummy until your bow reaches it. Your primary attack fires automatically.",
        hint = "Step into range to trigger your first shots.",
        condition = "approached_dummy",
        spawnDummy = 1,
        taskLabel = "Enter attack range",
    },
    {
        id = "multi_shot",
        title = "MULTI SHOT (Q)",
        body = "Walk into range. Multi Shot fires a 3-arrow cone automatically when it is ready.",
        hint = "Get close enough and let Q trigger on its own.",
        condition = "ability_fired",
        abilityId = "multi_shot",
        highlight = "Q",
        spawnDummy = 1,
        taskLabel = "Trigger Q auto-cast",
    },
    {
        id = "arrow_volley",
        title = "ARROW VOLLEY (E)",
        body = "Walk into range. Arrow Volley rains arrows on the dummy automatically when it is ready.",
        hint = "Get close enough and let E trigger on its own.",
        condition = "ability_fired",
        abilityId = "entangle",
        highlight = "E",
        spawnDummy = 1,
        taskLabel = "Trigger E auto-cast",
    },
    {
        id = "dash",
        title = "DASH (SPACE)",
        body = "Dodge the incoming volleys! Press SPACE to dash. Grants invincibility frames.",
        hint = "Dash out of 2 red circles to continue!",
        condition = "dash_count",
        highlight = "SPACE",
        spawnDummy = 1,
        taskLabel = "Dash 2 times",
    },
    {
        id = "frenzy",
        title = "FRENZY (R)",
        body = "You're hurt. Press R to activate Frenzy, then move in and attack the dummy to heal.",
        hint = "Press R, then attack to restore health.",
        condition = "press_key",
        waitKey = "r",
        highlight = "R",
        grantFrenzy = true,
        spawnDummy = 1,
        scriptedDamage = true,
        taskLabel = "Press R",
    },
    {
        id = "practice_wave",
        title = "SEE IT IN ACTION",
        body = "Defeat the monsters using everything you've learned!",
        hint = "Kill the monsters to continue.",
        condition = "practice_wave",
        spawnSlimes = 4,
        taskLabel = "Clear the wave",
    },
    {
        id = "complete",
        title = "TUTORIAL COMPLETE!",
        body = "You're ready to begin your ascent. Good luck!",
        hint = "Press ENTER or click BEGIN below.",
        condition = "press_key",
        waitKey = "return",
    },
}

function TutorialScene:new(gameState)
    local scene = {
        gameState = gameState,
        player = nil,
        particles = nil,
        screenShake = nil,
        camera = nil,
        damageNumbers = nil,
        arrows = {},
        arrowVolleys = {},
        enemies = {},
        barkVolleyAoEs = {},
        barkVolleySpawnTimer = 0,
        fireCooldown = 0,
        fireRate = 0.4,
        attackRange = 350,

        -- Dash
        isDashing = false,
        dashTime = 0,
        dashDirX = 0,
        dashDirY = 0,
        dashDuration = 0.2,
        dashSpeed = 800,
        dashCooldown = 0,
        dashCount = 0,

        -- Tutorial state
        currentPhase = 1,
        phaseTimer = 0,
        phaseComplete = false,
        phaseAdvanceTimer = 0,
        killCount = 0,
        movedDirs = {},
        abilityFiredThisPhase = false,
        keyPressedThisPhase = false,
        approachedDummy = false,

        -- Frenzy (simplified for tutorial)
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        frenzyActive = false,
        frenzyDuration = 0,

        -- Arena dimensions (set in load)
        arenaW = 1920,
        arenaH = 1080,
    }
    setmetatable(scene, TutorialScene)
    return scene
end

function TutorialScene:load()
    self.arenaW = love.graphics.getWidth()
    self.arenaH = love.graphics.getHeight()

    self.player = Player:new(self.arenaW / 2, self.arenaH / 2)
    self.player.maxHealth = 999
    self.player.health = 999

    self.particles = Particles:new()
    self.screenShake = ScreenShake:new()
    self.camera = Camera:new(0, 0, self.arenaW, self.arenaH)
    self.damageNumbers = DamageNumbers:new()

    self.player.abilities.frenzy.charge = 0
    self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax

    self:startPhase(1)
end

function TutorialScene:startPhase(idx)
    self.currentPhase = idx
    self.phaseTimer = 0
    self.phaseComplete = false
    self.phaseAdvanceTimer = 0
    self.killCount = 0
    self.abilityFiredThisPhase = false
    self.keyPressedThisPhase = false
    self.approachedDummy = false
    self.dashCount = 0
    self.barkVolleyAoEs = {}
    self.barkVolleySpawnTimer = 0
    self.arrows = {}
    self.arrowVolleys = {}
    self.isDashing = false
    self.dashTime = 0

    if self.player then
        self.player.x = self.arenaW / 2
        self.player.y = self.arenaH / 2
    end

    local phase = PHASES[idx]
    if not phase then return end

    -- Spawn dummy (invulnerable target)
    if phase.spawnDummy then
        self.enemies = {}
        local dx = phase.dummyOffsetX or DUMMY_OFFSET_X
        local dy = phase.dummyOffsetY or 0
        local dummyX = self.arenaW / 2 + dx
        local dummyY = self.arenaH / 2 + dy
        local dummy = TutorialDummy:new(dummyX, dummyY)
        dummy.damage = 0
        dummy.speed = 0
        table.insert(self.enemies, dummy)
    end

    -- Spawn real slimes (practice wave)
    if phase.spawnSlimes then
        self.enemies = {}
        for i = 1, phase.spawnSlimes do
            local angle = (i / phase.spawnSlimes) * math.pi * 2
            local dist = 180 + math.random(0, 60)
            local sx = self.arenaW / 2 + math.cos(angle) * dist
            local sy = self.arenaH / 2 + math.sin(angle) * dist
            local slime = Slime:new(sx, sy)
            slime.health = 30
            slime.maxHealth = 30
            slime.damage = 8
            slime.speed = 40
            table.insert(self.enemies, slime)
        end
    end

    -- Tutorial cooldowns (slower so player can observe)
    if self.player then
        if phase.abilityId == "multi_shot" then
            self.player.abilities.multi_shot.cooldown = 4.5
            self.player.abilities.multi_shot.currentCooldown = 0
        elseif phase.abilityId == "entangle" then
            self.player.abilities.entangle.cooldown = 3
            self.player.abilities.entangle.currentCooldown = 3  -- Start on CD so it doesn't fire right away
        end
    end

    -- Frenzy phase: scripted damage + grant charge
    if phase.scriptedDamage and self.player then
        self.player.maxHealth = 100
        self.player.health = math.max(1, math.floor(self.player.maxHealth * 0.5))
    end
    if phase.grantFrenzy and self.player then
        self.frenzyCharge = self.frenzyChargeMax
        self.player.abilities.frenzy.charge = self.frenzyChargeMax
    end
end

function TutorialScene:update(dt)
    dt = math.min(dt, 1 / 30)

    self.phaseTimer = self.phaseTimer + dt
    self.particles:update(dt)
    self.screenShake:update(dt)
    if self.damageNumbers then self.damageNumbers:update(dt) end

    if self.camera and self.player then
        self.camera:update(dt, self.player.x, self.player.y)
    end

    -- Dash
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    if self.isDashing then
        self.dashTime = self.dashTime - dt
        if self.dashTime <= 0 then
            self.isDashing = false
        else
            self.player.x = self.player.x + self.dashDirX * self.dashSpeed * dt
            self.player.y = self.player.y + self.dashDirY * self.dashSpeed * dt
            self.particles:createDashTrail(self.player.x, self.player.y)
        end
    end

    self.player.isDashing = self.isDashing
    self.player:update(dt)

    -- Clamp to arena
    self.player.x = math.max(self.player.size, math.min(self.arenaW - self.player.size, self.player.x))
    self.player.y = math.max(self.player.size, math.min(self.arenaH - self.player.size, self.player.y))

    -- Track movement directions
    if love.keyboard.isDown("w") then self.movedDirs["w"] = true end
    if love.keyboard.isDown("a") then self.movedDirs["a"] = true end
    if love.keyboard.isDown("s") then self.movedDirs["s"] = true end
    if love.keyboard.isDown("d") then self.movedDirs["d"] = true end

    -- Update cooldowns
    self.fireCooldown = math.max(0, self.fireCooldown - dt)

    -- Frenzy charge display and duration
    self.player.abilities.frenzy.charge = math.floor(self.frenzyCharge)
    self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax
    if self.frenzyActive then
        self.frenzyDuration = self.frenzyDuration - dt
        if self.frenzyDuration <= 0 then
            self.frenzyActive = false
        end
    end

    local px, py = self.player:getPosition()
    local nearest, nearDist = nil, self.attackRange
    for _, e in ipairs(self.enemies) do
        if e.isAlive then
            local ex, ey = e:getPosition()
            local d = math.sqrt((px - ex)^2 + (py - ey)^2)
            if d < nearDist then
                nearest = e
                nearDist = d
            end
            -- Track approached dummy (phase 2)
            if e.isTutorialDummy and d <= APPROACH_DISTANCE then
                self.approachedDummy = true
            end
        end
    end

    -- Auto-fire primary at nearest enemy
    if nearest then
        local ex, ey = nearest:getPosition()
        self.player:aimAt(ex, ey)
        if self.fireCooldown <= 0 and not self.isDashing then
            local sx, sy = self.player:getBowTip()
            local arrow = Arrow:new(sx, sy, ex, ey, { damage = 15, kind = "primary", knockback = 100 })
            table.insert(self.arrows, arrow)
            self.fireCooldown = self.fireRate
            if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
        end
    end

    -- Multi Shot auto-cast (phase 3 only)
    if self.currentPhase == 3 and self.player:isAbilityReady("multi_shot") and nearest and not self.isDashing then
        local ex, ey = nearest:getPosition()
        self.player:useAbility("multi_shot")
        self.abilityFiredThisPhase = true
        local sx, sy = self.player:getBowTip()
        local baseAngle = math.atan2(ey - sy, ex - sx)
        local spread = math.rad(15)
        for off = -1, 1 do
            local a = baseAngle + off * spread / 2
            local tx = sx + math.cos(a) * 400
            local ty = sy + math.sin(a) * 400
            table.insert(self.arrows, Arrow:new(sx, sy, tx, ty, { damage = 15, kind = "multi_shot", knockback = 80 }))
        end
        self.screenShake:add(2, 0.08)
    end

    -- Arrow Volley auto-cast (phase 4 only) — uses real ArrowVolley entity for in-game VFX
    if self.currentPhase == 4 and self.player:isAbilityReady("entangle") and nearest and not self.isDashing then
        self.player:useAbility("entangle")
        self.abilityFiredThisPhase = true
        local ex, ey = nearest:getPosition()
        local volley = ArrowVolley:new(ex, ey, 25, 80, 0)
        table.insert(self.arrowVolleys, volley)
        self.screenShake:add(3, 0.12)
        self.particles:createRootBurst(px, py)
        if _G.audio then _G.audio:playSFX("shoot_arrow") end
        if _G.triggerScreenFlash then _G.triggerScreenFlash({0.8, 0.2, 0.2, 0.2}, 0.08) end
    end

    -- Dash phase: spawn Bark Volley AOE at player
    if self.currentPhase == 5 then
        self.barkVolleySpawnTimer = self.barkVolleySpawnTimer + dt
        if self.barkVolleySpawnTimer >= BARK_VOLLEY_SPAWN_INTERVAL then
            self.barkVolleySpawnTimer = 0
            local cfg = Config.TreentOverlord or {}
            local radius = cfg.barkVolleyRadius or 55
            local damage = cfg.barkVolleyDamage or 25
            local telegraph = cfg.barkVolleyTelegraphDuration or 0.9
            local impact = cfg.barkVolleyImpactDuration or 0.25
            local aoe = BarkVolleyAOE:new(px, py, radius, damage, telegraph, impact)
            table.insert(self.barkVolleyAoEs, aoe)
        end
    end

    -- Update Bark Volley AOEs and check player damage (dash phase)
    for i = #self.barkVolleyAoEs, 1, -1 do
        local aoe = self.barkVolleyAoEs[i]
        aoe:update(dt)
        if aoe:isInImpactPhase() and self.player then
            if aoe:isPlayerInDanger(px, py) and not self.isDashing then
                local dmg = aoe:getDamage()
                self.player:takeDamage(dmg)
                self.screenShake:add(3, 0.12)
            end
        end
        if aoe.isFinished then
            table.remove(self.barkVolleyAoEs, i)
        end
    end

    -- Update Arrow Volleys (phase 4 — impact-timed damage, same as real game)
    for i = #self.arrowVolleys, 1, -1 do
        local volley = self.arrowVolleys[i]
        volley:update(dt)
        if volley:shouldApplyDamage() then
            local dmg = volley:getDamage()
            local vx, vy = volley:getPosition()
            local radius = volley:getDamageRadius()
            for _, e in ipairs(self.enemies) do
                if e.isAlive then
                    local ex, ey = e:getPosition()
                    local dx = ex - vx
                    local dy = ey - vy
                    if dx * dx + dy * dy <= radius * radius then
                        e:takeDamage(dmg, vx, vy, nil)
                        self.particles:createHitSpark(ex, ey, {1, 1, 0.6})
                        if self.damageNumbers then
                            self.damageNumbers:add(ex, ey - e:getSize(), dmg, {})
                        end
                    end
                end
            end
        end
        if volley:isFinished() then
            table.remove(self.arrowVolleys, i)
        end
    end

    -- Update arrows + collision (with lifesteal for Frenzy phase)
    local lifeSteal = (Config.Abilities and Config.Abilities.frenzy and Config.Abilities.frenzy.lifeSteal) or 0.10
    for i = #self.arrows, 1, -1 do
        local arrow = self.arrows[i]
        arrow:update(dt)
        local ax, ay = arrow:getPosition()
        local hit = false
        for _, e in ipairs(self.enemies) do
            if e.isAlive then
                local ex, ey = e:getPosition()
                local dx = ax - ex
                local dy = ay - ey
                local sumR = e:getSize() + arrow:getSize()
                if dx * dx + dy * dy < sumR * sumR and arrow:canHit(e) then
                    arrow:markHit(e)
                    local died = e:takeDamage(arrow.damage, ax, ay, 100)
                    self.particles:createHitSpark(ex, ey, {1, 1, 0.6})
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - e:getSize(), arrow.damage, {})
                    end
                    -- Frenzy lifesteal
                    if self.frenzyActive and self.player and not self.player:isDead() then
                        local healAmount = arrow.damage * lifeSteal
                        self.player.health = math.min(self.player.maxHealth, self.player.health + healAmount)
                    end
                    if died then
                        self.killCount = self.killCount + 1
                        self.particles:createExplosion(ex, ey, {0.3, 0.6, 0.3})
                        self.screenShake:add(4, 0.15)
                    end
                    if not arrow:consumePierce() then hit = true end
                    break
                end
            end
        end
        if hit or arrow:isExpired() then
            table.remove(self.arrows, i)
        end
    end

    -- Update enemies
    for _, e in ipairs(self.enemies) do
        if e.isAlive then e:update(dt, px, py) end
    end

    -- Practice wave: enemy contact damage (throttled per enemy)
    if self.currentPhase == 7 then
        for _, e in ipairs(self.enemies) do
            if e.isAlive and e.damage and e.damage > 0 then
                local ex, ey = e:getPosition()
                local dist = math.sqrt((px - ex)^2 + (py - ey)^2)
                if dist < self.player:getSize() + e:getSize() and not self.isDashing and not self.player:isInvincible() then
                    e.tutorialContactTimer = (e.tutorialContactTimer or 0) + dt
                    if e.tutorialContactTimer >= 0.6 then
                        e.tutorialContactTimer = 0
                        self.player:takeDamage(e.damage)
                    end
                else
                    e.tutorialContactTimer = 0
                end
            end
        end
    end

    -- Practice wave: player death returns to menu
    if self.currentPhase == 7 and self.player and self.player:isDead() then
        self.gameState:reset()
        return
    end

    -- Check phase completion
    self:checkPhaseCondition()

    if self.phaseComplete and self.phaseAdvanceTimer > 0 then
        self.phaseAdvanceTimer = math.max(0, self.phaseAdvanceTimer - dt)
        if self.phaseAdvanceTimer <= 0 then
            local next = self.currentPhase + 1
            if next <= #PHASES then
                self:startPhase(next)
            end
        end
    end
end

function TutorialScene:checkPhaseCondition()
    local phase = PHASES[self.currentPhase]
    if not phase or self.phaseComplete then return end

    if phase.condition == "move_all_dirs" then
        if self.movedDirs["w"] and self.movedDirs["a"] and self.movedDirs["s"] and self.movedDirs["d"] and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    elseif phase.condition == "approached_dummy" then
        if self.approachedDummy and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    elseif phase.condition == "ability_fired" then
        if self.abilityFiredThisPhase and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    elseif phase.condition == "dash_count" then
        if self.dashCount >= DASH_PHASE_REQUIRED and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    elseif phase.condition == "press_key" then
        if self.keyPressedThisPhase and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    elseif phase.condition == "practice_wave" then
        if self.killCount >= PRACTICE_WAVE_KILLS then
            self:completePhase()
        end
    elseif phase.condition == "press_key" then
        if self.keyPressedThisPhase and self.phaseTimer >= MIN_PHASE_DURATION then
            self:completePhase()
        end
    end
end

function TutorialScene:completePhase()
    self.phaseComplete = true
    local phase = PHASES[self.currentPhase]
    if phase and phase.id == "complete" then
        self:transitionToGame()
        return
    end
    self.phaseAdvanceTimer = PHASE_COMPLETE_HOLD
end

-- Shared transition logic (complete phase or skip)
function TutorialScene:transitionToGame()
    self.gameState:selectBiome("DEEPWOOD")
    self.gameState:setDefaultDifficulty()
    self.gameState:initFloor(1)
    self.gameState:transitionTo(self.gameState.States.PLAYING)
end

function TutorialScene:draw()
    if self.camera then self.camera:attach() end

    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)

    -- Arena floor
    love.graphics.setColor(0.12, 0.18, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, self.arenaW, self.arenaH)
    -- Arena border
    love.graphics.setColor(0.3, 0.4, 0.3, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 2, 2, self.arenaW - 4, self.arenaH - 4, 4, 4)
    love.graphics.setLineWidth(1)

    -- Draw Bark Volley AOEs (dash phase)
    for _, aoe in ipairs(self.barkVolleyAoEs) do
        aoe:draw()
    end

    -- Draw enemies
    for _, e in ipairs(self.enemies) do
        if e.isAlive then e:draw() end
    end

    -- Draw player
    if self.player then
        if self.isDashing then love.graphics.setColor(1, 1, 1, 0.3) end
        self.player:draw()
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Arrow Volleys (falling arrows + impact zones)
    for _, volley in ipairs(self.arrowVolleys) do
        volley:draw()
    end

    -- Arrows
    for _, arrow in ipairs(self.arrows) do arrow:draw() end

    -- Damage numbers
    if self.damageNumbers then self.damageNumbers:draw() end

    -- Particles
    self.particles:draw()

    love.graphics.pop()
    if self.camera then self.camera:detach() end

    -- Draw tutorial HUD (screen space)
    self:drawTutorialHUD()
    self:drawBottomHUD()
end

function TutorialScene:getTutorialPanelRect()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local panelW = 660
    local panelH = 154
    local panelX = (w - panelW) / 2
    local panelY = math.max(36, math.floor(h * 0.08))
    return panelX, panelY, panelW, panelH
end

function TutorialScene:getTaskTrackerRect(panelX, panelY, panelW, panelH)
    local phase = PHASES[self.currentPhase]
    local isMovement = phase and phase.condition == "move_all_dirs"
    local trackerW = isMovement and 220 or 280
    local trackerH = isMovement and 104 or 58
    local trackerX = math.max(24, panelX - trackerW - 26)
    local trackerY = panelY + math.floor((panelH - trackerH) / 2)
    return trackerX, trackerY, trackerW, trackerH
end

function TutorialScene:drawTutorialHUD()
    local w = love.graphics.getWidth()
    local phase = PHASES[self.currentPhase]
    if not phase then return end

    local titleFont = _G.PixelFonts and (_G.PixelFonts.uiLarge or _G.PixelFonts.header) or love.graphics.getFont()
    local bodyFont = _G.PixelFonts and (_G.PixelFonts.uiSmall or _G.PixelFonts.body) or love.graphics.getFont()
    local hintFont = _G.PixelFonts and _G.PixelFonts.uiTiny or bodyFont

    local panelX, panelY, panelW, panelH = self:getTutorialPanelRect()
    local innerPad = 16
    local topRowY = panelY + 8
    local titleY = panelY + 16
    local skipText = "TAB TO SKIP"
    local counter = string.format("PHASE %d/%d", self.currentPhase, #PHASES)
    local leftW = hintFont:getWidth(counter)
    local rightW = hintFont:getWidth(skipText)
    local titleMaxW = panelW - innerPad * 2 - leftW - rightW - 28
    local bodyMaxW = panelW - innerPad * 2 - 24
    local titleText = fitText(
        titleFont,
        getRevealedText(phase.title, self.phaseTimer, TITLE_REVEAL_SPEED, 0.00, self.phaseComplete),
        titleMaxW
    )
    local bodyText = getRevealedText(phase.body, self.phaseTimer, BODY_REVEAL_SPEED, 0.15, self.phaseComplete)
    local hintText = getRevealedText(phase.hint, self.phaseTimer, HINT_REVEAL_SPEED, 0.90, self.phaseComplete)
    local bodyLines = getWrappedRevealLines(bodyFont, bodyText, bodyMaxW, 2)
    local hintLines = getWrappedRevealLines(hintFont, hintText, bodyMaxW, 2)
    local bodyLineHeight = bodyFont:getHeight() + 2
    local hintLineHeight = hintFont:getHeight() + 1
    local titleBottomY = titleY + titleFont:getHeight()
    local bodyStartY = titleBottomY + 10
    local hintStartY = bodyStartY + (#bodyLines * bodyLineHeight) + 12

    love.graphics.setColor(0.04, 0.04, 0.08, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setColor(0.5, 0.7, 1.0, 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Skip hint (for returning players)
    love.graphics.setFont(hintFont)
    love.graphics.setColor(0.5, 0.6, 0.7, 0.7)
    love.graphics.print(skipText, panelX + panelW - rightW - innerPad, topRowY)

    -- Phase counter
    love.graphics.setFont(hintFont)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.print(counter, panelX + innerPad, topRowY)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.9, 0.6, 1)
    local tw = titleFont:getWidth(titleText)
    love.graphics.print(titleText, w / 2 - tw / 2, titleY)

    -- Body text
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    for i, line in ipairs(bodyLines) do
        local bw = bodyFont:getWidth(line)
        love.graphics.print(line, w / 2 - bw / 2, bodyStartY + (i - 1) * bodyLineHeight)
    end

    -- Hint (pulsing)
    love.graphics.setFont(hintFont)
    local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(0.4, 0.8, 1.0, pulse)
    for i, line in ipairs(hintLines) do
        local hw = hintFont:getWidth(line)
        love.graphics.print(line, w / 2 - hw / 2, hintStartY + (i - 1) * hintLineHeight)
    end

    -- Begin button (complete phase only)
    if phase.id == "complete" then
        local btnW, btnH = 180, 44
        local btnX = (w - btnW) / 2
        local btnY = panelY + panelH + 18
        local hover = self:isPointInBeginButton(love.mouse.getX(), love.mouse.getY())
        love.graphics.setColor(0.15, 0.35, 0.2, 0.95)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 8, 8)
        love.graphics.setColor(hover and 0.5 or 0.35, 0.85, hover and 0.6 or 0.45, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 8, 8)
        love.graphics.setLineWidth(1)
        love.graphics.setFont(titleFont)
        love.graphics.setColor(1, 1, 0.95, 1)
        local btnText = "BEGIN"
        love.graphics.print(btnText, btnX + (btnW - titleFont:getWidth(btnText)) / 2, btnY + (btnH - titleFont:getHeight()) / 2 - 2)
    end

    -- Highlight indicator on the relevant ability diamond
    if phase.highlight then
        self:drawAbilityHighlight(phase.highlight)
    end

    if phase.id ~= "complete" then
        self:drawTaskTracker(panelX, panelY, panelW, panelH)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TutorialScene:isCurrentTaskComplete()
    local phase = PHASES[self.currentPhase]
    if not phase then return false end

    if phase.condition == "move_all_dirs" then
        return self.movedDirs["w"] and self.movedDirs["a"] and self.movedDirs["s"] and self.movedDirs["d"]
    elseif phase.condition == "approached_dummy" then
        return self.approachedDummy
    elseif phase.condition == "ability_fired" then
        return self.abilityFiredThisPhase
    elseif phase.condition == "dash_count" then
        return self.dashCount >= DASH_PHASE_REQUIRED
    elseif phase.condition == "press_key" then
        return self.keyPressedThisPhase
    elseif phase.condition == "practice_wave" then
        return self.killCount >= PRACTICE_WAVE_KILLS
    end

    return false
end

function TutorialScene:getTaskLabel()
    local phase = PHASES[self.currentPhase]
    if not phase then
        return "Objective"
    end

    if phase.taskLabel then
        return phase.taskLabel
    end

    if phase.condition == "move_all_dirs" then
        return "Move in all directions"
    elseif phase.condition == "approached_dummy" then
        return "Enter attack range"
    elseif phase.condition == "ability_fired" then
        return "Let it auto-cast"
    elseif phase.condition == "dash_count" then
        return "Dash through danger"
    elseif phase.condition == "press_key" then
        return "Press " .. getTutorialKeyLabel(phase.waitKey)
    elseif phase.condition == "practice_wave" then
        return "Clear the wave"
    end

    return phase.title or "Objective"
end

function TutorialScene:drawTaskTracker(panelX, panelY, panelW, panelH)
    local phase = PHASES[self.currentPhase]
    if not phase then
        return
    end

    local trackerX, trackerY, trackerW, trackerH = self:getTaskTrackerRect(panelX, panelY, panelW, panelH)
    local complete = self:isCurrentTaskComplete() or self.phaseComplete
    local titleFont = _G.PixelFonts and _G.PixelFonts.uiSmall or love.graphics.getFont()
    local valueFont = (_G.PixelFonts and (_G.PixelFonts.uiBody or _G.PixelFonts.uiSmall)) or titleFont
    local borderColor = complete and {0.35, 0.9, 0.45, 0.9} or {0.45, 0.65, 1.0, 0.55}

    love.graphics.setColor(0.03, 0.05, 0.10, 0.92)
    love.graphics.rectangle("fill", trackerX, trackerY, trackerW, trackerH, 8, 8)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", trackerX, trackerY, trackerW, trackerH, 8, 8)
    love.graphics.setLineWidth(1)

    if phase.condition == "move_all_dirs" then
        local moveCount = 0
        if self.movedDirs["w"] then moveCount = moveCount + 1 end
        if self.movedDirs["a"] then moveCount = moveCount + 1 end
        if self.movedDirs["s"] then moveCount = moveCount + 1 end
        if self.movedDirs["d"] then moveCount = moveCount + 1 end

        love.graphics.setFont(titleFont)
        love.graphics.setColor(0.82, 0.88, 0.98, 0.95)
        love.graphics.print("MOVE KEYS", trackerX + 14, trackerY + 8)

        love.graphics.setFont(valueFont)
        love.graphics.setColor(1, 0.92, 0.62, 1)
        local moveProgress = string.format("%d/4", moveCount)
        love.graphics.print(moveProgress, trackerX + trackerW - valueFont:getWidth(moveProgress) - 14, trackerY + 8)

        local keys = {
            { id = "w", label = "W" },
            { id = "a", label = "A" },
            { id = "s", label = "S" },
            { id = "d", label = "D" },
        }

        love.graphics.setFont(titleFont)
        for index, entry in ipairs(keys) do
            local col = (index - 1) % 2
            local row = math.floor((index - 1) / 2)
            local cellX = trackerX + 14 + col * 92
            local cellY = trackerY + 34 + row * 28
            local checked = self.movedDirs[entry.id]

            love.graphics.setColor(0.85, 0.9, 1.0, 0.8)
            love.graphics.rectangle("line", cellX, cellY, 14, 14, 3, 3)
            if checked then
                love.graphics.setColor(0.35, 0.95, 0.45, 0.95)
                love.graphics.rectangle("fill", cellX + 3, cellY + 3, 8, 8, 2, 2)
            end

            love.graphics.setColor(checked and 0.9 or 0.75, checked and 1.0 or 0.82, checked and 0.92 or 0.9, 1)
            love.graphics.print(entry.label, cellX + 22, cellY - 1)
        end

        return
    end

    local progressText = complete and "1/1" or "0/1"
    local taskLabel = fitText(titleFont, self:getTaskLabel(), trackerW - 88)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.82, 0.88, 0.98, 0.95)
    love.graphics.print("TASK", trackerX + 14, trackerY + 8)
    love.graphics.setColor(1, 1, 1, 0.82)
    love.graphics.print(taskLabel, trackerX + 14, trackerY + 29)

    love.graphics.setFont(valueFont)
    if complete then
        love.graphics.setColor(0.45, 1.0, 0.55, 1)
    else
        love.graphics.setColor(1, 0.92, 0.62, 1)
    end
    love.graphics.print(progressText, trackerX + trackerW - valueFont:getWidth(progressText) - 14, trackerY + 18)
end

function TutorialScene:getBeginButtonRect()
    local w = love.graphics.getWidth()
    local _, panelY, _, panelH = self:getTutorialPanelRect()
    local btnW, btnH = 180, 44
    local btnX = (w - btnW) / 2
    local btnY = panelY + panelH + 18
    return btnX, btnY, btnW, btnH
end

function TutorialScene:isPointInBeginButton(px, py)
    local phase = PHASES[self.currentPhase]
    if not phase or phase.id ~= "complete" then return false end
    local bx, by, bw, bh = self:getBeginButtonRect()
    return px >= bx and px <= bx + bw and py >= by and py <= by + bh
end

function TutorialScene:drawAbilityHighlight(key)
    local slots = getAbilitySlotLayout()
    for _, slot in ipairs(slots) do
        if slot.key == key then
            local r = slot.r or 26
            local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 5)
            love.graphics.setColor(1, 0.9, 0.3, 0.3 * pulse)
            love.graphics.circle("fill", slot.cx, slot.cy, r + 14)
            love.graphics.setColor(1, 0.9, 0.3, 0.7 * pulse)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", slot.cx, slot.cy, r + 10)
            love.graphics.setLineWidth(1)
            -- Arrow pointing at diamond
            love.graphics.setColor(1, 0.9, 0.3, pulse)
            local arrowY = slot.cy - r - 20
            love.graphics.polygon("fill", slot.cx, arrowY + 8, slot.cx - 6, arrowY, slot.cx + 6, arrowY)
            break
        end
    end
end

function TutorialScene:drawBottomHUD()
    if self.player then
        drawBottomHUD(self.player)
    end
end

function TutorialScene:keypressed(key)
    local phase = PHASES[self.currentPhase]

    -- Tab: skip tutorial (for returning players)
    if key == "tab" then
        self:transitionToGame()
        return
    end

    if phase and phase.condition == "press_key" and key == phase.waitKey then
        self.keyPressedThisPhase = true

        if key == "space" then
            self:startDash()
        elseif key == "r" and self.frenzyCharge >= self.frenzyChargeMax then
            self.frenzyCharge = 0
            self.frenzyActive = true
            self.frenzyDuration = (Config.Abilities and Config.Abilities.frenzy and Config.Abilities.frenzy.duration) or 8.0
            self.screenShake:add(4, 0.15)
            if self.player then
                local px, py = self.player:getPosition()
                self.particles:createFrenzyBurst(px, py)
            end
        end
    elseif key == "space" then
        self:startDash()
    end

    if phase and phase.id == "complete" and key == "return" then
        self:completePhase()
    end
end

function TutorialScene:startDash()
    if self.dashCooldown > 0 or self.isDashing then return end
    self.isDashing = true
    self.dashTime = self.dashDuration
    self.dashCooldown = self.player.abilities.dash.cooldown
    self.player.abilities.dash.currentCooldown = self.player.abilities.dash.cooldown
    self.player.invincibleTime = self.dashDuration
    if self.currentPhase == 5 then
        self.dashCount = self.dashCount + 1
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        self.dashDirX = dx / len
        self.dashDirY = dy / len
    else
        self.dashDirX = math.cos(self.player:getBowAngle())
        self.dashDirY = math.sin(self.player:getBowAngle())
    end
    self.screenShake:add(2, 0.1)
end

function TutorialScene:mousepressed(x, y, button)
    if button == 1 and self:isPointInBeginButton(x, y) then
        self:completePhase()
    end
end
function TutorialScene:mousemoved(x, y) end

return TutorialScene
