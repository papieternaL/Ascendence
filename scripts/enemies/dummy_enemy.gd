extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const DummyVisuals = preload("res://scripts/enemies/dummy_visuals.gd")

func _ready() -> void:
	body_color = Color(0.8, 0.88, 0.92, 1.0)
	contact_damage = 0.0
	xp_reward = 12
	display_name = "Target Dummy"
	enemy_kind = "training_dummy"
	show_health_bar_always = true
	show_nameplate = true
	health_bar_scale = Vector2(1.5, 1.0)
	max_health = CombatBalance.scale(50.0)
	super._ready()

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func apply_hit_recoil(_direction: Vector2, _heavy: bool) -> void:
	_knockback_velocity = Vector2.ZERO

func _draw() -> void:
	DummyVisuals.draw_training_dummy(
		self,
		_flash_remaining,
		_flash_duration_current,
		_hit_reaction_remaining,
		_hit_reaction_duration_current,
		_hit_reaction_direction,
		_hit_reaction_intensity,
		Color(0.42, 0.78, 1.0, 0.94)
	)
