# Ascendence — Full Spec for Greenfield / First Iteration

**Use this document when starting a new Cursor project with no existing code.** Give it to the agent so it can build a first iteration from scratch. The game is a 2D pixel-art survivor-like; target platform is **web** (HTML + JS/TS + Canvas), **Ember Knights-style** aesthetic.

---

## 1. How to Use This Spec

- **No codebase**: Assume empty folder or new repo. Agent creates structure from this spec.
- **First iteration**: Implement a playable MVP (player, one enemy type, basic combat, one ability, level-up with 3 cards, one upgrade pool). Then expand.
- **Design laws**: Must not be broken by any implementation (see §2).
- **Data-driven**: Prefer data files (e.g. `data/upgrades.json`, `data/enemies.json`) so content can be extended without rewriting logic.

---

## 2. Project Identity & Design Laws

### Project
- **Name**: Ascendence (working title)
- **Genre**: 2D pixel-art survivor-like (waves, level-up, card picks, boss fight)
- **Platform**: Web — HTML + JavaScript/TypeScript + Canvas. Run in browser or via `npm run dev`. No external game engine.

### Core Vision
- **Power fantasy** via high enemy counts
- **Skill expression** via movement, positioning, and manual abilities (dash, ultimate)
- **Bosses** are execution checks, not stat checks

### Design Laws (DO NOT BREAK)
- **No boss crowd control** — no CC that trivializes the boss
- Abilities may be **auto-cast** if the kit is designed for it; keep mechanics readable
- **No infinite ult uptime**
- **Chaos via quantity**, not unreadable mechanics
- **Boss difficulty from execution**, not HP inflation

### Visual Target
- **Ember Knights-style pixel art**: vibrant, crunchy, juice-heavy
- Low-res canvas (e.g. 320×180 or 426×240), scaled up **nearest-neighbor**
- Palette-conscious art (32–64 colors); juice: hit-stop, particles, screen shake

---

## 3. Controls & General Rules

- **Movement**: WASD
- **Aim**: Mouse (or joystick later)
- **Primary fire**: Auto-aim at nearest enemy + auto-fire (no click-to-shoot)
- **Abilities**: See §5 (auto-cast vs manual)
- **Healing**: Rare drop from monsters
- **Failure**: Death (no revive)
- **Boss arenas**: Same-map “sealed arena” feel
- **Run stats page**: Show permanent values only (base + upgrades; exclude temporary buffs). Toggle with Tab; pause while open.

---

## 4. Game State Flow

- **MENU** → **CHARACTER_SELECT** (optional) → **BIOME_SELECT** / **DIFFICULTY_SELECT** (optional) → **PLAYING** → **GAME_OVER**
- In PLAYING: spawn waves, combat, XP, level-up (modal with 3 cards), then resume. Boss portal appears at configured level (e.g. 10); entering goes to boss arena or sealed area.

---

## 5. Combat & Input Split

- **Auto-aim**: Primary weapon + core abilities (Power Shot, Entangle) — auto-target nearest valid enemy and auto-cast when off cooldown.
- **Manual**: Dash (Space), Ultimate Frenzy (R when charged). These are player-triggered for skill expression.

---

## 6. Player: Archer

### Base Stats (from config)
- Health: 100
- Primary damage: 10
- Move speed: 200
- Attack speed: 1.0 (shots per second)
- Crit chance: 5%
- Crit damage: 1.5×
- Pierce: 0 (arrows hit one enemy unless upgraded)
- Range: 400
- Dash: speed 800, duration 0.2s, cooldown 1.0s

### Abilities
1. **Power Shot** (auto-cast at nearest enemy when ready)
   - Damage: 300% of base (3×)
   - Cooldown: 6s
   - Pierces all enemies; guaranteed crit
   - Projectile speed 760, knockback 260

2. **Entangle** (auto-cast at nearest valid target when ready)
   - Roots non-boss enemies; +15% damage taken while rooted
   - Cooldown: 8s
   - Range 300, base damage 25, radius 60, damage mult 1.5
   - **No root on bosses** (design law: no boss CC)

3. **Dash** (manual, Space)
   - Invuln during dash; cooldown 1s

4. **Frenzy** (manual, R when fully charged)
   - Duration: 8s; ends early if player takes damage
   - Move speed ×1.25, attack speed ×1.5, +25% crit chance
   - Player takes +15% damage during Frenzy
   - Charge: built by dealing damage / kills (no infinite uptime)

---

## 7. Progression: Levels & Upgrades

