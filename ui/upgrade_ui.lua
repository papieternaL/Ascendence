-- ui/upgrade_ui.lua
-- Modal UI for selecting upgrades on level-up

local UpgradeUI = {}
UpgradeUI.__index = UpgradeUI

-- Rarity colors
local rarityColors = {
  common = { 0.7, 0.7, 0.7 },  -- Gray
  rare = { 0.3, 0.5, 1.0 },    -- Blue
  epic = { 0.7, 0.3, 0.9 },    -- Purple
}

local rarityGlow = {
  common = { 0.5, 0.5, 0.5, 0.3 },
  rare = { 0.3, 0.5, 1.0, 0.4 },
  epic = { 0.7, 0.3, 0.9, 0.5 },
}

function UpgradeUI:new()
  local ui = setmetatable({
    visible = false,
    options = {},  -- Array of upgrade data
    selectedIndex = 1,
    hoveredIndex = nil,
    
    -- Animation
    showTime = 0,
    cardAnimations = {},
    
    -- Callback when upgrade is selected
    onSelect = nil,
  }, UpgradeUI)
  return ui
end

function UpgradeUI:show(options, onSelect)
  self.visible = true
  self.options = options or {}
  self.selectedIndex = 1
  self.hoveredIndex = nil
  self.onSelect = onSelect
  self.showTime = 0
  
  -- Initialize card animations (stagger entrance)
  self.cardAnimations = {}
  for i = 1, #self.options do
    self.cardAnimations[i] = {
      y = -100,  -- Start above screen
      targetY = 0,
      scale = 0.8,
      targetScale = 1.0,
      delay = (i - 1) * 0.1,
    }
  end
end

function UpgradeUI:hide()
  self.visible = false
  self.options = {}
  self.onSelect = nil
end

function UpgradeUI:update(dt)
  if not self.visible then return end
  
  self.showTime = self.showTime + dt
  
  -- Animate cards
  for i, anim in ipairs(self.cardAnimations) do
    if self.showTime > anim.delay then
      anim.y = anim.y + (anim.targetY - anim.y) * dt * 10
      anim.scale = anim.scale + (anim.targetScale - anim.scale) * dt * 10
    end
  end
end

function UpgradeUI:draw()
  if not self.visible then return end
  
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  
  -- Darken background
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
  
  -- Title
  love.graphics.setColor(1, 0.9, 0.3, 1)
  local font = love.graphics.getFont()
  local title = "LEVEL UP! Choose an Upgrade"
  local titleWidth = font:getWidth(title)
  love.graphics.print(title, screenWidth / 2 - titleWidth / 2, 60)
  
  -- Draw upgrade cards
  local cardWidth = 200
  local cardHeight = 280
  local cardSpacing = 30
  local totalWidth = #self.options * cardWidth + (#self.options - 1) * cardSpacing
  local startX = (screenWidth - totalWidth) / 2
  local cardY = (screenHeight - cardHeight) / 2
  
  for i, upgrade in ipairs(self.options) do
    local anim = self.cardAnimations[i] or { y = 0, scale = 1 }
    local cardX = startX + (i - 1) * (cardWidth + cardSpacing)
    local isSelected = (i == self.selectedIndex)
    local isHovered = (i == self.hoveredIndex)
    
    self:drawCard(upgrade, cardX, cardY + anim.y, cardWidth, cardHeight, anim.scale, isSelected or isHovered)
  end
  
  -- Instructions
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  local instructions = "[A/D or Arrow Keys] Navigate   [Enter] Select   [Click] Select"
  local instrWidth = font:getWidth(instructions)
  love.graphics.print(instructions, screenWidth / 2 - instrWidth / 2, screenHeight - 50)
  
  love.graphics.setColor(1, 1, 1, 1)
end

