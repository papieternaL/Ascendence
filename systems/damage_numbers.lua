-- systems/damage_numbers.lua
-- Floating combat text (damage numbers)

local DamageNumbers = {}
DamageNumbers.__index = DamageNumbers

function DamageNumbers:new()
  local o = setmetatable({
    items = {},
    font = nil,
    fontCrit = nil,
  }, DamageNumbers)
  return o
end

local function ensureFonts(self)
  if not self.font then
    self.font = love.graphics.newFont(12)
    self.fontCrit = love.graphics.newFont(16)
  end
end

-- opts: { isCrit=true/false, color={r,g,b,a}, vx, vy, damageType="normal"|"bleed"|"burn" }
function DamageNumbers:add(x, y, amount, opts)
  ensureFonts(self)
  opts = opts or {}

  local isCrit = opts.isCrit == true
  local damageType = opts.damageType or "normal"
  local txt = tostring(math.floor(amount + 0.5))

  -- Auto-select color based on damage type
  local color = opts.color
  if not color then
    if damageType == "bleed" then
      color = {0.8, 0.1, 0.1, 1}  -- Red for bleed
    elseif isCrit then
      color = {1, 0.9, 0.2, 1}    -- Golden for crit
    else
      color = {1, 1, 1, 1}        -- White for normal
    end
  end

  self.items[#self.items+1] = {
    x = x,
    y = y,
    vx = opts.vx or ((math.random() - 0.5) * 20),
    vy = opts.vy or (-35 - math.random() * 25),
    text = txt,
    age = 0,
    lifetime = isCrit and 0.85 or 0.65,
    isCrit = isCrit,
    color = color,
    damageType = damageType,
  }
end

function DamageNumbers:update(dt)
  for i = #self.items, 1, -1 do
    local it = self.items[i]
    it.age = it.age + dt
    it.x = it.x + it.vx * dt
    it.y = it.y + it.vy * dt
    it.vx = it.vx * 0.97
    it.vy = it.vy + 40 * dt -- slight gravity
    if it.age >= it.lifetime then
      table.remove(self.items, i)
    end
  end
end

function DamageNumbers:draw()
  ensureFonts(self)
  for _, it in ipairs(self.items) do
    local t = it.age / it.lifetime
    local alpha = 1 - t
    local c = it.color

    -- Drop shadow
    love.graphics.setFont(it.isCrit and self.fontCrit or self.font)
    love.graphics.setColor(0, 0, 0, 0.6 * alpha)
    love.graphics.print(it.text, it.x + 1, it.y + 1)

    -- Main text
    love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
    love.graphics.print(it.text, it.x, it.y)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return DamageNumbers