### Major vs Minor Levels
- **Major levels**: 1, 5, 10, 15, 20, 25 — grant **mechanical augments only** (e.g. ricochet, slow zones). Pool: ability-path or special augments.
- **Minor levels**: All others — grant **stat upgrades** (damage, speed, crit, etc.) OR **Luck** (another stat in the pool).

### Luck
- Per-run stat. Investing at minor levels increases **Rare/Epic weight at Major Level rolls only**.

### Rerolls
- 3 free rerolls per run. One reroll = re-roll **all 3 cards** and consume 1 charge.

### Level-up UX
- On level-up: pause (or slow) gameplay; show **3 cards**. Player picks one. Stats/abilities apply immediately. Resume.
- XP: base 100 to level 2; scale by 1.15 per level (e.g. 100, 115, 132…). XP orbs drop on enemy death; collect by walking near (pickup radius).

### Soft cap
- Leveling can continue past 25 for fun; mechanical upgrades stop at 25 so boss stays execution-focused.

---

## 8. Enemies

### Data Fields (per type)
- size, speed, health, damage, knockbackDecay, flashDuration
- isElite, isMCM (mechanic-carrying minion — teaches boss mechanics, grants massive XP)
- xpValue, rarityCharges (boosts upgrade rarity when leveling after killing MCMs)

### Enemy Types (implement as many as feasible in first iteration; expand later)

| Type        | Role              | Notes                                      | MCM  | XP   |
|------------|-------------------|--------------------------------------------|------|------|
| enemy      | Basic melee       | Chase, knockback                           | no   | 12   |
| lunger     | Charge/lunge      | Idle → charge → lunge → cooldown; teaches dodge | yes  | 60   |
| wolf       | Lunger variant    | lungeSpeed 450, charge 0.7s, lunge 0.4s     | no   | 12   |
| treent     | Elite tank        | Slow, high HP, reduced knockback            | no   | 24   |
| small_treent | Ranged (bark)   | Shoots bark; teaches projectile dodge     | yes  | 150  |
| wizard     | Roots player      | Root cone; teaches root escape              | yes  | 225  |
| druid_treent | Healer support  | Heals allies                               | yes  | 275  |
| imp        | Fast swarmer      | —                                          | no   | 10   |
| slime      | Tanky             | —                                          | no   | 20   |
| bat        | Erratic flyer     | Wobble movement                            | no   | 12   |
| skeleton   | Medium            | —                                          | no   | 15   |
| healer     | Support           | Heals allies, no direct damage             | no   | 18   |

MCMs grant ~5× XP and 2 rarity charges; killing them before level-up improves Rare/Epic odds.

---

## 9. Boss: Treent Overlord

### Overview
- **Phase 1** (100%–50% HP): Lunge + Bark Barrage
- **Phase 2** (50%–0% HP): Encompass Root + Territory Control (vine lanes, earthquake). Boss becomes more aggressive (e.g. 2 bark bursts per attack).

### Stats (example)
- Health: 3500
- Damage: 40
- Speed: 65
- Size: 48

### Phase 1
- **Lunge**: State machine idle → charging (0.6s telegraph) → lunging (0.28s travel, speed 900) → idle. Targets player position at charge start. Player must dodge.
- **Bark Barrage**: Every ~2s (when not lunging), fires 5 bark projectiles in a horizontal spread toward player. 0.06s delay between shots. Speed 220.

### Phase 2 (at 50% HP)
- Transition: Boss teleports to arena center; phase flag set.
- **Encompass Root**: Boss roots the player for 6s. **Root entities** (destructible objects) spawn; player must **shoot roots** to break free. **Auto-aim priority**: during root phase, auto-aim targets roots first so player can escape.
- **Territory Control**: Vine lanes (5 lanes, damage 9999, dodge), earthquake (telegraph then safe zones; standing in wrong zone = 9999 damage). Boss can be invulnerable during earthquake cast.
- Bark Barrage in Phase 2: 2 bursts per attack, bark speed 280.

### Design constraints
- No CC on boss (no root/stun from player abilities).
- Difficulty = execution (dodge lunge, bark, vines, earthquake), not HP grind.

---

## 10. Upgrade System (Data Model)

### Rarities
- **common**, **rare**, **epic** (weighted by roll; Luck increases Rare/Epic at Major levels).

