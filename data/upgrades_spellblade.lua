local upgrades = {
    list = {
        {
            id = "spell_c_crystal_edge",
            name = "Crystal Edge",
            rarity = "common",
            description = "Energy Wave deals +4 damage.",
            tags = {"spellblade", "primary"},
            effects = {
                { kind = "ability_mod", ability = "energy_wave", mod = "damage_add", value = 4 },
            },
        },
        {
            id = "spell_c_mirror_step",
            name = "Mirror Step",
            rarity = "common",
            description = "Mirror Blink cooldown -0.35s.",
            tags = {"spellblade", "blink"},
            effects = {
                { kind = "ability_mod", ability = "mirror_blink", mod = "cooldown_add", value = -0.35 },
            },
        },
        {
            id = "spell_c_rift_span",
            name = "Rift Span",
            rarity = "common",
            description = "Prism Rift radius +16.",
            tags = {"spellblade", "rift"},
            effects = {
                { kind = "ability_mod", ability = "prism_rift", mod = "radius_add", value = 16 },
            },
        },
        {
            id = "spell_c_blade_density",
            name = "Blade Density",
            rarity = "common",
            description = "Arcane Swords deal +3 damage.",
            tags = {"spellblade", "swords"},
            effects = {
                { kind = "ability_mod", ability = "arcane_swords", mod = "damage_add", value = 3 },
            },
        },
        {
            id = "spell_c_quickened_guard",
            name = "Quickened Guard",
            rarity = "common",
            description = "Move speed +18.",
            tags = {"spellblade", "utility"},
            effects = {
                { kind = "stat_add", stat = "move_speed", value = 18 },
            },
        },
        {
            id = "spell_c_fractured_guard",
            name = "Fractured Guard",
            rarity = "common",
            description = "Mirror Blink contact damage +8 during Astral windows and beyond.",
            tags = {"spellblade", "blink"},
            effects = {
                { kind = "ability_mod", ability = "mirror_blink", mod = "contact_damage_add", value = 8 },
            },
        },
        {
            id = "spell_r_prism_pressure",
            name = "Prism Pressure",
            rarity = "rare",
            description = "Prism Rift pull strength +80 and collapse damage +10.",
            tags = {"spellblade", "rift"},
            effects = {
                { kind = "ability_mod", ability = "prism_rift", mod = "pull_strength_add", value = 80 },
                { kind = "ability_mod", ability = "prism_rift", mod = "collapse_damage_add", value = 10 },
            },
        },
        {
            id = "spell_r_dual_orbit",
            name = "Dual Orbit",
            rarity = "rare",
            description = "Arcane Swords gain +1 sword and orbit faster.",
            tags = {"spellblade", "swords"},
            effects = {
                { kind = "ability_mod", ability = "arcane_swords", mod = "sword_count_add", value = 1 },
                { kind = "ability_mod", ability = "arcane_swords", mod = "orbit_speed_mul", value = 1.15 },
            },
        },
        {
            id = "spell_r_long_cast",
            name = "Long Cast",
            rarity = "rare",
            description = "Energy Wave length +24 and max distance +36.",
            tags = {"spellblade", "primary"},
            effects = {
                { kind = "ability_mod", ability = "energy_wave", mod = "length_add", value = 24 },
                { kind = "ability_mod", ability = "energy_wave", mod = "max_distance_add", value = 36 },
            },
        },
        {
            id = "spell_r_resonant_form",
            name = "Resonant Form",
            rarity = "rare",
            description = "Astral Ascension lasts 1.4s longer.",
            tags = {"spellblade", "ultimate"},
            effects = {
                { kind = "ability_mod", ability = "astral_ascension", mod = "duration_add", value = 1.4 },
            },
        },
        {
            id = "spell_e_shardstorm",
            name = "Shardstorm",
            rarity = "epic",
            description = "Energy Wave cooldown -0.05s and Arcane Swords damage x1.25.",
            tags = {"spellblade", "epic"},
            effects = {
                { kind = "ability_mod", ability = "energy_wave", mod = "cooldown_add", value = -0.05 },
                { kind = "ability_mod", ability = "arcane_swords", mod = "damage_mul", value = 1.25 },
            },
        },
        {
            id = "spell_e_mirror_legion",
            name = "Mirror Legion",
            rarity = "epic",
            description = "Mirror Blink mirrors hit harder and Prism Rift cooldown -1.2s.",
            tags = {"spellblade", "epic"},
            effects = {
                { kind = "ability_mod", ability = "mirror_blink", mod = "mirror_damage_mul", value = 1.25 },
                { kind = "ability_mod", ability = "prism_rift", mod = "cooldown_add", value = -1.2 },
            },
        },
    },
}

return upgrades
