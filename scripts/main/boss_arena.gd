extends Node2D

const FLOOR_TEXTURE: Texture2D = preload("res://assets/forest/Winlu exterior remaster/Fantasy_Tileset_red_Edition_upgrade/tilesets/Fantasy_Outside_A5_red.png")
const DECOR_TEXTURE: Texture2D = preload("res://assets/forest/Winlu exterior remaster/Fantasy_Tileset_red_Edition_upgrade/tilesets/Fantasy_Outside_D_red_NoShadow.png")

const MAP_SCALE: float = 1.25
const VIEWPORT_SIZE: Vector2 = Vector2(2400, 1350)
## ~25% larger boss arena (same center as previous rect).
const ARENA_RECT: Rect2 = Rect2(
	960.0 - 720.0 * MAP_SCALE,
	540.0 - 380.0 * MAP_SCALE,
	1440.0 * MAP_SCALE,
	760.0 * MAP_SCALE
)
const PLAYER_SPAWN: Vector2 = Vector2(960, 760 + 95.0)
const BOSS_SPAWN: Vector2 = Vector2(960, 360 + 40.0)

const FLOOR_REGION: Rect2 = Rect2(240, 96, 96, 96)
const MIN_SMALL_ROCK_SPACING: float = 56.0

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

func get_player_spawn_position() -> Vector2:
	return PLAYER_SPAWN

func get_boss_spawn_position() -> Vector2:
	return BOSS_SPAWN

func get_random_arena_position() -> Vector2:
	var x: float = ARENA_RECT.position.x + randf() * ARENA_RECT.size.x
	var y: float = ARENA_RECT.position.y + randf() * ARENA_RECT.size.y
	return Vector2(x, y)

func get_arena_rect() -> Rect2:
	return ARENA_RECT

func get_spawn_bounds() -> Rect2:
	return ARENA_RECT

func get_lane_centers(count: int = 5) -> Array[float]:
	var centers: Array[float] = []
	var divisor: float = float(max(count, 1) + 1)
	for i in range(count):
		centers.append(ARENA_RECT.position.y + ARENA_RECT.size.y * float(i + 1) / divisor)
	return centers

func clamp_position(position: Vector2) -> Vector2:
	return Vector2(
		clamp(position.x, ARENA_RECT.position.x, ARENA_RECT.end.x),
		clamp(position.y, ARENA_RECT.position.y, ARENA_RECT.end.y)
	)

func apply_camera_limits(camera: Camera2D) -> void:
	if camera == null:
		return
	camera.limit_left = int(ARENA_RECT.position.x - 120.0)
	camera.limit_top = int(ARENA_RECT.position.y - 120.0)
	camera.limit_right = int(ARENA_RECT.end.x + 120.0)
	camera.limit_bottom = int(ARENA_RECT.end.y + 120.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.02, 0.02, 0.02, 1.0), true)
	draw_rect(ARENA_RECT.grow(180.0), Color(0.04, 0.02, 0.02, 1.0), true)
	_draw_floor()
	draw_arc(Vector2(960, 510), 188.0, 0.0, TAU, 72, Color(0.72, 0.26, 0.22, 0.46), 18.0)
	draw_arc(Vector2(960, 510), 86.0, 0.0, TAU, 56, Color(0.94, 0.68, 0.3, 0.36), 12.0)
	for rock in [
		Vector2(360, 280), Vector2(1540, 280), Vector2(330, 780), Vector2(1590, 780),
		Vector2(610, 220), Vector2(1310, 220), Vector2(540, 880), Vector2(1380, 880)
	]:
		_draw_rock(rock, 1.3)
	var small_rock_positions: Array = _filter_positions([
		Vector2(300, 220), Vector2(450, 210), Vector2(700, 210), Vector2(1220, 210), Vector2(1470, 220), Vector2(1620, 220),
		Vector2(280, 380), Vector2(430, 470), Vector2(1490, 470), Vector2(1640, 380),
		Vector2(260, 650), Vector2(430, 760), Vector2(700, 840), Vector2(1220, 840), Vector2(1490, 760), Vector2(1660, 650),
		Vector2(340, 900), Vector2(520, 890), Vector2(1400, 890), Vector2(1580, 900),
	], MIN_SMALL_ROCK_SPACING)
	for rock in small_rock_positions:
		_draw_rock(rock, 0.7)
	for cinder in [
		Vector2(420, 330), Vector2(530, 320), Vector2(690, 300), Vector2(1230, 300), Vector2(1390, 320), Vector2(1500, 330),
		Vector2(360, 620), Vector2(520, 700), Vector2(700, 740), Vector2(1220, 740), Vector2(1400, 700), Vector2(1560, 620),
		Vector2(590, 470), Vector2(1330, 470), Vector2(520, 540), Vector2(1400, 540),
	]:
		_draw_cinder_cluster(cinder)
	for point in [Vector2(520, 510), Vector2(1400, 510), Vector2(960, 210), Vector2(960, 905)]:
		draw_arc(point, 42.0, 0.0, TAU, 32, Color(0.48, 0.16, 0.14, 0.58), 8.0)

func _draw_floor() -> void:
	if FLOOR_TEXTURE == null:
		draw_rect(ARENA_RECT, Color(0.06, 0.04, 0.04, 1.0), true)
		return
	var tile_w: float = FLOOR_REGION.size.x
	var tile_h: float = FLOOR_REGION.size.y
	var start_x: int = int(ARENA_RECT.position.x) - int(tile_w)
	var end_x: int = int(ARENA_RECT.end.x) + int(tile_w)
	var start_y: int = int(ARENA_RECT.position.y) - int(tile_h)
	var end_y: int = int(ARENA_RECT.end.y) + int(tile_h)
	var x: int = start_x
	while x < end_x:
		var y: int = start_y
		while y < end_y:
			draw_texture_rect_region(FLOOR_TEXTURE, Rect2(float(x), float(y), tile_w, tile_h), FLOOR_REGION)
			y += int(tile_h)
		x += int(tile_w)

func _draw_rock(position: Vector2, scale_factor: float) -> void:
	if DECOR_TEXTURE == null:
		draw_circle(position, 20.0 * scale_factor, Color(0.38, 0.32, 0.34, 1.0))
		return
	var source: Rect2 = Rect2(8 * 48, 5 * 48, 48, 48)
	var size: Vector2 = Vector2(48, 48) * scale_factor
	draw_texture_rect_region(DECOR_TEXTURE, Rect2(position - size * 0.5, size), source)

func _draw_cinder_cluster(position: Vector2) -> void:
	for offset in [Vector2.ZERO, Vector2(10, -4), Vector2(-7, 7), Vector2(15, 10), Vector2(-12, -6)]:
		draw_circle(position + offset, 2.0, Color(0.26, 0.08, 0.06, 0.45))
		draw_circle(position + offset + Vector2(1, -1), 1.1, Color(0.76, 0.34, 0.16, 0.35))
