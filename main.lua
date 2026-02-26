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
local FONT_PATH = "assets/Other/Fonts/Kenney Future Narrow.ttf"
local FONT_PATH_BOLD = "assets/Other/Fonts/Kenney Future.ttf"

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

    hudFonts.tiny   = loadFont(FONT_PATH, 12)
    hudFonts.small  = loadFont(FONT_PATH, 15)
    hudFonts.body   = loadFont(FONT_PATH, 18)
    hudFonts.header = loadFont(FONT_PATH_BOLD, 28)
    hudFonts.title  = loadFont(FONT_PATH_BOLD, 42)
    hudFonts.dmgNormal = loadFont(FONT_PATH, 14)
    hudFonts.dmgCrit   = loadFont(FONT_PATH_BOLD, 20)
    hudFonts.uiTiny      = loadFont(FONT_PATH, 11)
    hudFonts.uiSmall     = loadFont(FONT_PATH, 14)
    hudFonts.uiBody      = loadFont(FONT_PATH, 17)
    hudFonts.uiSmallText = loadFont(FONT_PATH, 10)
    hudFonts.uiLarge     = loadFont(FONT_PATH_BOLD, 34)

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
        screenFlash.color = color or {1, 1, 1, 0.4}
        screenFlash.duration = duration or 0.1
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
            -- Boss Test Mode: immediately jump to boss fight after scene loads
            if gameState.bossTestMode then
                gameState.bossTestMode = false
                gameState:enterBossFight()
            end
        end
        gameScene:update(dt)

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
        
        -- Draw transition overlay
        if gameState.transitionAlpha > 0 then
            love.graphics.setColor(0, 0, 0, gameState.transitionAlpha)
            love.graphics.rectangle("fill", 0, 0, winW, winH)
            love.graphics.setColor(1, 1, 1, 1)
        end
        return
    end

    -- ── Gameplay states render directly at native resolution ──
    love.graphics.clear(0.05, 0.05, 0.08, 1)

    if state == States.PLAYING then
        if gameScene then
            gameScene:draw()
            drawHUD()
            if not gameScene.pauseMenuVisible then
                drawQuitButton()
            end
            if gameScene.drawOverlays then
                gameScene:drawOverlays()
            end
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene then
            bossArenaScene:draw()
            drawQuitButton()
        end
    elseif state == States.TUTORIAL then
        if tutorialScene then
            tutorialScene:draw()
        end
    end

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
end

-- Helper: draw text with subtle shadow for readability
local function drawTextWithShadow(text, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, x, y)
end

function drawHUD()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- Draw bottom HUD (health bar + abilities)
    if gameScene and gameScene.player then
        drawBottomHUD(gameScene.player)
    end
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

function isPointInQuitButton(px, py)
    local w = love.graphics.getWidth()
    local btnW, btnH = 90, 32
    local btnX = w - btnW - 20
    local btnY = 20
    return px >= btnX and px <= btnX + btnW and py >= btnY and py <= btnY + btnH
end

-- Helper: draw a diamond (rotated square) polygon
local function drawDiamond(mode, cx, cy, halfW, halfH)
    love.graphics.polygon(mode, cx, cy - halfH, cx + halfW, cy, cx, cy + halfH, cx - halfW, cy)
end

function drawBottomHUD(player)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local t = love.timer.getTime()

    -- Sleek dark panel
    local panelW = 560
    local panelH = 110
    local panelX = (w - panelW) / 2
    local panelY = h - panelH - 8

    -- Panel background gradient (dark, semi-transparent)
    love.graphics.setColor(0.04, 0.04, 0.08, 0.85)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)
    -- Panel top accent line (warm gold, Hades-style)
    love.graphics.setColor(0.75, 0.55, 0.25, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.line(panelX + 20, panelY, panelX + panelW - 20, panelY)
    -- Panel border
    love.graphics.setColor(0.35, 0.28, 0.18, 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 10, 10)
    love.graphics.setLineWidth(1)

    -- Health bar (Hades/CotDG style: red fill, metallic frame)
    local healthBarWidth = panelW - 60
    local healthBarHeight = 18
    local healthBarX = panelX + 30
    local healthBarY = panelY + 14

    local healthPercent = math.max(0, player.health / player.maxHealth)

    -- Bar track (dark)
    love.graphics.setColor(0.12, 0.04, 0.04, 1)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 3, 3)

    -- Bar fill (deep red → bright red gradient feel)
    local fillW = (healthBarWidth - 2) * healthPercent
    if fillW > 0 then
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

    -- Ability diamonds (Hades-inspired rotated squares)
    local diamondR = 28
    local diamondSpacing = 76
    local numAbilities = #player.abilityOrder
    local abilitiesWidth = (numAbilities - 1) * diamondSpacing
    local abilitiesStartX = w / 2 - abilitiesWidth / 2
    local abilitiesCY = healthBarY + healthBarHeight + 10 + diamondR + 2

    for i, abilityId in ipairs(player.abilityOrder) do
        local ability = player.abilities[abilityId]
        if ability then
            local cx = abilitiesStartX + (i - 1) * diamondSpacing
            drawAbilityDiamond(ability, cx, abilitiesCY, diamondR)
        end
    end

    -- Ability tooltip on hover
    local mx, my = love.mouse.getPosition()
    for i, abilityId in ipairs(player.abilityOrder) do
        local ability = player.abilities[abilityId]
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
    love.graphics.setColor(0.06, 0.06, 0.1, 0.94)
    love.graphics.rectangle("fill", tipX, tipY, tipW, tipH, 6, 6)
    love.graphics.setColor(0.45, 0.4, 0.3, 0.6)
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

