-- data/status_effects.lua
-- Defines all status effects (enemy debuffs and player buffs)

local StatusEffects = {
  -- ENEMY STATUSES
  bleed = {
    type = "dot",
    target = "enemy",
    max_stacks = 10,
    damage_per_tick = function(source_damage) 
      return source_damage * 0.20
    end,
    tick_interval = 0.5,
    color = {0.8, 0.1, 0.1},
    icon = "bleed",
    particle_effect = "blood_drip",
    display_name = "Bleeding"
  },
  
  marked = {
    type = "debuff",
    target = "enemy",
    max_stacks = 1,
    damage_multiplier = 1.20,
    color = {1.0, 0.9, 0.2},
    icon = "marked",
    particle_effect = "target_glow",
    display_name = "Marked"
  },
  
  rooted = {
    type = "debuff",
    target = "enemy",
    max_stacks = 1,
    color = {0.4, 0.8, 0.2},
    icon = "rooted",
    display_name = "Rooted"
  },
  
  -- PLAYER BUFFS
  focused_shots = {
    type = "buff",
    target = "player",
    max_stacks = 1,
    charges = 2,
    stat_mods = {
      primary_damage = { mul = 1.30 }
    },
    color = {0.3, 0.6, 1.0},
    icon = "focused",
    particle_effect = "focus_aura",
    display_name = "Focused Shots",
    rules = {
      no_stack_in_frenzy = true,
      consume_on_primary_hit = true
    }
  },
  
  momentum = {
    type = "buff",
    target = "player",
    max_stacks = 1,
    stat_mods = {
      move_speed = { mul = 1.10 }
    },
    color = {0.2, 1.0, 0.4},
    icon = "momentum",
    particle_effect = "speed_trail",
    display_name = "Momentum"
  },
  
  battle_rhythm = {
    type = "buff",
    target = "player",
    max_stacks = 1,
    stat_mods = {
      attack_speed = { mul = 1.15 }
    },
    color = {1.0, 0.5, 0.2},
    icon = "rhythm",
    particle_effect = "rhythm_pulse",
    display_name = "Battle Rhythm",
    rules = {
      break_on_roll = true,
      break_on_hit_taken = true
    }
  },
  
  ghost_quiver = {
    type = "buff",
    target = "player",
    max_stacks = 1,
    weapon_mods = {
      primary_ghosting = 1
    },
    color = {0.7, 0.3, 0.9},
    icon = "ghost",
    particle_effect = "ghost_aura",
    display_name = "Ghost Quiver",
    rules = {
      primary_only = true,
      excludes_abilities = {"multi_shot"}
    }
  },
  
  perfect_predator = {
    type = "buff",
    target = "player",
    max_stacks = 1,
    stat_mods = {
      attack_speed = { mul = 1.30 },
      crit_chance = { add = 0.20 }
    },
    color = {1.0, 0.8, 0.0},
    icon = "predator",
    particle_effect = "golden_glow",
    display_name = "Perfect Predator",
    rules = {
      break_on_hit_taken = true,
      disabled_during_frenzy = true
    }
  }
}

return StatusEffects
