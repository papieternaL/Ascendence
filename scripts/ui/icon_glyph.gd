extends Control

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@export var icon_id: String = "default"
@export var fallback_icon_id: String = ""
@export var primary_color: Color = Color(0.83, 0.9, 1.0, 1.0)
@export var accent_color: Color = Color(0.97, 0.77, 0.3, 1.0)
@export var line_width: float = 2.0
@export var cooldown_overlay_visible: bool = false
@export_range(0.0, 1.0, 0.001) var cooldown_fill_ratio: float = 0.0
@export var cooldown_seconds: float = 0.0
@export var charge_pips_total: int = 0
@export var charge_pips_filled: int = 0

## Scale factor for icon content so it stays inside the circle (avoids clipping).
const INNER_SCALE: float = 0.78

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func configure(
	next_icon_id: String,
	next_primary: Color = Color(0.83, 0.9, 1.0, 1.0),
	next_accent: Color = Color(0.97, 0.77, 0.3, 1.0),
	next_fallback_icon_id: String = ""
) -> void:
	if icon_id == next_icon_id and fallback_icon_id == next_fallback_icon_id and primary_color == next_primary and accent_color == next_accent:
		return
	icon_id = next_icon_id
	fallback_icon_id = next_fallback_icon_id
	primary_color = next_primary
	accent_color = next_accent
	queue_redraw()

func set_cooldown_overlay(show_overlay: bool, fill_ratio: float, next_charge_total: int = 0, next_charge_filled: int = 0, next_cooldown_seconds: float = 0.0) -> void:
	var clamped_fill: float = clampf(fill_ratio, 0.0, 1.0)
	var resolved_total: int = max(next_charge_total, 0)
	var resolved_filled: int = clampi(next_charge_filled, 0, resolved_total)
	var resolved_seconds: float = maxf(next_cooldown_seconds, 0.0)
	if cooldown_overlay_visible == show_overlay and is_equal_approx(cooldown_fill_ratio, clamped_fill) and charge_pips_total == resolved_total and charge_pips_filled == resolved_filled and is_equal_approx(cooldown_seconds, resolved_seconds):
		return
	cooldown_overlay_visible = show_overlay
	cooldown_fill_ratio = clamped_fill
	cooldown_seconds = resolved_seconds
	charge_pips_total = resolved_total
	charge_pips_filled = resolved_filled
	queue_redraw()

func _draw() -> void:
	var drew_icon_texture: bool = false
	if FrontendStyle.has_icon(icon_id):
		var texture: Texture2D = FrontendStyle.make_icon_texture(icon_id)
		if texture != null:
			draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
			drew_icon_texture = true
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var center: Vector2 = rect.get_center()
	var radius: float = min(rect.size.x, rect.size.y) * 0.42
	if not drew_icon_texture:
		draw_circle(center, radius, Color(0.14, 0.19, 0.28, 0.96))
		draw_circle(center, radius * 0.78, Color(0.08, 0.12, 0.18, 0.46))
		draw_arc(center, radius, 0.0, TAU, 24, Color(0.86, 0.92, 1.0, 0.86), 1.8)
	var inner_radius: float = radius * INNER_SCALE
	if not drew_icon_texture:
		var procedural_icon_id: String = fallback_icon_id if not fallback_icon_id.strip_edges().is_empty() else icon_id
		match procedural_icon_id:
			"bow":
				_draw_bow(center, inner_radius)
			"power_shot":
				_draw_power_shot(center, inner_radius)
			"arrow_volley":
				_draw_arrow_volley(center, inner_radius)
			"arrow_storm":
				_draw_arrow_storm(center, inner_radius)
			"explosive_volley":
				_draw_explosive_volley(center, inner_radius)
			"dash", "blink", "move":
				_draw_dash(center, inner_radius)
			"dash_charge":
				_draw_dash_charge(center, inner_radius)
			"sentinel", "sentinel_upgrade":
				_draw_sentinel(center, inner_radius)
			"fire":
				_draw_fire(center, inner_radius)
			"ice":
				_draw_ice(center, inner_radius)
			"lightning":
				_draw_lightning(center, inner_radius)
			"entangle", "entangle_upgrade":
				_draw_entangle(center, inner_radius)
			"frenzy", "frenzy_upgrade", "crit":
				_draw_frenzy(center, inner_radius)
			"pistol":
				_draw_pistol(center, inner_radius)
			"missiles", "arcane":
				_draw_missiles(center, inner_radius)
			"sniper", "pierce":
				_draw_sniper(center, inner_radius)
			"ricochet":
				_draw_ricochet(center, inner_radius)
			"deadeye_bloom":
				_draw_deadeye_bloom(center, inner_radius)
			"damage":
				_draw_damage(center, inner_radius)
			"attack_speed":
				_draw_attack_speed(center, inner_radius)
			"default":
				_draw_default(center, inner_radius)
			_:
				_draw_default(center, inner_radius)
	if cooldown_overlay_visible and cooldown_fill_ratio > 0.001:
		_draw_cooldown_overlay(center, radius * 0.96, cooldown_fill_ratio)
	if charge_pips_total > 0:
		_draw_charge_pips(center, radius * 1.02, charge_pips_total, charge_pips_filled)

