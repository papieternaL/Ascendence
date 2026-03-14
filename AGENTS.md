# AGENTS HANDOFF (Cursor)

This file is the **single source of truth** for coordination between multiple Cursor chats/agents.

## How to use this file
- **Starting a whole new Cursor folder (no codebase)?** Give the agent **GREENFIELD_SPEC.md** — it contains the full spec (upgrades, systems, boss, enemies, progression, data model) so the agent can build a first iteration from scratch.
- **Starting a new agent conversation?** Give the agent **NEW_AGENT_BRIEF.md** (paste or @-mention) for quick context; then point them here for full detail.
- **Before working**: read this file top-to-bottom.
- **After working**: add a short update under **Changelog** and, if needed, add questions under **Open Questions**.
- **If you change direction**: update **Decisions** (don’t bury key decisions in chat).

## Roles
- **Design Agent (this chat)**: game design rules, systems design, constraints, UX requirements.
- **Build Agent (other chat)**: implement code, refactors, bug fixes, wiring, performance.

## Project: Ascendence (Working Title)
2D pixel-art survivor-like. **Current codebase**: LÖVE2D (Lua). **Target**: build the game **purely through Cursor** — no external engine install (see Platform & tooling below).

### Platform & tooling (Cursor-first)
- **Goal**: Develop and run entirely from this repo in Cursor; no LÖVE or other desktop engine required.
- **Chosen direction**: **Web-based** — port/rewrite to **HTML + JavaScript/TypeScript + Canvas** (or equivalent web stack). Run by opening in a browser or via a simple dev server (`npm run dev` / `npx serve`). All editing in Cursor; play in browser.
- **Visual target**: **Ember Knights-style pixel art** — vibrant, crunchy, juice-heavy. The web build will aim for this from the start: low-resolution canvas (e.g. 320×180 or 426×240) scaled up with nearest-neighbor, palette-conscious art, and juice (hit-stop, particles, screen shake). See “Visual Overhaul Plan” below.
- **Implications**: When porting, replicate current design and data flow (see Codebase Architecture); game logic and content can be translated from Lua to JS/TS while keeping the same structure (scenes, entities, systems, data files).

### Core Vision
- Power fantasy via **massive enemy counts**
- Skill expression via **movement, positioning, manual abilities**
- Bosses are **execution checks**, not stat checks

### Design Laws (DO NOT BREAK)
- No boss crowd control
- (Updated) Abilities may be **auto-cast** if the class kit is designed around it; keep mechanics readable and avoid passive “fire-and-forget” boss counters.
- No infinite ult uptime
- Chaos via quantity, not unreadable mechanics
- Boss difficulty comes from execution, not HP inflation

## Confirmed Design Decisions (as of 2025-12-30)

### Combat & Input Split
- **Auto-Aim**: Primary weapon + Core abilities (Entangle/Arrow Volley) for speed.
- **Manual**: Multi Shot (Q), Utility (Dash) + Ultimates (Frenzy) for skill expression.

### Progression: The Major Level System
- **Major Levels** (1, 5, 10, 15, 20, 25): Grant **mechanical augments only** (e.g., bouncing arrows, lingering slow zones). Pool-based selection.
- **Minor Levels** (all others): Grant **stat upgrades** (damage, speed, crit, etc.) OR **Luck investment** (Luck is just another stat option in the pool).
- **Rerolls**: 3 free rerolls per run; each reroll **re-rolls all 3 cards** and consumes 1 charge.
- **Soft Cap**: Leveling is infinite for fun; mechanical upgrades stop after level 25 (or similar cap) to refocus on boss execution.