### Effect Primitives (wire these in code)
- **stat_add** — e.g. `stat="crit_chance", value=0.05`
- **stat_mul** — e.g. `stat="primary_damage", value=1.10`
- **weapon_mod** — e.g. `mod="pierce_add", value=1`; `mod="ricochet", bounces=1, range=220`; `mod="bonus_projectiles", value=1, spread_deg=6`
- **ability_mod** — e.g. `ability="power_shot", mod="cooldown_add", value=-1.5` or `mod="damage_mul", value=1.15`
- **proc** — conditional trigger (see below); `trigger`, `chance`, `apply` (nested effect)
- **buff** — temporary player buff: `name`, `duration`, `stats`, `rules` (e.g. break_on_hit_taken, no_stack_in_frenzy)
- **status_apply** — apply to enemy: `status="bleed"|"marked"`, `stacks`, `duration`
- **chain_damage** — e.g. lightning chain: `jumps=2`, `range=180`, `damage_mul=0.35`
- **aoe_explosion** — on kill: `radius=90`, `damage_mul_of_target_maxhp=0.06`
- **aoe_projectile_burst** — e.g. 12 arrows: `count=12`, `damage_mul=0.40`

### Proc Triggers (for first iteration, implement a subset)
- `on_primary_hit`, `on_crit_hit`, `on_crit_kill`, `on_kill_target_with_status`
- `after_roll`, `every_n_primary_shots` (n=4 or 5)
- `while_enemy_within` (range), `while_target_beyond_range_pct`, `while_target_has_status`, `while_enemies_bleeding`
- `firing_continuously_for` (seconds), `no_damage_taken_for` (seconds)

### Rule (enforced by data)
- **Frenzy risk cannot be removed** — no upgrade that removes “take more damage during Frenzy”.

---

## 11. Archer Upgrades (Full List)

### Common (12)
- **Sharpened Tips** — +10% primary damage (stat_mul primary_damage 1.10)
- **Quick Nock** — +10% attack speed
- **Fleetfoot** — +8% move speed
- **Long Draw** — +12% range
- **Piercing Practice** — +1 pierce
- **Barbed Shafts** — Primary hit applies bleed: 20% of hit damage every 0.5s for 3s (proc on_primary_hit → status_apply bleed)
- **Hollow Points** — +15% crit damage
- **Hunter's Instinct** — +5% crit chance (stat_add 0.05)
- **Stamina Training** — Dash cooldown 10% faster (roll_cooldown 0.90)
- **Keen Focus** — +10% damage to enemies within 140px (proc while_enemy_within)
- **Light Quiver** — Every 5th shot +1 arrow, spread 6° (proc every_n_primary_shots n=5 → bonus_projectiles)
- **XP Magnet** — +15% XP pickup radius

### Rare (9)
- **Ricochet Arrows** — Arrows bounce to nearby enemy once (weapon_mod ricochet, range 220)
- **Split Shot** — Every 4th shot +2 arrows, spread 16°
- **Marked Prey** — Crits mark enemy; marked take +20% damage for 4s (proc on_crit_hit → status marked; proc while_target_has_status → damage mul)
- **Bleeding Frenzy** — +1% damage per bleeding enemy, cap 10%
- **Phase Roll: Focused** — After dash, next 2 shots +30% damage (buff focused_shots, no_stack_in_frenzy)
- **Precision Momentum** — Crit kill → +10% move speed 1.5s (buff momentum)
- **Battle Rhythm** — Fire 2s continuously → +15% attack speed 2.5s; breaks on dash or hit taken
- **Tactical Spacing** — +25% damage to enemies beyond 55% of range
- **Tactical Draw** — Power Shot −1.5s cooldown, −10% damage (ability_mod power_shot)

### Epic (5)
- **Chain Reaction** — Crit hits chain lightning to 2 enemies, 35% damage each
- **Arrowstorm** — Every 10th shot: 12 arrows in all directions, 40% damage each
- **Hemorrhage** — Kill bleeding enemy → explode, 6% max HP damage in radius 90
- **Ghost Quiver** — After dash, arrows pierce all for 1.25s (buff ghost_quiver, primary_only)
- **Perfect Predator** — No damage 5s → +30% attack speed, +20% crit until hit (break_on_hit_taken, disabled_during_frenzy)

---

## 12. Ability-Path Upgrades (Power Shot, Entangle, Frenzy)

### Power Shot
- Scope Line (C): +20% range
- Broadhead (C): +15% damage
- Double Tap (R): Fires twice, delay 0.08s, second shot 55% damage
- Sundering Arrow (R): Applies shattered_armor 3s, +12% damage taken
- Execution Line (E): +35% damage vs elite/MCM

### Entangle
- Wide Volley (C): +3 arrow count
- Quick Cast (C): −10% cooldown
- Thorned Volley (R): +35% damage
- Piercing Vines (R): +3 pierce
- Thorn Storm (E): +5 arrows, +15% damage, −15% cooldown

