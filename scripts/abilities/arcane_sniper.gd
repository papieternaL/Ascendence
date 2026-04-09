extends Node2D

@export var duration: float = 7.0
@export var cooldown: float = 18.0

var active_remaining: float = 0.0

func tick(delta: float) -> void:
	active_remaining = max(active_remaining - delta, 0.0)

func activate(cooldown_system: Node, cooldown_key: StringName) -> bool:
	if cooldown_system == null:
		return false
	if not cooldown_system.is_ready(cooldown_key):
		return false
	active_remaining = duration
	cooldown_system.set_cooldown(cooldown_key, cooldown)
	return true

func is_active() -> bool:
	return active_remaining > 0.0

func get_remaining() -> float:
	return active_remaining
