-- ui/stats_overlay.lua
-- Run stats overlay (toggle with Tab). Shows computed stats and acquired upgrades.

local StatsOverlay = {}
StatsOverlay.__index = StatsOverlay

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function pct(x)
  return string.format("%.0f%%", (x or 0) * 100)
end

local function num(x)
  if x == nil then return "-" end
  if math.abs(x) >= 100 then return string.format("%.0f", x) end
  return string.format("%.2f", x)
end

local function fitText(font, text, maxWidth)
  text = tostring(text or "")
  if not font or font:getWidth(text) <= maxWidth then
    return text
  end

  local trimmed = text
  while #trimmed > 0 and font:getWidth(trimmed .. "...") > maxWidth do
    trimmed = trimmed:sub(1, -2)
  end

  if trimmed == "" then
    return "..."
  end
  return trimmed .. "..."
end

function StatsOverlay:new()
  local o = setmetatable({
    visible = false,
    scrollIndex = 1,
    fontTitle = nil,
    fontBody = nil,
    fontSmall = nil,
  }, StatsOverlay)
  return o
end

function StatsOverlay:isVisible()
  return self.visible
end

function StatsOverlay:toggle()
  self.visible = not self.visible
end

function StatsOverlay:scroll(delta, upgradeCount)
  upgradeCount = upgradeCount or 0
  if upgradeCount <= 0 then
    self.scrollIndex = 1
    return
  end
  self.scrollIndex = clamp(self.scrollIndex + delta, 1, upgradeCount)
end

local FONT_PATH = "assets/Other/Fonts/Kenney Pixel.ttf"

local function ensureFonts(self)
  if not self.fontTitle then
    local ok, f
    local function loadUI(size)
      ok, f = pcall(love.graphics.newFont, FONT_PATH, size)
      if ok then
        f:setFilter("linear", "linear")
        return f
      end
      f = love.graphics.newFont(size)
      f:setFilter("linear", "linear")
      return f
    end

    self.fontTitle = loadUI(22)
    self.fontBody = loadUI(15)
    self.fontSmall = loadUI(13)
  end
end

local function drawPanel(x, y, w, h)
  love.graphics.setColor(0, 0, 0, 0.78)
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)
  love.graphics.setColor(0.6, 0.75, 1, 0.4)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, w, h, 10, 10)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
end

local function rarityColor(rarity)
  if rarity == "epic" then return 0.75, 0.45, 1.0 end
  if rarity == "rare" then return 0.35, 0.7, 1.0 end
  return 0.85, 0.85, 0.85
end

local function groupAbilityUpgrades(upgrades)
  local abilityUpgrades = {
    multi_shot = {},
    arrow_volley = {},
    frenzy = {},
    other = {},
  }

  for _, upgrade in ipairs(upgrades) do
    if not upgrade.effects then
      table.insert(abilityUpgrades.other, upgrade)
    else
      local hasAbilityMod = false
      for _, effect in ipairs(upgrade.effects) do
        if effect.kind == "ability_mod" and abilityUpgrades[effect.ability] then
          table.insert(abilityUpgrades[effect.ability], upgrade)
          hasAbilityMod = true
          break
        end
      end
      if not hasAbilityMod then
        table.insert(abilityUpgrades.other, upgrade)
      end
    end
  end

  return abilityUpgrades
end

