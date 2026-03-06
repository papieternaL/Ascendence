-- ui/upgrade_ui.lua
-- Modal UI for selecting upgrades on level-up

local UpgradeUI = {}
UpgradeUI.__index = UpgradeUI

local FONT_PATH_BOLD = "assets/Other/Fonts/Kenney Bold.ttf"
local FONT_PATH_SMALL = "assets/Other/Fonts/Kenney Mini Square.ttf"
local scaledCardFonts = nil

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

-- Metallic frame colors (grey/silver common, green rare, blue epic)
local metallicColors = {
  common = { 0.55, 0.52, 0.5 },
  rare = { 0.25, 0.65, 0.4 },
  epic = { 0.35, 0.5, 0.9 },
}

-- Derive upgrade type from tags
local function getUpgradeType(upgrade)
  if upgrade.type then return upgrade.type end
  local tags = upgrade.tags or {}
  for _, t in ipairs(tags) do
    if t == "element" or t == "fire" or t == "ice" or t == "lightning" then return "Element" end
    if t == "projectile" or t == "primary" or t == "multishot" then return "Projectile" end
  end
  return "Passive"
end

-- Derive icon key from upgrade id/tags (for procedural icon drawing)
local function getUpgradeIconKey(upgrade)
  if upgrade.icon then return upgrade.icon end
  local id = upgrade.id or ""
  if id:find("fleetfoot") or id:find("stamina") then return "boot" end
  if id:find("fire") then return "flame" end
  if id:find("ice") then return "snowflake" end
  if id:find("lightning") then return "bolt" end
  if id:find("arrow") or id:find("ricochet") or id:find("pierc") then return "arrow" end
  if id:find("crit") or id:find("hollow") then return "target" end
  if id:find("xp") or id:find("magnet") then return "magnet" end
  if id:find("bleed") or id:find("barbed") then return "blood" end
  return "star"
end

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

local function ensureScaledCardFonts()
  if scaledCardFonts then
    return scaledCardFonts
  end

  local function loadFont(path, size)
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok then
      font:setFilter("linear", "linear")
      return font
    end
    font = love.graphics.newFont(size)
    font:setFilter("linear", "linear")
    return font
  end

  scaledCardFonts = {
    name = loadFont(FONT_PATH_BOLD, 15),
    body = loadFont(FONT_PATH_SMALL, 12),
    tag = loadFont(FONT_PATH_SMALL, 10),
  }

  return scaledCardFonts
end

