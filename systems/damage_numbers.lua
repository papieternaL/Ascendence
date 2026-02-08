-- systems/damage_numbers.lua
-- Floating combat text with pop-in scale, pixel outlines, and color-coded types

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
    if _G.PixelFonts then
      self.font = _G.PixelFonts.dmgNormal or _G.PixelFonts.small
      self.fontCrit = _G.PixelFonts.dmgCrit or _G.PixelFonts.body
    else
      local fontPath = "assets/Other/Fonts/Kenney Pixel.ttf"
      local ok, f = pcall(love.graphics.newFont, fontPath, 12)
      if ok then
        f:setFilter("nearest", "nearest")
        self.font = f
      else
        self.font = love.graphics.newFont(12)
      end
      ok, f = pcall(love.graphics.newFont, fontPath, 16)
      if ok then
        f:setFilter("nearest", "nearest")
        self.fontCrit = f
      else
        self.fontCrit = love.graphics.newFont(16)
      end
    end
  end
end

-- opts: { isCrit=bool, color={r,g,b,a}, vx, vy }
function DamageNumbers:add(x, y, amount, opts)
  ensureFonts(self)
  opts = opts or {}

  local isCrit = opts.isCrit == true
  local txt = tostring(math.floor(amount + 0.5))
  if isCrit then txt = txt .. "!" end

  -- Color: explicit > crit gold > white
  local color
  if opts.color then
    color = opts.color
  elseif isCrit then
    color = {1, 0.85, 0.1, 1}
  else
    color = {1, 1, 1, 1}
  end

  -- Stagger horizontal to reduce overlap
  local staggerX = (math.random() - 0.5) * 10

  self.items[#self.items+1] = {
    x = x + staggerX,
    y = y,
    vx = opts.vx or ((math.random() - 0.5) * 14),
    vy = opts.vy or (-55 - math.random() * 20),
    text = txt,
    age = 0,
    lifetime = isCrit and 0.9 or 0.6,
    isCrit = isCrit,
    color = color,
    -- Pop-in scale
    scaleStart = isCrit and 2.2 or 1.5,
    scaleEnd = isCrit and 1.05 or 0.85,
    popDuration = isCrit and 0.16 or 0.10,
  }
end

function DamageNumbers:update(dt)
  for i = #self.items, 1, -1 do
    local it = self.items[i]
    it.age = it.age + dt
    it.x = it.x + it.vx * dt
    it.y = it.y + it.vy * dt
    it.vx = it.vx * 0.90
    it.vy = it.vy + 90 * dt -- gravity arc
    if it.age >= it.lifetime then
      table.remove(self.items, i)
    end
  end
end

function DamageNumbers:draw()
  ensureFonts(self)
  for _, it in ipairs(self.items) do
    local t = it.age / it.lifetime

    -- Alpha: full for first 55%, then fade out
    local alpha
    if t < 0.55 then
      alpha = 1
    else
      alpha = 1 - ((t - 0.55) / 0.45)
    end

    -- Pop-in scale: start big, ease-out to final size
    local popT = math.min(1, it.age / it.popDuration)
    local easeOut = 1 - (1 - popT) ^ 3
    local scale = it.scaleStart + (it.scaleEnd - it.scaleStart) * easeOut

    local font = it.isCrit and self.fontCrit or self.font
    love.graphics.setFont(font)

    local tw = font:getWidth(it.text)
    local th = font:getHeight()
    local dx = math.floor(it.x - (tw * scale) / 2)
    local dy = math.floor(it.y - (th * scale) / 2)

    -- 4-directional pixel outline for readability
    local outOff = math.max(1, math.floor(scale * 0.8))
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.print(it.text, dx - outOff, dy, 0, scale, scale)
    love.graphics.print(it.text, dx + outOff, dy, 0, scale, scale)
    love.graphics.print(it.text, dx, dy - outOff, 0, scale, scale)
    love.graphics.print(it.text, dx, dy + outOff, 0, scale, scale)

    -- Main text color (with white flash on crits)
    local c = it.color
    local cr, cg, cb = c[1], c[2], c[3]
    if it.isCrit and it.age < 0.08 then
      local flash = 1 - (it.age / 0.08)
      cr = cr + (1 - cr) * flash
      cg = cg + (1 - cg) * flash
      cb = cb + (1 - cb) * flash
    end
    love.graphics.setColor(cr, cg, cb, (c[4] or 1) * alpha)
    love.graphics.print(it.text, dx, dy, 0, scale, scale)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return DamageNumbers