func _draw_cooldown_overlay(center: Vector2, radius: float, fill_ratio: float) -> void:
	var clamped_ratio: float = clampf(fill_ratio, 0.0, 1.0)
	if clamped_ratio <= 0.001:
		return
	if clamped_ratio >= 0.999:
		draw_circle(center, radius, Color(0.14, 0.14, 0.16, 0.62))
		draw_arc(center, radius, 0.0, TAU, 32, Color(0.72, 0.72, 0.78, 0.24), 1.2)
		return
	var start_angle: float = -PI * 0.5
	var sweep: float = TAU * clamped_ratio
	var steps: int = max(10, int(42.0 * clamped_ratio))
	var points: PackedVector2Array = PackedVector2Array([center])
	for i in range(steps + 1):
		var angle: float = start_angle + sweep * (float(i) / float(max(steps, 1)))
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	draw_colored_polygon(points, Color(0.14, 0.14, 0.16, 0.62))
	draw_arc(center, radius, start_angle, start_angle + sweep, max(18, steps), Color(0.72, 0.72, 0.78, 0.24), 1.2)

func _draw_charge_pips(center: Vector2, radius: float, total: int, filled: int) -> void:
	if total <= 0:
		return
	for i in range(total):
		var t: float = 0.5 if total <= 1 else float(i) / float(total - 1)
		var angle: float = lerpf(PI * 0.78, PI * 0.22, t)
		var pip_center: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius
		var is_filled: bool = i < filled
		var pip_radius: float = 3.0
		var fill_color: Color = accent_color if is_filled else Color(0.18, 0.24, 0.34, 0.98)
		var outline_color: Color = Color(0.96, 0.98, 1.0, 0.9) if is_filled else Color(0.48, 0.58, 0.72, 0.92)
		draw_circle(pip_center, pip_radius + 1.2, Color(0.02, 0.04, 0.07, 0.44))
		draw_circle(pip_center, pip_radius, fill_color)
		draw_arc(pip_center, pip_radius, 0.0, TAU, 18, outline_color, 1.2)

func _draw_power_shot(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(-radius * 0.2, 0.0), radius * 0.6, -1.0, 1.0, 12, primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.15, 0.0), center + Vector2(radius * 0.7, 0.0), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.32, -radius * 0.22), center + Vector2(radius * 0.7, 0.0), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.32, radius * 0.22), center + Vector2(radius * 0.7, 0.0), accent_color, line_width)

func _draw_bow(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(-radius * 0.1, 0.0), radius * 0.64, -1.18, 1.18, 14, primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.34, -radius * 0.52), center + Vector2(-radius * 0.34, radius * 0.52), accent_color, line_width)
	draw_line(center + Vector2(-radius * 0.1, 0.0), center + Vector2(radius * 0.72, 0.0), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.38, -radius * 0.18), center + Vector2(radius * 0.72, 0.0), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.38, radius * 0.18), center + Vector2(radius * 0.72, 0.0), accent_color, line_width)

func _draw_arrow_volley(center: Vector2, radius: float) -> void:
	for i in range(3):
		var y_offset: float = (float(i) - 1.0) * radius * 0.28
		draw_line(center + Vector2(-radius * 0.52, y_offset), center + Vector2(radius * 0.44, y_offset), primary_color, line_width)
		draw_line(center + Vector2(radius * 0.12, y_offset - radius * 0.14), center + Vector2(radius * 0.44, y_offset), accent_color, line_width)
		draw_line(center + Vector2(radius * 0.12, y_offset + radius * 0.14), center + Vector2(radius * 0.44, y_offset), accent_color, line_width)

