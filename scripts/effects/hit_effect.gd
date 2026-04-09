extends Node2D

const PULSE_SHADER: Shader = preload("res://shaders/effects/additive_pulse.gdshader")
const HEAT_SHADER: Shader = preload("res://shaders/effects/heat_shimmer.gdshader")

@export var duration: float = 0.1
@export var start_radius: float = 4.0
@export var end_radius: float = 16.0
@export var color: Color = Color(0.5, 0.9, 1.0, 0.9)
@export var effect_style: String = "arrow"
@export var particle_amount: int = 6
@export var particle_lifetime: float = 0.12
@export var particle_speed: float = 88.0

var _time: float = 0.0
var _particles: GPUParticles2D
var _particle_material: ParticleProcessMaterial

func _ready() -> void:
	_apply_shader()
	_ensure_particles()
	_refresh_particles()

func configure(next_color: Color, next_style: String = "arrow", next_start_radius: float = -1.0, next_end_radius: float = -1.0, next_duration: float = -1.0) -> void:
	color = next_color
	effect_style = next_style
	if next_start_radius > 0.0:
		start_radius = next_start_radius
	if next_end_radius > 0.0:
		end_radius = next_end_radius
	if next_duration > 0.0:
		duration = next_duration
	_apply_style_defaults()
	_apply_shader()
	_refresh_particles()

func _process(delta: float) -> void:
	_time += delta
	_update_shader_params()
	queue_redraw()
	if _time >= duration:
		queue_free()

func _draw() -> void:
	var reduced_flashes: bool = GameSettings and GameSettings.use_reduced_flashes()
	var t: float = clampf(_time / max(duration, 0.001), 0.0, 1.0)
	var radius: float = lerpf(start_radius, end_radius, t)
	var alpha_scale: float = 0.72 if reduced_flashes else 1.0
	var a: float = (1.0 - t) * color.a * alpha_scale
	draw_circle(Vector2.ZERO, radius * 0.18, Color(color.r, color.g, color.b, a * 0.16))
	match effect_style:
		"heavy":
			draw_circle(Vector2.ZERO, radius * 0.22, Color(1.0, 0.96, 0.84, a * 0.24))
			draw_arc(Vector2.ZERO, radius * 0.88, 0.0, TAU, 20, Color(1.0, 0.94, 0.8, a * 0.86), 2.8)
			for i in range(7):
				var angle: float = TAU * float(i) / 7.0 + t * 0.32
				var inner: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.18)
				var outer: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 1.08)
				draw_line(inner, outer, Color(color.r, color.g, color.b, a), 2.6, true)
			draw_circle(Vector2.ZERO, radius * 0.56, Color(color.r, color.g, color.b, a * 0.08))
		"power":
			draw_arc(Vector2.ZERO, radius * 0.78, 0.0, TAU, 18, Color(1.0, 0.95, 0.82, a * 0.8), 2.2)
			for i in range(6):
				var angle: float = TAU * float(i) / 6.0 + t * 0.45
				var inner: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.18)
				var outer: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.96)
				draw_line(inner, outer, Color(color.r, color.g, color.b, a), 2.4, true)
		"sentinel":
			draw_arc(Vector2.ZERO, radius * 0.54, 0.0, TAU, 18, Color(color.r, color.g, color.b, a * 0.72), 1.8)
			draw_line(Vector2(-radius * 0.38, -radius * 0.18), Vector2(radius * 0.7, 0.0), Color(color.r, color.g, color.b, a), 2.2, true)
			draw_line(Vector2(-radius * 0.28, radius * 0.24), Vector2(radius * 0.62, -radius * 0.05), Color(1.0, 0.95, 0.78, a * 0.88), 2.0, true)
		"flash":
			draw_circle(Vector2.ZERO, radius * 0.14, Color(1.0, 0.96, 0.84, a * 0.32))
			for i in range(5):
				var angle: float = TAU * float(i) / 5.0
				var start: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.1)
				var finish: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.72)
				draw_line(start, finish, Color(color.r, color.g, color.b, a), 1.8, true)
		"volley":
			draw_line(Vector2(-radius * 0.48, 0.0), Vector2(radius * 0.62, 0.0), Color(color.r, color.g, color.b, a), 1.8, true)
			draw_line(Vector2(radius * 0.08, -radius * 0.18), Vector2(radius * 0.62, 0.0), Color(1.0, 0.95, 0.82, a * 0.92), 1.6, true)
			draw_line(Vector2(radius * 0.08, radius * 0.18), Vector2(radius * 0.62, 0.0), Color(1.0, 0.95, 0.82, a * 0.92), 1.6, true)
		_:
			draw_line(Vector2(-radius * 0.42, 0.0), Vector2(radius * 0.62, 0.0), Color(color.r, color.g, color.b, a), 2.0, true)
			draw_line(Vector2(radius * 0.08, -radius * 0.22), Vector2(radius * 0.62, 0.0), Color(1.0, 0.95, 0.82, a * 0.92), 1.8, true)
			draw_line(Vector2(radius * 0.08, radius * 0.22), Vector2(radius * 0.62, 0.0), Color(1.0, 0.95, 0.82, a * 0.92), 1.8, true)
			draw_line(Vector2(-radius * 0.18, -radius * 0.28), Vector2.ZERO, Color(1.0, 0.92, 0.74, a * 0.56), 1.4, true)
			draw_line(Vector2(-radius * 0.18, radius * 0.28), Vector2.ZERO, Color(1.0, 0.92, 0.74, a * 0.56), 1.4, true)

