extends Node2D

signal spawn_requested(spawn_position: Vector2)

@export var delay: float = 0.65
@export var radius: float = 30.0

var _remaining: float = 0.0

func _ready() -> void:
	_remaining = delay
	queue_redraw()

func _process(delta: float) -> void:
	_remaining -= delta
	queue_redraw()
	if _remaining <= 0.0:
		spawn_requested.emit(global_position)
		queue_free()

func _draw() -> void:
	var ratio: float = 1.0 if delay <= 0.0 else clamp(1.0 - (_remaining / delay), 0.0, 1.0)
	var pulse: float = 0.72 + sin(Time.get_ticks_msec() * 0.016) * 0.12
	var ring_color: Color = Color(1.0, 0.14, 0.14, 0.45 + ratio * 0.3)
	var fill_color: Color = Color(0.24, 0.02, 0.02, 0.28 + ratio * 0.18)
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, lerp(radius + 8.0, radius, ratio), 0.0, TAU, 48, ring_color, 4.0)
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48, Color(1.0, 0.58, 0.18, 0.35), 2.0)
	var icon_scale: float = 0.9 + ratio * 0.12
	var head_center: Vector2 = Vector2(0.0, -4.0)
	draw_circle(head_center, 8.0 * icon_scale, Color(0.9, 0.1, 0.1, 0.95))
	draw_circle(head_center + Vector2(-3.0, -1.0), 1.3 * icon_scale, Color(1.0, 0.92, 0.82, 0.95))
	draw_circle(head_center + Vector2(3.0, -1.0), 1.3 * icon_scale, Color(1.0, 0.92, 0.82, 0.95))
	draw_polygon(
		PackedVector2Array([
			Vector2(-8.0, 6.0) * icon_scale,
			Vector2(8.0, 6.0) * icon_scale,
			Vector2(0.0, 14.0) * icon_scale,
		]),
		PackedColorArray([
			Color(0.9, 0.1, 0.1, 0.95),
			Color(0.9, 0.1, 0.1, 0.95),
			Color(0.64, 0.04, 0.04, 0.95),
		])
	)
