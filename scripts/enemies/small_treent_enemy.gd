extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

signal bark_shot(origin: Vector2, target: Vector2, speed: float, damage: float)

@export var target_path: NodePath
@export var preferred_range: float = 220.0
@export var bark_range: float = 260.0
@export var bark_cooldown: float = 2.0

var _bark_timer: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_color = Color(0.48, 0.68, 0.34, 1.0)
	max_health = CombatBalance.scale(70.0)
	health = max_health
	move_speed = 58.0
	contact_damage = 0.0
	xp_reward = 60
	display_name = "Small Treent"
	enemy_kind = "small_treent"
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
	if distance > 0.001:
		_aim_direction = to_target.normalized()
	if distance > preferred_range:
		velocity = to_target.normalized() * get_effective_move_speed()
	else:
		velocity = Vector2.ZERO
	if distance <= bark_range:
		_bark_timer += delta
		if _bark_timer >= bark_cooldown:
			_bark_timer = 0.0
			emit_signal("bark_shot", global_position, target.global_position, 265.0, CombatBalance.scale(10.0))
	else:
		_bark_timer = 0.0
	_apply_motion_with_knockback(delta)
	queue_redraw()

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	draw_circle(Vector2(0, 8), 14.0, Color(0.05, 0.1, 0.08, 0.22))
	draw_circle(Vector2.ZERO, 14.0, tint)
	draw_circle(Vector2(0, -8), 6.0, Color(0.34, 0.54, 0.24, 0.95))
	draw_circle(Vector2(10, -2), 3.0, Color(0.88, 0.92, 0.74, 0.92))
	var bark_ratio: float = clampf(_bark_timer / max(bark_cooldown, 0.001), 0.0, 1.0)
	if bark_ratio >= 0.45:
		var telegraph_alpha: float = (bark_ratio - 0.45) / 0.55
		var aim_tip: Vector2 = _aim_direction * 30.0
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.74, 0.6, 0.38, 0.24 + telegraph_alpha * 0.4), 2.2)
		draw_line(Vector2.ZERO, aim_tip, Color(0.84, 0.72, 0.48, 0.24 + telegraph_alpha * 0.72), 3.4, true)
		draw_circle(aim_tip, 5.0 + telegraph_alpha * 3.0, Color(0.7, 0.56, 0.34, 0.18 + telegraph_alpha * 0.34))
