extends EnemyBase

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const DummyVisuals = preload("res://scripts/enemies/dummy_visuals.gd")

@export var reset_delay: float = 0.8

var _spawn_position: Vector2 = Vector2.ZERO
var _respawning: bool = false

@onready var body_collider: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

func _ready() -> void:
	body_color = Color(0.90, 0.78, 0.46, 1.0)
	contact_damage = 0.0
	xp_reward = 0
	counts_as_kill = false
	display_name = "Training Dummy"
	enemy_kind = "training_dummy"
	max_health = CombatBalance.scale(280.0)
	show_health_bar_always = true
	show_nameplate = true
	health_bar_scale = Vector2(1.8, 1.15)
	_spawn_position = global_position
	super._ready()
	var feedback_callback: Callable = Callable(self, "_on_damage_feedback")
	if not damage_feedback.is_connected(feedback_callback):
		damage_feedback.connect(feedback_callback)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func apply_hit_recoil(_direction: Vector2, _heavy: bool) -> void:
	_knockback_velocity = Vector2.ZERO

func die() -> void:
	if _respawning:
		return
	_respawning = true
	health = 0.0
	_update_health_bar()
	visible = false
	if body_collider != null:
		body_collider.disabled = true
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	set_physics_process(false)
	var timer: SceneTreeTimer = get_tree().create_timer(reset_delay)
	timer.timeout.connect(_reset_dummy, CONNECT_ONE_SHOT)

func _reset_dummy() -> void:
	global_position = _spawn_position
	health = max_health
	elemental_statuses.clear()
	rooted_remaining = 0.0
	last_hit_was_crit = false
	_knockback_velocity = Vector2.ZERO
	_flash_remaining = 0.0
	_hit_reaction_remaining = 0.0
	visible = true
	if body_collider != null:
		body_collider.disabled = false
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	set_physics_process(true)
	_update_health_bar()
	queue_redraw()
	_respawning = false

func _draw() -> void:
	DummyVisuals.draw_training_dummy(
		self,
		_flash_remaining,
		_flash_duration_current,
		_hit_reaction_remaining,
		_hit_reaction_duration_current,
		_hit_reaction_direction,
		_hit_reaction_intensity,
		Color(0.84, 0.22, 0.16, 0.96)
	)

func _on_damage_feedback(data: Dictionary) -> void:
	if bool(data.get("killed", false)):
		return
	var event_id: String = "dummy_hit_heavy" if bool(data.get("heavy_hit", false)) else "dummy_hit_light"
	AudioDirector.play_sfx(event_id, -5.0 if event_id == "dummy_hit_heavy" else -7.0)
