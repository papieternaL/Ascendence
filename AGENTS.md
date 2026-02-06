# AGENTS HANDOFF (Cursor)

This file is the **single source of truth** for coordination between multiple Cursor chats/agents.

## How to use this file
- **Before working**: read this file top-to-bottom.
- **After working**: add a short update under **Changelog** and, if needed, add questions under **Open Questions**.
- **If you change direction**: update **Decisions** (don’t bury key decisions in chat).

## Roles
- **Design Agent (this chat)**: game design rules, systems design, constraints, UX requirements.
- **Build Agent (other chat)**: implement code, refactors, bug fixes, wiring, performance.

## Project: Ascendence (Working Title)
2D pixel-art survivor-like in **LÖVE2D (Lua)**.

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
- **Auto-Aim**: Primary weapon + Core abilities (Power Shot, Entangle) for speed.
- **Manual**: Utility (Dash) + Ultimates (Frenzy) for skill expression.

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
│   └── forest_tilemap.lua   # Kenney foliage pack: trees, bushes, rocks, flowers
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
    ├── 2D assets/           # Kenney sprite packs (Foliage, Monochrome RPG, Platformer)
    └── 32x32/               # Custom sprites (bow, arrow)
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

**Target: Ember Knights-style pixel art** — vibrant, crunchy, juice-heavy.

### Phase 1: Rendering Pipeline
- Canvas-based rendering at native pixel resolution (320x180 or 426x240), scaled up nearest-neighbor
- Post-processing shaders: bloom, vignette, per-biome color grading
- Palette-constrained art (32-64 colors per biome)

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