local function getCardLayout(optionCount, screenWidth, screenHeight)
  local cardWidth = 222
  local cardHeight = 304
  local cardSpacing = 28
  local totalWidth = optionCount * cardWidth + math.max(0, optionCount - 1) * cardSpacing
  local startX = (screenWidth - totalWidth) / 2
  local titleY = math.floor(screenHeight * 0.22)
  local cardY = math.max(math.floor(screenHeight * 0.34), titleY + 64)
  return {
    cardWidth = cardWidth,
    cardHeight = cardHeight,
    cardSpacing = cardSpacing,
    totalWidth = totalWidth,
    startX = startX,
    titleY = titleY,
    cardY = cardY,
  }
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
  local layout = getCardLayout(#self.options, screenWidth, screenHeight)
  
  -- Use smaller UI fonts so card text fits
  local cardFonts = ensureScaledCardFonts()
  local cardFont = cardFonts.body or (_G.PixelFonts and _G.PixelFonts.uiSmall) or love.graphics.getFont()
  local titleFont = _G.PixelFonts and _G.PixelFonts.uiBody or cardFont
  love.graphics.setFont(cardFont)
  
  -- Darken background, but keep the playfield readable under the modal.
  love.graphics.setColor(0.01, 0.02, 0.03, 0.5)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

  self:drawBackdropAtmosphere(layout, screenWidth, screenHeight)

  local title = "LEVEL UP! CHOOSE AN UPGRADE"
  local titleDrawFont = _G.PixelFonts and _G.PixelFonts.title or _G.PixelFonts and _G.PixelFonts.uiLarge or titleFont
  love.graphics.setFont(titleDrawFont)
  local titleW = love.graphics.getFont():getWidth(title)
  local titleX = screenWidth / 2 - titleW / 2
  local titleY = layout.titleY
  love.graphics.setBlendMode("add", "alphamultiply")
  love.graphics.setColor(0.7, 0.95, 1.0, 0.12)
  love.graphics.ellipse("fill", screenWidth / 2, titleY + 18, titleW * 0.58, 26)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0.02, 0.04, 0.06, 0.8)
  love.graphics.print(title, titleX + 3, titleY + 3)
  love.graphics.setColor(0.85, 0.97, 1.0, 0.22)
  love.graphics.print(title, titleX + 1, titleY + 1)
  love.graphics.setColor(0.93, 0.97, 0.99, 1)
  love.graphics.print(title, titleX, titleY)
  love.graphics.setColor(0.7, 0.95, 1.0, 0.22)
  love.graphics.line(screenWidth / 2 - 136, titleY + love.graphics.getFont():getHeight() + 8, screenWidth / 2 + 136, titleY + love.graphics.getFont():getHeight() + 8)
  love.graphics.setColor(1, 1, 1, 1)
  
  for i, upgrade in ipairs(self.options) do
    local anim = self.cardAnimations[i] or { y = 0, scale = 1, flipProgress = 0, showFront = true }
    local cardX = layout.startX + (i - 1) * (layout.cardWidth + layout.cardSpacing)
    local isSelected = (i == self.selectedIndex)
    local isHovered = (i == self.hoveredIndex)

    self:drawCard(upgrade, cardX, layout.cardY + anim.y, layout.cardWidth, layout.cardHeight, anim.scale, isSelected or isHovered, i)
  end
  
  -- Instructions
  local instrFont = _G.PixelFonts and _G.PixelFonts.uiTiny or love.graphics.getFont()
  love.graphics.setFont(instrFont)
  local instructions = "[A/D] OR [ARROWS] NAVIGATE    [ENTER] SELECT    [1-3] QUICK PICK"
  local instrWidth = instrFont:getWidth(instructions)
  local instrX = screenWidth / 2 - instrWidth / 2
  local instrY = screenHeight - 48
  love.graphics.setColor(0.02, 0.03, 0.05, 0.48)
  love.graphics.rectangle("fill", instrX - 14, instrY - 5, instrWidth + 28, instrFont:getHeight() + 10, 10, 10)
  love.graphics.setColor(0.45, 0.75, 0.9, 0.18)
  love.graphics.rectangle("line", instrX - 14, instrY - 5, instrWidth + 28, instrFont:getHeight() + 10, 10, 10)
  love.graphics.setColor(0.72, 0.78, 0.82, 1)
  love.graphics.print(instructions, instrX, instrY)
  
  love.graphics.setColor(1, 1, 1, 1)
end

