-- Base Scene Class
local Scene = {}
Scene.__index = Scene

function Scene:new()
    local scene = {}
    setmetatable(scene, Scene)
    return scene
end

function Scene:load()
    -- Override in child classes
end

function Scene:update(dt)
    -- Override in child classes
end

function Scene:draw()
    -- Override in child classes
end

function Scene:keypressed(key)
    -- Override in child classes
end

function Scene:mousepressed(x, y, button)
    -- Override in child classes
end

function Scene:unload()
    -- Override in child classes for cleanup
end

return Scene

