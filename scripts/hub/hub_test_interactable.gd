extends HubInteractable

@export_multiline var panel_body_text: String = "Prototype marker.\n\nThis plaque confirms the Esseloria interaction loop is wired and ready for future hub stations."

func interact(hub: Node, _player: Node) -> void:
	if hub != null and hub.has_method("open_test_panel"):
		hub.call("open_test_panel", get_interactable_name(), panel_body_text)

func _draw() -> void:
	draw_circle(Vector2(0.0, 16.0), 26.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(-28.0, -22.0), Vector2(56.0, 50.0)), Color(0.28, 0.32, 0.40, 0.98), true)
	draw_rect(Rect2(Vector2(-24.0, -18.0), Vector2(48.0, 42.0)), Color(0.16, 0.18, 0.23, 0.98), true)
	draw_rect(Rect2(Vector2(-15.0, 28.0), Vector2(30.0, 12.0)), Color(0.32, 0.36, 0.42, 1.0), true)
	draw_rect(Rect2(Vector2(-8.0, 40.0), Vector2(16.0, 10.0)), Color(0.20, 0.22, 0.28, 1.0), true)
	for y in [Vector2(-12.0, -6.0), Vector2(-12.0, 0.0), Vector2(-12.0, 6.0)]:
		draw_line(y, Vector2(12.0, y.y), Color(0.82, 0.74, 0.52, 0.62), 2.0, true)
