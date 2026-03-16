extends Area2D

const DAMAGE_SYSTEM = preload("res://scripts/systems/damage_system.gd")

signal hit(at: Vector2)

@export var speed: float = 300.0
@export var turn_rate: float = 8.0
@export var lifetime: float = 3.0
@export var damage: float = 20.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
var direction: Vector2 = Vector2.RIGHT
var target: Node2D

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if notifier:
		notifier.screen_exited.connect(queue_free)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var desired: Vector2 = global_position.direction_to(target.global_position)
		direction = direction.slerp(desired, min(turn_rate * delta, 1.0)).normalized()
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
	var payload: Dictionary = DAMAGE_SYSTEM.build_hit_payload(damage, crit_chance, crit_multiplier)
	if DAMAGE_SYSTEM.apply_hit(target, payload).is_empty():
		return
	hit.emit(global_position)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.86, 0.52, 1.0, 0.95))
	draw_circle(Vector2(-6, 0), 3.0, Color(0.58, 0.28, 0.9, 0.4))
	draw_line(Vector2(-14, 0), Vector2.ZERO, Color(0.86, 0.52, 1.0, 0.28), 3.0, true)
