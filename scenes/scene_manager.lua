-- Scene Manager - handles switching between scenes
local SceneManager = {}
SceneManager.currentScene = nil

function SceneManager.init()
    -- Initialize the scene manager
end

function SceneManager.switch(newScene)
    -- Unload current scene if it exists
    if SceneManager.currentScene and SceneManager.currentScene.unload then
        SceneManager.currentScene:unload()
    end
    
    -- Switch to new scene
    SceneManager.currentScene = newScene
    
    -- Load the new scene
    if newScene and newScene.load then
        newScene:load()
    end
end

function SceneManager.update(dt)
    if SceneManager.currentScene and SceneManager.currentScene.update then
        SceneManager.currentScene:update(dt)
    end
end

function SceneManager.draw()
    if SceneManager.currentScene and SceneManager.currentScene.draw then
        SceneManager.currentScene:draw()
    end
end

function SceneManager.keypressed(key)
    if SceneManager.currentScene and SceneManager.currentScene.keypressed then
        SceneManager.currentScene:keypressed(key)
    end
end

function SceneManager.mousepressed(x, y, button)
    if SceneManager.currentScene and SceneManager.currentScene.mousepressed then
        SceneManager.currentScene:mousepressed(x, y, button)
    end
end

return SceneManager

