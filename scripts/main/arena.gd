extends Node2D

const DECOR_TEXTURE: Texture2D = preload("res://assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/tilesets/Fantasy_Outside_D_green_NoShadow.png")

const MAP_SCALE: float = 1.25
const VIEWPORT_CENTER: Vector2 = Vector2(1000, 620)
const ARENA_PAD_X: float = 900.0
const ARENA_PAD_Y: float = 620.0
## Expanded around VIEWPORT_CENTER so gameplay area grows without exposing empty margins.
const ARENA_RECT: Rect2 = Rect2(
	VIEWPORT_CENTER.x - 1420.0 * MAP_SCALE - ARENA_PAD_X,
	VIEWPORT_CENTER.y - 880.0 * MAP_SCALE - ARENA_PAD_Y,
	2840.0 * MAP_SCALE + ARENA_PAD_X * 2.0,
	1760.0 * MAP_SCALE + ARENA_PAD_Y * 2.0
)
const OBJECTIVE_POSITIONS: Array[Vector2] = [
	Vector2(640, 420),
	Vector2(1360, 420),
	Vector2(1000, 700),
	Vector2(640, 1020),
	Vector2(1360, 1020),
]
## Core positions for objective phase (configurable 8-12 core layout).
## Configurable via core_count; positions are selected from this pool.
const CORE_POSITIONS: Array[Vector2] = [
	Vector2(120, 480),
	Vector2(1880, 480),
	Vector2(1000, 10),
	Vector2(400, 200),
	Vector2(1600, 200),
	Vector2(400, 1100),
	Vector2(1600, 1100),
	Vector2(200, 750),
	Vector2(1820, 750),
	Vector2(1000, 1350),
	Vector2(600, 640),
	Vector2(1400, 640),
	Vector2(760, 320),
	Vector2(1240, 320),
	Vector2(760, 980),
	Vector2(1240, 980),
	Vector2(540, 860),
	Vector2(1460, 860),
]
const DEFAULT_CORE_COUNT: int = 18
const MIN_ROCK_SPACING: float = 90.0
const MIN_SMALL_ROCK_SPACING: float = 64.0
const MIN_FLOWER_SPACING: float = 55.0
const MIN_SMALL_FLOWER_SPACING: float = 42.0

@export var core_count: int = DEFAULT_CORE_COUNT

func _filter_positions(positions: Array, min_dist: float) -> Array:
	var result: Array = []
	for pos in positions:
		var p: Vector2 = pos as Vector2
		var ok: bool = true
		for kept in result:
			if p.distance_to(kept as Vector2) < min_dist:
				ok = false
				break
		if ok:
			result.append(p)
	return result

func _ready() -> void:
	queue_redraw()

static func scale_map_point(p: Vector2) -> Vector2:
	return VIEWPORT_CENTER + (p - VIEWPORT_CENTER) * MAP_SCALE

func get_player_spawn_position() -> Vector2:
	return scale_map_point(Vector2(1000, 780))

func get_boss_spawn_position() -> Vector2:
	return scale_map_point(Vector2(1000, 120))

func get_core_positions(requested_count: int = core_count) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var count: int = clamp(requested_count, 1, CORE_POSITIONS.size())
	for i in range(count):
		positions.append(scale_map_point(CORE_POSITIONS[i]))
	return positions

func get_objective_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in OBJECTIVE_POSITIONS:
		out.append(scale_map_point(p))
	return out

func get_spawn_bounds() -> Rect2:
	return ARENA_RECT

func get_random_arena_position(margin: float = 64.0) -> Vector2:
	return Vector2(
		randf_range(ARENA_RECT.position.x + margin, ARENA_RECT.end.x - margin),
		randf_range(ARENA_RECT.position.y + margin, ARENA_RECT.end.y - margin)
	)

func clamp_position(position: Vector2) -> Vector2:
	return Vector2(
		clamp(position.x, ARENA_RECT.position.x, ARENA_RECT.end.x),
		clamp(position.y, ARENA_RECT.position.y, ARENA_RECT.end.y)
	)

func apply_camera_limits(camera: Camera2D) -> void:
	if camera == null:
		return
	camera.limit_left = int(ARENA_RECT.position.x - 140.0)
	camera.limit_top = int(ARENA_RECT.position.y - 140.0)
	camera.limit_right = int(ARENA_RECT.end.x + 140.0)
	camera.limit_bottom = int(ARENA_RECT.end.y + 160.0)

