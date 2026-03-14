extends Node2D

const ARENA_RECT := Rect2(140, 110, 1000, 560)
const PLAYER_SPAWN := Vector2(640, 420)
const BOSS_SPAWN := Vector2(640, 250)
const CORE_POSITIONS: Array[Vector2] = [
	Vector2(430, 300),
	Vector2(850, 300),
	Vector2(640, 205),
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

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.08, 0.18, 0.12, 1.0), true)
	draw_rect(ARENA_RECT.grow(120), Color(0.11, 0.24, 0.15, 1.0), true)
	draw_rect(ARENA_RECT, Color(0.17, 0.34, 0.21, 1.0), true)

	for patch in [
		Rect2(220, 160, 220, 120),
		Rect2(700, 150, 260, 110),
		Rect2(310, 430, 250, 100),
		Rect2(760, 420, 180, 90),
	]:
		draw_rect(patch, Color(0.22, 0.4, 0.24, 0.34), true)

	draw_arc(Vector2(640, 320), 110.0, 0.0, TAU, 40, Color(0.72, 0.84, 0.64, 0.28), 10.0)
	draw_arc(Vector2(640, 320), 42.0, 0.0, TAU, 28, Color(0.12, 0.22, 0.14, 0.7), 20.0)

	for tree in [
		Vector2(180, 150), Vector2(220, 580), Vector2(1110, 170), Vector2(1080, 550),
		Vector2(340, 120), Vector2(930, 600), Vector2(520, 145), Vector2(760, 128),
	]:
		_draw_tree(tree)

	for rock in [
		Vector2(280, 250), Vector2(990, 260), Vector2(340, 520), Vector2(920, 470),
		Vector2(595, 610), Vector2(765, 565), Vector2(170, 420), Vector2(1090, 420),
	]:
		_draw_rock(rock)

	for flower in [
		Vector2(500, 215), Vector2(770, 215), Vector2(445, 445), Vector2(820, 445), Vector2(640, 545), Vector2(305, 360), Vector2(980, 350)
	]:
		_draw_flower_cluster(flower)

func _draw_tree(position: Vector2) -> void:
	draw_circle(position + Vector2(4, 18), 18.0, Color(0.04, 0.1, 0.06, 0.22))
	draw_rect(Rect2(position.x - 6, position.y + 10, 12, 36), Color(0.35, 0.22, 0.1, 1.0), true)
	draw_colored_polygon(
		PackedVector2Array([position + Vector2(0, -30), position + Vector2(-34, 18), position + Vector2(34, 18)]),
		Color(0.16, 0.46, 0.22, 1.0)
	)
	draw_colored_polygon(
		PackedVector2Array([position + Vector2(0, -50), position + Vector2(-24, -2), position + Vector2(24, -2)]),
		Color(0.2, 0.56, 0.28, 1.0)
	)

func _draw_rock(position: Vector2) -> void:
	draw_circle(position + Vector2(4, 12), 14.0, Color(0.05, 0.1, 0.08, 0.18))
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

func _draw_flower_cluster(position: Vector2) -> void:
	for offset in [Vector2.ZERO, Vector2(10, -6), Vector2(-8, 8), Vector2(14, 10)]:
		draw_circle(position + offset, 3.0, Color(0.96, 0.86, 0.54, 1.0))
		draw_circle(position + offset + Vector2(3, -2), 2.5, Color(0.94, 0.7, 0.85, 1.0))
