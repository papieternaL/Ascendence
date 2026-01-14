-- ui/buff_bar.lua
-- Buff bar that displays above ability icons

local StatusEffects = require("data.status_effects")

local BuffBar = {}
BuffBar.__index = BuffBar

function BuffBar:new()
  local bb = {
    y_offset_from_abilities = 50,
    icon_size = 40,
    spacing = 8,
    max_visible = 12,
    padding = 12,
    bar_height = 64,
    bar_color = {0.08, 0.08, 0.12, 0.95},
    bar_border_color = {0.3, 0.3, 0.4, 0.8},
    buff_flash_timers = {},
    buff_pulse_phases = {},
    font_small = love.graphics.newFont(10),
    font_timer = love.graphics.newFont(12),
    font_label = love.graphics.newFont(11)
  }
  setmetatable(bb, BuffBar)
  return bb
end

function BuffBar:update(dt, player)
  for buff_name, timer in pairs(self.buff_flash_timers) do
    self.buff_flash_timers[buff_name] = timer - dt
    if timer <= 0 then
      self.buff_flash_timers[buff_name] = nil
    end
  end
  
  for buff_name, phase in pairs(self.buff_pulse_phases) do
    self.buff_pulse_phases[buff_name] = phase + dt * 4
  end
  
  if player.statusComponent then
    local new_statuses = player.statusComponent:getNewStatuses()
    for _, status_name in ipairs(new_statuses) do
      self:onBuffGained(status_name)
    end
  end
end

function BuffBar:draw(player, ability_hud_y)
  if not player.statusComponent then return end
  
  local buffs = player.statusComponent:getActiveBuffs()
  if #buffs == 0 then return end
  
  table.sort(buffs, function(a, b) return a.duration < b.duration end)
  
  local num_buffs = math.min(#buffs, self.max_visible)
  local content_width = num_buffs * (self.icon_size + self.spacing) - self.spacing
  local bar_width = content_width + self.padding * 2
  local bar_height = self.bar_height
  
  local screen_width = love.graphics.getWidth()
  local bar_x = (screen_width - bar_width) / 2
  local bar_y = ability_hud_y - self.y_offset_from_abilities - bar_height
  
  self:drawBarBackground(bar_x, bar_y, bar_width, bar_height, #buffs)
  
  local start_x = bar_x + self.padding
  local icon_y = bar_y + (bar_height - self.icon_size) / 2 - 8
  
  for i, buff in ipairs(buffs) do
    if i > self.max_visible then break end
    
    local x = start_x + (i - 1) * (self.icon_size + self.spacing)
    self:drawBuffIcon(x, icon_y, buff)
  end
end

function BuffBar:drawBarBackground(x, y, width, height, buff_count)
  love.graphics.setColor(self.bar_color)
  love.graphics.rectangle("fill", x, y, width, height, 6, 6)
  
  love.graphics.setColor(self.bar_color[1] + 0.05, self.bar_color[2] + 0.05, self.bar_color[3] + 0.08, 0.4)
  love.graphics.rectangle("fill", x, y, width, height * 0.3, 6, 6)
  
  love.graphics.setColor(self.bar_border_color)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, width, height, 6, 6)
  
  love.graphics.setColor(0.4, 0.4, 0.5, 0.6)
  love.graphics.setLineWidth(1)
  love.graphics.line(x + 8, y, x, y, x, y + 8)
  love.graphics.line(x + width - 8, y, x + width, y, x + width, y + 8)
  
  love.graphics.setFont(self.font_label)
  love.graphics.setColor(0.5, 0.5, 0.6, 0.9)
  love.graphics.print("BUFFS", x + 6, y + height - 16)
  love.graphics.printf(buff_count .. "/" .. self.max_visible, x, y + height - 16, width - 8, "right")
  
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1)
end

function BuffBar:drawBuffIcon(x, y, buff)
  local def = StatusEffects[buff.name]
  if not def then return end
  
  local size = self.icon_size
  
  local is_expiring = buff.duration < 2.0
  local pulse_alpha = 0
  if is_expiring then
    local phase = self.buff_pulse_phases[buff.name] or 0
    pulse_alpha = (math.sin(phase) + 1) * 0.25
  end
  
  love.graphics.setColor(0.1, 0.1, 0.1, 0.85)
  love.graphics.rectangle("fill", x, y, size, size, 4, 4)
  
  local border_brightness = is_expiring and (1.0 + pulse_alpha) or 1.0
  love.graphics.setColor(
    def.color[1] * border_brightness, 
    def.color[2] * border_brightness, 
    def.color[3] * border_brightness, 
    0.9
  )
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, size, size, 4, 4)
  
  local flash_timer = self.buff_flash_timers[buff.name]
  if flash_timer and flash_timer > 0 then
    local flash_alpha = (flash_timer / 0.4) * 0.6
    love.graphics.setColor(1, 1, 1, flash_alpha)
    love.graphics.rectangle("fill", x, y, size, size, 4, 4)
  end
  
  love.graphics.setColor(def.color[1], def.color[2], def.color[3], 0.8)
  love.graphics.circle("fill", x + size/2, y + size/2, size/3)
  
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.circle("fill", x + size/2, y + size/2, size/5)
  
  self:drawDurationArc(x + size/2, y + size/2, size/2 - 3, buff.duration, buff.max_duration)
  
  if buff.stacks and buff.stacks > 1 then
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(buff.stacks, x + size - 11, y + size - 13)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(buff.stacks, x + size - 12, y + size - 14)
  end
  
  if buff.charges then
    love.graphics.setFont(self.font_small)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(buff.charges, x + size - 11, y + 3)
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print(buff.charges, x + size - 12, y + 2)
  end
  
  love.graphics.setFont(self.font_timer)
  local duration_text = string.format("%.1f", buff.duration)
  
  local time_color = {1, 1, 1}
  if buff.duration < 1.0 then
    time_color = {1, 0.3, 0.3}
  elseif buff.duration < 2.0 then
    time_color = {1, 0.9, 0.2}
  end
  
  local text_width = self.font_timer:getWidth(duration_text)
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(duration_text, x + size/2 - text_width/2 + 1, y + size + 3)
  
  love.graphics.setColor(time_color)
  love.graphics.print(duration_text, x + size/2 - text_width/2, y + size + 2)
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
end

function BuffBar:drawDurationArc(cx, cy, radius, remaining, max_duration)
  local progress = math.max(0, math.min(1, remaining / max_duration))
  local start_angle = -math.pi / 2
  local end_angle = start_angle + (progress * math.pi * 2)
  
  local arc_color = {1, 1, 1, 0.6}
  if progress < 0.3 then
    arc_color = {1, 0.5, 0.5, 0.8}
  end
  
  love.graphics.setColor(arc_color)
  love.graphics.setLineWidth(3)
  love.graphics.arc("line", "open", cx, cy, radius, start_angle, end_angle, 32)
  love.graphics.setLineWidth(1)
end

function BuffBar:onBuffGained(buff_name)
  self.buff_flash_timers[buff_name] = 0.4
  self.buff_pulse_phases[buff_name] = 0
end

return BuffBar
