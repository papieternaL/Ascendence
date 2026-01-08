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
  table.insert(self.orbs, {
    x = x,
    y = y,
    value = value or 10,
    vx = (math.random() - 0.5) * 100,
    vy = (math.random() - 0.5) * 100,
    lifetime = 0,
    collected = false,
    
    -- Visual properties
    size = 6 + math.random() * 4,
    pulsePhase = math.random() * math.pi * 2,
  })
end

-- Update XP orbs (physics, collection)
function XpSystem:update(dt, playerX, playerY, pickupRadius)
  pickupRadius = pickupRadius or 60
  
  local toRemove = {}
  
  for i, orb in ipairs(self.orbs) do
    orb.lifetime = orb.lifetime + dt
    
    -- Friction on initial velocity
    orb.vx = orb.vx * 0.95
    orb.vy = orb.vy * 0.95
    
    -- Move toward player if within pickup radius
    local dx = playerX - orb.x
    local dy = playerY - orb.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist < pickupRadius * 2 then
      -- Accelerate toward player
      local speed = 400 * (1 - dist / (pickupRadius * 2))
      speed = math.max(speed, 100)
      
      if dist > 0 then
        orb.vx = orb.vx + (dx / dist) * speed * dt * 5
        orb.vy = orb.vy + (dy / dist) * speed * dt * 5
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
end

function XpSystem:draw()
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
  
  love.graphics.setColor(1, 1, 1, 1)
end

return XpSystem