### Luck Stat
- Luck is a **per-run stat** that increases Rare/Epic weight at **Major Level rolls only**.
- Players can invest in Luck at minor levels (it's just another option in the stat pool).

### Class Identity: Elemental Attunements
- **Pre-run choice**: Players select attunements before the run starts (loadout-style).
- **Class-locked**: Archer gets Fire/Poison/Dark; Ice Mage gets Dark/Wind (example).
- **Enhancement, not replacement**: Elements modify existing abilities (e.g., Fire adds DoT, Poison adds spread), keeping core mechanics intact.

### MCMs (Mechanic-Carrying Minions)
- Teach boss mechanics during waves.
- Grant **massive EXP burst** on kill (reward engagement).

### Forest Boss: Treent Overlord
- **Phase 1**: Lunge + Bark Barrage.
- **Phase 2 (Territory Control)**: Encompass Root—player is rooted, must manually blast roots while dodging earthquake safe-zone mechanic.
- **Auto-target priority shift**: During root phase, auto-aim intelligently targets roots first so player can escape.

### Meta-Progression: Gear Profile
- **Universal Relics**: Equippable by all classes (e.g., +10% move speed, start with X charges).
- **Class-Specific Relics**: Mechanical shifts per class (e.g., Archer: "Power Shot chains twice").
- **Win/Loss Stakes**: Beat the boss → keep new relics; die → lose them (no extraction mechanic).

### General Rules
- **Controls**: WASD + mouse aim (joystick/mobile later).
- **Healing**: rare chance drop from monsters.
- **Failure**: death (no revive).
- **Boss arenas**: same-map "sealed arena" feel.
- **Run stats page**: show **permanent values only** (base + upgrades; exclude temporary buffs).

## Code Status (implemented)
### Run Stats Overlay (Tab)
- **Toggle**: `Tab` in `PLAYING` opens/closes overlay.
- **Pause**: gameplay pauses while overlay visible.
- **Scroll**: `↑/↓` scroll acquired upgrades list.
- **Permanent-only stats**: overlay reads from `PlayerStats:getPermanent()` when available.

Files touched/added:
- Added: `ui/stats_overlay.lua`
- Updated: `systems/player_stats.lua`
  - logs ordered upgrade picks in `acquiredUpgradeLog`
  - `getUpgradeLog()`
  - `getPermanent(stat)` (excludes temporary buffs)
- Updated: `scenes/game_scene.lua`
  - wires overlay + pause + `drawOverlays()`
- Updated: `main.lua`
  - draws `gameScene:drawOverlays()` on top of HUD
  - routes keypress to scene first so `Tab` is handled

## Codebase Architecture

```
Ascendence/
├── main.lua                 # Entry point, HUD rendering, input routing, audio init
├── conf.lua                 # LÖVE2D config (1280x720, nearest filter, no physics)
├── AGENTS.md                # Design doc & handoff notes (this file)
│
├── entities/                # Game objects (self-contained update/draw)
│   ├── player.lua           # Archer: movement, abilities, bow aiming, health
│   ├── enemy.lua            # Basic melee: chase AI, root support, knockback
│   ├── lunger.lua           # Charge enemy: 4-state machine (idle→charge→lunge→cooldown)
│   ├── treent.lua           # Elite tank: slow, high HP, reduced knockback
│   ├── arrow.lua            # Projectile: pierce, crit, hit tracking, lifetime
│   ├── fireball.lua         # (unused) Future projectile entity
│   └── tree.lua             # Decorative tree/bush with sway animation
│
├── systems/                 # Game mechanics & managers
│   ├── game_state.lua       # State machine: MENU→SELECT→PLAYING→GAME_OVER
│   ├── player_stats.lua     # Stat computation: base + additive + multiplier + buffs + ability mods
│   ├── upgrade_roll.lua     # Rarity-weighted upgrade selection with MCM charge bonus
│   ├── xp_system.lua        # XP orbs, leveling, level-up queue
│   ├── rarity_charge.lua    # MCM kill tracking → rarity boosts on level-up
│   ├── audio.lua            # Music + SFX system with fading & track management
│   ├── animation.lua        # Sprite animation system
│   ├── particles.lua        # Explosion, dash trail, hit spark particles
│   ├── damage_numbers.lua   # Floating damage text with crit scaling
│   ├── screen_shake.lua     # Camera shake on impact
│   ├── tilemap.lua          # Procedural grass/flowers background
│   └── forest_tilemap.lua   # Kenney Tiny Town: floor, trees, bushes, rocks, flowers
│
├── scenes/
│   ├── scene.lua            # Base scene class
│   ├── scene_manager.lua    # Scene transitions
│   ├── empty.lua            # Empty placeholder
│   └── game_scene.lua       # Main gameplay: spawn, combat, abilities, floor progression
│
├── ui/
│   ├── menu.lua             # Main menu, character/biome/difficulty select, game over
│   ├── upgrade_ui.lua       # Level-up card selection modal (3 cards, animated)
│   └── stats_overlay.lua    # Tab overlay: run stats + acquired upgrades
│
├── data/
│   ├── upgrades_archer.lua  # 12 common + 9 rare + 5 epic archer upgrades
│   └── ability_paths_archer.lua  # Ability-specific upgrades (PS/Entangle/Frenzy)
│
└── assets/
    ├── Audio/               # Kenney audio packs (RPG, Impact, Music Loops, etc.)
    ├── 2D assets/           # Kenney: Tiny Town (env), Tiny Dungeon (weapons/enemies), Monochrome RPG
    └── 32x32/               # Legacy sprites (fallback for bow, arrow, some enemies)
```

### Data Flow
```
Input → Player.update() → Movement
     → GameScene.update()
        → Find nearest enemy → Auto-aim + Auto-fire arrows
        → Auto-cast Power Shot / Entangle
        → Manual: Dash (Space), Frenzy (R)
        → Arrow collision → takeDamage() → Death → XP orb → RarityCharge
        → XP collection → Level-up → UpgradeRoll → UpgradeUI → PlayerStats.applyUpgrade()
        → PlayerStats.get() → applyStatsToPlayer() → Modified combat stats
```

---

## Upgrade System Audit (2026-02-06)

### Working Correctly
| Effect Kind | Status | Notes |
|---|---|---|
| `stat_add` | OK | Additive modifiers applied correctly |
| `stat_mul` | OK | Multiplicative stacking works |
| `weapon_mod: pierce_add` | OK | Pierce wired to primary arrows |
| `weapon_mod: ricochet` | STORED | Data tracked; bounce behavior not yet in arrow.lua |
| `weapon_mod: bonus_projectiles` | **FIXED** | Now fires extra arrows at spread angles |
| `ability_mod` | **FIXED** | Now stored and applied to cooldowns, damage, range, charge gain, etc. |
| `proc` effects | STORED | Most triggers not yet checked in combat loop |
| Buff system | OK | Duration tick + break conditions all functional |

### Issues Fixed
1. `ability_mod` effects silently dropped → handler + accessors added
2. Bonus projectiles never fired → wired into primary shot logic
3. Ability cooldown/damage mods not applied → `applyStatsToPlayer()` reads ability mods
4. Entangle didn't target Treents → added to target loop
5. Entangle boss check missing → added `target.isBoss` guard
6. Frenzy duration/crit/speed not moddable → reads from `getAbilityValue()`
7. Frenzy charge gain not moddable → `charge_gain_mul` applied on kill

### Needs Future Implementation
- Ricochet arrow behavior (bounce projectiles on hit)
- Bleed/Marked status systems (referenced by 5+ upgrades)
- Proc trigger engine (13 distinct trigger types defined in data)
- Chain damage, AOE burst, AOE explosion, Ghost Quiver mechanics

---

## Visual Overhaul Plan: Pixel Roguelite Aesthetic

**Target: Ember Knights-style pixel art** — vibrant, crunchy, juice-heavy. This is the visual target for the **web/Cursor build**; Canvas (or a small back buffer) is well-suited: draw at low resolution, scale to window with `image-rendering: pixelated` (or equivalent), optional WebGL/CSS for bloom/vignette/color grading.

### Phase 1: Rendering Pipeline
- Canvas-based rendering at native pixel resolution (320×180 or 426×240), scaled up nearest-neighbor (crisp pixels, no blur)
- Post-processing: bloom, vignette, per-biome color grading (via second canvas or WebGL)
- Palette-constrained art (32–64 colors per biome) for a cohesive Ember Knights-like look

### Phase 2: Entity Sprites
- Replace all placeholder shapes with animated pixel sprite sheets (16x16 or 24x24)
- Distinct silhouettes per enemy type; squash/stretch movement; anticipation + impact frames
- Player character with idle, run, dash, hurt animations

### Phase 3: VFX & Juice
- Pixel-art particle sprites replacing circle particles
- Hit-stop on kills (~50ms), chromatic aberration, screen flash
- Projectile trails, enemy death disintegration animations

### Phase 4: Environment
- Hand-crafted tile sets per biome with auto-tiling
- Parallax background layers for depth
- Point lights on projectiles/abilities via light map shader

### Asset Pipeline
- Aseprite for sprite creation; 16x16 base grid; 4-frame idle, 6-frame actions

---

## Open Questions
- (none right now)

## Next Steps (suggested, prioritized)
1. **MCM designation + EXP burst**: Tag Treent (and future enemies) as MCM; grant massive XP on kill to teach boss mechanics.
2. **Boss arena + Treent Overlord encounter**: Build separate arena scene; implement two-phase boss (Lunge + Bark Barrage → Encompass Root + Territory Control).
3. **Auto-target priority override**: During root phase, auto-aim targets roots first so player can escape.
4. **Major/Minor Level system**: Detect Major Levels (1,5,10,15,20,25); roll mechanical augments at Major, stats/luck at Minor.
5. **Reroll system**: Add 3-reroll budget; wire reroll button into `UpgradeUI` (re-rolls all 3 cards, consumes 1 charge).
6. **Elemental Attunement pre-run UI**: Add attunement selection screen before run starts (Fire/Poison/Dark for Archer).
7. **Meta-progression scaffold**: Add gear profile screen (Universal + Class relics); wire win/loss → keep/lose relics.
8. **Visual overhaul Phase 1**: Implement canvas rendering + post-processing pipeline.
9. **Proc trigger engine**: Build runtime proc checker for combat loop.
10. **Status effect system**: Implement bleed, marked, shattered_armor statuses.

## Changelog
- 2026-03-14: **Godot combat hit-contract fix + authored HUD pass**:
  - Fixed the Arcane Pistol damage path in `scripts/systems/damage_system.gd` plus `scripts/projectiles/bullet.gd`, `scripts/projectiles/missile.gd`, and `scripts/projectiles/sniper_shot.gd`: player projectiles now react to enemy hurtbox `Area2D` collisions, resolve the owning damageable node, preserve sniper pierce tracking, and keep hit VFX emission through the existing signal path.
  - `scripts/main/main.gd` now exposes HUD-facing run state beyond the original debug strings: current/max health, run timer, and objective progress values, while still driving the existing forest/core/boss flow and cooldown hooks.
  - Rebuilt `scenes/ui/HUD.tscn` and `scripts/ui/hud.gd` into a full-screen authored layout with a top-left timer plaque, top-center objective/boss panel, bottom-center ability plate, separate bottom health panel, left level badge, and bottom XP strip, replacing the previous stacked debug-label presentation.
  - Validation note: this shell still cannot run Godot, so the pass was checked with static script/scene inspection and `git diff --check`; live in-editor validation is still required for collision feel and UI placement.
- 2026-03-14: **Godot forest run slice milestone (Arcane Pistol first pass)**:
  - Expanded the Godot `Main.tscn` loop into a real forest-run slice in `scripts/main/main.gd`: nearest-target Arcane Pistol combat, level-up pause/selection flow, forest-wave progression into a core objective, Treent boss spawn, boss bark-shot/root wiring, objective/boss HUD state, and restart/victory messaging.
  - `scripts/main/arena.gd` now draws a larger authored forest clearing with fixed player/core/boss anchor positions and exposes clamp/spawn helper methods so the run takes place in a bounded forest arena instead of a blank test scene.
  - Added `scripts/enemies/objective_core.gd` + `scenes/enemies/ObjectiveCore.tscn` for destructible forest cores, and `scripts/enemies/treent_boss.gd` + `scenes/enemies/TreentBoss.tscn` for a first Treent Overlord pass with lunge, bark barrage, and phase-two Encompass Root / territory pressure hooks.
  - Added `scripts/projectiles/enemy_bark_shot.gd` + `scenes/projectiles/EnemyBarkShot.tscn` for boss projectile pressure, and extended `scripts/player/player.gd` / `scenes/player/Player.tscn` with root-state handling plus a smoothing `Camera2D`.
  - `scripts/enemies/enemy_base.gd` now exposes `display_name` / `enemy_kind` and groups enemies by kind so objectives, boss logic, and HUD targeting can share the same damage/death contract.
  - `scripts/ui/hud.gd` now surfaces objective and boss state alongside the existing HP/XP/cooldown/runtime labels for the forest slice.
  - Validation note: this shell still cannot launch Godot, so the slice was verified by code-path inspection and `git diff --check`, not by running `Main.tscn` in-editor.
- 2026-03-14: **Godot loop tranche after syncing local `ascendence-0.5` to origin**:
  - Discarded the dirty local Love2D/web pivot state and hard-synced the repo to `origin/ascendence-0.5`, making the upstream Godot 4 + GDScript project the active migration baseline.
  - `scripts/main/main.gd`: replaced the fixed demo-only behavior with a fuller Arcane Pistol gameplay loop: nearest-enemy lock for primary fire with mouse fallback, Arcane Sniper ultimate activation on `R`, enemy contact damage, death/restart flow, XP gain from kills, simple level-up upgrade picks, and timed enemy spawning.
  - `scripts/player/player.gd`, `scripts/enemies/enemy_base.gd`, `scripts/enemies/chaser_enemy.gd`, and `scripts/enemies/dummy_enemy.gd`: added procedural placeholder rendering, player damage/invulnerability/death signaling, enemy contact damage/xp rewards, and more usable chase behavior.
  - `scripts/projectiles/bullet.gd`, `scripts/projectiles/missile.gd`, and `scripts/projectiles/sniper_shot.gd`: upgraded projectile readability and gameplay behavior with procedural draw passes, sniper piercing, and shared hit signaling.
  - Added `scripts/systems/experience_system.gd` and `scripts/systems/upgrade_catalog.gd` for a lightweight Godot-native XP/level-up pipeline, plus `scripts/effects/trail_effect.gd` and `scripts/effects/death_effect.gd` with matching scene wiring for better fire/death feedback.
  - `scripts/ui/hud.gd` now surfaces runtime loop state beyond the original health/cooldown bars: level/xp, wave/enemy count, target label, sniper status, upgrade prompt, and game-over prompt.
  - Validation note: Godot is not installed in this shell (`godot`/`godot4` unavailable), so this tranche was validated by static scene/script inspection and repo consistency checks rather than an editor/runtime launch.
- 2026-03-14: **Godot Phase 2 combat foundation (primary/missiles/cooldowns/HUD)**:
  - Implemented Arcane Pistol primary fire in `scripts/main/main.gd` with cooldown-gated bullet spawning and nearest-enemy targeting behavior.
  - Implemented Arcane Missiles casting pipeline (`ability_2`/E) via `scenes/abilities/ArcaneMissiles.tscn` + `scripts/abilities/arcane_missiles.gd`, spawning homing missiles against sorted nearby targets.
  - Upgraded `scripts/systems/cooldown_system.gd` to run per-frame ticking and expose `is_ready()` / `get_remaining()` for gameplay and HUD use.
  - Added hit feedback through enemy damage flash (`scripts/enemies/enemy_base.gd`) and reusable impact ring VFX (`scenes/effects/HitEffect.tscn`, `scripts/effects/hit_effect.gd`), and expanded `scripts/ui/hud.gd` for health + cooldown display.
- 2026-03-14: **Godot scene-structure correctness pass (post-feedback)**:
  - Reworked `scenes/main/Main.tscn` into a deterministic composition tree with pre-instanced `Player` and `HUD`, plus a visible `Systems` subtree (`DamageSystem`, `CooldownSystem`, `Spawner`) for cleaner scene-first migration workflows.
  - Added concrete collision `Shape2D` sub-resources to player/enemy/projectile scenes so baseline scenes load without missing-shape warnings and are safer to validate in-editor.
  - Updated runtime scaffolding (`scripts/main/main.gd`, `scripts/player/player.gd`, `scripts/enemies/enemy_base.gd`, projectile scripts, and `project.godot` autoload) to better align with Godot node contracts while staying feature-light.
  - Added `docs/godot_mcp_setup.md` and expanded migration notes with a scene validation checklist for Godot-MCP-based editor verification.
- 2026-03-14: **Godot 4 migration skeleton scaffold pass**:
  - Added a full `project.godot` bootstrap and Godot-first directory scaffolding (`scripts/`, `resources/configs/`, and scene domains under `scenes/`) while keeping the existing Love2D folders intact for staged migration.
  - Created starter reusable scenes for main flow, player, enemy variants, projectile variants, abilities, HUD widgets, and effects, each with matching script stubs and TODO-safe migration hooks.
  - Added baseline config resources (`player_stats`, `weapon_stats`, `missile_stats`, `enemy_stats`) plus `docs/migration_notes.md` documenting folder mapping rules and phased migration plan.
- 2026-03-06: **Forest grounding/art-direction pass + boss arena environment rebuild**:
  - `systems/forest_tilemap.lua`: removed the remaining screen-space ambient orb overlay entirely, replaced it with world-space composition layers (macro grass-value patches, edge framing, pebble/needle-bed decals), and added stronger contact shadows under trees, bushes, rocks, and blockers so props feel planted on the floor.
  - `scenes/boss_arena_scene.lua`: removed the placeholder Monochrome RPG edge-prop treatment and rebuilt the room as a dedicated forest arena with a central clearing, root-ring framing, stone/stump perimeter accents, and subdued edge dressing that fits the main game's current visual language.
  - `main.lua`: enlarged the timer plaque again and raised the bottom XP strip/level badge to keep the level readout clear of the bottom edge.
  - `scenes/game_scene.lua`: moved the major progress bar higher again to separate it from gameplay and the top HUD.
- 2026-03-06: **Forest layout composition fix before further polish**:
  - `systems/forest_tilemap.lua`: upgraded forest generation from loose random scatter to a clearer composition pass with a protected central playfield, readable horizontal/vertical combat lanes, stronger edge weighting, and denser peripheral clustering so the level has usable focal hierarchy before additional polish layers are added.
  - Large blockers now bias toward more intentional outer anchor zones instead of random mid-field placement, which should improve path readability and preserve cleaner combat space around the player spawn and objective flow.
- 2026-03-06: **Shadow rollback + bottom HUD separation fix**:
  - `systems/forest_tilemap.lua`: removed the added ground-shadow layer and stripped the remaining dark macro shadow blobs/edge darkening after they were reading as random circles and making props feel like they were hovering.
  - `main.lua`: moved the bottom health plate higher so it no longer collides with the bottom XP strip.
- 2026-03-06: **Forest cleanup correction + HUD spacing polish**:
  - `systems/forest_tilemap.lua`: removed the guessed decorative D-sheet prop layer and the glowing ground-dot accents after they produced broken-looking half props and random green circles in-game; the denser trees/rocks/bushes remain.
  - `main.lua`: raised the bottom XP strip slightly so the level badge text no longer clips against the bottom edge, and increased the top-left timer plaque by about 15%.
  - `scenes/game_scene.lua`: moved the top progress bar higher for cleaner separation from the map and tighter HUD composition.
- 2026-03-06: **Attunement gating fix + progress bar polish + forest density pass**:
  - `scenes/game_scene.lua`: restored the rule that the currently active attunement card must never appear in upgrade choices again; active elements now scale through their follow-up upgrades instead of re-rolling the same attunement card.
  - `scenes/game_scene.lua`: the top boss-progress track is larger, slightly higher, and more polished, with the explicit `OBJECTIVE` label removed so the milestone stays mysterious until it triggers.
  - `systems/forest_tilemap.lua`: removed the screen-edge darkening overlay, increased tree/rock/bush density, and added a new decorative scatter layer using extra `Fantasy_Outside_D_green_NoShadow` props (stumps, logs, shrubs, and flower pieces) to make the forest feel fuller and more authored.
- 2026-03-05: **Repeat-pick stacking pass + burn VFX upgrade**:
  - `systems/player_stats.lua` now treats acquired upgrades as counted stacks instead of one-time booleans, recomputes from the full pick log, and merges repeat proc/buff/element effects so duplicate picks actually improve the build instead of silently doing nothing.
  - `scenes/game_scene.lua` was temporarily opened to repeat active attunement picks during the stacking pass; this was later corrected on `2026-03-06` so the same attunement card does not appear again.
  - `systems/particles.lua`, `scenes/game_scene.lua`, and `scenes/boss_arena_scene.lua` now give burning targets a proper ember/flame treatment with stronger burn tick flares and a persistent fiery aura instead of reusing the old bleed drip placeholder.
- 2026-03-05: **Split Shot retune + ricochet/lightning performance pass**:
  - `data/upgrades_archer.lua`: removed `Light Quiver` as the overlapping extra-shot proc and retuned `Split Shot` to trigger every 3rd shot instead of every 4th.
  - `systems/proc_engine.lua`: added a dedicated on-hit damage-multiplier evaluation path so primary hits no longer run the full proc scan twice before/after crit resolution.
  - `scenes/game_scene.lua`: nearest-target helpers now compare squared distances instead of using `sqrt` on every candidate, and chain lightning now trims cosmetic overhead after the first few jumps (fewer arc/damage-number spawns) while preserving actual jump damage and targeting.
- 2026-03-05: **Objective target + reward chest pass**:
  - Removed the top-right in-run quit button from `main.lua` and disabled its click handling so the top HUD stays cleaner.
  - Removed the player's floating green HP bar in `entities/player.lua`; health now reads from the bottom HUD only.
  - `scenes/game_scene.lua` now prioritizes live cores for primary fire, Multi Shot, Arrow Volley targeting, ricochet retargeting, and objective-adjacent AOE/chain follow-up so the objective can be cleared through the normal combat kit.
  - Added `entities/treasure_chest.lua` and rewired the timed core objective reward: finishing the cores in time now spawns a breakable treasure chest that drops a guaranteed rare-only 3-card reward when destroyed.
  - Arrow Volley and arrows now damage objective targets directly, and the objective HUD reflects the chest phase after the cores are cleared.
- 2026-03-05: **Boss arena HUD parity + typing window extension**:
  - `main.lua` now routes boss fights through the same shared top/bottom HUD renderer as normal gameplay, with a small ability-id alias so the boss arena's `arrow_volley` still appears in the regular `E` slot.
  - `scenes/boss_arena_scene.lua` no longer draws the old corner ability HUD/buff strip, and its boss HP bar was restyled into the same centered slim-panel language used by the main-game progression bar.
  - `entities/treent_overlord.lua` no longer prints `PHASE 1/2` above the boss sprite.
  - Boss typing-test windows now use `115%` of the base vine cast time, giving the player 15% more time to finish the sequence.
- 2026-03-05: **Shared HUD scale-up + timer moved top-left**:
  - `main.lua` now treats the gameplay HUD as a shared scaled system (`+10%`) so the center crest, bottom health plate, and ability row all render larger in both the regular map and boss arena.
  - The run timer was moved out of the top-center stack into a dedicated top-left plaque to prevent overlap with boss and progression bars.
  - `getAbilitySlotLayout()` was updated alongside the HUD scale so tutorial/highlight logic continues to line up with the larger ability row.
- 2026-03-05: **Upgrade overlap cleanup pass**:
  - Fixed a data bug in `data/upgrades_archer.lua` where `Arrowstorm` was sitting in the epic section but tagged as `rare`.
  - Reworked `Light Quiver` away from another extra-arrow trigger into a short attack-speed tempo proc, and shifted `Phase Roll: Focused` from dash-damage into a dash-crit window so it no longer overlaps as heavily with `Ghost Quiver`.
  - Renamed/retuned several Arrow Volley path descriptions in `data/ability_paths_archer.lua` so `Mirror Volley`, `Satellite Volley`, `Volley Line`, and `Explosion Volley` read as more distinct choices during selection.
- 2026-03-05: **Upgrade pool trim pass + magnet drop reduction**:
  - Removed `Ghost Quiver`, `Battle Rhythm`, all bleed upgrades (`Barbed Shafts`, `Bleeding Frenzy`, `Hemorrhage`), and the range/close-range picks (`Long Draw`, `Keen Focus`) from `data/upgrades_archer.lua`.
  - Merged `Bigger Blast Radius` into `Ice Blast`, so the ice on-death package now grants both the proc and the radius increase in a single pick.
  - Renamed Arrow Volley path upgrades from `Satellite Volley` -> `Orbit Volley` and `Mirror Volley` -> `Twin Volley`, and made `P.arrow_volley` the primary ability-path table while keeping `P.entangle` only as a compatibility alias for current runtime wiring.
  - Reduced the XP magnet drop chance in `scenes/game_scene.lua` from `5%` to `2.5%`.
- 2026-03-05: **Gameplay XP bar restored**:
  - `scenes/game_scene.lua` now draws the level XP bar again during normal gameplay in a slimmer centered slot under the top crest.
  - The boss-approach bar was moved lower so the restored XP bar and major-progress bar no longer overlap.
- 2026-03-05: **Boss-progress milestone bar pass**:
  - `scenes/game_scene.lua` now draws the major boss-progression track with visible milestone cuts and icon markers so players can read when the core objective is coming before it starts.
  - Replaced the plain boss-text endpoint treatment with a stylized skull marker and shifted the bar toward a cleaner milestone-driven presentation inspired by the provided reference.
- 2026-03-05: **Core objective progress timing fix**:
  - `scenes/game_scene.lua` no longer grants boss-bar progress for each individual core destroyed.
  - The objective completion reward is now the full chunk: `5.6` progress, which matches `8%` of the current `70`-point boss progression bar.
- 2026-03-05: **Run stats overlay visual refresh**:
  - `ui/stats_overlay.lua` was restyled to match the current HUD language with deeper blue-black panels, cyan/gold framing, brighter section headers, stronger title treatment, and a cleaner three-column presentation.
  - The overlay now reads more like an authored in-game profile screen instead of a flat debug sheet while preserving the same stat and upgrade information.
- 2026-03-05: **Chest reward gating parity + bottom XP strip**:
  - `scenes/game_scene.lua` now routes chest reward rolls through the same upgrade-eligibility rules as normal level-up cards, so attunement/path restrictions remain consistent and off-path element upgrades no longer appear.
  - `main.lua` removes the large mirrored level block from the top HUD and moves player level progression into a thin Spell Brigade-style XP strip along the bottom edge with a level badge on the left.
  - The top HUD is now reduced to the timer plaque only, leaving the upper center cleaner for objective and boss-progression presentation.
- 2026-03-05: **Bottom HUD split into floating islands**:
  - `main.lua` no longer renders the bottom HUD as one connected footer slab; the abilities now sit in their own smaller floating plate above a separate health bar plate.
  - This intentionally leaves a visible gap of map space between the abilities and health sections so enemies and pickups below the player are easier to read.
  - `getAbilitySlotLayout()` was updated to keep tutorial/highlight references aligned with the new detached ability row position.
- 2026-03-05: **Boss pacing -30% total progression + lower-profile bottom HUD**:
  - `scenes/game_scene.lua` now reduces total boss-portal progression required from `100` to `70`, which is a 30% reduction in total progress needed before the boss portal can spawn.
  - `main.lua` bottom HUD was compressed and lowered toward a footer-style layout so the ability bar sits closer to the bottom edge and obscures less space beneath the player, following the lower-profile reference direction.
- 2026-03-05: **Boss-approach bar surfaced + old top-row bars removed**:
  - `scenes/game_scene.lua` no longer draws the old stacked top-row bars; the legacy XP/top-row strip was removed from the gameplay draw pass.
  - The existing `majorProgress` system is now presented as a cleaner centered bar under the top HUD, with stateful labels (`BOSS APPROACH`, `CORE HUNT`, `PORTAL READY`) so players can read how close they are to the boss portal at a glance.
  - The boss-approach bar hides automatically during the actual boss fight and shows an `ENTER PORTAL` prompt once the portal is available.
- 2026-03-05: **Concept-art UI/HUD pass + upgrade/ability VFX polish**:
  - `ui/upgrade_ui.lua` was reworked toward the provided concept art: the bulky framed banner was replaced with a centered glow-title treatment, cards now use a tighter/narrower layout, stronger rarity-specific framing, icon pedestals, atmospheric modal motes, improved hover/selection scaling, and corrected card hit-testing for the new layout.
  - `main.lua` gameplay HUD was rebuilt into a more authored-looking presentation with a centered top status crest, a more ornamental QUIT button, a reshaped bottom panel, and upgraded ability slots that now include glyphs, stronger ready-state glow, and cleaner slot framing.
  - `systems/particles.lua`, `scenes/game_scene.lua`, and `scenes/boss_arena_scene.lua` received a shared polish pass: new reusable cast/upgrade bursts, richer frenzy/root/dash particles, upgrade-confirm burst feedback, and stronger cast bursts on Multi Shot / Arrow Volley / Frenzy activations in both map and boss contexts.
- 2026-03-03: **Upgrade modal typography tune-back + concept-style pass**:
  - `ui/upgrade_ui.lua` reverts the oversized upgrade card name text from the recent readability bump, bringing the title size back down so long ability names fit more comfortably again.
  - The upgrade modal now uses tighter small-body typography plus subtle text shadowing on the banner and card titles to better match the provided concept-art presentation without changing the rest of the HUD font system.
- 2026-03-03: **Settings menu spacing overhaul + expanded options**:
  - `ui/menu.lua` settings screen was rebuilt into a cleaner two-column layout with shared row hitboxes, improved spacing, and room for additional options without the cramped single-column stacking.
  - Added high-value settings to the main menu settings screen: **Master Volume**, **Reduced Flashes**, **Damage Numbers toggle**, and **FPS Counter toggle**, while keeping existing audio, graphics, and keybind controls.
  - `systems/settings.lua`, `systems/audio.lua`, `systems/damage_numbers.lua`, and `main.lua` now persist and apply the new settings at runtime (master audio scaling, reduced flash intensity/duration, optional combat text hiding, optional FPS overlay).
- 2026-03-03: **Ice VFX polish pass + flash removal**:
  - Removed the screen flash from ice blast / ice dissolve blast in both `scenes/game_scene.lua` and `scenes/boss_arena_scene.lua` so ice detonations keep the hit-stop and shake without the harsh full-screen pop.
  - `systems/particles.lua` now renders ice blast as a cleaner circular frost ring with layered inner halo, crystal spokes, and tighter frost mist so it reads as a proper icy detonation.
  - Chill/freeze enemy overlays in both gameplay and boss arena were upgraded from simple rings to fuller icy aura treatments with cold fill, stronger frost edging, and rotating crystal flecks.
- 2026-03-03: **Global movement speed +5% pass**:
  - Added shared movement multipliers in `data/config.lua` so both the player and spawned monsters get an additional 5% movement speed on top of the current tuning.
  - `scenes/game_scene.lua` now applies `playerMoveSpeedScale` when refreshing player stats and `enemyMoveSpeedScale` when spawning enemies, keeping the speed change centralized and easy to retune.
- 2026-03-03: **Upgrade modal lowered + larger card text**:
  - `ui/upgrade_ui.lua` now places the level-up banner lower so it clears the translucent top HUD strip instead of sitting inside it.
  - The upgrade cards now use cached larger fonts (roughly a 15% readability bump for name/body/tag text) so card copy reads more cleanly at gameplay scale.
- 2026-03-03: **Main menu subtitle removed**:
  - Removed the "A Descent Into Darkness" subtitle from the main menu title block in `ui/menu.lua` so only the `ASCENDENCE` title remains.
- 2026-03-03: **Upgrade modal containment + coin HUD removal + XP magnet + tree collision polish**:
  - **Upgrade modal banner containment**: `ui/upgrade_ui.lua` now sizes the level-up banner from the title width, falls back to a smaller title font when needed, and pushes the cards slightly lower so "LEVEL UP! CHOOSE AN UPGRADE" stays inside the frame.
  - **Top-left HUD cleanup**: `main.lua` removes the unused coin icon / `0` currency display and re-centers the run timer closer to the level readout.
  - **XP magnet drop**: `systems/xp_system.lua` now supports a dedicated magnet pickup that visually reads as a larger premium XP orb; when collected it flags every XP orb on the map to home into the player. `scenes/game_scene.lua` now routes monster XP drops through a shared helper and gives the magnet a 5% drop chance on enemy deaths.
  - **Tree collision + bush grounding**: `systems/forest_tilemap.lua` now builds trunk collision blockers for the large trees, exposes combined movement blockers for player/enemy collision, and draws bushes a few pixels lower so they sit more naturally on the ground plane.
- 2026-03-03: **Forest blocker alignment + hole removal + light floor accents**:
  - `systems/forest_tilemap.lua` now excludes the incorrect cave/hole sprite from the rock pool and uses a single safe large rock sprite for LOS blockers, removing the random hole prop from the map.
  - Large blocker collision was tightened to a consistent tuned radius and shifted upward relative to the sprite draw position so the collision footprint better matches the visible big rock instead of letting the player overlap the top of it.
  - Added a subtle floor-depth pass on the seamless grass base: about 10% of the ground detail budget is now split between tiny flowers and grass tufts (5% each), with the rest staying low-contrast so the floor remains clean.
  - Files: systems/forest_tilemap.lua, AGENTS.md.
- 2026-03-03: **Camera clamp fix + zoom-out + larger field pass**:
  - `systems/camera.lua` now supports camera zoom and viewport-aware clamping; it no longer allows downward overscroll past world bounds, which prevents the black void below the map from becoming visible.
  - `systems/enemy_spawner.lua` now uses the camera's actual visible world rectangle (top-left + viewport size) for off-screen spawning, which keeps spawn positions consistent with the zoomed camera.
  - `scenes/game_scene.lua` now applies a shared enemy size multiplier at spawn time so regular monsters render larger without hand-editing each enemy class.
  - `data/config.lua` increases world size by 10% (`2640x1760`), sets a mild zoom-out (`0.90`), adds a slight upward follow bias, and enables a shared enemy scale (`1.18`).
  - Files: systems/camera.lua, systems/enemy_spawner.lua, scenes/game_scene.lua, data/config.lua, AGENTS.md.
- 2026-03-03: **Forest floor simplified to seamless green base**:
  - `systems/forest_tilemap.lua` no longer repeats the cropped floor image for the Winlu floor path; it now uses a clean seamless green grass fill so no tile seams, grid lines, or mixed transition cells appear.
  - This intentionally prioritizes a clean uninterrupted forest base over showing any autotile edge detail until a dedicated seamless grass texture is chosen.
  - Files: systems/forest_tilemap.lua, AGENTS.md.
- 2026-03-03: **Forest floor seamless grass pass**:
  - `systems/forest_tilemap.lua` now uses a larger grass patch crop from the `Fantasy_Outside_A2_green` sheet for the floor instead of a small single-cell tile, and it draws that patch at native size to avoid visible repeated grid seams.
  - `data/config.lua` now points `winluFloorSheet` at `Fantasy_Outside_A2_green.png` so the forest floor comes from the correct grass sheet page provided by the user.
  - Files: systems/forest_tilemap.lua, data/config.lua, AGENTS.md.
- 2026-03-03: **Forest simplification pass from direct art references**:
  - `systems/forest_tilemap.lua` now uses a single repeated Winlu floor tile for the full forest ground instead of mixing multiple guessed floor cells.
  - Winlu tree usage was reduced to the two reference silhouettes (one tall pine, one rounded tree) with much lower spawn counts for a cleaner, less cluttered map.
  - Forest prop density was reduced overall (trees, small trees, bushes, rocks), and large LOS blockers now spawn less frequently but remain heavier rock-based blockers.
  - When the Winlu floor is active, the ground micro-detail pass is reduced so the official floor art stays readable instead of being over-painted.
  - Files: systems/forest_tilemap.lua, AGENTS.md.
- 2026-03-03: **Forest art pass with Winlu official sprites**:
  - `systems/forest_tilemap.lua` now prefers the new Winlu green no-shadow assets for forest rendering: the floor uses `Fantasy_Outside_A5_green`, trees use `!$Big_Trees_green_NoShadow`, and rock props/large blockers use `Fantasy_Outside_D_green_NoShadow`.
  - Added multi-atlas sprite registration so the forest tilemap can mix the legacy fallback sheets with the new official tree, decor, and floor sheets without breaking fallback rendering.
  - Large procedural blocker rocks are now replaced by scaled official rock sprites when the Winlu decor sheet is present, while the procedural fallback remains intact if those assets are missing.
  - `data/config.lua` now exposes explicit Winlu asset paths under `Config.ForestScene`.
  - Files: systems/forest_tilemap.lua, data/config.lua, AGENTS.md.
- 2026-03-03: **Tutorial phase reset positioning**:
  - `scenes/tutorial_scene.lua` now re-centers the player and clears active dash state whenever a new tutorial phase starts, so each phase begins from neutral and the player must move back into range before auto-fire/auto-cast triggers.
  - Files: scenes/tutorial_scene.lua, AGENTS.md.
- 2026-03-03: **Tutorial prompt spacing + top-safe placement pass**:
  - `scenes/tutorial_scene.lua` now places the tutorial prompt panel in a top-safe HUD zone instead of mid-screen, so it reads as UI and stops hovering directly over the player.
  - Increased tutorial panel height/width and added more vertical spacing between the large gold title, body copy, and hint text to remove the cramped/janky stacking.
  - Files: scenes/tutorial_scene.lua, AGENTS.md.
- 2026-03-03: **Tutorial readability + movement task UI pass**:
  - `scenes/tutorial_scene.lua` now uses progressive typewriter-style text reveal for tutorial title/body/hint text so phases read in instead of dumping full text immediately.
  - Tutorial panel layout was expanded and re-spaced to reduce title/body/hint overlap, especially on longer phases like Primary Attack and Frenzy.
  - The task tracker now sits to the side of the tutorial panel instead of underneath it, keeping the player area clearer.
  - Movement phase now shows a dedicated 4-checkbox WASD tracker (`W`, `A`, `S`, `D`) with per-key completion instead of a single binary task line.
  - Tutorial dummies now spawn farther away so primary fire and auto-cast tutorial phases require moving into range before they trigger.
  - Frenzy task copy now explicitly instructs `Press R` instead of saying to use the shown key.
  - Files: scenes/tutorial_scene.lua, AGENTS.md.
- 2026-03-03: **Settings/tutorial/stats layout cleanup + tutorial task tracker**:
  - **Settings layout anchored to frame**: `ui/menu.lua` now positions slider rows, graphics toggles, keybind rows, and BACK using the settings frame bounds instead of loose screen percentages, so the title and controls stay inside the panel.
  - **Tutorial task tracker**: `scenes/tutorial_scene.lua` now shows a separate small task window under the tutorial panel with a binary progress state (`0/1` -> `1/1`) for the active objective.
  - **Tutorial completion hold**: tutorial phases now pause briefly after completion before advancing, so players can actually see the tracker flip to `1/1`.
  - **Stats overlay spacing pass**: `ui/stats_overlay.lua` now uses tighter column sizing, safer header alignment, and truncation for long entries so labels and upgrade names stay inside their columns.
  - **Follow-up overlap reduction**: `main.lua` HUD font sizes were reduced slightly, `scenes/tutorial_scene.lua` now uses constrained title/body/hint rows with truncation, and `ui/ability_hud.lua` no longer leaks temporary font changes into later UI draws.
  - **Menu + level-up card containment pass**: `ui/menu.lua` now constrains biome and character card text inside their cards, with larger card bounds and updated hitboxes; `ui/upgrade_ui.lua` now uses tighter description spacing and line limits so level-up descriptions/previews stay inside the upgrade cards.
  - **Visual cleanup + brightness control**: `systems/forest_tilemap.lua` removes the obvious circular blocker placeholders and concentric gameplay vignette rings, brightens the forest palette slightly, `systems/settings.lua` adds persistent graphics brightness, and `ui/menu.lua` now exposes brightness as a settings slider. `main.lua` applies the brightness pass globally across menu and gameplay rendering.
  - Files: ui/menu.lua, scenes/tutorial_scene.lua, ui/stats_overlay.lua, AGENTS.md.
- 2026-03-02: **Typography + color palette pass (menu/HUD readability and style)**:
  - Updated global UI font paths in `main.lua` to a squarer, more retro-futuristic set (`Kenney Future Square` + `Kenney Bold`) to better match the requested reference style.
  - Refined `ui/menu.lua` with a centralized palette (gold title accents + cool cyan highlights) and applied it across menu title, subtitle, slider/toggle states, section labels, and back button text.
  - Updated menu particle and radial background tinting toward cooler cosmic hues while keeping existing fallback rendering behavior.
  - Files: main.lua, ui/menu.lua, AGENTS.md.
- 2026-03-02: **Forest map HD-style art pass scaffold (asset-first + richer fallback)**:
  - Upgraded `systems/forest_tilemap.lua` to an **asset-first renderer** with safe fallback: supports optional `grass_dirt`, `forest_sheet`, and sprite quads (trees/bushes/rocks/root clumps) while preserving procedural drawing when assets are missing.
  - Added richer floor rendering for closer-to-reference look: deeper green grading, micro ground detail (leaf specks + glow flecks), denser prop distribution, and improved world texture tiling behavior.
  - Added subtle screen-space ambience via `drawScreenOverlay()` (vignette + glowing firefly specks) and wired updates so ambience animates continuously.
  - Integrated overlay into gameplay draw flow and ambience update into `GameScene:update` for consistent visual polish during normal play and modal pauses.
  - Files: systems/forest_tilemap.lua, scenes/game_scene.lua, AGENTS.md.
- 2026-03-02: **Menu visual pass: cosmic backdrop + image-driven chrome + quick state shortcuts**:
  - Added optional image-driven menu visuals in `ui/menu.lua` with safe fallbacks: cosmic background (`assets/ui/backgrounds/cosmic_space_ripple.png`), title, menu button, settings frame, and back button art if present.
  - Menu background now applies subtle continuous drift/rotation and additive highlight accents for selected buttons.
  - `Menu:draw()` now renders the shared background first for menu-family states, then overlays state-specific UI.
  - Added shortcut parity requested for quick navigation: `S` opens Settings from Main Menu; `Backspace` returns to Main Menu from Settings (Escape still works).
  - Files: ui/menu.lua, AGENTS.md.
- 2026-02-15: **Ice attunement rework + Arrow Volley upgrades + Tactical Spacing removed**:
  - **Tactical Spacing removed**: "Deal 25% more damage to distant enemies" upgrade deleted.
  - **Ice Attunement rework**: Base effect now applies chill (slow) instead of freeze; when chill expires, ice burst deals AOE damage at entity position. StatusEffects.update returns expiredChillEntity for chill-expiry handling.
  - **Ice Blast (rare)**: When enemies die with chill or freeze, they release an ice blast (AOE damage). Proc engine + executeAction in game_scene and boss_arena.
  - **Double Volley (common)**: Arrow Volley spawns 2 volleys at once.
  - **Volley Line (rare)**: Arrow Volley becomes 3 smaller circles in a vertical line (OOO).
  - **Explosion Volley (rare)**: Arrow Volley applies burn on impact.
  - Boss arena: ProcEngine for on-kill procs; status effect ticking for boss/adds; chill expiry burst; ice blast on add death.
  - Files: data/upgrades_archer.lua, data/ability_paths_archer.lua, systems/status_effects.lua, systems/player_stats.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua.
- 2026-02-15: **Boss arena auto-aim/attack parity with main game**:
  - Primary aim and fire now auto-target boss/adds (nearest in range) instead of mouse.
  - Multi Shot (Q) auto-casts at nearest target when off cooldown; manual Q key removed.
  - Bonus projectiles from weapon mods now fire in boss arena.
  - `fireMultiShot(targetX, targetY)` accepts target coords for auto-cast; falls back to mouse when nil.
  - Files: scenes/boss_arena_scene.lua.
- 2026-02-15: **Boss Test instant teleport**:
  - Main menu Boss Test now teleports straight into the boss arena (no main map visible).
  - Added optional `instant` param to `GameState:transitionTo(newState, instant)` and `enterBossFight(instant)`.
  - Menu uses `transitionTo(PLAYING, true)` for Boss Test; main.lua uses `enterBossFight(true)` and creates boss arena in same frame.
  - Files: systems/game_state.lua, ui/menu.lua, main.lua.
- 2026-02-15: **Tutorial skip + Begin button**:
  - **Tab to skip**: "Press Tab to skip tutorial" shown in panel; Tab at any time transitions directly to main game (for returning players).
  - **Begin button**: On complete phase, clickable "BEGIN" button below the hint; ENTER or click both start the game.
  - Main.lua: TUTORIAL state now receives mousepressed for button clicks.
  - Files: scenes/tutorial_scene.lua, main.lua, AGENTS.md.
- 2026-02-15: **Tutorial Arrow Volley: 3s CD + in-game VFX**:
  - **3s cooldown**: Arrow Volley phase starts with 3s cooldown (currentCooldown = 3) so it doesn't fire immediately; player sees the countdown before it triggers.
  - **Real ArrowVolley entity**: Replaced fake arrow-circle VFX with the actual `ArrowVolley` entity (red target circle, falling arrows, impact flash) to match in-game visuals.
  - Added root burst particles, screen flash, and SFX when volley fires for parity with main game.
  - Files: scenes/tutorial_scene.lua, AGENTS.md.
- 2026-02-15: **Multi-fix: upgrade UI, core timer, pause sliders, boss arrows, attunement**:
  - **Upgrade cards**: Description starts at lineY 138 (below brighter band); nameFont uiBody, descFont uiSmall; brighter grey background (0.18).
  - **Core objective timer expiry**: When timer hits limit, cores despawn, "TASK FAILED" popup + HUD; `despawnCores()` helper; `coreObjectiveFailed` and `coreObjectiveFailPopupTimer`.
  - **Pause settings sliders**: Mouse click on slider track sets value (Music/SFX/Shake); `getPauseOverlayLayout` extended with sliderX/sliderW/sliderH.
  - **Boss arena arrows**: Sync mouse position every frame via `love.mouse.getPosition()` so aim is correct even after transition.
  - **Attunement filter**: Current attunement (fire/ice/lightning) excluded from upgrade roll; only other attunements shown for switching.
  - Files: ui/upgrade_ui.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua.
- 2026-02-15: **Pause menu fix + HUD cleanup**:
  - **Pause menu mouse interaction**: Added `getPauseOverlayLayout()` so draw and hit-test use identical coordinates; expanded hit regions to 56px (optGap) so no dead zones between Resume/Settings/Quit; BACK button uses same layout.
  - **Black bars removed**: Top bar dark fill removed; bottom HUD panel alpha reduced to 0.18 (was 0.85).
  - **Timer placement**: Timer moved from center-right to left, next to level/currency (`coinX + 70`).
  - Files: scenes/game_scene.lua, main.lua.
- 2026-02-15: **Forest Scene (rich environment)**:
  - Added `scenes/forest_scene.lua`: standalone scene with load/update/draw, asset management, procedural map generation, atmospheric particles, tiling background, interactive camera, and Y-sorted rendering.
  - Asset paths: `assets/forest/grass_dirt.png`, `forest_sheet.png`, `fungi_sheet.png` (procedural fallback when missing).
  - Config: `Config.ForestScene` with asset paths. `assets/forest/ASSETS_README.txt` documents required sheet layouts.
  - Use: `ForestScene:new({ player = ..., worldWidth, worldHeight })` then load/update/draw. Can replace or compose with ForestTilemap when integrated into game_scene.
  - Files: scenes/forest_scene.lua, data/config.lua, assets/forest/ASSETS_README.txt.
- 2026-02-15: **Settings menu mouse support + overlap fix**:
  - **Full mouse support**: Sliders (click to set value), toggles (Fullscreen/VSync), keybind rows (click to rebind), and BACK button now respond to left-click.
  - **Hover feedback**: `mousemoved` and `update` update `selectedIndex` for SETTINGS so selection highlight follows the mouse.
  - **Overlap fix**: Section headers (AUDIO, GRAPHICS, KEYBINDS) moved from `y - 4` to `y - 20` to avoid overlap with first item labels.
  - **Shared layout**: Added `getSettingsLayout(w, h)` and `isPointInRect` for consistent hit-testing across draw, mousepressed, and mousemoved.
  - Files: ui/menu.lua.
- 2026-02-15: **Attunement bow VFX + mouse-aim primary**:
  - **Bow attunement VFX**: Fire/Ice/Lightning attunements now show visible aura on the bow (flicker, shimmer, pulse) in both main map and boss arena.
  - **Primary aim**: Auto-fire primary arrows now shoot toward mouse cursor instead of nearest enemy; movement and aim decoupled.
  - **Arrow elemental aura**: Slightly increased visibility (alpha, radius) for Fire/Ice/Lightning projectile auras.
  - Boss arena primary arrows now receive `element` for full attunement VFX parity.
  - Files: entities/player.lua, entities/arrow.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua.
- 2026-02-15: **Tutorial redesign: self-paced phases + practice wave**:
  - **Dummy enemy**: Added `entities/tutorial_dummy.lua` — invulnerable target (Slime-like) for phases 2–6; never dies, shows hit feedback.
  - **Phase flow**: Movement → Primary (approach dummy, observe auto-aim) → Multi Shot (slower CD, observe) → Arrow Volley (slower CD, observe) → Dash (dodge 2 Bark Volley AOEs) → Frenzy (scripted damage, lifesteal demo) → Practice wave (3–5 real slimes) → Complete (ENTER → PLAYING).
  - **Slower pacing**: MIN_PHASE_DURATION 6s; Multi Shot CD 4.5s, Arrow Volley 21s in tutorial.
  - **Dash phase**: BarkVolleyAOE spawns at player every 2.8s; player must dash out of 2 circles.
  - **Frenzy phase**: Player health set to 50%; grant Frenzy charge; lifesteal applied when arrows hit dummy.
  - **Practice wave**: 4 slimes; kill 3 to complete. Death returns to menu.
  - **Transition**: Complete phase transitions to PLAYING (main game) with DEEPWOOD, floor 1.
  - Files: entities/tutorial_dummy.lua, scenes/tutorial_scene.lua, AGENTS.md.
- 2026-02-15: **UI cleanup + tutorial improvements**:
  - **Top bar**: Removed ASCENDENCE text (was overlapping game world). Kept level, currency, time, QUIT.
  - **Ability slots**: Reduced to 4 (Q, SPACE, E, R); removed W placeholder. Removed procedural icons; key labels only.
  - **Tutorial**: Panel moved to play area (h*0.35). Min phase duration 4s; ability-fire wait 5s. Highlight circle uses `getAbilitySlotLayout()` for correct slot alignment.
  - Files: main.lua, scenes/tutorial_scene.lua, AGENTS.md.
- 2026-02-15: **Pause menu mouse clicks**:
  - Pause overlay buttons (Resume, Settings, Quit to Menu) now respond to left-click. Added hit-testing in `GameScene:mousepressed`; Settings sub-view BACK button also clickable.
  - Files: scenes/game_scene.lua.
- 2026-02-15: **Upgrade screen mockup implementation**:
  - **Top bar**: "ASCENDENCE" title, LVL + gem icon, currency (placeholder 0), time (hourglass), QUIT with dark banner. `drawTopBar()` in main.lua; `gameState.runTimer` and `gameState.runCurrency` in game_scene load/update.
  - **Upgrade modal**: Ornate "LEVEL UP! CHOOSE AN UPGRADE" banner with metallic borders and corner flourishes. Metallic card frames (grey common, green rare, blue epic). Type labels (Passive/Element/Projectile) derived from tags. Procedural upgrade icons (boot, flame, snowflake, bolt, arrow, etc.). Larger cards (260x320). Overlay 0.6 alpha so forest visible behind.
  - **Bottom HUD**: Red crystal on left of health bar. Five ability slots (Q Multi Shot, W placeholder, SPACE Dash, E Arrow Volley, R Frenzy) with procedural icons (bow, shield, burst, multi-arrow, focus-arrow).
  - **Data**: `upgrade.type` and `upgrade.icon` added to select upgrades in upgrades_archer.lua; derivation from tags for others. ASSETS_README updated with icon layout for future sprite sheet.
  - Files: main.lua, ui/upgrade_ui.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua, data/upgrades_archer.lua, assets/forest/ASSETS_README.txt, AGENTS.md.
- 2026-02-25: **Upgrade card readability + core objective at 25%**:
  - **Upgrade card text**: Larger fonts (name uiBody, desc uiSmall, tags uiTiny), increased line-height and card size (260x360) for readability.
  - **Core objective delayed**: Cores spawn only when major progress reaches 25% (not at run start). Objective HUD hidden until then.
  - **Objective start popup**: When 25% threshold is crossed, popup displays "CORE OBJECTIVE!" / "DESTROY 20 CORES" with SFX (portal_open), screen flash, and screen shake.
  - Files: ui/upgrade_ui.lua, scenes/game_scene.lua, AGENTS.md.
- 2026-02-15: **Boss rework + Multi Shot + PixelGen**:
  - **Boss phase logic**: Vine Attack sequence only at 50% and 25% HP; removed 5% typing-test trigger. Phase 2 pace multipliers for lunge and bark barrage cooldowns.
  - **Bark Volley AOE**: Circular telegraphed zones near player with config-driven telegraph/damage timing; runs concurrently with lunge + bark barrage.
  - **Multi Shot (Q)**: Replaced Power Shot with manual 3-arrow cone (2.5s cooldown). Fires toward mouse aim in game and boss scenes; disabled during typing test/root.
  - **Power Shot removal**: Removed Power Shot ability path and arch_r_tactical_draw; added Multi Shot path (Wide Spread, Heavy Tips). Updated upgrade_roll, ability_hud, stats_overlay, arrow.lua, status_effects.
  - **PixelGen dev tool**: Added `systems/pixelgen.lua` for procedural asset generation. F9 (when `_G.DEBUG_PIXELGEN` is true) exports to LOVE save dir `generated/`. Isolated; does not affect main gameplay.
  - Files: entities/treent_overlord.lua, entities/bark_volley_aoe.lua, scenes/boss_arena_scene.lua, scenes/game_scene.lua, entities/player.lua, data/config.lua, data/ability_paths_archer.lua, data/upgrades_archer.lua, systems/upgrade_roll.lua, ui/ability_hud.lua, ui/stats_overlay.lua, entities/arrow.lua, data/status_effects.lua, systems/pixelgen.lua, main.lua, AGENTS.md.
- 2026-02-15: **Phase 1 boss pressure + spawn tuning**:
  - **Phase 1 falling trunks**: Trunks now spawn in both phases; Phase 1 uses lighter tuning (2.2s interval, 40 dmg) vs Phase 2 (1.5s, 60 dmg). Config: `trunkPhase1Interval`, `trunkPhase1Damage`, `trunkPhase2Interval`, `trunkPhase2Damage`.
  - **Bark barrage per-shot targeting**: Each bark shot aims at the player's position at fire time (per-shot snapshot) with small random spread (25px) for readability.
  - **Global spawn rate -15%**: Added `global_spawn_rate_mult = 0.85` in enemy_spawner config; applied to spawn cadence so non-boss waves spawn ~15% slower. Stacks with density_mult and late_wave_reduction.
  - Files: scenes/boss_arena_scene.lua, entities/treent_overlord.lua, systems/enemy_spawner.lua, data/config.lua, AGENTS.md.
- 2026-02-15: **Late-wave mob count reduction (-25%)**:
  - Added late-wave spawn scaling in `enemy_spawner`: mob pressure now ramps down in later waves to target ~25% fewer concurrent enemies/spawn batch pressure.
  - Added config knobs: `late_wave_reduction`, `late_wave_start_seconds`, `late_wave_ramp_seconds`.
  - Defaults: reduction starts at 120s and ramps over 90s to full 25% reduction.
  - Files: systems/enemy_spawner.lua, data/config.lua, AGENTS.md.
- 2026-02-15: **Chain lightning VFX tuning**:
  - **Screen flash removed**: Chain lightning no longer triggers global screen flash; hit-freeze retained.
  - **Bolder lightning arc**: Denser segmentation, reduced jag for cleaner shape, dual-layer (bright core + outer glow), larger particles and longer lifetime for stronger silhouette.
  - Files: scenes/game_scene.lua, systems/particles.lua, AGENTS.md.
- 2026-02-15: **Boss Frenzy, attunement visibility, Ricochet clarity**:
  - **Boss-room Frenzy**: Frenzy charge carries over from main game; boss arena gains charge from time-in-combat (3.5/sec) and boss hits (2.5/hit). Ultimate (R) usable in boss room; typing-test lockout unchanged.
  - **Attunement early visibility**: Core attunements (Fire, Ice, Lightning) exempt from path gating so they appear from early levels; pick bias 1.6x so they show reliably.
  - **Ricochet UI + boss parity**: Ricochet description now states "+1 bounce per pick (stacks)"; upgrade card shows "Bounce targets: X -> Y next". Boss arena primary arrows use ricochet params and bounce retarget on hit.
  - Files: scenes/game_scene.lua, scenes/boss_arena_scene.lua, main.lua, data/upgrades_archer.lua, ui/upgrade_ui.lua, AGENTS.md.
- 2026-02-15: **Attunement rarity reversion, Archer HP, music direction**:
  - **Attunements to common**: Fire, Ice, and Lightning Attunements restored to common rarity so players receive them early as integral to Archer kit.
  - **Archer base HP**: Raised Archer baseHP from 80 to 100 in GameState.HeroClasses.
  - **Music direction**: Target vibe set to medieval battle style (reference: https://soundcloud.com/zchegxtpr15s/medieval-battle-music); no track integration yet.
  - Files: data/upgrades_archer.lua, systems/game_state.lua, AGENTS.md.
- 2026-02-13: **Audio rollback + portal prompt + phase 2 movement lock**:
  - **BGM disabled**: Menu, gameplay, boss, and game-over music calls removed; SFX and volume plumbing preserved.
  - **Ability SFX reverted**: Primary shot, power shot, arrow volley use `shoot_arrow`; frenzy uses `hit_heavy`; dash uses `hit_light`. Portal SFX unchanged.
  - **Portal spawn text**: Prompt shows once spawn animation completes (`scale >= 0.9`), not only when player is in activation range.
  - **Phase 2 movement lock**: Player gains `applyRoot(duration)`, `isRooted`, `rootDuration`; movement suppressed when rooted. Boss arena skips `player:update` during typing test and blocks dash when rooted or typing active.
  - Files: main.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua, entities/player.lua, AGENTS.md.
- 2026-02-13: **Audio, boss, upgrade, and visual pass**:
  - **Rare upgrade chance +10%**: Base rarity weights in upgrade_roll.lua adjusted (common 0.60, rare 0.35).
  - **Music + sliders**: BGM re-enabled for menu/gameplay/boss; settings sliders control and persist music/SFX volumes.
  - **Distinct ability SFX**: Primary shot, power shot, arrow volley, frenzy, dash, and portal_open use dedicated sounds.
  - **Boss carryover + scaling**: Full player stat sync at boss arena init; boss HP scales +6%/level above 10 (cap +120%).
  - **Portal polish**: Spawn/open SFX at spawn and activation; stronger pulse, outer ring, and particle burst on spawn complete.
  - **Forest cleanup**: Reduced tree/smallTree/bush/rock/largeBlocker counts; floor thresholds favor darker green tiles.
  - **Arrow Volley cluster targeting**: Prefers clusters of 2–3+ enemies over single targets; fallback to nearest.
  - Files: systems/upgrade_roll.lua, main.lua, systems/audio.lua, scenes/boss_arena_scene.lua, entities/boss_portal.lua, systems/forest_tilemap.lua, scenes/game_scene.lua, AGENTS.md.
- 2026-02-15: **Controlled upgrade path + settings menu + in-run pause/settings + boss typing race**:
  - **Upgrade flow control**: Added staged gating in `game_scene` so elemental build progression is enforced as **Bleed -> Fire -> Lightning -> Ice** while allowing crit/regen utility picks at any stage; added roll bias support (`pickBias`) in `upgrade_roll`.
  - **Persistent settings**: Added `systems/settings.lua` with save/load for music volume, SFX volume, and screen shake intensity (`settings.lua` save file); applied at boot and wired to audio volumes globally.
  - **Settings UI**: Added a dedicated menu `SETTINGS` screen with volume/shake bars and keyboard adjustment.
  - **Pause menu (ESC)**: In `PLAYING`, ESC now opens pause with **Resume / Settings / Quit to Menu**; includes in-run settings bars and pauses gameplay while open.
  - **Boss Phase 2 timing fix**: Typing test now starts concurrently with vine cast timer; player is rooted during typing, and failing to finish before vine attack resolves causes immediate lethal failure.
  - Files: systems/settings.lua, systems/screen_shake.lua, systems/game_state.lua, systems/upgrade_roll.lua, ui/menu.lua, main.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua, AGENTS.md.
- 2026-02-15: **Enemy roster, VFX, HP scaling, upgrade prerequisites**:
  - **Roster**: Removed Basic Enemy and Imp from spawns; bat re-themed to purple (sprite tint + fallback).
  - **Healer VFX**: Vibrant layered beam (outer/mid/core glow), animated green crosses along beam, brighter endpoint glows.
  - **Skeleton**: Procedural sword overlay with swing animation tied to attack range; windup and strike telegraph.
  - **Wizard**: Procedural staff overlay with cast animation (staff raises during isCasting); glowing orb at staff tip.
  - **Hybrid HP scaling**: Enemies scale HP by player level (4%/level), floor (8%/floor), and spawner time (capped 2.5x). Config in `Config.enemy_hp_scaling`.
  - **Upgrade prerequisites**: `requires_upgrade` on bleed-dependent (Bleeding Frenzy, Hemorrhage) and element-dependent (Fire Intensity, Ice Depth, Freeze Spread, Bigger Blast Radius, Lightning Reach). Dependent upgrades hidden until prerequisite owned.
  - Files: systems/enemy_spawner.lua, scenes/game_scene.lua, entities/bat.lua, entities/healer.lua, entities/skeleton.lua, entities/wizard.lua, data/config.lua, data/upgrades_archer.lua, AGENTS.md.
- 2026-02-15: **LOS terrain obstacles (dark floor, large blockers, steering, turn-lock, projectile blocking)**:
  - **Dark-green floor**: Increased dark-green tile probability in forest tilemap floor bands.
  - **Large LOS blockers**: Added large rock/mountain structures as full blockers (player, enemies, projectiles). Represented as circular collision data; drawn procedurally with Y-sort.
  - **Enemy steering**: Melee/chasing enemies resolve position against blockers via `ObstacleNav.resolvePosition`; same-speed obstacle avoidance.
  - **Melee turn-lock**: 0.25s no-attack window when melee enemies change direction significantly (~45°); creates dive-in/out skill windows.
  - **Projectile blocking**: Arrows and bark projectiles blocked by terrain; impact VFX on hit.
  - Files: systems/forest_tilemap.lua, systems/obstacle_navigation.lua, scenes/game_scene.lua, AGENTS.md.
- 2026-02-15: **Attunement rarity rebalance, chain merge, Arrowstorm, HP regen**:
  - **Attunements to rare (blue)**: Fire, Ice, and Lightning Attunements moved from common to rare.
  - **Chain Reaction removed**: Purple chain upgrade removed; progression folded into Lightning Attunement. Base 2 jumps, +1 per additional pick (2→3→4…).
  - **Attunement proc dedupe**: Repeat attunement picks no longer add duplicate proc entries; stacking via element_mod only (e.g. chain_jumps_add).
  - **Arrowstorm rare + reduced arrow count**: Moved to rare; burst reduced from 12 to 8 arrows.
  - **Field Mending (HP regen)**: New rare upgrade: +0.4 HP/sec always-on, stacks (stored in hp_regen_per_sec).
  - Files: data/upgrades_archer.lua, systems/player_stats.lua, systems/upgrade_roll.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua.
- 2026-02-15: **Forest map switched to procedural assets (no Tiny Town dependency)**:
  - Replaced `systems/forest_tilemap.lua` sprite/tile loading with a fully procedural renderer (no external map/prop images).
  - Floor now uses deterministic, muted-green tile variation (stable per tile; no per-frame random flicker), tuned for stronger contrast against ability VFX.
  - Trees, small trees, bushes, and rocks are now procedurally drawn (trunks/foliage/ellipses/shadows) and still integrated with existing Y-sorting in `game_scene`.
  - Prop placement now scatters across the full playable map with spacing rules and a soft center-thinning rule (instead of hard center exclusion), so the map no longer looks empty around player routes.
  - Files: systems/forest_tilemap.lua, AGENTS.md.
- 2026-02-15: **Attunement-First Integrated Workflow (Ice dissolve blast, clarity, upgrades)**:
  - **Ice Attunement dissolve blast**: When ice-attuned primary arrows expire (without hitting), trigger a high-damage ice blast at the arrow position. Base radius 70, damage 1.6× primary. Wired in game_scene and boss_arena_scene.
  - **Upgrade progression**: **Freeze Spread** (arch_r_freeze_spread) — blast spreads chill/freeze to nearby enemies (bosses get chill only). **Bigger Blast Radius** (arch_r_ice_blast_radius) — +25 radius per pick, stacks additively.
  - **Icy blast VFX**: `createIceBlast` in particles.lua — cold shock ring, ice shard burst, frost mist accents (cyan/white, readable on green terrain).
  - **Element mod stacking**: `element_mod` effects with `_add` suffix now stack additively in player_stats.
  - Files: entities/arrow.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua, systems/particles.lua, systems/player_stats.lua, data/upgrades_archer.lua.
- 2026-02-13: **Upgrade UI UTF-8 crash fix**:
  - Replaced byte-based truncation with UTF-8-safe helpers (`utf8SafeSub`, `truncateToWidth`) to prevent `font:getWidth` crash when tags/names contain multi-byte chars (e.g. bullet `•`).
  - Files: ui/upgrade_ui.lua.
- 2026-02-13: **UI/VFX polish: upgrade card overlap, falling arrows, chain lightning, freeze/chill overlays**:
  - **Upgrade card text**: Font-height line spacing, content clipping before tags, name/tag truncation with ellipsis to fix overlapping text.
  - **Arrow Volley**: Impact-timed falling arrows using primary-arrow sprite; damage applies when arrows land. Replaced tick-damage groundAOEs in game_scene; boss arena uses same volley entities for main cast and pending (double_strike, extra_zone).
  - **Chain lightning VFX**: Brighter blue arcs, `createChainLightningImpact` burst at targets, source spark at origin.
  - **Freeze/chill overlays**: Icy cyan ring for freeze, lighter blue aura for chill/slow in both game_scene and boss_arena draw passes.
  - Files: ui/upgrade_ui.lua, entities/arrow_volley.lua, scenes/game_scene.lua, scenes/boss_arena_scene.lua, systems/particles.lua, AGENTS.md.
- 2026-02-13: **Crash fix in `game_scene` draw pass**:
  - Fixed Lua parse error in marked-outline rendering guard: changed method-existence check from invalid `:` syntax to `.` (`drawable.entity.getSize and drawable.entity:getSize()`).
  - Resolves startup failure: `Syntax error: scenes/game_scene.lua ... function arguments expected near 'and'`.
  - Files: scenes/game_scene.lua.
- 2026-02-13: **Archer upgrade overhaul + elemental system**:
  - **Upgrade sync**: Reconciled UPGRADES.txt edits into upgrades_archer.lua and ability_paths_archer.lua (Piercing Practice, Light Quiver, Arrowstorm, Bleeding Frenzy; removed Sundering Arrow/Execution Line from Power Shot path).
  - **Arrow Volley**: 2s persistent falling-arrow field (was 0.6s); Rain of Arrows upgrade adds extra AOE zone; multi-zone support in game and boss scenes.
  - **Switchable primary elements**: Fire/Ice/Lightning attunements with reset-on-switch (switching removes other elements' upgrades from run). Element mods: burn_damage_mul, chill_duration_add, slow_mul, chain_jumps_add.
  - **Status effects**: Burn DoT, chill (slow), freeze (immobilize); bosses receive chill only (no hard freeze). All enemies (incl. DruidTreent) respect freeze/speed from status_effects.
  - **Chain Reaction bias**: Epic main-pool picks give arch_e_chain_reaction 1.25x weight.
  - **VFX polish**: Marked targets show pulsing gold outline; hemorrhage explosion adds blood-drip burst.
  - **XP**: Config.xp_drop_multiplier = 0.75 for longer runs.
  - Files: upgrades_archer.lua, ability_paths_archer.lua, player_stats.lua, status_effects.lua, upgrade_roll.lua, game_scene.lua, boss_arena_scene.lua, druid_treent.lua, config.lua.
- 2026-02-13: **Balance, boss pacing, map props, UI readability**:
  - **Mob density -20%**: Added `density_multiplier = 0.8` in `Config.enemy_spawner`; applied to spawner (interval, max/min enemies, batch size) and floor-start wave counts in `spawnEnemies()`.
  - **Boss adds removed**: Set `maxAddsPhase1` and `maxAddsPhase2` to 0 in boss arena.
  - **Boss volley pressure**: `barkBarrageCooldown` 2.0→1.8 (~10% faster); `barkBarrageCount` 5→6 shots per burst; `vineLaneCount` 5→6. Boss entity now reads `barkBarrageCount` from config.
  - **Map props**: Added rocks (tile_0048–0050) and small trees (tile_0003) to forest tilemap; Y-sorted with entities via `getRocksForSorting`/`getSmallTreesForSorting`.
  - **UI readability**: UI fonts use `linear` filter; added `loadUIFont` and `PixelFonts.ui*` variants. Upgrade UI, stats overlay, menu body/small, and boss UI use these for long descriptions.
  - **Mechanics fixes**: Arrow Volley base damage uses `primary_damage` (was `attack`); stats overlay "Press P"→"Press Tab"; Arrow Volley key [W]→[E].
  - Files: config.lua, enemy_spawner.lua, game_scene.lua, boss_arena_scene.lua, treent_overlord.lua, forest_tilemap.lua, main.lua, upgrade_ui.lua, stats_overlay.lua, menu.lua.
- 2026-02-06: **Boss freeze fix, cooldowns, upgrade UX, Power Shot perf**:
  - **Boss portal freeze**: `JuiceManager.update(dt)` now called every frame in main.lua; `JuiceManager.reset()` on boss arena init prevents stale hit-stop state.
  - **15% cooldown reduction**: `base_cooldown_mul = 0.85` in config; applied in game_scene `applyStatsToPlayer`, boss arena init, and dash use path. Cooldowns applied at run start.
  - **Upgrade stacking + current->next preview**: Same upgrade can be picked multiple times (stacking); cards show "X -> Y next" for already-picked upgrades when `playerStats` is passed to `UpgradeUI:show`.
  - **Upgrade descriptions**: All ability-path upgrades in `ability_paths_archer.lua` now have explicit `description` fields.
  - **Power Shot perf**: Squared-distance collision checks; VFX/SFX throttled for piercing arrows (first 4 hits only); damage numbers capped for non-kill piercing hits.
  - Files: main.lua, juice_manager.lua, boss_arena_scene.lua, config.lua, game_scene.lua, player_stats.lua, upgrade_ui.lua, ability_paths_archer.lua.
- 2026-02-06: **Revert archer sprite + explosion sprite; greener map floor**:
  - **Player**: Archer strip sprite disabled; player rendered as procedural circle only. Animator removed from active runtime; `playAttackAnimation` remains as no-op.
  - **Explosions**: Pixel-burst particles restored (no Tank Pack sprite); `createExplosion` uses color-aware burst.
  - **Forest floor**: Weighted tile selection: ~85% tile_0001 (green), ~15% tile_0002 to reduce tan/sand feel.
  - Files: player.lua, particles.lua, forest_tilemap.lua.
- 2026-02-06: **Asset corrections + Archer animation integration**:
  - **Tiny Town tiles**: Bow and arrow updated to `tile_0118.png` / `tile_0119.png` (player.lua, arrow.lua). Forest floor uses `tile_0001` + `tile_0002` quads; trees/bushes to `tile_0004`/`tile_0005`/`tile_0006`; scatter counts reduced; rocks removed.
  - **Wolf sprite**: Tiny Ski `tile_0078.png` and `tile_0079.png` for idle frames (wolf.lua).
  - **Explosion VFX**: Sprite-based explosion using Tank Pack `tank_explosion3.png`; particles now support image-based particles; `createExplosion` uses `createSpriteExplosion` (particles.lua).
  - **Shoot SFX**: Desert Shooter Pack `shoot-f.ogg` wired to all `Arrow:new` sites (audio.lua, game_scene.lua, boss_arena_scene.lua).
  - **Archer animations**: Strip-based sprites from `assets/Archer/` — idle, run, attack, dash. `player_animator.lua` rewritten; frame count from image width/height; facing from `bowAngle`; horizontal flip when facing left. Player integrated with animator; `playAttackAnimation` called on primary, power shot, arrow storm; dash state syncs during scene update.
  - Files: player.lua, arrow.lua, wolf.lua, forest_tilemap.lua, particles.lua, audio.lua, player_animator.lua, game_scene.lua, boss_arena_scene.lua.
- 2026-02-06: **Tiny Pack asset integration** (Tiny Town + Tiny Dungeon):
  - **Environment**: `forest_tilemap.lua` now uses Tiny Town tilemap for grass floor (quads from tile indices 0–26) and individual Tiles for trees (18–23), bushes (30–32), rocks (48–50), flowers (58–59). Replaced Foliage Pack + Pixel Platformer.
  - **Weapons**: Player bow and arrow use Tiny Dungeon `tile_0108.png` / `tile_0109.png` with fallback chain (Tiny Town → old 32x32). Auto-scale 2x for 16px sprites.
  - **Enemies**: Wizard, Healer, Wolf, SmallTreent use Tiny Dungeon sprites (tiles 72, 74, 80, 76/55) with fallbacks. Scale 1.5x for 16px. Wolf uses sprite when available, else procedural circles.
- 2026-02-06: **Frenzy persistence + lifesteal**:
  - Frenzy no longer ends when taking damage (`break_on_hit_taken` removed in both regular map and boss arena activation).
  - Added configurable Frenzy lifesteal: `Config.Abilities.frenzy.lifeSteal = 0.10` (10% of player damage dealt).
  - Lifesteal now applies to all player outgoing damage paths in both scenes (arrow hits, AOE ticks, proc/chain/hemorrhage damage, boss/add hits, Arrow Volley boss hits).
  - Frenzy damage-taken downside remains active (`damageTakenMult` behavior unchanged).
  - Files: `data/config.lua`, `scenes/game_scene.lua`, `scenes/boss_arena_scene.lua`.
- 2026-02-06: **Wizard dodge window + healer wiring**:
  - Wizard cone attack: `coneInterval` 3.5→5.0 s, `castDuration` 0.6→0.95 s for better dodge window.
  - Healer and DruidTreent fully wired into game_scene: spawn, update (with flattened ally list for healing), arrow collision, contact damage, draw, getAllEnemyLists.
  - Enemy spawner: added healer (weight 1.5) and druid_treent (weight 0.8) to enemy_weights.
  - DruidTreent: fixed `statusComponent:update(dt, self)`, added `applyRoot` for consistency.
  - Files: wizard.lua, game_scene.lua, enemy_spawner.lua, druid_treent.lua.
- 2026-02-06: **Boss crash fix, audio, Frenzy VFX, enemy variety, speed pass**:
  - Fixed boss crash: added `Player:isDead()` to entities/player.lua.
  - Audio: BGM disabled everywhere (menu/gameplay/game over); arrow-hit SFX on enemy/boss impacts via `_G.audio`.
  - Frenzy: ongoing aura particles (`createFrenzyAura`), player glow ring, both regular map and boss arena.
  - Enemy variety: wired `EnemySpawner`, `GameScene:spawnEnemy`; added slime, bat, skeleton, imp, wolf, small_treent, wizard; bark projectiles from small treents; lunger weight 1.5→4.
  - Boss arena: phase-aware adds (lungers, wizards) spawn at edges; arrows hit adds before boss.
  - Speed +12%: player move 200→224, dash 800→896; enemy speeds scaled in spawn; hero class base speeds bumped.
  - Files: player.lua, main.lua, audio, particles.lua, game_scene.lua, boss_arena_scene.lua, enemy_spawner.lua, config.lua, player_stats.lua, game_state.lua.
- 2026-02-06: **Quit buttons, Arrow Volley VFX, XP orb speed, font clarity**:
  - Main-menu Quit closes app (love.event.quit); in-game Quit (top-right HUD) returns to menu.
  - Arrow Volley AOE and screen flash changed from green/gold to red tones.
  - XP orb attraction multiplier increased by 15% (5 → 5.75) in xp_system.lua.
  - Kenney font legibility: HUD font sizes bumped (tiny 16→18, small 20→22, body 28→30, header 40→44); subtle shadow/outline on health, cooldown, XP bar, Quit label, ability icons; menu title/headers/buttons/instructions use shadow + higher contrast.
- 2026-02-09: **GREENFIELD_SPEC.md** — Full spec for building the game in a new Cursor folder with no codebase. Includes: design laws, controls, game state, Archer abilities, all enemy types + MCM/XP, Treent Overlord boss (phases 1 & 2), full upgrade list (common/rare/epic + ability paths), status effects, effect primitives & proc triggers, systems to implement, data flow, and suggested first-iteration MVP scope.
- 2026-02-09: **Ember Knights-style pixel art** confirmed as visual target for the web build. Updated Platform & tooling (visual target bullet), Visual Overhaul Plan (tied to web/Cursor), and NEW_AGENT_BRIEF (visual target in Tech Stack).
- 2026-02-09: **Platform: Cursor-first / web**. Decided to build the game purely through Cursor (no LÖVE install). Target: web-based (HTML + JS/TS + Canvas), run in browser from repo. Added "Platform & tooling" section; removed open question on post-LÖVE target.
- 2026-02-09: **Platform direction**: Documented intent to build the game without LÖVE2D; target (web/Godot/Unity/custom etc.) TBD. Updated project description and Open Questions in AGENTS.md; updated NEW_AGENT_BRIEF.md Tech Stack.
- 2026-02-09: Added **NEW_AGENT_BRIEF.md** — short onboarding doc for new Cursor conversations (project summary, design laws, where spec lives, codebase map, conventions). Updated "How to use this file" to reference it.
- 2026-02-06: Development directives session:
  - **Architecture**: Created full codebase diagram with data flow map in AGENTS.md.
  - **Enemy sprites removed**: Stripped all placeholder Monochrome RPG Tileset sprites from enemy.lua, lunger.lua, treent.lua. Kept fallback geometric shapes + all behavior/logic intact. Added root-state visual feedback to all enemy draw methods.
  - **Upgrade system audit**: Fixed 7 bugs (ability_mod handler, bonus projectiles, Entangle targeting, Frenzy modding). Documented all working/broken/pending upgrade effects.
  - **Visual overhaul plan**: Wrote 4-phase plan for Ember Knights-style pixel aesthetic (canvas rendering → sprites → VFX → environment).
  - **Audio system**: Added `systems/audio.lua` with music playback, SFX, fading, mute toggle (M key). Wired Kenney Music Loops into gameplay (random track on game start), menu, and game over states.
  - Files added: `systems/audio.lua`
  - Files modified: `entities/enemy.lua`, `entities/lunger.lua`, `entities/treent.lua`, `systems/player_stats.lua`, `scenes/game_scene.lua`, `main.lua`, `AGENTS.md`
- 2025-12-30: Major design overhaul captured in handoff:
  - **Major/Minor Level system**: Major levels (1, 5, 10, 15, 20, 25) grant mechanical augments; minor levels grant stats or Luck investment.
  - **Luck stat**: Per-run investment that boosts Rare/Epic odds at Major Levels.
  - **Rerolls**: 3 free rerolls per run.
  - **Elemental Attunements**: Class-locked (Archer: Fire/Poison/Dark); enhance abilities instead of replacing them.
  - **MCM + EXP burst**: MCMs teach boss mechanics and grant massive EXP.
  - **Forest Boss: Treent Overlord**: Two-phase execution check with root mechanic + auto-target priority shift.
  - **Meta-progression: Gear Profile**: Universal + Class-specific Relics; win/loss determines if you keep them.
- 2025-12-30: Implemented floating damage numbers, increased enemy HP, added Treent enemy, swapped to pixel-clean Monochrome RPG Tileset sprites.
- 2025-12-29: Added Tab Run Stats overlay + upgrade history; stats page shows permanent-only values.
- 2025-12-29: Temporarily removed top HUD strip (class/floor/biome); kept bottom health/ability HUD.
- 2025-12-29: Implemented Archer abilities V1:
  - Q Power Shot: auto-cast at nearest enemy when ready, 6s CD, 300% dmg, pierces all, guaranteed crit.
  - E Entangle: auto-cast at nearest target when ready, roots trash/elites and applies +15% dmg taken while rooted (no boss logic yet).
  - R Frenzy: user-activated ult (press R when fully charged), 8s buff, ends early on hit, player takes +15% damage during Frenzy.
  - Added crit + pierce support to projectile loop; primary shots can crit.
- 2025-12-29: Integrated Kenney asset packs for lush forest biome.
  - Added: `systems/forest_tilemap.lua` - procedural forest using Foliage Pack (trees, bushes, rocks, flowers) + Pixel Platformer grass tiles.
  - Updated: `scenes/game_scene.lua` - uses ForestTilemap; removed hardcoded tree/bush generation.
  - Updated: `entities/player.lua`, `entities/arrow.lua`, `entities/tree.lua` - asset paths now point to `assets/` folder with fallbacks.
  - Trees/bushes from tilemap integrate with Y-sorting for proper depth layering.
- 2025-12-29: Updated Archer loop to be less input-heavy:
  - Abilities auto-cast when ready (Power Shot/Entangle); dash remains manual.
  - Ultimate (Frenzy) is user-activated on `R` once fully charged.
  - Level-up UI no longer selects on Space; gameplay inputs are swallowed while the upgrade modal is open.
