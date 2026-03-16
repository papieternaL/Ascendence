extends Node2D

@export var cooldown: float = 7.2
@export var arrows_per_cast: int = 5
@export var spread_degrees: float = 14.0
@export var projectile_speed: float = 620.0
@export var damage_multiplier: float = 1.2
@export var pierce_count: int = 0

func cast(source: Node2D, projectile_scene: PackedScene, projectile_parent: Node, targets: Array[Node2D], base_damage: float, crit_chance: float, crit_multiplier: float, bonus_arrows: int = 0) -> Array[Area2D]:
	if source == null or projectile_scene == null or projectile_parent == null or targets.is_empty():
		return []

	var spawned: Array[Area2D] = []
	var count: int = max(1, arrows_per_cast + bonus_arrows)
	var primary_target: Node2D = targets[0]
	var base_direction: Vector2 = source.global_position.direction_to(primary_target.global_position)
	if base_direction.length_squared() <= 0.0001:
		base_direction = Vector2.RIGHT
	for i in range(count):
		var shot: Area2D = projectile_scene.instantiate() as Area2D
		if shot == null:
			continue
		shot.global_position = source.global_position
		var offset_index: float = float(i) - float(count - 1) * 0.5
		var direction: Vector2 = base_direction.rotated(deg_to_rad(offset_index * spread_degrees))
		var target: Node2D = _pick_target(targets, i)
		if target != null:
			direction = source.global_position.direction_to(target.global_position).normalized().slerp(direction, 0.3)
		if direction.length_squared() <= 0.0001:
			direction = Vector2.RIGHT
		shot.set("direction", direction.normalized())
		shot.set("damage", base_damage * damage_multiplier)
		shot.set("speed", projectile_speed)
		shot.set("pierce_count", pierce_count)
		shot.set("crit_chance", crit_chance)
		shot.set("crit_multiplier", crit_multiplier)
		shot.set("visual_style", "arrow_volley")
		projectile_parent.add_child(shot)
		spawned.append(shot)
	return spawned

func _pick_target(targets: Array[Node2D], cast_index: int) -> Node2D:
	if targets.is_empty():
		return null
	return targets[min(cast_index, targets.size() - 1)]
