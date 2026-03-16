extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 10.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var pierce_count: int = 0
@export var visual_style: String = "arcane"
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
	var payload: Dictionary = DAMAGE_SYSTEM.build_hit_payload(damage, crit_chance, crit_multiplier)
	if DAMAGE_SYSTEM.apply_hit(resolved, payload).is_empty():
		return
	hit.emit(global_position)
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func _draw() -> void:
	match visual_style:
		"arrow", "arrow_volley":
			_draw_arrow(false)
		"power_arrow":
			_draw_arrow(true)
		_:
			draw_circle(Vector2.ZERO, 4.0, Color(0.62, 0.96, 1.0, 0.95))
			draw_line(Vector2(-10, 0), Vector2.ZERO, Color(0.62, 0.96, 1.0, 0.35), 2.0, true)

func _draw_arrow(empowered: bool) -> void:
	var shaft_color: Color = Color(0.74, 0.58, 0.28, 1.0)
	var head_color: Color = Color(1.0, 0.9, 0.7, 1.0) if empowered else Color(0.92, 0.92, 0.88, 1.0)
	var trail_color: Color = Color(1.0, 0.82, 0.46, 0.42) if empowered else Color(0.92, 0.84, 0.56, 0.2)
	draw_line(Vector2(-16, 0), Vector2(8, 0), shaft_color, 2.0, true)
	draw_line(Vector2(-18, -2), Vector2(-12, 0), Color(0.98, 0.86, 0.64, 0.9), 2.0, true)
	draw_line(Vector2(-18, 2), Vector2(-12, 0), Color(0.98, 0.86, 0.64, 0.9), 2.0, true)
	draw_line(Vector2(4, -3), Vector2(11, 0), head_color, 2.0, true)
	draw_line(Vector2(4, 3), Vector2(11, 0), head_color, 2.0, true)
	draw_line(Vector2(-28, 0), Vector2(-8, 0), trail_color, 1.6, true)
	if empowered:
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color(1.0, 0.86, 0.42, 0.45), 2.0)
