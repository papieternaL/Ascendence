-- systems/xp_system.lua
-- Handles experience points, leveling, and XP orbs

local XpSystem = {}
XpSystem.__index = XpSystem

function XpSystem:new()
  local system = setmetatable({
    xp = 0,
    level = 1,
    xpToNextLevel = 100,
    
    -- XP scaling per level
    baseXpRequired = 100,
    xpScaling = 1.15,  -- Each level requires 15% more XP
    
    -- Pending level-ups (player must select upgrades)
    pendingLevelUps = 0,
    
    -- XP orbs floating in the world
    orbs = {},

    -- Magnet pickups that vacuum every orb on the map when collected
    magnets = {},
  }, XpSystem)
  return system
end

function XpSystem:addXp(amount)
  self.xp = self.xp + amount
  
  -- Check for level up(s)
  while self.xp >= self.xpToNextLevel do
    self.xp = self.xp - self.xpToNextLevel
    self.level = self.level + 1
    self.pendingLevelUps = self.pendingLevelUps + 1
    
    -- Calculate next level XP requirement
    self.xpToNextLevel = math.floor(self.baseXpRequired * (self.xpScaling ^ (self.level - 1)))
  end
end

function XpSystem:hasPendingLevelUp()
  return self.pendingLevelUps > 0
end

function XpSystem:consumeLevelUp()
  if self.pendingLevelUps > 0 then
    self.pendingLevelUps = self.pendingLevelUps - 1
    return true
  end
  return false
end

function XpSystem:getProgress()
  return self.xp / self.xpToNextLevel
end

-- Spawn an XP orb at a position
function XpSystem:spawnOrb(x, y, value)
  local Config = require("data.config")
  local mult = Config.xp_drop_multiplier or 1.0
  value = math.max(1, math.floor((value or 10) * mult))
  table.insert(self.orbs, {
    x = x,
    y = y,
    value = value,
    vx = (math.random() - 0.5) * 100,
    vy = (math.random() - 0.5) * 100,
    lifetime = 0,
    collected = false,
    attracted = false,  -- Once true, orb always homes to player until collected
    
    -- Visual properties
    size = 6 + math.random() * 4,
    pulsePhase = math.random() * math.pi * 2,
  })
end

function XpSystem:spawnMagnet(x, y)
  table.insert(self.magnets, {
    x = x,
    y = y,
    vx = (math.random() - 0.5) * 80,
    vy = (math.random() - 0.5) * 80,
    lifetime = 0,
    collected = false,
    size = 14 + math.random() * 3,
    pulsePhase = math.random() * math.pi * 2,
  })
end

function XpSystem:activateMagnet()
  for _, orb in ipairs(self.orbs) do
    orb.attracted = true
    orb.magnetBoost = 1.8
    orb.vx = orb.vx * 0.3
    orb.vy = orb.vy * 0.3
  end
end

-- Update XP orbs (physics, collection)
function XpSystem:update(dt, playerX, playerY, pickupRadius)
  pickupRadius = pickupRadius or 63
  
  local toRemove = {}

  local magnetsToRemove = {}
  for i, magnet in ipairs(self.magnets) do
    magnet.lifetime = magnet.lifetime + dt
    magnet.vx = magnet.vx * 0.92
    magnet.vy = magnet.vy * 0.92

    local dx = playerX - magnet.x
    local dy = playerY - magnet.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local pullRadius = pickupRadius * 1.35

    if dist < pullRadius and dist > 0 then
      local pull = 520 * (1 - math.min(1, dist / pullRadius))
      magnet.vx = magnet.vx + (dx / dist) * pull * dt * 8
      magnet.vy = magnet.vy + (dy / dist) * pull * dt * 8
    end

    magnet.x = magnet.x + magnet.vx * dt
    magnet.y = magnet.y + magnet.vy * dt

    if dist < 26 then
      self:activateMagnet()
      magnet.collected = true
      magnetsToRemove[#magnetsToRemove + 1] = i
    elseif magnet.lifetime > 18 then
      magnetsToRemove[#magnetsToRemove + 1] = i
    end
  end
  
  for i, orb in ipairs(self.orbs) do
    orb.lifetime = orb.lifetime + dt
    if orb.magnetBoost then
      orb.magnetBoost = math.max(1, orb.magnetBoost - dt * 0.9)
      if orb.magnetBoost <= 1.01 then
        orb.magnetBoost = nil
      end
    end
    
    -- Friction on initial velocity
    orb.vx = orb.vx * 0.95
    orb.vy = orb.vy * 0.95
    
    -- Move toward player if within pickup radius or once attracted (sticky)
    local dx = playerX - orb.x
    local dy = playerY - orb.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist < pickupRadius * 2 then
      orb.attracted = true
    end
    if orb.attracted or dist < pickupRadius * 2 then
      -- Accelerate toward player (much faster snap once in proximity)
      local speed = 800 * (1 - math.min(1, dist / (pickupRadius * 2)))
      speed = math.max(speed, orb.attracted and 500 or 100)
      speed = speed * (orb.magnetBoost or 1)
      
      if dist > 0 then
        orb.vx = orb.vx + (dx / dist) * speed * dt * 18.0
        orb.vy = orb.vy + (dy / dist) * speed * dt * 18.0
      end
    end
    
    -- Apply velocity
    orb.x = orb.x + orb.vx * dt
    orb.y = orb.y + orb.vy * dt
    
    -- Check collection
    if dist < 20 then
      self:addXp(orb.value)
      orb.collected = true
      toRemove[#toRemove+1] = i
    end
    
    -- Remove old uncollected orbs
    if orb.lifetime > 30 then
      toRemove[#toRemove+1] = i
    end
  end
  
  -- Remove collected/expired orbs (iterate backwards)
  for i = #toRemove, 1, -1 do
    table.remove(self.orbs, toRemove[i])
  end

  for i = #magnetsToRemove, 1, -1 do
    table.remove(self.magnets, magnetsToRemove[i])
  end
end

function XpSystem:draw()
  for _, magnet in ipairs(self.magnets) do
    local pulse = math.sin(love.timer.getTime() * 4 + magnet.pulsePhase) * 0.25 + 0.75
    local size = magnet.size * pulse

    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(0.3, 1.0, 0.9, 0.18)
    love.graphics.circle("fill", magnet.x, magnet.y, size * 1.9)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(0.18, 0.55, 0.42, 0.95)
    love.graphics.circle("fill", magnet.x, magnet.y, size)

    love.graphics.setColor(0.82, 1.0, 0.96, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", magnet.x, magnet.y, size * 0.9)

    love.graphics.setColor(0.95, 1.0, 1.0, 0.9)
    love.graphics.rectangle("fill", magnet.x - size * 0.18, magnet.y - size * 0.55, size * 0.36, size * 1.1, 2, 2)
    love.graphics.rectangle("fill", magnet.x - size * 0.55, magnet.y - size * 0.18, size * 1.1, size * 0.36, 2, 2)
  end

  for _, orb in ipairs(self.orbs) do
    local pulse = math.sin(love.timer.getTime() * 6 + orb.pulsePhase) * 0.3 + 0.7
    local size = orb.size * pulse
    
    -- Glow effect
    love.graphics.setColor(0.3, 0.8, 1, 0.3)
    love.graphics.circle("fill", orb.x, orb.y, size * 1.5)
    
    -- Core
    love.graphics.setColor(0.5, 0.9, 1, 1)
    love.graphics.circle("fill", orb.x, orb.y, size)
    
    -- Bright center
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", orb.x, orb.y, size * 0.4)
  end
  
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
end

return XpSystem












