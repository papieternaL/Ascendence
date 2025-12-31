-- Tree Entity (using sprite)
local Tree = {}
Tree.__index = Tree

-- Static images (loaded once)
Tree.treeImage = nil
Tree.bushImage = nil

function Tree:new(x, y, isBush)
    -- Load images if not loaded (with fallbacks)
    if not Tree.treeImage then
        local success, result = pcall(love.graphics.newImage, "images/tree.PNG")
        if success then
            Tree.treeImage = result
            Tree.treeImage:setFilter("nearest", "nearest")
        end
    end
    if not Tree.bushImage then
        local success, result = pcall(love.graphics.newImage, "images/bush.PNG")
        if success then
            Tree.bushImage = result
            Tree.bushImage:setFilter("nearest", "nearest")
        end
    end
    
    local tree = {
        x = x or 0,
        y = y or 0,
        isBush = isBush or false,
        scale = isBush and 0.5 or 0.6, -- Bushes smaller than trees
        size = isBush and 20 or 35, -- Collision size
        bobOffset = 0,
        bobSpeed = 1 + math.random() * 0.5,
        bobAmount = 2
    }
    setmetatable(tree, Tree)
    return tree
end

function Tree:update(dt)
    -- Gentle swaying animation
    self.bobOffset = math.sin(love.timer.getTime() * self.bobSpeed + self.x) * self.bobAmount
end

function Tree:draw()
    local img = self.isBush and Tree.bushImage or Tree.treeImage
    local imgW = img:getWidth()
    local imgH = img:getHeight()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        img,
        self.x,
        self.y + self.bobOffset,
        0, -- rotation
        self.scale, self.scale,
        imgW / 2, imgH -- Center bottom origin
    )
end

function Tree:getPosition()
    return self.x, self.y
end

function Tree:getSize()
    return self.size
end

return Tree
