extends Area2D

signal hit(at: Vector2)

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT

@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if notifier:
		notifier.screen_exited.connect(queue_free)

func _process(delta: float) -> void:
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
