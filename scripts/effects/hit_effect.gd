extends Node2D

@export var duration: float = 0.12
@export var start_radius: float = 6.0
@export var end_radius: float = 18.0
@export var color: Color = Color(0.5, 0.9, 1.0, 0.9)

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var t := clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var radius := lerp(start_radius, end_radius, t)
	var a := (1.0 - t) * color.a
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, a), 2.0)
