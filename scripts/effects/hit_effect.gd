extends Node2D

@export var duration: float = 0.12
@export var start_radius: float = 6.0
@export var end_radius: float = 18.0
@export var color: Color = Color(0.5, 0.9, 1.0, 0.9)
@export var effect_style: String = "ring"

var _time: float = 0.0

func configure(next_color: Color, next_style: String = "ring", next_start_radius: float = -1.0, next_end_radius: float = -1.0, next_duration: float = -1.0) -> void:
	color = next_color
	effect_style = next_style
	if next_start_radius > 0.0:
		start_radius = next_start_radius
	if next_end_radius > 0.0:
		end_radius = next_end_radius
	if next_duration > 0.0:
		duration = next_duration

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var radius: float = lerp(start_radius, end_radius, t)
	var a: float = (1.0 - t) * color.a
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, a), 2.0)
	if effect_style == "arrow":
		draw_line(Vector2(-radius * 0.8, 0.0), Vector2(radius * 0.8, 0.0), Color(color.r, color.g, color.b, a * 0.85), 2.0, true)
		draw_line(Vector2(radius * 0.2, -radius * 0.28), Vector2(radius * 0.8, 0.0), Color(1.0, 0.95, 0.82, a), 2.0, true)
		draw_line(Vector2(radius * 0.2, radius * 0.28), Vector2(radius * 0.8, 0.0), Color(1.0, 0.95, 0.82, a), 2.0, true)
	elif effect_style == "flash":
		for i in range(4):
			var angle: float = TAU * float(i) / 4.0
			var start: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.18)
			var finish: Vector2 = Vector2.RIGHT.rotated(angle) * radius
			draw_line(start, finish, Color(color.r, color.g, color.b, a), 2.0, true)