function UpgradeUI:drawBackdropAtmosphere(layout, screenWidth, screenHeight)
  local t = self.showTime

  -- Vignette
  love.graphics.setColor(0, 0, 0, 0.12)
  love.graphics.rectangle("fill", 0, 0, screenWidth, 72)
  love.graphics.rectangle("fill", 0, screenHeight - 84, screenWidth, 84)
  love.graphics.rectangle("fill", 0, 0, 64, screenHeight)
  love.graphics.rectangle("fill", screenWidth - 64, 0, 64, screenHeight)

  -- Central stage light behind the cards.
  love.graphics.setBlendMode("add", "alphamultiply")
  love.graphics.setColor(0.28, 0.6, 0.72, 0.08)
  love.graphics.ellipse("fill", screenWidth / 2, layout.cardY + 82, layout.totalWidth * 0.42, 118)
  love.graphics.setColor(0.4, 0.92, 1.0, 0.04)
  love.graphics.ellipse("fill", screenWidth / 2, layout.cardY + 38, layout.totalWidth * 0.34, 76)
  love.graphics.setBlendMode("alpha")

  -- Floating motes keep the modal from feeling static while paused.
  for i = 1, 16 do
    local phase = t * (0.8 + i * 0.03) + i * 0.7
    local mx = screenWidth * (0.16 + (i % 8) * 0.095) + math.sin(phase) * 14
    local my = layout.cardY - 34 + (i % 4) * 42 + math.cos(phase * 1.2) * 16
    local size = 2 + (i % 3)
    local alpha = 0.16 + 0.08 * math.sin(phase * 1.4)
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(0.55, 0.88, 1.0, alpha)
    love.graphics.rectangle("fill", math.floor(mx), math.floor(my), size, size)
    love.graphics.setBlendMode("alpha")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function UpgradeUI:drawCard(upgrade, x, y, width, height, scale, isSelected, cardIndex)
  local anim = self.cardAnimations[cardIndex]
  local focusScale = isSelected and 1.03 or 1.0
  local focusYOffset = isSelected and -4 or 0

  love.graphics.push()
  love.graphics.translate(x + width / 2, y + height / 2 + focusYOffset)

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

  love.graphics.scale(scale * focusScale * flipScaleX, scale * focusScale)
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
  local metallic = metallicColors[rarity] or metallicColors.common
  local t = love.timer.getTime()
  local upgradeType = getUpgradeType(upgrade)
  local iconKey = getUpgradeIconKey(upgrade)

  local cardFonts = ensureScaledCardFonts()
  local nameFont = cardFonts.name or (_G.PixelFonts and _G.PixelFonts.uiBody) or love.graphics.getFont()
  local descFont = cardFonts.body or (_G.PixelFonts and _G.PixelFonts.uiSmall) or love.graphics.getFont()
  local tagFont  = cardFonts.tag or (_G.PixelFonts and _G.PixelFonts.uiSmallText) or descFont
  
  if isSelected then
    local pulse = 0.72 + 0.28 * math.sin(t * 4.4)
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(glow[1], glow[2], glow[3], glow[4] * pulse)
    love.graphics.rectangle("fill", -10, -8, width + 20, height + 16, 14, 14)
    love.graphics.setBlendMode("alpha")
  end

  -- Drop shadow
  love.graphics.setColor(0, 0, 0, 0.32)
  love.graphics.rectangle("fill", 6, 8, width, height, 12, 12)

  -- Card body
  love.graphics.setColor(0.11, 0.12, 0.17, 0.96)
  love.graphics.rectangle("fill", 0, 0, width, height, 12, 12)
  love.graphics.setColor(0.16, 0.17, 0.23, 0.96)
  love.graphics.rectangle("fill", 4, 4, width - 8, math.floor(height * 0.42), 10, 10)
  love.graphics.setColor(0.07, 0.08, 0.12, 0.92)
  love.graphics.rectangle("fill", 4, math.floor(height * 0.42), width - 8, height - math.floor(height * 0.42) - 4)

  -- Side rarity accents to push the concept-art silhouette.
  love.graphics.setBlendMode("add", "alphamultiply")
  love.graphics.setColor(color[1], color[2], color[3], isSelected and 0.12 or 0.06)
  love.graphics.polygon("fill", 8, 52, 28, 38, 28, 124, 8, 138)
  love.graphics.polygon("fill", width - 8, 52, width - 28, 38, width - 28, 124, width - 8, 138)
  love.graphics.setBlendMode("alpha")

  -- Outer and inner frame
  love.graphics.setLineWidth(isSelected and 2.5 or 1.8)
  love.graphics.setColor(metallic[1], metallic[2], metallic[3], isSelected and 1 or 0.9)
  love.graphics.rectangle("line", 0, 0, width, height, 12, 12)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 0.08)
  love.graphics.rectangle("line", 3, 3, width - 6, height - 6, 10, 10)

  -- Small rarity plaque instead of a full-width top strip.
  local plaqueW = 74
  local plaqueX = width / 2 - plaqueW / 2
  love.graphics.setColor(0.08, 0.09, 0.12, 0.95)
  love.graphics.rectangle("fill", plaqueX, 10, plaqueW, 18, 8, 8)
  love.graphics.setColor(color[1], color[2], color[3], 0.26)
  love.graphics.rectangle("fill", plaqueX + 2, 12, plaqueW - 4, 6, 6, 6)
  love.graphics.setColor(color[1], color[2], color[3], 0.9)
  love.graphics.setFont(tagFont)
  local rarityText = string.upper(rarity)
  local font = love.graphics.getFont()
  local rarityWidth = font:getWidth(rarityText)
  love.graphics.print(rarityText, width / 2 - rarityWidth / 2, 14)

  -- Icon altar
  local iconBoxSize = 74
  local iconBoxX = width / 2 - iconBoxSize / 2
  local iconBoxY = 40
  love.graphics.setColor(0.09, 0.1, 0.14, 0.95)
  love.graphics.rectangle("fill", iconBoxX, iconBoxY, iconBoxSize, iconBoxSize, 12, 12)
  love.graphics.setBlendMode("add", "alphamultiply")
  love.graphics.setColor(color[1], color[2], color[3], 0.18 + 0.05 * math.sin(t * 3.2))
  love.graphics.rectangle("fill", iconBoxX + 4, iconBoxY + 4, iconBoxSize - 8, iconBoxSize - 8, 10, 10)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(color[1], color[2], color[3], 0.8)
  love.graphics.rectangle("line", iconBoxX, iconBoxY, iconBoxSize, iconBoxSize, 12, 12)
  love.graphics.setColor(1, 1, 1, 0.07)
  love.graphics.rectangle("line", iconBoxX + 3, iconBoxY + 3, iconBoxSize - 6, iconBoxSize - 6, 10, 10)

  local emblemCX = width / 2
  local emblemCY = iconBoxY + iconBoxSize / 2
  local emblemR = 21
  love.graphics.setColor(0.96, 0.98, 1.0, 1)
  self:drawUpgradeIcon(iconKey, emblemCX, emblemCY, emblemR)

  -- Upgrade name (below icon)
  love.graphics.setFont(nameFont)
  font = love.graphics.getFont()
  local name = truncateToWidth(string.upper(upgrade.name or "Unknown"), width - 24, font, "...")
  local nameWidth = font:getWidth(name)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.print(name, width / 2 - nameWidth / 2 + 1, 125)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(name, width / 2 - nameWidth / 2, 124)

  -- Type line
  love.graphics.setFont(tagFont)
  font = love.graphics.getFont()
  local typeText = string.upper(upgradeType)
  local typeWidth = font:getWidth(typeText)
  love.graphics.setColor(color[1], color[2], color[3], 0.95)
  love.graphics.print(typeText, width / 2 - typeWidth / 2, 148)
  
  -- Separator
  love.graphics.setColor(color[1], color[2], color[3], 0.28)
  love.graphics.line(18, 168, width - 18, 168)
  
  -- Description
  love.graphics.setFont(descFont)
  font = love.graphics.getFont()
  love.graphics.setColor(0.84, 0.86, 0.9, 1)
  local description = self:getUpgradeDescription(upgrade)
  
  local textX = 16
  local maxWidth = width - 32
  local lineHeight = font:getHeight() + 4
  local tagY = height - 28
  local lines = self:wrapText(description, maxWidth)
  local lineY = 182
  local maxLines = math.max(1, math.floor((tagY - lineY) / lineHeight))
  for i, line in ipairs(lines) do
    if i > maxLines then break end
    if i == maxLines and #lines > maxLines then
      line = truncateToWidth(line, maxWidth, font, "...")
    end
    love.graphics.print(line, textX, lineY)
    lineY = lineY + lineHeight
  end
  
  -- Current -> next preview
  if self.playerStats and self.playerStats.hasUpgrade and self.playerStats:hasUpgrade(upgrade.id) then
    local preview = self:getCurrentNextPreview(upgrade)
    if preview and preview ~= "" then
      love.graphics.setColor(0.4, 0.9, 0.5, 1)
      local previewLines = self:wrapText(preview, maxWidth)
      local remainingLines = math.max(0, math.floor((tagY - lineY) / lineHeight))
      for i, line in ipairs(previewLines) do
        if i > remainingLines then break end
        if i == remainingLines and #previewLines > remainingLines then
          line = truncateToWidth(line, maxWidth, font, "...")
        end
        love.graphics.print(line, textX, lineY)
        lineY = lineY + lineHeight
      end
    end
  end
  
  -- Decorative bottom accent line
  love.graphics.setColor(color[1], color[2], color[3], 0.22)
  love.graphics.line(18, height - 30, width - 18, height - 30)

  -- Tags at bottom
  if upgrade.tags and #upgrade.tags > 0 then
    love.graphics.setFont(tagFont)
    font = love.graphics.getFont()
    love.graphics.setColor(0.55, 0.6, 0.66, 0.9)
    local tagText = table.concat(upgrade.tags, "  ")
    tagText = truncateToWidth(string.upper(tagText), width - 20, font, "...")
    if tagText ~= "" then
      local tagWidth = font:getWidth(tagText)
      love.graphics.print(tagText, width / 2 - tagWidth / 2, height - 22)
    end
  end