func _draw_arrow_storm(center: Vector2, radius: float) -> void:
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		var start: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.12)
		var end: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.76)
		draw_line(start, end, primary_color, line_width)
		var head_base: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.46)
		draw_line(head_base + Vector2.RIGHT.rotated(angle - 0.24) * (radius * 0.18), end, accent_color, line_width)
		draw_line(head_base + Vector2.RIGHT.rotated(angle + 0.24) * (radius * 0.18), end, accent_color, line_width)
	draw_circle(center, radius * 0.14, accent_color)

func _draw_explosive_volley(center: Vector2, radius: float) -> void:
	_draw_arrow_volley(center + Vector2(-radius * 0.12, 0.0), radius * 0.74)
	draw_circle(center + Vector2(radius * 0.36, 0.0), radius * 0.18, accent_color)
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		draw_line(
			center + Vector2(radius * 0.36, 0.0),
			center + Vector2(radius * 0.36, 0.0) + Vector2.RIGHT.rotated(angle) * (radius * 0.34),
			primary_color,
			line_width
		)

func _draw_dash(center: Vector2, radius: float) -> void:
	for i in range(3):
		var offset: float = (float(i) - 1.0) * radius * 0.28
		draw_line(center + Vector2(offset - radius * 0.18, radius * 0.18), center + Vector2(offset + radius * 0.08, 0.0), primary_color, line_width)
		draw_line(center + Vector2(offset - radius * 0.18, -radius * 0.18), center + Vector2(offset + radius * 0.08, 0.0), accent_color, line_width)

func _draw_dash_charge(center: Vector2, radius: float) -> void:
	_draw_dash(center + Vector2(-radius * 0.18, 0.0), radius * 0.72)
	draw_circle(center + Vector2(radius * 0.44, -radius * 0.16), radius * 0.22, accent_color)
	draw_circle(center + Vector2(radius * 0.44, -radius * 0.16), radius * 0.1, primary_color)

func _draw_sentinel(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(-radius * 0.08, 0.0), radius * 0.48, 2.4, 3.95, 12, primary_color, line_width)
	draw_arc(center + Vector2(-radius * 0.08, 0.0), radius * 0.48, -0.8, 0.75, 12, accent_color, line_width)
	draw_line(center + Vector2(-radius * 0.1, 0.0), center + Vector2(radius * 0.55, 0.0), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.16, -radius * 0.16), center + Vector2(radius * 0.62, 0.0), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.16, radius * 0.16), center + Vector2(radius * 0.62, 0.0), accent_color, line_width)
	draw_circle(center + Vector2(radius * 0.06, -radius * 0.04), radius * 0.07, accent_color)

func _draw_fire(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(0.0, radius * 0.14), radius * 0.18, accent_color)
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(0.0, -radius * 0.82),
			center + Vector2(radius * 0.3, -radius * 0.2),
			center + Vector2(radius * 0.08, radius * 0.58),
			center + Vector2(-radius * 0.14, radius * 0.16),
			center + Vector2(-radius * 0.42, radius * 0.74),
			center + Vector2(-radius * 0.34, -radius * 0.08),
		]),
		primary_color
	)

func _draw_ice(center: Vector2, radius: float) -> void:
	for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
		var axis: Vector2 = Vector2.RIGHT.rotated(angle) * radius * 0.72
		draw_line(center - axis, center + axis, primary_color, line_width)
	draw_arc(center, radius * 0.22, 0.0, TAU, 12, accent_color, line_width)

func _draw_lightning(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.18, -radius * 0.74), center + Vector2(radius * 0.08, -radius * 0.18), accent_color, line_width + 0.4)
	draw_line(center + Vector2(radius * 0.08, -radius * 0.18), center + Vector2(-radius * 0.04, -radius * 0.02), primary_color, line_width + 0.4)
	draw_line(center + Vector2(-radius * 0.04, -radius * 0.02), center + Vector2(radius * 0.24, radius * 0.12), primary_color, line_width + 0.4)
	draw_line(center + Vector2(radius * 0.24, radius * 0.12), center + Vector2(-radius * 0.02, radius * 0.76), accent_color, line_width + 0.4)

func _draw_entangle(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.12, accent_color)
	draw_arc(center, radius * 0.72, 0.1, 2.7, 16, primary_color, line_width)
	draw_arc(center, radius * 0.54, 2.8, 5.6, 16, primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.2, radius * 0.62), center + Vector2(-radius * 0.38, radius * 0.85), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.24, radius * 0.56), center + Vector2(radius * 0.42, radius * 0.84), accent_color, line_width)