function UpgradeUI:drawCard(upgrade, x, y, width, height, scale, isSelected)
  love.graphics.push()
  love.graphics.translate(x + width / 2, y + height / 2)
  love.graphics.scale(scale, scale)
  love.graphics.translate(-width / 2, -height / 2)
  
  local rarity = upgrade.rarity or "common"
  local color = rarityColors[rarity] or rarityColors.common
  local glow = rarityGlow[rarity] or rarityGlow.common
  
  -- Glow effect for selected/hovered
  if isSelected then
    love.graphics.setColor(glow[1], glow[2], glow[3], glow[4] + 0.2)
    love.graphics.rectangle("fill", -8, -8, width + 16, height + 16, 12, 12)
  end
  
  -- Card background
  love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
  love.graphics.rectangle("fill", 0, 0, width, height, 8, 8)
  
  -- Rarity border
  if isSelected then
    love.graphics.setLineWidth(3)
    love.graphics.setColor(color[1], color[2], color[3], 1)
  else
    love.graphics.setLineWidth(2)
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, 1)
  end
  love.graphics.rectangle("line", 0, 0, width, height, 8, 8)
  love.graphics.setLineWidth(1)
  
  -- Rarity banner at top
  love.graphics.setColor(color[1], color[2], color[3], 0.3)
  love.graphics.rectangle("fill", 0, 0, width, 30, 8, 8)
  love.graphics.rectangle("fill", 0, 15, width, 15)
  
  -- Rarity text
  love.graphics.setColor(color[1], color[2], color[3], 1)
  local rarityText = string.upper(rarity)
  local font = love.graphics.getFont()
  local rarityWidth = font:getWidth(rarityText)
  love.graphics.print(rarityText, width / 2 - rarityWidth / 2, 8)
  
  -- Upgrade name
  love.graphics.setColor(1, 1, 1, 1)
  local name = upgrade.name or "Unknown"
  local nameWidth = font:getWidth(name)
  love.graphics.print(name, width / 2 - nameWidth / 2, 45)
  
  -- Separator line
  love.graphics.setColor(color[1], color[2], color[3], 0.5)
  love.graphics.line(20, 70, width - 20, 70)
  
  -- Effect description
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  local description = self:getUpgradeDescription(upgrade)
  
  -- Word wrap the description
  local maxWidth = width - 20
  local lines = self:wrapText(description, maxWidth)
  local lineY = 85
  for _, line in ipairs(lines) do
    love.graphics.print(line, 10, lineY)
    lineY = lineY + 18
  end
  
  -- Tags at bottom
  if upgrade.tags and #upgrade.tags > 0 then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    local tagText = table.concat(upgrade.tags, " • ")
    local tagWidth = font:getWidth(tagText)
    if tagWidth > width - 10 then
      tagText = table.concat({upgrade.tags[1], upgrade.tags[2] or ""}, " • ")
      tagWidth = font:getWidth(tagText)
    end
    love.graphics.print(tagText, width / 2 - tagWidth / 2, height - 25)
  end
  
  love.graphics.pop()
end

