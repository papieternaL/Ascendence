-- LOVE2D Action RPG - ASCENDENCE
-- Main Entry Point

local GameState = require("systems.game_state")
local Menu = require("ui.menu")
local GameScene = require("scenes.game_scene")
local BossArenaScene = require("scenes.boss_arena_scene")
local Audio = require("systems.audio")
local Settings = require("systems.settings")
local JuiceManager = require("systems.juice_manager")

-- Pixel-art rendering constants (reserved for future use with pixel sprite sheets)
-- local INTERNAL_W = 320
-- local INTERNAL_H = 180
-- local gameCanvas

-- Pre-loaded Kenney Pixel fonts (shared globally via _G)
local FONT_PATH = "assets/Other/Fonts/Kenney Pixel.ttf"

-- Screen flash system (game_scene can trigger via _G.triggerScreenFlash)
local screenFlash = { timer = 0, duration = 0, color = {1, 1, 1, 0} }

-- Global game objects
local gameState
local menu
local gameScene
local bossArenaScene
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

    -- Load Kenney Pixel fonts at various sizes
    local ok, f
    local function loadPixelFont(size)
        ok, f = pcall(love.graphics.newFont, FONT_PATH, size)
        if ok then
            f:setFilter("nearest", "nearest")
            return f
        end
        f = love.graphics.newFont(size)
        f:setFilter("nearest", "nearest")
        return f
    end
    -- UI fonts: linear filter for ~10% less pixelation on long descriptions
    local function loadUIFont(size)
        ok, f = pcall(love.graphics.newFont, FONT_PATH, size)
        if ok then
            f:setFilter("linear", "linear")
            return f
        end
        f = love.graphics.newFont(size)
        f:setFilter("linear", "linear")
        return f
    end

    hudFonts.tiny   = loadPixelFont(18)
    hudFonts.small  = loadPixelFont(22)
    hudFonts.body   = loadPixelFont(30)
    hudFonts.header = loadPixelFont(44)
    hudFonts.title  = loadPixelFont(64)
    hudFonts.dmgNormal = loadPixelFont(24)
    hudFonts.dmgCrit   = loadPixelFont(32)
    -- UI-specific fonts (linear filter for readability)
    hudFonts.uiTiny      = loadUIFont(20)
    hudFonts.uiSmall     = loadUIFont(24)
    hudFonts.uiBody      = loadUIFont(33)
    hudFonts.uiSmallText = loadUIFont(14)
    hudFonts.uiLarge     = loadUIFont(54)

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
    elseif state == States.MENU or state == States.SETTINGS or
           state == States.CHARACTER_SELECT or state == States.BIOME_SELECT then
        menu:update(dt)
        -- Reset game scene when in menu
        if gameScene then
            gameScene = nil
        end
        bossArenaScene = nil
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

function drawBottomHUD(player)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- U-shaped HUD background
    local hudWidth = 600
    local hudHeight = 130
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

    -- Health bar (at the top of the U)
    local healthBarWidth = hudWidth - 80
    local healthBarHeight = 24
    local healthBarX = hudX + 40
    local healthBarY = hudY + 25

    -- Health bar background
    love.graphics.setColor(0.2, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 4, 4)

    -- Health bar fill
    local healthPercent = player.health / player.maxHealth
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

    -- Health text (using pre-loaded font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(hudFonts.small)
    local healthText = math.floor(player.health) .. "/" .. player.maxHealth
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(healthText)
    drawTextWithShadow(healthText, healthBarX + healthBarWidth/2 - textWidth/2, healthBarY + 1)

    -- Draw abilities in a row below health bar
    local abilitySize = 64
    local abilitySpacing = 16
    local numAbilities = #player.abilityOrder
    local abilitiesWidth = numAbilities * abilitySize + (numAbilities - 1) * abilitySpacing
    local abilitiesX = (w - abilitiesWidth) / 2
    local abilitiesY = healthBarY + healthBarHeight + 10

    for i, abilityId in ipairs(player.abilityOrder) do
        local ability = player.abilities[abilityId]
        if ability then
            local x = abilitiesX + (i - 1) * (abilitySize + abilitySpacing)
            drawAbilityIcon(ability, x, abilitiesY, abilitySize)
        end
    end
end

function drawAbilityIcon(ability, x, y, size)
    local hasCharge = (ability.chargeMax ~= nil)
    local isReady = ability.currentCooldown <= 0
    local cooldownPercent = 0
    if hasCharge then
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        isReady = c >= m
        cooldownPercent = 1 - (c / m)
    else
        cooldownPercent = ability.cooldown > 0 and (ability.currentCooldown / ability.cooldown) or 0
    end

    -- Ability background
    if isReady then
        love.graphics.setColor(0.2, 0.25, 0.35, 1)
    else
        love.graphics.setColor(0.1, 0.1, 0.15, 1)
    end
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)

    -- Cooldown overlay (sweeping clock effect)
    if not isReady then
        love.graphics.setColor(0, 0, 0, 0.6)
        local segments = 32
        local angleStart = -math.pi / 2
        local angleEnd = angleStart + (2 * math.pi * cooldownPercent)
        local centerX = x + size / 2
        local centerY = y + size / 2
        local radius = size / 2 - 2
        local vertices = {centerX, centerY}
        for i = 0, segments do
            local angle = angleStart + (angleEnd - angleStart) * (i / segments)
            table.insert(vertices, centerX + math.cos(angle) * radius)
            table.insert(vertices, centerY + math.sin(angle) * radius)
        end
        if #vertices >= 6 then
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Ability icon (text symbol)
    love.graphics.setColor(1, 1, 1, isReady and 1 or 0.4)
    love.graphics.setFont(hudFonts.header)
    local font = love.graphics.getFont()
    local iconWidth = font:getWidth(ability.icon)
    drawTextWithShadow(ability.icon, x + size/2 - iconWidth/2, y + 6)

    -- Keybind
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(hudFonts.tiny)
    font = love.graphics.getFont()
    local keyWidth = font:getWidth(ability.key)
    drawTextWithShadow(ability.key, x + size/2 - keyWidth/2, y + size - 14)

    -- Border
    if isReady then
        love.graphics.setColor(0.5, 0.7, 1, 1)
    else
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, 6, 6)
    love.graphics.setLineWidth(1)

    -- Cooldown timer text
    if hasCharge then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(hudFonts.small)
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        local txt = string.format("%d%%", math.floor((c / m) * 100))
        font = love.graphics.getFont()
        local tw = font:getWidth(txt)
        drawTextWithShadow(txt, x + size/2 - tw/2, y + size/2 - 6)
    elseif not isReady then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(hudFonts.body)
        local cdText = string.format("%.1f", ability.currentCooldown)
        font = love.graphics.getFont()
        local cdWidth = font:getWidth(cdText)
        drawTextWithShadow(cdText, x + size/2 - cdWidth/2, y + size/2 - 7)
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
