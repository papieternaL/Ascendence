extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

@export var target_path: NodePath
@export var engage_range: float = 48.0
@export var swing_range: float = 62.0
@export var swing_angle: float = PI * 0.72
@export var swing_windup: float = 0.48
@export var swing_recovery: float = 0.72
@export var swing_damage: float = 180.0

var _target: Node2D
var _state: String = "approach"
var _state_timer: float = 0.0
var _swing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	max_health = CombatBalance.scale(42.0)
	health = max_health
	move_speed = 86.0
	contact_damage = 0.0
	xp_reward = 24
	rarity_charge_reward = 1
	display_name = "Skeleton"
	enemy_kind = "skeleton"
	body_color = Color(0.8, 0.82, 0.76, 1.0)
	super._ready()

func _physics_process(delta: float) -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null or is_rooted():
		_state = "approach"
		_state_timer = 0.0
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if distance > 0.001:
		_swing_direction = to_target.normalized()
	match _state:
		"approach":
			if distance <= engage_range:
				_state = "windup"
				_state_timer = 0.0
				velocity = Vector2.ZERO
			else:
				velocity = _swing_direction * get_effective_move_speed()
		"windup":
			velocity = Vector2.ZERO
			_state_timer += delta
			if _state_timer >= swing_windup:
				_perform_swing_hit()
				_state = "recovery"
				_state_timer = 0.0
		"recovery":
			velocity = Vector2.ZERO
			_state_timer += delta
			if _state_timer >= swing_recovery:
				_state = "approach"
				_state_timer = 0.0
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _perform_swing_hit() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if distance > swing_range or distance <= 0.001:
		return
	var angle_diff: float = absf(wrapf(to_target.angle() - _swing_direction.angle(), -PI, PI))
	if angle_diff <= swing_angle * 0.5 and _target.has_method("take_damage"):
		_target.call("take_damage", swing_damage)

func _draw() -> void:
	super._draw()
	draw_circle(Vector2(-4.0, -2.0), 1.8, Color(0.16, 0.1, 0.08, 0.9))
	draw_circle(Vector2(4.0, -2.0), 1.8, Color(0.16, 0.1, 0.08, 0.9))
	draw_line(Vector2(-4.0, 5.0), Vector2(4.0, 5.0), Color(0.18, 0.1, 0.08, 0.7), 1.5, true)
	var facing_angle: float = _swing_direction.angle()
	var sword_points: PackedVector2Array = PackedVector2Array([
		Vector2.ZERO,
		Vector2.RIGHT.rotated(facing_angle - 0.12) * 20.0,
		Vector2.RIGHT.rotated(facing_angle + 0.12) * 20.0,
	])
	draw_colored_polygon(sword_points, Color(0.68, 0.66, 0.62, 0.9))
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(facing_angle) * 26.0, Color(0.86, 0.82, 0.74, 0.95), 3.0, true)
	if _state == "windup" or _state == "recovery":
		var arc_start: float = facing_angle - swing_angle * 0.5
		var arc_end: float = facing_angle + swing_angle * 0.5
		var telegraph_color: Color = Color(1.0, 0.72, 0.46, 0.14)
		var outline_color: Color = Color(1.0, 0.76, 0.5, 0.58)
		if _state == "recovery":
			telegraph_color = Color(1.0, 0.86, 0.66, 0.18)
			outline_color = Color(1.0, 0.92, 0.72, 0.74)
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		var segments: int = 10
		for i in range(segments + 1):
			var t: float = float(i) / float(segments)
			var angle: float = lerpf(arc_start, arc_end, t)
			wedge.append(Vector2.RIGHT.rotated(angle) * swing_range)
		draw_colored_polygon(wedge, telegraph_color)
		draw_arc(Vector2.ZERO, swing_range, arc_start, arc_end, 20, outline_color, 3.0)
		if _state == "recovery":
			draw_arc(Vector2.ZERO, swing_range + 8.0, arc_start, arc_end, 18, Color(1.0, 0.96, 0.84, 0.42), 2.0)
