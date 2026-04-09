extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 100.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var pierce_count: int = 0
@export var visual_style: String = "arcane"
@export var visual_scale: float = 1.3
@export var attack_payload: Dictionary = {}
var direction: Vector2 = Vector2.RIGHT
var _hit_ids: Dictionary = {}
var _ricochet_remaining: int = 0

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var shape: CircleShape2D = (collision_shape.shape as CircleShape2D).duplicate()
		shape.radius *= maxf(visual_scale, 0.1)
		collision_shape.shape = shape
	_ricochet_remaining = int(attack_payload.get("ricochet_bounces", 0))
	if notifier:
		notifier.screen_exited.connect(queue_free)
	queue_redraw()

func _process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_attempt_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_attempt_hit(area)

func _attempt_hit(target: Node) -> void:
	var resolved: Node = DAMAGE_SYSTEM.resolve_damageable_target(target)
	if resolved == null:
		return
	var body_id: int = resolved.get_instance_id()
	if _hit_ids.has(body_id):
		return
	_hit_ids[body_id] = true
	var payload: Dictionary = DAMAGE_SYSTEM.build_hit_payload(damage, crit_chance, crit_multiplier)
	for key in attack_payload.keys():
		payload[key] = attack_payload[key]
	var result: Dictionary = DAMAGE_SYSTEM.apply_hit(resolved, payload)
	if result.is_empty():
		return
	hit.emit(global_position)
	_trigger_explosion(resolved, result)
	if _try_ricochet(resolved):
		return
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func _try_ricochet(current_target: Node) -> bool:
	if _ricochet_remaining <= 0:
		return false
	var next_target: Node2D = _find_ricochet_target(current_target)
	if next_target == null:
		return false
	_ricochet_remaining -= 1
	attack_payload["suppress_impact_juice"] = true
	direction = global_position.direction_to(next_target.global_position).normalized()
	if direction.length_squared() <= 0.0001:
		return false
	return true

func _find_ricochet_target(current_target: Node) -> Node2D:
	var radius: float = float(attack_payload.get("ricochet_range", 220.0))
	var best: Node2D
	var best_d2: float = INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node2D):
			continue
		var node: Node2D = candidate as Node2D
		if node == current_target:
			continue
		if _hit_ids.has(node.get_instance_id()):
			continue
		var d2: float = global_position.distance_squared_to(node.global_position)
		if d2 > radius * radius:
			continue
		if d2 < best_d2:
			best_d2 = d2
			best = node
	return best

func _trigger_explosion(resolved: Node, hit_result: Dictionary) -> void:
	var explosion_radius: float = float(attack_payload.get("explosion_radius", 0.0))
	if explosion_radius <= 0.0:
		return
	var damage_ratio: float = float(attack_payload.get("explosion_damage_ratio", 0.6))
	var center: Vector2 = global_position
	if resolved is Node2D:
		center = (resolved as Node2D).global_position
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var target: Node = DAMAGE_SYSTEM.resolve_damageable_target(candidate)
		if target == null or target == resolved:
			continue
		if not (target is Node2D):
			continue
		if center.distance_squared_to((target as Node2D).global_position) > explosion_radius * explosion_radius:
			continue
		var splash: Dictionary = DAMAGE_SYSTEM.build_hit_payload(
			float(hit_result.get("amount", damage)) * damage_ratio,
			0.0,
			1.0
		)
		splash["impact_direction"] = center.direction_to((target as Node2D).global_position)
		splash["hit_kind"] = "volley"
		splash["suppress_impact_juice"] = true
		DAMAGE_SYSTEM.apply_hit(target, splash)

func _draw() -> void:
	match visual_style:
		"arrow", "arrow_volley":
			_draw_arrow(false)
		"power_arrow":
			_draw_arrow(true)
		"bullet":
			_draw_bullet()
		_:
			draw_circle(Vector2.ZERO, 5.4 * visual_scale, Color(0.62, 0.96, 1.0, 0.95))
			draw_line(Vector2(-14, 0) * visual_scale, Vector2.ZERO, Color(0.62, 0.96, 1.0, 0.35), 2.8 * visual_scale, true)

func _draw_arrow(empowered: bool) -> void:
	var shaft_color: Color = Color(0.74, 0.58, 0.28, 1.0)
	var head_color: Color = Color(1.0, 0.9, 0.7, 1.0) if empowered else Color(0.92, 0.92, 0.88, 1.0)
	var trail_color: Color = Color(1.0, 0.82, 0.46, 0.42) if empowered else Color(0.92, 0.84, 0.56, 0.2)
	draw_line(Vector2(-16, 0) * visual_scale, Vector2(8, 0) * visual_scale, shaft_color, 2.4 * visual_scale, true)
	draw_line(Vector2(-18, -2) * visual_scale, Vector2(-12, 0) * visual_scale, Color(0.98, 0.86, 0.64, 0.9), 2.2 * visual_scale, true)
	draw_line(Vector2(-18, 2) * visual_scale, Vector2(-12, 0) * visual_scale, Color(0.98, 0.86, 0.64, 0.9), 2.2 * visual_scale, true)
	draw_line(Vector2(4, -3) * visual_scale, Vector2(11, 0) * visual_scale, head_color, 2.4 * visual_scale, true)
	draw_line(Vector2(4, 3) * visual_scale, Vector2(11, 0) * visual_scale, head_color, 2.4 * visual_scale, true)
	draw_line(Vector2(-28, 0) * visual_scale, Vector2(-8, 0) * visual_scale, trail_color, 1.9 * visual_scale, true)
	if empowered:
		draw_arc(Vector2.ZERO, 8.0 * visual_scale, 0.0, TAU, 16, Color(1.0, 0.86, 0.42, 0.45), 2.2 * visual_scale)

func _draw_bullet() -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(-12.0, -2.2) * visual_scale,
		Vector2(2.0, -2.2) * visual_scale,
		Vector2(7.0, 0.0) * visual_scale,
		Vector2(2.0, 2.2) * visual_scale,
		Vector2(-12.0, 2.2) * visual_scale,
	])
	draw_colored_polygon(body, Color(0.82, 0.92, 1.0, 0.96))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(0.24, 0.38, 0.52, 0.85), 1.3 * visual_scale, true)
	draw_line(Vector2(-9.0, 0.0) * visual_scale, Vector2(1.5, 0.0) * visual_scale, Color(0.34, 0.62, 0.90, 0.7), 1.2 * visual_scale, true)
	draw_line(Vector2(-22.0, 0.0) * visual_scale, Vector2(-8.0, 0.0) * visual_scale, Color(0.50, 0.88, 1.0, 0.30), 1.8 * visual_scale, true)
