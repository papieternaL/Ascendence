extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 300.0
@export var turn_rate: float = 8.0
@export var lifetime: float = 3.0
@export var damage: float = 200.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var visual_scale: float = 1.28
@export var attack_payload: Dictionary = {}
var direction: Vector2 = Vector2.RIGHT
var target: Node2D

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var shape: CircleShape2D = (collision_shape.shape as CircleShape2D).duplicate()
		shape.radius *= maxf(visual_scale, 0.1)
		collision_shape.shape = shape
	if notifier:
		notifier.screen_exited.connect(queue_free)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var desired: Vector2 = global_position.direction_to(target.global_position)
		direction = direction.slerp(desired, min(turn_rate * delta, 1.0)).normalized()
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_attempt_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_attempt_hit(area)

func _attempt_hit(target: Node) -> void:
	var payload: Dictionary = DAMAGE_SYSTEM.build_hit_payload(damage, crit_chance, crit_multiplier)
	for key in attack_payload.keys():
		payload[key] = attack_payload[key]
	if DAMAGE_SYSTEM.apply_hit(target, payload).is_empty():
		return
	hit.emit(global_position)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2(-8.0, 0.0) * visual_scale, 7.0 * visual_scale, Color(0.22, 0.06, 0.34, 0.18))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(8.0, 0.0) * visual_scale,
			Vector2(-2.0, -4.0) * visual_scale,
			Vector2(-7.0, -2.0) * visual_scale,
			Vector2(-7.0, 2.0) * visual_scale,
			Vector2(-2.0, 4.0) * visual_scale,
		]),
		Color(0.88, 0.54, 1.0, 0.96)
	)
	draw_circle(Vector2(2.0, 0.0) * visual_scale, 3.2 * visual_scale, Color(1.0, 0.84, 1.0, 0.72))
	draw_line(Vector2(-18.0, 0.0) * visual_scale, Vector2(-4.0, 0.0) * visual_scale, Color(0.84, 0.46, 1.0, 0.30), 4.4 * visual_scale, true)
	draw_line(Vector2(-14.0, -2.0) * visual_scale, Vector2(-5.0, -1.0) * visual_scale, Color(0.70, 0.34, 0.98, 0.22), 2.5 * visual_scale, true)
	draw_line(Vector2(-14.0, 2.0) * visual_scale, Vector2(-5.0, 1.0) * visual_scale, Color(0.70, 0.34, 0.98, 0.22), 2.5 * visual_scale, true)
