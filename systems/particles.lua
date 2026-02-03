-- Particle System for Explosions
local Particles = {}
Particles.__index = Particles

function Particles:new()
    local system = {
        particles = {}
    }
    setmetatable(system, Particles)
    return system
end

function Particles:createExplosion(x, y, color)
    color = color or {1, 0.3, 0.1} -- Default orange/red
    local numParticles = 20
    
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2 + math.random() * 0.5
        local speed = 50 + math.random() * 100
        local lifetime = 0.3 + math.random() * 0.2
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 3 + math.random() * 4,
            lifetime = lifetime,
            age = 0,
            color = {
                color[1] + (math.random() - 0.5) * 0.3,
                color[2] + (math.random() - 0.5) * 0.3,
                color[3] + (math.random() - 0.5) * 0.3
            }
        })
    end
end

function Particles:createDashTrail(x, y)
    -- Create a few particles for dash trail
    for i = 1, 3 do
        local offsetX = (math.random() - 0.5) * 10
        local offsetY = (math.random() - 0.5) * 10
        
        table.insert(self.particles, {
            x = x + offsetX,
            y = y + offsetY,
            vx = 0,
            vy = 0,
            size = 4 + math.random() * 3,
            lifetime = 0.2,
            age = 0,
            color = {0.5, 0.7, 1} -- Blue dash trail
        })
    end
end

function Particles:createHitSpark(x, y, color)
    color = color or {1, 1, 0.5}
    local numParticles = 8
    
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2
        local speed = 80 + math.random() * 50
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 2 + math.random() * 2,
            lifetime = 0.15,
            age = 0,
            color = color
        })
    end
end

function Particles:createFrenzyMist(x, y)
    -- Golden mist particles for Frenzy effect
    for i = 1, 3 do
        local offsetX = (math.random() - 0.5) * 20
        local offsetY = (math.random() - 0.5) * 20
        local speed = 20 + math.random() * 30
        local angle = math.random() * math.pi * 2

        table.insert(self.particles, {
            x = x + offsetX,
            y = y + offsetY,
            vx = math.cos(angle) * speed * 0.5,
            vy = math.sin(angle) * speed * 0.5 - 30,  -- Upward drift
            size = 6 + math.random() * 4,
            lifetime = 0.5 + math.random() * 0.5,
            age = 0,
            color = {
                1.0,  -- Red
                0.6 + math.random() * 0.3,  -- Green (orange tint)
                0.1 + math.random() * 0.2   -- Blue (minimal)
            },
            mistParticle = true  -- Flag for special rendering
        })
    end
end

function Particles:createBleedEffect(x, y)
    -- Red dripping blood droplets
    for i = 1, 3 do
        local offsetX = (math.random() - 0.5) * 10  -- Slight spread
        table.insert(self.particles, {
            x = x + offsetX,
            y = y,
            vx = (math.random() - 0.5) * 15,
            vy = math.random() * 25 + 10,  -- Drip downward
            size = math.random() + 1.5,  -- 1.5-2.5px droplets
            lifetime = 0.8,
            age = 0,
            color = {0.8, 0.1, 0.1},  -- Dark red
            bleedParticle = true,  -- Flag for special rendering with gravity
        })
    end
end

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        if p.bleedParticle then
            -- Bleed particles have gravity
            p.vy = p.vy + 80 * dt
        else
            -- Regular particles have friction
            p.vx = p.vx * 0.95
            p.vy = p.vy * 0.95
        end

        p.age = p.age + dt

        if p.age >= p.lifetime then
            table.remove(self.particles, i)
        end
    end
end

function Particles:createAmbientLeaves(x, y)
    -- Floating leaf particles for ambient forest feel
    table.insert(self.particles, {
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 20,
        vy = -10 - math.random() * 15,
        size = 2 + math.random() * 2,
        lifetime = 2.0 + math.random() * 1.0,
        age = 0,
        color = {0.3 + math.random() * 0.3, 0.6 + math.random() * 0.2, 0.2},
        ambientParticle = true
    })
end

function Particles:draw()
    for i, p in ipairs(self.particles) do
        local alpha = 1 - (p.age / p.lifetime)

        if p.mistParticle then
            -- Mist particles have softer, glowing appearance
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.6)
            love.graphics.circle("fill", p.x, p.y, p.size * alpha * 1.5)

            -- Inner glow
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
            love.graphics.circle("fill", p.x, p.y, p.size * alpha * 2.5)
        elseif p.ambientParticle then
            -- Ambient particles (leaves) have softer rendering
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.4)
            love.graphics.circle("fill", p.x, p.y, p.size)
        else
            -- Regular particles
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.circle("fill", p.x, p.y, p.size * alpha)
        end
    end
end

return Particles