end

function UpgradeUI:drawUpgradeIcon(iconKey, cx, cy, r)
  -- Procedural icons: boot, flame, snowflake, bolt, arrow, target, magnet, blood, star
  if iconKey == "boot" then
    love.graphics.polygon("fill", cx-r*0.58, cy+r*0.25, cx+r*0.48, cy+r*0.25, cx+r*0.3, cy-r*0.48, cx-r*0.18, cy-r*0.48, cx-r*0.48, cy-r*0.08)
  elseif iconKey == "flame" then
    love.graphics.polygon("fill", cx, cy-r, cx+r*0.5, cy-r*0.2, cx+r*0.4, cy+r*0.4, cx+r*0.1, cy+r, cx-r*0.1, cy+r*0.38, cx-r*0.34, cy+r, cx-r*0.46, cy+r*0.2, cx-r*0.24, cy-r*0.26)
  elseif iconKey == "snowflake" then
    for i = 0, 5 do
      local a = i * math.pi / 3
      love.graphics.line(cx + math.cos(a)*r*0.3, cy + math.sin(a)*r*0.3, cx + math.cos(a)*r, cy + math.sin(a)*r)
    end
  elseif iconKey == "bolt" then
    love.graphics.polygon("fill", cx+r*0.18, cy-r, cx-r*0.34, cy-r*0.1, cx-r*0.05, cy-r*0.1, cx-r*0.3, cy+r, cx+r*0.38, cy+r*0.05, cx+r*0.08, cy+r*0.05)
  elseif iconKey == "arrow" then
    love.graphics.setLineWidth(3)
    love.graphics.line(cx-r*0.8, cy+r*0.55, cx+r*0.65, cy-r*0.55)
    love.graphics.setLineWidth(1)
    love.graphics.polygon("fill", cx+r*0.22, cy-r*0.8, cx+r*0.72, cy-r*0.52, cx+r*0.36, cy-r*0.18)
  elseif iconKey == "target" then
    love.graphics.circle("line", cx, cy, r*0.8)
    love.graphics.circle("line", cx, cy, r*0.4)
    love.graphics.circle("fill", cx, cy, r*0.15)
  elseif iconKey == "magnet" then
    love.graphics.rectangle("fill", cx-r*0.5, cy-r*0.6, r, r*0.4, 2, 2)
    love.graphics.rectangle("fill", cx-r*0.5, cy+r*0.2, r, r*0.4, 2, 2)
  elseif iconKey == "blood" then
    love.graphics.circle("fill", cx, cy, r*0.5)
    love.graphics.polygon("fill", cx-r*0.3, cy+r*0.5, cx+r*0.3, cy+r*0.5, cx, cy+r)
  else
    -- star (default): diamond
    love.graphics.polygon("fill", cx, cy-r, cx+r*0.7, cy, cx, cy+r, cx-r*0.7, cy)
  end
