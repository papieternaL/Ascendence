-- Pixel-Art Particle System
-- All particles render as small pixel squares for a crisp retro look.

local Particles = {}
Particles.__index = Particles

function Particles:new()
    local system = {
        particles = {},
    }
    setmetatable(system, Particles)
    return system
end

---------------------------------------------------------------------------
-- Core emitters
---------------------------------------------------------------------------

-- Color-aware pixel burst explosion (no sprite)
function Particles:createExplosion(x, y, color)
    color = color or {1, 0.5, 0.1}
    local numParticles = 12
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2 + (math.random() - 0.5) * 0.5
        local speed = 80 + math.random() * 60
        self.particles[#self.particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 2 + math.random(0, 2),
            lifetime = 0.12 + math.random() * 0.08,
            age = 0,
            color = {
                math.min(1, color[1] + (math.random() - 0.5) * 0.2),
                math.min(1, color[2] + (math.random() - 0.5) * 0.2),
                math.min(1, color[3] + (math.random() - 0.5) * 0.2),
            },
            gravity = 0,
        }
    end
end

function Particles:createHitSpark(x, y, color)
    color = color or {1, 1, 0.5}
    local numParticles = 6
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2 + (math.random() - 0.5) * 0.4
        local speed = 60 + math.random() * 50
        self.particles[#self.particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 2 + math.random(0, 1),
            lifetime = 0.12 + math.random() * 0.06,
            age = 0,
            color = color,
            gravity = 0,
        }
    end
end

function Particles:createDashTrail(x, y)
    for i = 1, 4 do
        self.particles[#self.particles + 1] = {
            x = x + (math.random() - 0.5) * 12,
            y = y + (math.random() - 0.5) * 12,
            vx = (math.random() - 0.5) * 15,
            vy = (math.random() - 0.5) * 15,
            size = 3 + math.random(0, 2),
            lifetime = 0.18 + math.random() * 0.08,
            age = 0,
            color = {0.4, 0.6, 1},
            gravity = 0,
        }
    end
end

---------------------------------------------------------------------------
-- New VFX emitters for combat systems
---------------------------------------------------------------------------

-- Chain lightning impact: bold blue burst at target (high visibility)
function Particles:createChainLightningImpact(x, y)
    local color = {0.55, 0.85, 1.0}
    for i = 1, 18 do
        local angle = (i / 18) * math.pi * 2 + (math.random() - 0.5) * 0.6
        local speed = 110 + math.random() * 90
        self.particles[#self.particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 3 + math.random(0, 2),
            lifetime = 0.22 + math.random() * 0.12,
            age = 0,
            color = {
                math.min(1, color[1] + math.random() * 0.25),
                math.min(1, color[2] + math.random() * 0.2),
                1,
            },
            gravity = 0,
        }
    end
end

-- Lightning arc: bold jagged line (denser, brighter, more defined for chain lightning)
function Particles:createLightningArc(x1, y1, x2, y2, color)
    color = color or {0.55, 0.8, 1.0}
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0 then dist = 1 end
    local steps = math.max(8, math.floor(dist / 8))
    local perpX = -dy / dist
    local perpY = dx / dist

    local prevX, prevY = x1, y1
    for i = 1, steps do
        local t = i / steps
        local baseX = x1 + dx * t
        local baseY = y1 + dy * t
        local jag = (math.random() - 0.5) * 20
        local px = baseX + perpX * jag
        local py = baseY + perpY * jag
        local segDist = math.sqrt((px - prevX) ^ 2 + (py - prevY) ^ 2)
        local segSteps = math.max(2, math.floor(segDist / 4))
        for j = 0, segSteps do
            local st = j / math.max(1, segSteps)
            local cx = prevX + (px - prevX) * st
            local cy = prevY + (py - prevY) * st
            -- Bright core
            self.particles[#self.particles + 1] = {
                x = cx,
                y = cy,
                vx = (math.random() - 0.5) * 20,
                vy = (math.random() - 0.5) * 20,
                size = 4 + math.random(0, 2),
                lifetime = 0.28 + math.random() * 0.1,
                age = 0,
                color = {
                    math.min(1, color[1] + math.random() * 0.4),
                    math.min(1, color[2] + math.random() * 0.35),
                    1,
                },
                gravity = 0,
            }
            -- Outer glow (slightly offset, softer)
            local off = (math.random() - 0.5) * 6
            self.particles[#self.particles + 1] = {
                x = cx + perpX * off,
                y = cy + perpY * off,
                vx = (math.random() - 0.5) * 16,
                vy = (math.random() - 0.5) * 16,
                size = 3 + math.random(0, 1),
                lifetime = 0.22 + math.random() * 0.08,
                age = 0,
                color = {
                    math.min(1, color[1] * 0.85 + math.random() * 0.2),
                    math.min(1, color[2] * 0.9 + math.random() * 0.2),
                    0.95,
                },
                gravity = 0,
                baseAlpha = 0.75,
            }
        end
        prevX, prevY = px, py
    end
    self:createChainLightningImpact(x2, y2)
    self:createHitSpark(x1, y1, {0.55, 0.8, 1.0})
