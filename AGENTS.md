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

## Changelog
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

## Cursor Cloud specific instructions

### Engine & Runtime
- **LÖVE2D 11.5** is the only external dependency. Installed from PPA `ppa:bartbes/love-stable`.
- Lua/LuaJIT is bundled inside LÖVE2D — no separate Lua install needed.
- No package manager, no build step, no lockfile. All `require()` calls reference internal project modules.

### Running the Game
- Launch: `love .` (or `love /workspace`) from the repository root.
- ALSA audio warnings (`cannot find card '0'`) are expected in headless VMs — the game runs fine without audio hardware.
- A display server is required. The VM provides `$DISPLAY=:1` via Xvfb.

### Project Layout
- `main.lua` / `conf.lua` — entry point and LÖVE2D config (1280×720, v11.5).
- `entities/` — player, enemies, projectiles.
- `scenes/` — game scene, scene management.
- `systems/` — tilemap, XP, stats, particles, animation, etc.
- `ui/` — menu, upgrade cards, stats overlay.
- `data/` — upgrade/ability data tables.
- `assets/` — bundled Kenney sprite/audio packs (~465 MB, committed).

### Testing
- There is no automated test suite. Verification is done by running the game (`love .`) and interacting via the GUI.
- Menu flow: BEGIN TRIAL → Choose Hero (Archer) → Select Domain (Deepwood) → Choose Trial (Adept) → gameplay starts.
- Core gameplay: WASD movement, auto-fire arrows, abilities auto-cast, press R for ultimate, Space to dash.

