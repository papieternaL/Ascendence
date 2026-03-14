extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
