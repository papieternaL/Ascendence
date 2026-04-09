extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

@export var target_path: NodePath
@export var lunge_range: float = 340.0
@export var lunge_charge_duration: float = 0.8
@export var lunge_duration: float = 0.45
@export var lunge_cooldown: float = 1.5
@export var lunge_speed: float = 500.0

var _state: String = "idle"
var _state_timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_color = Color(0.82, 0.42, 0.84, 1.0)
	max_health = CombatBalance.scale(40.0)
	health = max_health
	move_speed = 30.0
	contact_damage = CombatBalance.scale(15.0)
	xp_reward = 26
	display_name = "Lunger"
	enemy_kind = "enemy"
	super._ready()

func _physics_process(delta: float) -> void:
	if is_rooted():
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	var target: Node2D = get_node_or_null(target_path) as Node2D
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	match _state:
		"idle":
			velocity = to_target.normalized() * get_effective_move_speed() if distance > 0.001 else Vector2.ZERO
			if distance <= lunge_range:
				_state = "charging"
				_state_timer = 0.0
				_lunge_direction = to_target.normalized() if distance > 0.001 else Vector2.RIGHT
		"charging":
			velocity = Vector2.ZERO
			_state_timer += delta
			if distance > 0.001:
				_lunge_direction = to_target.normalized()
			if _state_timer >= lunge_charge_duration:
				_state = "lunging"
				_state_timer = 0.0
		"lunging":
			velocity = _lunge_direction * lunge_speed
			_state_timer += delta
			if _state_timer >= lunge_duration:
				_state = "cooldown"
				_state_timer = 0.0
		"cooldown":
			velocity = Vector2.ZERO
			_state_timer += delta
			if _state_timer >= lunge_cooldown:
				_state = "idle"
				_state_timer = 0.0
	_apply_motion_with_knockback(delta)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	if _state == "charging":
		tint = tint.lerp(Color(1.0, 0.58, 0.42, 1.0), 0.4)
	elif _state == "lunging":
		tint = tint.lerp(Color(1.0, 0.24, 0.24, 1.0), 0.55)
	draw_circle(Vector2(0, 6), 13.0, Color(0.05, 0.12, 0.1, 0.22))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -14),
			Vector2(14, 0),
			Vector2(0, 14),
			Vector2(-14, 0),
		]),
		tint
	)
	if _state == "charging":
		var telegraph_dir: Vector2 = _lunge_direction.normalized()
		if telegraph_dir.length_squared() <= 0.0001:
			telegraph_dir = Vector2.RIGHT
		var tip: Vector2 = telegraph_dir * 38.0
		var wing_a: Vector2 = tip + telegraph_dir.rotated(2.55) * 12.0
		var wing_b: Vector2 = tip + telegraph_dir.rotated(-2.55) * 12.0
		draw_line(Vector2.ZERO, tip, Color(1.0, 0.84, 0.58, 0.94), 3.4, true)
		draw_line(tip, wing_a, Color(1.0, 0.7, 0.46, 0.94), 2.4, true)
		draw_line(tip, wing_b, Color(1.0, 0.7, 0.46, 0.94), 2.4, true)
		draw_arc(Vector2.ZERO, 22.0, telegraph_dir.angle() - 0.45, telegraph_dir.angle() + 0.45, 18, Color(1.0, 0.5, 0.36, 0.66), 2.0)
