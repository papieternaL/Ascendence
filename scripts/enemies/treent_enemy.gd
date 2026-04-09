extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

@export var target_path: NodePath
@export var slam_range: float = 82.0
@export var slam_windup: float = 0.8
@export var slam_recovery: float = 1.1
@export var slam_damage: float = 240.0

var _state: String = "approach"
var _state_timer: float = 0.0
var _target: Node2D

func _ready() -> void:
	body_color = Color(0.46, 0.34, 0.22, 1.0)
	max_health = CombatBalance.scale(220.0)
	health = max_health
	move_speed = 22.0
	contact_damage = 0.0
	xp_reward = 55
	display_name = "Big Treent"
	enemy_kind = "treent"
	super._ready()

func _physics_process(delta: float) -> void:
	if is_rooted():
		_state = "approach"
		_state_timer = 0.0
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target == null:
		velocity = Vector2.ZERO
	else:
		var to_target: Vector2 = _target.global_position - global_position
		var distance: float = to_target.length()
		match _state:
			"approach":
				if distance <= slam_range:
					_state = "windup"
					_state_timer = 0.0
					velocity = Vector2.ZERO
				else:
					velocity = to_target.normalized() * get_effective_move_speed() if distance > 0.001 else Vector2.ZERO
			"windup":
				velocity = Vector2.ZERO
				_state_timer += delta
				if _state_timer >= slam_windup:
					_perform_slam_hit()
					_state = "recovery"
					_state_timer = 0.0
			"recovery":
				velocity = Vector2.ZERO
				_state_timer += delta
				if _state_timer >= slam_recovery:
					_state = "approach"
					_state_timer = 0.0
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _perform_slam_hit() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if global_position.distance_to(_target.global_position) <= slam_range and _target.has_method("take_damage"):
		_target.call("take_damage", slam_damage)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	draw_circle(Vector2(0, 9), 18.0, Color(0.05, 0.1, 0.08, 0.24))
	draw_rect(Rect2(-18, -18, 36, 36), tint, true)
	draw_circle(Vector2(0, -8), 10.0, Color(0.3, 0.48, 0.2, 0.95))
	if _state == "windup" or _state == "recovery":
		var active_duration: float = slam_windup if _state == "windup" else slam_recovery
		var slam_ratio: float = clampf(_state_timer / max(active_duration, 0.001), 0.0, 1.0)
		draw_circle(Vector2.ZERO, slam_range, Color(0.78, 0.56, 0.28, 0.08 + slam_ratio * 0.16))
		draw_arc(Vector2.ZERO, slam_range, 0.0, TAU, 30, Color(0.94, 0.78, 0.48, 0.34 + slam_ratio * 0.5), 3.6)
		if _state == "recovery":
			draw_arc(Vector2.ZERO, slam_range + 12.0, 0.0, TAU, 30, Color(1.0, 0.92, 0.72, 0.38), 2.2)
