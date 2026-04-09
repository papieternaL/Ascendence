extends Node2D

@export var cooldown: float = 6.0
@export var damage_multiplier: float = 3.0
@export var projectile_speed: float = 760.0
@export var projectile_lifetime: float = 0.7
@export var pierce_count: int = 99

func cast(source: Node2D, projectile_scene: PackedScene, projectile_parent: Node, target: Node2D, base_damage: float, crit_multiplier: float) -> Area2D:
	if source == null or projectile_scene == null or projectile_parent == null or target == null:
		return null
	return cast_in_direction(
		source,
		projectile_scene,
		projectile_parent,
		source.global_position.direction_to(target.global_position),
		base_damage,
		crit_multiplier
	)

func cast_in_direction(source: Node2D, projectile_scene: PackedScene, projectile_parent: Node, direction: Vector2, base_damage: float, crit_multiplier: float) -> Area2D:
	if source == null or projectile_scene == null or projectile_parent == null:
		return null
	var shot: Area2D = projectile_scene.instantiate() as Area2D
	if shot == null:
		return null
	shot.global_position = source.global_position
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	shot.set("direction", direction)
	shot.set("damage", base_damage * damage_multiplier)
	shot.set("speed", projectile_speed)
	shot.set("lifetime", projectile_lifetime)
	shot.set("pierce_count", pierce_count)
	shot.set("crit_chance", 1.0)
	shot.set("crit_multiplier", crit_multiplier)
	projectile_parent.add_child(shot)
	return shot
