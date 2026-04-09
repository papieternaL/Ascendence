extends Node2D

@export var duration: float = 0.2
@export var start_radius: float = 4.0
@export var end_radius: float = 20.0
@export var burst_color: Color = Color(1.0, 0.72, 0.42, 0.82)

var _time: float = 0.0

func configure(next_color: Color, next_start_radius: float = -1.0, next_end_radius: float = -1.0, next_duration: float = -1.0) -> void:
	burst_color = next_color
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
	var reduced_flashes: bool = GameSettings and GameSettings.use_reduced_flashes()
	var t: float = clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var radius: float = lerp(start_radius, end_radius, t)
	var alpha: float = (1.0 - t) * burst_color.a
	if reduced_flashes:
		alpha *= 0.72
	draw_circle(Vector2.ZERO, radius * 0.34, Color(burst_color.r, burst_color.g, burst_color.b, alpha * 0.14))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(burst_color.r, burst_color.g, burst_color.b, alpha), 2.0)
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0 + t * 0.8
		var inner: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.24)
		var outer: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.98)
		draw_line(inner, outer, Color(1.0, 0.92, 0.76, alpha * 0.84), 1.6, true)
