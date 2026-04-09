extends Node2D
## Pentagon shrine: progress charges while the player stays inside the shrine network.
## The connection lines are the main read; shrine pillars are anchor visuals only.

const DamageSystem = preload("res://scripts/systems/damage_system.gd")

signal objective_started(objective_id: StringName)
signal objective_progressed(objective_id: StringName, value: float, detail: String)
signal objective_completed(objective_id: StringName, boss_progress_bonus: float)
signal objective_failed(objective_id: StringName)

@export var objective_id: StringName = &"pentagon_shrine"
@export var pentagon_radius: float = 160.0
@export var point_activation_radius: float = 48.0
@export var network_radius_padding: float = 90.0
@export var progress_gain_rate: float = 0.07
@export var progress_loss_rate: float = 0.09
@export var point_refresh_grace_seconds: float = 1.3
@export var reset_threshold: float = 0.0
@export var completion_explosion_radius: float = 270.0
@export var completion_damage: float = 80.0
@export var boss_progress_bonus: float = 16.0
@export var completion_cleanup_delay: float = 0.9
@export var persist_after_completion: bool = false
@export var explosion_effect_scene: PackedScene
@export var player_time_limit: float = 0.0

@onready var shrine_points_root: Node2D = $ShrinePoints
@onready var center_collision: CollisionShape2D = $CenterArea/CollisionShape2D
@onready var connections_root: Node2D = $Connections
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D

var _player: Node2D
var _points: Array[ShrinePoint] = []
var _connections: Array[Line2D] = []
var _progress_line: Line2D
var _progress: float = 0.0
var _status_text: String = "Step into the shrine network"
var _started: bool = false
var _completed: bool = false
var _failed_emitted: bool = false
var _completion_timer: float = 0.0
var _last_emitted_progress: float = -1.0
var _last_emitted_detail: String = ""
var _objective_elapsed: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_cache_points()
	_configure_shapes()
	_create_connections()
	_progress_line = Line2D.new()
	_progress_line.width = 10.0
	_progress_line.default_color = Color(0.8, 0.96, 1.0, 0.96)
	_progress_line.antialiased = true
	_progress_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_progress_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_progress_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_progress_line.z_index = 4
	connections_root.add_child(_progress_line)
	queue_redraw()

func _process(delta: float) -> void:
	if not _started or _failed_emitted:
		return
	if _completed:
		if not persist_after_completion and _completion_timer > 0.0:
			_completion_timer = max(_completion_timer - delta, 0.0)
			if _completion_timer <= 0.0:
				queue_free()
		return
	_objective_elapsed += delta
	if player_time_limit > 0.0 and _objective_elapsed >= player_time_limit:
		_fail_objective()
		return

	var inside_network: bool = _is_player_inside_network()
	if inside_network:
		_progress = min(_progress + progress_gain_rate * delta, 1.0)
	else:
		_progress = max(_progress - progress_loss_rate * delta, 0.0)
	_update_status_text(inside_network)
	_update_visual_state()
	_emit_progress_if_changed()
	if _progress >= 1.0:
		_complete_objective()

func start_objective(center_position: Vector2) -> void:
	global_position = center_position
	_layout_points()
	_progress = 0.0
	_started = true
	_completed = false
	_failed_emitted = false
	_completion_timer = 0.0
	_last_emitted_progress = -1.0
	_last_emitted_detail = ""
	_objective_elapsed = 0.0
	_update_visual_state()
	_status_text = "Hold the shrine network"
	objective_started.emit(objective_id)
	_emit_progress_if_changed(true)

func set_player(player: Node2D) -> void:
	_player = player
	for point in _points:
		point.set_player(player)

func tick(_delta: float) -> void:
	pass

func is_completed() -> bool:
	return _completed

func get_progress() -> float:
	return _progress

func get_status_text() -> String:
	return _status_text

func get_boss_progress_bonus() -> float:
	return boss_progress_bonus

func get_player_time_remaining() -> float:
	if player_time_limit <= 0.0:
		return 0.0
	return maxf(player_time_limit - _objective_elapsed, 0.0)

func _fail_objective() -> void:
	if _failed_emitted or _completed:
		return
	_failed_emitted = true
	_status_text = "Shrine unstable - time expired"
	_emit_progress_if_changed(true)
	objective_failed.emit(objective_id)

func _cache_points() -> void:
	_points.clear()
	for child in shrine_points_root.get_children():
		if child is ShrinePoint:
			var point: ShrinePoint = child as ShrinePoint
			point.configure(point_activation_radius, point_refresh_grace_seconds)
			_points.append(point)
	_points.sort_custom(func(a, b): return a.point_index < b.point_index)

func _configure_shapes() -> void:
	if center_collision != null and center_collision.shape is CircleShape2D:
		(center_collision.shape as CircleShape2D).radius = pentagon_radius + network_radius_padding
	if explosion_collision != null and explosion_collision.shape is CircleShape2D:
		(explosion_collision.shape as CircleShape2D).radius = completion_explosion_radius

func _layout_points() -> void:
	for i in range(_points.size()):
		var angle: float = -PI * 0.5 + TAU * float(i) / float(_points.size())
		_points[i].position = Vector2.RIGHT.rotated(angle) * pentagon_radius
	_update_connections_geometry()

func _create_connections() -> void:
	for child in _connections:
		if is_instance_valid(child):
			child.queue_free()
	_connections.clear()
	for i in range(_points.size()):
		var line: Line2D = Line2D.new()
		line.width = 7.0
		line.default_color = Color(0.24, 0.44, 0.66, 0.32)
		line.antialiased = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.z_index = 1
		connections_root.add_child(line)
		_connections.append(line)
	_update_connections_geometry()

