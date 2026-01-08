-- LÖVE2D Action RPG - ASCENDENCE
-- Main Entry Point

local GameState = require("systems.game_state")
local Menu = require("ui.menu")
local GameScene = require("scenes.game_scene")
local Config = require("data.config")
local UIUtils = require("ui.ui_utils")
local JuiceManager = require("systems.juice_manager")
local RetroRenderer = require("systems.retro_renderer")
-- BossArenaScene loaded as global to allow hot-reload
BossArenaScene = require("scenes.boss_arena_scene")

-- Global game objects
local gameState
local menu
local gameScene
local bossArenaScene
local retroRenderer

-- Hot-reload function for development
function reloadBossModules()
    print("!!! RELOAD BOSS MODULES CALLED !!!")
    
    -- Clear cached modules by pattern to be safe
    for k, v in pairs(package.loaded) do
        if k:match("boss_arena_scene") or k:match("treent_overlord") or k:match("root") or k:match("bark_projectile") then
            package.loaded[k] = nil
            print("Cleared cache for: " .. k)
        end
    end

    -- Reload the modules (re-require)
    BossArenaScene = require("scenes.boss_arena_scene")
    
    -- If boss arena is active, recreate it
    if gameState and gameState:getState() == gameState.States.BOSS_FIGHT then
        bossArenaScene = nil  -- Force recreation on next update
        print("Boss modules reloaded! Boss arena will be recreated on next frame...")
    else
        print("Boss modules reloaded!")
    end
end

function love.load()
    -- Set up window
    love.window.setTitle("ASCENDENCE")
    
    -- Enable smooth graphics
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Initialize retro renderer
    retroRenderer = RetroRenderer:new()
    retroRenderer:initialize()
    
    -- Initialize game state
    gameState = GameState:new()
    
    -- Initialize menu
    menu = Menu:new(gameState)
    
    -- Game scenes will be initialized when game starts
    gameScene = nil
    bossArenaScene = nil
end

function love.update(dt)
    -- Cap delta time to prevent physics issues
    dt = math.min(dt, 1/30)
    
    -- Update JuiceManager (freeze timer, flash timers)
    JuiceManager.update(dt)
    
    -- Update game state transitions
    gameState:update(dt)
    
    local state = gameState:getState()
    local States = gameState.States
    
    if state == States.PLAYING then
        -- Initialize game scene if needed
        if not gameScene then
            gameScene = GameScene:new(gameState)
            gameScene:load()
        end
        gameScene:update(dt)
        
        -- Check for game over
        if gameScene.player and gameScene.player.health <= 0 then
            gameState:transitionTo(States.GAME_OVER)
        end
    elseif state == States.BOSS_FIGHT then
        -- Initialize boss arena if needed
        if not bossArenaScene then
            if gameState.bossTestMode and not gameScene then
                -- BOSS TEST MODE: Create temporary game scene with boosted player
                print("Creating BOSS TEST MODE game scene")
                gameScene = GameScene:new(gameState)
                gameScene:load()
                
                -- Boost player stats for testing
                if gameScene.player and gameScene.playerStats then
                    gameScene.player.health = 150
                    gameScene.player.maxHealth = 150
                    gameScene.player.attackDamage = 25
                    gameScene.player.speed = 250
                    
                    -- Apply some upgrades
                    gameScene.playerStats.base.crit_chance = 0.25
                    gameScene.playerStats.base.crit_damage = 2.5
                    gameScene.playerStats.base.move_speed = 250
                    
                    print("Player boosted for boss test: HP=150, ATK=25, SPD=250")
                end
            end
            
            if gameScene then
                bossArenaScene = BossArenaScene:new(
                    gameScene.player,
                    gameScene.playerStats,
                    gameState,
                    gameScene.xpSystem,
                    gameScene.rarityCharge
                )
                print("Boss arena scene created!")
            end
        end
        if bossArenaScene then
            bossArenaScene:update(dt)
        end
    elseif state == States.MENU or state == States.CHARACTER_SELECT or 
           state == States.BIOME_SELECT or state == States.DIFFICULTY_SELECT then
        menu:update(dt)
        -- Reset game scenes when in menu
        if gameScene then
            gameScene = nil
        end
        if bossArenaScene then
            bossArenaScene = nil
        end
    elseif state == States.GAME_OVER or state == States.VICTORY then
        menu:update(dt)
    end
end

function love.draw()
    local state = gameState:getState()
    local States = gameState.States
    
    -- Start retro rendering (to low-res canvas)
    local isRetro = retroRenderer:startDrawing()
    
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
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene then
            bossArenaScene:draw()
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
    
    -- Finish retro rendering (apply shaders and scale up)
    if isRetro then
        retroRenderer:finishDrawing()
    end
end

function drawHUD()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- Draw bottom HUD (health bar + abilities)
    if gameScene and gameScene.player then
        drawBottomHUD(gameScene.player)
        
        -- Draw floor indicator (top-left corner)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("FLOOR: " .. gameState.currentFloor, 20, 20)
        
        -- Debug: show when boss should trigger
        if gameState.currentFloor == 4 then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print(">>> NEXT WAVE = BOSS! <<<", 20, 40)
        elseif gameState.currentFloor >= 5 then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.print("!!! BOSS SHOULD HAVE TRIGGERED !!!", 20, 40)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function drawBottomHUD(player)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local cfg = Config.UI
    
    -- U-shaped HUD background
    local hudWidth = cfg.hudWidth
    local hudHeight = cfg.hudHeight
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
    local healthBarWidth = cfg.healthBarWidth
    local healthBarHeight = cfg.healthBarHeight
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
    
    -- Health text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    local healthText = math.floor(player.health) .. "/" .. player.maxHealth
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(healthText)
    love.graphics.print(healthText, healthBarX + healthBarWidth/2 - textWidth/2, healthBarY + 1)
    
    -- Draw abilities in a row below health bar
    local abilitySize = cfg.abilityIconSize
    local abilitySpacing = cfg.abilitySpacing
    local numAbilities = #player.abilityOrder
    local abilitiesWidth = numAbilities * abilitySize + (numAbilities - 1) * abilitySpacing
    local abilitiesX = (w - abilitiesWidth) / 2
    local abilitiesY = healthBarY + healthBarHeight + 10
    
    for i, abilityId in ipairs(player.abilityOrder) do
        local ability = player.abilities[abilityId]
        if ability then
            local x = abilitiesX + (i - 1) * (abilitySize + abilitySpacing)
            UIUtils.drawAbilityIcon(ability, x, abilitiesY, abilitySize)
        end
    end
end

function love.keypressed(key)
    -- Hot-reload for development (F5) - works in any state
    if key == "f5" then
        reloadBossModules()
        print("Hot-reloaded boss modules!")
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
            -- TODO: Pause menu
            gameState:transitionTo(States.MENU)
        end
    elseif state == States.BOSS_FIGHT then
        if bossArenaScene and bossArenaScene.keypressed then
            bossArenaScene:keypressed(key)
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
