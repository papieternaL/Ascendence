# Ascendence - AGENTS.md

## Changelog

- **Combat aim / cast defaults (2026-04)**: Restored **quick cast** + **nearest-enemy auto-aim** for primary, Arrow Volley / Arcane Bomb, and mobility (dash/blink) in `main.gd`, `arcane_pistol_runtime.gd`, hub practice, and tutorial. **Ability 1** (Power Shot / Arcane Missiles) stays **manual cursor aim**; default binding set to **Shift** in `input_bindings.gd` and `project.godot`. **Ultimate (R)** unchanged. Wired `_should_auto_fire_primary()` for soft-lock assist. Fixed `run_profile` default key in `project.godot` to **Tab** (4194306) so it does not share Shift with Ability 1.
- **Primary aim decoupled from cursor (2026-04)**: `_get_primary_auto_aim_direction()` aims primary shots at the nearest enemy only (no cursor fallback). Player facing via `_update_targeting()` uses nearest-enemy position or movement / last facing when empty; HUD label shows **Auto Aim** without mouse. `_should_auto_fire_primary()` uses nearest-in-range, not cursor proximity.
- **Quest scroll overlay (2026-03)**: `hub_controller.gd` sizes the quest overlay from `hub_quest_scroll.png` aspect (portrait scroll, not a fixed wide rect), uses **Control** `LAYOUT_MODE_CONTAINER` and expanding labels so text fills the panel, **ColorRect** underlay plus parchment fallback (avoids default white **Panel**), and **MarginContainer** insets scaled from texture dimensions so copy sits inside the parchment under the seal.
- **Hub ground blending (2026-03)**: `_draw_ground_contact()` soft ellipses under virtue, portal, weapon pillars, quest building, merchant, training; softer `_draw_central_plaza` alphas; `_draw_anchor_spaces` rim-only; `modulate` `(0.92, 0.94, 0.98)` on hub props for tonal match to cobble.
- **Esseloria hub zoom & decor (2026-03)**: `apply_hub_camera_zoom()` (deferred + on viewport resize) fits the camera to limits; `ViewportBackdrop` warm grey fills letterbox. **Perimeter** walls tile on the **padded floor rect** (same as cobble), not only `HUB_RECT`. **Cobble** tile replaced with warmer SpriteCook art + 128×128 nearest upscale; `cobble_tile_px` 0 = texture width; `TEXTURE_FILTER_NEAREST` on hub root; `_draw_floor_warmth()` subtle tint. Walls `hub_wall_h/v` thin strips; quest/merchant sprites; `_draw_dirt_paths()`.
- **Esseloria hub layout (2026-03)**: 2D hub matches hub-and-spoke reference — **Virtue** at `HUB_CENTER`, **Ascension Portal** south, **Quest** top-left, **two cobble weapon pillars** west (Archer bow / Arcane Pistol); **Training** uses `Polygon2D` dummies (no interact). **Cobble tile** floor via `hub_controller.gd` `cobble_floor_texture` tiled to `_floor_draw_rect()` (same bounds as camera limits: `HUB_RECT` + padding); no black/green outer rings. SpriteCook PNGs under `art/hub/`. Removed unused `esseloria_hub.gd`.
- **Hub sprites (2026-03)**: `art/hub/` — SpriteCook pixel art for virtue, portal, quest, cobble floor tile, and pillar props. **Per-pillar overlay** `open_weapon_class_overlay(class_id)` shows one class + abilities from `RunConfig`. `HubInteractable.uses_hub_art_sprite()` skips vector `_draw()` when `ArtSprite` has a texture.
- **Run flow / presentation (2025-03)**: XP from kills spawns as pickup orbs (`xp_orb_field.gd`) with optional **Arch C: XP Magnet** upgrade; objective **callout** under run timer (title / progress / phase timer); boss arena **~+25% scale** to match main map; **Enter (`ui_accept`)** confirms selected level-up card; top objective bar **!** markers + **skull** at boss end; upgrade cards drop rarity words from titles and use stronger selection VFX; **post vignette** shader on main scene; UI typography prefers **Gungeon block bitmap** via `frontend_style.gd` / `bitmap_font_library.gd` (import PNG as Font per `assets/fonts/gungeon_block_font_setup.md`). Primary arrow hits skip heavy hit-ring VFX to reduce hitches.
- **HUD / Spell Brigade pass (2025-03)**: Bottom HUD rework — full-width thin XP bar (glowing white-cyan fill), large **level ring** bottom-left (`spell_level_ring`), centered **HP bar** with numeric text overlaid on the bar (no separate label row), **ability row** as circular `ability_orb` glyphs only with small **numeric pills** (cooldown seconds / charge `%` / stack count); key labels and AUTO/READY strings removed from slots. Tooltips unchanged for hover detail. Styles in `frontend_style.gd`: `spell_level_ring`, `ability_orb`, `ability_pill`, `hud_xp_track`, `health_bar_spell`.
- **Upgrade cards (2025-03)**: Level-up cards use a roguelike-style layout: dark header bar (title) → icon well with **IconGlyph** placeholder only (no per-upgrade PNGs) → body text; **Kenney Pixel Square** via `apply_header` / `apply_body`; selected card uses cyan-border `upgrade_card_selected` style; inner header/well panels use `upgrade_header_bar` / `upgrade_icon_well`. Removed `UpgradeCardArt` / Gemini fallback path.
- **Shrine / Pause / Roots (2025-03)**: Pentagon shrine uses nearest-neighbor laser path over 25s (`laser_sequence_duration`) and 1:30 player limit (`player_time_limit`); `objective_failed` advances run with no reward; gameplay nodes set to `PROCESS_MODE_PAUSABLE` under `Main`/`ArcanePistolMain` so `get_tree().paused` freezes world during upgrade overlay; removed Wizard/Druid `root_cone_fired` → player root (boss encompass root unchanged).
- **UI Polish (2025-03)**: Arena trees rotated 90° for correct orientation; IconGlyph inner scale (0.78) and clip_contents=false to fix circular icon clipping; HP bar and LevelBadge moved lower to prevent overlap with ability bar; in-game ability hover tooltips (detail from RunConfig); dark blue-grey menus with BEGIN TRIAL/TUTORIAL/BOSS TEST/SETTINGS/QUIT, footer "PRESS ENTER OR CLICK TO CONTINUE", golden title, character select green selection border, nav hints.
- **Arena/Quit/Spawn (2025-03)**: UI CanvasLayer process_mode ALWAYS for pause menu input; reverted arena to forest green; spawn cadence tuned with `min_enemies_start 4` and `global_spawn_rate_mult 0.85`; removed spawn indicator VFX.
- **UI, Spawn, Theming (2025-03)**: Tutorial ESC menu; level-up pause verification; side-based spawn flow; arena decor spacing; character select layout and double-click; minimal map select; black base color scheme for pixel art.
- **Combat/Boss Pass (2025-03)**: BossConfig resource for Treent Overlord tuning; expanded core positions (8-12); dynamic spawn system with ramp, late-wave reduction, weighted selection; GameSettings autoload (brightness, reduced flashes, show FPS); Wolf, Wizard, Slime, Bat enemies; Falling Trunks and Bark Volley AOE boss phase 2 hazards.

