-- ui/stats_overlay.lua
-- Run stats overlay (toggle with Tab). Shows computed stats + acquired upgrades.

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

function StatsOverlay:new()
  local o = setmetatable({
    visible = false,
    scrollIndex = 1, -- 1-based index into acquired upgrade log
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

local function ensureFonts(self)
  if not self.fontTitle then
    self.fontTitle = love.graphics.newFont(20)
    self.fontBody = love.graphics.newFont(13)
    self.fontSmall = love.graphics.newFont(11)
  end
end

local function drawPanel(x, y, w, h)
  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)
  love.graphics.setColor(0.6, 0.75, 1, 0.35)
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

function StatsOverlay:draw(playerStats, xpSystem)
  if not self.visible then return end
  if not playerStats then return end

  ensureFonts(self)
  local getStat = playerStats.getPermanent and function(stat) return playerStats:getPermanent(stat) end
    or function(stat) return playerStats:get(stat) end

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local pad = 18
  local panelW = math.min(760, sw - pad * 2)
  local panelH = math.min(520, sh - pad * 2)
  local x = (sw - panelW) / 2
  local y = (sh - panelH) / 2

  drawPanel(x, y, panelW, panelH)

  -- Header
  love.graphics.setFont(self.fontTitle)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("RUN STATS", x + 16, y + 12)

  love.graphics.setFont(self.fontSmall)
  love.graphics.setColor(1, 1, 1, 0.75)
  local levelText = xpSystem and ("Level " .. tostring(xpSystem.level)) or ""
  love.graphics.print(levelText, x + panelW - 140, y + 18)

  -- Columns
  local colGap = 18
  local leftW = math.floor(panelW * 0.42)
  local rightW = panelW - leftW - colGap - 32
  local leftX = x + 16
  local rightX = leftX + leftW + colGap
  local contentY = y + 52
  local contentH = panelH - 68

  -- Left: key stats
  love.graphics.setFont(self.fontBody)
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Stats", leftX, contentY)

  local lineY = contentY + 22
  local lineH = 18

  local statsOrder = {
    { key="primary_damage", label="Primary Damage", fmt=num },
    { key="attack_speed", label="Attack Speed", fmt=num },
    { key="move_speed", label="Move Speed", fmt=num },
    { key="range", label="Range", fmt=num },
    { key="crit_chance", label="Crit Chance", fmt=pct },
    { key="crit_damage", label="Crit Damage", fmt=function(v) return string.format("%.2fx", v or 0) end },
    { key="roll_cooldown", label="Roll Cooldown", fmt=function(v) return string.format("%.2fs", v or 0) end },
    { key="xp_pickup_radius", label="XP Pickup Radius", fmt=num },
  }

  for _, s in ipairs(statsOrder) do
    local v = getStat(s.key)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.print(s.label .. ":", leftX, lineY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(s.fmt(v), leftX + 170, lineY)
    lineY = lineY + lineH
  end

  -- Weapon mods summary
  lineY = lineY + 8
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Weapon Mods", leftX, lineY)
  lineY = lineY + 22

  local pierce = playerStats:getWeaponMod("pierce")
  local bounces = playerStats:getWeaponMod("ricochet_bounces")
  local bonusProj = playerStats:getWeaponMod("bonus_projectiles")
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.print("Pierce:", leftX, lineY); love.graphics.setColor(1, 1, 1, 1); love.graphics.print(tostring(pierce), leftX + 170, lineY); lineY = lineY + lineH
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.print("Ricochet Bounces:", leftX, lineY); love.graphics.setColor(1, 1, 1, 1); love.graphics.print(tostring(bounces), leftX + 170, lineY); lineY = lineY + lineH
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.print("Bonus Projectiles:", leftX, lineY); love.graphics.setColor(1, 1, 1, 1); love.graphics.print(tostring(bonusProj), leftX + 170, lineY); lineY = lineY + lineH

  -- Right: acquired upgrades list
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Upgrades This Run", rightX, contentY)

  local upgrades = (playerStats.getUpgradeLog and playerStats:getUpgradeLog()) or {}
  local total = #upgrades
  love.graphics.setFont(self.fontSmall)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print(("Total: %d   (Tab to close, ↑/↓ to scroll)"):format(total), rightX, contentY + 18)

  love.graphics.setFont(self.fontBody)
  local listY = contentY + 44
  local listBottom = y + panelH - 16
  local maxLines = math.floor((listBottom - listY) / 18)
  maxLines = math.max(3, maxLines)

  -- Keep scrollIndex valid
  if total <= 0 then
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("No upgrades yet.", rightX, listY)
  else
    self.scrollIndex = clamp(self.scrollIndex, 1, total)
    local startIdx = self.scrollIndex
    local endIdx = math.min(total, startIdx + maxLines - 1)

    local yy = listY
    for i = startIdx, endIdx do
      local u = upgrades[i]
      local r, g, b = rarityColor(u.rarity)
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print(string.upper(u.rarity or "common"), rightX, yy)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(u.name or u.id or "Unknown", rightX + 80, yy)
      yy = yy + 18
    end

    -- Scroll hint
    if endIdx < total then
      love.graphics.setFont(self.fontSmall)
      love.graphics.setColor(1, 1, 1, 0.6)
      love.graphics.print(("... %d more"):format(total - endIdx), rightX, yy + 4)
      love.graphics.setFont(self.fontBody)
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return StatsOverlay


