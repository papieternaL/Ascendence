extends Node2D

const ZONE_SCENE: PackedScene = preload("res://scenes/effects/ArcaneBombZone.tscn")

var _start_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _travel_duration: float = 0.34
var _elapsed: float = 0.0
var _zone_radius: float = 78.0
var _zone_duration: float = 3.4
var _tick_interval: float = 0.45
var _tick_damage: float = 18.0
var _slow_mul: float = 1.18
var _slow_duration: float = 0.7

func setup(config: Dictionary) -> void:
	_start_position = Vector2(config.get("start_position", _start_position))
	_target_position = Vector2(config.get("target_position", _target_position))
	_travel_duration = maxf(float(config.get("travel_duration", _travel_duration)), 0.01)
	_zone_radius = float(config.get("zone_radius", _zone_radius))
	_zone_duration = float(config.get("zone_duration", _zone_duration))
	_tick_interval = float(config.get("tick_interval", _tick_interval))
	_tick_damage = float(config.get("tick_damage", _tick_damage))
	_slow_mul = float(config.get("slow_mul", _slow_mul))
	_slow_duration = float(config.get("slow_duration", _slow_duration))
	global_position = _start_position

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / _travel_duration, 0.0, 1.0)
	global_position = _start_position.lerp(_target_position, t)
	queue_redraw()
	if t >= 1.0:
		_spawn_zone()
		queue_free()

func _spawn_zone() -> void:
	var zone: Node2D = ZONE_SCENE.instantiate() as Node2D
	if zone == null:
		return
	if zone.has_method("setup"):
		zone.call("setup", {
			"position": _target_position,
			"radius": _zone_radius,
			"duration": _zone_duration,
			"tick_interval": _tick_interval,
			"tick_damage": _tick_damage,
			"slow_mul": _slow_mul,
			"slow_duration": _slow_duration,
		})
	get_parent().add_child(zone)

func _draw() -> void:
	var t: float = clampf(_elapsed / _travel_duration, 0.0, 1.0)
	var arc_height: float = sin(t * PI) * 26.0
	var shadow_color: Color = Color(0.10, 0.06, 0.14, 0.22)
	draw_circle(Vector2.ZERO, 7.0, shadow_color)
	draw_circle(Vector2(0.0, -arc_height), 8.0, Color(0.76, 0.38, 1.0, 0.96))
	draw_circle(Vector2(0.0, -arc_height), 5.0, Color(0.96, 0.76, 1.0, 0.72))
	draw_arc(Vector2(0.0, -arc_height), 10.0, 0.0, TAU, 24, Color(0.54, 0.24, 0.92, 0.82), 1.4)
	for i in range(3):
		var offset: Vector2 = Vector2(-10.0 - float(i) * 6.0, -arc_height + (float(i) - 1.0) * 3.0)
		draw_circle(offset, 2.4 - float(i) * 0.4, Color(0.94, 0.72, 1.0, 0.22))
