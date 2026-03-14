extends Node

var cooldowns: Dictionary = {}

func set_cooldown(key: StringName, duration: float) -> void:
	cooldowns[key] = duration

func tick(delta: float) -> void:
	for key: StringName in cooldowns.keys():
		cooldowns[key] = max(cooldowns[key] - delta, 0.0)
