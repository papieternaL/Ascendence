# New Agent Brief — Ascendence

**Use this when starting a new Cursor conversation** so the agent has project context. For full design history, code status, and changelog, read **AGENTS.md** in this repo.

---

## What This Project Is

**Ascendence** (working title) is a **2D pixel-art survivor-like**. The player controls an Archer through waves of enemies, levels up, picks upgrades from a card system, and eventually faces a boss (Treent Overlord). Core pillars:

- **Power fantasy** via high enemy counts
- **Skill expression** via movement, positioning, and manual abilities (dash, ultimate)
- **Bosses as execution checks**, not stat checks

---

## Tech Stack

- **Current (legacy)**: LÖVE2D (Lua) — run with `love .` from project root.
- **Target**: **Purely through Cursor** — no external engine. Port to **web** (HTML + JavaScript/TypeScript + Canvas). Edit in Cursor; run in browser or via `npm run dev` / dev server.
- **Visual target**: **Ember Knights-style pixel art** — vibrant, crunchy, juice-heavy; low-res canvas scaled up nearest-neighbor, palette-conscious art, hit-stop/particles/screen shake. See AGENTS.md Platform & tooling and Visual Overhaul Plan.

---

## Design Laws (Do Not Break)

- **No boss crowd control** — CC that trivializes the boss is forbidden.
- Abilities may be **auto-cast** if the kit is designed for it; keep mechanics readable.
- **No infinite ult uptime.**
- **Chaos via quantity**, not unreadable mechanics.
- **Boss difficulty from execution**, not HP inflation.

---

## Where the Spec Lives

- **AGENTS.md** — Single source of truth: design decisions, progression (Major/Minor levels, Luck, rerolls), combat (auto-aim vs manual), MCMs, Forest Boss (Treent Overlord), meta-progression (Gear Profile), upgrade audit, visual overhaul plan, next steps, changelog.
- **.cursor/rules/** — Workflow, testing, and game-dev patterns (plan before implementing, modularity, state management, etc.).

---

## Codebase at a Glance

- **Entry**: `main.lua` — boot, input routing, HUD, audio init.
- **Scenes**: `scenes/game_scene.lua` (main gameplay), `scenes/boss_arena_scene.lua` (boss fight). Base: `scenes/scene.lua`; manager: `scenes/scene_manager.lua`.
- **Player**: `entities/player.lua` — Archer movement, bow, abilities (Power Shot, Entangle, Dash, Frenzy).
- **Enemies**: `entities/enemy.lua`, `entities/lunger.lua`, `entities/treent.lua`, plus others (bat, skeleton, slime, wizard, etc.). Boss: `entities/treent_overlord.lua`.
- **Projectiles**: `entities/arrow.lua` (primary + pierce/crit).
- **Systems**: `game_state.lua`, `player_stats.lua`, `upgrade_roll.lua`, `xp_system.lua`, `rarity_charge.lua`, `audio.lua`, `camera.lua`, `targeting_system.lua`, `enemy_spawner.lua`, `proc_engine.lua`, `status_effects.lua`, particles, damage numbers, screen shake, tilemaps, etc.
- **UI**: `menu.lua`, `upgrade_ui.lua`, `stats_overlay.lua` (Tab = run stats).
- **Data**: `data/upgrades_archer.lua`, `data/ability_paths_archer.lua`, `data/enemies.lua`, `data/config.lua`.

**Data flow (simplified):** Input → Player → GameScene → auto-aim/auto-fire + auto-cast abilities → collisions → damage/XP → level-up → UpgradeRoll → UpgradeUI → PlayerStats → applied to player/abilities.

---

## Conventions (from Project Rules)

- **Plan before implementing** — Analyze structure and impact; cite files and logic.
- **Small, focused changes** — One feature or fix at a time.
- **Update AGENTS.md** — Changelog and relevant comments when behavior or design changes.
- **Modularity** — Scenes, entities, systems; keep game logic out of one giant file.
- **Clear state** — Explicit game state (e.g. MENU → SELECT → PLAYING → GAME_OVER); clear update/draw split.

---

## Quick Start for the Agent

1. Read **AGENTS.md** top to bottom before making design or architecture changes.
2. For a specific feature, search the codebase for the relevant system (e.g. upgrades → `player_stats.lua`, `upgrade_roll.lua`, `data/upgrades_archer.lua`).
3. Follow existing patterns when adding entities or systems (see AGENTS.md checklists and codebase architecture).
4. After changes: update **AGENTS.md** Changelog and any affected comments.

---

*This brief is a snapshot for new conversations. For current code status, next steps, and open questions, always refer to AGENTS.md.*
