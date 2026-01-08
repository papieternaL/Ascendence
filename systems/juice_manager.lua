-- JuiceManager: Global feedback effects (hit-stop, shake, flash)
-- Inspired by Ember Knights and Hades for impactful combat feel

local JuiceManager = {
    -- Freeze/Hit-stop state
    freezeRemaining = 0,
    
    -- Flash tracking (entity -> flash time remaining)
    flashEntities = {},
    
    -- Reference to screen shake (set by scenes)
    screenShake = nil,
}

-- Set the screen shake reference (called by scenes on load)
function JuiceManager.setScreenShake(shakeSystem)
    JuiceManager.screenShake = shakeSystem
end

-- Hit-Stop: Freeze game logic for a brief moment
-- Creates that "impact" feeling on heavy hits
function JuiceManager.freezeTime(duration)
    duration = duration or 0.05
    JuiceManager.freezeRemaining = math.max(JuiceManager.freezeRemaining, duration)
end

-- Check if game should be frozen (call at top of update loops)
function JuiceManager.isFrozen()
    return JuiceManager.freezeRemaining > 0
end

-- Update freeze timer (call once per frame in main.lua or a central place)
function JuiceManager.update(dt)
    if JuiceManager.freezeRemaining > 0 then
        JuiceManager.freezeRemaining = JuiceManager.freezeRemaining - dt
        if JuiceManager.freezeRemaining < 0 then
            JuiceManager.freezeRemaining = 0
        end
    end
    
    -- Update flash timers
    for entity, timeLeft in pairs(JuiceManager.flashEntities) do
        JuiceManager.flashEntities[entity] = timeLeft - dt
        if JuiceManager.flashEntities[entity] <= 0 then
            JuiceManager.flashEntities[entity] = nil
        end
    end
end

-- Screen Shake: Delegate to existing shake system
function JuiceManager.shake(intensity, duration)
    if JuiceManager.screenShake then
        JuiceManager.screenShake:add(intensity, duration)
    end
end

-- Flash: Make an entity render pure white for a brief moment
function JuiceManager.flash(entity, duration)
    if entity then
        duration = duration or 0.08 -- ~2 frames at 60fps
        JuiceManager.flashEntities[entity] = duration
    end
end

-- Check if an entity should render as white flash
function JuiceManager.isFlashing(entity)
    return JuiceManager.flashEntities[entity] and JuiceManager.flashEntities[entity] > 0
end

-- Trigger all three effects at once (for heavy impacts like Power Shot)
function JuiceManager.impact(entity, freezeDuration, shakeIntensity, shakeDuration, flashDuration)
    JuiceManager.freezeTime(freezeDuration or 0.05)
    JuiceManager.shake(shakeIntensity or 8, shakeDuration or 0.15)
    JuiceManager.flash(entity, flashDuration or 0.08)
end

return JuiceManager

