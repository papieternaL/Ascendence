-- LOVE2D Action RPG - ASCENDENCE
-- Main Entry Point

local GameState = require("systems.game_state")
local Menu = require("ui.menu")
local GameScene = require("scenes.game_scene")
local BossArenaScene = require("scenes.boss_arena_scene")
local TutorialScene = require("scenes.tutorial_scene")
local Audio = require("systems.audio")
local Settings = require("systems.settings")
local JuiceManager = require("systems.juice_manager")

-- Pixel-art rendering constants (reserved for future use with pixel sprite sheets)
-- local INTERNAL_W = 320
-- local INTERNAL_H = 180
-- local gameCanvas

-- Pre-loaded fonts (shared globally via _G)
local FONT_PATH = "assets/Other/Fonts/Kenney Future Square.ttf"
local FONT_PATH_BOLD = "assets/Other/Fonts/Kenney Bold.ttf"

-- Screen flash system (game_scene can trigger via _G.triggerScreenFlash)
local screenFlash = { timer = 0, duration = 0, color = {1, 1, 1, 0} }

-- Global game objects
local gameState
local menu
local gameScene
local bossArenaScene
local tutorialScene
local audio
local settings
local prevState = nil

-- Pre-loaded fonts for HUD (avoid creating every frame)
local hudFonts = {}

local function getBrightnessSetting()
    local graphics = _G.GameSettings and _G.GameSettings.graphics or nil
    return graphics and graphics.brightness or 0.58
end

local function useReducedFlashes()
    local gameplay = _G.GameSettings and _G.GameSettings.gameplay or nil
    return gameplay and gameplay.reducedFlashes == true
end

local function shouldShowFPS()
    local gameplay = _G.GameSettings and _G.GameSettings.gameplay or nil
    return gameplay and gameplay.showFPS == true
end

local function drawBrightnessOverlay(w, h)
    local brightness = getBrightnessSetting()
    local delta = brightness - 0.5
    if math.abs(delta) < 0.01 then
        return
    end

    if delta > 0 then
        love.graphics.setColor(1.0, 0.99, 0.96, math.min(0.24, delta * 0.45))
    else
        love.graphics.setColor(0, 0, 0, math.min(0.35, (-delta) * 0.60))
    end
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.load()
    -- Set up window
    love.window.setTitle("ASCENDENCE")

    -- Nearest-neighbor filtering for crisp pixel art
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load fonts with linear filter for clean scaling
    local ok, f
    local function loadFont(path, size)
        ok, f = pcall(love.graphics.newFont, path, size)
        if ok then
            f:setFilter("linear", "linear")
            return f
        end
        f = love.graphics.newFont(size)
        f:setFilter("linear", "linear")
        return f
    end

    hudFonts.tiny   = loadFont(FONT_PATH, 11)
    hudFonts.small  = loadFont(FONT_PATH, 14)
    hudFonts.body   = loadFont(FONT_PATH, 16)
    hudFonts.header = loadFont(FONT_PATH_BOLD, 24)
    hudFonts.title  = loadFont(FONT_PATH_BOLD, 36)
    hudFonts.dmgNormal = loadFont(FONT_PATH, 14)
    hudFonts.dmgCrit   = loadFont(FONT_PATH_BOLD, 20)
    hudFonts.uiTiny      = loadFont(FONT_PATH, 10)
    hudFonts.uiSmall     = loadFont(FONT_PATH, 12)
    hudFonts.uiBody      = loadFont(FONT_PATH, 15)
    hudFonts.uiSmallText = loadFont(FONT_PATH, 10)
    hudFonts.uiLarge     = loadFont(FONT_PATH_BOLD, 28)

    -- Expose fonts globally so other modules can use them
    _G.PixelFonts = hudFonts

    -- Set default font
    love.graphics.setFont(hudFonts.body)

    -- Initialize game state
    gameState = GameState:new()

    -- Initialize menu
    menu = Menu:new(gameState)

    -- Initialize audio system
    audio = Audio:new()
    _G.audio = audio

    -- Load + apply persistent user settings (must run before music so volume is correct)
    settings = Settings:new()
    settings:load()
    settings:setAudio(audio)

    -- BGM disabled temporarily; SFX and volume plumbing remain
    _G.settings = settings

    -- Global screen flash trigger (called by game_scene)
    _G.triggerScreenFlash = function(color, duration)
        local flashColor = color or {1, 1, 1, 0.4}
        local flashDuration = duration or 0.1
        local flashAlpha = flashColor[4] or 0.4

        if useReducedFlashes() then
            flashAlpha = math.min(flashAlpha, 0.12)
            flashDuration = math.min(flashDuration * 0.6, 0.06)
        end

        screenFlash.color = {flashColor[1], flashColor[2], flashColor[3], flashAlpha}
        screenFlash.duration = math.max(0.01, flashDuration)
        screenFlash.timer = screenFlash.duration
    end

    -- Game scene will be initialized when game starts
    gameScene = nil
