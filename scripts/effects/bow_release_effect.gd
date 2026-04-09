extends Node2D

@export var duration: float = 0.07
@export var start_alpha: float = 0.85
@export var flare_radius: float = 5.0
@export var streak_length: float = 10.0
@export var tint: Color = Color(1.0, 0.92, 0.66, 0.92)

var _time: float = 0.0

func configure(direction: Vector2, next_tint: Color = Color(1.0, 0.92, 0.66, 0.92)) -> void:
	tint = next_tint
	if direction.length_squared() > 0.0001:
		rotation = direction.angle()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var reduced_flashes: bool = GameSettings and GameSettings.use_reduced_flashes()
	var t: float = clampf(_time / max(duration, 0.001), 0.0, 1.0)
	var alpha: float = (1.0 - t) * start_alpha
	if reduced_flashes:
		alpha *= 0.7
	var radius: float = lerpf(flare_radius * 0.65, flare_radius, t)
	var forward: Vector2 = Vector2.RIGHT
	var upper: Vector2 = Vector2(0.18, -0.74).normalized()
	var lower: Vector2 = Vector2(0.18, 0.74).normalized()
	draw_circle(Vector2.ZERO, radius, Color(tint.r, tint.g, tint.b, alpha * 0.22))
	draw_line(forward * -3.0, forward * streak_length, Color(tint.r, tint.g, tint.b, alpha), 2.0, true)
	draw_line(Vector2.ZERO, upper * streak_length * 0.72, Color(1.0, 0.96, 0.8, alpha * 0.82), 1.7, true)
	draw_line(Vector2.ZERO, lower * streak_length * 0.72, Color(1.0, 0.96, 0.8, alpha * 0.82), 1.7, true)
	draw_line(forward * -5.0, upper * 3.0, Color(1.0, 0.95, 0.84, alpha * 0.5), 1.2, true)
	draw_line(forward * -5.0, lower * 3.0, Color(1.0, 0.95, 0.84, alpha * 0.5), 1.2, true)
