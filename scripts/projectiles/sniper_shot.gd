extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 1200.0
@export var lifetime: float = 0.35
@export var damage: float = 42.0
@export var pierce_count: int = 2
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
	if not DAMAGE_SYSTEM.apply_hit(resolved, damage):
		return
	hit.emit(global_position)
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-26, 0), Vector2(16, 0), Color(1.0, 0.75, 0.35, 0.98), 4.0, true)
	draw_line(Vector2(-12, 0), Vector2(16, 0), Color(1.0, 0.94, 0.8, 0.55), 2.0, true)