-- Ability color accents per key (matching element vibes)
local abilityAccents = {
    Q = {0.3, 0.75, 1.0},
    SPACE = {0.9, 0.85, 0.4},
    E = {0.85, 0.3, 0.3},
    R = {1.0, 0.55, 0.15},
}

function drawAbilityDiamond(ability, cx, cy, r)
    local hasCharge = (ability.chargeMax ~= nil)
    local isReady = ability.currentCooldown <= 0
    local cooldownPercent = 0
    local t = love.timer.getTime()

    if hasCharge then
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        isReady = c >= m
        cooldownPercent = 1 - (c / m)
    else
        cooldownPercent = ability.cooldown > 0 and (ability.currentCooldown / ability.cooldown) or 0
    end

    local accent = abilityAccents[ability.key] or {0.5, 0.7, 1.0}

    -- Outer glow when ready (pulsing)
    if isReady then
        local pulse = 0.25 + 0.15 * math.sin(t * 3)
        love.graphics.setColor(accent[1], accent[2], accent[3], pulse)
        drawDiamond("fill", cx, cy, r + 6, r + 6)
    end

    -- Diamond background
    if isReady then
        love.graphics.setColor(0.1, 0.12, 0.18, 0.95)
    else
        love.graphics.setColor(0.06, 0.06, 0.09, 0.95)
    end
    drawDiamond("fill", cx, cy, r, r)

    -- Cooldown fill (dark overlay sweeping from bottom)
    if not isReady then
        local fillH = r * 2 * cooldownPercent
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.stencil(function()
            drawDiamond("fill", cx, cy, r - 1, r - 1)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.rectangle("fill", cx - r, cy - r, r * 2, fillH)
        love.graphics.setStencilTest()
    end

    -- Ability icon symbol
    love.graphics.setColor(1, 1, 1, isReady and 1 or 0.35)
    love.graphics.setFont(hudFonts.body)
    local font = love.graphics.getFont()
    local iconW = font:getWidth(ability.icon)
    local iconH = font:getHeight()
    drawTextWithShadow(ability.icon, cx - iconW / 2, cy - iconH / 2 - 3)

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
    love.graphics.setColor(0.85, 0.78, 0.6, isReady and 0.9 or 0.45)
    love.graphics.setFont(hudFonts.tiny)
    font = love.graphics.getFont()
    local keyW = font:getWidth(ability.key)
    drawTextWithShadow(ability.key, cx - keyW / 2, cy + r + 4)

    -- Cooldown / charge text inside diamond
    if hasCharge then
        love.graphics.setColor(1, 0.9, 0.5, 1)
        love.graphics.setFont(hudFonts.tiny)
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        local txt = string.format("%d%%", math.floor((c / m) * 100))
        font = love.graphics.getFont()
        local tw = font:getWidth(txt)
        drawTextWithShadow(txt, cx - tw / 2, cy + 4)
    elseif not isReady then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(hudFonts.small)
        local cdText = string.format("%.1f", ability.currentCooldown)
        font = love.graphics.getFont()
        local cdW = font:getWidth(cdText)
        drawTextWithShadow(cdText, cx - cdW / 2, cy - font:getHeight() / 2 + 2)
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
        elseif isPointInQuitButton(x, y) then
            gameState:transitionTo(States.MENU)
        elseif gameScene then
            gameScene:mousepressed(x, y, button)
        end
    elseif state == States.BOSS_FIGHT then
        if isPointInQuitButton(x, y) then
            gameState:transitionTo(States.MENU)
        elseif bossArenaScene and bossArenaScene.mousepressed then
            bossArenaScene:mousepressed(x, y, button)
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
