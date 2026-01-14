-- data/ability_paths_archer.lua
-- Ability-centric upgrades for Archer. These are not in the main pool by default.
-- You can inject them once the player reaches certain levels or after midboss.

local P = {}

P.meta = { version = 1, class = "archer" }

P.power_shot = {
  {
    id="ps_c_scope_line", name="Scope Line", rarity="common",
    effects={ { kind="ability_mod", ability="power_shot", mod="range_mul", value=1.20 } }
  },
  {
    id="ps_c_broadhead", name="Broadhead", rarity="common",
    effects={ { kind="ability_mod", ability="power_shot", mod="damage_mul", value=1.15 } }
  },
  {
    id="ps_r_double_tap", name="Double Tap", rarity="rare",
    effects={
      { kind="ability_mod", ability="power_shot", mod="fires_twice", value=1, delay=0.08, second_shot_damage_mul=0.55 }
    }
  },
  {
    id="ps_r_sundering", name="Sundering Arrow", rarity="rare",
    effects={
      { kind="ability_mod", ability="power_shot", mod="applies_status", status="shattered_armor", duration=3.0,
        status_effect={ kind="target_damage_taken_mul", value=1.12 } }
    }
  },
  {
    id="ps_e_execution_line", name="Execution Line", rarity="epic",
    effects={
      { kind="ability_mod", ability="power_shot", mod="bonus_damage_vs_elite_mcm", value=1.35 }
    }
  },
}

P.arrow_volley = {
  -- Arrow Volley upgrades: AOE damage ability that rains arrows on a target area
  {
    id="av_c_wide_spread", name="Wide Spread", rarity="common",
    effects={ { kind="ability_mod", ability="arrow_volley", mod="radius_add", value=20 } }
  },
  {
    id="av_c_rapid_reload", name="Rapid Reload", rarity="common",
    effects={ { kind="ability_mod", ability="arrow_volley", mod="cooldown_mul", value=0.85 } }
  },
  {
    id="av_r_heavy_volley", name="Heavy Volley", rarity="rare",
    effects={
      { kind="ability_mod", ability="arrow_volley", mod="damage_mul", value=1.25 }
    }
  },
  {
    id="av_r_arrow_storm", name="Arrow Storm", rarity="rare",
    effects={
      { kind="ability_mod", ability="arrow_volley", mod="arrow_count_add", value=6 }
    }
  },
  {
    id="av_e_double_strike", name="Double Strike", rarity="epic",
    effects={
      { kind="ability_mod", ability="arrow_volley", mod="double_strike", value=1, delay=0.3, second_volley_damage_mul=0.6 }
      -- Volley strikes the same location twice with a short delay (second volley deals 60% damage)
    }
  },
}

P.frenzy = {
  -- Frenzy is time-limited, ends early on hit. These upgrades support *earning* it and *using* it well.
  {
    id="fr_c_hot_start", name="Hot Start", rarity="common",
    effects={ { kind="ability_mod", ability="frenzy", mod="charge_gain_mul", value=1.10 } }
  },
  {
    id="fr_c_long_breath", name="Long Breath", rarity="common",
    effects={ { kind="ability_mod", ability="frenzy", mod="duration_add", value=1.0 } }
  },
  {
    id="fr_r_predatory_focus", name="Predatory Focus", rarity="rare",
    effects={
      { kind="ability_mod", ability="frenzy", mod="crit_chance_add", value=0.08 }
    }
  },
  {
    id="fr_r_adrenal_step", name="Adrenal Step", rarity="rare",
    effects={
      { kind="ability_mod", ability="frenzy", mod="move_speed_mul", value=1.10 },
      { kind="ability_mod", ability="frenzy", mod="roll_cooldown_mul", value=0.85 }
    }
  },
  {
    id="fr_e_kill_fuel", name="Kill Fuel", rarity="epic",
    effects={
      { kind="ability_mod", ability="frenzy", mod="extend_on_kill", value=0.15, max_extend=2.0 }
      -- Still ends on hit. This is just rewarding clean play.
    }
  },
}

return P












