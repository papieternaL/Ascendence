# Ascendence Love2D → Godot 4 Migration Notes

## Scope of this pass
This pass creates a **Godot-native project skeleton only**. Gameplay systems are intentionally scaffolded with TODO markers.

## Migration plan
1. **Project bootstrap**
   - Add `project.godot` with a Godot 4 run target and base input map.
   - Set `Main.tscn` as the startup scene.
2. **Scene-first runtime layout**
   - Build reusable gameplay object scenes (`Player`, enemies, projectiles, abilities, effects).
   - Keep composition in `Main.tscn` with clear ownership buckets (`Entities`, `Projectiles`, `Effects`, `UI`, `Systems`).
   - Instance core startup scenes (`Player`, `HUD`) directly in `Main.tscn` for deterministic editor validation.
3. **Script domain split**
   - Move shared cross-cutting logic toward `scripts/systems`.
   - Keep object-specific behavior on object scripts.
4. **Resource-backed tuning**
   - Create starter config resources in `resources/configs` to replace data-table style balancing.
5. **UI isolation**
   - Host HUD in `CanvasLayer/Control` scenes with dedicated script entry points.
6. **Incremental gameplay porting (future)**
   - Port one feature vertical slice at a time (movement/combat/xp/upgrades/boss).

## Folder mapping (old → Godot)
- `assets/` → `assets/` (plus normalized subfolders `sprites/`, `audio/`, `shaders/` for Godot imports)
- `data/` → `resources/configs/` for tuning data, and `scripts/systems/` for behavior-driven data logic
- `entities/` → scene+script pairs under `scenes/player`, `scenes/enemies`, `scenes/projectiles`, `scripts/*`
- `scenes/` (Lua scene flow) → `scenes/main` plus reusable scene modules
- `shaders/` → `assets/shaders/`
- `systems/` → `scripts/systems/`
- `ui/` → `scenes/ui/` + `scripts/ui/`

## Created scene/script inventory
### Main flow
- `scenes/main/Main.tscn`
- `scenes/main/Arena.tscn`
- `scripts/main/main.gd`
- `scripts/main/arena.gd`
- `docs/godot_mcp_setup.md`

### Player
- `scenes/player/Player.tscn`
- `scripts/player/player.gd`
- `scripts/player/weapon_controller.gd`

### Enemies
- `scenes/enemies/EnemyBase.tscn`
- `scenes/enemies/DummyEnemy.tscn`
- `scenes/enemies/ChaserEnemy.tscn`
- `scripts/enemies/enemy_base.gd`
- `scripts/enemies/dummy_enemy.gd`
- `scripts/enemies/chaser_enemy.gd`

### Projectiles
- `scenes/projectiles/Bullet.tscn`
- `scenes/projectiles/Missile.tscn`
- `scenes/projectiles/SniperShot.tscn`
- `scripts/projectiles/bullet.gd`
- `scripts/projectiles/missile.gd`
- `scripts/projectiles/sniper_shot.gd`

### Abilities
- `scenes/abilities/ArcaneMissiles.tscn`
- `scenes/abilities/ArcaneSniper.tscn`
- `scripts/abilities/arcane_missiles.gd`
- `scripts/abilities/arcane_sniper.gd`

### UI
- `scenes/ui/HUD.tscn`
- `scenes/ui/CooldownBar.tscn`
- `scenes/ui/HealthBar.tscn`
- `scripts/ui/hud.gd`

### Effects
- `scenes/effects/HitEffect.tscn`
- `scenes/effects/DeathEffect.tscn`
- `scenes/effects/TrailEffect.tscn`

### Systems
- `scripts/systems/damage_system.gd`
- `scripts/systems/cooldown_system.gd`
- `scripts/systems/spawn_system.gd`
- `scripts/systems/game_events.gd`
- `scripts/systems/stat_block.gd`

### Resources
- `resources/configs/player_stats.tres`
- `resources/configs/weapon_stats.tres`
- `resources/configs/missile_stats.tres`
- `resources/configs/enemy_stats.tres`

## Scene correctness improvements (follow-up pass)
- Added concrete `Shape2D` sub-resources to player/enemy/projectile scenes to remove missing-shape warnings.
- Added a `Systems` subtree in `Main.tscn` (`DamageSystem`, `CooldownSystem`, `Spawner`) so shared services are visible and testable in scene composition.
- Bound `HUD` to instantiated `Player` in `scripts/main/main.gd` for a clean scene-level contract without full gameplay porting.
- Added `docs/godot_mcp_setup.md` with recommended scene validation flow when using `godot-mcp`.

## Phase 2 implementation (current)
- Added Arcane Pistol primary fire flow in `scripts/main/main.gd` using `primary_fire` input and cooldown-gated projectile spawning.
- Implemented Arcane Missiles cast flow wired from `ability_2` (`E`) into `scripts/abilities/arcane_missiles.gd` with multi-target missile spawning.
- Upgraded cooldown handling via `scripts/systems/cooldown_system.gd` (`_process`, `is_ready`, `get_remaining`).
- Added hit feedback via enemy sprite flash on damage and impact ring VFX (`scenes/effects/HitEffect.tscn` + `scripts/effects/hit_effect.gd`).
- Extended simple HUD to display health and Arcane Missiles readiness/countdown text plus a basic primary-fire readiness bar.

## Next migration checkpoints
- Wire main-scene systems into gameplay loops and decide final autoload surface beyond `game_events.gd`.
- Replace placeholder collision shapes/sprites with imported assets.
- Port movement + auto-fire + XP loop first, then upgrade cards, then boss flow.
