extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

signal bark_shot(origin: Vector2, target: Vector2, speed: float, damage: float)
signal encompass_root(duration: float)
signal territory_started()
signal territory_ended()

@export var target_path: NodePath
@export var config: BossConfig
@export var lunge_cooldown: float = 3.2
@export var lunge_charge_duration: float = 0.55
@export var lunge_duration: float = 0.38
@export var lunge_speed: float = 460.0
@export var lunge_damage: float = 240.0
@export var lunge_hit_radius: float = 46.0
@export var bark_cooldown: float = 2.8
@export var bark_shots_per_burst: int = 5
@export var bark_delay: float = 0.18
@export var bark_windup_duration: float = 0.45
@export var phase_two_root_cooldown: float = 8.5
@export var root_duration: float = 1.4
@export var territory_duration: float = 2.8
@export var territory_windup_duration: float = 0.8

const DEFAULT_CONFIG: BossConfig = preload("res://resources/configs/boss_treent_config.tres")

var phase: int = 1
var _phase_two_lunge_mult: float = 0.75
var _phase_two_bark_mult: float = 0.80
var territory_active: bool = false
var territory_label: String = ""

var _target: Node2D
var _lunge_state: String = "idle"
var _lunge_timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.ZERO
var _lunge_hit_applied: bool = false
var _bark_timer: float = 0.0
var _bark_active: bool = false
var _bark_index: int = 0
var _bark_internal_timer: float = 0.0
var _territory_timer: float = 0.0
var _territory_cooldown_timer: float = 4.0
var _territory_burst_timer: float = 0.0
var _territory_windup_timer: float = 0.0
var _territory_windup_active: bool = false
var _transition_fired: bool = false

func _ready() -> void:
	var cfg: BossConfig = config if config != null else DEFAULT_CONFIG
	max_health = CombatBalance.scale(cfg.max_health)
	health = max_health
	move_speed = cfg.move_speed
	contact_damage = 0.0
	lunge_damage = CombatBalance.scale(cfg.contact_damage)
	xp_reward = cfg.xp_reward
	lunge_cooldown = cfg.lunge_cooldown
	lunge_charge_duration = cfg.lunge_charge_duration
	lunge_duration = cfg.lunge_duration
	lunge_speed = cfg.lunge_speed
	bark_cooldown = cfg.bark_cooldown
	bark_shots_per_burst = cfg.bark_shots_per_burst
	bark_delay = cfg.bark_delay
	phase_two_root_cooldown = cfg.phase_two_root_cooldown
	root_duration = cfg.root_duration
	territory_duration = cfg.territory_duration
	_phase_two_lunge_mult = cfg.phase_two_lunge_mult
	_phase_two_bark_mult = cfg.phase_two_bark_mult
	display_name = "Treent Overlord"
	enemy_kind = "boss"
	body_color = Color(0.44, 0.72, 0.34, 1.0)
	super._ready()

func _physics_process(delta: float) -> void:
	_target = get_node_or_null(target_path) as Node2D
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		territory_label = "Phase 2"
		territory_active = false
		_territory_cooldown_timer = 1.8
		_transition_fired = true
		global_position = Vector2(960, 540)

	_update_lunge(delta)
	_update_bark_barrage(delta)
	_update_territory(delta)
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _update_lunge(delta: float) -> void:
	if _target == null:
		velocity = Vector2.ZERO
		return
	if territory_active or _territory_windup_active:
		velocity = Vector2.ZERO
		return

	match _lunge_state:
		"idle":
			_lunge_timer += delta
			var active_cooldown: float = lunge_cooldown * (_phase_two_lunge_mult if phase == 2 else 1.0)
			if _lunge_timer >= active_cooldown:
				_lunge_state = "charging"
				_lunge_timer = 0.0
				_lunge_direction = global_position.direction_to(_target.global_position)
				_lunge_hit_applied = false
				if _lunge_direction.length_squared() <= 0.0001:
					_lunge_direction = Vector2.RIGHT
				territory_label = "Lunge Charge"
			else:
				var follow_distance: float = 180.0
				var to_target: Vector2 = _target.global_position - global_position
				velocity = to_target.normalized() * get_effective_move_speed() if to_target.length() > follow_distance else Vector2.ZERO
		"charging":
			_lunge_timer += delta
			velocity = Vector2.ZERO
			if _lunge_timer >= lunge_charge_duration:
				_lunge_state = "lunging"
				_lunge_timer = 0.0
				territory_label = "Lunge"
		"lunging":
			_lunge_timer += delta
			velocity = _lunge_direction * lunge_speed * (1.08 if phase == 2 else 1.0)
			if not _lunge_hit_applied and global_position.distance_to(_target.global_position) <= lunge_hit_radius:
				if _target.has_method("take_damage"):
					_target.call("take_damage", lunge_damage)
				_lunge_hit_applied = true
			if _lunge_timer >= lunge_duration:
				_lunge_state = "idle"
				_lunge_timer = 0.0
				velocity = Vector2.ZERO
				territory_label = ""

