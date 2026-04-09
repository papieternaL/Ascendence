extends Node

## Spawn controller with explicit Deepwood pacing phases.

const ENEMY_COUNT_MULTIPLIER: float = 1.15
const SPAWN_INTERVAL_MULTIPLIER: float = 1.0 / ENEMY_COUNT_MULTIPLIER

const WOLF_SCENE: PackedScene = preload("res://scenes/enemies/WolfEnemy.tscn")
const WIZARD_SCENE: PackedScene = preload("res://scenes/enemies/WizardEnemy.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/enemies/SkeletonEnemy.tscn")
const DRUID_TREENT_SCENE: PackedScene = preload("res://scenes/enemies/DruidTreentEnemy.tscn")
const TREENT_SCENE: PackedScene = preload("res://scenes/enemies/TreentEnemy.tscn")
const SMALL_TREENT_SCENE: PackedScene = preload("res://scenes/enemies/SmallTreentEnemy.tscn")

@export var early_phase_end_seconds: float = 90.0
@export var mid_phase_end_seconds: float = 240.0
@export var first_minute_end_seconds: float = 60.0
@export var first_minute_spawn_interval: float = 1.13
@export var first_minute_spawn_radius_min: float = 340.0
@export var first_minute_spawn_radius_max: float = 520.0
@export var dynamic_spawn_lockout_seconds: float = 4.5

@export var early_active_floor: int = 4
@export var early_active_cap: int = 7
@export var early_spawn_interval: float = 2.26
@export var early_skeleton_weight: float = 10.0
@export var early_wolf_weight: float = 2.0
@export var early_small_treent_weight: float = 3.0
@export var early_wizard_weight: float = 0.0
@export var early_druid_treent_weight: float = 0.0
@export var early_treent_weight: float = 1.0

@export var mid_active_floor: int = 5
@export var mid_active_cap: int = 9
@export var mid_spawn_interval: float = 2.09
@export var mid_skeleton_weight: float = 8.0
@export var mid_wolf_weight: float = 5.0
@export var mid_small_treent_weight: float = 4.0
@export var mid_wizard_weight: float = 1.5
@export var mid_druid_treent_weight: float = 2.0
@export var mid_treent_weight: float = 2.0

@export var late_active_floor: int = 7
@export var late_active_cap: int = 14
@export var late_spawn_interval: float = 1.48
@export var late_skeleton_weight: float = 7.0
@export var late_wolf_weight: float = 6.0
@export var late_small_treent_weight: float = 4.0
@export var late_wizard_weight: float = 3.0
@export var late_druid_treent_weight: float = 3.0
@export var late_treent_weight: float = 2.5

@export var early_spawn_margin_min: float = 300.0
@export var early_spawn_margin_max: float = 460.0
@export var mid_spawn_margin_min: float = 360.0
@export var mid_spawn_margin_max: float = 520.0
@export var late_spawn_margin_min: float = 400.0
@export var late_spawn_margin_max: float = 560.0
## Distance off viewport edge for side-based spawning.
@export var early_spawn_margin: float = 165.0
@export var mid_spawn_margin: float = 205.0
@export var late_spawn_margin: float = 235.0
@export var player_exclusion_radius: float = 270.0

var _time_alive: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_bounds: Rect2 = Rect2(-420.0, -260.0, 2840.0, 1760.0)
var _has_spawn_bounds: bool = false