end

-- Expanding AOE ring (for hemorrhage, arrowstorm, etc.)
function Particles:createAoeRing(x, y, radius, color)
    color = color or {1, 0.4, 0.1}
    local numParticles = math.max(12, math.floor(radius / 4))
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2
        local r = radius * (0.6 + math.random() * 0.4)
        self.particles[#self.particles + 1] = {
            x = x + math.cos(angle) * r,
            y = y + math.sin(angle) * r,
            vx = math.cos(angle) * 40,
            vy = math.sin(angle) * 40,
            size = 2 + math.random(0, 2),
            lifetime = 0.25 + math.random() * 0.15,
            age = 0,
            color = {
                math.min(1, color[1] + (math.random() - 0.5) * 0.2),
                math.min(1, color[2] + (math.random() - 0.5) * 0.2),
                math.min(1, color[3] + (math.random() - 0.5) * 0.2),
            },
            gravity = 0,
        }
    end
end

-- Ice blast: cold shock ring, ice shard burst, frost mist (distinct on green terrain)
function Particles:createIceBlast(x, y, radius)
    radius = radius or 70
    local color = {0.6, 0.92, 1.0}
    -- Cold shock ring (expanding outward)
    local numRing = math.max(14, math.floor(radius / 5))
    for i = 1, numRing do
        local angle = (i / numRing) * math.pi * 2 + (math.random() - 0.5) * 0.3
        local r = radius * (0.7 + math.random() * 0.3)
        self.particles[#self.particles + 1] = {
            x = x + math.cos(angle) * r,
            y = y + math.sin(angle) * r,
            vx = math.cos(angle) * 55,
            vy = math.sin(angle) * 55,
            size = 3 + math.random(0, 2),
            lifetime = 0.28 + math.random() * 0.12,
            age = 0,
            color = {
                math.min(1, color[1] + (math.random() - 0.5) * 0.15),
                math.min(1, color[2] + (math.random() - 0.5) * 0.15),
                1,
            },
            gravity = 0,
        }
    end
    -- Ice shard burst (bright cyan/white center)
    for i = 1, 16 do
        local angle = (i / 16) * math.pi * 2 + (math.random() - 0.5) * 0.5
        local speed = 90 + math.random() * 70
        self.particles[#self.particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 2 + math.random(0, 2),
            lifetime = 0.2 + math.random() * 0.1,
            age = 0,
            color = {
                0.7 + math.random() * 0.3,
                0.9 + math.random() * 0.1,
                1,
            },
            gravity = 0,
        }
    end
    -- Frost mist accents (short-lived)
    for i = 1, 8 do
        local angle = love.math.random() * math.pi * 2
        local dist = love.math.random() * radius * 0.4
        self.particles[#self.particles + 1] = {
            x = x + math.cos(angle) * dist,
            y = y + math.sin(angle) * dist,
            vx = (math.random() - 0.5) * 40,
            vy = (math.random() - 0.5) * 40,
            size = 2 + math.random(0, 1),
            lifetime = 0.15 + math.random() * 0.1,
            age = 0,
            color = {0.85, 0.95, 1.0},
            gravity = 0,
        }
    end
end

