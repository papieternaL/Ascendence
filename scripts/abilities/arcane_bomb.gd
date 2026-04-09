extends Node2D

@export var throw_distance: float = 220.0
@export var travel_duration: float = 0.34
@export var zone_radius: float = 78.0
@export var zone_duration: float = 3.4
@export var tick_interval: float = 0.45
@export var tick_damage: float = 18.0
@export var slow_mul: float = 1.18
@export var slow_duration: float = 0.7

func cast_in_direction(source: Node2D, projectile_scene: PackedScene, effects_parent: Node, direction: Vector2) -> Node2D:
	if source == null or projectile_scene == null or effects_parent == null:
		return null
	var facing: Vector2 = direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	var projectile: Node2D = projectile_scene.instantiate() as Node2D
	if projectile == null:
		return null
	if projectile.has_method("setup"):
		projectile.call("setup", {
			"start_position": source.global_position,
			"target_position": source.global_position + facing * throw_distance,
			"travel_duration": travel_duration,
			"zone_radius": zone_radius,
			"zone_duration": zone_duration,
			"tick_interval": tick_interval,
			"tick_damage": tick_damage,
			"slow_mul": slow_mul,
			"slow_duration": slow_duration,
		})
	effects_parent.add_child(projectile)
	return projectile
