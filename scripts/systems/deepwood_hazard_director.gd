extends Node

const FALLING_TRUNK_SCENE: PackedScene = preload("res://scenes/effects/FallingTrunk.tscn")
const WIND_STORM_SCENE: PackedScene = preload("res://scenes/effects/WindStormHazard.tscn")

@export var bark_wave_size: int = 3
@export var bark_safe_radius: float = 90.0
@export var bark_spawn_radius_min: float = 140.0
@export var bark_spawn_radius_max: float = 300.0
@export var bark_damage: float = 240.0
@export var bark_interval_early: float = 9.0
@export var bark_interval_mid: float = 7.0
@export var bark_interval_late: float = 5.5
@export var wind_warning_duration: float = 1.5
@export var wind_active_duration: float = 7.0
@export var wind_interval: float = 18.0
@export var wind_force: float = 90.0

var _player: Node2D
var _arena: Node2D
var _effects: Node2D
var _overlay_parent: Node
var _progress_ratio: float = 0.0
var _run_active: bool = false
var _bark_timer: float = 0.0
var _wind_timer: float = 0.0
var _wind_effect: Node
var _current_wind_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func setup(player: Node2D, arena: Node2D, effects: Node2D, overlay_parent: Node = null) -> void:
	_player = player
	_arena = arena
	_effects = effects
	_overlay_parent = overlay_parent

func set_progress_ratio(value: float) -> void:
	_progress_ratio = clampf(value, 0.0, 1.0)

func set_run_active(active: bool) -> void:
	if _run_active == active:
		return
	_run_active = active
	if not _run_active:
		_clear_active_wind()
		_clear_spawned_hazards()
		_set_player_environment_force(Vector2.ZERO)

func _process(delta: float) -> void:
	if _player == null or _effects == null:
		return
	if not _run_active:
		_set_player_environment_force(Vector2.ZERO)
		return
	_bark_timer += delta
	_wind_timer += delta
	if _bark_timer >= _get_bark_interval():
		_bark_timer = 0.0
		_spawn_bark_wave()
	if (_wind_effect == null or not is_instance_valid(_wind_effect)) and _wind_timer >= wind_interval:
		_wind_timer = 0.0
		_start_wind_storm()
	if _wind_effect != null and is_instance_valid(_wind_effect):
		if _wind_effect.has_method("is_force_active") and bool(_wind_effect.call("is_force_active")):
			_set_player_environment_force(_current_wind_direction * wind_force)
		else:
			_set_player_environment_force(Vector2.ZERO)
		if _wind_effect.has_method("is_finished") and bool(_wind_effect.call("is_finished")):
			_wind_effect = null
			_current_wind_direction = Vector2.ZERO
	else:
		_set_player_environment_force(Vector2.ZERO)

func _get_bark_interval() -> float:
	if _progress_ratio >= 0.75:
		return bark_interval_late
	if _progress_ratio >= 0.25:
		return bark_interval_mid
	return bark_interval_early

func _spawn_bark_wave() -> void:
	if _player == null or _effects == null:
		return
	for _i in range(max(bark_wave_size, 1)):
		var pos: Vector2 = _pick_bark_spawn_position()
		var trunk: Node2D = FALLING_TRUNK_SCENE.instantiate() as Node2D
		if trunk == null:
			continue
		trunk.add_to_group("deepwood_hazard")
		if trunk.has_method("setup"):
			trunk.set("damage", bark_damage)
			trunk.setup(pos)
		else:
			trunk.global_position = pos
		_effects.add_child(trunk)

func _pick_bark_spawn_position() -> Vector2:
	var center: Vector2 = _player.global_position if _player != null else Vector2.ZERO
	var bounds: Rect2 = Rect2(center.x - 420.0, center.y - 260.0, 840.0, 520.0)
	if _arena != null and _arena.has_method("get_spawn_bounds"):
		bounds = _arena.get_spawn_bounds()
	for _attempt in range(24):
		var angle: float = randf() * TAU
		var radius: float = randf_range(bark_spawn_radius_min, bark_spawn_radius_max)
		var candidate: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius
		candidate = Vector2(
			clampf(candidate.x, bounds.position.x + 42.0, bounds.end.x - 42.0),
			clampf(candidate.y, bounds.position.y + 42.0, bounds.end.y - 42.0)
		)
		if candidate.distance_to(center) >= bark_safe_radius:
			return candidate
	return center + Vector2.RIGHT * max(bark_safe_radius + 32.0, bark_spawn_radius_min)

func _start_wind_storm() -> void:
	var parent: Node = _overlay_parent if _overlay_parent != null else _effects
	if parent == null:
		return
	_current_wind_direction = _pick_cardinal_direction()
	var effect: Node = WIND_STORM_SCENE.instantiate()
	if effect == null:
		return
	effect.add_to_group("deepwood_hazard")
	effect.process_mode = Node.PROCESS_MODE_PAUSABLE
	if effect.has_method("configure"):
		effect.configure(_current_wind_direction, wind_warning_duration, wind_active_duration)
	parent.add_child(effect)
	_wind_effect = effect

func _pick_cardinal_direction() -> Vector2:
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	return directions[randi() % directions.size()]

func _set_player_environment_force(force: Vector2) -> void:
	if _player != null and _player.has_method("set_environment_force"):
		_player.set_environment_force(force)

func _clear_active_wind() -> void:
	if _wind_effect != null and is_instance_valid(_wind_effect):
		_wind_effect.queue_free()
	_wind_effect = null
	_current_wind_direction = Vector2.ZERO

func _clear_spawned_hazards() -> void:
	for node in get_tree().get_nodes_in_group("deepwood_hazard"):
		if node != null and is_instance_valid(node):
			node.queue_free()
