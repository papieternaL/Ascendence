-- systems/pixelgen.lua
-- Isolated dev tool for procedural pixel art generation.
-- Does not affect main gameplay. Trigger via debug key when DEBUG_PIXELGEN is true.

local PixelGen = {}
PixelGen.__index = PixelGen

-- Default output: LOVE save directory / generated/
function PixelGen:getOutputDir()
    local saveDir = love.filesystem.getSaveDirectory()
    return saveDir .. "/generated"
end

-- Ensure output directory exists
function PixelGen:ensureOutputDir()
    local ok = love.filesystem.createDirectory("generated")
    return ok
end

-- Generate a simple procedural sprite (placeholder implementation)
-- Returns ImageData; caller can encode to PNG.
function PixelGen:generate(width, height)
    width = width or 16
    height = height or 16
    local img = love.image.newImageData(width, height)
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            -- Simple procedural: gradient + noise
            local r = (x / width) * 0.8 + math.random() * 0.2
            local g = (y / height) * 0.6 + math.random() * 0.2
            local b = 0.4 + math.random() * 0.3
            local a = 1
            img:setPixel(x, y, r, g, b, a)
        end
    end
    return img
end

-- Reroll: generate with new seed (uses current time)
function PixelGen:reroll(width, height)
    math.randomseed(os.time() + (os.clock() * 1000))
    return self:generate(width, height)
end

-- Export current generation to file in generated/
function PixelGen:export(filename)
    self:ensureOutputDir()
    local img = self:reroll(16, 16)
    local fname = filename or ("pixelgen_" .. os.date("%Y%m%d_%H%M%S") .. ".png")
    local ok, err = pcall(function()
        img:encode("png", "generated/" .. fname)
    end)
    if ok then
        return true, self:getOutputDir() .. "/" .. fname
    else
        return false, err
    end
end

-- One-shot: generate and export (convenience for debug key)
function PixelGen:generateAndExport()
    local ok, path = self:export()
    if ok then
        return true, path
    else
        return false, path -- path is error message
    end
end

-- Module instance
local instance = setmetatable({}, PixelGen)

return instance
