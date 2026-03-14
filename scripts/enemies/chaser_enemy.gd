extends EnemyBase

@export var target_path: NodePath
@export var desired_distance: float = 36.0

func _ready() -> void:
	body_color = Color(0.84, 0.46, 0.85, 1.0)
	contact_damage = 10.0
	xp_reward = 22
	super._ready()

func _physics_process(_delta: float) -> void:
	var target: Node2D = get_node_or_null(target_path) as Node2D
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		velocity = Vector2.ZERO
	else:
		var to_target: Vector2 = target.global_position - global_position
		if to_target.length() > desired_distance:
			velocity = to_target.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()
