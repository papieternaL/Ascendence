extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 10.0
@export var pierce_count: int = 0
var direction: Vector2 = Vector2.RIGHT
var _hit_ids: Dictionary = {}

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
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
	if not DAMAGE_SYSTEM.apply_hit(resolved, damage):
		return
	hit.emit(global_position)
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.62, 0.96, 1.0, 0.95))
	draw_line(Vector2(-10, 0), Vector2.ZERO, Color(0.62, 0.96, 1.0, 0.35), 2.0, true)