func spawn(scene: PackedScene, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	var instance: Node = scene.instantiate()
	if instance is Node2D:
		(instance as Node2D).global_position = position
	parent.add_child(instance)
	return instance

func tick(delta: float) -> void:
	_time_alive += delta
	if _time_alive < dynamic_spawn_lockout_seconds:
		return
	_spawn_timer += delta

func set_spawn_bounds(bounds: Rect2) -> void:
	_spawn_bounds = bounds
	_has_spawn_bounds = true

func set_player_exclusion_radius(radius: float) -> void:
	player_exclusion_radius = maxf(radius, 0.0)

func get_current_phase_name() -> String:
	if _time_alive < early_phase_end_seconds:
		return "early"
	if _time_alive < mid_phase_end_seconds:
		return "mid"
	return "late"

func get_current_phase_config() -> Dictionary:
	match get_current_phase_name():
		"early":
			return {
				"floor": int(ceil(float(early_active_floor) * ENEMY_COUNT_MULTIPLIER)),
				"cap": int(ceil(float(early_active_cap) * ENEMY_COUNT_MULTIPLIER)),
				"interval": early_spawn_interval * SPAWN_INTERVAL_MULTIPLIER,
				"weights": {
					"skeleton": early_skeleton_weight,
					"wolf": early_wolf_weight,
					"small_treent": early_small_treent_weight,
					"wizard": early_wizard_weight,
					"druid_treent": early_druid_treent_weight,
					"treent": early_treent_weight,
				},
			}
		"mid":
			return {
				"floor": int(ceil(float(mid_active_floor) * ENEMY_COUNT_MULTIPLIER)),
				"cap": int(ceil(float(mid_active_cap) * ENEMY_COUNT_MULTIPLIER)),
				"interval": mid_spawn_interval * SPAWN_INTERVAL_MULTIPLIER,
				"weights": {
					"skeleton": mid_skeleton_weight,
					"wolf": mid_wolf_weight,
					"small_treent": mid_small_treent_weight,
					"wizard": mid_wizard_weight,
					"druid_treent": mid_druid_treent_weight,
					"treent": mid_treent_weight,
				},
			}
		_:
			return {
				"floor": int(ceil(float(late_active_floor) * ENEMY_COUNT_MULTIPLIER)),
				"cap": int(ceil(float(late_active_cap) * ENEMY_COUNT_MULTIPLIER)),
				"interval": late_spawn_interval * SPAWN_INTERVAL_MULTIPLIER,
				"weights": {
					"skeleton": late_skeleton_weight,
					"wolf": late_wolf_weight,
					"small_treent": late_small_treent_weight,
					"wizard": late_wizard_weight,
					"druid_treent": late_druid_treent_weight,
					"treent": late_treent_weight,
				},
			}

func get_effective_min() -> int:
	return int(get_current_phase_config().get("floor", early_active_floor))

func get_effective_max() -> int:
	return int(get_current_phase_config().get("cap", early_active_cap))

func get_scaled_interval() -> float:
	if _time_alive < first_minute_end_seconds:
		return first_minute_spawn_interval * SPAWN_INTERVAL_MULTIPLIER
	return float(get_current_phase_config().get("interval", early_spawn_interval))

func is_first_minute_active() -> bool:
	return _time_alive < first_minute_end_seconds

func should_spawn(active_count: int) -> bool:
	if _time_alive < dynamic_spawn_lockout_seconds:
		return false
	var effective_max: int = get_effective_max()
	if active_count >= effective_max:
		return false
	var interval: float = get_scaled_interval()
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		return true
	return false

func needs_catch_up_spawn(active_count: int) -> bool:
	if _time_alive < dynamic_spawn_lockout_seconds:
		return false
	if active_count >= get_effective_max():
		return false
	return active_count < get_effective_min()

func select_enemy_scene() -> PackedScene:
	var total: float = 0.0
	var weights: Dictionary = get_current_phase_config().get("weights", {})
	for key in weights:
		total += maxf(float(weights[key]), 0.0)
	if total <= 0.0:
		return SKELETON_SCENE
	var roll: float = randf() * total
	for key in weights:
		roll -= maxf(float(weights[key]), 0.0)
		if roll <= 0.0:
			match key:
				"wolf":
					return WOLF_SCENE
				"skeleton":
					return SKELETON_SCENE
				"druid_treent":
					return DRUID_TREENT_SCENE
				"wizard":
					return WIZARD_SCENE
				"treent":
					return TREENT_SCENE
				"small_treent":
					return SMALL_TREENT_SCENE
				_:
					return SKELETON_SCENE
	return SKELETON_SCENE

func get_spawn_offset() -> Vector2:
	var angle: float = randf() * TAU
	var range: Vector2 = _get_spawn_radius_range()
	var radius: float = range.x + randf() * maxf(range.y - range.x, 0.0)
	return Vector2.RIGHT.rotated(angle) * radius

func get_first_minute_spawn_offset(player_pos: Vector2) -> Vector2:
	var min_radius: float = maxf(first_minute_spawn_radius_min, player_exclusion_radius)
	var max_radius: float = maxf(first_minute_spawn_radius_max, min_radius)
	var best_position: Vector2 = _clamp_to_spawn_bounds(player_pos + Vector2.RIGHT * min_radius)
	var best_distance: float = best_position.distance_to(player_pos)
	for _attempt in range(16):
		var angle: float = randf() * TAU
		var radius: float = randf_range(min_radius, max_radius)
		var candidate: Vector2 = _clamp_to_spawn_bounds(player_pos + Vector2.RIGHT.rotated(angle) * radius)
		var distance_to_player: float = candidate.distance_to(player_pos)
		if distance_to_player >= min_radius and distance_to_player <= max_radius + 6.0:
			return candidate - player_pos
		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_position = candidate
	var fallback_direction: Vector2 = best_position - player_pos
	if fallback_direction.length_squared() <= 0.0001:
		fallback_direction = Vector2.RIGHT.rotated(randf() * TAU)
	best_position = _clamp_to_spawn_bounds(player_pos + fallback_direction.normalized() * min_radius)
	return best_position - player_pos

## Spawn at viewport edge (one of 4 sides), spawn_margin off-screen.
## Returns offset from player_pos to spawn world position.
func get_spawn_offset_from_viewport(camera: Camera2D, player_pos: Vector2) -> Vector2:
	if camera == null:
		return get_spawn_offset()
	var best_position: Vector2 = player_pos + get_spawn_offset()
	var best_distance: float = -INF
	for _attempt in range(10):
		var candidate: Vector2 = _sample_viewport_edge_spawn(camera)
		candidate = _clamp_to_spawn_bounds(candidate)
		var distance_to_player: float = candidate.distance_to(player_pos)
		if distance_to_player >= player_exclusion_radius:
			return candidate - player_pos
		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_position = candidate
	var direction: Vector2 = best_position - player_pos
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT.rotated(randf() * TAU)
	best_position = player_pos + direction.normalized() * player_exclusion_radius
	best_position = _clamp_to_spawn_bounds(best_position)
	return best_position - player_pos

func _sample_viewport_edge_spawn(camera: Camera2D) -> Vector2:
	var viewport_size: Vector2 = _get_camera_world_view_size(camera)
	var cam_pos: Vector2 = camera.global_position
	var left: float = cam_pos.x - viewport_size.x * 0.5
	var right: float = cam_pos.x + viewport_size.x * 0.5
	var top: float = cam_pos.y - viewport_size.y * 0.5
	var bottom: float = cam_pos.y + viewport_size.y * 0.5
	var margin: float = _get_viewport_spawn_margin()
	var side: int = randi_range(1, 4)
	var spawn_x: float
	var spawn_y: float
	match side:
		1:
			spawn_x = randf_range(left - margin, right + margin)
			spawn_y = top - margin
		2:
			spawn_x = right + margin
			spawn_y = randf_range(top - margin, bottom + margin)
		3:
			spawn_x = randf_range(left - margin, right + margin)
			spawn_y = bottom + margin
		_:
			spawn_x = left - margin
			spawn_y = randf_range(top - margin, bottom + margin)
	return Vector2(spawn_x, spawn_y)

func _get_camera_world_view_size(camera: Camera2D) -> Vector2:
	if camera == null:
		return Vector2.ZERO
	if camera.has_method("get_world_view_size"):
		return camera.call("get_world_view_size")
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	return Vector2(
		viewport_size.x / maxf(camera.zoom.x, 0.001),
		viewport_size.y / maxf(camera.zoom.y, 0.001)
	)

func _clamp_to_spawn_bounds(position: Vector2) -> Vector2:
	if not _has_spawn_bounds:
		return position
	return Vector2(
		clampf(position.x, _spawn_bounds.position.x, _spawn_bounds.end.x),
		clampf(position.y, _spawn_bounds.position.y, _spawn_bounds.end.y)
	)

func _get_spawn_radius_range() -> Vector2:
	match get_current_phase_name():
		"early":
			return Vector2(early_spawn_margin_min, early_spawn_margin_max)
		"mid":
			return Vector2(mid_spawn_margin_min, mid_spawn_margin_max)
		_:
			return Vector2(late_spawn_margin_min, late_spawn_margin_max)

func _get_viewport_spawn_margin() -> float:
	match get_current_phase_name():
		"early":
			return early_spawn_margin
		"mid":
			return mid_spawn_margin
		_:
			return late_spawn_margin