end

function love.update(dt)
    -- Cap delta time to prevent physics issues
    dt = math.min(dt, 1/30)

    -- Update screen flash
    if screenFlash.timer > 0 then
        screenFlash.timer = screenFlash.timer - dt
    end

    -- Update game state transitions
    gameState:update(dt)

    -- Update JuiceManager (hit-stop freeze, flash timers) - must run every frame
    JuiceManager.update(dt)

    -- Update audio system (handles fading)
    if audio then audio:update(dt) end

    local state = gameState:getState()
    local States = gameState.States

    -- Reset game scene when re-entering PLAYING from Game Over / Victory / Boss
    if state == States.PLAYING and prevState ~= nil and prevState ~= States.PLAYING then
        gameScene = nil
        bossArenaScene = nil
    end
    prevState = state

    if state == States.PLAYING then
        -- Initialize game scene if needed
        if not gameScene then
            gameScene = GameScene:new(gameState)
            gameScene:load()
            -- Boss Test Mode: immediately jump to boss fight (instant, no main map)
            if gameState.bossTestMode then
                gameState.bossTestMode = false
                gameState:enterBossFight(true)
                -- Create boss arena in same frame so we can draw it immediately
                if gameState:getState() == States.BOSS_FIGHT and not bossArenaScene and gameScene then
                    bossArenaScene = BossArenaScene:new(
                        gameScene.player,
                        gameScene.playerStats,
                        gameState,
                        gameScene.xpSystem,
                        gameScene.rarityCharge,
                        gameScene.frenzyCharge
                    )
                end
            end
        end
        if gameState:getState() == States.BOSS_FIGHT and bossArenaScene then
            bossArenaScene:update(dt)
        else
            gameScene:update(dt)
        end

        -- Check for game over
        if gameScene.player and gameScene.player:isDead() then
            gameState:transitionTo(States.GAME_OVER)
        end
    elseif state == States.BOSS_FIGHT then
        if not bossArenaScene and gameScene then
            bossArenaScene = BossArenaScene:new(
                gameScene.player,
                gameScene.playerStats,
                gameState,
                gameScene.xpSystem,
                gameScene.rarityCharge,
                gameScene.frenzyCharge
            )
        end
        if bossArenaScene then
            bossArenaScene:update(dt)
        end
    elseif state == States.TUTORIAL then
        if not tutorialScene then
            tutorialScene = TutorialScene:new(gameState)
            tutorialScene:load()
        end
        tutorialScene:update(dt)
    elseif state == States.MENU or state == States.SETTINGS or
           state == States.CHARACTER_SELECT or state == States.BIOME_SELECT then
        menu:update(dt)
        -- Reset scenes when in menu
        if gameScene then gameScene = nil end
        bossArenaScene = nil
        tutorialScene = nil
    elseif state == States.GAME_OVER or state == States.VICTORY then
        bossArenaScene = nil
        menu:update(dt)
    end
end

