extends Node2D

## Must match HubController HUB_RECT + camera padding (same as cobble draw rect).
const HUB_RECT: Rect2 = Rect2(80.0, 120.0, 1840.0, 1000.0)
const CAMERA_PADDING_X: float = 110.0
const CAMERA_PADDING_Y: float = 90.0

@export var segment_texture: Texture2D
@export var segment_texture_vertical: Texture2D
## How far outside the walkable floor rect the wall center sits (world units).
@export var outward_offset: float = 36.0


func _floor_rect() -> Rect2:
	return HUB_RECT.grow_individual(
		CAMERA_PADDING_X,
		CAMERA_PADDING_Y,
		CAMERA_PADDING_X,
		CAMERA_PADDING_Y
	)


func _ready() -> void:
	if segment_texture == null:
		return
	var tex_h: Texture2D = segment_texture
	var tex_v: Texture2D = segment_texture_vertical if segment_texture_vertical != null else segment_texture
	var fr: Rect2 = _floor_rect()
	var seg_w: float = float(tex_h.get_width())
	var seg_h: float = float(tex_v.get_height())
	if seg_w < 1.0 or seg_h < 1.0:
		return
	var left: float = fr.position.x
	var right: float = fr.end.x
	var top: float = fr.position.y
	var bottom: float = fr.end.y
	# Top and bottom edges: tile horizontal texture across full width.
	var n_top: int = int(ceil((right - left) / seg_w))
	for i in range(n_top):
		var cx: float = left + (float(i) + 0.5) * seg_w
		_add_sprite(tex_h, Vector2(cx, top - outward_offset))
		_add_sprite(tex_h, Vector2(cx, bottom + outward_offset))
	# Left and right edges: tile vertical texture across full height.
	var n_side: int = int(ceil((bottom - top) / seg_h))
	for j in range(n_side):
		var cy: float = top + (float(j) + 0.5) * seg_h
		_add_sprite(tex_v, Vector2(left - outward_offset, cy))
		_add_sprite(tex_v, Vector2(right + outward_offset, cy))


func _add_sprite(tex: Texture2D, pos: Vector2) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	s.z_index = -3
	add_child(s)
