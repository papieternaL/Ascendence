extends Node2D

const DECOR_TEXTURE: Texture2D = preload("res://assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/tilesets/Fantasy_Outside_D_green_NoShadow.png")
const TREES_TEXTURE: Texture2D = preload("res://assets/forest/Winlu exterior remaster/Fantasy_Tileset_Green_Edition_upgrade/characters/!$Big_Trees_green_NoShadow.png")
const TREE_SOURCE_REGIONS: Array[Rect2] = [
	Rect2(0.0, 0.0, 192.0, 288.0),
	Rect2(192.0, 0.0, 192.0, 288.0),
	Rect2(384.0, 0.0, 192.0, 288.0),
]

const VIEWPORT_SIZE: Vector2 = Vector2(1920, 1080)
const ARENA_RECT: Rect2 = Rect2(-420, -260, 2840, 1760)
const PLAYER_SPAWN: Vector2 = Vector2(1000, 780)
const BOSS_SPAWN: Vector2 = Vector2(1000, 120)
const CORE_POSITIONS: Array[Vector2] = [
	Vector2(120, 480),
	Vector2(1880, 480),
	Vector2(1000, 10),
]

func _ready() -> void:
	queue_redraw()

func get_player_spawn_position() -> Vector2:
	return PLAYER_SPAWN

func get_boss_spawn_position() -> Vector2:
	return BOSS_SPAWN

func get_core_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for point in CORE_POSITIONS:
		positions.append(point)
	return positions

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
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.08, 0.18, 0.12, 1.0), true)
	draw_rect(ARENA_RECT.grow(220), Color(0.1, 0.22, 0.14, 1.0), true)
	_draw_floor()

	for patch in [
		Rect2(-120, 50, 520, 240),
		Rect2(1590, 80, 520, 250),
		Rect2(-40, 1110, 620, 180),
		Rect2(1440, 1100, 560, 190),
		Rect2(690, 560, 660, 250),
	]:
		draw_rect(patch, Color(0.22, 0.4, 0.24, 0.34), true)

	draw_arc(Vector2(1000, 480), 186.0, 0.0, TAU, 56, Color(0.72, 0.84, 0.64, 0.28), 12.0)
	draw_arc(Vector2(1000, 480), 62.0, 0.0, TAU, 32, Color(0.12, 0.22, 0.14, 0.7), 24.0)

	for tree in [
		Vector2(-260, -70), Vector2(40, 40), Vector2(260, 1320), Vector2(2190, 20), Vector2(2020, 1380),
		Vector2(470, -20), Vector2(1780, 10), Vector2(780, -40), Vector2(1360, -30), Vector2(1940, 430),
		Vector2(-120, 600), Vector2(2180, 760), Vector2(250, 1150), Vector2(1710, 1180), Vector2(2340, 1020),
		Vector2(1010, -70), Vector2(1040, 1400), Vector2(-310, 980), Vector2(2280, 970), Vector2(620, 1430),
		Vector2(1450, 1420), Vector2(230, 230), Vector2(1850, 240), Vector2(60, 1500), Vector2(2140, 1500),
	]:
		_draw_tree(tree, int(abs(tree.x + tree.y)) % TREE_SOURCE_REGIONS.size())

	for rock in [
		Vector2(40, 300), Vector2(1860, 250), Vector2(320, 980), Vector2(1680, 980),
		Vector2(720, 1260), Vector2(1280, 1220), Vector2(-120, 760), Vector2(2020, 810),
		Vector2(620, 180), Vector2(1425, 210), Vector2(560, 610), Vector2(1480, 640), Vector2(2240, 610),
		Vector2(260, 1450), Vector2(1790, 1450),
	]:
		_draw_rock(rock)

	for flower in [
		Vector2(440, 260), Vector2(1430, 300), Vector2(390, 760), Vector2(1570, 760),
		Vector2(1000, 1070), Vector2(140, 560), Vector2(1810, 560), Vector2(820, 650), Vector2(1160, 650),
		Vector2(120, 1130), Vector2(1830, 1120), Vector2(2140, 260), Vector2(620, 1320), Vector2(1310, 1350)
	]:
		_draw_flower_cluster(flower)

func _draw_floor() -> void:
	draw_rect(ARENA_RECT, Color(0.28, 0.58, 0.33, 1.0), true)
	for patch in [
		Rect2(ARENA_RECT.position.x + 110.0, ARENA_RECT.position.y + 140.0, 420.0, 180.0),
		Rect2(ARENA_RECT.position.x + 1640.0, ARENA_RECT.position.y + 150.0, 360.0, 200.0),
		Rect2(ARENA_RECT.position.x + 220.0, ARENA_RECT.position.y + 740.0, 460.0, 190.0),
		Rect2(ARENA_RECT.position.x + 1370.0, ARENA_RECT.position.y + 780.0, 420.0, 190.0),
		Rect2(ARENA_RECT.position.x + 880.0, ARENA_RECT.position.y + 380.0, 420.0, 260.0),
		Rect2(ARENA_RECT.position.x + 720.0, ARENA_RECT.position.y + 1210.0, 460.0, 180.0),
	]:
		draw_rect(patch, Color(0.24, 0.52, 0.29, 0.55), true)
	for i in range(64):
		var x: float = ARENA_RECT.position.x + 40.0 + float((i * 173) % int(ARENA_RECT.size.x - 80.0))
		var y: float = ARENA_RECT.position.y + 30.0 + float((i * 257) % int(ARENA_RECT.size.y - 60.0))
		draw_circle(Vector2(x, y), 2.0 + float(i % 3), Color(0.18, 0.44, 0.24, 0.18))

func _draw_tree(position: Vector2, tree_index: int) -> void:
	draw_circle(position + Vector2(10, 54), 28.0, Color(0.04, 0.1, 0.06, 0.22))
	if TREES_TEXTURE == null:
		draw_rect(Rect2(position.x - 6, position.y + 10, 12, 36), Color(0.35, 0.22, 0.1, 1.0), true)
		return
	var source: Rect2 = TREE_SOURCE_REGIONS[tree_index % TREE_SOURCE_REGIONS.size()]
	var size: Vector2 = source.size
	draw_texture_rect_region(TREES_TEXTURE, Rect2(position - Vector2(size.x * 0.5, size.y * 0.82), size), source)

func _draw_rock(position: Vector2) -> void:
	draw_circle(position + Vector2(4, 12), 16.0, Color(0.05, 0.1, 0.08, 0.18))
	if DECOR_TEXTURE == null:
		draw_polygon(
			PackedVector2Array([
				position + Vector2(-20, 8),
				position + Vector2(-8, -14),
				position + Vector2(15, -18),
				position + Vector2(26, 4),
				position + Vector2(8, 18),
				position + Vector2(-16, 20),
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
	var source: Rect2 = Rect2(8 * 48, 4 * 48, 48, 48)
	draw_texture_rect_region(DECOR_TEXTURE, Rect2(position - Vector2(24, 24), Vector2(48, 48)), source)

func _draw_flower_cluster(position: Vector2) -> void:
	for offset in [Vector2.ZERO, Vector2(10, -6), Vector2(-8, 8), Vector2(14, 10)]:
		draw_circle(position + offset, 3.0, Color(0.96, 0.86, 0.54, 1.0))
		draw_circle(position + offset + Vector2(3, -2), 2.5, Color(0.94, 0.7, 0.85, 1.0))
