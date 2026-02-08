-- Treent Enemy - Tanky forest bruiser
-- NOTE: Sprite visuals intentionally removed. Will be re-implemented
-- in the visual overhaul phase to match Ember Knights pixel art direction.
local StatusEffects = require("systems.status_effects")

local Treent = {}
Treent.__index = Treent

function Treent:new(x, y)
  local t = {
    x = x or 0,
    y = y or 0,
    size = 22,
    speed = 28,
    maxHealth = 140,
    health = 140,
    isAlive = true,
    damage = 18,

    flashTime = 0,
    flashDuration = 0.12,
    knockbackX = 0,
    knockbackY = 0,
    knockbackDecay = 7,

    rootedTime = 0,
    rootedDamageTakenMul = 1.0,
    statuses = {},
  }
  setmetatable(t, Treent)
  return t
end

function Treent:update(dt, playerX, playerY)
  if not self.isAlive then return end

  if self.flashTime > 0 then
    self.flashTime = self.flashTime - dt
  end

  self.knockbackX = self.knockbackX * (1 - self.knockbackDecay * dt)
  self.knockbackY = self.knockbackY * (1 - self.knockbackDecay * dt)

  if self.rootedTime and self.rootedTime > 0 then
    self.rootedTime = math.max(0, self.rootedTime - dt)
    if self.rootedTime <= 0 then
      self.rootedDamageTakenMul = 1.0
    end
    self.x = self.x + (self.knockbackX * dt)
    self.y = self.y + (self.knockbackY * dt)
    return
  end

  if playerX and playerY then
    local dx = playerX - self.x
    local dy = playerY - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
      dx = dx / dist
      dy = dy / dist
      self.x = self.x + (dx * self.speed * dt) + (self.knockbackX * dt)
      self.y = self.y + (dy * self.speed * dt) + (self.knockbackY * dt)
    end
  end

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  self.x = math.max(self.size, math.min(sw - self.size, self.x))
  self.y = math.max(self.size, math.min(sh - self.size, self.y))
end

function Treent:takeDamage(damage, hitX, hitY, knockbackForce)
  if not self.isAlive then return false end

  local mul = (self.rootedTime and self.rootedTime > 0) and (self.rootedDamageTakenMul or 1.0) or 1.0
  mul = mul * StatusEffects.getDamageTakenMul(self)
  self.health = self.health - (damage * mul)
  self.flashTime = self.flashDuration

  if hitX and hitY then
    local dx = self.x - hitX
    local dy = self.y - hitY
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
      local k = knockbackForce or 80 -- tanky: less knockback
      self.knockbackX = (dx / dist) * k
      self.knockbackY = (dy / dist) * k
    end
  end

  if self.health <= 0 then
    self.isAlive = false
    return true
  end
  return false
end

function Treent:applyRoot(duration, damageTakenMul)
  self.rootedTime = math.max(self.rootedTime or 0, duration or 0)
  self.rootedDamageTakenMul = damageTakenMul or 1.15
end

function Treent:draw()
  if not self.isAlive then return end

  -- Placeholder shape (sprite to be added in visual overhaul)
  local r, g, b = 0.2, 0.8, 0.2
  if self.flashTime > 0 then r, g, b = 1, 1, 1 end
  if self.rootedTime and self.rootedTime > 0 then
    r, g, b = r * 0.6, g + 0.2, b * 0.6
  end
  if StatusEffects.has(self, "bleed") then
    r = math.min(1, r + 0.2); g = g * 0.5; b = b * 0.5
  end
  if StatusEffects.has(self, "marked") then
    r = r * 0.8; g = g * 0.8; b = math.min(1, b + 0.4)
  end
  love.graphics.setColor(r, g, b, 1)
  -- Larger square to convey tankiness
  love.graphics.rectangle("fill", self.x - self.size, self.y - self.size, self.size*2, self.size*2)
  love.graphics.setColor(1, 1, 1, 1)
end

function Treent:getPosition()
  return self.x, self.y
end

function Treent:getSize()
  return self.size
end

function Treent:isDead()
  return not self.isAlive
end

function Treent:getDamage()
  return self.damage
end

return Treent



