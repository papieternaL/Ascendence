extends Node2D

## Falling trunk hazard - telegraph, fall, impact. Deals damage if player in radius during impact.

@export var damage: float = 600.0
@export var telegraph_duration: float = 1.2
@export var falling_duration: float = 0.4
@export var impact_radius: float = 50.0

var _state: String = "telegraph"
var _telegraph_timer: float = 0.0
var _falling_timer: float = 0.0
var _impact_timer: float = 0.0
var _fall_start_y: float = -100.0
var _current_y: float = -100.0
var _target_y: float = 0.0
var _impact_dealt: bool = false

func setup(target_position: Vector2) -> void:
	global_position = target_position
	_target_y = target_position.y
	_fall_start_y = target_position.y - 400.0
	_current_y = _fall_start_y

func _process(delta: float) -> void:
	match _state:
		"telegraph":
			_telegraph_timer += delta
			if _telegraph_timer >= telegraph_duration:
				_state = "falling"
				_falling_timer = 0.0
				_current_y = _fall_start_y
		"falling":
			_falling_timer += delta
			var progress: float = _falling_timer / falling_duration
			progress = progress * progress
			_current_y = _fall_start_y + (_target_y - _fall_start_y) * progress
			if _falling_timer >= falling_duration:
				_state = "impact"
				_impact_timer = 0.0
				_current_y = _target_y
		"impact":
			_impact_timer += delta
			if _impact_timer >= 0.3:
				queue_free()
	queue_redraw()

func _draw() -> void:
	match _state:
		"telegraph":
			var pulse: float = sin(_telegraph_timer * 10.0) * 0.3 + 0.7
			var alpha: float = minf(1.0, _telegraph_timer / 0.3)
			draw_circle(Vector2.ZERO, 45.0 * 1.5, Color(1.0, 0.2, 0.2, 0.2 * alpha * pulse))
			draw_circle(Vector2.ZERO, 45.0, Color(1.0, 0.3, 0.3, 0.5 * alpha * pulse))
			draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 32, Color(1.0, 0.5, 0.2, 0.9 * alpha * pulse))
			draw_line(Vector2(-10, 0), Vector2(10, 0), Color(1.0, 1.0, 0.3, 0.8 * alpha))
			draw_line(Vector2(0, -10), Vector2(0, 10), Color(1.0, 1.0, 0.3, 0.8 * alpha))
		"falling":
			var local_y: float = _current_y - global_position.y
			draw_rect(Rect2(-15.0, local_y - 40.0, 30.0, 80.0), Color(0.45, 0.3, 0.2, 1.0))
		"impact":
			var progress: float = _impact_timer / 0.3
			var ring_r: float = impact_radius * (1.0 + progress * 2.0)
			var a: float = 1.0 - progress
			draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, Color(1.0, 0.6, 0.2, a * 0.6))

func is_player_in_danger(player_pos: Vector2) -> bool:
	if _state != "impact":
		return false
	return global_position.distance_to(player_pos) <= impact_radius

func is_in_impact_phase() -> bool:
	return _state == "impact"

func get_impact_elapsed() -> float:
	return _impact_timer

func get_radius() -> float:
	return impact_radius

func get_damage() -> float:
	return damage

## Returns damage if player is in zone during first 0.1s of impact. Only returns non-zero once.
func get_damage_if_player_hit(player_pos: Vector2) -> float:
	if _impact_dealt:
		return 0.0
	if _state != "impact" or _impact_timer >= 0.1:
		return 0.0
	if global_position.distance_to(player_pos) <= impact_radius:
		_impact_dealt = true
		return damage
	return 0.0
