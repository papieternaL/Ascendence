extends Node2D

const PULSE_SHADER: Shader = preload("res://shaders/effects/additive_pulse.gdshader")
const HEAT_SHADER: Shader = preload("res://shaders/effects/heat_shimmer.gdshader")

@export var duration: float = 0.22
@export var color: Color = Color(1.0, 0.6, 0.2, 0.92)
@export var accent_color: Color = Color(1.0, 0.86, 0.6, 0.85)
@export var radius: float = 22.0
@export var effect_style: String = "fire"

var _time: float = 0.0

func _ready() -> void:
	_apply_shader()

func configure(next_style: String, next_color: Color, next_accent: Color, next_radius: float = 22.0, next_duration: float = 0.22) -> void:
	effect_style = next_style
	color = next_color
	accent_color = next_accent
	radius = next_radius
	duration = next_duration
	_apply_shader()

func _process(delta: float) -> void:
	_time += delta
	_update_shader_params()
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_time / max(duration, 0.001), 0.0, 1.0)
	var alpha: float = (1.0 - t)
	var live_radius: float = lerp(radius * 0.32, radius, t)
	match effect_style:
		"fire":
			for i in range(5):
				var angle: float = TAU * float(i) / 4.0 + t * 0.8
				var pos: Vector2 = Vector2.RIGHT.rotated(angle) * live_radius * 0.26
				draw_circle(pos, live_radius * 0.2, Color(color.r, color.g, color.b, color.a * alpha * 0.65))
				draw_circle(pos * 0.72, live_radius * 0.08, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.4))
			draw_arc(Vector2.ZERO, live_radius * 0.72, 0.0, TAU, 22, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha), 2.0)
			for i in range(3):
				var spark_angle: float = -0.4 + float(i) * 0.4
				var spark: Vector2 = Vector2.RIGHT.rotated(spark_angle + t) * live_radius * 0.86
				draw_line(Vector2.ZERO, spark, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.55), 1.6, true)
		"ice":
			for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
				var axis: Vector2 = Vector2.RIGHT.rotated(angle) * live_radius * 0.78
				draw_line(-axis, axis, Color(color.r, color.g, color.b, color.a * alpha), 2.0, true)
			draw_arc(Vector2.ZERO, live_radius * 0.86, 0.0, TAU, 20, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.9), 2.0)
			draw_circle(Vector2.ZERO, live_radius * 0.34, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.12))
			for i in range(3):
				var mist_angle: float = PI * 0.5 + float(i) * 0.9
				var mist_pos: Vector2 = Vector2.RIGHT.rotated(mist_angle) * live_radius * 0.28
				draw_circle(mist_pos + Vector2(0.0, -live_radius * 0.16), live_radius * 0.16, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.08))
		"lightning":
			for i in range(4):
				var x: float = -live_radius * 0.45 + float(i) * live_radius * 0.28
				draw_line(Vector2(x, -live_radius * 0.78), Vector2(x + live_radius * 0.16, -live_radius * 0.06), Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha), 2.0, true)
				draw_line(Vector2(x + live_radius * 0.16, -live_radius * 0.06), Vector2(x - live_radius * 0.08, live_radius * 0.56), Color(color.r, color.g, color.b, color.a * alpha), 2.0, true)
			draw_arc(Vector2.ZERO, live_radius * 0.7, 0.0, TAU, 18, Color(color.r, color.g, color.b, color.a * alpha * 0.62), 2.0)
			draw_circle(Vector2.ZERO, live_radius * 0.18, Color(accent_color.r, accent_color.g, accent_color.b, accent_color.a * alpha * 0.7))
		_:
			draw_arc(Vector2.ZERO, live_radius, 0.0, TAU, 18, Color(color.r, color.g, color.b, color.a * alpha), 2.0)

func _apply_shader() -> void:
	var shader: Shader = HEAT_SHADER if effect_style == "fire" else PULSE_SHADER
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
	if effect_style == "fire":
		shader_material.set_shader_parameter("heat_strength", 0.36)
		shader_material.set_shader_parameter("flicker_speed", 10.0)
	else:
		shader_material.set_shader_parameter("pulse_strength", 0.22)
		shader_material.set_shader_parameter("pulse_speed", 10.0 if effect_style == "lightning" else 7.0)
		shader_material.set_shader_parameter("shimmer_amount", 0.12)
