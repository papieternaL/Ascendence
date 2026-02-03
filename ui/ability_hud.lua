-- Ability HUD - Hexagonal frames with health bar and level badge
local AbilityHUD = {}
AbilityHUD.__index = AbilityHUD

function AbilityHUD:new()
    local hud = {}
    setmetatable(hud, AbilityHUD)
    return hud
end

-- Draw a hexagon
local function drawHexagon(x, y, radius, filled)
    local points = {}
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2 - math.pi / 2
        table.insert(points, x + math.cos(angle) * radius)
        table.insert(points, y + math.sin(angle) * radius)
    end
    
    if filled then
        love.graphics.polygon("fill", points)
    else
        love.graphics.polygon("line", points)
    end
end

-- Draw radial cooldown as a hexagon sweep
local function drawHexagonalCooldown(x, y, radius, progress, color)
    if progress >= 1 then return end
    
    love.graphics.setColor(0.15, 0.15, 0.2, 0.6)
    
    -- Draw hexagonal segments based on progress
    local segments = 36
    local angle = progress * math.pi * 2
    
    for i = 0, segments do
        local a = (i / segments) * math.pi * 2 - math.pi / 2
        if a - math.pi / 2 <= angle then
            local x1 = x + math.cos(a) * radius
            local y1 = y + math.sin(a) * radius
            local x2 = x + math.cos(a + math.pi * 2 / segments) * radius
            local y2 = y + math.sin(a + math.pi * 2 / segments) * radius
            love.graphics.polygon("fill", x, y, x1, y1, x2, y2)
        end
    end
end

