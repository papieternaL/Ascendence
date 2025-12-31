-- Tilemap System - Procedural grass with variation
local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap:new()
    local tilemap = {
        tileSize = 32,
        -- Store grass color variations
        grassTiles = {},
        flowers = {},
        grassPatches = {},
        generated = false
    }
    setmetatable(tilemap, Tilemap)
    return tilemap
end

function Tilemap:generate()
    if self.generated then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local tilesX = math.ceil(screenWidth / self.tileSize) + 1
    local tilesY = math.ceil(screenHeight / self.tileSize) + 1
    
    -- Generate grass color variation for each tile
    self.grassTiles = {}
    for y = 0, tilesY do
        self.grassTiles[y] = {}
        for x = 0, tilesX do
            -- Base green with random variation
            local variation = math.random() * 0.15
            local darkPatch = math.random() < 0.3 -- 30% chance of darker patch
            
            if darkPatch then
                self.grassTiles[y][x] = {
                    r = 0.28 + variation * 0.5,
                    g = 0.55 + variation,
                    b = 0.15 + variation * 0.3
                }
            else
                self.grassTiles[y][x] = {
                    r = 0.35 + variation,
                    g = 0.65 + variation,
                    b = 0.20 + variation * 0.5
                }
            end
        end
    end
    
    -- Generate darker grass patches (larger areas)
    self.grassPatches = {}
    local numPatches = math.random(8, 15)
    for i = 1, numPatches do
        table.insert(self.grassPatches, {
            x = math.random(0, screenWidth),
            y = math.random(0, screenHeight),
            radius = math.random(40, 100),
            darkness = math.random() * 0.1 + 0.05
        })
    end
    
    -- Generate small flowers/details
    self.flowers = {}
    local numFlowers = math.random(30, 50)
    for i = 1, numFlowers do
        local flowerType = math.random(1, 4)
        local flower = {
            x = math.random(20, screenWidth - 20),
            y = math.random(60, screenHeight - 20),
            type = flowerType
        }
        
        if flowerType == 1 then
            -- White flowers (daisies)
            flower.color = {1, 1, 1}
            flower.size = math.random(2, 4)
        elseif flowerType == 2 then
            -- Yellow flowers
            flower.color = {1, 0.9, 0.3}
            flower.size = math.random(2, 3)
        elseif flowerType == 3 then
            -- Blue flowers
            flower.color = {0.4, 0.6, 1}
            flower.size = math.random(2, 4)
        else
            -- Small grass tufts
            flower.color = {0.3, 0.5, 0.2}
            flower.size = math.random(3, 5)
            flower.isGrass = true
        end
        
        table.insert(self.flowers, flower)
    end
    
    self.generated = true
end

function Tilemap:update(dt)
    -- Could add subtle animation here
end

function Tilemap:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Make sure we've generated the map
    if not self.generated then
        self:generate()
    end
    
    -- Draw base grass tiles
    for y = 0, math.ceil(screenHeight / self.tileSize) do
        for x = 0, math.ceil(screenWidth / self.tileSize) do
            local tile = self.grassTiles[y] and self.grassTiles[y][x]
            if tile then
                love.graphics.setColor(tile.r, tile.g, tile.b, 1)
            else
                love.graphics.setColor(0.35, 0.6, 0.2, 1)
            end
            love.graphics.rectangle("fill", 
                x * self.tileSize, 
                y * self.tileSize, 
                self.tileSize, 
                self.tileSize)
        end
    end
    
    -- Draw darker grass patches (circular overlays)
    for _, patch in ipairs(self.grassPatches) do
        -- Draw gradient circle
        for r = patch.radius, 1, -5 do
            local alpha = (patch.darkness) * (r / patch.radius)
            love.graphics.setColor(0.2, 0.4, 0.1, alpha)
            love.graphics.circle("fill", patch.x, patch.y, r)
        end
    end
    
    -- Draw grid lines (subtle)
    love.graphics.setColor(0.25, 0.45, 0.15, 0.15)
    for x = 0, screenWidth, self.tileSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, self.tileSize do
        love.graphics.line(0, y, screenWidth, y)
    end
    
    -- Draw flowers and grass tufts
    for _, flower in ipairs(self.flowers) do
        if flower.isGrass then
            -- Draw grass tuft
            love.graphics.setColor(flower.color[1], flower.color[2], flower.color[3], 0.8)
            -- Draw 3 small lines for grass
            for i = -1, 1 do
                local offsetX = i * 2
                love.graphics.line(
                    flower.x + offsetX, flower.y,
                    flower.x + offsetX + i, flower.y - flower.size
                )
            end
        else
            -- Draw flower
            love.graphics.setColor(flower.color[1], flower.color[2], flower.color[3], 1)
            love.graphics.circle("fill", flower.x, flower.y, flower.size)
            -- Flower center
            if flower.type == 1 then
                love.graphics.setColor(1, 0.8, 0.2, 1)
                love.graphics.circle("fill", flower.x, flower.y, flower.size * 0.4)
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Tilemap