func _update_connections_geometry() -> void:
	if _points.size() != 5:
		return
	for i in range(_connections.size()):
		if i >= _points.size():
			break
		var line: Line2D = _connections[i]
		var a: Vector2 = _points[i].position
		var b: Vector2 = _points[(i + 1) % _points.size()].position
		line.clear_points()
		line.add_point(a)
		line.add_point(b)

func _get_perimeter_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point in _points:
		points.append(point.position)
	if points.size() >= 2:
		points.append(points[0])
	return points

func _update_progress_line_visual() -> void:
	if _progress_line == null:
		return
	_progress_line.clear_points()
	var perimeter: PackedVector2Array = _get_perimeter_points()
	if perimeter.size() < 2:
		return
	var total_length: float = 0.0
	for i in range(perimeter.size() - 1):
		total_length += perimeter[i].distance_to(perimeter[i + 1])
	if total_length <= 0.001:
		return
	var target_length: float = clampf(_progress, 0.0, 1.0) * total_length
	_progress_line.add_point(perimeter[0])
	if target_length <= 0.001:
		_progress_line.add_point(perimeter[0] + Vector2(0.01, 0.0))
		return
	var walked_length: float = 0.0
	for i in range(perimeter.size() - 1):
		var start_point: Vector2 = perimeter[i]
		var end_point: Vector2 = perimeter[i + 1]
		var segment_length: float = start_point.distance_to(end_point)
		if walked_length + segment_length >= target_length:
			var segment_t: float = (target_length - walked_length) / max(segment_length, 0.001)
			_progress_line.add_point(start_point.lerp(end_point, clampf(segment_t, 0.0, 1.0)))
			break
		walked_length += segment_length
		_progress_line.add_point(end_point)

func _update_visual_state() -> void:
	var inside_network: bool = _is_player_inside_network()
	for point in _points:
		point.set_visual_state(_progress, inside_network, _completed)
	for i in range(_connections.size()):
		var line: Line2D = _connections[i]
		var pulse: float = 0.86 + 0.14 * sin(Time.get_ticks_msec() * 0.007 + float(i))
		var brightness: float = 0.22 + (_progress * 0.46)
		if inside_network:
			brightness += 0.18
		if _completed:
			brightness = 1.0
		line.width = 6.0 + _progress * 6.0 + (1.5 if inside_network else 0.0)
		line.default_color = Color(0.58, 0.82, 1.0, clamp(brightness * pulse, 0.28, 1.0))
	if _progress_line != null:
		_update_progress_line_visual()
		var pulse_fill: float = 0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.008)
		_progress_line.width = 10.0 + _progress * 7.0 + (2.0 if inside_network else 0.0)
		var fill_alpha: float = lerpf(0.44, 1.0, _progress) * pulse_fill
		if _completed:
			fill_alpha = 1.0
		_progress_line.default_color = Color(0.9, 0.98, 1.0, clampf(fill_alpha, 0.3, 1.0))
	queue_redraw()

func _format_mm_ss(seconds_remaining: float) -> String:
	var s: int = int(ceil(max(seconds_remaining, 0.0)))
	var m: int = s / 60
	var r: int = s % 60
	return "%d:%02d" % [m, r]

func _update_status_text(inside_network: bool) -> void:
	if _completed:
		_status_text = "The shrine is fully consecrated"
	elif inside_network:
		_status_text = "Hold the shrine network"
	elif _progress > 0.0:
		_status_text = "Return to the shrine network"
	else:
		_status_text = "Step into the shrine network"

func _emit_progress_if_changed(force: bool = false) -> void:
	if force or absf(_progress - _last_emitted_progress) > 0.002 or _status_text != _last_emitted_detail:
		_last_emitted_progress = _progress
		_last_emitted_detail = _status_text
		objective_progressed.emit(objective_id, _progress, _status_text)

func _is_player_inside_network() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) <= pentagon_radius + network_radius_padding

func _complete_objective() -> void:
	if _completed or _failed_emitted:
		return
	_completed = true
	_progress = 1.0
	_status_text = "Shrine complete"
	_update_visual_state()
	_emit_progress_if_changed(true)
	_spawn_completion_effect()
	_damage_enemies_in_radius()
	objective_completed.emit(objective_id, boss_progress_bonus)
	_completion_timer = completion_cleanup_delay if not persist_after_completion else 0.0

func _spawn_completion_effect() -> void:
	if explosion_effect_scene == null:
		return
	var effect: Node2D = explosion_effect_scene.instantiate() as Node2D
	if effect == null:
		return
	effect.global_position = global_position
	if effect.has_method("configure"):
		effect.configure(completion_explosion_radius)
	get_parent().add_child(effect)

func _damage_enemies_in_radius() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var resolved: Node = DamageSystem.resolve_damageable_target(enemy)
		if resolved == null or not (resolved is Node2D):
			continue
		var node: Node2D = resolved as Node2D
		if node.global_position.distance_to(global_position) > completion_explosion_radius:
			continue
		DamageSystem.apply_hit(resolved, {
			"amount": completion_damage,
			"is_crit": false,
			"impact_direction": global_position.direction_to(node.global_position),
			"hit_kind": "holy",
		})

func _draw() -> void:
	if _completed:
		draw_circle(Vector2.ZERO, pentagon_radius + network_radius_padding * 0.6, Color(1.0, 0.95, 0.72, 0.10))
	else:
		draw_circle(Vector2.ZERO, pentagon_radius + network_radius_padding * 0.5, Color(0.48, 0.72, 1.0, 0.06 + _progress * 0.08))
	for i in range(3, 0, -1):
		var alpha: float = (0.03 + _progress * 0.03) * float(i)
		draw_circle(Vector2.ZERO, pentagon_radius + network_radius_padding * (0.22 + float(i) * 0.15), Color(0.74, 0.9, 1.0, alpha))