function love.draw()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local state = gameState:getState()
    local States = gameState.States

    -- ── Menu states render directly at native resolution (crisp UI) ──
    if state == States.MENU or state == States.SETTINGS or state == States.CHARACTER_SELECT or 
       state == States.BIOME_SELECT or state == States.GAME_OVER or state == States.VICTORY then
        menu:draw()
        drawBrightnessOverlay(winW, winH)
        
        -- Draw transition overlay
        if gameState.transitionAlpha > 0 then
            love.graphics.setColor(0, 0, 0, gameState.transitionAlpha)
            love.graphics.rectangle("fill", 0, 0, winW, winH)
            love.graphics.setColor(1, 1, 1, 1)
        end
        drawFPSOverlay()
        return
    end

    -- ── Gameplay states render directly at native resolution ──
    love.graphics.clear(0.05, 0.05, 0.08, 1)

    if state == States.PLAYING then
        if gameScene then
            gameScene:draw()
            drawHUD()
            if gameScene.drawOverlays then
                gameScene:drawOverlays()
            end
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene then
            bossArenaScene:draw()
            drawHUD()
        end
    elseif state == States.TUTORIAL then
        if tutorialScene then
            tutorialScene:draw()
        end
    end

    drawBrightnessOverlay(winW, winH)

    -- Draw transition overlay for gameplay states
    if gameState.transitionAlpha > 0 then
        love.graphics.setColor(0, 0, 0, gameState.transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, winW, winH)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Screen flash
    if screenFlash.timer > 0 then
        local a = (screenFlash.color[4] or 0.4) * (screenFlash.timer / screenFlash.duration)
        love.graphics.setColor(screenFlash.color[1], screenFlash.color[2], screenFlash.color[3], a)
        love.graphics.rectangle("fill", 0, 0, winW, winH)
        love.graphics.setColor(1, 1, 1, 1)
    end

    drawFPSOverlay()
end

function drawFPSOverlay()
    if not shouldShowFPS() then
        return
    end

    local font = (hudFonts and hudFonts.tiny) or love.graphics.getFont()
    local text = string.format("FPS %d", love.timer.getFPS())
    local x = love.graphics.getWidth() - font:getWidth(text) - 12
    local y = 10

    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(0.85, 0.92, 1.0, 0.92)
    love.graphics.print(text, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Helper: draw text with subtle shadow for readability
local function drawTextWithShadow(text, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, x, y)
end

-- Helper: draw a diamond (rotated square) polygon
local function drawDiamond(mode, cx, cy, halfW, halfH)
    love.graphics.polygon(mode, cx, cy - halfH, cx + halfW, cy, cx, cy + halfH, cx - halfW, cy)
end

local function drawHexPlate(mode, cx, cy, halfW, halfH, notch)
    notch = notch or math.floor(halfW * 0.34)
    love.graphics.polygon(
        mode,
        cx - halfW + notch, cy - halfH,
        cx + halfW - notch, cy - halfH,
        cx + halfW, cy,
        cx + halfW - notch, cy + halfH,
        cx - halfW + notch, cy + halfH,
        cx - halfW, cy
    )
end

function drawHUD()
    local state = gameState:getState()
    local States = gameState.States
    local hudPlayer = nil

    if state == States.PLAYING and gameScene then
        hudPlayer = gameScene.player
    elseif state == States.BOSS_FIGHT and bossArenaScene then
        hudPlayer = bossArenaScene.player
    end

    -- Draw top bar
    drawTopBar()

    -- Draw bottom HUD (health bar + abilities)
    if hudPlayer then
        drawBottomHUD(hudPlayer)
    end
end

-- Top bar layout
local HUD_SCALE = 1.10
local TOP_BAR_H = 52
local TOP_BAR_PAD = 14
local HUD_PANEL_W = 500
local HUD_PANEL_H = 92

local function getTopBarLayout(w)
    local centerW = math.floor(372 * HUD_SCALE)
    local centerH = math.floor(34 * HUD_SCALE)
    local centerX = w / 2 - centerW / 2
    local centerY = TOP_BAR_PAD
    local timeW = math.floor(122 * HUD_SCALE)
    local timeH = math.floor(32 * HUD_SCALE)
    local timeX = TOP_BAR_PAD
    local timeY = TOP_BAR_PAD + 2
    return {
        centerX = centerX,
        centerY = centerY,
        centerW = centerW,
        centerH = centerH,
        timeX = timeX,
        timeY = timeY,
        timeW = timeW,
        timeH = timeH,
    }
end

function drawTopBar()
    local w = love.graphics.getWidth()
    local state = gameState:getState()
    local States = gameState.States

    -- Only draw during play or boss fight
    if state ~= States.PLAYING and state ~= States.BOSS_FIGHT then return end

    local runTimer = gameState.runTimer or 0

    local layout = getTopBarLayout(w)
    local timeM = math.floor(runTimer / 60)
    local timeS = math.floor(runTimer % 60)
    local timeStr = string.format("%d:%02d", timeM, timeS)

    -- Time plaque in the top-left
    local timeCX = layout.timeX + layout.timeW / 2
    local timeCY = layout.timeY + layout.timeH / 2
    love.graphics.setColor(0, 0, 0, 0.24)
    drawHexPlate("fill", timeCX, timeCY + 3, layout.timeW / 2, layout.timeH / 2, math.floor(14 * HUD_SCALE))
    love.graphics.setColor(0.12, 0.08, 0.13, 0.94)
    drawHexPlate("fill", timeCX, timeCY, layout.timeW / 2, layout.timeH / 2, math.floor(14 * HUD_SCALE))
    love.graphics.setColor(0.86, 0.74, 0.44, 0.26)
    drawHexPlate("line", timeCX, timeCY, layout.timeW / 2, layout.timeH / 2, math.floor(14 * HUD_SCALE))
    love.graphics.setColor(0.86, 0.74, 0.44, 0.9)
    drawDiamond("fill", layout.timeX + 17, timeCY, 5, 5)
    love.graphics.setFont(hudFonts.tiny)
    drawTextWithShadow(timeStr, layout.timeX + 33, layout.timeY + 9)

    love.graphics.setColor(1, 1, 1, 1)
end

function drawQuitButton()
    local w = love.graphics.getWidth()
    local btnW, btnH = 90, 32
    local btnX = w - btnW - 20
    local btnY = 20
    love.graphics.setColor(0.15, 0.12, 0.15, 0.9)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 6, 6)
    love.graphics.setColor(0.5, 0.45, 0.5, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 6, 6)
    love.graphics.setFont(hudFonts.small)
    love.graphics.setColor(1, 1, 1, 0.9)
    local textW = hudFonts.small:getWidth("QUIT")
    drawTextWithShadow("QUIT", btnX + btnW/2 - textW/2, btnY + 6)
    love.graphics.setColor(1, 1, 1, 1)
