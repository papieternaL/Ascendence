extends Node2D

## Bark Volley AOE - circular telegraphed zone, detonates and deals damage.

@export var radius: float = 55.0
@export var damage: float = 250.0
@export var telegraph_duration: float = 0.9
@export var impact_duration: float = 0.25

var _state: String = "telegraph"
var _telegraph_timer: float = 0.0
var _impact_timer: float = 0.0
var _damage_dealt: bool = false

func setup(center_position: Vector2) -> void:
	global_position = center_position

func _process(delta: float) -> void:
	match _state:
		"telegraph":
			_telegraph_timer += delta
			if _telegraph_timer >= telegraph_duration:
				_state = "impact"
				_impact_timer = 0.0
		"impact":
			_impact_timer += delta
			if _impact_timer >= impact_duration:
				queue_free()
	queue_redraw()

func _draw() -> void:
	match _state:
		"telegraph":
			var pulse: float = sin(_telegraph_timer * 12.0) * 0.25 + 0.75
			var alpha: float = minf(1.0, _telegraph_timer / 0.2)
			draw_circle(Vector2.ZERO, radius * 1.2, Color(0.8, 0.4, 0.1, 0.25 * alpha * pulse))
			draw_circle(Vector2.ZERO, radius, Color(0.9, 0.5, 0.15, 0.5 * alpha * pulse))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.6, 0.2, 0.9 * alpha * pulse))
		"impact":
			var progress: float = _impact_timer / impact_duration
			var ring_r: float = radius * (1.0 + progress * 0.5)
			var a: float = 1.0 - progress
			draw_circle(Vector2.ZERO, ring_r, Color(1.0, 0.5, 0.2, a * 0.6))
			draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, Color(1.0, 0.7, 0.3, a * 0.9))

func is_in_impact_phase() -> bool:
	return _state == "impact"

func get_impact_elapsed() -> float:
	return _impact_timer

func get_radius() -> float:
	return radius

func is_finished() -> bool:
	return is_queued_for_deletion()

func get_damage_if_player_hit(player_pos: Vector2) -> float:
	if _damage_dealt:
		return 0.0
	if _state != "impact" or _impact_timer >= 0.12:
		return 0.0
	if global_position.distance_to(player_pos) <= radius:
		_damage_dealt = true
		return damage
	return 0.0
