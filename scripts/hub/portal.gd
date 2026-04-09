extends HubInteractable

func interact(hub: Node, _player: Node) -> void:
	if hub != null and hub.has_method("open_portal_panel"):
		hub.call("open_portal_panel")

func _draw() -> void:
	if uses_hub_art_sprite():
		return
	draw_circle(Vector2(0.0, 34.0), 44.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 40, Color(0.52, 0.88, 1.0, 0.90), 5.0)
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 40, Color(0.82, 0.98, 1.0, 0.68), 4.0)
	draw_circle(Vector2.ZERO, 16.0, Color(0.26, 0.64, 0.96, 0.42))
	draw_line(Vector2(-26.0, 22.0), Vector2(-14.0, 48.0), Color(0.34, 0.38, 0.44, 0.96), 4.0, true)
	draw_line(Vector2(26.0, 22.0), Vector2(14.0, 48.0), Color(0.34, 0.38, 0.44, 0.96), 4.0, true)
