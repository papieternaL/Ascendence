-- Forest Scene - Rich environment with tiling background, asset sheet, procedural map,
-- atmospheric particles, and interactive camera. Designed for integration with game flow.
local Scene = require("scenes.scene")
local Config = require("data.config")

local ForestScene = {}
ForestScene.__index = ForestScene
setmetatable(ForestScene, Scene)

-- Asset paths (add images to these paths; procedural fallback when missing)
local ASSET_PATHS = {
    grassDirt = "assets/forest/grass_dirt.png",
    forestSheet = "assets/forest/forest_sheet.png",
    fungiSheet = "assets/forest/fungi_sheet.png",
}

-- Seeded random for deterministic procedural generation
local function seeded01(ix, iy, seed)
    seed = seed or 12345
    local v = (ix * 73856093 + iy * 19349663 + seed) % 1000
    return v / 999
end

local function distSq(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return dx * dx + dy * dy
end

function ForestScene:new(opts)
    opts = opts or {}
    local scene = {
        player = opts.player,
        worldWidth = opts.worldWidth or (Config.World and Config.World.width or 1920),
        worldHeight = opts.worldHeight or (Config.World and Config.World.height or 1080),
        assets = {},
        worldMap = {},
        camera = { x = 0, y = 0},
        particleSystem = nil,
        drawables = {},
        seed = opts.seed or math.random(1, 99999),
    }
    setmetatable(scene, ForestScene)
    return scene
end

function ForestScene:load()
    self.assets = {}
    self.worldMap = {}
    self.drawables = {}

    -- Load grass/dirt tiling background (512x512)
    local ok, img = pcall(love.graphics.newImage, ASSET_PATHS.grassDirt)
    if ok and img then
        img:setFilter("nearest", "nearest")
        img:setWrap("repeat", "repeat")
        self.assets.grassDirt = img
    else
        self.assets.grassDirt = nil
    end

    -- Load forest asset sheet
    ok, img = pcall(love.graphics.newImage, ASSET_PATHS.forestSheet)
    if ok and img then
        img:setFilter("nearest", "nearest")
        self.assets.forestSheet = img
        local iw, ih = img:getDimensions()
        -- Quad definitions (adjust x,y,w,h to match your sheet layout)
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
    else
        self.assets.forestSheet = nil
        self.assets.forestQuads = nil
    end

    -- Load fungi sheet
    ok, img = pcall(love.graphics.newImage, ASSET_PATHS.fungiSheet)
    if ok and img then
        img:setFilter("nearest", "nearest")
        self.assets.fungiSheet = img
        local iw, ih = img:getDimensions()
        self.assets.fungiQuads = {
            small_spores = love.graphics.newQuad(0, 0, 24, 24, iw, ih),
            mushroom_cluster = love.graphics.newQuad(24, 0, 48, 48, iw, ih),
            light_specks = love.graphics.newQuad(72, 0, 16, 16, iw, ih),
        }
    else
        self.assets.fungiSheet = nil
        self.assets.fungiQuads = nil
    end

    -- Generate procedural world map
    self:generateWorldMap()

    -- Atmospheric particle system (1x1 white pixel for soft spore effect)
    local imgData = love.image.newImageData(1, 1)
    imgData:setPixel(0, 0, 1, 1, 1, 1)
    local particleImg = love.graphics.newImage(imgData)
    self.particleSystem = love.graphics.newParticleSystem(particleImg, 256)
    self.particleSystem:setParticleLifetime(4, 8)
    self.particleSystem:setEmissionRate(8)
    self.particleSystem:setSizes(0.5, 0.5, 0.2)
    self.particleSystem:setSizeVariation(0.5)
    self.particleSystem:setLinearAcceleration(-20, -20, 20, 20)
    self.particleSystem:setLinearDamping(0.1)
    self.particleSystem:setSpread(math.pi * 2)
    self.particleSystem:setSpeed(15, 30)
    self.particleSystem:setColors(
        0.4, 0.7, 0.9, 0.15,
        0.3, 0.6, 0.85, 0.08,
        0.2, 0.5, 0.8, 0
    )
    self.particleSystem:setEmissionArea("uniform", 400, 400, 0, 0, 0)
    self.particleSystem:setEmitterLifetime(-1)
    self.particleSystem:start()

    -- Camera position (will be updated in update)
    local px, py = self.worldWidth * 0.5, self.worldHeight * 0.5
    if self.player then
        px, py = self.player.x or px, self.player.y or py
    end
    self.camera.x = math.max(0, px - love.graphics.getWidth() / 2)
    self.camera.y = math.max(0, py - love.graphics.getHeight() / 2)
end

function ForestScene:generateWorldMap()
    local worldW, worldH = self.worldWidth, self.worldHeight
    local tileSize = 32
    local centerX, centerY = worldW * 0.5, worldH * 0.5
    local centerSoftRadiusSq = 180 * 180

    local function canPlace(list, x, y, minDist)
        local minDistSq = minDist * minDist
        for _, item in ipairs(list) do
            if distSq(item.x, item.y, x, y) < minDistSq then return false end
        end
        return true
    end

    local trees = {}
    local bushes = {}
    local rocks = {}
    local fungi = {}
    local roots = {}

    local treeTypes = {"pine_tree_1", "pine_tree_2", "oak_tree_3", "oak_tree_4", "dead_tree_5"}
    local bushTypes = {"bush_1", "bush_2", "bush_3"}
    local rockTypes = {"mossy_rock_a", "mossy_rock_b"}
    local fungiTypes = {"small_spores", "mushroom_cluster", "light_specks"}

    local function addScattered(list, count, minDist, margin, makeItem)
        local tries = count * 20
        while #list < count and tries > 0 do
            tries = tries - 1
            local x = math.random(margin, worldW - margin)
            local y = math.random(margin, worldH - margin)
            local inCenter = distSq(x, y, centerX, centerY) < centerSoftRadiusSq
            if inCenter and math.random() < 0.65 then goto continue end
            if canPlace(list, x, y, minDist) then
                list[#list + 1] = makeItem(x, y)
            end
            ::continue::
        end
    end

    addScattered(trees, 14, 110, 70, function(x, y)
        return {
            x = x, y = y,
            type = treeTypes[math.random(1, #treeTypes)],
            trunkW = 7 + math.random(0, 3),
            trunkH = 16 + math.random(0, 6),
            crownR = 18 + math.random(0, 10),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(bushes, 28, 52, 40, function(x, y)
        return {
            x = x, y = y,
            type = bushTypes[math.random(1, #bushTypes)],
            radius = 8 + math.random(0, 7),
            swayOffset = math.random() * math.pi * 2,
        }
    end)

    addScattered(rocks, 22, 56, 45, function(x, y)
        return {
            x = x, y = y,
            type = rockTypes[math.random(1, #rockTypes)],
            rx = 7 + math.random(0, 7),
            ry = 5 + math.random(0, 5),
            tint = 0.52 + math.random() * 0.08,
        }
    end)

    -- Fungi clusters (light sources)
    addScattered(fungi, 12, 90, 80, function(x, y)
        return {
            x = x, y = y,
            type = fungiTypes[math.random(1, #fungiTypes)],
            glow = 0.6 + math.random() * 0.4,
        }
    end)

    addScattered(roots, 8, 120, 60, function(x, y)
        return { x = x, y = y, type = "root_clump" }
    end)

    self.worldMap = {
        trees = trees,
        bushes = bushes,
        rocks = rocks,
        fungi = fungi,
        roots = roots,
    }
end

function ForestScene:update(dt)
    local px, py = self.worldWidth * 0.5, self.worldHeight * 0.5
    if self.player then
        px = self.player.x or px
        py = self.player.y or py
    end

    -- Camera smoothing
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local desiredX = math.max(0, math.min(px - sw / 2, self.worldWidth - sw))
    local desiredY = math.max(0, math.min(py - sh / 2, self.worldHeight - sh))
    self.camera.x = self.camera.x + (desiredX - self.camera.x) * 0.15 * 60 * dt
    self.camera.y = self.camera.y + (desiredY - self.camera.y) * 0.15 * 60 * dt

    -- Update particle system
    if self.particleSystem then
        self.particleSystem:update(dt)
    end
end

function ForestScene:draw()
    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- 1. Tiling background
    self:drawTilingBackground()

    -- 2. Build Y-sorted drawables
    local drawables = self:buildDrawables()

    -- 3. Draw environment (Y-sorted)
    table.sort(drawables, function(a, b) return a.y < b.y end)
    for _, d in ipairs(drawables) do
        d.draw()
    end

    -- 4. Player (if provided) - drawn by caller typically; optional here
    if self.player and self.player.draw then
        self.player:draw()
    end

    love.graphics.pop()

    -- 5. Atmospheric overlays (screen-space, after pop)
    self:drawAtmosphericOverlay()

    -- 6. Particle system (world-space, centered on player area)
    local px, py = self.worldWidth * 0.5, self.worldHeight * 0.5
    if self.player then
        px = self.player.x or px
        py = self.player.y or py
    end
    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)
    love.graphics.draw(self.particleSystem, px, py)
    love.graphics.pop()
end

function ForestScene:drawTilingBackground()
    local tileSize = 32
    local worldW, worldH = self.worldWidth, self.worldHeight
    local tilesX = math.ceil(worldW / tileSize) + 2
    local tilesY = math.ceil(worldH / tileSize) + 2

    if self.assets.grassDirt then
        local img = self.assets.grassDirt
        local iw, ih = img:getDimensions()
        local quad = love.graphics.newQuad(0, 0, worldW + 512, worldH + 512, iw, ih)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, quad, -tileSize, -tileSize)
    else
        -- Procedural grass/dirt
        for y = -1, tilesY do
            for x = -1, tilesX do
                local n = seeded01(x, y, self.seed)
                if n < 0.50 then
                    love.graphics.setColor(0.18, 0.32, 0.18, 1)
                elseif n < 0.75 then
                    love.graphics.setColor(0.20, 0.34, 0.20, 1)
                elseif n < 0.92 then
                    love.graphics.setColor(0.22, 0.36, 0.22, 1)
                else
                    love.graphics.setColor(0.18, 0.28, 0.16, 1)
                end
                love.graphics.rectangle("fill", x * tileSize, y * tileSize, tileSize, tileSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function ForestScene:buildDrawables()
    local list = {}
    local t = love.timer.getTime()

    local function drawProceduralTree(tree)
        local sway = math.sin(t * 0.6 + tree.swayOffset) * 1.2
        local trunkX = tree.x + sway
        love.graphics.setColor(0.06, 0.10, 0.06, 0.35)
        love.graphics.ellipse("fill", trunkX, tree.y + 2, tree.crownR * 0.72, 4)
        love.graphics.setColor(0.34, 0.23, 0.14, 1)
        love.graphics.rectangle("fill", trunkX - tree.trunkW * 0.5, tree.y - tree.trunkH, tree.trunkW, tree.trunkH)
        love.graphics.setColor(0.11, 0.23, 0.12, 1)
        love.graphics.circle("fill", trunkX, tree.y - tree.trunkH - tree.crownR * 0.45, tree.crownR)
        love.graphics.setColor(0.16, 0.29, 0.16, 0.9)
        love.graphics.circle("fill", trunkX - tree.crownR * 0.22, tree.y - tree.trunkH - tree.crownR * 0.58, tree.crownR * 0.55)
    end

    local function drawProceduralBush(bush)
        local sway = math.sin(t * 1.05 + bush.swayOffset) * 0.8
        local x, y = bush.x + sway, bush.y
        love.graphics.setColor(0.08, 0.12, 0.08, 0.25)
        love.graphics.ellipse("fill", x, y + 2, bush.radius * 0.85, 3)
        love.graphics.setColor(0.12, 0.22, 0.12, 1)
        love.graphics.circle("fill", x, y, bush.radius)
        love.graphics.setColor(0.17, 0.30, 0.16, 0.85)
        love.graphics.circle("fill", x - bush.radius * 0.25, y - bush.radius * 0.2, bush.radius * 0.45)
    end

    local function drawProceduralRock(rock)
        love.graphics.setColor(0.09, 0.10, 0.10, 0.25)
        love.graphics.ellipse("fill", rock.x, rock.y + 2, rock.rx * 1.05, 3)
        love.graphics.setColor(rock.tint, rock.tint, rock.tint + 0.02, 1)
        love.graphics.ellipse("fill", rock.x, rock.y, rock.rx, rock.ry)
    end

    local function drawProceduralFungi(f)
        love.graphics.setColor(0.2, 0.6, 0.9, 0.4 * f.glow)
        love.graphics.circle("fill", f.x, f.y, 12)
        love.graphics.setColor(0.3, 0.8, 1.0, 0.6 * f.glow)
        love.graphics.circle("fill", f.x, f.y, 6)
    end

    local function drawProceduralRoot(r)
        love.graphics.setColor(0.28, 0.22, 0.16, 1)
        love.graphics.ellipse("fill", r.x, r.y, 18, 12)
    end

    for _, tree in ipairs(self.worldMap.trees or {}) do
        list[#list + 1] = {
            x = tree.x, y = tree.y,
            draw = function()
                if self.assets.forestSheet and self.assets.forestQuads and self.assets.forestQuads[tree.type] then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(self.assets.forestSheet, self.assets.forestQuads[tree.type], tree.x - 32, tree.y - 96, 0, 1, 1)
                else
                    drawProceduralTree(tree)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end

    for _, bush in ipairs(self.worldMap.bushes or {}) do
        list[#list + 1] = {
            x = bush.x, y = bush.y,
            draw = function()
                if self.assets.forestSheet and self.assets.forestQuads and self.assets.forestQuads[bush.type] then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(self.assets.forestSheet, self.assets.forestQuads[bush.type], bush.x - 24, bush.y - 24, 0, 1, 1)
                else
                    drawProceduralBush(bush)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end

    for _, rock in ipairs(self.worldMap.rocks or {}) do
        list[#list + 1] = {
            x = rock.x, y = rock.y,
            draw = function()
                if self.assets.forestSheet and self.assets.forestQuads and self.assets.forestQuads[rock.type] then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(self.assets.forestSheet, self.assets.forestQuads[rock.type], rock.x - 16, rock.y - 16, 0, 1, 1)
                else
                    drawProceduralRock(rock)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end

    for _, f in ipairs(self.worldMap.fungi or {}) do
        list[#list + 1] = {
            x = f.x, y = f.y,
            draw = function()
                if self.assets.fungiSheet and self.assets.fungiQuads and self.assets.fungiQuads[f.type] then
                    love.graphics.setColor(1, 1, 1, f.glow)
                    love.graphics.draw(self.assets.fungiSheet, self.assets.fungiQuads[f.type], f.x - 24, f.y - 24, 0, 1, 1)
                else
                    drawProceduralFungi(f)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end

    for _, r in ipairs(self.worldMap.roots or {}) do
        list[#list + 1] = {
            x = r.x, y = r.y,
            draw = function()
                if self.assets.forestSheet and self.assets.forestQuads and self.assets.forestQuads[r.type] then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(self.assets.forestSheet, self.assets.forestQuads[r.type], r.x - 24, r.y - 24, 0, 1, 1)
                else
                    drawProceduralRoot(r)
                end
                love.graphics.setColor(1, 1, 1, 1)
            end,
        }
    end

    return list
end

function ForestScene:drawAtmosphericOverlay()
    love.graphics.push()
    love.graphics.origin()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Subtle blue/purple mist (alpha ~0.08)
    love.graphics.setColor(0.15, 0.18, 0.28, 0.08)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function ForestScene:unload()
    return true
end

return ForestScene
