extends Node2D

const PULSE_SHADER: Shader = preload("res://shaders/effects/additive_pulse.gdshader")

@export var duration: float = 0.08
@export var width: float = 2.0
@export var color: Color = Color(0.62, 0.94, 1.0, 0.6)

var _time: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _style: String = "trail"

func _ready() -> void:
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = PULSE_SHADER
	material = shader_material
	_update_shader_params()

func setup(from: Vector2, to: Vector2, tint: Color, line_width: float = 2.0, next_style: String = "trail") -> void:
	_from = from
	_to = to
	color = tint
	width = line_width
	_style = next_style
	_update_shader_params()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_update_shader_params()
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var alpha: float = (1.0 - t) * color.a
	var normal: Vector2 = (_to - _from).orthogonal().normalized()
	draw_line(_from, _to, Color(color.r, color.g, color.b, alpha), width, true)
	draw_line(_from.lerp(_to, 0.08), _to, Color(1.0, 0.96, 0.8, alpha * 0.52), max(width - 1.0, 1.0), true)
	if _style == "dash":
		draw_line(_from + normal * 6.0, _to + normal * 2.0, Color(color.r, color.g, color.b, alpha * 0.38), max(width - 0.6, 1.0), true)
		draw_line(_from - normal * 6.0, _to - normal * 2.0, Color(color.r, color.g, color.b, alpha * 0.24), max(width - 1.0, 1.0), true)
		draw_circle(_to, width * 0.8, Color(0.88, 0.96, 1.0, alpha * 0.44))
	elif _style == "power":
		draw_line(_from + normal * 3.5, _to, Color(1.0, 0.9, 0.54, alpha * 0.38), width + 1.0, true)
		draw_line(_from - normal * 3.5, _to, Color(1.0, 0.76, 0.26, alpha * 0.28), width, true)
		draw_circle(_to, width * 0.54, Color(1.0, 0.88, 0.48, alpha * 0.5))
	elif _style == "arrow":
		var tip_dir: Vector2 = (_to - _from).normalized()
		var tip_left: Vector2 = _to - tip_dir * 8.0 + normal * 4.0
		var tip_right: Vector2 = _to - tip_dir * 8.0 - normal * 4.0
		draw_line(tip_left, _to, Color(1.0, 0.96, 0.82, alpha * 0.82), 1.8, true)
		draw_line(tip_right, _to, Color(1.0, 0.96, 0.82, alpha * 0.82), 1.8, true)
	elif _style == "sentinel":
		draw_line(_from + normal * 4.0, _to, Color(1.0, 0.9, 0.54, alpha * 0.34), width, true)
		draw_arc(_to, width * 1.6, 0.0, TAU, 12, Color(1.0, 0.95, 0.8, alpha * 0.35), 1.6)
	else:
		draw_circle(_to, width * 0.36, Color(color.r, color.g, color.b, alpha * 0.5))

func _update_shader_params() -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("tint", color)
	shader_material.set_shader_parameter("pulse_strength", 0.12 if _style == "arrow" else 0.18)
	shader_material.set_shader_parameter("pulse_speed", 10.0 if _style == "dash" else 7.0)
	shader_material.set_shader_parameter("shimmer_amount", 0.08)
