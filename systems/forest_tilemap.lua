-- Forest Tilemap System - asset-first rendering with procedural fallback
local ForestTilemap = {}
ForestTilemap.__index = ForestTilemap

local Config = require("data.config")

local function worldSize()
    local w = Config.World and Config.World.width or love.graphics.getWidth()
    local h = Config.World and Config.World.height or love.graphics.getHeight()
    return w, h
end

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

local function safeImage(path)
    if not path or not love.filesystem.getInfo(path) then
        return nil
    end
    local ok, img = pcall(love.graphics.newImage, path)
    if not ok then return nil end
    img:setFilter("nearest", "nearest")
    return img
end

function ForestTilemap:new()
    local tilemap = {
        tileSize = 32,
        generated = false,

        -- Decorative elements
        trees = {},
        smallTrees = {},
        bushes = {},
        rocks = {},
        largeBlockers = {}, -- LOS blockers: { x, y, radius, type }

        -- Small floor accents to break up flat color when no texture exists.
        groundDecor = {},

        -- Optional art-driven assets.
        assets = {
            grassDirt = nil,
            forestSheet = nil,
            fungiSheet = nil,
            forestQuads = nil,
        },

        -- Subtle screen-space ambience (fireflies + vignette).
        ambientSpecks = {},
    }
    setmetatable(tilemap, ForestTilemap)
    tilemap:loadAssets()
    tilemap:initAmbientSpecks()
    return tilemap
end

function ForestTilemap:loadAssets()
    local forestCfg = Config.ForestScene or {}

    self.assets.grassDirt = safeImage(forestCfg.grassDirt or "assets/forest/grass_dirt.png")
    if self.assets.grassDirt then
        self.assets.grassDirt:setWrap("repeat", "repeat")
    end

    self.assets.forestSheet = safeImage(forestCfg.forestSheet or "assets/forest/forest_sheet.png")
    if self.assets.forestSheet then
        local iw, ih = self.assets.forestSheet:getDimensions()
        self.assets.forestQuads = {
            pine_tree_1 = love.graphics.newQuad(0, 0, 64, 96, iw, ih),
            pine_tree_2 = love.graphics.newQuad(64, 0, 64, 96, iw, ih),
            oak_tree_3 = love.graphics.newQuad(128, 0, 64, 96, iw, ih),
            oak_tree_4 = love.graphics.newQuad(192, 0, 64, 96, iw, ih),
            dead_tree_5 = love.graphics.newQuad(256, 0, 64, 96, iw, ih),
            bush_1 = love.graphics.newQuad(0, 96, 48, 48, iw, ih),
            bush_2 = love.graphics.newQuad(48, 96, 48, 48, iw, ih),
            bush_3 = love.graphics.newQuad(96, 96, 48, 48, iw, ih),
            mossy_rock_a = love.graphics.newQuad(0, 144, 32, 32, iw, ih),
            mossy_rock_b = love.graphics.newQuad(32, 144, 32, 32, iw, ih),
            root_clump = love.graphics.newQuad(64, 144, 48, 48, iw, ih),
        }
    end

    self.assets.fungiSheet = safeImage(forestCfg.fungiSheet or "assets/forest/fungi_sheet.png")
end

