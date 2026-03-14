extends Node2D

@export var missiles_per_cast: int = 3
@export var spread_degrees: float = 16.0

func cast(source: Node2D, missile_scene: PackedScene, projectile_parent: Node, targets: Array[Node2D]) -> int:
	if source == null or missile_scene == null or projectile_parent == null:
		return 0

	var spawned: int = 0
	for i in missiles_per_cast:
		var missile: Node = missile_scene.instantiate()
		if not missile is Area2D:
			continue

		var missile_area: Area2D = missile as Area2D
		missile_area.global_position = source.global_position

		var target: Node2D = _pick_target(targets, i)
		if target:
			missile_area.set("target", target)
			missile_area.set("direction", source.global_position.direction_to(target.global_position))
		else:
			var spread: float = deg_to_rad((float(i) - float(missiles_per_cast - 1) * 0.5) * spread_degrees)
			missile_area.set("direction", Vector2.RIGHT.rotated(source.global_rotation + spread))

		projectile_parent.add_child(missile_area)
		spawned += 1

	return spawned

func _pick_target(targets: Array[Node2D], cast_index: int) -> Node2D:
	if targets.is_empty():
		return null
	return targets[cast_index % targets.size()]
