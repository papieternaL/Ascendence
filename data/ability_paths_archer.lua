-- data/ability_paths_archer.lua
-- Ability-centric upgrades for Archer. These are not in the main pool by default.
-- You can inject them once the player reaches certain levels or after midboss.

local P = {}

P.meta = { version = 1, class = "archer" }

P.multi_shot = {
  {
    id="ms_c_wide_spread", name="Wide Spread", rarity="common",
    description="Multi Shot cone spread increased by 5°",
    effects={ { kind="ability_mod", ability="multi_shot", mod="cone_spread_add", value=5 } }
  },
  {
    id="ms_c_heavy_tips", name="Heavy Tips", rarity="common",
    description="Multi Shot deals 15% more damage",
    effects={ { kind="ability_mod", ability="multi_shot", mod="damage_mul", value=1.15 } }
  },
}

P.entangle = {
  {
    id="en_c_wide_volley", name="Wide Volley", rarity="common",
    description="Arrow Volley fires 3 additional arrows",
    effects={ { kind="ability_mod", ability="entangle", mod="arrow_count_add", value=3 } }
  },
  {
    id="en_c_quick_cast", name="Quick Cast", rarity="common",
    description="Arrow Volley cooldown reduced by 10%",
    effects={ { kind="ability_mod", ability="entangle", mod="cooldown_mul", value=0.90 } }
  },
  {
    id="en_r_thorned_volley", name="Thorned Volley", rarity="rare",
    description="Arrow Volley deals 35% more damage",
    effects={
      { kind="ability_mod", ability="entangle", mod="damage_mul", value=1.35 }
    }
  },
  {
    id="en_r_piercing_vines", name="Piercing Vines", rarity="rare",
    description="Arrow Volley vines pierce through 3 additional enemies",
    effects={
      { kind="ability_mod", ability="entangle", mod="pierce_add", value=3 }
    }
  },
  {
    id="en_e_thorn_storm", name="Thorn Storm", rarity="epic",
    description="Arrow Volley: +5 arrows, 15% more damage, 15% faster cooldown",
    effects={
      { kind="ability_mod", ability="entangle", mod="arrow_count_add", value=5 },
      { kind="ability_mod", ability="entangle", mod="damage_mul", value=1.15 },
      { kind="ability_mod", ability="entangle", mod="cooldown_mul", value=0.85 }
    }
  },
  {
    id="en_r_rain_of_arrows", name="Rain of Arrows", rarity="rare",
    description="Arrow Volley creates an additional AOE circle to attack enemies",
    effects={
      { kind="ability_mod", ability="entangle", mod="extra_zone_add", value=1 }
    }
  },
}
P.arrow_volley = P.entangle

P.frenzy = {
  {
    id="fr_c_hot_start", name="Hot Start", rarity="common",
    description="Frenzy charges 10% faster from dealing damage",
    effects={ { kind="ability_mod", ability="frenzy", mod="charge_gain_mul", value=1.10 } }
  },
  {
    id="fr_c_long_breath", name="Long Breath", rarity="common",
    description="Frenzy lasts 1 second longer",
    effects={ { kind="ability_mod", ability="frenzy", mod="duration_add", value=1.0 } }
  },
  {
    id="fr_r_predatory_focus", name="Predatory Focus", rarity="rare",
    description="During Frenzy, gain 8% additional crit chance",
    effects={
      { kind="ability_mod", ability="frenzy", mod="crit_chance_add", value=0.08 }
    }
  },
  {
    id="fr_r_adrenal_step", name="Adrenal Step", rarity="rare",
    description="During Frenzy: 10% move speed and 15% faster dash recovery",
    effects={
      { kind="ability_mod", ability="frenzy", mod="move_speed_mul", value=1.10 },
      { kind="ability_mod", ability="frenzy", mod="roll_cooldown_mul", value=0.85 }
    }
  },
  {
    id="fr_e_kill_fuel", name="Kill Fuel", rarity="epic",
    description="Kills during Frenzy extend its duration by 0.15s, up to 2s total",
    effects={
      { kind="ability_mod", ability="frenzy", mod="extend_on_kill", value=0.15, max_extend=2.0 }
    }
  },
}

return P




