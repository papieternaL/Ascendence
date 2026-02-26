-- data/config.lua
-- Unified game configuration (single difficulty)

local Config = {}

Config.game_balance = {
  player = {
    base_health = 100,
    base_damage = 10,
    base_move_speed = 224,
    base_attack_speed = 1.0,
    base_crit_chance = 0.05,
    base_crit_damage = 1.5,
    base_pierce = 0,
    base_range = 400,
    dash_speed = 896,
    dash_duration = 0.2,
    dash_cooldown = 1.0,
    base_cooldown_mul = 0.85,  -- 15% reduction to all ability cooldowns
  },
  
  enemies = {
    slime = { health = 30, damage = 8, move_speed = 112, xp_value = 10 },
    bat = { health = 20, damage = 6, move_speed = 168, xp_value = 12 },
    wolf = { health = 40, damage = 12, move_speed = 123, xp_value = 40 },
    skeleton = { health = 35, damage = 10, move_speed = 123, xp_value = 15 },
    imp = { health = 25, damage = 12, move_speed = 146, xp_value = 18 },
    lunger = { health = 40, damage = 15, move_speed = 202, xp_value = 50 },
    small_treent = { health = 45, damage = 10, move_speed = 84, xp_value = 50 },
    wizard = { health = 35, damage = 12, move_speed = 95, xp_value = 50 },
    druid_treent = { health = 55, damage = 8, move_speed = 73, xp_value = 60 },
    treent = { health = 150, damage = 20, move_speed = 73, xp_value = 100 }
  },
  
  boss = {
    treent_overlord = {
      health = 3500,
      damage = 40,
      move_speed = 65
    }
  }
}

-- XP pacing: 0.6375 = ~36% less XP from kills (another 15% down from 0.75) for longer runs
Config.xp_drop_multiplier = 0.6375

Config.boss_progression = {
  level_required = 10,
  portal_spawn_delay = 2.0,
  show_notification = true,
  notification_text = "The Boss Awaits..."
}

Config.enemy_spawner = {
  base_spawn_interval = 1.8,
  max_enemies = 80,
  min_enemies = 18,
  min_enemies_start = 10,      -- target count early in run; more manageable start
  min_enemies_max = 24,
  min_enemies_ramp_seconds = 120,
  late_wave_reduction = 0.25,   -- by end of ramp, spawn pressure is reduced by 25%
  late_wave_start_seconds = 120, -- when late-wave reduction starts
  late_wave_ramp_seconds = 90,   -- how quickly late-wave reduction reaches full value
  difficulty_scale_rate = 0.008,
  spawn_margin = 250,   -- pixels off-screen; enemies spawn here and move toward player
  density_multiplier = 0.8,    -- 20% fewer enemies (non-boss waves only)
  global_spawn_rate_mult = 0.85,  -- Additional 15% slower spawn cadence (stacks with density + late_wave)
}

-- Base stat gains applied every level-up (HP and attack)
Config.level_up_base_gains = {
  level_up_hp_gain = 10,
  level_up_attack_gain = 1,
}

-- Time-based scaling: enemies get stronger as run time increases
Config.enemy_time_scale = {
  rate = 0.012,   -- per second (e.g. 60s -> 1 + 0.72 = 1.72x)
  cap = 2.5       -- max multiplier so late game isn't one-shot
}

-- Hybrid HP scaling: level + floor + time (enemies scale with player growth)
Config.enemy_hp_scaling = {
  level_factor = 0.04,   -- 4% HP per player level (e.g. level 10 -> 1.36x)
  floor_factor = 0.08,   -- 8% HP per floor (e.g. floor 5 -> 1.4x)
  time_cap = 2.5,        -- max time-based multiplier
  enabled = true,
}