func _update_bark_barrage(delta: float) -> void:
	if _target == null:
		return
	if _lunge_state != "idle" and not territory_active:
		return

	if not _bark_active:
		_bark_timer += delta
		var active_cooldown: float = bark_cooldown * (_phase_two_bark_mult if phase == 2 else 1.0)
		if _bark_timer >= active_cooldown:
			_bark_active = true
			_bark_timer = 0.0
			_bark_index = 0
			_bark_internal_timer = -bark_windup_duration
			if territory_label.is_empty():
				territory_label = "Bark Barrage"
		return

	_bark_internal_timer += delta
	if _bark_internal_timer < 0.0:
		return
	if _bark_internal_timer >= bark_delay and _bark_index < bark_shots_per_burst:
		_bark_internal_timer = 0.0
		_bark_index += 1
		var spread: float = deg_to_rad((-10.0 + float(_bark_index - 1) * 5.0))
		var target_vector: Vector2 = global_position.direction_to(_target.global_position).rotated(spread)
		emit_signal("bark_shot", global_position, global_position + target_vector * 120.0, 260.0 if phase == 2 else 220.0, CombatBalance.scale(10.0 if phase == 2 else 8.0))

	if _bark_index >= bark_shots_per_burst:
		_bark_active = false
		territory_label = ""

func _update_territory(delta: float) -> void:
	if phase != 2:
		return
	if territory_active:
		_territory_timer -= delta
		_territory_burst_timer += delta
		if _territory_burst_timer >= 0.36:
			_territory_burst_timer = 0.0
			for i in range(6):
				var angle: float = TAU * float(i) / 6.0 + _territory_timer
				var dir: Vector2 = Vector2.RIGHT.rotated(angle)
				emit_signal("bark_shot", global_position, global_position + dir * 140.0, 285.0, CombatBalance.scale(9.0))
		if _territory_timer <= 0.0:
			territory_active = false
			territory_label = ""
			emit_signal("territory_ended")
		return
	if _territory_windup_active:
		_territory_windup_timer -= delta
		velocity = Vector2.ZERO
		if _territory_windup_timer <= 0.0:
			_territory_windup_active = false
			territory_active = true
			_territory_timer = territory_duration
			_territory_burst_timer = 0.0
			_territory_cooldown_timer = phase_two_root_cooldown
			territory_label = "Encompass Root"
			emit_signal("encompass_root", root_duration)
			emit_signal("territory_started")
		return

	_territory_cooldown_timer -= delta
	if _territory_cooldown_timer <= 0.0:
		_territory_windup_active = true
		_territory_windup_timer = territory_windup_duration
		territory_label = "Encompass Root"

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.96, 0.96, 1.0), flash_mix)
	var outer: Color = Color(0.68, 0.28, 0.22, 0.8) if phase == 2 else Color(0.42, 0.88, 0.42, 0.75)
	draw_circle(Vector2(0, 10), 28.0, Color(0.05, 0.1, 0.07, 0.3))
	if territory_active:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(0.76, 0.58, 0.22, 0.85), 4.0)
	elif _territory_windup_active:
		var windup_ratio: float = 1.0 - clampf(_territory_windup_timer / max(territory_windup_duration, 0.001), 0.0, 1.0)
		draw_circle(Vector2.ZERO, 34.0 + windup_ratio * 10.0, Color(0.54, 0.42, 0.18, 0.08 + windup_ratio * 0.14))
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 30, Color(0.94, 0.8, 0.44, 0.34 + windup_ratio * 0.34), 3.0)
	elif _lunge_state == "charging":
		var charge_dir: Vector2 = _lunge_direction.normalized()
		if charge_dir.length_squared() <= 0.0001:
			charge_dir = Vector2.RIGHT
		var start_angle: float = charge_dir.angle() - 0.34
		var end_angle: float = charge_dir.angle() + 0.34
		var wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for i in range(10):
			var t: float = float(i) / 9.0
			var angle: float = lerpf(start_angle, end_angle, t)
			wedge.append(Vector2.RIGHT.rotated(angle) * 64.0)
		draw_colored_polygon(wedge, Color(1.0, 0.46, 0.24, 0.12))
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 28, Color(1.0, 0.7, 0.26, 0.82), 3.0)
	draw_circle(Vector2.ZERO, 26.0, tint)
	draw_circle(Vector2(0, -10), 12.0, outer)
	draw_circle(Vector2(-14, 6), 9.0, tint.darkened(0.18))
	draw_circle(Vector2(14, 6), 9.0, tint.darkened(0.18))
	if _bark_active and _bark_internal_timer < 0.0 and _target != null:
		var bark_dir: Vector2 = global_position.direction_to(_target.global_position)
		if bark_dir.length_squared() <= 0.0001:
			bark_dir = Vector2.RIGHT
		var bark_start: float = bark_dir.angle() - 0.24
		var bark_end: float = bark_dir.angle() + 0.24
		var bark_wedge: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for i in range(8):
			var t: float = float(i) / 7.0
			var angle: float = lerpf(bark_start, bark_end, t)
			bark_wedge.append(Vector2.RIGHT.rotated(angle) * 92.0)
		draw_colored_polygon(bark_wedge, Color(0.56, 0.38, 0.2, 0.12))
		draw_arc(Vector2.ZERO, 90.0, bark_start, bark_end, 18, Color(0.88, 0.72, 0.46, 0.52), 3.0)