### Frenzy
- Hot Start (C): +10% charge gain
- Long Breath (C): +1s duration
- Predatory Focus (R): +8% crit chance during Frenzy
- Adrenal Step (R): +10% move speed, −15% dash cooldown during Frenzy
- Kill Fuel (E): Kill during Frenzy extends duration 0.15s, max 2s (still ends on hit)

---

## 13. Status Effects

### Enemy
- **bleed** — DoT: 20% of source hit every 0.5s; max 10 stacks; 3s default
- **marked** — Take +20% damage; 4s
- **rooted** — Cannot move; from Entangle (non-boss only)
- **shattered_armor** — +12% damage taken (from ability-path upgrade)

### Player (buffs)
- **focused_shots** — +30% primary damage; 2 charges; no stack in Frenzy; consume on primary hit
- **momentum** — +10% move speed; 1.5s
- **battle_rhythm** — +15% attack speed; breaks on roll or hit taken
- **ghost_quiver** — Primary arrows pierce all; primary only, excludes Power Shot
- **perfect_predator** — +30% attack speed, +20% crit; breaks on hit, disabled during Frenzy

---

## 14. Systems to Implement (High Level)

- **Game state** — MENU → SELECT → PLAYING → GAME_OVER; transition logic
- **Player** — Position, health, stats, abilities (Power Shot, Entangle, Dash, Frenzy), input (WASD, aim)
- **Targeting** — Nearest enemy (and during boss root phase: roots first)
- **Combat** — Primary auto-fire, auto-cast Power Shot/Entangle, manual Dash/Frenzy; collision; damage formula (base × crit × modifiers)
- **Projectiles** — Arrows (pierce, crit), bark (boss); ricochet/bonus_projectiles when wired
- **Enemies** — Per-type AI (chase, lunge, bark, root, heal); death → XP orb + rarity charge
- **XP system** — Orbs spawn on kill; collect by proximity; add XP; level-up threshold (100 × 1.15^level); pending level-ups
- **Upgrade roll** — Pick 3 cards from pool (by rarity weights; MCM kills add rarity charge); Major vs Minor level pools
- **Player stats** — Base + stat_add/stat_mul + buffs + ability_mod; get(stat), getPermanent(stat), getAbilityValue(ability, mod)
- **Rarity charge** — Track MCM kills; on level-up consume charges to boost Rare/Epic weight
- **Boss** — Treent Overlord: phase 1 (lunge + bark), phase 2 (encompass root, vine lanes, earthquake); root entities destructible by player
- **Camera** — Follow player; optional screen shake on hit
- **Audio** — Music (menu, playing, game over), SFX (shoot, hit, dash, level-up)
- **UI** — Main menu, upgrade modal (3 cards, pick one), HUD (health, abilities, Frenzy charge), Tab stats overlay (permanent stats + upgrade log)

---

## 15. Data Flow (Target Architecture)

```
Input → Player (move, aim)
     → Game loop: nearest enemy → auto-aim + auto-fire primary
                → auto-cast Power Shot / Entangle when ready
                → manual Dash (Space), Frenzy (R)
     → Collisions → damage → death → XP orb + rarity charge
     → XP collect → level-up queue → UpgradeRoll (3 cards) → player picks → PlayerStats.applyUpgrade
     → PlayerStats.get() / getAbilityValue() → drive combat and HUD
```

---

## 16. Suggested First-Iteration Scope (MVP)

- **Platform**: Web (HTML + JS or TS + Canvas). Low-res buffer, nearest-neighbor scale.
- **Player**: Movement, aim, primary auto-fire, **one** ability (e.g. Power Shot or Dash first).
- **One enemy type**: e.g. basic melee (chase, health, damage, death → XP orb).
- **XP + level-up**: Collect orbs, threshold 100 (scale 1.15). On level-up show **3 cards** from a **small pool** (e.g. 5–6 common upgrades: damage, speed, pierce, crit).
- **Stats**: Apply one upgrade (stat_add/stat_mul) and show effect in combat.
- **Game state**: MENU → PLAYING → GAME_OVER (simplified).
- **No boss, no Entangle/Frenzy, no proc engine** in v0. Add in next iterations: more abilities, more enemies, MCM + rarity, Major/Minor levels, then boss.

After MVP is playable, add: Dash, Frenzy, Power Shot/Entangle, more upgrades from §11–12, more enemy types, Treent Overlord (phase 1 then phase 2), and full upgrade/status/proc wiring.

---

*End of spec. Use this as the single source of truth for a greenfield build.*