function ForestTilemap:initAmbientSpecks()
    self.ambientSpecks = {}
    local w, h = love.graphics.getDimensions()
    for i = 1, 55 do
        self.ambientSpecks[#self.ambientSpecks + 1] = {
            x = math.random() * w,
            y = math.random() * h,
            speed = 6 + math.random() * 14,
            phase = math.random() * math.pi * 2,
            size = 0.8 + math.random() * 1.6,
            hue = (math.random() < 0.5) and "cyan" or "lime",
        }
    end
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
    self.groundDecor = {}

    local treeTypes = { "pine_tree_1", "pine_tree_2", "oak_tree_3", "oak_tree_4", "dead_tree_5" }
    local bushTypes = { "bush_1", "bush_2", "bush_3" }
    local rockTypes = { "mossy_rock_a", "mossy_rock_b" }

    local function addScattered(list, count, minDist, margin, makeItem)
        local tries = count * 20
        while #list < count and tries > 0 do
            tries = tries - 1
            local x = math.random(margin, worldW - margin)
            local y = math.random(margin, worldH - margin)

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

    addScattered(self.trees, 18, 108, 70, function(x, y)
        return {
            x = x,
            y = y,
            sprite = treeTypes[math.random(1, #treeTypes)],
            trunkW = 7 + math.random(0, 3),
            trunkH = 16 + math.random(0, 6),
            crownR = 18 + math.random(0, 10),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.smallTrees, 20, 78, 60, function(x, y)
        return {
            x = x,
            y = y,
            sprite = treeTypes[math.random(1, #treeTypes)],
            trunkW = 5 + math.random(0, 2),
            trunkH = 10 + math.random(0, 4),
            crownR = 12 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.bushes, 34, 48, 40, function(x, y)
        return {
            x = x,
            y = y,
            sprite = bushTypes[math.random(1, #bushTypes)],
            radius = 8 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.rocks, 24, 52, 45, function(x, y)
        return {
            x = x,
            y = y,
            sprite = rockTypes[math.random(1, #rockTypes)],
            rx = 7 + math.random(0, 7),
            ry = 5 + math.random(0, 5),
            tint = 0.52 + math.random() * 0.08,
        }
    end)

    local allProps = {}
    for _, t in ipairs(self.trees) do table.insert(allProps, t) end
    for _, r in ipairs(self.rocks) do table.insert(allProps, r) end
    for _, b in ipairs(self.bushes) do table.insert(allProps, b) end
    for _, st in ipairs(self.smallTrees) do table.insert(allProps, st) end
    addScattered(self.largeBlockers, 8, 200, 100, function(x, y)
        local radius = 28 + math.random(0, 20)
        local typ = math.random() < 0.5 and "large_rock" or "mountain"
        return { x = x, y = y, radius = radius, type = typ, sprite = "root_clump" }
    end)

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

    -- Tiny clumps/specks to emulate richer floor painting.
    local decorCount = math.floor((worldW * worldH) / (96 * 96))
    for i = 1, decorCount do
        self.groundDecor[#self.groundDecor + 1] = {
            x = math.random(0, worldW),
            y = math.random(0, worldH),
            kind = (math.random() < 0.75) and "leaf" or "glow",
            size = 1 + math.random() * 2.8,
            phase = math.random() * math.pi * 2,
        }
    end

    self.generated = true
end

function ForestTilemap:update(dt)
    for _, s in ipairs(self.ambientSpecks) do
        s.y = s.y + s.speed * dt
        s.x = s.x + math.sin(love.timer.getTime() * 0.7 + s.phase) * 5 * dt
        if s.y > love.graphics.getHeight() + 5 then
            s.y = -5
            s.x = math.random() * love.graphics.getWidth()
        end
    end
end

function ForestTilemap:draw()
    if not self.generated then
        self:generate()
    end

    local worldW, worldH = worldSize()
    local tile = self.tileSize
    local tilesX = math.ceil(worldW / tile)
    local tilesY = math.ceil(worldH / tile)

    if self.assets.grassDirt then
        local img = self.assets.grassDirt
        local iw, ih = img:getDimensions()
        local quad = love.graphics.newQuad(0, 0, worldW + tile * 2, worldH + tile * 2, iw, ih)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, quad, -tile, -tile)

        -- Color-grade overlay to push deep forest tones closer to reference.
        love.graphics.setColor(0.10, 0.28, 0.20, 0.22)
        love.graphics.rectangle("fill", 0, 0, worldW, worldH)
    else
        for y = 0, tilesY do
            for x = 0, tilesX do
                local n = seeded01(x, y)
                if n < 0.50 then
                    love.graphics.setColor(0.14, 0.31, 0.19, 1)
                elseif n < 0.75 then
                    love.graphics.setColor(0.16, 0.35, 0.22, 1)
                elseif n < 0.92 then
                    love.graphics.setColor(0.18, 0.38, 0.24, 1)
                else
                    love.graphics.setColor(0.12, 0.27, 0.18, 1)
                end
                love.graphics.rectangle("fill", x * tile, y * tile, tile, tile)
            end
        end
    end

    -- Ground micro-detail pass.
    local t = love.timer.getTime()
    for _, d in ipairs(self.groundDecor) do
        if d.kind == "leaf" then
            love.graphics.setColor(0.42, 0.62, 0.37, 0.24)
            love.graphics.rectangle("fill", d.x, d.y, d.size * 1.4, d.size * 0.8)
        else
            local pulse = 0.15 + 0.08 * math.sin(t * 2.2 + d.phase)
            love.graphics.setColor(0.45, 0.95, 0.85, pulse)
            love.graphics.circle("fill", d.x, d.y, d.size * 0.45)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawProceduralTree(tree, small)
    local t = love.timer.getTime()
    local sway = math.sin(t * (small and 0.9 or 0.6) + tree.swayOffset) * (small and 0.8 or 1.2)
    local trunkX = tree.x + sway
    local baseY = tree.y

    love.graphics.setColor(0.06, 0.10, 0.06, 0.35)
    love.graphics.ellipse("fill", trunkX, baseY + 2, tree.crownR * 0.72, 4)

    love.graphics.setColor(0.34, 0.23, 0.14, 1)
    love.graphics.rectangle("fill", trunkX - tree.trunkW * 0.5, baseY - tree.trunkH, tree.trunkW, tree.trunkH)

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

    love.graphics.setColor(0.05, 0.06, 0.06, 0.4)
    love.graphics.ellipse("fill", x, y + 4, r * 1.05, 6)
    love.graphics.setColor(0.42, 0.44, 0.46, 1)
    love.graphics.circle("fill", x, y, r)
    love.graphics.setColor(0.32, 0.34, 0.36, 1)
    love.graphics.circle("line", x, y, r)
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

function ForestTilemap:drawSprite(spriteKey, x, y, ox, oy, sx, sy)
    local sheet = self.assets.forestSheet
    local quads = self.assets.forestQuads
    local quad = quads and quads[spriteKey]
    if not (sheet and quad) then return false end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sheet, quad, x, y, 0, sx or 1, sy or sx or 1, ox or 0, oy or 0)
    return true
end

function ForestTilemap:getTreesForSorting()
    local result = {}
    for _, tree in ipairs(self.trees) do
        result[#result + 1] = {
            x = tree.x,
            y = tree.y,
            draw = function()
                local sway = math.sin(love.timer.getTime() * 0.6 + tree.swayOffset) * 1.2
                local drewSprite = self:drawSprite(tree.sprite, tree.x + sway, tree.y, 32, 96, 1.0)
                if not drewSprite then
                    drawProceduralTree(tree, false)
                end
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
                local sway = math.sin(love.timer.getTime() * 1.05 + bush.swayOffset) * 0.8
                local drewSprite = self:drawSprite(bush.sprite, bush.x + sway, bush.y, 24, 48, 1.0)
                if not drewSprite then
                    drawProceduralBush(bush)
                end
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
                local sway = math.sin(love.timer.getTime() * 0.9 + tree.swayOffset) * 0.9
                local drewSprite = self:drawSprite(tree.sprite, tree.x + sway, tree.y + 4, 32, 96, 0.72)
                if not drewSprite then
                    drawProceduralTree(tree, true)
                end
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
                local drewSprite = self:drawSprite(rock.sprite, rock.x, rock.y, 16, 32, 1.0)
                if not drewSprite then
                    drawProceduralRock(rock)
                end
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
                local drewSprite = self:drawSprite(blk.sprite, blk.x, blk.y + 8, 24, 48, 1.4)
                if not drewSprite then
                    drawProceduralLargeBlocker(blk)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end
    return result
end

function ForestTilemap:drawScreenOverlay()
    local w, h = love.graphics.getDimensions()

    -- Soft vignette to match the reference's focused center lighting.
    local cx, cy = w * 0.5, h * 0.52
    for i = 9, 1, -1 do
        local radius = (w * 0.68) * (i / 9)
        love.graphics.setColor(0.02, 0.04, 0.05, 0.018 * i)
        love.graphics.circle("fill", cx, cy, radius)
    end

    -- Glowing specks
    local t = love.timer.getTime()
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, s in ipairs(self.ambientSpecks) do
        local pulse = 0.3 + 0.25 * math.sin(t * 2.5 + s.phase)
        if s.hue == "cyan" then
            love.graphics.setColor(0.50, 1.00, 0.95, pulse)
        else
            love.graphics.setColor(0.72, 1.00, 0.70, pulse)
        end
        love.graphics.circle("fill", s.x, s.y, s.size)
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function ForestTilemap:getLargeBlockers()
    return self.largeBlockers or {}
end

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
