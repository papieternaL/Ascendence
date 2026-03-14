extends Area2D

@export var lifetime: float = 0.12

func _process(delta: float) -> void:
	# TODO(Migration): replace with raycast-style hit resolution and VFX sync.
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
