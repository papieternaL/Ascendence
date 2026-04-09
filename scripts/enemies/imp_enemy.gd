extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

@export var target_path: NodePath

var _target: Node2D
var _orbit_time: float = 0.0

func _ready() -> void:
	max_health = CombatBalance.scale(22.0)
	health = max_health
	move_speed = 158.0
	contact_damage = CombatBalance.scale(7.0)
	xp_reward = 16
	rarity_charge_reward = 1
	display_name = "Imp"
	enemy_kind = "imp"
	body_color = Color(0.84, 0.42, 0.3, 1.0)
	super._ready()

func _physics_process(delta: float) -> void:
	_target = get_node_or_null(target_path) as Node2D
	_orbit_time += delta
	if _target == null or is_rooted():
		velocity = Vector2.ZERO
	else:
		var to_target: Vector2 = _target.global_position - global_position
		var forward: Vector2 = to_target.normalized()
		var strafe: Vector2 = forward.orthogonal() * sin(_orbit_time * 5.5)
		velocity = (forward + strafe * 0.35).normalized() * get_effective_move_speed()
	_apply_motion_with_knockback(delta)
