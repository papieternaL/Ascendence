-- data/config.lua
-- Unified game configuration (single difficulty)

local Config = {}

Config.game_balance = {
  player = {
    base_health = 100,
    base_damage = 10,
    base_move_speed = 200,
    base_attack_speed = 1.0,
    base_crit_chance = 0.05,
    base_crit_damage = 1.5,
    base_pierce = 0,
    base_range = 400,
    dash_speed = 800,
    dash_duration = 0.2,
    dash_cooldown = 1.0,
  },
  
  enemies = {
    slime = { health = 30, damage = 8, move_speed = 80, xp_value = 10 },
    bat = { health = 20, damage = 6, move_speed = 120, xp_value = 12 },
    skeleton = { health = 35, damage = 10, move_speed = 90, xp_value = 15 },
    imp = { health = 25, damage = 12, move_speed = 100, xp_value = 18 },
    lunger = { health = 40, damage = 15, move_speed = 150, xp_value = 50 },
    small_treent = { health = 45, damage = 10, move_speed = 60, xp_value = 50 },
    wizard = { health = 35, damage = 12, move_speed = 70, xp_value = 50 },
    treent = { health = 150, damage = 20, move_speed = 50, xp_value = 100 }
  },
  
  boss = {
    treent_overlord = {
      health = 3500,
      damage = 40,
      move_speed = 65
    }
  }
}

Config.boss_progression = {
  level_required = 10,
  portal_spawn_delay = 2.0,
  show_notification = true,
  notification_text = "The Boss Awaits..."
}

Config.enemy_spawner = {
  base_spawn_interval = 2.5,
  max_enemies = 60,
  min_enemies = 12,
  difficulty_scale_rate = 0.008
}

-- Ability Specifics (kept for compatibility)
Config.Abilities = {
  powerShot = {
    damageMult = 3.0,
    cooldown = 6.0,
    speed = 760,
    knockback = 260,
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
  }
}

-- Boss: Treent Overlord (kept for compatibility)
Config.TreentOverlord = {
  maxHealth = 3500,
  speed = 65,
  damage = 40,
  size = 48,
  
  -- Phase 1 (sped up)
  lungeCooldown = 1.5,           -- Was 2.0
  lungeChargeDuration = 0.8,     -- Was 1.2
  lungeDuration = 0.4,           -- Was 0.5
  lungeSpeed = 900,              -- Was 800
  
  barkBarrageCooldown = 2.0,     -- Was 3.0
  barkBarrageCount = 10,         -- Was 8
  barkBarrageDelay = 0.06,       -- Was 0.08
  
  -- Phase 2 (sped up)
  encompassRootDuration = 6.0,   -- Was 8.0
  earthquakeCooldown = 7.0,      -- Was 10.0
  earthquakeDuration = 2.5,      -- Was 3.0
  earthquakeCastTime = 3.0,      -- Was 5.0
  earthquakeDamage = 9999,
  
  -- Vine Lanes
  vineLaneCount = 5,
  vineLaneSpeed = 320,           -- Was 280
  vineLaneDamage = 9999,
  vineLaneDuration = 4.0,        -- Was 5.0
  vineLaneCooldown = 8.0,        -- Was 12.0
  vineLaneSpacing = 100,
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
