-- Forest Tilemap System - Fully procedural assets (no external sprites)
local ForestTilemap = {}
ForestTilemap.__index = ForestTilemap

local Config = require("data.config")

local function worldSize()
    local w = Config.World and Config.World.width or love.graphics.getWidth()
    local h = Config.World and Config.World.height or love.graphics.getHeight()
    return w, h
end

-- Deterministic pseudo-random value in [0, 1] from integer coords.
-- Keeps floor variation stable frame-to-frame (no flicker).
local function seeded01(ix, iy)
    local v = (ix * 73856093 + iy * 19349663) % 1000
    return v / 999
end

local function distSq(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

local function canPlace(list, x, y, minDist)
    local minDistSq = minDist * minDist
    for _, item in ipairs(list) do
        if distSq(item.x, item.y, x, y) < minDistSq then
            return false
        end
    end
    return true
end

function ForestTilemap:new()
    local tilemap = {
        tileSize = 32,
        generated = false,

        -- Decorative elements (procedural)
        trees = {},
        smallTrees = {},
        bushes = {},
        rocks = {},
        largeBlockers = {},  -- LOS blockers: { x, y, radius, type }
    }
    setmetatable(tilemap, ForestTilemap)
    return tilemap
end

function ForestTilemap:generate()
    if self.generated then return end

    local worldW, worldH = worldSize()
    local centerX, centerY = worldW * 0.5, worldH * 0.5
    local centerSoftRadiusSq = 180 * 180

    self.trees = {}
    self.smallTrees = {}
    self.bushes = {}
    self.rocks = {}
    self.largeBlockers = {}

    local function addScattered(list, count, minDist, margin, makeItem)
        local tries = count * 20
        while #list < count and tries > 0 do
            tries = tries - 1
            local x = math.random(margin, worldW - margin)
            local y = math.random(margin, worldH - margin)

            -- Keep combat readability at center, but do not hard-exclude.
            local inCenter = distSq(x, y, centerX, centerY) < centerSoftRadiusSq
            if inCenter and math.random() < 0.65 then
                goto continue
            end

            if canPlace(list, x, y, minDist) then
                list[#list + 1] = makeItem(x, y)
            end
            ::continue::
        end
    end

    addScattered(self.trees, 14, 110, 70, function(x, y)
        return {
            x = x,
            y = y,
            trunkW = 7 + math.random(0, 3),
            trunkH = 16 + math.random(0, 6),
            crownR = 18 + math.random(0, 10),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.smallTrees, 18, 80, 60, function(x, y)
        return {
            x = x,
            y = y,
            trunkW = 5 + math.random(0, 2),
            trunkH = 10 + math.random(0, 4),
            crownR = 12 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.bushes, 28, 52, 40, function(x, y)
        return {
            x = x,
            y = y,
            radius = 8 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.rocks, 22, 56, 45, function(x, y)
        return {
            x = x,
            y = y,
            rx = 7 + math.random(0, 7),
            ry = 5 + math.random(0, 5),
            tint = 0.52 + math.random() * 0.08,
        }
    end)

    -- Large rock/mountain LOS blockers (full collision, kiting structures)
    local allProps = {}
    for _, t in ipairs(self.trees) do table.insert(allProps, t) end
    for _, r in ipairs(self.rocks) do table.insert(allProps, r) end
    for _, b in ipairs(self.bushes) do table.insert(allProps, b) end
    for _, st in ipairs(self.smallTrees) do table.insert(allProps, st) end
    addScattered(self.largeBlockers, 8, 200, 100, function(x, y)
        local radius = 28 + math.random(0, 20)
        local typ = math.random() < 0.5 and "large_rock" or "mountain"
        return { x = x, y = y, radius = radius, type = typ }
    end)
    -- Ensure large blockers don't overlap with trees/rocks
    local filtered = {}
    for _, blk in ipairs(self.largeBlockers) do
        local ok = true
        for _, p in ipairs(allProps) do
            local px, py = p.x, p.y
            local pr = (p.radius or p.rx or p.crownR or 15) + 20
            if distSq(blk.x, blk.y, px, py) < (blk.radius + pr) * (blk.radius + pr) then
                ok = false
                break
            end
        end
        if ok then filtered[#filtered + 1] = blk end
    end
    self.largeBlockers = filtered

    self.generated = true
end

function ForestTilemap:update(dt)
    -- Intentionally lightweight; props use small sway in draw closures.
end

function ForestTilemap:draw()
    if not self.generated then
        self:generate()
    end

    local worldW, worldH = worldSize()
    local tile = self.tileSize
    local tilesX = math.ceil(worldW / tile)
    local tilesY = math.ceil(worldH / tile)

    -- Favor darker green tiles; reduce off-color variation.
    for y = 0, tilesY do
        for x = 0, tilesX do
            local n = seeded01(x, y)
            if n < 0.50 then
                love.graphics.setColor(0.18, 0.32, 0.18, 1)
            elseif n < 0.75 then
                love.graphics.setColor(0.20, 0.34, 0.20, 1)
            elseif n < 0.92 then
                love.graphics.setColor(0.22, 0.36, 0.22, 1)
            else
                love.graphics.setColor(0.24, 0.38, 0.24, 1)
            end
            love.graphics.rectangle("fill", x * tile, y * tile, tile, tile)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawProceduralTree(tree, small)
    local t = love.timer.getTime()
    local sway = math.sin(t * (small and 0.9 or 0.6) + tree.swayOffset) * (small and 0.8 or 1.2)
    local trunkX = tree.x + sway
    local baseY = tree.y

    -- Base shadow for separation against floor.
    love.graphics.setColor(0.06, 0.10, 0.06, 0.35)
    love.graphics.ellipse("fill", trunkX, baseY + 2, tree.crownR * 0.72, 4)

    -- Trunk
    love.graphics.setColor(0.34, 0.23, 0.14, 1)
    love.graphics.rectangle("fill", trunkX - tree.trunkW * 0.5, baseY - tree.trunkH, tree.trunkW, tree.trunkH)

    -- Foliage base + highlight
    love.graphics.setColor(0.11, 0.23, 0.12, 1)
    love.graphics.circle("fill", trunkX, baseY - tree.trunkH - tree.crownR * 0.45, tree.crownR)
    love.graphics.setColor(0.16, 0.29, 0.16, 0.9)
    love.graphics.circle("fill", trunkX - tree.crownR * 0.22, baseY - tree.trunkH - tree.crownR * 0.58, tree.crownR * 0.55)
end

local function drawProceduralBush(bush)
    local t = love.timer.getTime()
    local sway = math.sin(t * 1.05 + bush.swayOffset) * 0.8
    local x = bush.x + sway
    local y = bush.y

    love.graphics.setColor(0.08, 0.12, 0.08, 0.25)
    love.graphics.ellipse("fill", x, y + 2, bush.radius * 0.85, 3)
    love.graphics.setColor(0.12, 0.22, 0.12, 1)
    love.graphics.circle("fill", x, y, bush.radius)
    love.graphics.setColor(0.17, 0.30, 0.16, 0.85)
    love.graphics.circle("fill", x - bush.radius * 0.25, y - bush.radius * 0.2, bush.radius * 0.45)
end

local function drawProceduralLargeBlocker(blk)
    local x, y = blk.x, blk.y
    local r = blk.radius
    local isMountain = blk.type == "mountain"
    -- Shadow
    love.graphics.setColor(0.05, 0.06, 0.06, 0.4)
    love.graphics.ellipse("fill", x, y + 4, r * 1.05, 6)
    -- Base grey
    love.graphics.setColor(0.42, 0.44, 0.46, 1)
    love.graphics.circle("fill", x, y, r)
    -- Darker rim
    love.graphics.setColor(0.32, 0.34, 0.36, 1)
    love.graphics.circle("line", x, y, r)
    -- Highlight (mountain: snow cap hint)
    if isMountain then
        love.graphics.setColor(0.65, 0.66, 0.68, 0.9)
        love.graphics.circle("fill", x - r * 0.25, y - r * 0.35, r * 0.35)
    else
        love.graphics.setColor(0.52, 0.54, 0.56, 0.8)
        love.graphics.circle("fill", x - r * 0.2, y - r * 0.25, r * 0.3)
    end
end

local function drawProceduralRock(rock)
    local x, y = rock.x, rock.y
    local rx, ry = rock.rx, rock.ry
    local tint = rock.tint

    love.graphics.setColor(0.09, 0.10, 0.10, 0.25)
    love.graphics.ellipse("fill", x, y + 2, rx * 1.05, 3)
    love.graphics.setColor(tint, tint, tint + 0.02, 1)
    love.graphics.ellipse("fill", x, y, rx, ry)
    love.graphics.setColor(tint + 0.12, tint + 0.12, tint + 0.12, 0.65)
    love.graphics.ellipse("fill", x - rx * 0.25, y - ry * 0.2, rx * 0.45, ry * 0.35)
end

function ForestTilemap:getTreesForSorting()
    local result = {}
    for _, tree in ipairs(self.trees) do
        result[#result + 1] = {
            x = tree.x,
            y = tree.y,
            draw = function()
                drawProceduralTree(tree, false)
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

function ForestTilemap:getBushesForSorting()
    local result = {}
    for _, bush in ipairs(self.bushes) do
        result[#result + 1] = {
            x = bush.x,
            y = bush.y,
            draw = function()
                drawProceduralBush(bush)
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

function ForestTilemap:getSmallTreesForSorting()
    local result = {}
    for _, tree in ipairs(self.smallTrees) do
        result[#result + 1] = {
            x = tree.x,
            y = tree.y,
            draw = function()
                drawProceduralTree(tree, true)
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

function ForestTilemap:getRocksForSorting()
    local result = {}
    for _, rock in ipairs(self.rocks) do
        result[#result + 1] = {
            x = rock.x,
            y = rock.y,
            draw = function()
                drawProceduralRock(rock)
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

function ForestTilemap:getLargeBlockersForSorting()
    local result = {}
    for _, blk in ipairs(self.largeBlockers or {}) do
        result[#result + 1] = {
            x = blk.x,
            y = blk.y,
            draw = function()
                drawProceduralLargeBlocker(blk)
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

-- Returns collision circles for gameplay (player, enemy, projectile blocking).
function ForestTilemap:getLargeBlockers()
    return self.largeBlockers or {}
end

-- Kept for compatibility with older call sites.
function ForestTilemap:drawTrees()
    for _, drawable in ipairs(self:getTreesForSorting()) do
        drawable.draw()
    end
end

function ForestTilemap:drawBushes()
    for _, drawable in ipairs(self:getBushesForSorting()) do
        drawable.draw()
    end
end

return ForestTilemap












