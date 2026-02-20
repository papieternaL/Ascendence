-- LÖVE2D Configuration File
function love.conf(t)
    t.title = "LÖVE2D Game"
    t.version = "11.5"
    
    -- Window settings
    t.window.width = 1920
    t.window.height = 1080
    t.window.resizable = true
    t.window.minwidth = 640
    t.window.minheight = 360
    
    -- Enable modules
    t.modules.joystick = false
    t.modules.physics = false
end