function StatsOverlay:draw(playerStats, xpSystem, player)
  if not self.visible or not playerStats then
    return
  end

  ensureFonts(self)
  local getStat = playerStats.getPermanent and function(stat)
    return playerStats:getPermanent(stat)
  end or function(stat)
    return playerStats:get(stat)
  end

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local pad = 24
  local panelW = math.min(900, sw - pad * 2)
  local panelH = math.min(560, sh - pad * 2)
  local x = (sw - panelW) / 2
  local y = (sh - panelH) / 2

  drawPanel(x, y, panelW, panelH)

  love.graphics.setFont(self.fontTitle)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("CHARACTER", x + 16, y + 12)

  love.graphics.setFont(self.fontSmall)
  love.graphics.setColor(1, 1, 1, 0.75)
  local levelText = xpSystem and ("Level " .. tostring(xpSystem.level)) or ""
  local closeText = levelText .. "  (Press Tab to close)"
  love.graphics.print(closeText, x + panelW - self.fontSmall:getWidth(closeText) - 16, y + 18)

  local contentY = y + 56
  local colGap = 24
  local col1W = 240
  local col2W = 250
  local col3W = panelW - col1W - col2W - colGap * 2 - 32

  local col1X = x + 16
  local col2X = col1X + col1W + colGap
  local col3X = col2X + col2W + colGap

  love.graphics.setFont(self.fontBody)
  love.graphics.setColor(0.5, 0.8, 1, 1)
  love.graphics.print("STATS", col1X, contentY)

  local lineY = contentY + 24
  local lineH = 18
  local statBaseX = col1X + 108
  local statArrowX = col1X + 144
  local statCurrentX = col1X + 172

  local statsOrder = {
    { key = "primary_damage", label = "Damage", fmt = num },
    { key = "attack_speed", label = "Attack Speed", fmt = num },
    { key = "move_speed", label = "Move Speed", fmt = num },
    { key = "range", label = "Range", fmt = num },
    { key = "crit_chance", label = "Crit Chance", fmt = pct },
    { key = "crit_damage", label = "Crit Damage", fmt = function(v) return string.format("%.2fx", v or 0) end },
    { key = "roll_cooldown", label = "Roll CD", fmt = function(v) return string.format("%.2fs", v or 0) end },
    { key = "xp_pickup_radius", label = "XP Radius", fmt = num },
  }

  love.graphics.setFont(self.fontSmall)
  for _, s in ipairs(statsOrder) do
    local base = playerStats:getBase(s.key)
    local current = getStat(s.key)
    local delta = current - base

    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.print(fitText(self.fontSmall, s.label, 98), col1X, lineY)

    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(s.fmt(base), statBaseX, lineY)

    if math.abs(delta) > 0.01 then
      love.graphics.setColor(0.6, 0.6, 0.6, 1)
      love.graphics.print(" -> ", statArrowX, lineY)

      if delta > 0 then
        love.graphics.setColor(0.3, 1, 0.3, 1)
      elseif delta < 0 then
        love.graphics.setColor(1, 0.4, 0.4, 1)
      else
        love.graphics.setColor(1, 1, 1, 1)
      end
      love.graphics.print(s.fmt(current), statCurrentX, lineY)
    end

    lineY = lineY + lineH
  end

  lineY = lineY + 12
  love.graphics.setFont(self.fontBody)
  love.graphics.setColor(0.5, 0.8, 1, 1)
  love.graphics.print("WEAPON MODS", col1X, lineY)
  lineY = lineY + 24

  love.graphics.setFont(self.fontSmall)
  local weaponMods = {
    { label = "Pierce", key = "pierce", base = 0 },
    { label = "Ricochet", key = "ricochet_bounces", base = 0 },
    { label = "Bonus Proj", key = "bonus_projectiles", base = 0 },
  }

  for _, mod in ipairs(weaponMods) do
    local current = playerStats:getWeaponMod(mod.key)

    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.print(mod.label, col1X, lineY)

    if current > mod.base then
      love.graphics.setColor(0.7, 0.7, 0.7, 1)
      love.graphics.print(tostring(mod.base), statBaseX, lineY)
      love.graphics.setColor(0.6, 0.6, 0.6, 1)
      love.graphics.print(" -> ", statArrowX, lineY)
      love.graphics.setColor(0.3, 1, 0.3, 1)
      love.graphics.print(tostring(current), statCurrentX, lineY)
    else
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(tostring(current), statBaseX, lineY)
    end

    lineY = lineY + lineH
  end

  if player and player.statusComponent then
    local activeBuffs = player.statusComponent:getActiveBuffs()
    if #activeBuffs > 0 then
      lineY = lineY + 12
      love.graphics.setFont(self.fontBody)
      love.graphics.setColor(0.5, 0.8, 1, 1)
      love.graphics.print("ACTIVE BUFFS", col1X, lineY)
      lineY = lineY + 24
      love.graphics.setFont(self.fontSmall)
      for _, buff in ipairs(activeBuffs) do
        local r, g, b = 1, 1, 1
        if buff.color and type(buff.color) == "table" then
          r = buff.color[1] or 1
          g = buff.color[2] or 1
          b = buff.color[3] or 1
        end
        love.graphics.setColor(r, g, b, 1)
        local name = buff.display_name or buff.name or "Buff"
        local timeStr = buff.duration and string.format(" (%.1fs)", buff.duration) or ""
        love.graphics.print("  " .. fitText(self.fontSmall, name .. timeStr, col1W - 12), col1X, lineY)
        lineY = lineY + lineH
      end
    end
  end

  love.graphics.setFont(self.fontBody)
  love.graphics.setColor(1, 0.7, 0.3, 1)
  love.graphics.print("ABILITY UPGRADES", col2X, contentY)

  local upgrades = (playerStats.getUpgradeLog and playerStats:getUpgradeLog()) or {}
  local grouped = groupAbilityUpgrades(upgrades)

  local abilityY = contentY + 24
  local abilityLineH = 16

  love.graphics.setFont(self.fontSmall)
  love.graphics.setColor(0.9, 0.6, 0.2, 1)
  love.graphics.print("Multi Shot [Q]", col2X, abilityY)
  abilityY = abilityY + 18
  if #grouped.multi_shot == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("  No upgrades", col2X, abilityY)
    abilityY = abilityY + abilityLineH
  else
    for _, u in ipairs(grouped.multi_shot) do
      local r, g, b = rarityColor(u.rarity)
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print("  " .. fitText(self.fontSmall, u.name or "Unknown", col2W - 10), col2X, abilityY)
      abilityY = abilityY + abilityLineH
    end
  end

  abilityY = abilityY + 8
  love.graphics.setColor(0.9, 0.6, 0.2, 1)
  love.graphics.print("Arrow Volley [E]", col2X, abilityY)
  abilityY = abilityY + 18
  if #grouped.arrow_volley == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("  No upgrades", col2X, abilityY)
    abilityY = abilityY + abilityLineH
  else
    for _, u in ipairs(grouped.arrow_volley) do
      local r, g, b = rarityColor(u.rarity)
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print("  " .. fitText(self.fontSmall, u.name or "Unknown", col2W - 10), col2X, abilityY)
      abilityY = abilityY + abilityLineH
    end
  end

  abilityY = abilityY + 8
  love.graphics.setColor(0.9, 0.6, 0.2, 1)
  love.graphics.print("Frenzy [R]", col2X, abilityY)
  abilityY = abilityY + 18
  if #grouped.frenzy == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("  No upgrades", col2X, abilityY)
    abilityY = abilityY + abilityLineH
  else
    for _, u in ipairs(grouped.frenzy) do
      local r, g, b = rarityColor(u.rarity)
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print("  " .. fitText(self.fontSmall, u.name or "Unknown", col2W - 10), col2X, abilityY)
      abilityY = abilityY + abilityLineH
    end
  end

  love.graphics.setFont(self.fontBody)
  love.graphics.setColor(0.5, 1, 0.5, 1)
  love.graphics.print("STAT UPGRADES", col3X, contentY)

  local total = #grouped.other
  love.graphics.setFont(self.fontSmall)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print(("Total: %d (Up/Down to scroll)"):format(total), col3X, contentY + 18)

  local listY = contentY + 40
  local listBottom = y + panelH - 16
  local maxLines = math.floor((listBottom - listY) / abilityLineH)
  maxLines = math.max(10, maxLines)

  if total <= 0 then
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("No stat upgrades yet.", col3X, listY)
  else
    self.scrollIndex = clamp(self.scrollIndex, 1, total)
    local startIdx = self.scrollIndex
    local endIdx = math.min(total, startIdx + maxLines - 1)
    local yy = listY

    for i = startIdx, endIdx do
      local u = grouped.other[i]
      local r, g, b = rarityColor(u.rarity)
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print(fitText(self.fontSmall, u.name or u.id or "Unknown", col3W - 8), col3X, yy)
      yy = yy + abilityLineH
    end

    if endIdx < total then
      love.graphics.setColor(1, 1, 1, 0.6)
      love.graphics.print(("... %d more"):format(total - endIdx), col3X, yy + 4)
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return StatsOverlay
