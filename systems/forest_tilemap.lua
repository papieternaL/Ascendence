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

local function inEllipse(x, y, cx, cy, rx, ry)
    local dx = (x - cx) / rx
    local dy = (y - cy) / ry
    return dx * dx + dy * dy <= 1
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

local function drawRotatedEllipse(mode, x, y, rx, ry, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle or 0)
    love.graphics.scale(rx, ry)
    love.graphics.circle(mode, 0, 0, 1)
    love.graphics.pop()
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
        decorProps = {},
        largeBlockers = {}, -- LOS blockers: { x, y, radius, type }
        treeBlockers = {},
        collisionBlockers = {},

        -- Layered world-space ground dressing.
        macroPatches = {},
        storyDecals = {},
        storyRegions = {},
        groundDecor = {},

        -- Optional art-driven assets.
        assets = {
            grassDirt = nil,
            forestSheet = nil,
            fungiSheet = nil,
            forestQuads = nil,
            winluTreeSheet = nil,
            winluDecorSheet = nil,
            winluFloorSheet = nil,
            spriteEntries = {},
            floorTileKeys = {},
            floorAccentKeys = {},
            floorPatternW = 48,
            floorPatternH = 48,
        },

        -- Legacy overlay ambience. Kept empty; world-space ambience reads better.
        ambientSpecks = {},
    }
    setmetatable(tilemap, ForestTilemap)
    tilemap:loadAssets()
    tilemap:initAmbientSpecks()
    return tilemap
end

function ForestTilemap:loadAssets()
    local forestCfg = Config.ForestScene or {}
    self.assets.spriteEntries = {}
    self.assets.floorTileKeys = {}
    self.assets.floorAccentKeys = {}
    self.assets.floorPatternW = 48
    self.assets.floorPatternH = 48

    local function registerSprite(key, image, quad)
        if key and image and quad then
            self.assets.spriteEntries[key] = {
                image = image,
                quad = quad,
            }
        end
    end

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
        for key, quad in pairs(self.assets.forestQuads) do
            registerSprite(key, self.assets.forestSheet, quad)
        end
    end

    self.assets.fungiSheet = safeImage(forestCfg.fungiSheet or "assets/forest/fungi_sheet.png")

    self.assets.winluTreeSheet = safeImage(
        forestCfg.winluTreeSheet
            or "assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/characters/!$Big_Trees_green_NoShadow.png"
    )
    if self.assets.winluTreeSheet then
        local iw, ih = self.assets.winluTreeSheet:getDimensions()
        local cellW, cellH = 192, 288
        local treeKeys = {
            "winlu_tree_1",
            "winlu_tree_2",
            "winlu_tree_3",
            "winlu_tree_4",
            "winlu_tree_5",
            "winlu_tree_6",
        }
        local index = 1
        for row = 0, 1 do
            for col = 0, 2 do
                local key = treeKeys[index]
                if key then
                    registerSprite(
                        key,
                        self.assets.winluTreeSheet,
                        love.graphics.newQuad(col * cellW, row * cellH, cellW, cellH, iw, ih)
                    )
                    index = index + 1
                end
            end
        end
    end

    self.assets.winluDecorSheet = safeImage(
        forestCfg.winluDecorSheet
            or "assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/tilesets/Fantasy_Outside_D_green_NoShadow.png"
    )
    if self.assets.winluDecorSheet then
        local iw, ih = self.assets.winluDecorSheet:getDimensions()
        local tile = 48
        local rockCoords = {
            winlu_rock_1 = { 8, 4 },
            winlu_rock_2 = { 9, 4 },
            winlu_rock_3 = { 8, 5 },
            winlu_rock_4 = { 9, 5 },
        }
        for key, coord in pairs(rockCoords) do
            registerSprite(
                key,
                self.assets.winluDecorSheet,
                love.graphics.newQuad(coord[1] * tile, coord[2] * tile, tile, tile, iw, ih)
            )
        end
    end

    self.assets.winluFloorSheet = safeImage(
        forestCfg.winluFloorSheet
            or "assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/tilesets/Fantasy_Outside_A5_green.png"
    )
    if self.assets.winluFloorSheet then
        local iw, ih = self.assets.winluFloorSheet:getDimensions()
        local patchX = 240
        local patchY = 96
        local patchW = 96
        local patchH = 96
        local floorKey = "winlu_floor_base"
        registerSprite(
            floorKey,
            self.assets.winluFloorSheet,
            love.graphics.newQuad(patchX, patchY, patchW, patchH, iw, ih)
        )
        self.assets.floorTileKeys[1] = floorKey
        self.assets.floorPatternW = patchW
        self.assets.floorPatternH = patchH
    end
end

function ForestTilemap:initAmbientSpecks()
    self.ambientSpecks = {}
end

