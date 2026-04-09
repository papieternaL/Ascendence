extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

signal bark_shot(origin: Vector2, target: Vector2, speed: float, damage: float)

@export var target_path: NodePath
@export var preferred_range: float = 260.0
@export var lunge_range: float = 260.0
@export var lunge_charge_duration: float = 0.6
@export var lunge_duration: float = 0.4
@export var lunge_cooldown: float = 1.3
@export var lunge_speed: float = 560.0
@export var lunge_hit_radius: float = 38.0
@export var lunge_damage: float = 240.0
@export var projectile_windup: float = 0.55
@export var projectile_speed: float = 320.0
@export var projectile_damage: float = 120.0
@export var projectile_range: float = 340.0
@export var projectile_cooldown: float = 2.2

var _state: String = "idle"
var _state_timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.RIGHT
var _aim_direction: Vector2 = Vector2.RIGHT
var _lunge_hit_applied: bool = false
var _lunge_cooldown_remaining: float = 0.0
var _projectile_cooldown_remaining: float = 0.0

func _ready() -> void:
	body_color = Color(0.76, 0.3, 0.22, 1.0)
	max_health = CombatBalance.scale(420.0)
	health = max_health
	move_speed = 208.0
	contact_damage = 0.0
	xp_reward = 0
	rarity_charge_reward = 3
	boss_progress_reward = 8.0
	show_health_bar_always = true
	show_nameplate = true
	health_bar_scale = Vector2(1.8, 1.1)
	health_bar_tint = Color(1.0, 0.78, 0.34, 1.0)
	nameplate_tint = Color(1.0, 0.94, 0.82, 1.0)
	display_name = "Deepwood Stalker"
	enemy_kind = "deepwood_stalker"
	super._ready()
	add_to_group("elite")

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
	if distance > 0.001:
		_aim_direction = to_target.normalized()
	_lunge_cooldown_remaining = max(_lunge_cooldown_remaining - delta, 0.0)
	_projectile_cooldown_remaining = max(_projectile_cooldown_remaining - delta, 0.0)

	match _state:
		"idle":
			_update_idle_behavior(distance, target, to_target)
		"charge_lunge":
			velocity = Vector2.ZERO
			_state_timer += delta
			if distance > 0.001:
				_lunge_direction = to_target.normalized()
			if _state_timer >= lunge_charge_duration:
				_state = "lunging"
				_state_timer = 0.0
				_lunge_hit_applied = false
				_lunge_cooldown_remaining = lunge_cooldown
		"lunging":
			velocity = _lunge_direction * lunge_speed
			_state_timer += delta
			if not _lunge_hit_applied and distance <= lunge_hit_radius and target.has_method("take_damage"):
				target.call("take_damage", lunge_damage)
				_lunge_hit_applied = true
			if _state_timer >= lunge_duration:
				_state = "idle"
				_state_timer = 0.0
		"charge_shot":
			velocity = Vector2.ZERO
			_state_timer += delta
			if distance > 0.001:
				_aim_direction = to_target.normalized()
			if distance > projectile_range:
				_state = "idle"
				_state_timer = 0.0
				_apply_motion_with_knockback(delta)
				queue_redraw()
				return
			if _state_timer >= projectile_windup:
				bark_shot.emit(global_position, target.global_position, projectile_speed, projectile_damage)
				_projectile_cooldown_remaining = projectile_cooldown
				_state = "idle"
				_state_timer = 0.0
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _update_idle_behavior(distance: float, target: Node2D, to_target: Vector2) -> void:
	if distance <= lunge_range and _lunge_cooldown_remaining <= 0.0:
		_state = "charge_lunge"
		_state_timer = 0.0
		_lunge_direction = to_target.normalized() if distance > 0.001 else Vector2.RIGHT
		velocity = Vector2.ZERO
		return
	if distance >= preferred_range * 0.72 and distance <= projectile_range and _projectile_cooldown_remaining <= 0.0:
		_state = "charge_shot"
		_state_timer = 0.0
		velocity = Vector2.ZERO
		return
	if distance > preferred_range:
		velocity = to_target.normalized() * get_effective_move_speed()
	elif distance < preferred_range * 0.58:
		var retreat_dir: Vector2 = global_position.direction_to(target.global_position)
		velocity = -retreat_dir * get_effective_move_speed() * 0.6
	else:
		velocity = Vector2.ZERO

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.96, 0.92, 1.0), flash_mix)
	if _state == "charge_lunge":
		tint = tint.lerp(Color(1.0, 0.54, 0.42, 1.0), 0.42)
	elif _state == "lunging":
		tint = tint.lerp(Color(1.0, 0.42, 0.3, 1.0), 0.58)
	elif _state == "charge_shot":
		tint = tint.lerp(Color(0.96, 0.72, 0.48, 1.0), 0.28)
	draw_circle(Vector2(0, 8), 15.0, Color(0.05, 0.08, 0.06, 0.24))
	draw_circle(Vector2.ZERO, 15.0, tint)
	draw_circle(Vector2(0.0, -8.0), 7.0, Color(0.52, 0.18, 0.14, 0.94))
	draw_circle(Vector2(11.0, -1.0), 3.2, Color(1.0, 0.88, 0.64, 0.96))
	if _state == "charge_lunge":
		var telegraph_dir: Vector2 = _lunge_direction.normalized()
		if telegraph_dir.length_squared() <= 0.0001:
			telegraph_dir = Vector2.RIGHT
		var start_angle: float = telegraph_dir.angle() - 0.3
		var end_angle: float = telegraph_dir.angle() + 0.3
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for i in range(9):
			var t: float = float(i) / 8.0
			var angle: float = lerpf(start_angle, end_angle, t)
			wedge.append(Vector2.RIGHT.rotated(angle) * 60.0)
		draw_colored_polygon(wedge, Color(1.0, 0.54, 0.38, 0.14))
		draw_arc(Vector2.ZERO, 28.0, telegraph_dir.angle() - 0.4, telegraph_dir.angle() + 0.4, 18, Color(1.0, 0.74, 0.46, 0.8), 2.4)
		draw_line(Vector2.ZERO, telegraph_dir * 38.0, Color(1.0, 0.84, 0.58, 0.9), 3.2, true)
	elif _state == "charge_shot":
		var bark_ratio: float = clampf(_state_timer / max(projectile_windup, 0.001), 0.0, 1.0)
		var aim_tip: Vector2 = _aim_direction * 38.0
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(0.94, 0.72, 0.42, 0.22 + bark_ratio * 0.38), 2.6)
		draw_line(Vector2.ZERO, aim_tip, Color(1.0, 0.82, 0.5, 0.24 + bark_ratio * 0.62), 3.6, true)
		draw_circle(aim_tip, 6.0 + bark_ratio * 3.0, Color(0.86, 0.6, 0.26, 0.16 + bark_ratio * 0.3))
