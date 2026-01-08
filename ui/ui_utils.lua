local UIUtils = {}

function UIUtils.drawAbilityIcon(ability, x, y, size)
    local hasCharge = (ability.chargeMax ~= nil)
    local isReady = ability.currentCooldown and ability.currentCooldown <= 0
    local cooldownPercent = 0
    if hasCharge then
        local c = ability.charge or 0
        local m = ability.chargeMax or 1
        isReady = c >= m
        cooldownPercent = 1 - (c / m)
    else
        cooldownPercent = (ability.cooldown and ability.cooldown > 0) and (ability.currentCooldown / ability.cooldown) or 0
    end
    
    -- Ability background
    if isReady then
        love.graphics.setColor(0.2, 0.25, 0.35, 1)
    else
        love.graphics.setColor(0.1, 0.1, 0.15, 1)
    end
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)
    
    -- Cooldown overlay (sweeping arc)
    if not isReady then
        love.graphics.setColor(0, 0, 0, 0.6)
        local centerX = x + size / 2
        local centerY = y + size / 2
        local radius = size / 2 - 2
        local angleStart = -math.pi / 2
        local angleEnd = angleStart + (2 * math.pi * cooldownPercent)
        
        -- Draw filled arc
        if cooldownPercent > 0 then
            local vertices = {centerX, centerY}
            local segments = 32
            for i = 0, segments do
                local t = i / segments
                local angle = angleStart + (angleEnd - angleStart) * t
                table.insert(vertices, centerX + math.cos(angle) * radius)
                table.insert(vertices, centerY + math.sin(angle) * radius)
            end
            if #vertices >= 6 then
                love.graphics.polygon("fill", vertices)
            end
        end
    end
    
    -- Ready border pulse
    if isReady then
        local pulse = 0.5 + math.sin(love.timer.getTime() * 4) * 0.5
        love.graphics.setColor(0.3, 0.8, 1, pulse)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, size, size, 6, 6)
        love.graphics.setLineWidth(1)
    end
    
    -- Border
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, 6, 6)
    love.graphics.setLineWidth(1)
    
    -- Ability icon or key
    love.graphics.setColor(1, 1, 1, isReady and 1 or 0.4)
    local icon = ability.icon or ability.key or "?"
    
    -- Try to draw emoji/icon with larger font
    local oldFont = love.graphics.getFont()
    local iconFont = love.graphics.newFont(20)
    love.graphics.setFont(iconFont)
    local textWidth = iconFont:getWidth(icon)
    love.graphics.print(icon, x + size/2 - textWidth/2, y + 6)
    
    -- Key binding (small text at bottom)
    if ability.key then
        love.graphics.setColor(1, 1, 1, 0.8)
        local keyFont = love.graphics.newFont(10)
        love.graphics.setFont(keyFont)
        local keyWidth = keyFont:getWidth(ability.key)
        love.graphics.print(ability.key, x + size/2 - keyWidth/2, y + size - 14)
    end
    
    -- Cooldown timer text
    if not isReady then
        love.graphics.setColor(1, 1, 1, 1)
        local cdFont = love.graphics.newFont(14)
        love.graphics.setFont(cdFont)
        local cdText = ""
        if hasCharge then
             local c = ability.charge or 0
             local m = ability.chargeMax or 1
             cdText = string.format("%d%%", math.floor((c / m) * 100))
        else
             local cd = ability.currentCooldown or 0
             cdText = string.format("%.1f", cd)
        end
        local cdWidth = cdFont:getWidth(cdText)
        love.graphics.print(cdText, x + size/2 - cdWidth/2, y + size/2 - 7)
    end
    
    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return UIUtils
