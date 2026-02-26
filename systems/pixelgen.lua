-- systems/pixelgen.lua
-- Procedural pixel-art sprite generator.
-- Two generators: make_creature (32x32 enemies) and make_icon (16x16 icons).
-- Trigger standalone preview via DEBUG_PIXELGEN + F9.

local pixelgen = {}

local palettes = {
  warm = { {0.10,0.10,0.12,1}, {0.85,0.20,0.25,1}, {0.95,0.75,0.15,1}, {0.92,0.92,0.95,1} },
  cool = { {0.06,0.08,0.10,1}, {0.15,0.55,0.95,1}, {0.10,0.85,0.65,1}, {0.90,0.95,1.00,1} },
  synth= { {0.08,0.07,0.10,1}, {0.65,0.30,0.95,1}, {0.25,0.90,0.40,1}, {0.95,0.95,0.95,1} },
  mono = { {0.06,0.06,0.07,1}, {0.95,0.95,0.97,1} },
}

local function choice(t, rng) return t[rng:random(1, #t)] end

local function clear(imgData, w, h)
  for y=0,h-1 do
    for x=0,w-1 do
      imgData:setPixel(x,y,0,0,0,0)
    end
  end
end

local function is_filled(imgData, x, y, w, h)
  if x < 0 or x >= w or y < 0 or y >= h then return false end
  local _, _, _, a = imgData:getPixel(x, y)
  return a > 0.0
end

local function outline4(imgData, w, h, col)
  for y=0,h-1 do
    for x=0,w-1 do
      if not is_filled(imgData, x, y, w, h) then
        if is_filled(imgData, x-1, y, w, h) or is_filled(imgData, x+1, y, w, h) or
           is_filled(imgData, x, y-1, w, h) or is_filled(imgData, x, y+1, w, h) then
          imgData:setPixel(x, y, col[1], col[2], col[3], 1)
        end
      end
    end
  end
end

local function count_filled(imgData, w, h)
  local c = 0
  for y=0,h-1 do
    for x=0,w-1 do
      local _, _, _, a = imgData:getPixel(x, y)
      if a > 0 then c = c + 1 end
    end
  end
  return c
end

-- ------------------------------------------------------------
-- CREATURE GENERATOR
-- Defaults: 32x32, symmetrical, outlined, center-weighted
-- ------------------------------------------------------------
function pixelgen.make_creature(opts)
  opts = opts or {}
  local w = opts.w or 32
  local h = opts.h or 32
  local seed = opts.seed or os.time()
  local density = opts.density or 0.42
  local outline = (opts.outline == nil) and true or opts.outline
  local center_weight = opts.center_weight or 0.65

  local rng = love.math.newRandomGenerator(seed)
  local palName = opts.palette_name or choice({"warm","cool","synth"}, rng)
  local pal = palettes[palName] or palettes.warm
  local dark = pal[1]

  local imgData = love.image.newImageData(w, h)
  clear(imgData, w, h)

  local half = math.floor(w / 2)
  local cx, cy = (w - 1) / 2, (h - 1) / 2
  local maxd = math.sqrt(cx*cx + cy*cy)

  for y=0,h-1 do
    for x=0,half-1 do
      local mx = (w - 1) - x
      local dx, dy = x - cx, y - cy
      local d = (math.sqrt(dx*dx + dy*dy) / maxd)
      local weight = (1.0 - d) * center_weight + (1.0 - center_weight)
      local p = density * weight

      if rng:random() < p then
        local c = choice(pal, rng)
        imgData:setPixel(x, y, c[1], c[2], c[3], c[4])
        imgData:setPixel(mx, y, c[1], c[2], c[3], c[4])
      end
    end
  end

  -- De-noise single isolated pixels
  for y=0,h-1 do
    for x=0,w-1 do
      if is_filled(imgData, x, y, w, h) then
        local n = 0
        if is_filled(imgData, x-1, y, w, h) then n=n+1 end
        if is_filled(imgData, x+1, y, w, h) then n=n+1 end
        if is_filled(imgData, x, y-1, w, h) then n=n+1 end
        if is_filled(imgData, x, y+1, w, h) then n=n+1 end
        if n == 0 and rng:random() < 0.85 then
          imgData:setPixel(x, y, 0, 0, 0, 0)
        end
      end
    end
  end

  if outline then outline4(imgData, w, h, dark) end

  local img = love.graphics.newImage(imgData)
  img:setFilter("nearest", "nearest")
  return img, imgData, seed, palName
end

-- ------------------------------------------------------------
-- ICON GENERATOR
-- Defaults: 16x16, mono palette, outlined, validated
-- ------------------------------------------------------------
local function draw_icon_shape(imgData, w, h, rng, shape, fill)
  local function set(x,y)
    if x>=0 and x<w and y>=0 and y<h then
      imgData:setPixel(x, y, fill[1], fill[2], fill[3], 1)
    end
  end

  local cx, cy = math.floor(w/2), math.floor(h/2)

  if shape == "orb" then
    local r = math.floor(math.min(w,h) * 0.32)
    for y=0,h-1 do
      for x=0,w-1 do
        local dx, dy = x-cx, y-cy
        if dx*dx + dy*dy <= r*r then set(x,y) end
      end
    end

  elseif shape == "bolt" then
    local x = cx
    for y=2,h-3 do
      set(x,y)
      if y % 3 == 0 then x = x + (rng:random(0,1)==0 and -1 or 1) end
      x = math.max(2, math.min(w-3, x))
      set(x+1,y)
    end
    for y=0,h-1 do for x=0,w-1 do
      if is_filled(imgData, x, y, w, h) then
        set(x+1,y); set(x,y+1)
      end
    end end

  elseif shape == "sword" then
    for y=2,h-5 do set(cx,y) end
    set(cx-1,3); set(cx+1,3)
    for x=cx-3,cx+3 do set(x,h-5) end
    for y=h-4,h-2 do set(cx,y) end

  elseif shape == "shield" then
    for y=2,h-4 do
      local t = math.floor((y-2) * 0.5)
      for x=cx-3+t, cx+3-t do set(x,y) end
    end
    for y=h-4,h-2 do
      local t = (h-2) - y
      for x=cx-1-t, cx+1+t do set(x,y) end
    end

  elseif shape == "star" then
    for i=-4,4 do set(cx+i,cy); set(cx,cy+i) end
    for i=-3,3 do set(cx+i,cy+i); set(cx+i,cy-i) end
  end
end

function pixelgen.make_icon(opts)
  opts = opts or {}
  local w = opts.w or 16
  local h = opts.h or 16
  local seed = opts.seed or os.time()
  local outline = (opts.outline == nil) and true or opts.outline
  local palName = opts.palette_name or "mono"
  local validate = (opts.validate == nil) and true or opts.validate
  local minFilled = opts.min_filled or 28
  local maxFilled = opts.max_filled or 140
  local attempts = opts.attempts or 50

  local function gen_once(s)
    local rng = love.math.newRandomGenerator(s)
    local pal = palettes[palName] or palettes.mono
    local dark = pal[1]
    local fill = pal[#pal]

    local imgData = love.image.newImageData(w, h)
    clear(imgData, w, h)

    local shape = opts.shape or "random"
    if shape == "random" then
      shape = choice({"bolt","orb","sword","shield","star"}, rng)
    end

    draw_icon_shape(imgData, w, h, rng, shape, fill)
    if outline then outline4(imgData, w, h, dark) end

    local filled = count_filled(imgData, w, h)

    local img = love.graphics.newImage(imgData)
    img:setFilter("nearest", "nearest")

    return img, imgData, s, shape, filled
  end

  local s = seed
  for i=1,attempts do
    local img, imgData, outSeed, shape, filled = gen_once(s)
    if not validate then
      return img, imgData, outSeed, shape, filled
    end
    if filled >= minFilled and filled <= maxFilled then
      return img, imgData, outSeed, shape, filled
    end
    s = s + 1
  end

  return gen_once(s)
end

-- Save ImageData to PNG (inside Love2D save directory)
function pixelgen.save_png(imgData, path)
  local fileData = imgData:encode("png")
  love.filesystem.createDirectory("generated")
  love.filesystem.write(path, fileData)
end

-- Legacy compatibility: generateAndExport (called by main.lua F9 debug key)
function pixelgen:generateAndExport()
  local img, imgData, seed, pal = pixelgen.make_creature({ seed = os.time() })
  local fname = ("generated/creature_%s_%d.png"):format(pal or "pal", seed)
  pixelgen.save_png(imgData, fname)
  local saveDir = love.filesystem.getSaveDirectory()
  return true, saveDir .. "/" .. fname
end

return pixelgen
