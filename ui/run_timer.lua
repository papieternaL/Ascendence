-- ui/run_timer.lua
-- Timer display at top center of screen

local RunTimer = {}
RunTimer.__index = RunTimer

function RunTimer:new()
  local timer = {
    font_time = love.graphics.newFont(22),
    font_label = love.graphics.newFont(12),
    font_millis = love.graphics.newFont(14),
    y_position = 15,
    bg_color = {0.08, 0.08, 0.12, 0.92},
    border_color = {0.3, 0.35, 0.4, 0.85},
    text_color = {1, 1, 1, 1},
    label_color = {0.6, 0.65, 0.7, 0.9},
    icon_size = 10,
    icon_color = {0.6, 0.65, 0.7, 0.9},
    show_milliseconds = false,
    show_label = false,
    pulse_phase = 0
  }
  setmetatable(timer, RunTimer)
  return timer
end

function RunTimer:update(dt)
  self.pulse_phase = self.pulse_phase + dt * 2
end

function RunTimer:draw(time_seconds)
  local screen_width = love.graphics.getWidth()
  local time_string = self:formatTime(time_seconds)
  
  love.graphics.setFont(self.font_time)
  local text_width = self.font_time:getWidth(time_string)
  
  local padding_x = 20
  local padding_y = 10
  local bg_width = text_width + padding_x * 2 + (self.icon_size + 8)
  local bg_height = 44
  
  if self.show_label then
    bg_height = bg_height + 16
  end
  
  local x = screen_width / 2 - bg_width / 2
  local y = self.y_position
  
  love.graphics.setColor(self.bg_color)
  love.graphics.rectangle("fill", x, y, bg_width, bg_height, 5, 5)
  
  love.graphics.setColor(self.bg_color[1] + 0.03, self.bg_color[2] + 0.03, self.bg_color[3] + 0.05, 0.5)
  love.graphics.rectangle("fill", x, y, bg_width, bg_height * 0.4, 5, 5)
  
  love.graphics.setColor(self.border_color)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, bg_width, bg_height, 5, 5)
  
  love.graphics.setColor(self.border_color[1] + 0.1, self.border_color[2] + 0.1, self.border_color[3] + 0.1, 0.6)
  love.graphics.setLineWidth(1.5)
  love.graphics.line(x + 6, y, x, y, x, y + 6)
  love.graphics.line(x + bg_width - 6, y, x + bg_width, y, x + bg_width, y + 6)
  
  local text_y = y + padding_y
  
  if self.show_label then
    love.graphics.setFont(self.font_label)
    love.graphics.setColor(self.label_color)
    love.graphics.printf("TIME", x, y + 4, bg_width, "center")
    text_y = y + 20
  end
  
  local icon_x = x + padding_x
  local icon_y = text_y + bg_height / 2 - (self.show_label and 8 or 0)
  
  love.graphics.setColor(self.icon_color)
  love.graphics.circle("line", icon_x, icon_y, self.icon_size)
  love.graphics.line(icon_x, icon_y, icon_x, icon_y - self.icon_size * 0.6)
  love.graphics.line(icon_x, icon_y, icon_x + self.icon_size * 0.5, icon_y - self.icon_size * 0.3)
  
  love.graphics.setFont(self.font_time)
  love.graphics.setColor(self.text_color)
  local text_x = x + padding_x + self.icon_size + 8
  love.graphics.print(time_string, text_x, text_y)
  
  if self.show_milliseconds then
    local millis = math.floor((time_seconds % 1) * 100)
    local millis_string = string.format(".%02d", millis)
    love.graphics.setFont(self.font_millis)
    love.graphics.setColor(self.text_color[1], self.text_color[2], self.text_color[3], 0.7)
    love.graphics.print(millis_string, text_x + text_width, text_y + 5)
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
end

function RunTimer:formatTime(time_seconds)
  local minutes = math.floor(time_seconds / 60)
  local seconds = math.floor(time_seconds % 60)
  return string.format("%02d:%02d", minutes, seconds)
end

return RunTimer
