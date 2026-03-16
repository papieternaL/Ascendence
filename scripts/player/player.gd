extends CharacterBody2D

signal died

@export var move_speed: float = 224.0
@export var max_health: float = 100.0
@export var invulnerability_time: float = 0.35
@export var blink_distance: float = 170.0
@export var blink_fx_duration: float = 0.12
@export var weapon_style: String = "bow"

var health: float
var invulnerability_remaining: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT
var rooted_remaining: float = 0.0
var dash_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var shoot_flash_remaining: float = 0.0

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
	if dash_remaining > 0.0:
		dash_remaining = max(dash_remaining - delta, 0.0)
	if shoot_flash_remaining > 0.0:
		shoot_flash_remaining = max(shoot_flash_remaining - delta, 0.0)
	if dash_remaining > 0.0:
		velocity = Vector2.ZERO
	else:
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

func clear_root() -> void:
	rooted_remaining = 0.0
	queue_redraw()

func start_dash(direction: Vector2) -> bool:
	if rooted_remaining > 0.0:
		return false
	var dash_dir: Vector2 = direction.normalized()
	if dash_dir.length_squared() <= 0.0001:
		dash_dir = aim_direction
	if dash_dir.length_squared() <= 0.0001:
		dash_dir = Vector2.RIGHT
	dash_direction = dash_dir.normalized()
	global_position += dash_direction * blink_distance
	dash_remaining = blink_fx_duration
	invulnerability_remaining = max(invulnerability_remaining, blink_fx_duration)
	queue_redraw()
	return true

func notify_primary_fired() -> void:
	shoot_flash_remaining = 0.12
	queue_redraw()

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(health / max_health, 0.0, 1.0)

func _draw() -> void:
	var flash: float = 0.35 if invulnerability_remaining > 0.0 else 0.0
	var body_color: Color = Color(0.45 + flash, 0.72 + flash * 0.4, 1.0, 1.0)
	draw_circle(Vector2(0, 4), 10.0, Color(0.06, 0.14, 0.18, 0.28))
	if dash_remaining > 0.0:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.74, 0.92, 1.0, 0.85), 4.0)
	if rooted_remaining > 0.0:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(0.48, 0.84, 0.46, 0.8), 3.0)
	draw_circle(Vector2.ZERO, 10.0, body_color)
	draw_circle(Vector2(0, -10), 5.5, Color(0.95, 0.84, 0.56, 1.0))
	if weapon_style == "bow":
		_draw_bow_weapon()
	else:
		_draw_pistol_weapon()

func _draw_bow_weapon() -> void:
	var forward: Vector2 = aim_direction.normalized()
	var right: Vector2 = forward.orthogonal()
	var bow_center: Vector2 = forward * 10.0
	var arc_offset: float = 6.0 + shoot_flash_remaining * 22.0
	var top: Vector2 = bow_center + right * 11.0
	var mid: Vector2 = bow_center + forward * 8.0
	var bottom: Vector2 = bow_center - right * 11.0
	draw_line(top, mid, Color(0.48, 0.28, 0.14, 1.0), 3.0, true)
	draw_line(mid, bottom, Color(0.58, 0.34, 0.16, 1.0), 3.0, true)
	var string_anchor: Vector2 = bow_center - forward * arc_offset
	draw_line(top, string_anchor, Color(0.92, 0.88, 0.72, 0.95), 1.5, true)
	draw_line(string_anchor, bottom, Color(0.92, 0.88, 0.72, 0.95), 1.5, true)
	draw_line(bow_center - forward * 4.0, bow_center + forward * 14.0, Color(0.8, 0.66, 0.36, 0.9), 2.0, true)
	draw_line(bow_center + forward * 11.0 + right * 2.0, bow_center + forward * 16.0, Color(1.0, 0.9, 0.66, 0.95), 2.0, true)
	draw_line(bow_center + forward * 11.0 - right * 2.0, bow_center + forward * 16.0, Color(1.0, 0.9, 0.66, 0.95), 2.0, true)
	if shoot_flash_remaining > 0.0:
		draw_arc(muzzle.position.rotated(weapon_pivot.rotation), 7.0 + shoot_flash_remaining * 12.0, 0.0, TAU, 20, Color(1.0, 0.88, 0.46, 0.6), 2.0)

func _draw_pistol_weapon() -> void:
	var gun_start: Vector2 = aim_direction * 4.0
	var gun_end: Vector2 = aim_direction * 18.0
	draw_line(gun_start, gun_end, Color(1.0, 0.9, 0.6, 0.95), 3.0, true)
	draw_line(gun_start + aim_direction.orthogonal() * 2.0, gun_start - aim_direction.orthogonal() * 3.0, Color(0.44, 0.34, 0.24, 1.0), 3.0, true)
	if shoot_flash_remaining > 0.0:
		draw_arc(muzzle.position.rotated(weapon_pivot.rotation), 6.0 + shoot_flash_remaining * 10.0, 0.0, TAU, 18, Color(0.7, 0.95, 1.0, 0.75), 2.0)