func _draw() -> void:
	draw_rect(ARENA_RECT.grow(900.0), Color(0.03, 0.06, 0.05, 1.0), true)
	draw_rect(ARENA_RECT.grow(260.0), Color(0.08, 0.18, 0.12, 1.0), true)
	_draw_floor()

	for patch in [
		{"position": Vector2(120, 110), "radius": Vector2(210, 120), "color": Color(0.18, 0.28, 0.16, 0.18)},
		{"position": Vector2(1840, 150), "radius": Vector2(180, 105), "color": Color(0.18, 0.28, 0.16, 0.16)},
		{"position": Vector2(160, 1240), "radius": Vector2(240, 92), "color": Color(0.18, 0.28, 0.16, 0.16)},
		{"position": Vector2(1800, 1240), "radius": Vector2(230, 88), "color": Color(0.18, 0.28, 0.16, 0.16)},
		{"position": Vector2(1000, 640), "radius": Vector2(280, 145), "color": Color(0.24, 0.34, 0.18, 0.10)},
	]:
		_draw_soft_patch(scale_map_point(patch.position), patch.radius * MAP_SCALE, patch.color)

	var rock_positions: Array = _filter_positions([
		Vector2(40, 300), Vector2(1860, 250), Vector2(320, 980), Vector2(1680, 980),
		Vector2(720, 1260), Vector2(1280, 1220), Vector2(-120, 760), Vector2(2020, 810),
		Vector2(620, 180), Vector2(1425, 210), Vector2(560, 610), Vector2(1480, 640), Vector2(2240, 610),
		Vector2(260, 1450), Vector2(1790, 1450),
	], MIN_ROCK_SPACING)
	for rock in rock_positions:
		_draw_rock(scale_map_point(rock))

	var small_rock_positions: Array = _filter_positions([
		Vector2(120, 190), Vector2(280, 250), Vector2(520, 210), Vector2(760, 140),
		Vector2(1180, 180), Vector2(1470, 210), Vector2(1700, 250), Vector2(1885, 190),
		Vector2(210, 470), Vector2(430, 560), Vector2(690, 520), Vector2(1300, 540),
		Vector2(1550, 560), Vector2(1785, 500), Vector2(110, 860), Vector2(320, 910),
		Vector2(600, 1080), Vector2(960, 1110), Vector2(1360, 1090), Vector2(1650, 930),
		Vector2(1880, 880), Vector2(290, 1290), Vector2(560, 1360), Vector2(1460, 1360),
		Vector2(1710, 1280), Vector2(2050, 1180),
	], MIN_SMALL_ROCK_SPACING)
	for rock in small_rock_positions:
		_draw_rock(scale_map_point(rock), 0.72)

	var flower_positions: Array = _filter_positions([
		Vector2(440, 260), Vector2(1430, 300), Vector2(390, 760), Vector2(1570, 760),
		Vector2(1000, 1070), Vector2(140, 560), Vector2(1810, 560), Vector2(820, 650), Vector2(1160, 650),
		Vector2(120, 1130), Vector2(1830, 1120), Vector2(2140, 260), Vector2(620, 1320), Vector2(1310, 1350)
	], MIN_FLOWER_SPACING)
	for flower in flower_positions:
		_draw_flower_cluster(scale_map_point(flower))

	var small_flower_positions: Array = _filter_positions([
		Vector2(250, 150), Vector2(360, 220), Vector2(540, 280), Vector2(690, 240), Vector2(840, 180),
		Vector2(1080, 220), Vector2(1250, 270), Vector2(1500, 300), Vector2(1680, 220), Vector2(1940, 150),
		Vector2(240, 420), Vector2(510, 470), Vector2(760, 440), Vector2(1240, 450), Vector2(1500, 480),
		Vector2(1760, 430), Vector2(250, 690), Vector2(520, 760), Vector2(740, 710), Vector2(1260, 730),
		Vector2(1490, 760), Vector2(1740, 700), Vector2(280, 980), Vector2(520, 1030), Vector2(760, 980),
		Vector2(1210, 980), Vector2(1450, 1030), Vector2(1700, 980), Vector2(300, 1220), Vector2(520, 1260),
		Vector2(820, 1220), Vector2(1160, 1240), Vector2(1480, 1260), Vector2(1700, 1220),
	], MIN_SMALL_FLOWER_SPACING)
	for flower in small_flower_positions:
		_draw_flower_cluster(scale_map_point(flower), 0.72)

