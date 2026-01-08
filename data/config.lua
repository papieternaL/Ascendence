-- Project Ascendence Central Configuration (SSOT)
local Config = {}

-- Player Balance
Config.Player = {
    baseHealth = 100,
    baseAttack = 10,
    baseSpeed = 200,
    fireRate = 0.4,
    attackRange = 400,
    dashSpeed = 800,
    dashDuration = 0.2,
    dashCooldown = 1.0,
}

-- Ability Specifics
Config.Abilities = {
    powerShot = {
        damageMult = 3.0,
        cooldown = 6.0,
        speed = 760,
        knockback = 260,
    },
    entangle = {
        cooldown = 8.0,
        range = 260,
        duration = 1.5,
        damageMult = 1.15,
    },
    frenzy = {
        duration = 8.0,
        moveSpeedMult = 1.25,
        attackSpeedMult = 1.5,  -- 50% faster attacks
        critChanceAdd = 0.25,
        damageTakenMult = 1.15,
    }
}

-- Boss: Treent Overlord
Config.TreentOverlord = {
    maxHealth = 3500,
    speed = 65,
    damage = 40,
    size = 48,
    
    -- Phase 1
    lungeCooldown = 2.0,
    lungeChargeDuration = 1.2,
    lungeDuration = 0.5,
    lungeSpeed = 800,
    
    barkBarrageCooldown = 3.0,
    barkBarrageCount = 8,
    barkBarrageDelay = 0.08,
    
    -- Phase 2
    encompassRootDuration = 8.0,
    earthquakeCooldown = 10.0,
    earthquakeDuration = 3.0,
    earthquakeCastTime = 5.0,
    earthquakeDamage = 9999, -- Lethal
    
    -- Vine Lanes (replaces earthquake in Phase 2)
    vineLaneCount = 5,           -- Total lanes (1 will be safe)
    vineLaneSpeed = 280,         -- Pixels per second
    vineLaneDamage = 9999,       -- Lethal damage per tick
    vineLaneDuration = 5.0,      -- How long vines are active
    vineLaneCooldown = 12.0,     -- Time between vine attacks
    vineLaneSpacing = 100,       -- Vertical pixels between lanes
}

-- UI Constants
Config.UI = {
    hudWidth = 400,
    hudHeight = 90,
    abilityIconSize = 44,
    abilitySpacing = 12,
    healthBarWidth = 320, -- hudWidth - 80
    healthBarHeight = 16,
}

-- Visuals
Config.Vfx = {
    hitFlashDuration = 0.1,
    knockbackFriction = 0.85,
}

-- Retro Art Style
Config.Retro = {
    enabled = false,  -- DISABLED - back to original look
    internalWidth = 1280,
    internalHeight = 720,
    outlineThickness = 2,
    scanlineIntensity = 0.08,
    paletteEnabled = false,
    pixelScale = 1,
}

-- World Size (larger explorable map)
Config.World = {
    width = 2400,   -- Roughly 2x typical screen width
    height = 1600,  -- Roughly 2x typical screen height
}

return Config