func _draw_frenzy(center: Vector2, radius: float) -> void:
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.22)
		var outer: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.82)
		var tint: Color = accent_color if i % 2 == 0 else primary_color
		draw_line(inner, outer, tint, line_width)
	draw_circle(center, radius * 0.2, primary_color)

func _draw_pistol(center: Vector2, radius: float) -> void:
	draw_rect(Rect2(center + Vector2(-radius * 0.45, -radius * 0.18), Vector2(radius * 0.74, radius * 0.28)), primary_color)
	draw_rect(Rect2(center + Vector2(-radius * 0.12, -radius * 0.02), Vector2(radius * 0.18, radius * 0.48)), accent_color)
	draw_rect(Rect2(center + Vector2(radius * 0.28, -radius * 0.08), Vector2(radius * 0.18, radius * 0.08)), accent_color)

func _draw_missiles(center: Vector2, radius: float) -> void:
	for i in range(3):
		var angle: float = -0.48 + float(i) * 0.48
		var tail: Vector2 = center + Vector2(-radius * 0.38, 0.0).rotated(angle)
		var head: Vector2 = center + Vector2(radius * 0.42, 0.0).rotated(angle)
		draw_line(tail, head, primary_color, line_width)
		draw_circle(head, radius * 0.12, accent_color)

func _draw_sniper(center: Vector2, radius: float) -> void:
	draw_arc(center, radius * 0.74, 0.0, TAU, 20, primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.86, 0.0), center + Vector2(radius * 0.86, 0.0), accent_color, line_width)
	draw_line(center + Vector2(0.0, -radius * 0.86), center + Vector2(0.0, radius * 0.86), accent_color, line_width)
	draw_circle(center, radius * 0.14, accent_color)

func _draw_ricochet(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.68, 0.0), center + Vector2(radius * 0.16, 0.0), primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.04, -radius * 0.18), center + Vector2(radius * 0.2, 0.0), accent_color, line_width)
	draw_line(center + Vector2(-radius * 0.04, radius * 0.18), center + Vector2(radius * 0.2, 0.0), accent_color, line_width)
	draw_arc(center + Vector2(radius * 0.14, 0.0), radius * 0.42, -0.8, 1.45, 14, primary_color, line_width)
	draw_line(center + Vector2(radius * 0.46, radius * 0.26), center + Vector2(radius * 0.7, radius * 0.08), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.46, radius * 0.26), center + Vector2(radius * 0.42, -radius * 0.02), accent_color, line_width)

func _draw_deadeye_bloom(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.16, accent_color)
	for i in range(4):
		var angle: float = PI * 0.25 + TAU * float(i) / 4.0
		var tip: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.78)
		var mid: Vector2 = center + Vector2.RIGHT.rotated(angle) * (radius * 0.32)
		draw_line(mid, tip, primary_color, line_width)
		draw_line(mid + Vector2.RIGHT.rotated(angle - 0.26) * (radius * 0.12), tip, accent_color, line_width)
		draw_line(mid + Vector2.RIGHT.rotated(angle + 0.26) * (radius * 0.12), tip, accent_color, line_width)

func _draw_damage(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.6, radius * 0.55), center + Vector2(radius * 0.02, -radius * 0.72), accent_color, line_width + 0.6)
	draw_line(center + Vector2(-radius * 0.06, -radius * 0.12), center + Vector2(radius * 0.54, -radius * 0.58), primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.18, radius * 0.18), center + Vector2(radius * 0.42, radius * 0.62), primary_color, line_width)

func _draw_attack_speed(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.72, -radius * 0.2), center + Vector2(radius * 0.5, -radius * 0.2), primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.72, radius * 0.22), center + Vector2(radius * 0.5, radius * 0.22), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.18, -radius * 0.44), center + Vector2(radius * 0.5, -radius * 0.2), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.18, 0.04 * radius), center + Vector2(radius * 0.5, radius * 0.22), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.18, -radius * 0.04), center + Vector2(radius * 0.5, -radius * 0.2), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.18, radius * 0.42), center + Vector2(radius * 0.5, radius * 0.22), accent_color, line_width)

func _draw_default(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.18, accent_color)
	draw_arc(center, radius * 0.52, 0.0, TAU, 18, primary_color, line_width)
