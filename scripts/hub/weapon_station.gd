extends HubInteractable

## RunConfig.CLASS_ARCHER or CLASS_ARCANE_PISTOL — drives per-pillar overlay.
@export var bound_class_id: String = ""
@export var pillar_texture: Texture2D

func _ready() -> void:
	super._ready()
	var art: Sprite2D = get_node_or_null("ArtSprite") as Sprite2D
	if art != null and pillar_texture != null:
		art.texture = pillar_texture
		queue_redraw()

func interact(hub: Node, _player: Node) -> void:
	if hub != null and hub.has_method("open_weapon_class_overlay") and not bound_class_id.is_empty():
		hub.call("open_weapon_class_overlay", bound_class_id)

func _draw() -> void:
	if uses_hub_art_sprite():
		return
	draw_circle(Vector2(0.0, 28.0), 36.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_rect(Rect2(Vector2(-36.0, 10.0), Vector2(72.0, 18.0)), Color(0.20, 0.24, 0.30, 1.0), true)
	draw_rect(Rect2(Vector2(-24.0, -26.0), Vector2(48.0, 40.0)), Color(0.28, 0.32, 0.40, 0.98), true)
	draw_line(Vector2(-18.0, -14.0), Vector2(18.0, -14.0), Color(0.84, 0.74, 0.44, 0.48), 2.0, true)
	draw_line(Vector2(-12.0, -2.0), Vector2(0.0, -18.0), Color(0.82, 0.60, 0.34, 0.92), 3.0, true)
	draw_line(Vector2(6.0, -2.0), Vector2(16.0, -18.0), Color(0.72, 0.84, 0.96, 0.92), 3.0, true)
	draw_line(Vector2(16.0, -18.0), Vector2(20.0, -12.0), Color(0.72, 0.84, 0.96, 0.92), 2.0, true)