end

function isPointInQuitButton(_px, _py)
    return false
end

-- Returns ability slot positions for tutorial highlight and other reuse
function getAbilitySlotLayout()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local diamondR, diamondSpacing = math.floor(24 * HUD_SCALE), math.floor(72 * HUD_SCALE)
    local slotConfig = {
        { key = "Q", abilityId = "multi_shot" },
        { key = "SPACE", abilityId = "dash" },
        { key = "E", abilityId = "entangle" },
        { key = "R", abilityId = "frenzy" },
    }
    local numSlots = #slotConfig
    local abilitiesWidth = (numSlots - 1) * diamondSpacing
    local abilitiesStartX = w / 2 - abilitiesWidth / 2
    local abilitiesCY = h - 92
    local slots = {}
    for i, slot in ipairs(slotConfig) do
        local cx = abilitiesStartX + (i - 1) * diamondSpacing
        slots[#slots + 1] = { key = slot.key, cx = cx, cy = abilitiesCY, r = diamondR }
    end
    return slots
end

function drawBottomHUD(player)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local t = love.timer.getTime()
    local state = gameState:getState()
    local States = gameState.States
    local xpSystem = nil

    if state == States.PLAYING and gameScene then
        xpSystem = gameScene.xpSystem
    elseif state == States.BOSS_FIGHT and bossArenaScene then
        xpSystem = bossArenaScene.xpSystem
    end

    -- Health bar with red crystal on left (Hades-style)
    local crystalSize = math.floor(24 * HUD_SCALE)
    local healthBarWidth = math.floor(320 * HUD_SCALE)
    local healthBarHeight = math.floor(16 * HUD_SCALE)
    local healthBarX = (w - (healthBarWidth + crystalSize + 20)) / 2 + crystalSize + 10
    local healthBarY = h - 42
    local healthPanelX = healthBarX - crystalSize - 14
    local healthPanelY = healthBarY - 10
    local healthPanelW = healthBarWidth + crystalSize + 28
    local healthPanelH = healthBarHeight + 20

    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", healthPanelX + 6, healthPanelY + 6, healthPanelW, healthPanelH, 12, 12)
    love.graphics.setColor(0.05, 0.06, 0.09, 0.84)
    love.graphics.rectangle("fill", healthPanelX, healthPanelY, healthPanelW, healthPanelH, 12, 12)
    love.graphics.setColor(0.52, 0.42, 0.28, 0.45)
    love.graphics.rectangle("line", healthPanelX, healthPanelY, healthPanelW, healthPanelH, 12, 12)

    -- Red crystal (procedural diamond) on left end
    local crystalCX = healthBarX - 12
    local crystalCY = healthBarY + healthBarHeight / 2
    love.graphics.setColor(0.5, 0.08, 0.08, 1)
    drawDiamond("fill", crystalCX, crystalCY, crystalSize / 2, crystalSize / 2)
    love.graphics.setColor(0.85, 0.2, 0.15, 0.9)
    drawDiamond("fill", crystalCX, crystalCY, crystalSize / 2 - 2, crystalSize / 2 - 2)
    love.graphics.setColor(0.6, 0.15, 0.12, 0.8)
    love.graphics.setLineWidth(1)
    drawDiamond("line", crystalCX, crystalCY, crystalSize / 2, crystalSize / 2)

    local healthPercent = math.max(0, player.health / player.maxHealth)

    -- Bar track (dark)
    love.graphics.setColor(0.12, 0.04, 0.04, 1)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 3, 3)

    -- Bar fill (deep red → bright red gradient feel)
    local fillW = (healthBarWidth - 2) * healthPercent
    if fillW > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.85, 0.18, 0.16, 0.14)
        love.graphics.rectangle("fill", healthBarX - 1, healthBarY - 1, fillW + 2, healthBarHeight + 2, 3, 3)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.7, 0.12, 0.12, 1)
        love.graphics.rectangle("fill", healthBarX + 1, healthBarY + 1, fillW, healthBarHeight - 2, 2, 2)
        -- Brighter top-half highlight
        love.graphics.setColor(0.9, 0.22, 0.18, 0.7)
        love.graphics.rectangle("fill", healthBarX + 1, healthBarY + 1, fillW, (healthBarHeight - 2) * 0.45, 2, 2)
        -- Critical: pulse orange glow when below 30%
        if healthPercent < 0.3 then
            local pulse = 0.3 + 0.25 * math.sin(t * 6)
            love.graphics.setColor(1, 0.4, 0.1, pulse)
            love.graphics.rectangle("fill", healthBarX + 1, healthBarY + 1, fillW, healthBarHeight - 2, 2, 2)
        end
    end

    -- Bar frame (metallic silver-gold)
    love.graphics.setColor(0.55, 0.48, 0.35, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 3, 3)
    love.graphics.setLineWidth(1)

    -- Health text
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.setFont(hudFonts.tiny)
    local healthText = math.floor(player.health) .. "/" .. player.maxHealth
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(healthText)
    drawTextWithShadow(healthText, healthBarX + healthBarWidth / 2 - textWidth / 2, healthBarY + 1)

    if xpSystem and xpSystem.getProgress then
        local xpProgress = math.max(0, math.min(1, xpSystem:getProgress() or 0))
        local xpBarH = 8
        local xpBarY = h - xpBarH - 16
        local xpBadgeR = 20
        local xpBarX = 30 + xpBadgeR * 2
        local xpBarW = w - xpBarX - 28

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", xpBarX, xpBarY + 2, xpBarW, xpBarH, 4, 4)
        love.graphics.setColor(0.05, 0.05, 0.08, 0.92)
        love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarW, xpBarH, 4, 4)

        local xpFillW = xpBarW * xpProgress
        if xpFillW > 0 then
            love.graphics.setColor(0.56, 0.42, 0.92, 1)
            love.graphics.rectangle("fill", xpBarX, xpBarY, xpFillW, xpBarH, 4, 4)
            love.graphics.setColor(0.82, 0.78, 1.0, 0.45)
            love.graphics.rectangle("fill", xpBarX, xpBarY, xpFillW, xpBarH * 0.45, 4, 4)
        end

        love.graphics.setColor(0.22, 0.2, 0.3, 0.95)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", xpBarX, xpBarY, xpBarW, xpBarH, 4, 4)

        local badgeCX = 28 + xpBadgeR
        local badgeCY = xpBarY + xpBarH / 2
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.circle("fill", badgeCX, badgeCY + 2, xpBadgeR)
        love.graphics.setColor(0.08, 0.08, 0.12, 0.96)
        love.graphics.circle("fill", badgeCX, badgeCY, xpBadgeR)
        love.graphics.setColor(0.74, 0.68, 0.98, 0.95)
        love.graphics.circle("line", badgeCX, badgeCY, xpBadgeR)
        love.graphics.setFont(hudFonts.small)
        local lvlText = tostring(xpSystem.level or 1)
        local lvlW = love.graphics.getFont():getWidth(lvlText)
        drawTextWithShadow(lvlText, badgeCX - lvlW / 2, badgeCY - 14)
    end

    local function resolveAbility(playerObj, abilityId)
        if not playerObj or not playerObj.abilities then return nil end
        if playerObj.abilities[abilityId] then
            return playerObj.abilities[abilityId]
        end
        if abilityId == "entangle" then
            return playerObj.abilities.arrow_volley
        end
        return nil
    end

    -- Four ability slots: Q, SPACE, E, R
    local slotConfig = {
        { key = "Q", abilityId = "multi_shot" },
        { key = "SPACE", abilityId = "dash" },
        { key = "E", abilityId = "entangle" },
        { key = "R", abilityId = "frenzy" },
    }
    local diamondR = math.floor(24 * HUD_SCALE)
    local diamondSpacing = math.floor(72 * HUD_SCALE)
    local numSlots = #slotConfig
    local abilitiesWidth = (numSlots - 1) * diamondSpacing
    local abilitiesStartX = w / 2 - abilitiesWidth / 2
    local abilitiesCY = h - 92
    local abilityPanelX = abilitiesStartX - 34
    local abilityPanelY = abilitiesCY - 34
    local abilityPanelW = abilitiesWidth + 68
    local abilityPanelH = 68

    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", abilityPanelX + 6, abilityPanelY + 6, abilityPanelW, abilityPanelH, 16, 16)
    love.graphics.setColor(0.05, 0.06, 0.09, 0.78)
    love.graphics.rectangle("fill", abilityPanelX, abilityPanelY, abilityPanelW, abilityPanelH, 16, 16)
    love.graphics.setColor(0.42, 0.55, 0.68, 0.16)
    love.graphics.rectangle("line", abilityPanelX, abilityPanelY, abilityPanelW, abilityPanelH, 16, 16)

    for i, slot in ipairs(slotConfig) do
        local ability = slot.abilityId and resolveAbility(player, slot.abilityId) or nil
        local cx = abilitiesStartX + (i - 1) * diamondSpacing
        drawAbilityDiamond(ability, slot.key, cx, abilitiesCY, diamondR)
    end

    -- Ability tooltip on hover
    local mx, my = love.mouse.getPosition()
    for i, slot in ipairs(slotConfig) do
        local ability = slot.abilityId and resolveAbility(player, slot.abilityId) or nil
        if ability and ability.description then
            local cx = abilitiesStartX + (i - 1) * diamondSpacing
            local dx = mx - cx
            local dy = my - abilitiesCY
            if math.abs(dx) + math.abs(dy) < diamondR + 4 then
                drawAbilityTooltip(ability, cx, abilitiesCY - diamondR - 8)
                break
            end
        end
    end