-- Bleed drip: small red pixels falling from entity position (optional color for burn etc.)
function Particles:createBleedDrip(x, y, color)
    color = color or {0.8 + math.random() * 0.2, 0.05, 0.05}
    for i = 1, 2 do
        self.particles[#self.particles + 1] = {
            x = x + (math.random() - 0.5) * 8,
            y = y,
            vx = (math.random() - 0.5) * 10,
            vy = 20 + math.random() * 30,
            size = 2,
            lifetime = 0.3 + math.random() * 0.2,
            age = 0,
            color = color,
            gravity = 80,
        }
    end
end

-- Ghost trail: semi-transparent afterimage pixels
function Particles:createGhostTrail(x, y, color)
    color = color or {0.3, 0.8, 1.0}
    for i = 1, 3 do
        self.particles[#self.particles + 1] = {
            x = x + (math.random() - 0.5) * 10,
            y = y + (math.random() - 0.5) * 10,
            vx = (math.random() - 0.5) * 8,
            vy = -10 - math.random() * 15,
            size = 2 + math.random(0, 2),
            lifetime = 0.2 + math.random() * 0.15,
            age = 0,
            color = color,
            gravity = -20, -- float up
            baseAlpha = 0.6,
        }
    end
end

-- Entangle root burst: green vine-like ring
function Particles:createRootBurst(x, y)
    for i = 1, 10 do
        local angle = (i / 10) * math.pi * 2
        local r = 20 + math.random() * 15
        self.particles[#self.particles + 1] = {
            x = x + math.cos(angle) * r,
            y = y + math.sin(angle) * r,
            vx = math.cos(angle) * 20,
            vy = math.sin(angle) * 20 - 15,
            size = 3 + math.random(0, 1),
            lifetime = 0.4 + math.random() * 0.2,
            age = 0,
            color = {0.1 + math.random() * 0.15, 0.6 + math.random() * 0.3, 0.1},
            gravity = 40,
        }
    end
end

-- Frenzy ongoing aura: light ember wisps around player
function Particles:createFrenzyAura(x, y)
    for i = 1, 6 do
        local angle = math.random() * math.pi * 2
        local r = 12 + math.random() * 20
        local speed = 8 + math.random() * 16
        self.particles[#self.particles + 1] = {
            x = x + math.cos(angle) * r,
            y = y + math.sin(angle) * r,
            vx = math.cos(angle) * speed * 0.3,
            vy = math.sin(angle) * speed * 0.3 - 15,
            size = 2 + math.random(0, 1),
            lifetime = 0.25 + math.random() * 0.15,
            age = 0,
            color = {1, 0.35 + math.random() * 0.35, 0.05},
            gravity = -8,
            baseAlpha = 0.7,
        }
    end
end

-- Frenzy activation burst: fiery orange radial
function Particles:createFrenzyBurst(x, y)
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2 + (math.random() - 0.5) * 0.3
        local speed = 80 + math.random() * 60
        self.particles[#self.particles + 1] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = 2 + math.random(0, 2),
            lifetime = 0.3 + math.random() * 0.2,
            age = 0,
            color = {1, 0.4 + math.random() * 0.4, 0.05},
            gravity = 0,
        }
    end
end

---------------------------------------------------------------------------
-- Update & Draw
---------------------------------------------------------------------------

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.94
        p.vy = p.vy * 0.94
        -- Apply gravity
        if p.gravity then
            p.vy = p.vy + p.gravity * dt
        end
        p.age = p.age + dt
        if p.age >= p.lifetime then
            table.remove(self.particles, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.particles) do
        local t = p.age / p.lifetime
        local alpha = (p.baseAlpha or 1) * (1 - t)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        if p.image then
            -- Sprite-based particle (explosion)
            local scale = 0.4 + (1 - t) * 0.8
            love.graphics.draw(
                p.image,
                p.x, p.y,
                0,
                scale, scale,
                (p.imageW or p.image:getWidth()) / 2,
                (p.imageH or p.image:getHeight()) / 2
            )
        else
            -- Pixel squares
            local s = math.max(1, math.floor(p.size * (1 - t * 0.5) + 0.5))
            love.graphics.rectangle("fill", math.floor(p.x - s / 2), math.floor(p.y - s / 2), s, s)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Particles
