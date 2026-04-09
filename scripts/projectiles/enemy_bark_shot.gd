extends Area2D

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")

signal hit(at: Vector2)

@export var speed: float = 240.0
@export var lifetime: float = 2.8
@export var damage: float = 100.0
@export var visual_scale: float = 1.0
@export var trail_length: float = 18.0
@export var trail_width: float = 5.0
var direction: Vector2 = Vector2.RIGHT

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var shape: CircleShape2D = (collision_shape.shape as CircleShape2D).duplicate()
		shape.radius *= maxf(visual_scale, 0.1)
		collision_shape.shape = shape
	body_entered.connect(_on_body_entered)
	if notifier:
		notifier.screen_exited.connect(queue_free)
	queue_redraw()

func _process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	hit.emit(global_position)
	queue_free()

func _draw() -> void:
	var body_half_width: float = 4.2 * visual_scale
	var body_half_length: float = 9.5 * visual_scale
	var trail_start: Vector2 = Vector2(-trail_length, 0.0)
	draw_line(trail_start, Vector2(-body_half_length * 0.8, 0.0), Color(0.22, 0.16, 0.1, 0.28), trail_width * 0.52, true)
	draw_line(trail_start * 0.7 + Vector2(0.0, -1.5 * visual_scale), Vector2(-body_half_length * 0.55, -1.0 * visual_scale), Color(0.52, 0.4, 0.26, 0.24), maxf(trail_width * 0.28, 1.0), true)
	draw_line(trail_start * 0.6 + Vector2(0.0, 1.8 * visual_scale), Vector2(-body_half_length * 0.45, 1.2 * visual_scale), Color(0.56, 0.42, 0.28, 0.2), maxf(trail_width * 0.22, 1.0), true)
	var bark_body: PackedVector2Array = PackedVector2Array([
		Vector2(-body_half_length, -body_half_width),
		Vector2(body_half_length * 0.72, -body_half_width * 1.15),
		Vector2(body_half_length, 0.0),
		Vector2(body_half_length * 0.72, body_half_width * 1.15),
		Vector2(-body_half_length, body_half_width),
		Vector2(-body_half_length * 1.12, 0.0),
	])
	draw_colored_polygon(bark_body, Color(0.34, 0.22, 0.12, 0.98))
	draw_line(Vector2(-body_half_length * 0.78, -1.1 * visual_scale), Vector2(body_half_length * 0.7, -1.8 * visual_scale), Color(0.68, 0.54, 0.36, 0.76), 1.6 * visual_scale, true)
	draw_line(Vector2(-body_half_length * 0.68, 1.6 * visual_scale), Vector2(body_half_length * 0.52, 1.1 * visual_scale), Color(0.24, 0.14, 0.08, 0.66), 1.2 * visual_scale, true)
	for chip in [
		Vector2(-body_half_length - 4.0 * visual_scale, -2.2 * visual_scale),
		Vector2(-body_half_length - 8.0 * visual_scale, 1.4 * visual_scale),
	]:
		draw_circle(chip, 1.2 * visual_scale, Color(0.72, 0.62, 0.44, 0.46))
