extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

func _ready() -> void:
	max_health = CombatBalance.scale(80.0)
	health = max_health
	move_speed = 0.0
	contact_damage = 0.0
	xp_reward = 32
	rarity_charge_reward = 0
	counts_as_kill = false
	display_name = "Forest Core"
	enemy_kind = "objective_core"
	body_color = Color(0.72, 0.96, 0.88, 1.0)
	super._ready()

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 1.0, 1.0, 1.0), flash_mix)
	draw_circle(Vector2(0, 8), 18.0, Color(0.03, 0.14, 0.12, 0.28))
	draw_polygon(
		PackedVector2Array([Vector2(0, -24), Vector2(18, -4), Vector2(10, 24), Vector2(-10, 24), Vector2(-18, -4)]),
		PackedColorArray([tint, tint, tint.darkened(0.15), tint.darkened(0.15), tint]),
	)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, Color(0.58, 1.0, 0.88, 0.6), 2.0)
