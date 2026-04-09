extends Node2D

@export var missiles_per_cast: int = 3
@export var spread_degrees: float = 12.0

func cast(source: Node2D, missile_scene: PackedScene, projectile_parent: Node, target: Node2D, forward_direction: Vector2 = Vector2.RIGHT) -> int:
	if source == null or missile_scene == null or projectile_parent == null:
		return 0

	var facing: Vector2 = forward_direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	var lateral_axis: Vector2 = facing.orthogonal().normalized()
	var spawned: int = 0
	for i in missiles_per_cast:
		var missile: Node = missile_scene.instantiate()
		if not missile is Area2D:
			continue

		var missile_area: Area2D = missile as Area2D
		var spread_index: float = float(i) - float(missiles_per_cast - 1) * 0.5
		missile_area.global_position = source.global_position + lateral_axis * spread_index * 7.0

		if target != null and is_instance_valid(target):
			missile_area.set("target", target)
			missile_area.set("direction", source.global_position.direction_to(target.global_position))
		else:
			var spread: float = deg_to_rad((float(i) - float(missiles_per_cast - 1) * 0.5) * spread_degrees)
			missile_area.set("direction", facing.rotated(spread))

		projectile_parent.add_child(missile_area)
		spawned += 1

	return spawned
