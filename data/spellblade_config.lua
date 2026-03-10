local SpellbladeConfig = {
    hero = {
        baseHP = 92,
        baseATK = 18,
        baseSpeed = 258,
        attackRange = 320,
        attackSpeed = 1.0,
    },

    primary = {
        damage = 20,
        width = 34,
        length = 92,
        speed = 760,
        maxDistance = 330,
        lifetime = 0.5,
        cooldown = 0.28,
        knockback = 120,
        color = {0.32, 0.92, 1.0},
        edgeColor = {0.88, 0.96, 1.0},
    },

    mirrorBlink = {
        blinkDistance = 132,
        cooldown = 2.8,
        mirrorDuration = 0.65,
        mirrorDamageMultiplier = 0.5,
        contactRadius = 32,
        contactDamage = 18,
        pathWidth = 34,
        color = {0.72, 0.58, 1.0},
    },

    arcaneSwords = {
        swordCount = 3,
        orbitRadius = 52,
        orbitSpeed = 2.8,
        damage = 12,
        duration = 5.5,
        cooldown = 8.0,
        hitInterval = 0.24,
        swordSize = 18,
        color = {0.55, 0.9, 1.0},
    },

    prismRift = {
        castRange = 240,
        spawnOffset = 140,
        radius = 88,
        pullStrength = 245,
        duration = 1.55,
        collapseDamage = 34,
        cooldown = 10.0,
        color = {0.48, 0.66, 1.0},
        collapseColor = {0.92, 0.72, 1.0},
    },

    astral = {
        debugInstantActivation = true,
        duration = 9.0,
        cooldown = 20.0,
        auraColor = {0.92, 0.64, 1.0},

        primaryCooldownMul = 0.42,
        primaryDamageMul = 0.82,
        primaryLengthMul = 0.78,
        primaryWidthMul = 0.92,
        primaryMaxDistanceMul = 0.82,
        primarySpeedMul = 1.15,

        blinkCooldownMul = 0.45,
        blinkDistanceMul = 1.08,
        blinkContactDamageMul = 1.65,
        blinkMirrorDamageMul = 0.8,

        swordsCountAdd = 2,
        swordsOrbitRadiusAdd = 8,
        swordsOrbitSpeedMul = 1.55,
        swordsDamageMul = 1.55,
        swordsDurationMul = 1.15,

        riftRadiusMul = 1.35,
        riftPullStrengthMul = 1.6,
        riftDurationMul = 1.1,
        riftCollapseDamageMul = 1.8,
    },
}

return SpellbladeConfig
