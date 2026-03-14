extends CharacterBody2D

signal died

@export var move_speed: float = 180.0
@export var max_health: float = 100.0
@export var invulnerability_time: float = 0.35

var health: float
var invulnerability_remaining: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT
var rooted_remaining: float = 0.0

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var ability_anchor: Node2D = $AbilityAnchor

func _ready() -> void:
	add_to_group("player")
	health = max_health
	queue_redraw()

func _physics_process(delta: float) -> void:
	if invulnerability_remaining > 0.0:
		invulnerability_remaining = max(invulnerability_remaining - delta, 0.0)
	if rooted_remaining > 0.0:
		rooted_remaining = max(rooted_remaining - delta, 0.0)
	var input_vector: Vector2 = Vector2.ZERO if rooted_remaining > 0.0 else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()
	queue_redraw()

func get_muzzle_global_position() -> Vector2:
	return muzzle.global_position

func set_aim_target(target_position: Vector2) -> void:
	var new_direction: Vector2 = global_position.direction_to(target_position)
	if new_direction.length_squared() <= 0.0001:
		return
	aim_direction = new_direction.normalized()
	weapon_pivot.rotation = aim_direction.angle()
	queue_redraw()

func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0 or invulnerability_remaining > 0.0:
		return
	health = max(health - amount, 0.0)
	invulnerability_remaining = invulnerability_time
	if has_node("/root/GameEvents"):
		GameEvents.player_damaged.emit(amount)
	queue_redraw()
	if health <= 0.0:
		died.emit()

func apply_root(duration: float) -> void:
	rooted_remaining = max(rooted_remaining, duration)
	queue_redraw()

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(health / max_health, 0.0, 1.0)

func _draw() -> void:
	var flash: float = 0.35 if invulnerability_remaining > 0.0 else 0.0
	var body_color: Color = Color(0.45 + flash, 0.72 + flash * 0.4, 1.0, 1.0)
	draw_circle(Vector2(0, 4), 10.0, Color(0.06, 0.14, 0.18, 0.28))
	if rooted_remaining > 0.0:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(0.48, 0.84, 0.46, 0.8), 3.0)
	draw_circle(Vector2.ZERO, 10.0, body_color)
	draw_circle(Vector2(0, -10), 5.5, Color(0.95, 0.84, 0.56, 1.0))
	draw_line(Vector2.ZERO, aim_direction * 18.0, Color(1.0, 0.9, 0.6, 0.95), 3.0, true)
