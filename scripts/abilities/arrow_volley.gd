extends Node2D

@export var cooldown: float = 7.2
@export var arrows_per_cast: int = 3
@export var spread_degrees: float = 5.0
@export var cast_range: float = 350.0
@export var projectile_speed: float = 620.0
@export var damage_multiplier: float = 1.2
@export var pierce_count: int = 0

func cast(source: Node2D, projectile_scene: PackedScene, projectile_parent: Node, targets: Array[Node2D], base_damage: float, crit_chance: float, crit_multiplier: float, bonus_arrows: int = 0) -> Array[Area2D]:
	if source == null or projectile_scene == null or projectile_parent == null or targets.is_empty():
		return []
	var valid_targets: Array[Node2D] = get_targets_in_range(source, targets)
	if valid_targets.is_empty():
		return []
	return cast_in_direction(
		source,
		projectile_scene,
		projectile_parent,
		_get_base_direction(source, valid_targets),
		base_damage,
		crit_chance,
		crit_multiplier,
		bonus_arrows
	)

func cast_in_direction(source: Node2D, projectile_scene: PackedScene, projectile_parent: Node, base_direction: Vector2, base_damage: float, crit_chance: float, crit_multiplier: float, bonus_arrows: int = 0) -> Array[Area2D]:
	if source == null or projectile_scene == null or projectile_parent == null:
		return []

	var spawned: Array[Area2D] = []
	var count: int = max(1, arrows_per_cast + bonus_arrows)
	if base_direction.length_squared() <= 0.0001:
		base_direction = Vector2.RIGHT
	base_direction = base_direction.normalized()
	for i in range(count):
		var shot: Area2D = projectile_scene.instantiate() as Area2D
		if shot == null:
			continue
		shot.global_position = source.global_position
		var offset_index: float = float(i) - float(count - 1) * 0.5
		var direction: Vector2 = base_direction.rotated(deg_to_rad(offset_index * spread_degrees))
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

func get_directional_targets(source: Node2D, targets: Array[Node2D], direction: Vector2) -> Array[Node2D]:
	var valid_targets: Array[Node2D] = get_targets_in_range(source, targets)
	if valid_targets.is_empty():
		return []
	var facing: Vector2 = direction.normalized()
	if facing.length_squared() <= 0.0001:
		return valid_targets
	valid_targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var a_score: float = facing.dot(source.global_position.direction_to(a.global_position))
		var b_score: float = facing.dot(source.global_position.direction_to(b.global_position))
		if absf(a_score - b_score) <= 0.0001:
			return source.global_position.distance_squared_to(a.global_position) < source.global_position.distance_squared_to(b.global_position)
		return a_score > b_score
	)
	return valid_targets

func get_targets_in_range(source: Node2D, targets: Array[Node2D]) -> Array[Node2D]:
	if source == null or targets.is_empty():
		return []
	var valid_targets: Array[Node2D] = []
	var max_distance_squared: float = cast_range * cast_range
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		if source.global_position.distance_squared_to(target.global_position) > max_distance_squared:
			continue
		valid_targets.append(target)
	return valid_targets

func _get_pack_center(targets: Array[Node2D]) -> Vector2:
	if targets.is_empty():
		return Vector2.ZERO
	var center: Vector2 = Vector2.ZERO
	var count: int = 0
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		center += target.global_position
		count += 1
	if count <= 0:
		return Vector2.ZERO
	return center / float(count)

func _get_base_direction(source: Node2D, valid_targets: Array[Node2D]) -> Vector2:
	var pack_center: Vector2 = _get_pack_center(valid_targets)
	var base_direction: Vector2 = source.global_position.direction_to(pack_center)
	if base_direction.length_squared() <= 0.0001:
		var primary_target: Node2D = valid_targets[0]
		base_direction = source.global_position.direction_to(primary_target.global_position)
	return base_direction
