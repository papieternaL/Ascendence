extends Node2D

var _radius: float = 260.0
var _time: float = 0.0
var _duration: float = 0.7

func configure(radius: float) -> void:
	_radius = max(radius, 32.0)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= _duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_time / _duration, 0.0, 1.0)
	var outer_radius: float = lerpf(12.0, _radius, t)
	var inner_radius: float = lerpf(2.0, _radius * 0.44, min(t * 1.2, 1.0))
	var flash_alpha: float = 0.34 * (1.0 - t)
	draw_circle(Vector2.ZERO, outer_radius, Color(1.0, 0.95, 0.72, flash_alpha))
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 40, Color(1.0, 0.98, 0.86, 0.96 * (1.0 - t)), 6.0)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 36, Color(1.0, 0.86, 0.42, 0.72 * (1.0 - t)), 4.0)
	for i in range(5):
		var angle: float = -PI * 0.5 + TAU * float(i) / 5.0
		var point: Vector2 = Vector2.RIGHT.rotated(angle) * inner_radius
		draw_line(Vector2.ZERO, point, Color(1.0, 0.96, 0.78, 0.62 * (1.0 - t)), 3.0, true)
