extends EnemyBase

@export var target_path: NodePath

func _physics_process(_delta: float) -> void:
	# TODO(Migration): replace with Godot navigation-aware chase and obstacle handling.
	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		velocity = Vector2.ZERO
	else:
		velocity = global_position.direction_to(target.global_position) * move_speed
	move_and_slide()
