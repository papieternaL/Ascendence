extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

## Slime - slow, tanky (Love2D parity).

@export var target_path: NodePath
@export var desired_distance: float = 36.0

func _ready() -> void:
	body_color = Color(0.35, 0.72, 0.48, 1.0)
	max_health = CombatBalance.scale(80.0)
	health = max_health
	move_speed = 30.0
	contact_damage = CombatBalance.scale(12.0)
	xp_reward = 20
	display_name = "Slime"
	enemy_kind = "enemy"
	super._ready()

func _physics_process(_delta: float) -> void:
	if is_rooted():
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(_delta)
		return
	var target: Node2D = get_node_or_null(target_path) as Node2D
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		velocity = Vector2.ZERO
	else:
		var to_target: Vector2 = target.global_position - global_position
		if to_target.length() > desired_distance:
			velocity = to_target.normalized() * get_effective_move_speed()
		else:
			velocity = Vector2.ZERO
	_apply_motion_with_knockback(_delta)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	draw_circle(Vector2(0, 8), 16.0, Color(0.05, 0.12, 0.1, 0.22))
	draw_circle(Vector2.ZERO, 14.0, tint)
	draw_circle(Vector2(0, -4), 5.0, Color(1.0, 1.0, 1.0, 0.15))
