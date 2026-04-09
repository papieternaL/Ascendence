extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

@export var target_path: NodePath
@export var heal_cooldown: float = 4.2
@export var heal_amount: float = 100.0
@export var heal_radius: float = 170.0
@export var retreat_distance: float = 170.0

var _target: Node2D
var _heal_timer: float = 0.0

func _ready() -> void:
	max_health = CombatBalance.scale(34.0)
	health = max_health
	move_speed = 82.0
	contact_damage = CombatBalance.scale(5.0)
	xp_reward = 24
	rarity_charge_reward = 2
	display_name = "Healer"
	enemy_kind = "healer"
	body_color = Color(0.46, 0.9, 0.62, 1.0)
	super._ready()

func _physics_process(delta: float) -> void:
	_target = get_node_or_null(target_path) as Node2D
	_heal_timer += delta
	var heal_target: EnemyBase = _find_heal_target()
	if _heal_timer >= heal_cooldown and heal_target != null:
		_heal_timer = 0.0
		_heal_ally(heal_target)
	if is_rooted():
		velocity = Vector2.ZERO
		_apply_motion_with_knockback(delta)
		return
	if heal_target != null and global_position.distance_to(heal_target.global_position) > heal_radius * 0.7:
		velocity = global_position.direction_to(heal_target.global_position) * get_effective_move_speed()
	elif _target != null:
		var to_player: Vector2 = _target.global_position - global_position
		if to_player.length() < retreat_distance:
			velocity = -to_player.normalized() * get_effective_move_speed()
		else:
			velocity = to_player.orthogonal().normalized() * (get_effective_move_speed() * 0.55)
	else:
		velocity = Vector2.ZERO
	_apply_motion_with_knockback(delta)

func _find_heal_target() -> EnemyBase:
	var best: EnemyBase
	var best_ratio: float = 1.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is EnemyBase):
			continue
		var enemy: EnemyBase = node as EnemyBase
		if enemy.health <= 0.0 or enemy.max_health <= 0.0:
			continue
		if enemy.global_position.distance_to(global_position) > heal_radius:
			continue
		var ratio: float = enemy.health / enemy.max_health
		if ratio < best_ratio:
			best_ratio = ratio
			best = enemy
	return best

func _heal_ally(target: EnemyBase) -> void:
	target.health = min(target.max_health, target.health + heal_amount)
	target.queue_redraw()
	if target.has_method("_update_health_bar"):
		target.call("_update_health_bar")

func _draw() -> void:
	super._draw()
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.56, 1.0, 0.7, 0.65), 2.0)
