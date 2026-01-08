-- Forest Tilemap System - Lush forest using Kenney assets
local ForestTilemap = {}
ForestTilemap.__index = ForestTilemap

-- Asset paths
local FOLIAGE_PATH = "assets/2D assets/Foliage Pack/PNG/Default size/"
local PIXEL_PLAT_PATH = "assets/2D assets/Pixel Platformer/Tilemap/"

-- Load config for retro settings
local Config = require("data.config")

-- Helper function to draw sprite with thick black outline
local function drawWithOutline(image, x, y, rotation, scaleX, scaleY, originX, originY)
    if not Config.Retro.enabled then
        -- No outline, just draw normally
        love.graphics.draw(image, x, y, rotation, scaleX, scaleY, originX, originY)
        return
    end
    
    local thickness = Config.Retro.outlineThickness
    
    -- Draw black outline in 8 directions
    love.graphics.setColor(0, 0, 0, 1)
    for dx = -thickness, thickness do
        for dy = -thickness, thickness do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.draw(image, x + dx, y + dy, rotation, scaleX, scaleY, originX, originY)
            end
        end
    end
    
    -- Draw the actual sprite on top
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y, rotation, scaleX, scaleY, originX, originY)
end

function ForestTilemap:new()
    local tilemap = {
        tileSize = 18,  -- Pixel Platformer tiles are 18x18
        
        -- Loaded images
        images = {},
        
        -- Background tiles (grass variations)
        grassTiles = {},
        
        -- Decorative elements
        trees = {},
        bushes = {},
        rocks = {},
        flowers = {},
        grassTufts = {},
        
        -- Background image
        backgroundImage = nil,
        
        generated = false
    }
    setmetatable(tilemap, ForestTilemap)
    return tilemap
end

function ForestTilemap:loadAssets()
    -- Load foliage pack images
    local foliageImages = {
        -- Trees (green)
        tree1 = "foliagePack_001.png",  -- Triangle tree
        tree2 = "foliagePack_002.png",  -- Wider triangle
        tree3 = "foliagePack_003.png",  -- Round tree
        tree4 = "foliagePack_004.png",  -- Tall tree
        tree5 = "foliagePack_005.png",  -- Small tree
        tree6 = "foliagePack_006.png",  -- Pine tree
        
        -- Bushes
        bush1 = "foliagePack_017.png",  -- Large bush
        bush2 = "foliagePack_018.png",  -- Medium bush
        bush3 = "foliagePack_019.png",  -- Small bush
        
        -- Rocks
        rock1 = "foliagePack_055.png",  -- Large rock
        rock2 = "foliagePack_056.png",  -- Medium rock
        rock3 = "foliagePack_057.png",  -- Small rock
        
        -- Flowers and grass
        flower1 = "foliagePack_058.png", -- Red flower
        flower2 = "foliagePack_059.png", -- White flower
    }
    
    -- Load each image
    for name, filename in pairs(foliageImages) do
        local path = FOLIAGE_PATH .. filename
        local success, result = pcall(love.graphics.newImage, path)
        if success then
            self.images[name] = result
            self.images[name]:setFilter("nearest", "nearest")
        else
            print("Warning: Could not load " .. path)
        end
    end
    
    -- Load Pixel Platformer background tilemap for grass
    local bgPath = PIXEL_PLAT_PATH .. "tilemap-backgrounds.png"
    local success, result = pcall(love.graphics.newImage, bgPath)
    if success then
        self.backgroundImage = result
        self.backgroundImage:setFilter("nearest", "nearest")
        
        -- Create quads for grass tiles (bottom right area of the tilemap - green section)
        -- The green grass tiles are at rows 6-8, columns 9-11 (0-indexed)
        self.grassQuads = {}
        local tileW, tileH = 18, 18
        local imgW = self.backgroundImage:getWidth()
        local imgH = self.backgroundImage:getHeight()
        
        -- Green grass tiles positions (x, y in tile coords)
        local grassPositions = {
            {9, 5}, {10, 5}, {11, 5},  -- Light grass
            {9, 6}, {10, 6}, {11, 6},  -- Medium grass
            {9, 7}, {10, 7}, {11, 7},  -- Dark grass
        }
        
        for i, pos in ipairs(grassPositions) do
            self.grassQuads[i] = love.graphics.newQuad(
                pos[1] * tileW, pos[2] * tileH,
                tileW, tileH,
                imgW, imgH
            )
        end
    else
        print("Warning: Could not load background tilemap: " .. bgPath)
    end
