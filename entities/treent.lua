-- Treent Enemy - Tanky forest bruiser
local Treent = {}
Treent.__index = Treent

Treent.image = nil

local function loadImageOnce()
  if Treent.image then return end
  -- Keep enemy visuals "pixel clean" by using the same Kenney Monochrome RPG tileset style.
  local success, img = pcall(love.graphics.newImage, "assets/2D assets/Monochrome RPG Tileset/Dot Matrix/Sprites/enemy2.png")
  if success and img then
    Treent.image = img
    Treent.image:setFilter("nearest", "nearest")
  end
end

function Treent:new(x, y)
  loadImageOnce()
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

  if Treent.image then
    local img = Treent.image
    local w, h = img:getWidth(), img:getHeight()
    local scale = 1.6
    if self.flashTime > 0 then
      love.graphics.setColor(1, 1, 1, 1)
    else
      -- Slight green tint to read as "forest bruiser"
      love.graphics.setColor(0.7, 1.0, 0.75, 1)
    end
    love.graphics.draw(img, self.x, self.y, 0, scale, scale, w/2, h/2)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end

  -- Fallback: big green square
  local r, g, b = 0.2, 0.8, 0.2
  if self.flashTime > 0 then r, g, b = 1, 1, 1 end
  love.graphics.setColor(r, g, b, 1)
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



