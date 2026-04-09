extends Node2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

@export var cooldown: float = 8.0
@export var radius: float = 84.0
@export var base_damage: float = 25.0
@export var damage_multiplier: float = 1.5
@export var root_duration: float = 1.6
@export var arrow_count: int = 6

func cast(target_point: Vector2, enemies: Array[Node2D], primary_damage: float) -> Array[Vector2]:
	var hits: Array[Vector2] = []
	var payload: Dictionary = {
		"amount": max(base_damage, primary_damage * damage_multiplier),
		"is_crit": false,
	}
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(target_point) > radius * radius:
			continue
		if DAMAGE_SYSTEM.apply_hit(enemy, payload).is_empty():
			continue
		hits.append(enemy.global_position)
		if not enemy.is_in_group("boss") and enemy.has_method("apply_root"):
			enemy.apply_root(root_duration)
	return hits
