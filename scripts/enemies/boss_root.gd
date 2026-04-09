extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

func _ready() -> void:
	max_health = CombatBalance.scale(36.0)
	health = max_health
	move_speed = 0.0
	contact_damage = 0.0
	xp_reward = 0
	rarity_charge_reward = 0
	counts_as_kill = false
	display_name = "Root"
	enemy_kind = "boss_root"
	body_color = Color(0.52, 0.36, 0.18, 1.0)
	super._ready()

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	_apply_motion_with_knockback(_delta)

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.96, 0.92, 1.0), flash_mix)
	draw_circle(Vector2(0, 8), 16.0, Color(0.05, 0.08, 0.06, 0.2))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -18),
			Vector2(16, -2),
			Vector2(8, 20),
			Vector2(-8, 20),
			Vector2(-16, -2),
		]),
		tint
	)