-- Ability Specifics (kept for compatibility)
Config.Abilities = {
  multiShot = {
    cooldown = 2.5,
    arrowCount = 3,
    coneSpreadDeg = 15,
    speed = 500,
    knockback = 100,
  },
  arrowVolley = {
    cooldown = 8.0,
    range = 300,
    baseDamage = 25,
    radius = 60,
    damageMult = 1.5,
  },
  frenzy = {
    duration = 8.0,
    moveSpeedMult = 1.25,
    attackSpeedMult = 1.5,
    critChanceAdd = 0.25,
    damageTakenMult = 1.15,
    lifeSteal = 0.10,
  }
}

-- Boss: Treent Overlord (kept for compatibility)
Config.TreentOverlord = {
  maxHealth = 3500,
  speed = 65,
  damage = 40,
  size = 48,
  
  -- Phase 1
  lungeCooldown = 1.1,
  lungeChargeDuration = 0.6,
  lungeDuration = 0.28,
  lungeSpeed = 900,

  barkBarrageCooldown = 1.8,
  barkBarrageCount = 6,
  barkBarrageDelay = 0.06,

  -- Phase 2: faster pace (multipliers applied when phase == 2)
  phase2LungeCooldownMul = 0.75,      -- 25% faster lunges
  phase2BarkBarrageCooldownMul = 0.80, -- 20% faster bark barrage

  -- Phase 2 (vine attack)
  encompassRootDuration = 6.0,   -- Was 8.0
  earthquakeCooldown = 7.0,      -- Was 10.0
  earthquakeDuration = 2.5,      -- Was 3.0
  earthquakeCastTime = 3.0,      -- Was 5.0
  earthquakeDamage = 9999,
  
  -- Vine Lanes
  vineLaneCount = 6,             -- +1 lane for more volley pressure
  vineLaneSpeed = 320,           -- Was 280
  vineLaneDamage = 9999,
  vineLaneDuration = 4.0,        -- Was 5.0
  vineLaneCooldown = 8.0,        -- Was 12.0
  vineLaneSpacing = 100,

  -- Falling trunks: Phase 1 (lighter) vs Phase 2 (heavier)
  trunkPhase1Interval = 2.2,
  trunkPhase1Damage = 40,
  trunkPhase2Interval = 1.5,
  trunkPhase2Damage = 60,

  -- Bark Volley AOE (circular zone near player, telegraph then damage)
  barkVolleyCooldown = 3.5,
  barkVolleyRadius = 55,
  barkVolleyDamage = 25,
  barkVolleyTelegraphDuration = 0.9,
  barkVolleyImpactDuration = 0.25,
  barkVolleyPlacementRadius = 120,  -- max distance from player for center
  barkVolleyPhase2CooldownMul = 0.75,  -- 25% faster in phase 2
}

-- UI Constants
Config.UI = {
  hudWidth = 400,
  hudHeight = 90,
  abilityIconSize = 44,
  abilitySpacing = 12,
  healthBarWidth = 320,
  healthBarHeight = 16,
}

-- Visuals
Config.Vfx = {
  hitFlashDuration = 0.1,
  knockbackFriction = 0.85,
}

-- Retro Art Style
Config.Retro = {
  enabled = false,
  internalWidth = 1280,
  internalHeight = 720,
  outlineThickness = 2,
  scanlineIntensity = 0.08,
  paletteEnabled = false,
  pixelScale = 1,
}

-- World Size
Config.World = {
  width = 2400,
  height = 1600,
  camera = {
    bottomThresholdStart = 0.65,
    bottomThresholdEnd = 0.88,
    maxDownwardOffset = 0.25,
  },
}

-- Legacy compatibility (map old structure to new)
Config.Player = {
  baseHealth = Config.game_balance.player.base_health,
  baseAttack = Config.game_balance.player.base_damage,
  baseSpeed = Config.game_balance.player.base_move_speed,
  fireRate = 0.4,
  attackRange = Config.game_balance.player.base_range,
  dashSpeed = Config.game_balance.player.dash_speed,
  dashDuration = Config.game_balance.player.dash_duration,
  dashCooldown = Config.game_balance.player.dash_cooldown,
}

return Config
