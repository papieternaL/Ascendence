# UI icon art (SpriteCook)

These icons are loaded by `FrontendStyle` from `res://art/ui/icons/<icon_asset_id>.png` and rendered by `IconGlyph` in the HUD, upgrade overlay, and class preview. Missing textures fall back to the procedural glyphs.

## Notes

- Generated through SpriteCook in `mode: "ui"` with `pixel: true`, `bg_mode: "transparent"`, `smart_crop: true`, and a shared bow icon style reference for visual consistency.
- PNGs are transparent individual files intended for nearest-neighbor rendering in the existing HUD and upgrade-card layouts.
- Ability icons use explicit class/ability filenames. Upgrade icons use the exact `UpgradeCatalog` upgrade IDs as filenames.

## Ability icons

| File | Source |
|------|--------|
| `archer_hunters_bow.png` | SpriteCook (`8a89905c-50da-4bd7-99e6-cf59b9ecaa2d`) |
| `archer_power_shot.png` | SpriteCook (`fb5784aa-39db-4dd8-a8d9-03e17d40db3a`) |
| `archer_dash.png` | SpriteCook (`259050cf-3d38-4959-8459-4dfea420fd77`) |
| `archer_arrow_volley.png` | SpriteCook (`1fe505dd-435b-4626-a90f-c034be630139`) |
| `archer_sentinel.png` | SpriteCook (`0ba94baa-f780-457c-90f2-db452ecc84de`) |
| `arcane_pistol_primary.png` | SpriteCook (`483182bd-83e8-4763-9f73-f29e84b49930`) |
| `arcane_blink.png` | SpriteCook (`239fcbb1-c524-4c8f-935b-9633e37051ab`) |
| `arcane_missiles.png` | SpriteCook (`00bee383-6b6e-474e-a1c8-b2033bb4a48b`) |
| `arcane_sniper.png` | SpriteCook (`eea292fa-65bd-40c2-b3c5-e23b48cf3c9d`) |

## Upgrade icons

| File | Source |
|------|--------|
| `arch_c_sharpened_tips.png` | SpriteCook (`86003210-462c-4c28-b512-54259a4200dd`) |
| `arch_c_quick_nock.png` | SpriteCook (`3c7de43b-bd3b-4c12-acfe-223c9f4d8120`) |
| `arch_c_fleetfoot.png` | SpriteCook (`8e360d7f-527a-4b1e-a989-a4b2fa54c7f8`) |
| `arch_c_piercing_practice.png` | SpriteCook (`9941256c-d526-47fb-be2d-32fb6153f7db`) |
| `arch_c_hollow_points.png` | SpriteCook (`117d19d0-31e5-4a96-886c-45a6ca0c80c8`) |
| `arch_c_hunters_instinct.png` | SpriteCook (`4bee9368-cb78-466e-9a2b-879d6dd0ec25`) |
| `arch_c_stamina_training.png` | SpriteCook (`82fe48f6-0bab-4ee0-a0ac-02654d1f670a`) |
| `arch_c_xp_magnet.png` | SpriteCook (`6863370c-8134-4b1c-86fc-01946476cfe6`) |
| `arch_c_ricochet_arrow.png` | SpriteCook (`ec2b82d9-f4f9-484d-8f6f-0d83e00ab004`) |
| `arch_c_fire_attunement.png` | SpriteCook (`b5a13bfa-05b3-4948-bc27-f7702dfc4896`) |
| `arch_c_ice_attunement.png` | SpriteCook (`b35545e1-4b59-4c5e-ae59-036f5f4a631a`) |
| `arch_c_lightning_attunement.png` | SpriteCook (`355d6c57-65ef-4a4a-ad96-46198f06a953`) |
| `arch_r_split_shot.png` | SpriteCook (`781f2acd-72c4-407e-85e5-3eb348057b50`) |
| `arch_r_thorned_volley.png` | SpriteCook (`f6c7905c-00dd-43ce-bdfe-62f0db6f3e73`) |
| `arch_r_expanded_volley.png` | SpriteCook (`b661fd6d-8ee7-4506-b063-2a8fc9546a34`) |
| `arch_r_predatory_focus.png` | SpriteCook (`3d59934e-2470-4041-ba1d-7c028c669daf`) |
| `arch_r_long_breath.png` | SpriteCook (`685a75cc-2423-448a-95ce-277c26bcf7d8`) |
| `arch_r_two_dashes.png` | SpriteCook (`961fa11a-c92b-4e34-a737-ac6435957be7`) |
| `arch_r_fire_intensity.png` | SpriteCook (`d262aa7f-a83e-4cf4-b6e6-5ac95170e5dd`) |
| `arch_r_ice_depth.png` | SpriteCook (`aae1c009-5c91-47f3-8248-a341fdfbe233`) |
| `arch_r_freeze_spread.png` | SpriteCook (`75a77ba0-4c35-4589-8bad-03cd8eb57557`) |
| `arch_r_ice_blast.png` | SpriteCook (`e4d6caec-2a7c-4537-900b-973fd2313f31`) |
| `arch_r_lightning_reach.png` | SpriteCook (`549858a4-de4b-43d9-bdc1-77ac59a70ec5`) |
| `arch_e_arrow_storm.png` | SpriteCook (`2902d0fd-1a30-4b9b-954a-7fbe9120c533`) |
| `arch_e_explosive_arrow_volley.png` | SpriteCook (`ce3b96c9-e2c6-450d-8234-5058e792898b`) |
| `arch_e_storm_volley.png` | SpriteCook (`5dd26c49-38b0-48bd-b4f2-8e503b8cbba0`) |
| `arch_e_perfect_predator.png` | SpriteCook (`a9047846-1618-4924-9489-396c89f1e78e`) |
| `arch_e_deadeye_bloom.png` | SpriteCook (`170abaa0-47ae-476f-b7e5-a22b3068f5e6`) |
| `charged_rounds.png` | SpriteCook (`111ca8e6-5181-4399-8390-c70b73b31b59`) |
| `quickdraw.png` | SpriteCook (`65028ee5-4a5e-43a0-8f5d-3af0f7f472cd`) |
| `spellclock.png` | SpriteCook (`77fbba13-57b1-4c7f-9d1f-ed6ac17284d1`) |
| `phase_stride.png` | SpriteCook (`4ebb12b4-4565-4ab4-a372-a8144f6ba12a`) |
| `satellite_volley.png` | SpriteCook (`636c1db9-d487-4a9f-b43a-8d19b9d73c2e`) |
| `deadeye.png` | SpriteCook (`0d9f887f-c313-4aff-82b7-3ca886b0a65f`) |
