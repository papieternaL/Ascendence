-- Screen Shake System
local ScreenShake = {}
ScreenShake.__index = ScreenShake

function ScreenShake:new()
    local shake = {
        intensity = 0,
        duration = 0,
        time = 0,
        offsetX = 0,
        offsetY = 0
    }
    setmetatable(shake, ScreenShake)
    return shake
end

function ScreenShake:add(intensity, duration)
    self.intensity = math.max(self.intensity, intensity)
    self.duration = math.max(self.duration, duration)
    self.time = 0
end

function ScreenShake:update(dt)
    if self.duration > 0 then
        self.time = self.time + dt
        
        if self.time < self.duration then
            local progress = self.time / self.duration
            local currentIntensity = self.intensity * (1 - progress)
            
            -- Random shake offset
            self.offsetX = (math.random() - 0.5) * currentIntensity * 2
            self.offsetY = (math.random() - 0.5) * currentIntensity * 2
        else
            self.duration = 0
            self.intensity = 0
            self.offsetX = 0
            self.offsetY = 0
        end
    end
end

function ScreenShake:getOffset()
    return self.offsetX, self.offsetY
end

return ScreenShake

