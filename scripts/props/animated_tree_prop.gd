@tool
extends Node2D

const FOLIAGE_SWAY_SHADER: Shader = preload("res://shaders/foliage_sway.gdshader")

@export var tree_texture: Texture2D
@export var render_scale: Vector2 = Vector2.ONE
@export var sway_strength_px: float = 2.4
@export var sway_speed: float = 1.15
@export var gust_strength_px: float = 0.9
@export var detail_strength_px: float = 0.4
@export_range(0.0, 0.9, 0.01) var canopy_start: float = 0.3
@export var phase_offset: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	call_deferred("_apply_tree_setup")

func _ready() -> void:
	_apply_tree_setup()

func _apply_tree_setup() -> void:
	if _sprite == null:
		return
	if tree_texture != null:
		_sprite.texture = tree_texture
	if _sprite.texture == null:
		return
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = render_scale
	# Keep the Node2D root at the trunk base so shared Y-sorting uses the
	# footprint instead of the canopy height.
	_sprite.position = Vector2(0.0, -_sprite.texture.get_height() * 0.5 * render_scale.y)
	var sway_material: ShaderMaterial = _sprite.material as ShaderMaterial
	if sway_material == null or sway_material.shader != FOLIAGE_SWAY_SHADER:
		sway_material = ShaderMaterial.new()
		sway_material.shader = FOLIAGE_SWAY_SHADER
	else:
		sway_material = sway_material.duplicate() as ShaderMaterial
	if is_zero_approx(phase_offset):
		phase_offset = fposmod(global_position.x * 0.012 + global_position.y * 0.018, TAU)
	sway_material.set_shader_parameter("sway_strength_px", sway_strength_px)
	sway_material.set_shader_parameter("sway_speed", sway_speed)
	sway_material.set_shader_parameter("gust_strength_px", gust_strength_px)
	sway_material.set_shader_parameter("detail_strength_px", detail_strength_px)
	sway_material.set_shader_parameter("canopy_start", canopy_start)
	sway_material.set_shader_parameter("phase_offset", phase_offset)
	_sprite.material = sway_material
