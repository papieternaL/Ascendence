-- LOVE2D Action RPG - ASCENDENCE
-- Main Entry Point

local GameState = require("systems.game_state")
local Menu = require("ui.menu")
local GameScene = require("scenes.game_scene")
local Audio = require("systems.audio")

-- Pixel-art rendering constants
local INTERNAL_W = 320
local INTERNAL_H = 180
local gameCanvas

-- Pre-loaded Kenney Pixel fonts (shared globally via _G)
local FONT_PATH = "assets/Other/Fonts/Kenney Pixel.ttf"

-- Screen flash system (game_scene can trigger via _G.triggerScreenFlash)
local screenFlash = { timer = 0, duration = 0, color = {1, 1, 1, 0} }

-- Global game objects
local gameState
local menu
local gameScene
local audio

-- Pre-loaded fonts for HUD (avoid creating every frame)
local hudFonts = {}

function love.load()
    -- Set up window
    love.window.setTitle("ASCENDENCE")

    -- Nearest-neighbor filtering for crisp pixel art
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create low-res canvas for pixel-art rendering
    gameCanvas = love.graphics.newCanvas(INTERNAL_W, INTERNAL_H)
    gameCanvas:setFilter("nearest", "nearest")

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

    hudFonts.tiny   = loadPixelFont(8)
    hudFonts.small  = loadPixelFont(10)
    hudFonts.body   = loadPixelFont(14)
    hudFonts.header = loadPixelFont(20)
    hudFonts.title  = loadPixelFont(36)
    hudFonts.dmgNormal = loadPixelFont(12)
    hudFonts.dmgCrit   = loadPixelFont(16)

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
    audio:playMenuMusic()

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

    -- Update audio system (handles fading)
    if audio then audio:update(dt) end

    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        -- Initialize game scene if needed
        if not gameScene then
            gameScene = GameScene:new(gameState)
            gameScene:load()
            -- Switch to gameplay music
            if audio then audio:playGameplayMusic() end
        end
        gameScene:update(dt)

        -- Check for game over
        if gameScene.player and gameScene.player.health <= 0 then
            gameState:transitionTo(States.GAME_OVER)
            if audio then audio:playGameOverMusic() end
        end
    elseif state == States.MENU or state == States.CHARACTER_SELECT or
           state == States.BIOME_SELECT or state == States.DIFFICULTY_SELECT then
        menu:update(dt)
        -- Reset game scene when in menu
        if gameScene then
            gameScene = nil
            -- Return to menu music
            if audio then audio:playMenuMusic() end
        end
    elseif state == States.GAME_OVER or state == States.VICTORY then
        menu:update(dt)
    end
end

function love.draw()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()

    -- ── Render everything to low-res canvas ──
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0.05, 0.05, 0.08, 1)

    love.graphics.push()
    local scaleX = INTERNAL_W / winW
    local scaleY = INTERNAL_H / winH
    love.graphics.scale(scaleX, scaleY)

    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        if gameScene then
            gameScene:draw()

            -- Draw HUD
            drawHUD()

            -- Draw overlays on top of HUD (e.g., run stats page)
            if gameScene.drawOverlays then
                gameScene:drawOverlays()
            end
        end
    elseif state == States.GAME_OVER or state == States.VICTORY then
        -- Draw game in background
        if gameScene then
            gameScene:draw()
        end
        menu:draw()
    else
        -- Menu states
        menu:draw()
    end

    -- Screen flash inside canvas (gets pixelated too)
    if screenFlash.timer > 0 then
        local a = (screenFlash.color[4] or 0.4) * (screenFlash.timer / screenFlash.duration)
        love.graphics.setColor(screenFlash.color[1], screenFlash.color[2], screenFlash.color[3], a)
        love.graphics.rectangle("fill", 0, 0, winW, winH)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.pop()
    love.graphics.setCanvas()

    -- ── Scale canvas to fill window (nearest-neighbor = crisp pixels) ──
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas, 0, 0, 0, winW / INTERNAL_W, winH / INTERNAL_H)
end

function drawHUD()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- Draw bottom HUD (health bar + abilities)
    if gameScene and gameScene.player then
        drawBottomHUD(gameScene.player)
    end
end

function drawBottomHUD(player)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- U-shaped HUD background
    local hudWidth = 400
    local hudHeight = 90
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
    local healthBarHeight = 16
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
    love.graphics.print(healthText, healthBarX + healthBarWidth/2 - textWidth/2, healthBarY + 1)

    -- Draw abilities in a row below health bar
    local abilitySize = 44
    local abilitySpacing = 12
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
    love.graphics.print(ability.icon, x + size/2 - iconWidth/2, y + 6)

    -- Keybind
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(hudFonts.tiny)
    font = love.graphics.getFont()
    local keyWidth = font:getWidth(ability.key)
    love.graphics.print(ability.key, x + size/2 - keyWidth/2, y + size - 14)

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
        love.graphics.print(txt, x + size/2 - tw/2, y + size/2 - 6)
    elseif not isReady then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(hudFonts.body)
        local cdText = string.format("%.1f", ability.currentCooldown)
        font = love.graphics.getFont()
        local cdWidth = font:getWidth(cdText)
        love.graphics.print(cdText, x + size/2 - cdWidth/2, y + size/2 - 7)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function love.keypressed(key)
    -- Global mute toggle
    if key == "m" and audio then
        audio:toggleMute()
        return
    end

    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        -- Let the scene handle overlay/upgrade inputs first
        if gameScene and gameScene.keypressed then
            local handled = gameScene:keypressed(key)
            if handled then return end
        end

        if key == "escape" then
            gameState:transitionTo(States.MENU)
        end
    else
        menu:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    local state = gameState:getState()
    local States = gameState.States

    if state == States.PLAYING then
        if gameScene then
            gameScene:mousepressed(x, y, button)
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
    else
        menu:mousemoved(x, y)
    end
end