end

function drawAbilityTooltip(ability, anchorX, anchorY)
    local tipFont = hudFonts.uiTiny or love.graphics.getFont()
    local nameFont = hudFonts.uiSmall or tipFont
    love.graphics.setFont(tipFont)

    local maxW = 200
    local padding = 8
    local lines = {}
    local currentLine = ""
    for word in ability.description:gmatch("%S+") do
        local test = currentLine == "" and word or (currentLine .. " " .. word)
        if tipFont:getWidth(test) <= maxW then
            currentLine = test
        else
            if currentLine ~= "" then lines[#lines + 1] = currentLine end
            currentLine = word
        end
    end
    if currentLine ~= "" then lines[#lines + 1] = currentLine end

    local lineH = tipFont:getHeight() + 2
    local nameH = nameFont:getHeight() + 4
    local castH = 0
    if ability.castType then castH = lineH end
    local tipH = nameH + #lines * lineH + castH + padding * 2
    local tipW = maxW + padding * 2
    local tipX = anchorX - tipW / 2
    local tipY = anchorY - tipH

    -- Clamp to screen
    tipX = math.max(4, math.min(love.graphics.getWidth() - tipW - 4, tipX))

    -- Background
    love.graphics.setColor(0.01, 0.01, 0.03, 0.18)
    love.graphics.rectangle("fill", tipX + 6, tipY + 6, tipW, tipH, 6, 6)
    love.graphics.setColor(0.06, 0.06, 0.1, 0.94)
    love.graphics.rectangle("fill", tipX, tipY, tipW, tipH, 6, 6)
    love.graphics.setColor(0.18, 0.18, 0.24, 0.28)
    love.graphics.rectangle("fill", tipX + 2, tipY + 2, tipW - 4, 12, 5, 5)
    love.graphics.setColor(0.55, 0.48, 0.36, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", tipX, tipY, tipW, tipH, 6, 6)

    -- Name
    love.graphics.setFont(nameFont)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    local nameW = nameFont:getWidth(ability.name)
    love.graphics.print(ability.name, tipX + tipW / 2 - nameW / 2, tipY + padding)

    -- Cast type label
    local yOff = tipY + padding + nameH
    if ability.castType then
        love.graphics.setFont(tipFont)
        local castLabel = ability.castType == "auto" and "AUTO-CAST" or "MANUAL"
        local castColor = ability.castType == "auto" and {0.4, 0.8, 0.5} or {1, 0.7, 0.3}
        love.graphics.setColor(castColor[1], castColor[2], castColor[3], 0.9)
        local cw = tipFont:getWidth(castLabel)
        love.graphics.print(castLabel, tipX + tipW / 2 - cw / 2, yOff)
        yOff = yOff + lineH
    end

    -- Description lines
    love.graphics.setFont(tipFont)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    for _, line in ipairs(lines) do
        love.graphics.print(line, tipX + padding, yOff)
        yOff = yOff + lineH
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Ability color accents per key
local abilityAccents = {
    Q = {0.3, 0.75, 1.0},
    SPACE = {0.9, 0.85, 0.4},
    E = {0.85, 0.3, 0.3},
    R = {1.0, 0.55, 0.15},
}

local function drawAbilityGlyph(ability, key, cx, cy, accent)
    local id = ability and ability.name and ability.name:lower() or key:lower()
    love.graphics.setColor(0.95, 0.97, 1.0, 0.92)
    if id:find("multi") or key == "Q" then
        love.graphics.setLineWidth(2)
        love.graphics.line(cx - 11, cy + 8, cx + 8, cy - 7)
        love.graphics.line(cx - 6, cy + 11, cx + 11, cy - 4)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("fill", cx + 7, cy - 10, cx + 13, cy - 6, cx + 8, cy - 2)
    elseif id:find("dash") or key == "SPACE" then
        love.graphics.setLineWidth(3)
        love.graphics.line(cx - 10, cy + 8, cx + 10, cy - 8)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("fill", cx + 3, cy - 13, cx + 14, cy - 8, cx + 6, cy)
    elseif id:find("entangle") or key == "E" then
        love.graphics.circle("line", cx, cy, 10)
        love.graphics.circle("line", cx, cy, 5)
        love.graphics.line(cx - 12, cy, cx + 12, cy)
        love.graphics.line(cx, cy - 12, cx, cy + 12)
    else
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.25)
        love.graphics.circle("fill", cx, cy, 13)
        love.graphics.setColor(0.97, 0.95, 0.88, 0.95)
        love.graphics.polygon("fill", cx, cy - 12, cx + 5, cy - 2, cx + 12, cy - 1, cx + 6, cy + 5, cx + 8, cy + 12, cx, cy + 7, cx - 8, cy + 12, cx - 6, cy + 5, cx - 12, cy - 1, cx - 5, cy - 2)
    end
end

function drawAbilityDiamond(ability, key, cx, cy, r)
    local isPlaceholder = (ability == nil)
    local hasCharge = not isPlaceholder and ability and (ability.chargeMax ~= nil)
    local isReady = false
    local cooldownPercent = 0
    local t = love.timer.getTime()

    if isPlaceholder then
        isReady = false
    elseif hasCharge then
        local c, m = ability.charge or 0, ability.chargeMax or 1
        isReady = c >= m
        cooldownPercent = 1 - (c / m)
    else
        isReady = ability and ability.currentCooldown <= 0
        cooldownPercent = (ability and ability.cooldown > 0) and (ability.currentCooldown / ability.cooldown) or 0
    end

    local accent = abilityAccents[key] or {0.5, 0.7, 1.0}

    -- Outer glow when ready (pulsing)
    if isReady then
        local pulse = 0.24 + 0.16 * math.sin(t * 3)
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(accent[1], accent[2], accent[3], pulse)
        drawDiamond("fill", cx, cy, r + 8, r + 8)
        love.graphics.setBlendMode("alpha")
    end

    -- Backplate
    love.graphics.setColor(0.07, 0.08, 0.11, 0.72)
    love.graphics.rectangle("fill", cx - 24, cy - 24, 48, 48, 12, 12)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.08)
    love.graphics.rectangle("line", cx - 24, cy - 24, 48, 48, 12, 12)

    -- Diamond background
    if isReady then
        love.graphics.setColor(0.11, 0.13, 0.20, 0.96)
    else
        love.graphics.setColor(0.05, 0.05, 0.08, 0.96)
    end
    drawDiamond("fill", cx, cy, r, r)
    love.graphics.setColor(1, 1, 1, 0.04)
    drawDiamond("fill", cx, cy - 3, r - 4, r - 10)

    -- Cooldown fill (dark overlay sweeping from bottom)
    if not isPlaceholder and not isReady then
        local fillH = r * 2 * cooldownPercent
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.stencil(function()
            drawDiamond("fill", cx, cy, r - 1, r - 1)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.rectangle("fill", cx - r, cy - r, r * 2, fillH)
        love.graphics.setStencilTest()
    end

    drawAbilityGlyph(ability, key, cx, cy - 6, accent)

    -- Diamond border
    if isReady then
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.9)
    else
        love.graphics.setColor(0.25, 0.22, 0.2, 0.7)
    end
    love.graphics.setLineWidth(2)
    drawDiamond("line", cx, cy, r, r)
    love.graphics.setLineWidth(1)

    -- Keybind label below diamond
    love.graphics.setColor(0.85, 0.78, 0.6, (isReady or isPlaceholder) and 0.9 or 0.45)
    love.graphics.setFont(hudFonts.tiny)
    local font = love.graphics.getFont()
    local keyW = font:getWidth(key)
    drawTextWithShadow(key, cx - keyW / 2, cy + r + 4)

    -- Cooldown / charge text inside diamond
    if hasCharge then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(1, 0.9, 0.5, 0.18)
        love.graphics.circle("fill", cx, cy, r - 4)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 0.9, 0.5, 1)
        love.graphics.setFont(hudFonts.tiny)
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        local txt = string.format("%d%%", math.floor((c / m) * 100))
        font = love.graphics.getFont()
        local tw = font:getWidth(txt)
        drawTextWithShadow(txt, cx - tw / 2, cy + 10)
    elseif not isPlaceholder and not isReady then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(hudFonts.small)
        local cdText = string.format("%.1f", ability.currentCooldown)
        local font = love.graphics.getFont()
        local cdW = font:getWidth(cdText)
        drawTextWithShadow(cdText, cx - cdW / 2, cy + 8)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function love.keypressed(key)
    -- Debug: PixelGen export (F9, gated by DEBUG_PIXELGEN)
    if key == "f9" and _G.DEBUG_PIXELGEN then
        local ok, err = pcall(function()
            local pixelgen = require("systems.pixelgen")
            local ok2, path = pixelgen:generateAndExport()
            if ok2 then
                print("[PixelGen] Exported to " .. tostring(path))
            else
                print("[PixelGen] Error: " .. tostring(path))
            end
        end)
        if not ok then
            print("[PixelGen] " .. tostring(err))
        end
        return
    end

    -- Global mute toggle
    if key == "m" and audio then
        audio:toggleMute()
        return
    end

    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        if gameScene and gameScene.keypressed then
            local handled = gameScene:keypressed(key)
            if handled then return end
        end
        if key == "escape" then
            gameState:transitionTo(States.MENU)
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene and bossArenaScene.keypressed then
            bossArenaScene:keypressed(key)
        end
    elseif state == States.TUTORIAL then
        if tutorialScene and tutorialScene.keypressed then
            tutorialScene:keypressed(key)
        end
        if key == "escape" then
            gameState:reset()
        end
    else
        menu:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        if gameScene and gameScene.pauseMenuVisible then
            gameScene:mousepressed(x, y, button)
            return
        elseif gameScene then
            gameScene:mousepressed(x, y, button)
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene and bossArenaScene.mousepressed then
            bossArenaScene:mousepressed(x, y, button)
        end
    elseif state == States.TUTORIAL then
        if tutorialScene and tutorialScene.mousepressed then
            tutorialScene:mousepressed(x, y, button)
        end
    else
        menu:mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y)
    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        if gameScene then
            gameScene:mousemoved(x, y)
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene and bossArenaScene.mousemoved then
            bossArenaScene:mousemoved(x, y)
        end
    else
        menu:mousemoved(x, y)
    end
end
