-- data/upgrades_archer.lua
-- Archer upgrade pool (V1). Data-driven. No direct boss-CC allowed.

local U = {}

U.meta = {
  version = 1,
  class = "archer",
  rarities = { "common", "rare", "epic" }
}

-- Helper notes for your systems:
-- effects use small, consistent primitives so Cursor can wire them cleanly:
--  - stat_add: add to player stats
--  - stat_mul: multiply player stats
--  - weapon_mod: changes primary projectile behavior
--  - proc: conditional triggers
--  - ability_mod: modifies a named ability (power_shot / arrow_volley / frenzy)
--  - aura/aoe: for radial bursts, on-death explosions, etc.
--
-- IMPORTANT RULES ENFORCED BY DATA:
--  - frenzy risk cannot be removed by upgrades (no effect for that exists)

U.list = {
  -- =========================
  -- COMMON (12)
  -- =========================
  {
    id="arch_c_sharpened_tips", name="Sharpened Tips", rarity="common",
    description="Your arrows deal 10% more damage",
    tags={ "damage", "primary" },
    effects={ { kind="stat_mul", stat="primary_damage", value=1.10 } }
  },
  {
    id="arch_c_quick_nock", name="Quick Nock", rarity="common",
    description="Draw and fire arrows 10% faster",
    tags={ "attack_speed", "primary" },
    effects={ { kind="stat_mul", stat="attack_speed", value=1.10 } }
  },
  {
    id="arch_c_fleetfoot", name="Fleetfoot", rarity="common",
    description="Move 8% faster",
    tags={ "move", "survival" },
    effects={ { kind="stat_mul", stat="move_speed", value=1.08 } }
  },
  {
    id="arch_c_long_draw", name="Long Draw", rarity="common",
    description="Arrows travel 12% farther before fading",
    tags={ "range", "primary" },
    effects={ { kind="stat_mul", stat="range", value=1.12 } }
  },
  {
    id="arch_c_piercing_practice", name="Piercing Practice", rarity="common",
    description="Arrows pierce through 2 additional enemies",
    tags={ "projectile", "primary" },
    effects={ { kind="weapon_mod", mod="pierce_add", value=2 } }
  },
  {
    id="arch_c_barbed_shafts", name="Barbed Shafts", rarity="common",
    description="Arrows cause bleeding, dealing 20% of hit damage every 0.5s for 3 seconds",
    tags={ "bleed", "dot" },
    effects={
      { kind="proc", trigger="on_primary_hit", chance=1.0, apply={ kind="status_apply", status="bleed", stacks=1, duration=3.0 } }
    }
  },
  {
    id="arch_c_hollow_points", name="Hollow Points", rarity="common",
    description="Critical hits deal 15% more damage",
    tags={ "crit", "damage" },
    effects={ { kind="stat_mul", stat="crit_damage", value=1.15 } }
  },
  {
    id="arch_c_hunters_instinct", name="Hunter's Instinct", rarity="common",
    description="5% increased chance to land critical hits",
    tags={ "crit" },
    effects={ { kind="stat_add", stat="crit_chance", value=0.05 } }
  },
  {
    id="arch_c_stamina_training", name="Stamina Training", rarity="common",
    description="Dash recovers 10% faster",
    tags={ "cooldown", "mobility" },
    effects={ { kind="stat_mul", stat="roll_cooldown", value=0.90 } }
  },
  {
    id="arch_c_keen_focus", name="Keen Focus", rarity="common",
    description="Deal 10% more damage to enemies within close range",
    tags={ "damage", "close_range" },
    effects={
      { kind="proc", trigger="while_enemy_within", range=140, apply={ kind="stat_mul", stat="primary_damage", value=1.10 } }
    }
  },
  {
    id="arch_c_light_quiver", name="Light Quiver", rarity="common",
    description="Every 3rd shot fires an extra arrow",
    tags={ "multishot", "primary" },
    effects={
      { kind="proc", trigger="every_n_primary_shots", n=3, apply={ kind="weapon_mod", mod="bonus_projectiles", value=1, spread_deg=6 } }
    }
  },
  {
    id="arch_c_xp_magnet", name="XP Magnet", rarity="common",
    description="Collect experience orbs from 15% farther away",
    tags={ "xp", "utility" },
    effects={ { kind="stat_mul", stat="xp_pickup_radius", value=1.15 } }
  },
  -- Primary element attunements (switchable; picking one resets others) - COMMON (integral to kit)
  {
    id="arch_c_fire_attunement", name="Fire Attunement", rarity="common",
    description="Primary shots set enemies on fire, dealing damage over time",
    tags={ "element", "fire", "dot" },
    effects={
      { kind="proc", trigger="on_primary_hit", chance=1.0, apply={ kind="status_apply", status="burn", stacks=1, duration=3.0 } }
    }
  },
  {
    id="arch_c_ice_attunement", name="Ice Attunement", rarity="common",
    description="Primary shots freeze enemies (bosses: slow only, no freeze)",
    tags={ "element", "ice", "cc" },
    effects={
      { kind="proc", trigger="on_primary_hit", chance=1.0, apply={ kind="status_apply", status="freeze", stacks=1, duration=1.5 } }
    }
  },
  {
    id="arch_c_lightning_attunement", name="Lightning Attunement", rarity="common",
    description="Primary shots chain lightning (2 targets base; +1 per additional pick)",
    tags={ "element", "lightning", "chain" },
    effects={
      { kind="proc", trigger="on_primary_hit", chance=1.0, apply={ kind="chain_damage", element="lightning", jumps=1, range=180, damage_mul=0.35 } },
      { kind="element_mod", element="lightning", mod="chain_jumps_add", value=1 }
    }
  },

  -- =========================
  -- RARE (9)
  -- =========================
  {
    id="arch_r_ricochet_arrows", name="Ricochet Arrows", rarity="rare",
    description="Arrows bounce to 1 additional target after hitting. +1 bounce per pick (stacks)",
    tags={ "projectile", "chaos" },
    effects={ { kind="weapon_mod", mod="ricochet", bounces=1, range=220 } }
  },
  {
    id="arch_r_split_shot", name="Split Shot", rarity="rare",
    description="Every 4th shot fires 2 extra arrows in a spread",
    tags={ "multishot", "chaos" },
    effects={
      { kind="proc", trigger="every_n_primary_shots", n=4, apply={ kind="weapon_mod", mod="bonus_projectiles", value=2, spread_deg=16 } }
    }
  },
  {
    id="arch_r_marked_prey", name="Marked Prey", rarity="rare",
    description="Critical hits mark enemies. Marked enemies take 20% more damage for 4 seconds",
    tags={ "crit", "targeting" },
    effects={
      { kind="proc", trigger="on_crit_hit", chance=1.0, apply={ kind="status_apply", status="marked", stacks=1, duration=4.0 } },
      { kind="proc", trigger="while_target_has_status", status="marked", apply={ kind="stat_mul", stat="primary_damage", value=1.20 } }
    }
  },
  {
    id="arch_r_bleeding_frenzy", name="Bleeding Frenzy", rarity="rare",
    description="Deal 5% more damage for each bleeding enemy, up to 10%",
    tags={ "bleed", "scaling" },
    requires_upgrade = "arch_c_barbed_shafts",
    effects={
      { kind="proc", trigger="while_enemies_bleeding", apply={ kind="stat_add", stat="primary_damage_pct_per_bleed_stack", value=0.05, cap=0.10 } }
    }
  },

  -- Reworked roll synergy (does NOT stack during Frenzy)
  {
    id="arch_r_phase_roll_focused", name="Phase Roll: Focused", rarity="rare",
    description="After dashing, your next 2 shots deal 30% more damage",
    tags={ "mobility", "burst" },
    effects={
      { kind="proc", trigger="after_roll", apply={ kind="buff", name="focused_shots", duration=4.0, charges=2,
          stats={ { stat="primary_damage", mul=1.30 } },
          rules={ no_stack_in_frenzy=true }
      } }
    }
  },

  -- Reworked from crit->roll refund (no infinite roll loops)
  {
    id="arch_r_precision_momentum", name="Precision Momentum", rarity="rare",
    description="Critical kills grant 10% movement speed for 1.5 seconds",
    tags={ "crit", "mobility" },
    effects={
      { kind="proc", trigger="on_crit_kill", chance=1.0, apply={ kind="buff", name="momentum", duration=1.5,
          stats={ { stat="move_speed", mul=1.10 } }
      } }
    }
  },

  -- Reworked from "stand still turret"
  {
    id="arch_r_battle_rhythm", name="Battle Rhythm", rarity="rare",
    description="Firing continuously for 2 seconds grants 15% attack speed. Breaks if you dash or take damage",
    tags={ "attack_speed", "tempo" },
    effects={
      { kind="proc", trigger="firing_continuously_for", seconds=2.0, apply={ kind="buff", name="battle_rhythm", duration=2.5,
          stats={ { stat="attack_speed", mul=1.15 } },
          rules={ break_on_roll=true, break_on_hit_taken=true }
      } }
    }
  },

  {
    id="arch_r_tactical_spacing", name="Tactical Spacing", rarity="rare",
    description="Deal 25% more damage to distant enemies",
    tags={ "damage", "positioning" },
    effects={
      { kind="proc", trigger="while_target_beyond_range_pct", pct=0.55, apply={ kind="stat_mul", stat="primary_damage", value=1.25 } }
    }
  },

  -- Element enhancement upgrades (require matching attunement; switching resets)
  {
    id="arch_r_fire_intensity", name="Fire Intensity", rarity="rare",
    description="Burn deals 25% more damage",
    tags={ "element", "fire", "dot" },
    requires_upgrade = "arch_c_fire_attunement",
    effects={ { kind="element_mod", element="fire", mod="burn_damage_mul", value=1.25 } }
  },
  {
    id="arch_r_ice_depth", name="Ice Depth", rarity="rare",
    description="Chill lasts 1s longer and slows 10% more",
    tags={ "element", "ice", "cc" },
    requires_upgrade = "arch_c_ice_attunement",
    effects={
      { kind="element_mod", element="ice", mod="chill_duration_add", value=1.0 },
      { kind="element_mod", element="ice", mod="slow_mul", value=1.10 }
    }
  },
  {
    id="arch_r_freeze_spread", name="Freeze Spread", rarity="rare",
    description="Ice dissolve blast spreads chill/freeze to nearby enemies",
    tags={ "element", "ice", "cc" },
    requires_upgrade = "arch_c_ice_attunement",
    effects={ { kind="element_mod", element="ice", mod="ice_freeze_spread", value=true } }
  },
  {
    id="arch_r_ice_blast_radius", name="Bigger Blast Radius", rarity="rare",
    description="Ice dissolve blast radius +25 per pick (stacks)",
    tags={ "element", "ice", "aoe" },
    requires_upgrade = "arch_c_ice_attunement",
    effects={ { kind="element_mod", element="ice", mod="ice_blast_radius_add", value=25 } }
  },
  {
    id="arch_r_lightning_reach", name="Lightning Reach", rarity="rare",
    description="Chain lightning jumps to 2 additional enemies",
    tags={ "element", "lightning", "chain" },
    requires_upgrade = "arch_c_lightning_attunement",
    effects={ { kind="element_mod", element="lightning", mod="chain_jumps_add", value=2 } }
  },

  -- HP regen (always-on, stacks)
  {
    id="arch_r_field_mending", name="Field Mending", rarity="rare",
    description="Regenerate 0.4 HP per second (stacks)",
    tags={ "survival", "regen" },
    effects={ { kind="stat_add", stat="hp_regen_per_sec", value=0.4 } }
  },

  -- =========================
  -- EPIC (3)
  -- =========================
  {
    id="arch_e_arrowstorm", name="Arrowstorm", rarity="rare",
    description="Every 6th shot releases a burst of 8 arrows in all directions, each dealing 40% damage",
    tags={ "aoe", "chaos" },
    effects={
      { kind="proc", trigger="every_n_primary_shots", n=6, apply={ kind="aoe_projectile_burst", count=8, radius=0, speed_mul=0.90, damage_mul=0.40 } }
    }
  },
  {
    id="arch_e_hemorrhage", name="Hemorrhage", rarity="epic",
    description="Killing bleeding enemies causes them to explode, dealing damage to nearby foes",
    tags={ "bleed", "explosion" },
    requires_upgrade = "arch_c_barbed_shafts",
    effects={
      { kind="proc", trigger="on_kill_target_with_status", status="bleed", chance=1.0,
        apply={ kind="aoe_explosion", radius=90, damage_mul_of_target_maxhp=0.06 }
      }
    }
  },
  {
    id="arch_e_ghost_quiver", name="Ghost Quiver", rarity="epic",
    description="After dashing, your arrows pierce through all enemies for 1.25 seconds",
    tags={ "mobility", "pierce" },
    effects={
      { kind="proc", trigger="after_roll", apply={ kind="buff", name="ghost_quiver", duration=1.25,
        rules={ primary_only=true, excludes_abilities={ "multi_shot" } },
        stats={ { stat="primary_ghosting", add=1 } } -- your projectile system reads this
      } }
    }
  },
  {
    id="arch_e_perfect_predator", name="Perfect Predator", rarity="epic",
    description="If you avoid damage for 5 seconds: gain 30% attack speed and 20% crit chance until hit",
    tags={ "tempo", "crit" },
    effects={
      { kind="proc", trigger="no_damage_taken_for", seconds=5.0, apply={ kind="buff", name="perfect_predator", duration=999,
        stats={
          { stat="attack_speed", mul=1.30 },
          { stat="crit_chance", add=0.20 }
        },
        rules={ break_on_hit_taken=true, disabled_during_frenzy=true }
      } }
    }
  },
}

return U
