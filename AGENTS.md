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