func _apply_style_defaults() -> void:
	match effect_style:
		"heavy":
			particle_amount = 10
			particle_lifetime = 0.16
			particle_speed = 126.0
		"power":
			particle_amount = 9
			particle_lifetime = 0.16
			particle_speed = 118.0
		"sentinel":
			particle_amount = 8
			particle_lifetime = 0.15
			particle_speed = 102.0
		"flash":
			particle_amount = 5
			particle_lifetime = 0.08
			particle_speed = 72.0
		"volley":
			particle_amount = 5
			particle_lifetime = 0.1
			particle_speed = 84.0
		_:
			particle_amount = 6
			particle_lifetime = 0.11
			particle_speed = 88.0

func _ensure_particles() -> void:
	if _particles != null:
		return
	_particles = GPUParticles2D.new()
	_particles.name = "Particles"
	_particles.one_shot = true
	_particles.emitting = false
	_particles.explosiveness = 1.0
	_particles.local_coords = true
	_particles.amount = particle_amount
	_particles.lifetime = particle_lifetime
	_particles.visibility_rect = Rect2(Vector2(-40.0, -40.0), Vector2(80.0, 80.0))
	_particle_material = ParticleProcessMaterial.new()
	_particle_material.gravity = Vector3.ZERO
	_particle_material.spread = 32.0
	_particle_material.initial_velocity_min = particle_speed * 0.65
	_particle_material.initial_velocity_max = particle_speed
	_particle_material.scale_min = 1.2
	_particle_material.scale_max = 2.2
	_particle_material.direction = Vector3.RIGHT
	_particle_material.color = Color(1.0, 1.0, 1.0, 1.0)
	_particles.process_material = _particle_material
	add_child(_particles)

func _refresh_particles() -> void:
	_apply_style_defaults()
	_ensure_particles()
	if _particles == null or _particle_material == null:
		return
	var reduced_flashes: bool = GameSettings and GameSettings.use_reduced_flashes()
	var amount_scale: float = 0.7 if reduced_flashes else 1.0
	_particles.amount = max(3, int(round(float(particle_amount) * amount_scale)))
	_particles.lifetime = particle_lifetime
	_particle_material.initial_velocity_min = particle_speed * 0.65
	_particle_material.initial_velocity_max = particle_speed
	_particle_material.spread = 18.0 if effect_style == "flash" else 36.0
	_particle_material.scale_min = 0.9 if effect_style == "flash" else 1.2
	_particle_material.scale_max = 1.6 if effect_style == "flash" else 2.2
	_particle_material.color = Color(color.r, color.g, color.b, 0.95 if not reduced_flashes else 0.68)
	_particles.restart()
	_particles.emitting = true

func _apply_shader() -> void:
	var shader: Shader = HEAT_SHADER if effect_style == "power" else PULSE_SHADER
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
	if effect_style == "power":
		shader_material.set_shader_parameter("heat_strength", 0.24)
		shader_material.set_shader_parameter("flicker_speed", 10.0)
	else:
		shader_material.set_shader_parameter("pulse_strength", 0.12)
		shader_material.set_shader_parameter("pulse_speed", 10.0)
		shader_material.set_shader_parameter("shimmer_amount", 0.05)
