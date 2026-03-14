extends Area2D

signal hit(at: Vector2)

@export var speed: float = 340.0
@export var turn_rate: float = 8.0
@export var lifetime: float = 3.0
@export var damage: float = 24.0
var direction: Vector2 = Vector2.RIGHT
var target: Node2D

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if notifier:
		notifier.screen_exited.connect(queue_free)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var desired := global_position.direction_to(target.global_position)
		direction = direction.slerp(desired, min(turn_rate * delta, 1.0)).normalized()
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	hit.emit(global_position)
	queue_free()
