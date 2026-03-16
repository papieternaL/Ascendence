extends Control

@export var icon_id: String = "default"
@export var primary_color: Color = Color(0.83, 0.9, 1.0, 1.0)
@export var accent_color: Color = Color(0.97, 0.77, 0.3, 1.0)
@export var line_width: float = 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func configure(next_icon_id: String, next_primary: Color = Color(0.83, 0.9, 1.0, 1.0), next_accent: Color = Color(0.97, 0.77, 0.3, 1.0)) -> void:
	icon_id = next_icon_id
	primary_color = next_primary
	accent_color = next_accent
	queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var center: Vector2 = rect.get_center()
	var radius: float = min(rect.size.x, rect.size.y) * 0.42
	draw_circle(center, radius, Color(0.08, 0.12, 0.16, 0.84))
	draw_arc(center, radius, 0.0, TAU, 24, Color(0.2, 0.28, 0.36, 1.0), 1.6)
	match icon_id:
		"power_shot":
			_draw_power_shot(center, radius)
		"dash", "blink", "move":
			_draw_dash(center, radius)
		"entangle", "entangle_upgrade":
			_draw_entangle(center, radius)
		"frenzy", "frenzy_upgrade", "crit":
			_draw_frenzy(center, radius)
		"pistol":
			_draw_pistol(center, radius)
		"missiles", "arcane":
			_draw_missiles(center, radius)
		"sniper", "pierce":
			_draw_sniper(center, radius)
		"damage":
			_draw_damage(center, radius)
		"attack_speed":
			_draw_attack_speed(center, radius)
		"default":
			_draw_default(center, radius)
		_:
			_draw_default(center, radius)

func _draw_power_shot(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(-radius * 0.2, 0.0), radius * 0.6, -1.0, 1.0, 12, primary_color, line_width)
	draw_line(center + Vector2(-radius * 0.15, 0.0), center + Vector2(radius * 0.7, 0.0), primary_color, line_width)
	draw_line(center + Vector2(radius * 0.32, -radius * 0.22), center + Vector2(radius * 0.7, 0.0), accent_color, line_width)
	draw_line(center + Vector2(radius * 0.32, radius * 0.22), center + Vector2(radius * 0.7, 0.0), accent_color, line_width)

func _draw_dash(center: Vector2, radius: float) -> void:
	for i in range(3):
		var offset: float = (float(i) - 1.0) * radius * 0.28
		draw_line(center + Vector2(offset - radius * 0.18, radius * 0.18), center + Vector2(offset + radius * 0.08, 0.0), primary_color, line_width)
		draw_line(center + Vector2(offset - radius * 0.18, -radius * 0.18), center + Vector2(offset + radius * 0.08, 0.0), accent_color, line_width)

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
