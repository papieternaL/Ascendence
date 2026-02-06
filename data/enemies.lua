-- Enemy Data Definitions
-- Centralized stats for all enemy types
-- Makes balancing easier and reduces code duplication

return {
    -- Basic Enemy
    enemy = {
        size = 12,
        speed = 90,
        health = 25,
        damage = 10,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 12,
        rarityCharges = 1,
    },
    
    -- Lunger (MCM - teaches dodge timing)
    lunger = {
        size = 16,
        speed = 70,
        health = 50,
        damage = 15,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = true,
        xpValue = 60, -- 5x multiplier
        rarityCharges = 2,
        lungeSpeed = 500,
    },
    
    -- Wolf (lunging charger)
    wolf = {
        size = 16,
        speed = 80,
        health = 40,
        damage = 12,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 12,
        rarityCharges = 1,
        lungeSpeed = 450,
        lungeRange = 320,
        chargeDuration = 0.7,
        lungeDuration = 0.4,
        cooldownDuration = 1.2,
    },
    
    -- Treent (elite tank)
    treent = {
        size = 26,
        speed = 30,
        health = 80,
        damage = 18,
        knockbackDecay = 7,
        flashDuration = 0.12,
        isElite = true,
        isMCM = false,
        xpValue = 24,
        rarityCharges = 1,
    },
    
    -- Small Treent (MCM - teaches projectile dodging)
    small_treent = {
        size = 14,
        speed = 70,
        health = 30,
        damage = 9,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = true,
        xpValue = 150, -- 5x multiplier
        rarityCharges = 2,
        barkCooldown = 2.4,
        barkRange = 260,
        barkMinRange = 80,
    },
    
    -- Wizard (MCM - teaches root escape)
    wizard = {
        size = 16,
        speed = 45,
        health = 45,
        damage = 10,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = true,
        xpValue = 225, -- 5x multiplier
        rarityCharges = 2,
        rootConeAngle = math.pi / 3,
        rootConeRange = 180,
        rootCooldown = 4.0,
    },
    
    -- Imp (fast swarmer)
    imp = {
        size = 12,
        speed = 90,
        health = 25,
        damage = 8,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 10,
        rarityCharges = 1,
    },
    
    -- Slime (tanky)
    slime = {
        size = 18,
        speed = 30,
        health = 80,
        damage = 12,
        knockbackDecay = 12,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 20,
        rarityCharges = 1,
    },
    
    -- Bat (erratic flyer)
    bat = {
        size = 14,
        speed = 70,
        health = 30,
        damage = 8,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 12,
        rarityCharges = 1,
        wobbleSpeed = 4,
        wobbleRadius = 30,
    },
    
    -- Skeleton (medium threat)
    skeleton = {
        size = 15,
        speed = 55,
        health = 40,
        damage = 10,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 15,
        rarityCharges = 1,
    },
    
    -- Healer (support)
    healer = {
        size = 14,
        speed = 60,
        health = 35,
        damage = 0, -- Doesn't attack
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = false,
        xpValue = 18,
        rarityCharges = 1,
        healAmount = 2,
        healRange = 200,
        healCooldown = 1.5,
    },
    
    -- Druid Treent (MCM - healer support)
    druid_treent = {
        size = 20,
        speed = 50,
        health = 55,
        damage = 8,
        knockbackDecay = 8,
        flashDuration = 0.1,
        isElite = false,
        isMCM = true,
        xpValue = 275, -- 5x multiplier
        rarityCharges = 2,
        healAmount = 3,
        healRange = 250,
        healCooldown = 1.2,
    },
}