end

function UpgradeUI:drawCardBack(width, height, isSelected)
  local pulse = 0.75 + 0.25 * math.sin(self.showTime * 5)
  love.graphics.setColor(0.09, 0.1, 0.15, 0.96)
  love.graphics.rectangle("fill", 0, 0, width, height, 12, 12)
  love.graphics.setColor(0.14, 0.16, 0.21, 0.95)
  love.graphics.rectangle("fill", 4, 4, width - 8, height - 8, 10, 10)
  love.graphics.setBlendMode("add", "alphamultiply")
  love.graphics.setColor(0.45, 0.65, 0.9, 0.08 * pulse)
  love.graphics.rectangle("fill", 14, 18, width - 28, height - 36, 14, 14)
  love.graphics.setBlendMode("alpha")

  local oldFont = love.graphics.getFont()
  love.graphics.setNewFont(56)
  local text = "?"
  local font = love.graphics.getFont()
  local tw = font:getWidth(text)
  love.graphics.setColor(0.75, 0.82, 0.92, 0.75)
  love.graphics.print(text, width/2 - tw/2, height/2 - 36)
  love.graphics.setFont(oldFont)

  if isSelected then
    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.62, 0.76, 0.98, 1)
  else
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.42, 0.48, 0.6, 1)
  end
  love.graphics.rectangle("line", 0, 0, width, height, 12, 12)
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
  local layout = getCardLayout(#self.options, screenWidth, screenHeight)
  
  for i = 1, #self.options do
    local cardX = layout.startX + (i - 1) * (layout.cardWidth + layout.cardSpacing)
    if x >= cardX and x <= cardX + layout.cardWidth and
       y >= layout.cardY and y <= layout.cardY + layout.cardHeight then
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


