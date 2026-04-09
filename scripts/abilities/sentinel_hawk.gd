extends Node2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal strike(at: Vector2, is_crit: bool)
signal swoop(from: Vector2, to: Vector2, tint: Color, width: float, style: String)

@export var duration: float = 8.0
@export var seek_range: float = 560.0
@export var strike_interval: float = 0.42
@export var move_speed: float = 760.0
@export var idle_radius: float = 34.0
@export var hit_radius: float = 18.0
@export var damage: float = 28.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5

var player: Node2D
var target: Node2D

var _remaining: float = 0.0
var _strike_remaining: float = 0.0
var _orbit_angle: float = 0.0
var _wing_time: float = 0.0

func setup(owner_player: Node2D, next_duration: float, next_seek_range: float, next_strike_interval: float, next_move_speed: float, next_damage: float, next_crit_chance: float, next_crit_multiplier: float) -> void:
	player = owner_player
	duration = next_duration
	seek_range = next_seek_range
	strike_interval = next_strike_interval
	move_speed = next_move_speed
	damage = next_damage
	crit_chance = next_crit_chance
	crit_multiplier = next_crit_multiplier
	_remaining = duration
	_strike_remaining = 0.12
	_orbit_angle = randf() * TAU
	queue_redraw()

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	_remaining = max(_remaining - delta, 0.0)
	if _remaining <= 0.0:
		queue_free()
		return
	_strike_remaining = max(_strike_remaining - delta, 0.0)
	_orbit_angle += delta * 3.2
	_wing_time += delta * 14.0
	_refresh_target()
	var from: Vector2 = global_position
	var destination: Vector2 = _idle_position()
	if target != null:
		destination = target.global_position + Vector2(0.0, -8.0)
	global_position = global_position.move_toward(destination, move_speed * delta)
	if target != null and _strike_remaining <= 0.0 and global_position.distance_to(target.global_position) <= hit_radius:
		_attempt_strike()
	var facing: Vector2 = (destination - global_position).normalized()
	if facing.length_squared() > 0.0001:
		rotation = facing.angle()
	queue_redraw()

func _refresh_target() -> void:
	if target != null and is_instance_valid(target):
		if player.global_position.distance_squared_to(target.global_position) <= seek_range * seek_range:
			return
	target = null
	var best: Node2D
	var best_d2: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		var d2: float = player.global_position.distance_squared_to(node.global_position)
		if d2 > seek_range * seek_range:
			continue
		if d2 < best_d2:
			best_d2 = d2
			best = node
	target = best

func _attempt_strike() -> void:
	if target == null or not is_instance_valid(target):
		return
	swoop.emit(global_position, target.global_position, Color(1.0, 0.9, 0.48, 0.32), 3.0, "sentinel")
	var payload: Dictionary = DAMAGE_SYSTEM.build_hit_payload(damage, crit_chance, crit_multiplier)
	payload["hit_kind"] = "sentinel"
	payload["impact_direction"] = player.global_position.direction_to(target.global_position)
	var result: Dictionary = DAMAGE_SYSTEM.apply_hit(target, payload)
	if result.is_empty():
		return
	strike.emit(target.global_position, bool(result.get("is_crit", false)))
	_strike_remaining = strike_interval
	target = null

func _idle_position() -> Vector2:
	var bob: float = sin(_orbit_angle * 1.9) * 10.0
	return player.global_position + Vector2(cos(_orbit_angle) * idle_radius, -34.0 + bob)

func _draw() -> void:
	var wing_flare: float = sin(_wing_time) * 6.0
	var glow_alpha: float = 0.18 + (max(_remaining / max(duration, 0.001), 0.0) * 0.16)
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.86, 0.34, glow_alpha * 0.55))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.94, 0.6, glow_alpha * 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12.0, -2.0),
			Vector2(-4.0, -7.0 - wing_flare),
			Vector2(2.0, -1.0),
			Vector2(-4.0, 1.0),
		]),
		Color(0.74, 0.56, 0.24, 1.0)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12.0, 2.0),
			Vector2(-4.0, 7.0 + wing_flare),
			Vector2(2.0, 1.0),
			Vector2(-4.0, -1.0),
		]),
		Color(0.86, 0.68, 0.28, 1.0)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-2.0, -4.0),
			Vector2(10.0, 0.0),
			Vector2(-2.0, 4.0),
			Vector2(-8.0, 0.0),
		]),
		Color(0.96, 0.9, 0.62, 1.0)
	)
	draw_line(Vector2(7.0, -1.0), Vector2(13.0, 0.0), Color(1.0, 0.72, 0.24, 1.0), 2.0, true)
	draw_circle(Vector2(2.0, -1.0), 1.4, Color(0.16, 0.12, 0.08, 0.9))
	draw_line(Vector2(-9.0, 0.0), Vector2(-16.0, 0.0), Color(1.0, 0.88, 0.56, glow_alpha * 0.9), 1.2, true)
