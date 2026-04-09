extends Camera2D

@export var framing_offset: Vector2 = Vector2(28.0, -42.0)
@export var locked_zoom: Vector2 = Vector2(0.92, 0.92)
@export var max_offset: float = 7.0
@export var reduced_flash_multiplier: float = 0.7
@export var impact_pan_strength: float = 5.5
@export var impact_pan_limit: float = 14.0
@export var impact_zoom_strength: float = 0.018
@export var impact_zoom_limit: float = 0.05
@export var impact_recover_speed: float = 8.0
@export var zoom_recover_speed: float = 8.0

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _impact_offset: Vector2 = Vector2.ZERO
var _impact_zoom: float = 0.0
var _external_framing_active: bool = false
var _external_zoom: Vector2 = Vector2.ONE
var _external_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	rotation = 0.0
	position = _get_base_offset()
	offset = Vector2.ZERO
	zoom = _get_base_zoom()

func set_external_framing(zoom_value: Vector2, offset_value: Vector2 = Vector2.ZERO) -> void:
	_external_framing_active = true
	_external_zoom = Vector2(maxf(zoom_value.x, 0.001), maxf(zoom_value.y, 0.001))
	_external_offset = offset_value
	position = _external_offset
	zoom = _external_zoom

func clear_external_framing() -> void:
	_external_framing_active = false
	position = framing_offset
	zoom = locked_zoom

func _get_base_zoom() -> Vector2:
	return _external_zoom if _external_framing_active else locked_zoom

func _get_base_offset() -> Vector2:
	return _external_offset if _external_framing_active else framing_offset

func shake(intensity: float, duration: float) -> void:
	if intensity <= 0.0 or duration <= 0.0:
		return
	var scaled_intensity: float = intensity
	if GameSettings and GameSettings.use_reduced_flashes():
		scaled_intensity *= reduced_flash_multiplier
	_shake_strength = max(_shake_strength, scaled_intensity)
	_shake_duration = max(_shake_duration, duration)
	_shake_time = max(_shake_time, duration)
	var kick_direction: Vector2 = Vector2(randf_range(-0.45, 0.45), -1.0).normalized()
	_impact_offset += kick_direction * (scaled_intensity * impact_pan_strength)
	_impact_offset = _impact_offset.limit_length(impact_pan_limit)
	_impact_zoom = minf(_impact_zoom + scaled_intensity * impact_zoom_strength, impact_zoom_limit)

func get_world_view_size() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	return Vector2(
		viewport_size.x / maxf(zoom.x, 0.001),
		viewport_size.y / maxf(zoom.y, 0.001)
	)

func _process(delta: float) -> void:
	rotation = 0.0
	position = _get_base_offset()
	var impact_lerp: float = 1.0 - exp(-impact_recover_speed * delta)
	var zoom_lerp: float = 1.0 - exp(-zoom_recover_speed * delta)
	_impact_offset = _impact_offset.lerp(Vector2.ZERO, impact_lerp)
	_impact_zoom = lerpf(_impact_zoom, 0.0, zoom_lerp)

	var shake_offset: Vector2 = Vector2.ZERO
	if _shake_time > 0.0 and _shake_duration > 0.0:
		_shake_time = max(_shake_time - delta, 0.0)
		var screen_shake_scale: float = GameSettings.screen_shake if GameSettings else 1.0
		var time_ratio: float = _shake_time / max(_shake_duration, 0.001)
		var strength: float = minf(_shake_strength * time_ratio * screen_shake_scale, max_offset)
		shake_offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
	if _shake_time <= 0.0:
		_shake_strength = 0.0
		_shake_duration = 0.0
	offset = _impact_offset + shake_offset
	var target_zoom: Vector2 = _get_base_zoom() + Vector2.ONE * _impact_zoom
	zoom = zoom.lerp(target_zoom, zoom_lerp)
