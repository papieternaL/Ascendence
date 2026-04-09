extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

## Wolf - lunging charger (Love2D parity).
## Gray/white, different stats from Lunger.

@export var target_path: NodePath
@export var lunge_range: float = 240.0
@export var lunge_charge_duration: float = 0.65
@export var lunge_duration: float = 0.4
@export var lunge_cooldown: float = 1.05
@export var lunge_speed: float = 520.0
@export var lunge_hit_radius: float = 34.0
@export var lunge_damage: float = 160.0

var _state: String = "idle"
var _state_timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.RIGHT
var _lunge_hit_applied: bool = false

func _ready() -> void:
	body_color = Color(0.7, 0.7, 0.8, 1.0)
	max_health = CombatBalance.scale(40.0)
	health = max_health
	move_speed = 188.0
	contact_damage = 0.0
	xp_reward = 40
	display_name = "Wolf"
	enemy_kind = "wolf"
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
				_lunge_hit_applied = false
		"lunging":
			velocity = _lunge_direction * lunge_speed
			_state_timer += delta
			if not _lunge_hit_applied and distance <= lunge_hit_radius and target.has_method("take_damage"):
				target.call("take_damage", lunge_damage)
				_lunge_hit_applied = true
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
	queue_redraw()

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	if _state == "charging":
		tint = tint.lerp(Color(1.0, 0.5, 0.45, 1.0), 0.4)
	elif _state == "lunging":
		tint = tint.lerp(Color(1.0, 0.35, 0.35, 1.0), 0.55)
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
		var start_angle: float = telegraph_dir.angle() - 0.34
		var end_angle: float = telegraph_dir.angle() + 0.34
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for i in range(9):
			var t: float = float(i) / 8.0
			var angle: float = lerpf(start_angle, end_angle, t)
			wedge.append(Vector2.RIGHT.rotated(angle) * 46.0)
		draw_colored_polygon(wedge, Color(1.0, 0.46, 0.28, 0.14))
		var tip: Vector2 = telegraph_dir * 34.0
		var wing_a: Vector2 = tip + telegraph_dir.rotated(2.6) * 10.0
		var wing_b: Vector2 = tip + telegraph_dir.rotated(-2.6) * 10.0
		draw_line(Vector2.ZERO, tip, Color(1.0, 0.8, 0.54, 0.92), 3.0, true)
		draw_line(tip, wing_a, Color(1.0, 0.7, 0.46, 0.92), 2.0, true)
		draw_line(tip, wing_b, Color(1.0, 0.7, 0.46, 0.92), 2.0, true)
		draw_arc(Vector2.ZERO, 20.0, telegraph_dir.angle() - 0.42, telegraph_dir.angle() + 0.42, 18, Color(1.0, 0.55, 0.42, 0.62), 2.0)
