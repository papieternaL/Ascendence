extends Node

@export var fire_cooldown: float = 0.2
var _cooldown_remaining: float = 0.0

func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = max(_cooldown_remaining - delta, 0.0)

func can_fire() -> bool:
	return _cooldown_remaining <= 0.0

func trigger_fire() -> void:
	# TODO(Migration): instantiate projectile scenes and apply stats from resources.
	_cooldown_remaining = fire_cooldown
