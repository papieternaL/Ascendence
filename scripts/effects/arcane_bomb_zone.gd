extends Node2D

const ElementalSystem = preload("res://scripts/systems/elemental_system.gd")

@export var radius: float = 78.0
@export var duration: float = 3.4
@export var tick_interval: float = 0.45
@export var tick_damage: float = 18.0
@export var slow_mul: float = 1.18
@export var slow_duration: float = 0.7

var _elapsed: float = 0.0
var _tick_timer: float = 0.0

func setup(config: Dictionary) -> void:
	global_position = Vector2(config.get("position", global_position))
	radius = float(config.get("radius", radius))
	duration = float(config.get("duration", duration))
	tick_interval = float(config.get("tick_interval", tick_interval))
	tick_damage = float(config.get("tick_damage", tick_damage))
	slow_mul = float(config.get("slow_mul", slow_mul))
	slow_duration = float(config.get("slow_duration", slow_duration))

func _process(delta: float) -> void:
	_elapsed += delta
	_tick_timer += delta
	while _tick_timer >= tick_interval:
		_tick_timer -= tick_interval
		_apply_tick()
	queue_redraw()
	if _elapsed >= duration:
		queue_free()

func _apply_tick() -> void:
	var parent_node: Node = get_parent()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if not is_instance_valid(node):
			continue
		if global_position.distance_squared_to(node.global_position) > radius * radius:
			continue
		if node.has_method("take_damage"):
			node.call("take_damage", {
				"amount": tick_damage,
				"is_crit": false,
				"hit_kind": "arcane_bomb",
				"impact_direction": global_position.direction_to(node.global_position),
				"suppress_impact_juice": true,
			})
		ElementalSystem.apply_status(node, "chill", 1, slow_duration, {
			"slow_mul": slow_mul,
			"effects_parent": parent_node,
		})

func _draw() -> void:
	var life_ratio: float = clampf(1.0 - (_elapsed / max(duration, 0.001)), 0.0, 1.0)
	var pulse: float = 0.88 + 0.12 * sin(_elapsed * 8.0)
	var outer_color: Color = Color(0.72, 0.32, 1.0, 0.20 * life_ratio * pulse)
	var inner_color: Color = Color(0.44, 0.16, 0.76, 0.34 * life_ratio)
	var rim_color: Color = Color(0.92, 0.62, 1.0, 0.84 * life_ratio)
	draw_circle(Vector2.ZERO, radius * 1.04, outer_color)
	draw_circle(Vector2.ZERO, radius * 0.82, inner_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, rim_color, 2.2)
	draw_arc(Vector2.ZERO, maxf(radius - 12.0, 8.0), 0.0, TAU, 44, Color(0.84, 0.52, 1.0, 0.46 * life_ratio), 1.2)
	for i in range(6):
		var angle: float = _elapsed * (1.8 + float(i) * 0.12) + TAU * float(i) / 6.0
		var orbit: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.52 + 4.0 * sin(_elapsed * 3.0 + float(i)))
		draw_circle(orbit, 4.0 + sin(_elapsed * 7.0 + float(i)) * 0.8, Color(0.94, 0.68, 1.0, 0.18 * life_ratio))
