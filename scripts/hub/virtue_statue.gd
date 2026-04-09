extends HubInteractable

func interact(hub: Node, _player: Node) -> void:
	if hub != null and hub.has_method("open_virtue_statue"):
		hub.call("open_virtue_statue")

func _draw() -> void:
	if uses_hub_art_sprite():
		return
	draw_circle(Vector2(0.0, 30.0), 34.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(-28.0, 12.0), Vector2(56.0, 16.0)), Color(0.20, 0.24, 0.30, 1.0), true)
	draw_rect(Rect2(Vector2(-10.0, -18.0), Vector2(20.0, 30.0)), Color(0.50, 0.56, 0.64, 0.98), true)
	draw_circle(Vector2(0.0, -28.0), 16.0, Color(0.70, 0.76, 0.86, 1.0))
	draw_arc(Vector2(0.0, -28.0), 24.0, 0.0, TAU, 24, Color(0.84, 0.74, 0.44, 0.46), 3.0)
	draw_circle(Vector2(0.0, -28.0), 6.0, Color(0.90, 0.84, 0.58, 0.92))