func _draw_floor() -> void:
	var clearing: Vector2 = scale_map_point(Vector2(1000, 780))
	draw_rect(ARENA_RECT, Color(0.31, 0.60, 0.34, 1.0), true)
	for patch in [
		{"position": Vector2(90, 90), "radius": Vector2(220, 88), "color": Color(0.23, 0.48, 0.27, 0.18)},
		{"position": Vector2(1880, 84), "radius": Vector2(180, 84), "color": Color(0.23, 0.48, 0.27, 0.16)},
		{"position": Vector2(240, 970), "radius": Vector2(220, 96), "color": Color(0.24, 0.49, 0.29, 0.18)},
		{"position": Vector2(1760, 980), "radius": Vector2(220, 96), "color": Color(0.24, 0.49, 0.29, 0.18)},
		{"position": Vector2(960, 460), "radius": Vector2(230, 120), "color": Color(0.23, 0.47, 0.27, 0.12)},
		{"position": Vector2(970, 1310), "radius": Vector2(240, 92), "color": Color(0.23, 0.49, 0.28, 0.14)},
	]:
		_draw_soft_patch(scale_map_point(patch.position), patch.radius * MAP_SCALE, patch.color)
	for patch in [
		{"position": clearing + Vector2(0, -320) * MAP_SCALE, "radius": Vector2(150, 60) * MAP_SCALE, "color": Color(0.48, 0.56, 0.34, 0.10)},
		{"position": clearing + Vector2(0, -120) * MAP_SCALE, "radius": Vector2(200, 82) * MAP_SCALE, "color": Color(0.46, 0.54, 0.32, 0.10)},
		{"position": clearing + Vector2(0, 120) * MAP_SCALE, "radius": Vector2(210, 88) * MAP_SCALE, "color": Color(0.46, 0.54, 0.32, 0.08)},
	]:
		_draw_soft_patch(patch.position, patch.radius, patch.color)
	_draw_path_strip(scale_map_point(Vector2(1000, 150)), scale_map_point(Vector2(1000, 1380)), 72.0 * MAP_SCALE, Color(0.45, 0.52, 0.31, 0.10))
	_draw_path_strip(scale_map_point(Vector2(760, 760)), scale_map_point(Vector2(1240, 760)), 82.0 * MAP_SCALE, Color(0.45, 0.52, 0.31, 0.08))
	for pos in [
		Vector2(220, 180), Vector2(420, 260), Vector2(620, 1160), Vector2(860, 220),
		Vector2(1140, 260), Vector2(1380, 1180), Vector2(1580, 260), Vector2(1820, 180),
		Vector2(240, 1300), Vector2(1780, 1320), Vector2(2140, 760), Vector2(-120, 760)
	]:
		_draw_grass_tuft(scale_map_point(pos), 14.0 * MAP_SCALE)

func _draw_path_strip(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var dir: Vector2 = (to - from).normalized()
	var normal: Vector2 = Vector2(-dir.y, dir.x) * width
	var polygon: PackedVector2Array = PackedVector2Array([
		from + normal,
		to + normal,
		to - normal,
		from - normal,
	])
	draw_colored_polygon(polygon, color)
	for step in range(7):
		var t: float = float(step) / 6.0
		_draw_soft_patch(from.lerp(to, t), Vector2(width * 0.9, width * 0.46), Color(color.r, color.g, color.b, color.a * 0.9))

func _draw_soft_patch(position: Vector2, radius: Vector2, color: Color) -> void:
	for ring in range(4, 0, -1):
		var scale: float = float(ring) / 4.0
		var ring_color: Color = color
		ring_color.a *= 0.35 + (0.18 * float(5 - ring))
		var polygon: PackedVector2Array = PackedVector2Array()
		for point in range(20):
			var angle: float = (TAU * float(point)) / 20.0
			polygon.append(position + Vector2(cos(angle) * radius.x * scale, sin(angle) * radius.y * scale))
		draw_colored_polygon(polygon, ring_color)

func _draw_grass_tuft(position: Vector2, height: float) -> void:
	for blade in [
		Vector2(-6, 0),
		Vector2(-2, -2),
		Vector2(2, -1),
		Vector2(6, 1),
	]:
		draw_line(
			position + blade,
			position + Vector2(blade.x * 0.35, -height + blade.y),
			Color(0.2, 0.46, 0.24, 0.3),
			2.0
		)

func _draw_rock(position: Vector2, scale_factor: float = 1.0) -> void:
	draw_circle(position + Vector2(4, 12) * scale_factor, 16.0 * scale_factor, Color(0.05, 0.1, 0.08, 0.18))
	if DECOR_TEXTURE == null:
		draw_polygon(
			PackedVector2Array([
				position + Vector2(-20, 8) * scale_factor,
				position + Vector2(-8, -14) * scale_factor,
				position + Vector2(15, -18) * scale_factor,
				position + Vector2(26, 4) * scale_factor,
				position + Vector2(8, 18) * scale_factor,
				position + Vector2(-16, 20) * scale_factor,
			]),
			PackedColorArray([
				Color(0.48, 0.54, 0.5, 1.0),
				Color(0.56, 0.62, 0.58, 1.0),
				Color(0.52, 0.6, 0.55, 1.0),
				Color(0.42, 0.5, 0.46, 1.0),
				Color(0.38, 0.46, 0.42, 1.0),
				Color(0.44, 0.52, 0.48, 1.0),
			]),
		)
		return
	var source: Rect2 = Rect2(8 * 48, 5 * 48, 48, 48)
	var size: Vector2 = Vector2(48, 48) * scale_factor
	draw_texture_rect_region(DECOR_TEXTURE, Rect2(position - size * 0.5, size), source)

func _draw_flower_cluster(position: Vector2, scale_factor: float = 1.0) -> void:
	for offset in [Vector2.ZERO, Vector2(10, -6), Vector2(-8, 8), Vector2(14, 10)]:
		var scaled_offset: Vector2 = offset * scale_factor
		draw_circle(position + scaled_offset, 3.0 * scale_factor, Color(0.96, 0.86, 0.54, 1.0))
		draw_circle(position + scaled_offset + Vector2(3, -2) * scale_factor, 2.5 * scale_factor, Color(0.94, 0.7, 0.85, 1.0))
