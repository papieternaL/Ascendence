extends Node2D

@export var speed: float = 320.0
@export var damage: float = 550.0
@export var telegraph_duration: float = 0.9
@export var length: float = 520.0
@export var wave_frequency: float = 0.018
@export var wave_amplitude: float = 22.0
@export var wave_speed: float = 4.0
@export var lane_half_height: float = 28.0

var _arena_rect: Rect2 = Rect2(240.0, 160.0, 1440.0, 760.0)
var _lane_y: float = 540.0
var _state: String = "telegraph"
var _telegraph_timer: float = 0.0
var _wave_time: float = 0.0
var _head_x: float = 0.0
var _tail_x: float = 0.0
var _damage_dealt: bool = false

func _ready() -> void:
	add_to_group("territory_vines")
	_head_x = _arena_rect.end.x + 80.0
	_tail_x = _head_x + length
	queue_redraw()

func setup(arena_rect: Rect2, lane_y: float) -> void:
	_arena_rect = arena_rect
	_lane_y = lane_y
	_head_x = _arena_rect.end.x + 80.0
	_tail_x = _head_x + length

func _process(delta: float) -> void:
	match _state:
		"telegraph":
			_telegraph_timer += delta
			if _telegraph_timer >= telegraph_duration:
				_state = "active"
		"active":
			_wave_time += delta * wave_speed
			_head_x -= speed * delta
			_tail_x -= speed * delta
			if _tail_x < _arena_rect.position.x - 120.0:
				queue_free()
	queue_redraw()

func _draw() -> void:
	if _state == "telegraph":
		var pulse: float = 0.7 + 0.3 * sin(_telegraph_timer * 10.0)
		var alpha: float = minf(1.0, _telegraph_timer / 0.18)
		draw_rect(
			Rect2(
				Vector2(_arena_rect.position.x, _lane_y - lane_half_height * 1.25),
				Vector2(_arena_rect.size.x, lane_half_height * 2.5)
			),
			Color(0.8, 0.24, 0.16, 0.16 * alpha * pulse),
			true
		)
		draw_line(
			Vector2(_arena_rect.position.x, _lane_y),
			Vector2(_arena_rect.end.x, _lane_y),
			Color(0.96, 0.58, 0.26, 0.82 * alpha * pulse),
			3.0,
			true
		)
		return
	var start_x: float = max(_arena_rect.position.x, _head_x)
	var end_x: float = min(_arena_rect.end.x, _tail_x)
	if start_x >= end_x:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 30
	var step: float = (end_x - start_x) / float(segments)
	for i in range(segments + 1):
		var x: float = start_x + step * float(i)
		points.append(Vector2(x, _get_wave_y(x)))
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.14, 0.08, 0.04, 0.92), 22.0, true)
		draw_line(points[i], points[i + 1], Color(0.34, 0.22, 0.1, 0.98), 14.0, true)
		draw_line(points[i], points[i + 1], Color(0.56, 0.38, 0.22, 0.42), 5.0, true)

func get_damage_if_player_hit(player_pos: Vector2) -> float:
	if _damage_dealt or _state != "active":
		return 0.0
	if player_pos.x < max(_arena_rect.position.x, _head_x) or player_pos.x > min(_arena_rect.end.x, _tail_x):
		return 0.0
	var wave_y: float = _get_wave_y(player_pos.x)
	if absf(player_pos.y - wave_y) <= lane_half_height:
		_damage_dealt = true
		return damage
	return 0.0

func _get_wave_y(x: float) -> float:
	return _lane_y + sin(x * wave_frequency + _wave_time) * wave_amplitude
