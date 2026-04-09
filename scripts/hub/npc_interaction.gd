extends HubInteractable

@export var hub_method_name: String = "open_quest_board"
@export var hub_method_args: Array = []

func interact(hub: Node, _player: Node) -> void:
	if hub == null or hub_method_name.is_empty():
		return
	if not hub.has_method(hub_method_name):
		return
	if hub_method_args.is_empty():
		hub.call(hub_method_name)
		return
	hub.callv(hub_method_name, hub_method_args)

func _draw() -> void:
	if uses_hub_art_sprite():
		return
	draw_circle(Vector2(0.0, 22.0), 32.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(-30.0, -20.0), Vector2(60.0, 40.0)), Color(0.42, 0.28, 0.16, 0.98), true)
	draw_rect(Rect2(Vector2(-24.0, -14.0), Vector2(48.0, 28.0)), Color(0.66, 0.58, 0.42, 0.94), true)
	draw_line(Vector2(-20.0, -6.0), Vector2(20.0, -6.0), Color(0.32, 0.24, 0.16, 0.48), 2.0, true)
	draw_line(Vector2(-20.0, 2.0), Vector2(14.0, 2.0), Color(0.32, 0.24, 0.16, 0.48), 2.0, true)
	draw_line(Vector2(-20.0, 10.0), Vector2(18.0, 10.0), Color(0.32, 0.24, 0.16, 0.48), 2.0, true)
	draw_line(Vector2(-18.0, 20.0), Vector2(-18.0, 44.0), Color(0.28, 0.20, 0.12, 1.0), 4.0, true)
	draw_line(Vector2(18.0, 20.0), Vector2(18.0, 44.0), Color(0.28, 0.20, 0.12, 1.0), 4.0, true)
