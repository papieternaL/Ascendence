@tool
extends Node2D

@export var prop_texture: Texture2D
@export var render_scale: Vector2 = Vector2.ONE

@onready var _sprite: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	call_deferred("_apply_prop_setup")

func _ready() -> void:
	_apply_prop_setup()

func _apply_prop_setup() -> void:
	if _sprite == null:
		return
	if prop_texture != null:
		_sprite.texture = prop_texture
	if _sprite.texture == null:
		return
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = render_scale
	# Keep the root at the ground-contact point so Y-sorting uses the base.
	_sprite.position = Vector2(0.0, -_sprite.texture.get_height() * 0.5 * render_scale.y)
