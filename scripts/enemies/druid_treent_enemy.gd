extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

signal root_cone_fired(duration: float)

@export var target_path: NodePath
@export var cone_cooldown: float = 4.6
@export var cone_range: float = 210.0
@export var cone_angle: float = PI / 2.8
@export var cast_duration: float = 1.0
@export var cone_damage: float = 140.0
@export var root_duration: float = 1.0

var _target: Node2D
var _cone_timer: float = 2.2
var _is_casting: bool = false
var _cast_timer: float = 0.0
var _cone_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	max_health = CombatBalance.scale(72.0)
	health = max_health
	move_speed = 56.0
	contact_damage = 0.0
	xp_reward = 45
	rarity_charge_reward = 2
	display_name = "Druid Treent"
	enemy_kind = "druid_treent"
	body_color = Color(0.34, 0.64, 0.34, 1.0)
	super._ready()

func _physics_process(delta: float) -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null or is_rooted():
		_is_casting = false
		_cast_timer = 0.0
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if _is_casting:
		velocity = Vector2.ZERO
		_cast_timer += delta
		if _cast_timer >= cast_duration:
			_is_casting = false
			_cast_timer = 0.0
			_cone_timer = cone_cooldown
			_fire_cone_attack(distance)
		_apply_motion_with_knockback(delta)
		queue_redraw()
		return
	_cone_timer -= delta
	if _cone_timer <= 0.0 and distance <= cone_range and distance > 0.001:
		_is_casting = true
		_cast_timer = 0.0
		_cone_direction = to_target.normalized()
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		queue_redraw()
		return
	var desired: Vector2 = to_target.normalized() if distance > 0.001 else Vector2.ZERO
	if distance > cone_range * 0.82:
		velocity = desired * get_effective_move_speed()
	elif distance < cone_range * 0.5:
		velocity = -desired * get_effective_move_speed()
	else:
		velocity = Vector2.ZERO
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _fire_cone_attack(distance_to_target: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if distance_to_target > cone_range:
		return
	var current_direction: Vector2 = (_target.global_position - global_position).normalized()
	if current_direction.length_squared() <= 0.0001:
		current_direction = _cone_direction
	var angle_diff: float = absf(current_direction.angle_to(_cone_direction))
	if angle_diff <= cone_angle * 0.5 and _target.has_method("take_damage"):
		_target.call("take_damage", cone_damage)
		root_cone_fired.emit(root_duration)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	if _is_casting:
		tint = tint.lerp(Color(0.72, 0.94, 0.68, 1.0), 0.34)
	draw_circle(Vector2(0, 7), 13.0, Color(0.05, 0.11, 0.08, 0.22))
	draw_circle(Vector2.ZERO, 13.0, tint)
	draw_circle(Vector2(0, -7), 7.0, Color(0.28, 0.48, 0.2, 0.95))
	draw_circle(Vector2(-6, -2), 2.2, Color(0.92, 0.96, 0.78, 0.62))
	draw_circle(Vector2(6, -2), 2.2, Color(0.92, 0.96, 0.78, 0.62))
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
		draw_colored_polygon(points, Color(0.56, 0.9, 0.46, 0.06 + cast_ratio * 0.16))
		draw_arc(Vector2.ZERO, cone_range, start_angle, end_angle, 18, Color(0.72, 1.0, 0.68, 0.36 + cast_ratio * 0.42), 3.0)
		draw_line(Vector2.ZERO, _cone_direction * cone_range * 0.88, Color(0.88, 1.0, 0.8, 0.36 + cast_ratio * 0.32), 2.6, true)
