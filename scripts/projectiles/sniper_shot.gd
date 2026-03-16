extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 1200.0
@export var lifetime: float = 0.35
@export var damage: float = 42.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var pierce_count: int = 2
@export var visual_style: String = "arcane_sniper"
var direction: Vector2 = Vector2.RIGHT
var _hit_ids: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
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
	if DAMAGE_SYSTEM.apply_hit(resolved, payload).is_empty():
		return
	hit.emit(global_position)
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func _draw() -> void:
	if visual_style == "power_arrow":
		draw_line(Vector2(-34, 0), Vector2(20, 0), Color(0.8, 0.58, 0.26, 1.0), 3.0, true)
		draw_line(Vector2(-16, -3), Vector2(-8, 0), Color(0.98, 0.88, 0.62, 0.95), 2.0, true)
		draw_line(Vector2(-16, 3), Vector2(-8, 0), Color(0.98, 0.88, 0.62, 0.95), 2.0, true)
		draw_line(Vector2(10, -5), Vector2(20, 0), Color(1.0, 0.96, 0.82, 1.0), 3.0, true)
		draw_line(Vector2(10, 5), Vector2(20, 0), Color(1.0, 0.96, 0.82, 1.0), 3.0, true)
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 18, Color(1.0, 0.84, 0.34, 0.42), 2.5)
		draw_line(Vector2(-48, 0), Vector2(-8, 0), Color(1.0, 0.84, 0.34, 0.32), 2.2, true)
	else:
		draw_line(Vector2(-26, 0), Vector2(16, 0), Color(1.0, 0.75, 0.35, 0.98), 4.0, true)
		draw_line(Vector2(-12, 0), Vector2(16, 0), Color(1.0, 0.94, 0.8, 0.55), 2.0, true)
