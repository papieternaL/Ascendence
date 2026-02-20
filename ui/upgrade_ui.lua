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

-- UTF-8-safe truncation (avoids splitting multi-byte chars, prevents getWidth crash)
local function utf8SafeSub(str, charCount)
  if not str or charCount <= 0 then return "" end
  if utf8 and utf8.len and utf8.offset then
    local len = utf8.len(str)
    if not len or charCount >= len then return str end
    local byteEnd = utf8.offset(str, charCount + 1)
    if byteEnd then
      return str:sub(1, byteEnd - 1)
    end
  end
  -- Fallback: find last UTF-8 char boundary at or before byte charCount
  local n = math.min(charCount, #str)
  while n > 0 do
    local b = str:byte(n)
    if not b or b < 0x80 or b > 0xBF then  -- ASCII or start byte
      return str:sub(1, n)
    end
    n = n - 1
  end
  return ""
end

local function splitUtf8Units(str)
  local units = {}
  if not str or str == "" then return units end
  local i = 1
  local n = #str
  while i <= n do
    local b = str:byte(i)
    local len = 1
    if b and b >= 0xF0 then
      len = 4
    elseif b and b >= 0xE0 then
      len = 3
    elseif b and b >= 0xC0 then
      len = 2
    end
    if i + len - 1 > n then
      len = 1
    end
    table.insert(units, str:sub(i, i + len - 1))
    i = i + len
  end
  return units
end

local function truncateToWidth(text, maxWidth, font, suffix)
  if not text or text == "" or not font then return text or "" end
  local utf8Available = (utf8 and utf8.len and utf8.offset) and true or false
  if font:getWidth(text) <= maxWidth then return text end
  suffix = suffix or "..."
  local suffixW = font:getWidth(suffix)
  local maxContentW = maxWidth - suffixW
  if maxContentW <= 0 then return suffix end

  if utf8Available then
    local charCount = utf8.len(text)
    if not charCount or charCount <= 0 then return suffix end
    for n = charCount, 1, -1 do
      local sub = utf8SafeSub(text, n)
      if sub and font:getWidth(sub) <= maxContentW then
        return sub .. suffix
      end
    end
  else
    local units = splitUtf8Units(text)
    for n = #units, 1, -1 do
      local sub = table.concat(units, "", 1, n)
      if font:getWidth(sub) <= maxContentW then
        return sub .. suffix
      end
    end
  end
  return suffix
end

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

function UpgradeUI:show(options, onSelect, playerStats)
  self.visible = true
  self.options = options or {}
  self.selectedIndex = 1
  self.hoveredIndex = nil
  self.onSelect = onSelect
  self.playerStats = playerStats
  self.showTime = 0
  
  -- Initialize card animations (stagger entrance + flip)
  self.cardAnimations = {}
  for i = 1, #self.options do
    self.cardAnimations[i] = {
      y = -100,  -- Start above screen
      targetY = 0,
      scale = 0.8,
      targetScale = 1.0,
      delay = (i - 1) * 0.1,
      -- Flip animation states
      flipState = "entering",  -- entering, waiting, flipping, revealed
      flipProgress = 0.0,      -- 0.0 to 1.0 during flip
      flipDelay = 0.5 + (i - 1) * 0.3,  -- Staggered: 0.5s, 0.8s, 1.1s
      showFront = false,       -- false = back, true = front
    }
  end

  -- Sound effect for card flip
  self.flipSound = nil
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
    -- Entrance animation
    if self.showTime > anim.delay then
      anim.y = anim.y + (anim.targetY - anim.y) * dt * 10
      anim.scale = anim.scale + (anim.targetScale - anim.scale) * dt * 10
    end

    -- Flip state machine
    if anim.flipState == "entering" then
      if math.abs(anim.y - anim.targetY) < 1 and math.abs(anim.scale - anim.targetScale) < 0.01 then
        anim.flipState = "waiting"
      end
    elseif anim.flipState == "waiting" then
      if self.showTime > anim.flipDelay then
        anim.flipState = "flipping"
        anim.flipProgress = 0.0
      end
    elseif anim.flipState == "flipping" then
      anim.flipProgress = anim.flipProgress + (dt / 0.4)  -- 0.4s flip duration
      if anim.flipProgress >= 1.0 then
        anim.flipProgress = 1.0
        anim.flipState = "revealed"
        anim.showFront = true
        self:playFlipSound()  -- Sound at flip completion
      end
    end
  end
end

function UpgradeUI:draw()
  if not self.visible then return end
  
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  
  -- Use UI fonts (linear filter) for readability when available
  local uiFont = _G.PixelFonts and (_G.PixelFonts.uiBody or _G.PixelFonts.body)
  if uiFont then love.graphics.setFont(uiFont) end
  
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
    local anim = self.cardAnimations[i] or { y = 0, scale = 1, flipProgress = 0, showFront = true }
    local cardX = startX + (i - 1) * (cardWidth + cardSpacing)
    local isSelected = (i == self.selectedIndex)
    local isHovered = (i == self.hoveredIndex)

    self:drawCard(upgrade, cardX, cardY + anim.y, cardWidth, cardHeight, anim.scale, isSelected or isHovered, i)
  end
  
  -- Instructions
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  local instructions = "[A/D or Arrow Keys] Navigate   [Enter] Select   [Click] Select"
  local instrWidth = font:getWidth(instructions)
  love.graphics.print(instructions, screenWidth / 2 - instrWidth / 2, screenHeight - 50)
  
  love.graphics.setColor(1, 1, 1, 1)
end

function UpgradeUI:drawCard(upgrade, x, y, width, height, scale, isSelected, cardIndex)
  local anim = self.cardAnimations[cardIndex]

  love.graphics.push()
  love.graphics.translate(x + width / 2, y + height / 2)

  -- Calculate flip scale (simulate 3D rotation)
  local flipScaleX = 1.0
  local showFront = anim and anim.showFront or false
  if anim and anim.flipProgress < 0.5 then
    flipScaleX = 1.0 - (anim.flipProgress * 2.0)  -- Shrink to 0
    showFront = false
  elseif anim and anim.flipProgress >= 0.5 then
    flipScaleX = (anim.flipProgress - 0.5) * 2.0  -- Expand from 0
    showFront = true
  end

  love.graphics.scale(scale * flipScaleX, scale)
  love.graphics.translate(-width / 2, -height / 2)

  if showFront then
    -- Draw front face (upgrade details)
    self:drawCardFront(upgrade, width, height, isSelected)
  else
    -- Draw card back
    self:drawCardBack(width, height, isSelected)
  end

  love.graphics.pop()
end

function UpgradeUI:drawCardFront(upgrade, width, height, isSelected)
  
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
  
  -- Upgrade name (UTF-8-safe truncate if too long)
  love.graphics.setColor(1, 1, 1, 1)
  local name = truncateToWidth(upgrade.name or "Unknown", width - 20, font, "...")
  local nameWidth = font:getWidth(name)
  love.graphics.print(name, width / 2 - nameWidth / 2, 45)
  
  -- Separator line
  love.graphics.setColor(color[1], color[2], color[3], 0.5)
  love.graphics.line(20, 70, width - 20, 70)
  
  -- Effect description
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  local description = self:getUpgradeDescription(upgrade)
  
  -- Word wrap the description; use font-based line height and clip before tags
  local maxWidth = width - 20
  local lineHeight = font:getHeight() + 2
  local tagY = height - 35
  local lines = self:wrapText(description, maxWidth)
  local lineY = 85
  for _, line in ipairs(lines) do
    if lineY + lineHeight > tagY then break end
    love.graphics.print(line, 10, lineY)
    lineY = lineY + lineHeight
  end
  
  -- Current -> next preview for already-picked upgrades
  if self.playerStats and self.playerStats.hasUpgrade and self.playerStats:hasUpgrade(upgrade.id) then
    local preview = self:getCurrentNextPreview(upgrade)
    if preview and preview ~= "" then
      love.graphics.setColor(0.4, 0.9, 0.5, 1)
      local previewLines = self:wrapText(preview, maxWidth)
      for _, line in ipairs(previewLines) do
        if lineY + lineHeight > tagY then break end
        love.graphics.print(line, 10, lineY)
        lineY = lineY + lineHeight
      end
    end
  end
  
  -- Tags at bottom (UTF-8-safe truncate with ellipsis if too wide)
  if upgrade.tags and #upgrade.tags > 0 then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    local tagText = table.concat(upgrade.tags, " • ")
    tagText = truncateToWidth(tagText, width - 20, font, "...")
    if tagText ~= "" then
      local tagWidth = font:getWidth(tagText)
      love.graphics.print(tagText, width / 2 - tagWidth / 2, height - 25)
    end
  end
end

function UpgradeUI:drawCardBack(width, height, isSelected)
  -- Dark background
  love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
  love.graphics.rectangle("fill", 0, 0, width, height, 8, 8)

  -- Mystery symbol
  love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
  local oldFont = love.graphics.getFont()
  love.graphics.setNewFont(64)
  local text = "?"
  local font = love.graphics.getFont()
  local tw = font:getWidth(text)
  love.graphics.print(text, width/2 - tw/2, height/2 - 40)
  love.graphics.setFont(oldFont)

  -- Border with glow if selected
  if isSelected then
    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
  else
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
  end
  love.graphics.rectangle("line", 0, 0, width, height, 8, 8)
  love.graphics.setLineWidth(1)
end

function UpgradeUI:playFlipSound()
  if not self.flipSound then
    local success, sound = pcall(love.audio.newSource, "assets/Audio/Interface Sounds/card_flip.ogg", "static")
    if success then
      self.flipSound = sound
    else
      return  -- Gracefully fail if sound missing
    end
  end

  if self.flipSound then
    self.flipSound:stop()
    self.flipSound:play()
  end
end

function UpgradeUI:getCurrentNextPreview(upgrade)
  if not self.playerStats or not upgrade.effects or #upgrade.effects == 0 then return "" end
  local parts = {}
  for _, effect in ipairs(upgrade.effects) do
    local stat = effect.stat
    local value = effect.value
    local name = self:formatStatName(stat or "")
    if effect.kind == "stat_add" and stat then
      local current = self.playerStats:getPermanent(stat) or 0
      local nextVal = current + (value or 0)
      if stat == "crit_chance" then
        table.insert(parts, string.format("Crit Chance: %d%% -> %d%% next", math.floor(current * 100), math.floor(nextVal * 100)))
      else
        table.insert(parts, string.format("%s: %.0f -> %.0f next", name, current, nextVal))
      end
    elseif effect.kind == "stat_mul" and stat then
      local current = self.playerStats:getPermanent(stat) or 0
      local nextVal = current * (value or 1)
      if stat == "crit_chance" then
        table.insert(parts, string.format("Crit Chance: %d%% -> %d%% next", math.floor(current * 100), math.floor(nextVal * 100)))
      elseif stat == "crit_damage" then
        table.insert(parts, string.format("Crit Damage: %.0f%% -> %.0f%% next", current * 100, nextVal * 100))
      elseif stat == "roll_cooldown" then
        table.insert(parts, string.format("Roll CD: %.1fs -> %.1fs next", current, nextVal))
      else
        table.insert(parts, string.format("%s: %.0f -> %.0f next", name, current, nextVal))
      end
    elseif effect.kind == "weapon_mod" and effect.mod == "pierce_add" then
      local current = self.playerStats:getWeaponMod("pierce") or 0
      local nextVal = current + (value or 0)
      table.insert(parts, string.format("Pierce: %d -> %d next", current, nextVal))
    elseif effect.kind == "weapon_mod" and effect.mod == "ricochet" then
      local current = self.playerStats:getWeaponMod("ricochet_bounces") or 0
      local addBounces = effect.bounces or 1
      local nextVal = current + addBounces
      table.insert(parts, string.format("Bounce targets: %d -> %d next", current, nextVal))
    elseif effect.kind == "ability_mod" then
      local ability = effect.ability or ""
      local mod = effect.mod or ""
      local baseVal = 1.0
      if mod == "damage_mul" or mod == "range_mul" then
        baseVal = 3.0
        if ability == "entangle" or ability == "arrow_volley" then baseVal = 1.5 end
      end
      local current = self.playerStats:getAbilityValue(ability, mod, baseVal)
      local nextVal = current * (value or 1)
      local label = ability:gsub("_", " "):gsub("^%l", string.upper)
      if mod == "damage_mul" then
        table.insert(parts, string.format("%s dmg: %.0f%% -> %.0f%% next", label, current * 100, nextVal * 100))
      elseif mod == "range_mul" then
        table.insert(parts, string.format("%s range: %.0f%% -> %.0f%% next", label, current * 100, nextVal * 100))
      elseif mod == "cooldown_mul" then
        table.insert(parts, string.format("%s CD: %.0f%% -> %.0f%% next", label, current * 100, nextVal * 100))
      end
    end
  end
  return table.concat(parts, "\n")
end

function UpgradeUI:getUpgradeDescription(upgrade)
  -- Use pre-written description if available (preferred)
  if upgrade.description then
    return upgrade.description
  end
  
  -- Fallback to dynamic generation for backwards compatibility
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


