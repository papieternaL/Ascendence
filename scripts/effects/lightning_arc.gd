extends Node2D

const PULSE_SHADER: Shader = preload("res://shaders/effects/additive_pulse.gdshader")

@export var duration: float = 0.1
@export var color: Color = Color(0.56, 0.82, 1.0, 0.95)
@export var width: float = 2.4

var _time: float = 0.0
var _segments: PackedVector2Array = PackedVector2Array()
var _branch_segments: Array[PackedVector2Array] = []

func _ready() -> void:
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = PULSE_SHADER
	material = shader_material
	_update_shader_params()

func setup(from: Vector2, to: Vector2, tint: Color, line_width: float = 2.4) -> void:
	color = tint
	width = line_width
	_segments = PackedVector2Array()
	_branch_segments.clear()
	var distance: float = from.distance_to(to)
	var steps: int = max(3, int(ceil(distance / 28.0)))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var point: Vector2 = from.lerp(to, t)
		if i > 0 and i < steps:
			var normal: Vector2 = (to - from).orthogonal().normalized()
			point += normal * randf_range(-10.0, 10.0)
		_segments.append(point)
	if _segments.size() >= 4:
		for branch_index in [1, _segments.size() / 2]:
			var idx: int = clampi(int(branch_index), 1, _segments.size() - 2)
			var branch_dir: Vector2 = (_segments[idx + 1] - _segments[idx - 1]).orthogonal().normalized()
			var branch_len: float = randf_range(16.0, 28.0)
			_branch_segments.append(PackedVector2Array([
				_segments[idx],
				_segments[idx] + branch_dir * branch_len,
			]))
	_update_shader_params()
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_update_shader_params()
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	if _segments.size() < 2:
		return
	var alpha: float = 1.0 - clamp(_time / max(duration, 0.001), 0.0, 1.0)
	for i in range(_segments.size() - 1):
		draw_line(_segments[i], _segments[i + 1], Color(color.r, color.g, color.b, color.a * alpha * 0.36), width + 2.2, true)
		draw_line(_segments[i], _segments[i + 1], Color(color.r, color.g, color.b, color.a * alpha), width, true)
		draw_line(_segments[i], _segments[i + 1], Color(1.0, 0.98, 0.88, alpha * 0.5), max(width - 1.0, 1.0), true)
	for branch in _branch_segments:
		if branch.size() < 2:
			continue
		draw_line(branch[0], branch[1], Color(color.r, color.g, color.b, color.a * alpha * 0.7), max(width - 0.8, 1.0), true)
		draw_line(branch[0], branch[1], Color(1.0, 0.98, 0.9, alpha * 0.34), 1.0, true)
	draw_circle(_segments[0], width * 0.82, Color(1.0, 0.98, 0.88, alpha * 0.24))
	draw_circle(_segments[_segments.size() - 1], width * 1.04, Color(1.0, 0.98, 0.88, alpha * 0.32))

func _update_shader_params() -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("tint", color)
	shader_material.set_shader_parameter("pulse_strength", 0.26)
	shader_material.set_shader_parameter("pulse_speed", 14.0)
	shader_material.set_shader_parameter("shimmer_amount", 0.16)
