extends Control

@export var warning_duration: float = 1.5
@export var active_duration: float = 7.0
@export var edge_band_size: float = 156.0

var direction: Vector2 = Vector2.RIGHT
var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func configure(next_direction: Vector2, next_warning_duration: float, next_active_duration: float) -> void:
	direction = next_direction.normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	warning_duration = maxf(next_warning_duration, 0.0)
	active_duration = maxf(next_active_duration, 0.1)
	_elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= warning_duration + active_duration:
		queue_free()

func is_force_active() -> bool:
	return _elapsed >= warning_duration and _elapsed < warning_duration + active_duration

func is_finished() -> bool:
	return _elapsed >= warning_duration + active_duration

func _draw() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var active: bool = is_force_active()
	var phase_t: float = clampf((_elapsed - warning_duration) / max(active_duration, 0.001), 0.0, 1.0) if active else clampf(_elapsed / max(warning_duration, 0.001), 0.0, 1.0)
	var source_edge: String = _get_source_edge()
	var band_rect: Rect2 = _get_edge_band_rect(viewport_size, source_edge)
	var dir: Vector2 = direction.normalized()
	var normal: Vector2 = dir.orthogonal()
	if active:
		_draw_directional_streaks(viewport_size, band_rect, dir, normal, phase_t, 14, 190.0, 2.4, 0.18, 0.12, true)
	else:
		_draw_directional_streaks(viewport_size, band_rect, dir, normal, phase_t, 7, 92.0, 1.8, 0.14, 0.07, false)

func _get_source_edge() -> String:
	if absf(direction.x) >= absf(direction.y):
		return "left" if direction.x > 0.0 else "right"
	return "top" if direction.y > 0.0 else "bottom"

func _get_edge_band_rect(viewport_size: Vector2, source_edge: String) -> Rect2:
	match source_edge:
		"left":
			return Rect2(0.0, 0.0, edge_band_size, viewport_size.y)
		"right":
			return Rect2(viewport_size.x - edge_band_size, 0.0, edge_band_size, viewport_size.y)
		"top":
			return Rect2(0.0, 0.0, viewport_size.x, edge_band_size)
		"bottom":
			return Rect2(0.0, viewport_size.y - edge_band_size, viewport_size.x, edge_band_size)
		_:
			return Rect2(0.0, 0.0, edge_band_size, viewport_size.y)

func _draw_directional_streaks(viewport_size: Vector2, band_rect: Rect2, dir: Vector2, normal: Vector2, phase_t: float, streak_count: int, travel_speed: float, width: float, base_alpha: float, alpha_bonus: float, active: bool) -> void:
	var motion_time: float = Time.get_ticks_msec() * 0.001
	for i in range(streak_count):
		var travel: float = fmod(motion_time * travel_speed + float(i) * 57.0, max(viewport_size.x, viewport_size.y) + 260.0) - 130.0
		var cross_extent: float = band_rect.size.y if absf(dir.x) > absf(dir.y) else band_rect.size.x
		var cross: float = lerpf(-cross_extent * 0.42, cross_extent * 0.42, float(i) / float(max(streak_count - 1, 1)))
		var origin_bias: float = 16.0 + float(i % 3) * 7.0
		var base_center: Vector2 = band_rect.get_center() + normal * cross + dir * (travel * 0.18 - origin_bias)
		var half_length: float = (18.0 if not active else 26.0) + 8.0 * sin(motion_time * 1.2 + float(i))
		var alpha: float = base_alpha + alpha_bonus * phase_t
		var tint: Color = Color(0.86, 0.96, 1.0, alpha)
		var start: Vector2 = base_center - dir * half_length
		var finish: Vector2 = base_center + dir * half_length
		draw_line(start, finish, tint, width, true)
		draw_line(start + normal * 4.0, finish + normal * 2.0, Color(0.92, 0.98, 1.0, alpha * 0.42), maxf(width * 0.58, 1.0), true)
		draw_line(start - normal * 5.0, finish - normal * 2.0, Color(0.78, 0.9, 1.0, alpha * 0.22), maxf(width * 0.44, 1.0), true)
		var arrow_tip: Vector2 = finish + dir * (6.0 if active else 4.0)
		var wing_a: Vector2 = finish - dir * 5.0 + normal * (5.0 if active else 3.5)
		var wing_b: Vector2 = finish - dir * 5.0 - normal * (5.0 if active else 3.5)
		draw_line(wing_a, arrow_tip, Color(0.98, 1.0, 1.0, alpha * 0.76), maxf(width * 0.7, 1.0), true)
		draw_line(wing_b, arrow_tip, Color(0.98, 1.0, 1.0, alpha * 0.76), maxf(width * 0.7, 1.0), true)
