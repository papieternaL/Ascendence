extends EnemyBase

func _physics_process(_delta: float) -> void:
	# TODO(Migration): training target behavior.
	velocity = Vector2.ZERO
	move_and_slide()
