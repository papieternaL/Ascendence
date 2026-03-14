# Godot MCP Usage Notes (Scene Validation Workflow)

This repo now has a Godot scene skeleton intended to be validated in-editor.

## Recommended `godot-mcp` workflow
1. Install and connect `godot-mcp` in your MCP-enabled client.
2. Open the project root (`/workspace/Ascendence`) in Godot 4.
3. Validate key scenes in order:
   - `res://scenes/main/Main.tscn`
   - `res://scenes/player/Player.tscn`
   - `res://scenes/enemies/EnemyBase.tscn`
   - `res://scenes/projectiles/Bullet.tscn`
   - `res://scenes/ui/HUD.tscn`
4. Confirm there are no missing scripts/resources and no inspector warnings for missing collision shapes.

## What this pass fixed for scene correctness
- Added explicit collision `Shape2D` sub-resources to player, enemy, and projectile scenes.
- Added a systems container in `Main.tscn` so shared runtime services are visible in scene-tree composition.
- Instanced `Player` and `HUD` directly in `Main.tscn` to make startup structure deterministic.

## Next checks (in Godot editor)
- Replace placeholder `Sprite2D` nodes with imported textures/animations.
- Decide whether `GameEvents` should be autoload singleton (current) or additionally mirrored scene-node access.
- If using physics layers differently, adjust the scaffold masks/layers before gameplay porting.
