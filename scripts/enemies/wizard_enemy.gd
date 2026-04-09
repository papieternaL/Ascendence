extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

## Wizard - root cone attack (Love2D parity).
## Teaches root escape for boss Phase 2.

signal root_cone_fired(duration: float)

@export var target_path: NodePath
@export var cone_cooldown: float = 4.0
@export var cone_range: float = 180.0
@export var cone_angle: float = PI / 3.0
@export var root_duration: float = 1.5
@export var cast_duration: float = 1.15
@export var cone_damage: float = 120.0

var _cone_timer: float = 2.0
var _is_casting: bool = false
var _cast_timer: float = 0.0
var _cone_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_color = Color(0.55, 0.45, 0.85, 1.0)
	max_health = CombatBalance.scale(45.0)
	health = max_health
	move_speed = 45.0
	contact_damage = 0.0
	xp_reward = 50
	display_name = "Wizard"
	enemy_kind = "wizard"
	super._ready()

func _physics_process(delta: float) -> void:
	if is_rooted():
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		queue_redraw()
		return
	var target: Node2D = get_node_or_null(target_path) as Node2D
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		queue_redraw()
		return
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	if _is_casting:
		velocity = Vector2.ZERO
		_cast_timer += delta
		if _cast_timer >= cast_duration:
			_is_casting = false
			_cast_timer = 0.0
			_cone_timer = cone_cooldown
			var dir: Vector2 = to_target.normalized() if distance > 0.001 else Vector2.RIGHT
			var angle_to_target: float = dir.angle()
			var angle_diff: float = absf(angle_to_target - _cone_direction.angle())
			if angle_diff > PI:
				angle_diff = TAU - angle_diff
			if angle_diff <= cone_angle * 0.5 and distance <= cone_range:
				if target.has_method("take_damage"):
					target.call("take_damage", cone_damage)
				root_cone_fired.emit(root_duration)
		_apply_motion_with_knockback(delta)
		return
	_cone_timer -= delta
	if _cone_timer <= 0.0 and distance <= cone_range and distance > 0.001:
		_is_casting = true
		_cast_timer = 0.0
		_cone_direction = to_target.normalized()
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	var ideal_dist: float = cone_range * 0.7
	if distance > ideal_dist:
		velocity = to_target.normalized() * get_effective_move_speed()
	elif distance < cone_range * 0.4:
		velocity = -to_target.normalized() * get_effective_move_speed()
	else:
		velocity = Vector2.ZERO
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	if _is_casting:
		tint = tint.lerp(Color(0.9, 0.7, 1.0, 1.0), 0.3)
	draw_circle(Vector2(0, 6), 12.0, Color(0.05, 0.12, 0.1, 0.22))
	draw_circle(Vector2.ZERO, 12.0, tint)
	draw_circle(Vector2(0, -4), 5.0, Color(1.0, 0.95, 0.9, 0.2))
	if _is_casting:
		var cast_ratio: float = clampf(_cast_timer / max(cast_duration, 0.001), 0.0, 1.0)
		var start_angle: float = _cone_direction.angle() - cone_angle * 0.5
		var end_angle: float = _cone_direction.angle() + cone_angle * 0.5
		var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		var segments: int = 10
		for i in range(segments + 1):
			var t: float = float(i) / float(segments)
			var angle: float = lerpf(start_angle, end_angle, t)
			points.append(Vector2.RIGHT.rotated(angle) * cone_range)
		draw_colored_polygon(points, Color(0.86, 0.54, 1.0, 0.06 + cast_ratio * 0.14))
		draw_arc(Vector2.ZERO, cone_range, start_angle, end_angle, 18, Color(0.92, 0.74, 1.0, 0.36 + cast_ratio * 0.44), 3.0)
		draw_line(Vector2.ZERO, _cone_direction * cone_range * 0.9, Color(1.0, 0.86, 1.0, 0.38 + cast_ratio * 0.34), 2.4, true)