function UpgradeUI:getUpgradeDescription(upgrade)
  if not upgrade.effects or #upgrade.effects == 0 then
    return "No effect"
  end
  
  local parts = {}
  
  for _, effect in ipairs(upgrade.effects) do
    if effect.kind == "stat_mul" then
      local percent = math.floor((effect.value - 1) * 100)
      local sign = percent >= 0 and "+" or ""
      parts[#parts+1] = sign .. percent .. "% " .. self:formatStatName(effect.stat)
      
    elseif effect.kind == "stat_add" then
      local sign = effect.value >= 0 and "+" or ""
      if effect.stat == "crit_chance" then
        parts[#parts+1] = sign .. math.floor(effect.value * 100) .. "% Crit Chance"
      else
        parts[#parts+1] = sign .. effect.value .. " " .. self:formatStatName(effect.stat)
      end
      
    elseif effect.kind == "weapon_mod" then
      if effect.mod == "pierce_add" then
        parts[#parts+1] = "+" .. effect.value .. " Pierce"
      elseif effect.mod == "ricochet" then
        parts[#parts+1] = "Arrows ricochet " .. effect.bounces .. " time(s)"
      elseif effect.mod == "bonus_projectiles" then
        parts[#parts+1] = "+" .. effect.value .. " bonus projectile(s)"
      end
      
    elseif effect.kind == "proc" then
      parts[#parts+1] = self:describeProcEffect(effect)
      
    elseif effect.kind == "ability_mod" then
      parts[#parts+1] = self:describeAbilityMod(effect)
    end
  end
  
  return table.concat(parts, "\n")
end

function UpgradeUI:formatStatName(stat)
  local names = {
    primary_damage = "Damage",
    attack_speed = "Attack Speed",
    move_speed = "Move Speed",
    range = "Range",
    crit_chance = "Crit Chance",
    crit_damage = "Crit Damage",
    roll_cooldown = "Roll Cooldown",
    xp_pickup_radius = "XP Pickup Range",
  }
  return names[stat] or stat
end

function UpgradeUI:describeProcEffect(effect)
  local trigger = effect.trigger or ""
  local apply = effect.apply or {}
  
  if trigger == "on_primary_hit" then
    if apply.kind == "status_apply" then
      return "Attacks apply " .. (apply.status or "effect")
    end
  elseif trigger == "on_crit_hit" then
    return "On crit: " .. (apply.kind or "effect")
  elseif trigger == "after_roll" then
    if apply.kind == "buff" then
      return "After roll: gain " .. (apply.name or "buff")
    end
  elseif trigger == "while_enemy_within" then
    return "+Damage when enemies nearby"
  elseif trigger == "every_n_primary_shots" then
    return "Every " .. (effect.n or 5) .. " shots: bonus effect"
  end
  
  return "Special effect"
end

function UpgradeUI:describeAbilityMod(effect)
  local ability = effect.ability or "ability"
  local mod = effect.mod or ""
  local value = effect.value or 0
  
  if mod == "cooldown_add" or mod == "cooldown_mul" then
    return ability:gsub("_", " "):gsub("^%l", string.upper) .. ": reduced cooldown"
  elseif mod == "damage_mul" or mod == "range_mul" then
    local percent = math.floor((value - 1) * 100)
    return ability:gsub("_", " "):gsub("^%l", string.upper) .. ": " .. (percent >= 0 and "+" or "") .. percent .. "%"
  end
  
  return ability:gsub("_", " "):gsub("^%l", string.upper) .. " improved"
end

function UpgradeUI:wrapText(text, maxWidth)
  local font = love.graphics.getFont()
  local lines = {}
  
  for line in text:gmatch("[^\n]+") do
    local currentLine = ""
    for word in line:gmatch("%S+") do
      local testLine = currentLine == "" and word or (currentLine .. " " .. word)
      if font:getWidth(testLine) <= maxWidth then
        currentLine = testLine
      else
        if currentLine ~= "" then
          lines[#lines+1] = currentLine
        end
        currentLine = word
      end
    end
    if currentLine ~= "" then
      lines[#lines+1] = currentLine
    end
  end
  
  return lines
end

function UpgradeUI:keypressed(key)
  if not self.visible then return false end
  
  if key == "left" or key == "a" then
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then
      self.selectedIndex = #self.options
    end
    return true
    
  elseif key == "right" or key == "d" then
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.options then
      self.selectedIndex = 1
    end
    return true
    
  elseif key == "return" then
    self:selectCurrent()
    return true
    
  elseif key == "1" and #self.options >= 1 then
    self.selectedIndex = 1
    self:selectCurrent()
    return true
    
  elseif key == "2" and #self.options >= 2 then
    self.selectedIndex = 2
    self:selectCurrent()
    return true
    
  elseif key == "3" and #self.options >= 3 then
    self.selectedIndex = 3
    self:selectCurrent()
    return true
  end
  
  return false
end

function UpgradeUI:mousepressed(x, y, button)
  if not self.visible or button ~= 1 then return false end
  
  local cardIndex = self:getCardAtPosition(x, y)
  if cardIndex then
    self.selectedIndex = cardIndex
    self:selectCurrent()
    return true
  end
  
  return false
end

function UpgradeUI:mousemoved(x, y)
  if not self.visible then return end
  
  self.hoveredIndex = self:getCardAtPosition(x, y)
end

function UpgradeUI:getCardAtPosition(x, y)
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  
  local cardWidth = 200
  local cardHeight = 280
  local cardSpacing = 30
  local totalWidth = #self.options * cardWidth + (#self.options - 1) * cardSpacing
  local startX = (screenWidth - totalWidth) / 2
  local cardY = (screenHeight - cardHeight) / 2
  
  for i = 1, #self.options do
    local cardX = startX + (i - 1) * (cardWidth + cardSpacing)
    if x >= cardX and x <= cardX + cardWidth and
       y >= cardY and y <= cardY + cardHeight then
      return i
    end
  end
  
  return nil
end

function UpgradeUI:selectCurrent()
  if self.selectedIndex >= 1 and self.selectedIndex <= #self.options then
    local upgrade = self.options[self.selectedIndex]
    if self.onSelect then
      self.onSelect(upgrade)
    end
    self:hide()
  end
end

function UpgradeUI:isVisible()
  return self.visible
end

return UpgradeUI


