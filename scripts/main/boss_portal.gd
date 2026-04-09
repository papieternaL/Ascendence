extends Area2D

signal portal_entered

@export var activation_radius: float = 34.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		call_deferred("_emit_portal_entered")

func _emit_portal_entered() -> void:
	portal_entered.emit()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 44.0, Color(0.06, 0.08, 0.16, 0.52))
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 40, Color(0.52, 0.86, 1.0, 0.92), 6.0)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 36, Color(0.88, 0.94, 1.0, 0.85), 4.0)
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0
		var point: Vector2 = Vector2.RIGHT.rotated(angle) * 38.0
		draw_circle(point, 3.5, Color(0.58, 0.92, 1.0, 0.92))
