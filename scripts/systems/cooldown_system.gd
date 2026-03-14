extends Node

var cooldowns: Dictionary = {}

func _process(delta: float) -> void:
	tick(delta)

func set_cooldown(key: StringName, duration: float) -> void:
	cooldowns[key] = max(duration, 0.0)

func tick(delta: float) -> void:
	for key: StringName in cooldowns.keys():
		cooldowns[key] = max(float(cooldowns[key]) - delta, 0.0)

func is_ready(key: StringName) -> bool:
	return get_remaining(key) <= 0.0

func get_remaining(key: StringName) -> float:
	return float(cooldowns.get(key, 0.0))