end

function ForestTilemap:generate()
    if self.generated then return end
    
    -- Load assets first
    self:loadAssets()
    
    -- Use world dimensions instead of screen
    local worldWidth = Config.World and Config.World.width or love.graphics.getWidth()
    local worldHeight = Config.World and Config.World.height or love.graphics.getHeight()
    
    -- Generate grass tile map
    local tilesX = math.ceil(worldWidth / self.tileSize) + 1
    local tilesY = math.ceil(worldHeight / self.tileSize) + 1
    
    self.grassTiles = {}
    for y = 0, tilesY do
        self.grassTiles[y] = {}
        for x = 0, tilesX do
            -- Pick a random grass quad (1-9)
            if self.grassQuads and #self.grassQuads > 0 then
                self.grassTiles[y][x] = math.random(1, #self.grassQuads)
            else
                self.grassTiles[y][x] = 1
            end
        end
    end
    
    -- Generate trees around the edges
    self.trees = {}
    local treeImages = {"tree1", "tree2", "tree3", "tree4", "tree5", "tree6"}
    
    -- Left edge trees (more for larger world)
    for i = 1, 8 do
        local x = math.random(30, 120)
        local y = math.random(80, worldHeight - 100)
        local imgKey = treeImages[math.random(1, #treeImages)]
        if self.images[imgKey] then
            table.insert(self.trees, {
                x = x, y = y,
                image = imgKey,
                scale = 0.6 + math.random() * 0.3,
                swayOffset = math.random() * math.pi * 2
            })
        end
    end
    
    -- Right edge trees
    for i = 1, 8 do
        local x = math.random(worldWidth - 120, worldWidth - 30)
        local y = math.random(80, worldHeight - 100)
        local imgKey = treeImages[math.random(1, #treeImages)]
        if self.images[imgKey] then
            table.insert(self.trees, {
                x = x, y = y,
                image = imgKey,
                scale = 0.6 + math.random() * 0.3,
                swayOffset = math.random() * math.pi * 2
            })
        end
    end
    
    -- Top edge trees
    for i = 1, 6 do
        local x = math.random(150, worldWidth - 150)
        local y = math.random(50, 120)
        local imgKey = treeImages[math.random(1, #treeImages)]
        if self.images[imgKey] then
            table.insert(self.trees, {
                x = x, y = y,
                image = imgKey,
                scale = 0.5 + math.random() * 0.3,
                swayOffset = math.random() * math.pi * 2
            })
        end
    end
    
    -- Generate bushes scattered around (more for larger world)
    self.bushes = {}
    local bushImages = {"bush1", "bush2", "bush3"}
    
    for i = 1, 30 do
        local x = math.random(40, worldWidth - 40)
        local y = math.random(60, worldHeight - 40)
        
        -- Keep away from center (player spawn)
        local dx = x - worldWidth/2
        local dy = y - worldHeight/2
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist > 100 then
            local imgKey = bushImages[math.random(1, #bushImages)]
            if self.images[imgKey] then
                table.insert(self.bushes, {
                    x = x, y = y,
                    image = imgKey,
                    scale = 0.4 + math.random() * 0.3,
                    swayOffset = math.random() * math.pi * 2
                })
            end
        end
    end
    
    -- Generate rocks (more for larger world)
    self.rocks = {}
    local rockImages = {"rock1", "rock2", "rock3"}
    
    for i = 1, 15 do
        local x = math.random(50, worldWidth - 50)
        local y = math.random(70, worldHeight - 50)
        local imgKey = rockImages[math.random(1, #rockImages)]
        if self.images[imgKey] then
            table.insert(self.rocks, {
                x = x, y = y,
                image = imgKey,
                scale = 0.5 + math.random() * 0.4
            })
        end
    end
    
    -- Generate flowers (more for larger world)
    self.flowers = {}
    local flowerImages = {"flower1", "flower2"}
    
    for i = 1, 50 do
        local x = math.random(30, worldWidth - 30)
        local y = math.random(50, worldHeight - 30)
        local imgKey = flowerImages[math.random(1, #flowerImages)]
        if self.images[imgKey] then
            table.insert(self.flowers, {
                x = x, y = y,
                image = imgKey,
                scale = 0.3 + math.random() * 0.2
            })
        end
    end
    
    self.generated = true
end

function ForestTilemap:update(dt)
    -- Could add gentle swaying animations here
end

function ForestTilemap:draw()
    -- Use world dimensions
    local worldWidth = Config.World and Config.World.width or love.graphics.getWidth()
    local worldHeight = Config.World and Config.World.height or love.graphics.getHeight()
    local time = love.timer.getTime()
    
    if not self.generated then
        self:generate()
    end
    
    -- Draw grass tile background
    if self.backgroundImage and self.grassQuads and #self.grassQuads > 0 then
        love.graphics.setColor(1, 1, 1, 1)
        for y = 0, math.ceil(worldHeight / self.tileSize) do
            for x = 0, math.ceil(worldWidth / self.tileSize) do
                local quadIndex = self.grassTiles[y] and self.grassTiles[y][x] or 1
                local quad = self.grassQuads[quadIndex]
                if quad then
                    love.graphics.draw(
                        self.backgroundImage,
                        quad,
                        x * self.tileSize,
                        y * self.tileSize,
                        0, 2, 2  -- Scale up 2x for better visibility
                    )
                end
            end
        end
    else
        -- Fallback: procedural grass
        for y = 0, math.ceil(worldHeight / 32) do
            for x = 0, math.ceil(worldWidth / 32) do
                local variation = math.random() * 0.1
                love.graphics.setColor(0.3 + variation, 0.55 + variation, 0.2 + variation * 0.5, 1)
                love.graphics.rectangle("fill", x * 32, y * 32, 32, 32)
            end
        end
    end
    
    -- Draw flowers (behind everything)
    for _, flower in ipairs(self.flowers) do
        local img = self.images[flower.image]
        if img then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                img,
                flower.x, flower.y,
                0,
                flower.scale, flower.scale,
                img:getWidth()/2, img:getHeight()
            )
        end
    end
    
    -- Draw rocks (with outlines)
    for _, rock in ipairs(self.rocks) do
        local img = self.images[rock.image]
        if img then
            drawWithOutline(
                img,
                rock.x, rock.y,
                0,
                rock.scale, rock.scale,
                img:getWidth()/2, img:getHeight()
            )
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function ForestTilemap:drawTrees()
    -- Draw trees with gentle swaying
    local time = love.timer.getTime()
    
    for _, tree in ipairs(self.trees) do
        local img = self.images[tree.image]
        if img then
            local sway = math.sin(time * 0.5 + tree.swayOffset) * 0.02
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                img,
                tree.x, tree.y,
                sway,
                tree.scale, tree.scale,
                img:getWidth()/2, img:getHeight()
            )
        end
    end
end

function ForestTilemap:drawBushes()
    -- Draw bushes with subtle movement
    local time = love.timer.getTime()
    
    for _, bush in ipairs(self.bushes) do
        local img = self.images[bush.image]
        if img then
            local sway = math.sin(time * 0.8 + bush.swayOffset) * 0.015
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                img,
                bush.x, bush.y,
                sway,
                bush.scale, bush.scale,
                img:getWidth()/2, img:getHeight()
            )
        end
    end
end

function ForestTilemap:getTreesForSorting()
    local result = {}
    for _, tree in ipairs(self.trees) do
        table.insert(result, {
            x = tree.x,
            y = tree.y,
            draw = function()
                local img = self.images[tree.image]
                if img then
                    local time = love.timer.getTime()
                    local sway = math.sin(time * 0.5 + tree.swayOffset) * 0.02
                    drawWithOutline(
                        img, tree.x, tree.y,
                        sway, tree.scale, tree.scale,
                        img:getWidth()/2, img:getHeight()
                    )
                end
            end
        })
    end
    return result
end

function ForestTilemap:getBushesForSorting()
    local result = {}
    for _, bush in ipairs(self.bushes) do
        table.insert(result, {
            x = bush.x,
            y = bush.y,
            draw = function()
                local img = self.images[bush.image]
                if img then
                    local time = love.timer.getTime()
                    local sway = math.sin(time * 0.8 + bush.swayOffset) * 0.015
                    drawWithOutline(
                        img, bush.x, bush.y,
                        sway, bush.scale, bush.scale,
                        img:getWidth()/2, img:getHeight()
                    )
                end
            end
        })
    end
    return result
end

return ForestTilemap