function ForestTilemap:generate()
    if self.generated then return end

    local worldW, worldH = worldSize()
    local areaScale = (worldW * worldH) / (2640 * 1760)
    local centerX, centerY = worldW * 0.5, worldH * 0.5
    local centerPlayRx = 250
    local centerPlayRy = 180
    local laneHalfW = 82
    local laneHalfH = 74
    local laneReachX = math.floor(worldW * 0.34)
    local laneReachY = math.floor(worldH * 0.32)
    local storyRegions = {
        { kind = "shrine_glade", x = centerX, y = centerY - worldH * 0.18, rx = 188, ry = 122 },
        { kind = "logging_camp", x = centerX + worldW * 0.18, y = centerY + 64, rx = 214, ry = 144 },
        { kind = "flower_meadow", x = centerX - worldW * 0.18, y = centerY + worldH * 0.15, rx = 214, ry = 146 },
        { kind = "fallen_hollow", x = centerX - worldW * 0.17, y = centerY - worldH * 0.13, rx = 184, ry = 132 },
    }
    local clusterAnchors = {
        { x = 170, y = 170, rx = 160, ry = 120 },
        { x = worldW - 170, y = 170, rx = 160, ry = 120 },
        { x = 170, y = worldH - 170, rx = 160, ry = 120 },
        { x = worldW - 170, y = worldH - 170, rx = 160, ry = 120 },
        { x = worldW * 0.5, y = 135, rx = 220, ry = 90 },
        { x = worldW * 0.5, y = worldH - 135, rx = 220, ry = 90 },
        { x = 125, y = worldH * 0.5, rx = 95, ry = 170 },
        { x = worldW - 125, y = worldH * 0.5, rx = 95, ry = 170 },
    }

    local function isReservedGameplaySpace(x, y, padding)
        padding = padding or 0
        if inEllipse(x, y, centerX, centerY, centerPlayRx + padding, centerPlayRy + padding) then
            return true
        end
        if math.abs(x - centerX) <= (laneHalfW + padding) and math.abs(y - centerY) <= (laneReachY + padding) then
            return true
        end
        if math.abs(y - centerY) <= (laneHalfH + padding) and math.abs(x - centerX) <= (laneReachX + padding) then
            return true
        end
        for _, region in ipairs(storyRegions) do
            if inEllipse(x, y, region.x, region.y, region.rx * 0.62 + padding, region.ry * 0.62 + padding) then
                return true
            end
        end
        return false
    end

    local function edgeWeight(x, y)
        local nearestEdge = math.min(x, y, worldW - x, worldH - y)
        if nearestEdge < 120 then
            return 1.0
        elseif nearestEdge < 220 then
            return 0.7
        end
        return 0.35
    end

    local function nearClusterAnchor(x, y)
        for _, anchor in ipairs(clusterAnchors) do
            if inEllipse(x, y, anchor.x, anchor.y, anchor.rx, anchor.ry) then
                return true
            end
        end
        return false
    end

    local function nearStoryRegionRim(x, y)
        for _, region in ipairs(storyRegions) do
            if inEllipse(x, y, region.x, region.y, region.rx * 1.18, region.ry * 1.18)
                and not inEllipse(x, y, region.x, region.y, region.rx * 0.72, region.ry * 0.72) then
                return true
            end
        end
        return false
    end

    self.trees = {}
    self.smallTrees = {}
    self.bushes = {}
    self.rocks = {}
    self.decorProps = {}
    self.largeBlockers = {}
    self.treeBlockers = {}
    self.collisionBlockers = {}
    self.macroPatches = {}
    self.storyDecals = {}
    self.storyRegions = storyRegions
    self.groundDecor = {}

    local usingWinluTrees = self.assets.winluTreeSheet ~= nil
    local usingWinluDecor = self.assets.winluDecorSheet ~= nil
    local usingWinluFloor = self.assets.winluFloorSheet ~= nil
    local treeTypes = {
        { key = "pine_tree_1", ox = 32, oy = 96, scale = 1.0, smallScale = 0.72, collisionRadius = 14, collisionOffsetY = -10 },
        { key = "pine_tree_2", ox = 32, oy = 96, scale = 1.0, smallScale = 0.72, collisionRadius = 14, collisionOffsetY = -10 },
        { key = "oak_tree_3", ox = 32, oy = 96, scale = 1.0, smallScale = 0.72, collisionRadius = 18, collisionOffsetY = -12 },
        { key = "oak_tree_4", ox = 32, oy = 96, scale = 1.0, smallScale = 0.72, collisionRadius = 18, collisionOffsetY = -12 },
        { key = "dead_tree_5", ox = 32, oy = 96, scale = 1.0, smallScale = 0.72, collisionRadius = 12, collisionOffsetY = -10 },
    }
    if usingWinluTrees then
        treeTypes = {
            -- Match the provided reference: one tall pine + one rounded tree.
            { key = "winlu_tree_3", ox = 96, oy = 288, scale = 0.40, smallScale = 0.23, collisionRadius = 14, collisionOffsetY = -10, drawOffsetY = 18, smallDrawOffsetY = 10 },
            { key = "winlu_tree_4", ox = 96, oy = 288, scale = 0.36, smallScale = 0.21, collisionRadius = 18, collisionOffsetY = -12, drawOffsetY = 16, smallDrawOffsetY = 9 },
        }
    end
    local bushTypes = { "bush_1", "bush_2", "bush_3" }
    local rockTypes = {
        { key = "mossy_rock_a", ox = 16, oy = 32, scale = 1.0, blockerScale = 1.4 },
        { key = "mossy_rock_b", ox = 16, oy = 32, scale = 1.0, blockerScale = 1.4 },
    }
    local blockerRockTypes = rockTypes
    if usingWinluDecor then
        rockTypes = {
            -- Keep only safe decorative rock sprites; exclude the cave/hole tile.
            { key = "winlu_rock_4", ox = 24, oy = 48, scale = 0.88, blockerScale = 2.30 },
            { key = "winlu_rock_4", ox = 24, oy = 48, scale = 0.76, blockerScale = 2.30 },
        }
        blockerRockTypes = {
            -- Use one consistent blocker sprite so collision can match the visible footprint.
            { key = "winlu_rock_3", ox = 24, oy = 48, scale = 0.84, blockerScale = 2.35, blockerRadius = 40, collisionOffsetY = -18, drawOffsetY = 14 },
        }
    end
    local treeCount = math.floor((usingWinluTrees and 7 or 18) * areaScale + 0.5)
    local smallTreeCount = math.floor((usingWinluTrees and 10 or 20) * areaScale + 0.5)
    local bushCount = math.floor((usingWinluDecor and 14 or 34) * areaScale + 0.5)
    local rockCount = math.floor((usingWinluDecor and 18 or 24) * areaScale + 0.5)
    local largeBlockerCount = math.floor((usingWinluDecor and 7 or 8) * math.max(1.0, areaScale * 0.92) + 0.5)
    local function addScattered(list, count, minDist, margin, makeItem)
        local tries = count * 20
        while #list < count and tries > 0 do
            tries = tries - 1
            local x = math.random(margin, worldW - margin)
            local y = math.random(margin, worldH - margin)

            if isReservedGameplaySpace(x, y, minDist * 0.35) then
                goto continue
            end

            local favoredZone = nearClusterAnchor(x, y)
            local weight = edgeWeight(x, y)
            if favoredZone then
                weight = math.min(1.0, weight + 0.35)
            end
            if nearStoryRegionRim(x, y) then
                weight = math.min(1.0, weight + 0.24)
            end
            if math.random() > weight then
                goto continue
            end

            if canPlace(list, x, y, minDist) then
                list[#list + 1] = makeItem(x, y)
            end
            ::continue::
        end
    end

    addScattered(self.trees, treeCount, 150, 110, function(x, y)
        local spriteDef = treeTypes[math.random(1, #treeTypes)]
        return {
            x = x,
            y = y,
            sprite = spriteDef.key,
            spriteOx = spriteDef.ox,
            spriteOy = spriteDef.oy,
            spriteScale = spriteDef.scale,
            spriteSmallScale = spriteDef.smallScale,
            drawOffsetY = spriteDef.drawOffsetY or 0,
            smallDrawOffsetY = spriteDef.smallDrawOffsetY or 0,
            collisionRadius = spriteDef.collisionRadius,
            collisionOffsetY = spriteDef.collisionOffsetY,
            trunkW = 7 + math.random(0, 3),
            trunkH = 16 + math.random(0, 6),
            crownR = 18 + math.random(0, 10),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.smallTrees, smallTreeCount, 118, 100, function(x, y)
        local spriteDef = treeTypes[math.random(1, #treeTypes)]
        return {
            x = x,
            y = y,
            sprite = spriteDef.key,
            spriteOx = spriteDef.ox,
            spriteOy = spriteDef.oy,
            spriteScale = spriteDef.scale,
            spriteSmallScale = spriteDef.smallScale,
            drawOffsetY = spriteDef.drawOffsetY or 0,
            smallDrawOffsetY = spriteDef.smallDrawOffsetY or 0,
            trunkW = 5 + math.random(0, 2),
            trunkH = 10 + math.random(0, 4),
            crownR = 12 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.bushes, bushCount, 90, 80, function(x, y)
        return {
            x = x,
            y = y,
            sprite = bushTypes[math.random(1, #bushTypes)],
            radius = 8 + math.random(0, 7),
            drawOffsetY = 5,
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(self.rocks, rockCount, 90, 80, function(x, y)
        local spriteDef = rockTypes[math.random(1, #rockTypes)]
        return {
            x = x,
            y = y,
            sprite = spriteDef.key,
            spriteOx = spriteDef.ox,
            spriteOy = spriteDef.oy,
            spriteScale = spriteDef.scale,
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
    local blockerAnchors = {
        { x = centerX - 420, y = centerY - 250 },
        { x = centerX + 420, y = centerY - 250 },
        { x = centerX - 420, y = centerY + 250 },
        { x = centerX + 420, y = centerY + 250 },
        { x = centerX, y = centerY - 330 },
        { x = centerX, y = centerY + 330 },
        { x = centerX - 560, y = centerY },
        { x = centerX + 560, y = centerY },
    }
    local blockerIndex = 1
    addScattered(self.largeBlockers, largeBlockerCount, 260, 150, function(x, y)
        local anchor = blockerAnchors[blockerIndex]
        if anchor then
            x = anchor.x + math.random(-70, 70)
            y = anchor.y + math.random(-55, 55)
            blockerIndex = blockerIndex + 1
        end
        local spriteDef = blockerRockTypes[math.random(1, #blockerRockTypes)]
        local radius = spriteDef.blockerRadius or (28 + math.random(0, 20))
        local typ = math.random() < 0.5 and "large_rock" or "mountain"
        local collisionOffsetY = spriteDef.collisionOffsetY or 0
        return {
            x = x,
            y = y + collisionOffsetY,
            radius = radius,
            type = typ,
            sprite = spriteDef.key,
            spriteOx = spriteDef.ox,
            spriteOy = spriteDef.oy,
            spriteScale = spriteDef.blockerScale,
            drawY = y + (spriteDef.drawOffsetY or 8),
        }
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

    for _, tree in ipairs(self.trees) do
        if tree.collisionRadius and tree.collisionRadius > 0 then
            self.treeBlockers[#self.treeBlockers + 1] = {
                x = tree.x,
                y = tree.y + (tree.collisionOffsetY or -10),
                radius = tree.collisionRadius,
                type = "tree",
            }
        end
    end

    for _, blk in ipairs(self.largeBlockers) do
        self.collisionBlockers[#self.collisionBlockers + 1] = blk
    end
    for _, blk in ipairs(self.treeBlockers) do
        self.collisionBlockers[#self.collisionBlockers + 1] = blk
    end

    local function addMacroPatch(kind, count, marginX, marginY, minRX, maxRX, minRY, maxRY, angle)
        for i = 1, count do
            local x = math.random(marginX, worldW - marginX)
            local y = math.random(marginY, worldH - marginY)
            if kind == "clearing" then
                x = centerX + math.random(-260, 260)
                y = centerY + math.random(-180, 180)
            end
            self.macroPatches[#self.macroPatches + 1] = {
                kind = kind,
                x = x,
                y = y,
                rx = math.random(minRX, maxRX),
                ry = math.random(minRY, maxRY),
                angle = angle or 0,
            }
        end
    end

    local function addTrail(x1, y1, x2, y2, rx, ry)
        local dx = x2 - x1
        local dy = y2 - y1
        local angle = math.atan2(dy, dx)
        local dist = math.sqrt(dx * dx + dy * dy)
        local steps = math.max(2, math.floor(dist / 130))
        for i = 0, steps do
            local t = i / steps
            self.macroPatches[#self.macroPatches + 1] = {
                kind = "trail",
                x = x1 + dx * t,
                y = y1 + dy * t,
                rx = rx + math.random(-8, 8),
                ry = ry + math.random(-4, 4),
                angle = angle,
            }
        end
    end

    self.macroPatches[#self.macroPatches + 1] = {
        kind = "playfield",
        x = centerX,
        y = centerY,
        rx = centerPlayRx + 38,
        ry = centerPlayRy + 28,
    }
    self.macroPatches[#self.macroPatches + 1] = {
        kind = "lane",
        x = centerX,
        y = centerY,
        rx = laneHalfW + 18,
        ry = laneReachY + 24,
    }
    self.macroPatches[#self.macroPatches + 1] = {
        kind = "lane",
        x = centerX,
        y = centerY,
        rx = laneReachX + 22,
        ry = laneHalfH + 18,
    }
    for _, region in ipairs(storyRegions) do
        addTrail(centerX, centerY, region.x, region.y, 84, 20)
    end
    addTrail(storyRegions[1].x, storyRegions[1].y, storyRegions[4].x, storyRegions[4].y, 58, 16)
    addTrail(storyRegions[4].x, storyRegions[4].y, storyRegions[3].x, storyRegions[3].y, 54, 16)
    addTrail(storyRegions[2].x, storyRegions[2].y, storyRegions[3].x, storyRegions[3].y, 64, 18)

    local function addStoryDecal(kind, x, y, radius, extra)
        local decal = {
            kind = kind,
            x = x,
            y = y,
            radius = radius,
            phase = math.random() * math.pi * 2,
        }
        if extra then
            for key, value in pairs(extra) do
                decal[key] = value
            end
        end
        self.storyDecals[#self.storyDecals + 1] = decal
    end

    addStoryDecal("stone_ring", centerX, centerY - 26, 34)
    addStoryDecal("shrine_core", centerX, centerY - 26, 12)
    addStoryDecal("trail_marks", centerX - 120, centerY + 82, 32, { angle = -0.62 })
    addStoryDecal("trail_marks", centerX + 136, centerY + 28, 38, { angle = 0.08 })

    for _, blk in ipairs(self.largeBlockers) do
        addStoryDecal("pebbles", blk.x + math.random(-28, 28), (blk.drawY or blk.y) + math.random(18, 34), 14 + math.random() * 8)
    end
    for _, tree in ipairs(self.trees) do
        if math.random() < 0.6 then
            addStoryDecal("needle_bed", tree.x + math.random(-8, 8), tree.y + math.random(4, 14), 18 + math.random() * 10)
        end
    end
    for _, region in ipairs(storyRegions) do
        if region.kind == "logging_camp" then
            for i = 1, 5 do
                addStoryDecal("log_cluster", region.x + math.random(-90, 90), region.y + math.random(-54, 54), 18 + math.random() * 10)
            end
            for i = 1, 4 do
                addStoryDecal("stump_cluster", region.x + math.random(-110, 110), region.y + math.random(-62, 62), 12 + math.random() * 8)
            end
            addStoryDecal("trail_marks", region.x - 58, region.y + 18, 36, { angle = 0.10 })
        elseif region.kind == "flower_meadow" then
            for i = 1, 12 do
                addStoryDecal("flower_patch", region.x + math.random(-120, 120), region.y + math.random(-84, 84), 16 + math.random() * 16)
            end
        elseif region.kind == "shrine_glade" then
            addStoryDecal("stone_ring", region.x, region.y, 42)
            addStoryDecal("shrine_core", region.x, region.y, 14)
            for i = 1, 4 do
                addStoryDecal("flower_patch", region.x + math.random(-70, 70), region.y + math.random(-46, 46), 12 + math.random() * 10)
            end
        elseif region.kind == "fallen_hollow" then
            for i = 1, 5 do
                addStoryDecal("fallen_log", region.x + math.random(-100, 100), region.y + math.random(-70, 70), 18 + math.random() * 14)
            end
            for i = 1, 4 do
                addStoryDecal("needle_bed", region.x + math.random(-110, 110), region.y + math.random(-72, 72), 22 + math.random() * 12)
            end
        end
    end

    -- Tiny clumps/specks to emulate richer floor painting.
    local decorCount
    if usingWinluFloor then
        decorCount = math.floor((worldW * worldH) / (220 * 220))
    else
        decorCount = math.floor((worldW * worldH) / (96 * 96))
    end
    for i = 1, decorCount do
        local kind
        if usingWinluFloor then
            local roll = math.random()
            if roll < 0.05 then
                kind = "flower"
            elseif roll < 0.10 then
                kind = "tuft"
            else
                kind = "leaf"
            end
        else
            kind = "leaf"
        end
        self.groundDecor[#self.groundDecor + 1] = {
            x = math.random(0, worldW),
            y = math.random(0, worldH),
            kind = kind,
            size = 1 + math.random() * 2.8,
            phase = math.random() * math.pi * 2,
        }
    end

    self.generated = true
end

function ForestTilemap:update(dt)
    return
end

local function drawGroundShadow(x, y, rx, ry, alpha)
    love.graphics.setColor(0.06, 0.10, 0.05, alpha or 0.14)
    love.graphics.ellipse("fill", x, y, rx, ry)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawMacroPatch(patch)
    if patch.kind == "playfield" then
        love.graphics.setColor(0.44, 0.68, 0.40, 0.05)
    elseif patch.kind == "lane" then
        love.graphics.setColor(0.42, 0.64, 0.38, 0.035)
    elseif patch.kind == "trail" then
        love.graphics.setColor(0.38, 0.34, 0.22, 0.125)
    else
        return
    end
    drawRotatedEllipse("fill", patch.x, patch.y, patch.rx, patch.ry, patch.angle)
end

local function drawStoryDecal(decal)
    if decal.kind == "pebbles" then
        love.graphics.setColor(0.28, 0.33, 0.29, 0.34)
        for i = 1, 4 do
            local a = decal.phase + i * 1.37
            local rr = decal.radius * (0.35 + i * 0.12)
            love.graphics.circle("fill", decal.x + math.cos(a) * rr, decal.y + math.sin(a) * rr * 0.45, 1 + (i % 2))
        end
    elseif decal.kind == "needle_bed" then
        love.graphics.setColor(0.22, 0.32, 0.18, 0.22)
        love.graphics.ellipse("fill", decal.x, decal.y, decal.radius, decal.radius * 0.42)
        love.graphics.setColor(0.30, 0.40, 0.22, 0.18)
        for i = -2, 2 do
            local x = decal.x + i * (decal.radius * 0.18)
            love.graphics.line(x, decal.y + decal.radius * 0.18, x - 2, decal.y - decal.radius * 0.16)
        end
    elseif decal.kind == "log_cluster" or decal.kind == "fallen_log" then
        local angle = decal.phase
        local length = decal.radius * (decal.kind == "fallen_log" and 1.7 or 1.35)
        local width = decal.radius * 0.28
        love.graphics.push()
        love.graphics.translate(decal.x, decal.y)
        love.graphics.rotate(angle)
        love.graphics.setColor(0.34, 0.22, 0.12, 0.9)
        love.graphics.rectangle("fill", -length * 0.5, -width, length, width * 2, width, width)
        love.graphics.setColor(0.46, 0.30, 0.18, 0.55)
        love.graphics.rectangle("fill", -length * 0.42, -width * 0.55, length * 0.84, width * 1.1, width * 0.7, width * 0.7)
        love.graphics.setColor(0.62, 0.48, 0.28, 0.65)
        love.graphics.circle("line", -length * 0.5, 0, width * 0.85)
        love.graphics.circle("line", length * 0.5, 0, width * 0.85)
        love.graphics.pop()
    elseif decal.kind == "stump_cluster" then
        love.graphics.setColor(0.34, 0.24, 0.16, 0.88)
        for i = 1, 3 do
            local a = decal.phase + i * 2.1
            local rr = decal.radius * (0.25 + i * 0.15)
            local x = decal.x + math.cos(a) * rr
            local y = decal.y + math.sin(a) * rr * 0.7
            love.graphics.circle("fill", x, y, 4 + i)
            love.graphics.setColor(0.70, 0.56, 0.36, 0.45)
            love.graphics.circle("line", x, y, 3 + i)
            love.graphics.setColor(0.34, 0.24, 0.16, 0.88)
        end
    elseif decal.kind == "flower_patch" then
        for i = 1, 8 do
            local a = decal.phase + i * 0.8
            local rr = decal.radius * (0.18 + (i % 4) * 0.18)
            local x = decal.x + math.cos(a) * rr
            local y = decal.y + math.sin(a) * rr * 0.72
            love.graphics.setColor(0.92, 0.82, 0.56, 0.34)
            love.graphics.circle("fill", x, y, 1.5)
            love.graphics.setColor(0.84, 0.94, 1.0, 0.26)
            love.graphics.circle("fill", x + 2, y - 1, 1.2)
            love.graphics.setColor(0.96, 0.72, 0.84, 0.22)
            love.graphics.circle("fill", x - 1, y + 2, 1.1)
        end
    elseif decal.kind == "stone_ring" then
        love.graphics.setColor(0.34, 0.38, 0.40, 0.82)
        for i = 0, 7 do
            local a = decal.phase + i * (math.pi * 2 / 8)
            local x = decal.x + math.cos(a) * decal.radius
            local y = decal.y + math.sin(a) * decal.radius * 0.74
            love.graphics.circle("fill", x, y, 3.5)
        end
        love.graphics.setColor(0.78, 0.86, 0.94, 0.20)
        love.graphics.circle("line", decal.x, decal.y, decal.radius * 0.68)
    elseif decal.kind == "shrine_core" then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.74, 0.92, 1.0, 0.32)
        love.graphics.circle("fill", decal.x, decal.y, decal.radius * 1.4)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0.70, 0.84, 0.96, 0.88)
        love.graphics.circle("line", decal.x, decal.y, decal.radius)
        love.graphics.line(decal.x - decal.radius * 0.8, decal.y, decal.x + decal.radius * 0.8, decal.y)
        love.graphics.line(decal.x, decal.y - decal.radius * 0.8, decal.x, decal.y + decal.radius * 0.8)
    elseif decal.kind == "trail_marks" then
        love.graphics.push()
        love.graphics.translate(decal.x, decal.y)
        love.graphics.rotate(decal.angle or 0)
        love.graphics.setColor(0.34, 0.30, 0.20, 0.30)
        love.graphics.rectangle("fill", -decal.radius * 0.75, -decal.radius * 0.18, decal.radius * 1.5, decal.radius * 0.12, 2, 2)
        love.graphics.rectangle("fill", -decal.radius * 0.75, decal.radius * 0.08, decal.radius * 1.5, decal.radius * 0.12, 2, 2)
        love.graphics.pop()
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

    if self.assets.floorTileKeys and #self.assets.floorTileKeys > 0 then
        -- Use a seamless grass field instead of repeating transition/autotile edges.
        love.graphics.setColor(0.33, 0.62, 0.36, 1)
        love.graphics.rectangle("fill", 0, 0, worldW, worldH)
        love.graphics.setColor(0.18, 0.36, 0.20, 0.05)
        love.graphics.rectangle("fill", 0, 0, worldW, worldH)
    elseif self.assets.grassDirt then
        local img = self.assets.grassDirt
        local iw, ih = img:getDimensions()
        local quad = love.graphics.newQuad(0, 0, worldW + tile * 2, worldH + tile * 2, iw, ih)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, quad, -tile, -tile)

        -- Slightly brighter grade to improve readability.
        love.graphics.setColor(0.16, 0.34, 0.24, 0.20)
        love.graphics.rectangle("fill", 0, 0, worldW, worldH)
    else
        for y = 0, tilesY do
            for x = 0, tilesX do
                local n = seeded01(x, y)
                if n < 0.50 then
                    love.graphics.setColor(0.17, 0.36, 0.22, 1)
                elseif n < 0.75 then
                    love.graphics.setColor(0.19, 0.39, 0.25, 1)
                elseif n < 0.92 then
                    love.graphics.setColor(0.21, 0.42, 0.27, 1)
                else
                    love.graphics.setColor(0.15, 0.31, 0.20, 1)
                end
                love.graphics.rectangle("fill", x * tile, y * tile, tile, tile)
            end
        end
    end

    -- Large-value composition pass to break up the flat green field.
    for _, patch in ipairs(self.macroPatches or {}) do
        drawMacroPatch(patch)
    end

    for _, decal in ipairs(self.storyDecals or {}) do
        drawStoryDecal(decal)
    end

    -- Ground micro-detail pass.
    for _, d in ipairs(self.groundDecor) do
        if d.kind == "leaf" then
            love.graphics.setColor(0.42, 0.62, 0.37, 0.24)
            love.graphics.rectangle("fill", d.x, d.y, d.size * 1.4, d.size * 0.8)
        elseif d.kind == "flower" then
            love.graphics.setColor(0.92, 0.84, 0.62, 0.28)
            love.graphics.circle("fill", d.x, d.y, d.size * 0.28)
            love.graphics.setColor(0.84, 0.94, 1.0, 0.22)
            love.graphics.circle("fill", d.x - d.size * 0.5, d.y, d.size * 0.22)
            love.graphics.circle("fill", d.x + d.size * 0.5, d.y, d.size * 0.22)
            love.graphics.circle("fill", d.x, d.y - d.size * 0.45, d.size * 0.20)
            love.graphics.circle("fill", d.x, d.y + d.size * 0.45, d.size * 0.20)
        elseif d.kind == "tuft" then
            love.graphics.setColor(0.26, 0.48, 0.24, 0.26)
            love.graphics.setLineWidth(1)
            love.graphics.line(d.x, d.y + d.size * 0.5, d.x - d.size * 0.35, d.y - d.size * 0.5)
            love.graphics.line(d.x, d.y + d.size * 0.5, d.x, d.y - d.size * 0.6)
            love.graphics.line(d.x, d.y + d.size * 0.5, d.x + d.size * 0.35, d.y - d.size * 0.5)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function drawProceduralTree(tree, small)
    local t = love.timer.getTime()
    local sway = math.sin(t * (small and 0.9 or 0.6) + tree.swayOffset) * (small and 0.8 or 1.2)
    local trunkX = tree.x + sway
    local baseY = tree.y

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
    love.graphics.setColor(0.12, 0.22, 0.12, 1)
    love.graphics.circle("fill", x, y, bush.radius)
    love.graphics.setColor(0.17, 0.30, 0.16, 0.85)
    love.graphics.circle("fill", x - bush.radius * 0.25, y - bush.radius * 0.2, bush.radius * 0.45)
end

local function drawProceduralLargeBlocker(blk)
    local x, y = blk.x, blk.y
    local r = blk.radius
    local isMountain = blk.type == "mountain"
    if isMountain then
        love.graphics.setColor(0.31, 0.34, 0.36, 0.96)
        love.graphics.polygon("fill",
            x - r * 0.95, y + r * 0.35,
            x - r * 0.42, y - r * 0.68,
            x + r * 0.06, y - r * 0.92,
            x + r * 0.72, y - r * 0.34,
            x + r * 0.96, y + r * 0.28
        )
        love.graphics.setColor(0.45, 0.48, 0.51, 0.88)
        love.graphics.polygon("fill",
            x - r * 0.18, y - r * 0.46,
            x + r * 0.10, y - r * 0.78,
            x + r * 0.42, y - r * 0.28,
            x + r * 0.10, y - r * 0.12
        )
    else
        love.graphics.setColor(0.38, 0.41, 0.43, 0.96)
        love.graphics.polygon("fill",
            x - r * 0.92, y - r * 0.10,
            x - r * 0.54, y - r * 0.76,
            x + r * 0.22, y - r * 0.68,
            x + r * 0.88, y - r * 0.12,
            x + r * 0.66, y + r * 0.56,
            x - r * 0.26, y + r * 0.78
        )
        love.graphics.setColor(0.54, 0.57, 0.59, 0.76)
        love.graphics.polygon("fill",
            x - r * 0.16, y - r * 0.34,
            x + r * 0.18, y - r * 0.54,
            x + r * 0.46, y - r * 0.10,
            x + r * 0.06, y + r * 0.06
        )
    end
    if isMountain then
        love.graphics.setColor(0.22, 0.25, 0.27, 0.8)
        love.graphics.line(x - r * 0.48, y + r * 0.18, x - r * 0.06, y - r * 0.50)
        love.graphics.line(x - r * 0.06, y - r * 0.50, x + r * 0.40, y - r * 0.02)
    else
        love.graphics.setColor(0.24, 0.27, 0.29, 0.82)
        love.graphics.line(x - r * 0.40, y + r * 0.28, x + r * 0.16, y - r * 0.24)
        love.graphics.line(x - r * 0.02, y + r * 0.50, x + r * 0.44, y + r * 0.04)
    end
end

local function drawProceduralRock(rock)
    local x, y = rock.x, rock.y
    local rx, ry = rock.rx, rock.ry
    local tint = rock.tint
    love.graphics.setColor(tint, tint, tint + 0.02, 1)
    love.graphics.ellipse("fill", x, y, rx, ry)
    love.graphics.setColor(tint + 0.12, tint + 0.12, tint + 0.12, 0.65)
    love.graphics.ellipse("fill", x - rx * 0.25, y - ry * 0.2, rx * 0.45, ry * 0.35)
end

function ForestTilemap:drawSprite(spriteKey, x, y, ox, oy, sx, sy)
    local entry = self.assets.spriteEntries and self.assets.spriteEntries[spriteKey]
    if not entry then
        local sheet = self.assets.forestSheet
        local quads = self.assets.forestQuads
        local quad = quads and quads[spriteKey]
        if not (sheet and quad) then return false end
        entry = {
            image = sheet,
            quad = quad,
        }
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(entry.image, entry.quad, x, y, 0, sx or 1, sy or sx or 1, ox or 0, oy or 0)
    return true
end

function ForestTilemap:getTreesForSorting()
    local result = {}
    for _, tree in ipairs(self.trees) do
        local drawY = tree.y + (tree.drawOffsetY or 0)
        result[#result + 1] = {
            x = tree.x,
            y = drawY,
            draw = function()
                local sway = math.sin(love.timer.getTime() * 0.6 + tree.swayOffset) * 1.2
                drawGroundShadow(tree.x, drawY + 5, 24, 7, 0.14)
                local drewSprite = self:drawSprite(
                    tree.sprite,
                    tree.x + sway,
                    drawY,
                    tree.spriteOx or 32,
                    tree.spriteOy or 96,
                    tree.spriteScale or 1.0
                )
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
        local drawY = bush.y + (bush.drawOffsetY or 0)
        result[#result + 1] = {
            x = bush.x,
            y = drawY,
            draw = function()
                local sway = math.sin(love.timer.getTime() * 1.05 + bush.swayOffset) * 0.8
                drawGroundShadow(bush.x, drawY + 1, bush.radius * 0.85, 3, 0.14)
                local drewSprite = self:drawSprite(bush.sprite, bush.x + sway, drawY, 24, 48, 1.0)
                if not drewSprite then
                    local oldY = bush.y
                    bush.y = drawY
                    drawProceduralBush(bush)
                    bush.y = oldY
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
        local drawY = tree.y + (tree.smallDrawOffsetY or tree.drawOffsetY or 0)
        result[#result + 1] = {
            x = tree.x,
            y = drawY,
            draw = function()
                local sway = math.sin(love.timer.getTime() * 0.9 + tree.swayOffset) * 0.9
                drawGroundShadow(tree.x, drawY + 4, 16, 5, 0.12)
                local drewSprite = self:drawSprite(
                    tree.sprite,
                    tree.x + sway,
                    drawY + 4,
                    tree.spriteOx or 32,
                    tree.spriteOy or 96,
                    tree.spriteSmallScale or tree.spriteScale or 0.72
                )
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
                drawGroundShadow(rock.x, rock.y + 1, 14, 4, 0.16)
                local drewSprite = self:drawSprite(
                    rock.sprite,
                    rock.x,
                    rock.y,
                    rock.spriteOx or 16,
                    rock.spriteOy or 32,
                    rock.spriteScale or 1.0
                )
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
            y = blk.drawY or blk.y,
            draw = function()
                local shadowY = (blk.drawY or blk.y) + 4
                drawGroundShadow(blk.x, shadowY, (blk.radius or 36) * 0.85, 7, 0.20)
                local drewSprite = self:drawSprite(
                    blk.sprite,
                    blk.x,
                    blk.drawY or (blk.y + 8),
                    blk.spriteOx or 24,
                    blk.spriteOy or 48,
                    blk.spriteScale or 1.4
                )
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
    return
end

function ForestTilemap:getLargeBlockers()
    if not self.generated then
        self:generate()
    end
    return self.largeBlockers or {}
end

function ForestTilemap:getCollisionBlockers()
    if not self.generated then
        self:generate()
    end
    return self.collisionBlockers or self.largeBlockers or {}
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
