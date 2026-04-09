extends Area2D
class_name ShrinePoint

@export var point_index: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _completed: bool = false
var _shared_progress: float = 0.0
var _charging: bool = false

func _ready() -> void:
	queue_redraw()

func configure(activation_radius: float, _grace_seconds: float) -> void:
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = activation_radius
	queue_redraw()

func set_player(_player: Node2D) -> void:
	pass

func set_visual_state(value: float, charging: bool, completed: bool) -> void:
	_shared_progress = clamp(value, 0.0, 1.0)
	_charging = charging
	_completed = completed
	queue_redraw()

func is_completed() -> bool:
	return _completed

func _draw() -> void:
	var time_value: float = Time.get_ticks_msec() * 0.001
	var shadow_alpha: float = 0.18 + 0.05 * sin(time_value * 2.5 + float(point_index))
	draw_circle(Vector2(0.0, 12.0), 18.0, Color(0.02, 0.08, 0.1, shadow_alpha))

	var pulse: float = 1.0 + 0.06 * sin(time_value * 3.8 + float(point_index) * 0.7)
	var outer_radius: float = 17.0 * pulse
	var inner_radius: float = 7.0 + 3.5 * _shared_progress
	var ring_color: Color = Color(0.32, 0.46, 0.66, 0.76)
	var fill_color: Color = Color(0.08, 0.14, 0.24, 0.92)
	var halo_color: Color = Color(0.28, 0.58, 0.92, 0.12 + _shared_progress * 0.08)

	if _completed:
		ring_color = Color(1.0, 0.95, 0.62, 0.98)
		fill_color = Color(0.98, 0.92, 0.54, 0.74)
		halo_color = Color(1.0, 0.94, 0.62, 0.28)
	elif _charging:
		ring_color = Color(0.84, 0.97, 1.0, 0.96)
		fill_color = Color(0.54, 0.9, 1.0, 0.26 + _shared_progress * 0.16)
		halo_color = Color(0.72, 0.94, 1.0, 0.24 + _shared_progress * 0.12)
	elif _shared_progress > 0.0:
		ring_color = Color(0.58, 0.78, 0.96, 0.88)
		fill_color = Color(0.22, 0.38, 0.56, 0.24 + _shared_progress * 0.08)
		halo_color = Color(0.52, 0.78, 1.0, 0.16 + _shared_progress * 0.08)

	draw_circle(Vector2.ZERO, outer_radius * 1.55, halo_color)
	draw_circle(Vector2.ZERO, outer_radius, Color(ring_color.r, ring_color.g, ring_color.b, 0.16))
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 28, ring_color, 3.2)
	draw_circle(Vector2.ZERO, inner_radius + 5.8, fill_color)
	draw_circle(Vector2.ZERO, inner_radius, Color(1.0, 1.0, 1.0, 0.14))
	draw_circle(Vector2.ZERO, inner_radius * 0.48, Color(1.0, 1.0, 1.0, 0.55 if _completed else 0.34))