## Project Identity
Ascendence is a 2D arena roguelite focused on build-crafting, ability synergies, and fast-paced, responsive combat.

The core experience is:
- fight enemies in an arena
- gain XP and level up
- choose upgrades that shape a build
- create powerful synergies
- survive escalating difficulty

---

## Core Principles

- Gameplay feel > visual complexity
- Responsiveness is critical (movement, shooting, feedback)
- Player choice and build variety drive replayability
- Ability synergy is more important than raw stat increases
- Systems should be simple, modular, and easy to extend

---

## Architecture Guidelines

- Use modular systems and avoid monolithic scripts
- Reusable gameplay objects should be self-contained (player, enemies, projectiles, abilities, UI)
- Separate concerns:
  - player logic
  - enemy logic
  - projectiles
  - abilities
  - systems (damage, cooldowns, spawning)
  - UI
- Prefer composition over large inheritance chains
- Keep systems loosely coupled

---

## Data & Tuning

- All gameplay values must be easy to tune
- Avoid hardcoding values inside logic
- Use config tables, resources, or exported variables for:
  - damage
  - cooldowns
  - speeds
  - scaling values
- Design systems to support rapid iteration and balancing

---

## Gameplay Priorities

1. Player movement and responsiveness
2. Combat feel and hit feedback
3. Enemy behavior and variety
4. Ability systems
5. Upgrade and progression systems
6. UI clarity and feedback
7. Additional content (enemies, bosses, abilities)

---

## Combat Design Rules

- Combat must be readable and fair
- Enemy attacks should be telegraphed
- Player should understand why they took damage
- Hits should feel impactful (visual + audio feedback)
- Avoid cluttering the screen with unnecessary effects

---

## Roguelite Systems

- Runs should be fast and replayable (target ~10-20 minutes)
- Players should be offered meaningful upgrade choices
- Upgrades should create synergies, not just stat increases

Bad upgrades:
- +5 damage
- +10% speed

Good upgrades:
- projectiles split
- attacks apply status effects
- abilities interact with each other

- Include limited RNG control (rerolls, weighted choices)

---

## Workflow Rules

- Implement one system at a time
- Do not build multiple large systems simultaneously
- Always complete a vertical slice before expanding
- Do not add new features until the current system works
- Prioritize playable states over unfinished breadth

---

## System Design Rules

- Avoid large "GameManager" style scripts
- Prefer smaller focused systems:
  - damage system
  - cooldown system
  - spawn system
- Systems should be testable in isolation
- Do not rewrite working systems without a clear reason

---

## DO NOT

- Do not over-engineer early systems
- Do not introduce unnecessary complexity
- Do not tightly couple unrelated systems
- Do not implement features outside the requested scope
- Do not sacrifice gameplay feel for architecture purity

---

## Expected AI Behavior

- Follow the requested scope strictly
- Do not add extra features unless asked
- When tasks are complex, outline a plan before coding
- Prefer simple, clean implementations over clever ones
- Make reasonable assumptions and continue progress if unclear

---

## Goal

Build a responsive, replayable roguelite where:
- each run feels different
- builds evolve through meaningful choices
- combat is satisfying and readable
- systems are clean and scalable
