extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

## Bat - erratic flyer with wobble (Love2D parity).

@export var target_path: NodePath
@export var desired_distance: float = 36.0
@export var wobble_speed: float = 4.0
@export var wobble_radius: float = 30.0

var _wobble_angle: float = 0.0

func _ready() -> void:
	body_color = Color(0.6, 0.58, 0.72, 1.0)
	max_health = CombatBalance.scale(30.0)
	health = max_health
	move_speed = 70.0
	contact_damage = CombatBalance.scale(8.0)
	xp_reward = 12
	display_name = "Bat"
	enemy_kind = "enemy"
	_wobble_angle = randf() * TAU
	super._ready()

func _physics_process(delta: float) -> void:
	if is_rooted():
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	_wobble_angle += delta * wobble_speed
	var target: Node2D = get_node_or_null(target_path) as Node2D
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		velocity = Vector2.ZERO
	else:
		var to_target: Vector2 = target.global_position - global_position
		var base_dir: Vector2 = to_target.normalized() if to_target.length() > 0.001 else Vector2.RIGHT
		var wobble_offset: Vector2 = Vector2(cos(_wobble_angle), sin(_wobble_angle * 1.3)) * wobble_radius * 0.015
		var move_dir: Vector2 = (base_dir + wobble_offset).normalized()
		if to_target.length() > desired_distance:
			velocity = move_dir * get_effective_move_speed()
		else:
			velocity = Vector2.ZERO
	_apply_motion_with_knockback(delta)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	draw_circle(Vector2(0, 6), 11.0, Color(0.05, 0.12, 0.1, 0.22))
	draw_circle(Vector2.ZERO, 11.0, tint)
	draw_circle(Vector2(-6, -2), 4.0, Color(tint.r * 0.85, tint.g * 0.85, tint.b * 0.85, tint.a))
	draw_circle(Vector2(6, -2), 4.0, Color(tint.r * 0.85, tint.g * 0.85, tint.b * 0.85, tint.a))