function AbilityHUD:draw(player, xpSystem)
    if not player or not player.abilities then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- ===== HEALTH BAR (bottom-left corner) =====
    local healthBarWidth = 300
    local healthBarHeight = 24
    local padding = 30
    local healthBarX = padding
    local healthBarY = screenHeight - padding - healthBarHeight
    local healthPercent = player.health / player.maxHealth
    
    -- Low health pulse
    local pulse = 1.0
    if healthPercent < 0.25 then
        pulse = 0.8 + math.sin(love.timer.getTime() * 8) * 0.2
    end
    
    -- Background
    love.graphics.setColor(0.08, 0.08, 0.12, 0.7)
    love.graphics.rectangle("fill", healthBarX - 3, healthBarY - 3, healthBarWidth + 6, healthBarHeight + 6, 4, 4)
    
    -- Health fill (orange gradient)
    local r, g, b = 1.0, 0.45, 0.1  -- Orange
    if healthPercent < 0.3 then
        -- Shift to red at low health
        r, g, b = 1.0, 0.2, 0.1
    end
    love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, 1)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight, 3, 3)
    
    -- Bright fill on top
    love.graphics.setColor(r, g, b, pulse * 0.9)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight * 0.5, 3, 3)
    
    -- Border glow
    love.graphics.setColor(r, g, b, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 3, 3)
    love.graphics.setLineWidth(1)
    
    -- HP text
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = string.format("%d/%d", math.floor(player.health), math.floor(player.maxHealth))
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(hpText)
    local textHeight = font:getHeight()
    love.graphics.print(hpText, healthBarX + healthBarWidth / 2 - textWidth / 2, healthBarY + healthBarHeight / 2 - textHeight / 2)
    
    -- ===== ABILITY ICONS (hexagonal frames, bottom-right corner) =====
    local iconSize = 45
    local spacing = 60  -- Reduced from 75 for compactness

    -- Count unlocked abilities
    local unlockedAbilities = {}
    local abilityOrder = player.abilityOrder or {"power_shot", "dash", "arrow_volley", "frenzy"}
    for _, aid in ipairs(abilityOrder) do
        if player.abilities[aid] and player.abilities[aid].unlocked then
            table.insert(unlockedAbilities, aid)
        end
    end

    local numUnlocked = #unlockedAbilities
    local totalWidth = numUnlocked * iconSize + (numUnlocked - 1) * spacing
    local startX = screenWidth - padding - totalWidth
    local yPos = screenHeight - padding - iconSize / 2 - 10

    -- #region agent log
    local logFile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
    if logFile then
        logFile:write('{"hypothesisId":"H3","location":"ability_hud.lua:draw","message":"abilities check","data":{"unlockedCount":'..numUnlocked..',"totalAbilities":4},"timestamp":'..os.time()..'}\n')
        logFile:close()
    end
    -- #endregion

    for idx, abilityId in ipairs(unlockedAbilities) do
        local ability = player.abilities[abilityId]
        if ability then
            local x = startX + (idx - 1) * (iconSize + spacing)
            local y = yPos
            
            -- Calculate cooldown/charge progress
            local progress = 0
            local isReady = false
            
            if abilityId == "frenzy" and ability.charge then
                progress = ability.charge / (ability.chargeMax or 100)
                isReady = progress >= 1
            else
                local currentCD = ability.currentCooldown or 0
                local maxCD = ability.cooldown or 1
                progress = 1 - (currentCD / maxCD)
                isReady = currentCD <= 0
            end
            
            -- Ability color
            local color = {0.5, 0.5, 0.6}
            if abilityId == "power_shot" then
                color = {1, 0.9, 0.3}  -- Golden
            elseif abilityId == "dash" then
                color = {0.4, 0.7, 1}  -- Blue
            elseif abilityId == "arrow_volley" then
                color = {0.3, 1, 0.5}  -- Green
            elseif abilityId == "frenzy" then
                color = {1, 0.3, 0.3}  -- Red
            end
            
            -- Glow when ready
            if isReady then
                local glowPulse = 0.6 + math.sin(love.timer.getTime() * 4) * 0.4
                love.graphics.setColor(color[1], color[2], color[3], glowPulse * 0.5)
                drawHexagon(x, y, iconSize / 2 + 10, true)
            end
            
            -- Dark metallic background hexagon
            love.graphics.setColor(0.12, 0.12, 0.18, 0.7)
            drawHexagon(x, y, iconSize / 2, true)
            
            -- Cooldown overlay
            drawHexagonalCooldown(x, y, iconSize / 2, progress, color)
            
            -- Hexagonal border
            love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 0.8)
            love.graphics.setLineWidth(2)
            drawHexagon(x, y, iconSize / 2, false)
            
            -- Bright border when ready
            if isReady then
                love.graphics.setColor(color[1], color[2], color[3], 1)
                love.graphics.setLineWidth(3)
                drawHexagon(x, y, iconSize / 2, false)
            end
            
            -- Keybind letter
            love.graphics.setColor(1, 1, 1, isReady and 1 or 0.6)
            local key = ability.key or "?"
            local keyWidth = font:getWidth(key)
            love.graphics.print(key, x - keyWidth / 2, y - textHeight / 2)
            
            -- Cooldown number inside icon
            if not isReady and not ability.charge then
                local cdText = string.format("%.1f", ability.currentCooldown or 0)
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.setNewFont(14)
                local cdFont = love.graphics.getFont()
                local cdWidth = cdFont:getWidth(cdText)
                local cdHeight = cdFont:getHeight()
                love.graphics.print(cdText, x - cdWidth / 2, y + 8)
                love.graphics.setNewFont(12)  -- Reset
            end
        end
    end
    
    -- ===== PLAYER LEVEL BADGE (bottom-left, above health bar) =====
    if xpSystem then
        local levelBadgeRadius = 35
        local levelBadgeX = padding + levelBadgeRadius + 10
        local levelBadgeY = screenHeight - padding - healthBarHeight - 60
        
        -- Outer glow ring
        love.graphics.setColor(0.3, 0.5, 0.8, 0.4)
        love.graphics.circle("fill", levelBadgeX, levelBadgeY, levelBadgeRadius + 4)
        
        -- Dark background circle
        love.graphics.setColor(0.1, 0.1, 0.15, 0.7)
        love.graphics.circle("fill", levelBadgeX, levelBadgeY, levelBadgeRadius)
        
        -- Border ring
        love.graphics.setColor(0.4, 0.6, 1, 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", levelBadgeX, levelBadgeY, levelBadgeRadius)
        
        -- Level number
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setNewFont(24)
        local levelFont = love.graphics.getFont()
        local levelText = tostring(xpSystem.level or 1)
        local levelWidth = levelFont:getWidth(levelText)
        local levelHeight = levelFont:getHeight()
        love.graphics.print(levelText, levelBadgeX - levelWidth / 2, levelBadgeY - levelHeight / 2)
        love.graphics.setNewFont(12)  -- Reset
    end
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return AbilityHUD
