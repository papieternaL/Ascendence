-- entities/boss_portal.lua
-- Portal that appears when player reaches level 15

local BossPortal = {}
BossPortal.__index = BossPortal

function BossPortal:new(x, y)
  local portal = {
    x = x,
    y = y,
    radius = 65,
    activation_range = 90,
    
    pulse_phase = 0,
    rotation = 0,
    inner_rotation = 0,
    spawn_animation = 0,
    
    color = {0.75, 0.25, 0.95},
    glow_intensity = 0,
    show_prompt = false,
    
    particles = {},
    particle_spawn_timer = 0,
    
    activated = false,
    spawn_time = 0
  }
  setmetatable(portal, BossPortal)
  return portal
end

function BossPortal:update(dt, player)
  self.spawn_time = self.spawn_time + dt
  
  if self.spawn_animation < 1.0 then
    self.spawn_animation = math.min(1.0, self.spawn_animation + dt * 2)
  end
  
  self.pulse_phase = self.pulse_phase + dt * 1.8
  self.rotation = self.rotation + dt * 0.4
  self.inner_rotation = self.inner_rotation - dt * 0.8
  
  local dist = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
  if dist < self.activation_range then
    self.glow_intensity = math.min(1.0, self.glow_intensity + dt * 4)
    self.show_prompt = true
  else
    self.glow_intensity = math.max(0, self.glow_intensity - dt * 2)
    self.show_prompt = false
  end
  
  self.particle_spawn_timer = self.particle_spawn_timer + dt
  if self.particle_spawn_timer >= 0.1 then
    self.particle_spawn_timer = 0
    self:spawnParticle()
  end
  
  for i = #self.particles, 1, -1 do
    local p = self.particles[i]
    p.life = p.life - dt
    p.angle = p.angle + dt * 2
    p.distance = p.distance - dt * 15
    p.y = p.y - dt * 40
    p.x = self.x + math.cos(p.angle) * p.distance
    p.alpha = (p.life / p.max_life) * 0.8
    
    if p.life <= 0 then
      table.remove(self.particles, i)
    end
  end
end

function BossPortal:spawnParticle()
  local angle = math.random() * math.pi * 2
  local distance = self.radius + math.random(0, 20)
  
  table.insert(self.particles, {
    x = self.x + math.cos(angle) * distance,
    y = self.y + math.sin(angle) * distance,
    angle = angle,
    distance = distance,
    size = math.random(2, 5),
    life = math.random(1.5, 2.5),
    max_life = 2.0,
    alpha = 1.0
  })
end

function BossPortal:draw()
  local scale = self.spawn_animation
  local pulse = (math.sin(self.pulse_phase) + 1) * 0.5
  
  local glow_radius = (self.radius + pulse * 25) * scale
  love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.15 * self.glow_intensity * scale)
  love.graphics.circle("fill", self.x, self.y, glow_radius)
  
  love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.25 * self.glow_intensity * scale)
  love.graphics.circle("fill", self.x, self.y, glow_radius * 0.7)
  
  love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.9 * scale)
  love.graphics.setLineWidth(5)
  love.graphics.circle("line", self.x, self.y, self.radius * scale)
  
  love.graphics.setLineWidth(3)
  love.graphics.circle("line", self.x, self.y, self.radius * 0.7 * scale)
  
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.rotation)
  love.graphics.scale(scale, scale)
  
  for i = 1, 8 do
    local angle = (i / 8) * math.pi * 2
    local dist = self.radius * 0.85
    local x = math.cos(angle) * dist
    local y = math.sin(angle) * dist
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.7)
    love.graphics.circle("fill", x, y, 4)
  end
  love.graphics.pop()
  
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.inner_rotation)
  love.graphics.scale(scale, scale)
  
  for i = 1, 6 do
    local angle = (i / 6) * math.pi * 2
    local x1 = math.cos(angle) * self.radius * 0.3
    local y1 = math.sin(angle) * self.radius * 0.3
    local x2 = math.cos(angle) * self.radius * 0.6
    local y2 = math.sin(angle) * self.radius * 0.6
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(x1, y1, x2, y2)
  end
  love.graphics.pop()
  
  for _, p in ipairs(self.particles) do
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], p.alpha * scale)
    love.graphics.circle("fill", p.x, p.y, p.size)
  end
  
  if self.show_prompt and scale >= 0.9 then
    local prompt_text = "[E] Enter Boss Fight"
    local font = love.graphics.getFont()
    local text_width = font:getWidth(prompt_text)
    local text_height = font:getHeight()
    local prompt_y = self.y - self.radius - 40
    
    love.graphics.setColor(0.05, 0.05, 0.08, 0.9)
    love.graphics.rectangle("fill", self.x - text_width/2 - 10, prompt_y - 5, text_width + 20, text_height + 10, 4, 4)
    
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x - text_width/2 - 10, prompt_y - 5, text_width + 20, text_height + 10, 4, 4)
    
    love.graphics.setColor(1, 1, 1, pulse * 0.3 + 0.7)
    love.graphics.printf(prompt_text, self.x - text_width/2, prompt_y, text_width, "center")
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
end

function BossPortal:canActivate(player)
  local dist = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
  return dist < self.activation_range and self.spawn_animation >= 0.9
end

function BossPortal:activate()
  if not self.activated then
    self.activated = true
    return true
  end
  return false
end

return BossPortal
