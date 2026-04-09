extends Node2D

const PULSE_SHADER: Shader = preload("res://shaders/effects/additive_pulse.gdshader")
const HEAT_SHADER: Shader = preload("res://shaders/effects/heat_shimmer.gdshader")

@export var duration: float = 0.18
@export var start_radius: float = 8.0
@export var end_radius: float = 28.0
@export var color: Color = Color(1.0, 0.84, 0.38, 0.5)
@export var shader_style: String = "pulse"

var _time: float = 0.0

func _ready() -> void:
	_apply_shader()

func configure(next_color: Color, next_start_radius: float = -1.0, next_end_radius: float = -1.0, next_duration: float = -1.0, next_shader_style: String = "") -> void:
	color = next_color
	if next_start_radius > 0.0:
		start_radius = next_start_radius
	if next_end_radius > 0.0:
		end_radius = next_end_radius
	if next_duration > 0.0:
		duration = next_duration
	if not next_shader_style.is_empty():
		shader_style = next_shader_style
	_apply_shader()

func _process(delta: float) -> void:
	_time += delta
	_update_shader_params()
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var radius: float = lerp(start_radius, end_radius, t)
	var alpha: float = (1.0 - t) * color.a
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, alpha * 0.14))
	draw_circle(Vector2.ZERO, radius * 0.74, Color(color.r, color.g, color.b, alpha * 0.2))
	draw_circle(Vector2.ZERO, radius * 0.42, Color(color.r, color.g, color.b, alpha * 0.28))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(color.r, color.g, color.b, alpha * 0.72), 2.0)
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0 + _time * 1.3
		var start: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.24)
		var finish: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.92)
		draw_line(start, finish, Color(1.0, 0.96, 0.84, alpha * 0.42), 1.6, true)

func _apply_shader() -> void:
	var shader: Shader = HEAT_SHADER if shader_style == "heat" else PULSE_SHADER
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null or shader_material.shader != shader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		material = shader_material
	_update_shader_params()

func _update_shader_params() -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("tint", color)
	if shader_style == "heat":
		shader_material.set_shader_parameter("heat_strength", 0.28 + color.a * 0.3)
		shader_material.set_shader_parameter("flicker_speed", 8.0)
	else:
		shader_material.set_shader_parameter("pulse_strength", 0.16 + color.a * 0.26)
		shader_material.set_shader_parameter("pulse_speed", 7.5)
		shader_material.set_shader_parameter("shimmer_amount", 0.1)
