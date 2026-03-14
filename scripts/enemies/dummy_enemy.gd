extends EnemyBase

func _ready() -> void:
	body_color = Color(0.8, 0.88, 0.92, 1.0)
	contact_damage = 0.0
	xp_reward = 12
	max_health = 50.0
	super._ready()

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
