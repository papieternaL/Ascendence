extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

func _ready() -> void:
	max_health = CombatBalance.scale(18.0)
	health = max_health
	move_speed = 0.0
	contact_damage = 0.0
	xp_reward = 0
	rarity_charge_reward = 0
	counts_as_kill = false
	display_name = "Reward Chest"
	enemy_kind = "reward_chest"
	body_color = Color(0.72, 0.46, 0.18, 1.0)
	super._ready()

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO

func _draw() -> void:
	draw_circle(Vector2(0, 10), 18.0, Color(0.05, 0.06, 0.04, 0.22))
	draw_rect(Rect2(-16.0, -8.0, 32.0, 22.0), Color(0.4, 0.22, 0.08, 1.0), true)
	draw_rect(Rect2(-12.0, -14.0, 24.0, 12.0), Color(0.58, 0.34, 0.12, 1.0), true)
	draw_rect(Rect2(-4.0, -10.0, 8.0, 20.0), Color(0.9, 0.76, 0.34, 0.92), true)
	draw_arc(Vector2.ZERO, 18.0, PI, TAU, 18, Color(0.96, 0.84, 0.42, 0.72), 2.0)
	if health_bar != null:
		health_bar.visible = health < max_health
