extends CharacterBody2D

signal died

const WEAPON_BOW_TEXTURE_PATH: String = "res://art/player/player_bow_equipped.png"
const WEAPON_PISTOL_TEXTURE_PATH: String = "res://art/player/player_arcane_pistol_equipped.png"
const WEAPON_SNIPER_TEXTURE_PATH: String = "res://art/player/player_arcane_sniper_equipped.png"

@export var move_speed: float = 224.0
@export var max_health: float = 1000.0
@export var invulnerability_time: float = 0.35
@export var dash_distance: float = 170.0
@export var dash_fx_duration: float = 0.12
@export var mobility_style: String = "dash"
@export var weapon_style: String = "bow"
@export var footstep_surface: String = "grass"
@export var footstep_distance: float = 46.0

var health: float
var invulnerability_remaining: float = 0.0
var aim_direction: Vector2 = Vector2.RIGHT
var rooted_remaining: float = 0.0
var dash_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_speed: float = 0.0
var shoot_flash_remaining: float = 0.0
var hit_flash_remaining: float = 0.0
var movement_input_enabled: bool = true
var environmental_force: Vector2 = Vector2.ZERO
var _footstep_distance_accum: float = 0.0
var _cast_preview: Dictionary = {}
var _weapon_texture_cache: Dictionary = {}

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var ability_anchor: Node2D = $AbilityAnchor
@onready var body_sprite: Sprite2D = $Sprite2D
@onready var weapon_sprite: Sprite2D = _ensure_weapon_sprite()

func _ready() -> void:
	add_to_group("player")
	health = max_health
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sync_body_sprite_visual()
	_sync_weapon_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	var last_position: Vector2 = global_position
	var input_vector: Vector2 = Vector2.ZERO
	if invulnerability_remaining > 0.0:
		invulnerability_remaining = max(invulnerability_remaining - delta, 0.0)
	if rooted_remaining > 0.0:
		rooted_remaining = max(rooted_remaining - delta, 0.0)
	if dash_remaining > 0.0:
		dash_remaining = max(dash_remaining - delta, 0.0)
	if shoot_flash_remaining > 0.0:
		shoot_flash_remaining = max(shoot_flash_remaining - delta, 0.0)
	if hit_flash_remaining > 0.0:
		hit_flash_remaining = max(hit_flash_remaining - delta, 0.0)
	if dash_remaining > 0.0:
		if mobility_style == "dash":
			velocity = dash_direction * dash_speed
		else:
			velocity = Vector2.ZERO
	else:
		if rooted_remaining <= 0.0 and movement_input_enabled:
			input_vector = _get_requested_move_vector()
		velocity = input_vector * move_speed + environmental_force
	move_and_slide()
	_update_footsteps(last_position, input_vector)
	_sync_body_sprite_visual()
	_sync_weapon_visual()
	queue_redraw()

func get_muzzle_global_position() -> Vector2:
	return muzzle.global_position

func set_aim_target(target_position: Vector2) -> void:
	var new_direction: Vector2 = global_position.direction_to(target_position)
	if new_direction.length_squared() <= 0.0001:
		return
	aim_direction = new_direction.normalized()
	weapon_pivot.rotation = aim_direction.angle()
	queue_redraw()

func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0 or invulnerability_remaining > 0.0:
		return
	health = max(health - amount, 0.0)
	invulnerability_remaining = invulnerability_time
	hit_flash_remaining = 0.18
	if has_node("/root/GameEvents"):
		GameEvents.player_damaged.emit(amount)
	queue_redraw()
	if health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0:
		return
	health = min(health + amount, max_health)
	if has_node("/root/GameEvents") and GameEvents.has_signal("player_healed"):
		GameEvents.player_healed.emit(amount)
	queue_redraw()

func apply_root(duration: float) -> void:
	rooted_remaining = max(rooted_remaining, duration)
	queue_redraw()

func clear_root() -> void:
	rooted_remaining = 0.0
	queue_redraw()

func set_environment_force(force: Vector2) -> void:
	environmental_force = force

func set_movement_input_enabled(enabled: bool) -> void:
	movement_input_enabled = enabled

func start_dash(direction: Vector2) -> bool:
	if rooted_remaining > 0.0:
		return false
	var movement_dash_dir: Vector2 = _get_requested_move_vector()
	var dash_dir: Vector2 = movement_dash_dir.normalized()
	if dash_dir.length_squared() <= 0.0001:
		dash_dir = direction.normalized()
	if dash_dir.length_squared() <= 0.0001:
		dash_dir = aim_direction
	if dash_dir.length_squared() <= 0.0001:
		dash_dir = Vector2.RIGHT
	dash_direction = dash_dir.normalized()
	if mobility_style == "blink":
		global_position += dash_direction * dash_distance
		dash_speed = 0.0
	else:
		dash_speed = dash_distance / max(dash_fx_duration, 0.01)
	dash_remaining = dash_fx_duration
	invulnerability_remaining = max(invulnerability_remaining, dash_fx_duration)
	queue_redraw()
	return true

func notify_primary_fired() -> void:
	shoot_flash_remaining = 0.12
	queue_redraw()

func set_cast_preview(preview: Dictionary) -> void:
	_cast_preview = preview.duplicate(true)
	queue_redraw()

func clear_cast_preview() -> void:
	if _cast_preview.is_empty():
		return
	_cast_preview.clear()
	queue_redraw()

func _get_requested_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _update_footsteps(last_position: Vector2, input_vector: Vector2) -> void:
	if dash_remaining > 0.0 or not movement_input_enabled:
		_footstep_distance_accum = 0.0
		return
	if input_vector.length_squared() <= 0.001:
		_footstep_distance_accum = 0.0
		return
	var moved_distance: float = global_position.distance_to(last_position)
	if moved_distance <= 0.01:
		return
	_footstep_distance_accum += moved_distance
	var interval: float = maxf(footstep_distance, 8.0)
	while _footstep_distance_accum >= interval:
		_footstep_distance_accum -= interval
		_play_footstep()

func _play_footstep() -> void:
	if AudioDirector == null:
		return
	var event_id: String = "footstep_stone" if footstep_surface == "stone" else "footstep_grass"
	AudioDirector.play_sfx(event_id, -6.0)

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(health / max_health, 0.0, 1.0)

func add_screen_shake(intensity: float, duration: float = 0.12) -> void:
	var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if camera.has_method("shake"):
		camera.call("shake", intensity, duration)

func _uses_body_sprite() -> bool:
	return body_sprite != null and body_sprite.texture != null

func _uses_textured_weapon() -> bool:
	return weapon_sprite != null and weapon_sprite.texture != null

func _ensure_weapon_sprite() -> Sprite2D:
	if weapon_pivot == null:
		return null
	var sprite: Sprite2D = weapon_pivot.get_node_or_null("WeaponSprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "WeaponSprite"
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		weapon_pivot.add_child(sprite)
		weapon_pivot.move_child(sprite, 0)
	return sprite

func _sync_body_sprite_visual() -> void:
	if body_sprite == null:
		return
	var using_sprite: bool = _uses_body_sprite()
	body_sprite.visible = using_sprite
	if not using_sprite:
		return
	var flash: float = 0.35 if invulnerability_remaining > 0.0 else 0.0
	var hit_mix: float = clamp(hit_flash_remaining / 0.18, 0.0, 1.0)
	var sprite_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	sprite_color = sprite_color.lerp(Color(1.0, 0.72, 0.72, 1.0), hit_mix * 0.55)
	sprite_color = sprite_color.lerp(Color(1.0, 1.0, 1.0, 1.0), flash * 0.3)
	body_sprite.modulate = sprite_color

func _sync_weapon_visual() -> void:
	if weapon_sprite == null:
		return
	var config: Dictionary = _get_weapon_visual_config()
	var texture: Texture2D = config.get("texture", null) as Texture2D
	weapon_sprite.visible = texture != null
	if texture == null:
		return
	weapon_sprite.texture = texture
	var texture_width: float = maxf(float(texture.get_width()), 1.0)
	var target_width: float = float(config.get("target_width", texture_width))
	var base_scale: float = target_width / texture_width
	var aim_x: float = aim_direction.x
	var aim_y: float = aim_direction.y
	var aiming_left: bool = aim_direction.x < 0.0
	var vertical_dominant: bool = absf(aim_y) > absf(aim_x)
	var aiming_up: bool = vertical_dominant and aim_y < 0.0
	var aiming_down: bool = vertical_dominant and aim_y > 0.0
	var scale_x: float = base_scale * float(config.get("scale_x", 1.0))
	var scale_y: float = base_scale * float(config.get("scale_y", 1.0))
	weapon_sprite.flip_v = aiming_left and bool(config.get("flip_upright_on_left", false))
	weapon_sprite.flip_h = false
	weapon_sprite.scale = Vector2(
		scale_x,
		scale_y
	)
	var visual_x: float = float(config.get("x", 0.0))
	var visual_y: float = float(config.get("y", 0.0))
	if aiming_up:
		visual_x = float(config.get("up_x", visual_x))
		visual_y = float(config.get("up_y", visual_y))
	elif aiming_down:
		visual_x = float(config.get("down_x", visual_x))
		visual_y = float(config.get("down_y", visual_y))
	elif aiming_left:
		visual_x = float(config.get("left_x", visual_x))
		visual_y = float(config.get("left_y", visual_y))
	weapon_sprite.position = Vector2(visual_x, visual_y)
	weapon_sprite.modulate = config.get("modulate", Color.WHITE)
	if muzzle != null:
		var muzzle_x: float = float(config.get("muzzle_x", 14.0))
		var muzzle_y: float = float(config.get("muzzle_y", 0.0))
		if aiming_up:
			muzzle_x = float(config.get("up_muzzle_x", muzzle_x))
			muzzle_y = float(config.get("up_muzzle_y", muzzle_y))
		elif aiming_down:
			muzzle_x = float(config.get("down_muzzle_x", muzzle_x))
			muzzle_y = float(config.get("down_muzzle_y", muzzle_y))
		elif aiming_left:
			muzzle_x = float(config.get("left_muzzle_x", muzzle_x))
			muzzle_y = float(config.get("left_muzzle_y", muzzle_y))
		muzzle.position = Vector2(muzzle_x, muzzle_y)

func _get_weapon_visual_config() -> Dictionary:
	match weapon_style:
		"bow":
			return {
				"texture": _load_weapon_texture(WEAPON_BOW_TEXTURE_PATH),
				"target_width": 58.0,
				"scale_x": 1.0,
				"scale_y": 1.0,
				"x": 12.0,
				"y": 0.0,
				"left_x": 12.0,
				"left_y": 0.0,
				"up_x": 12.0,
				"up_y": 0.0,
				"down_x": 12.0,
				"down_y": 0.0,
				"muzzle_x": 12.0,
				"muzzle_y": 0.0,
				"left_muzzle_x": 12.0,
				"left_muzzle_y": 0.0,
				"up_muzzle_x": 12.0,
				"up_muzzle_y": 0.0,
				"down_muzzle_x": 12.0,
				"down_muzzle_y": 0.0,
				"flip_upright_on_left": true,
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
			}
		"sniper":
			return {
				"texture": _load_weapon_texture(WEAPON_SNIPER_TEXTURE_PATH),
				"target_width": 38.0,
				"scale_x": 1.0,
				"scale_y": 1.0,
				"x": 16.0,
				"y": 0.0,
				"left_x": 16.0,
				"left_y": 0.0,
				"up_x": 14.0,
				"up_y": -4.0,
				"down_x": 14.0,
				"down_y": 4.0,
				"muzzle_x": 28.0,
				"muzzle_y": 0.0,
				"left_muzzle_x": 28.0,
				"left_muzzle_y": 0.0,
				"up_muzzle_x": 24.0,
				"up_muzzle_y": 0.0,
				"down_muzzle_x": 24.0,
				"down_muzzle_y": 0.0,
				"flip_upright_on_left": true,
				"modulate": Color(0.88, 0.98, 1.0, 1.0),
			}
		_:
			return {
				"texture": _load_weapon_texture(WEAPON_PISTOL_TEXTURE_PATH),
				"target_width": 30.0,
				"scale_x": 1.0,
				"scale_y": 1.0,
				"x": 13.0,
				"y": 0.0,
				"left_x": 13.0,
				"left_y": 0.0,
				"up_x": 11.0,
				"up_y": -4.0,
				"down_x": 11.0,
				"down_y": 4.0,
				"muzzle_x": 22.0,
				"muzzle_y": 0.0,
				"left_muzzle_x": 22.0,
				"left_muzzle_y": 0.0,
				"up_muzzle_x": 20.0,
				"up_muzzle_y": 0.0,
				"down_muzzle_x": 20.0,
				"down_muzzle_y": 0.0,
				"flip_upright_on_left": true,
				"modulate": Color(1.0, 1.0, 1.0, 1.0),
			}

func _load_weapon_texture(resource_path: String) -> Texture2D:
	if _weapon_texture_cache.has(resource_path):
		return _weapon_texture_cache[resource_path] as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(resource_path):
		texture = load(resource_path) as Texture2D
	if texture == null and FileAccess.file_exists(resource_path):
		var image: Image = Image.load_from_file(resource_path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture == null:
		var global_path: String = ProjectSettings.globalize_path(resource_path)
		if FileAccess.file_exists(global_path):
			var fallback_image: Image = Image.load_from_file(global_path)
			if fallback_image != null and not fallback_image.is_empty():
				texture = ImageTexture.create_from_image(fallback_image)
	_weapon_texture_cache[resource_path] = texture
	return texture

func _draw() -> void:
	var flash: float = 0.35 if invulnerability_remaining > 0.0 else 0.0
	var hit_mix: float = clamp(hit_flash_remaining / 0.18, 0.0, 1.0)
	var using_sprite: bool = _uses_body_sprite()
	draw_circle(Vector2(0, 4), 10.0, Color(0.06, 0.14, 0.18, 0.28))
	if dash_remaining > 0.0:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.74, 0.92, 1.0, 0.85), 4.0)
	if rooted_remaining > 0.0:
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(0.48, 0.84, 0.46, 0.8), 3.0)
	if hit_mix > 0.0:
		draw_arc(Vector2.ZERO, 20.0 + hit_mix * 4.0, 0.0, TAU, 24, Color(1.0, 0.42, 0.38, 0.72 * hit_mix), 3.0)
	_draw_cast_preview()
	_draw_weapon_muzzle_flash()
	if using_sprite:
		return
	var body_color: Color = Color(0.45 + flash, 0.72 + flash * 0.4, 1.0, 1.0)
	body_color = body_color.lerp(Color(1.0, 0.48, 0.42, 1.0), hit_mix * 0.58)
	draw_circle(Vector2.ZERO, 10.0, body_color)
	draw_circle(Vector2(0, -10), 5.5, Color(0.95, 0.84, 0.56, 1.0))
	if _uses_textured_weapon():
		return
	if weapon_style == "bow":
		_draw_bow_weapon()
	else:
		_draw_pistol_weapon()

func _draw_weapon_muzzle_flash() -> void:
	if shoot_flash_remaining <= 0.0 or muzzle == null:
		return
	var flash_origin: Vector2 = muzzle.position.rotated(weapon_pivot.rotation)
	if weapon_style == "bow":
		draw_arc(flash_origin, 7.0 + shoot_flash_remaining * 12.0, 0.0, TAU, 20, Color(1.0, 0.88, 0.46, 0.6), 2.0)
		return
	var flash_color: Color = Color(0.88, 0.98, 1.0, 0.78) if weapon_style == "sniper" else Color(0.7, 0.95, 1.0, 0.75)
	draw_arc(flash_origin, 6.0 + shoot_flash_remaining * 10.0, 0.0, TAU, 18, flash_color, 2.0)

func _draw_bow_weapon() -> void:
	var forward: Vector2 = aim_direction.normalized()
	var right: Vector2 = forward.orthogonal()
	var bow_center: Vector2 = forward * 10.0
	var arc_offset: float = 6.0 + shoot_flash_remaining * 22.0
	var top: Vector2 = bow_center + right * 11.0
	var mid: Vector2 = bow_center + forward * 8.0
	var bottom: Vector2 = bow_center - right * 11.0
	draw_line(top, mid, Color(0.48, 0.28, 0.14, 1.0), 3.0, true)
	draw_line(mid, bottom, Color(0.58, 0.34, 0.16, 1.0), 3.0, true)
	var string_anchor: Vector2 = bow_center - forward * arc_offset
	draw_line(top, string_anchor, Color(0.92, 0.88, 0.72, 0.95), 1.5, true)
	draw_line(string_anchor, bottom, Color(0.92, 0.88, 0.72, 0.95), 1.5, true)
	draw_line(bow_center - forward * 4.0, bow_center + forward * 14.0, Color(0.8, 0.66, 0.36, 0.9), 2.0, true)
	draw_line(bow_center + forward * 11.0 + right * 2.0, bow_center + forward * 16.0, Color(1.0, 0.9, 0.66, 0.95), 2.0, true)
	draw_line(bow_center + forward * 11.0 - right * 2.0, bow_center + forward * 16.0, Color(1.0, 0.9, 0.66, 0.95), 2.0, true)

func _draw_pistol_weapon() -> void:
	var gun_start: Vector2 = aim_direction * 4.0
	var gun_end: Vector2 = aim_direction * 18.0
	draw_line(gun_start, gun_end, Color(1.0, 0.9, 0.6, 0.95), 3.0, true)
	draw_line(gun_start + aim_direction.orthogonal() * 2.0, gun_start - aim_direction.orthogonal() * 3.0, Color(0.44, 0.34, 0.24, 1.0), 3.0, true)

func _draw_cast_preview() -> void:
	if _cast_preview.is_empty():
		return
	var kind: String = str(_cast_preview.get("kind", ""))
	var direction: Vector2 = Vector2(_cast_preview.get("direction", aim_direction))
	if direction.length_squared() <= 0.0001:
		direction = aim_direction if aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	direction = direction.normalized()
	var color: Color = _cast_preview.get("color", Color(0.74, 0.92, 1.0, 0.78))
	match kind:
		"line":
			_draw_preview_line(direction, float(_cast_preview.get("length", 180.0)), color, float(_cast_preview.get("width", 2.2)))
		"cone":
			_draw_preview_cone(direction, float(_cast_preview.get("length", 180.0)), float(_cast_preview.get("spread_degrees", 18.0)), color)
		"dash":
			_draw_preview_dash(direction, float(_cast_preview.get("length", dash_distance)), color)
		"fan":
			_draw_preview_fan(
				direction,
				float(_cast_preview.get("length", 180.0)),
				int(_cast_preview.get("count", 3)),
				float(_cast_preview.get("spread_degrees", 12.0)),
				color,
				_cast_preview.get("highlight_global_position", null)
			)
		"lob_line":
			_draw_preview_lob_line(
				direction,
				float(_cast_preview.get("length", 180.0)),
				float(_cast_preview.get("radius", 72.0)),
				color
			)
		"circle":
			_draw_preview_circle(
				_get_preview_local_position("ground_position", "target_position"),
				float(_cast_preview.get("radius", 72.0)),
				color
			)
		"reticle":
			_draw_preview_reticle(
				_get_preview_local_position("ground_position", "target_position"),
				float(_cast_preview.get("radius", 72.0)),
				color
			)

func _draw_preview_line(direction: Vector2, length: float, color: Color, width: float) -> void:
	var start: Vector2 = direction * 14.0
	var end: Vector2 = start + direction * length
	draw_line(start, end, color, width, true)
	draw_circle(end, 4.0, Color(color.r, color.g, color.b, 0.28))
	draw_arc(end, 6.0, 0.0, TAU, 18, Color(color.r, color.g, color.b, 0.72), 1.4)

func _draw_preview_cone(direction: Vector2, length: float, spread_degrees: float, color: Color) -> void:
	var half_angle: float = deg_to_rad(spread_degrees * 0.5)
	var left: Vector2 = direction.rotated(-half_angle) * length
	var right: Vector2 = direction.rotated(half_angle) * length
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, left, right]), Color(color.r, color.g, color.b, 0.12))
	draw_line(Vector2.ZERO, left, color, 1.6, true)
	draw_line(Vector2.ZERO, right, color, 1.6, true)
	draw_arc(Vector2.ZERO, length, direction.angle() - half_angle, direction.angle() + half_angle, 18, color, 1.2)

func _draw_preview_dash(direction: Vector2, length: float, color: Color) -> void:
	var end: Vector2 = direction * length
	draw_line(Vector2.ZERO, end, color, 2.4, true)
	draw_circle(end, 10.0, Color(color.r, color.g, color.b, 0.10))
	draw_arc(end, 12.0, 0.0, TAU, 20, color, 1.8)

func _draw_preview_fan(direction: Vector2, length: float, count: int, spread_degrees: float, color: Color, highlight_global: Variant) -> void:
	var clamped_count: int = max(count, 1)
	for i in range(clamped_count):
		var offset_index: float = float(i) - float(clamped_count - 1) * 0.5
		var rotated_direction: Vector2 = direction.rotated(deg_to_rad(offset_index * spread_degrees))
		_draw_preview_line(rotated_direction, length, Color(color.r, color.g, color.b, 0.72), 1.6)
	if highlight_global != null and typeof(highlight_global) == TYPE_VECTOR2:
		var local_target: Vector2 = to_local(highlight_global as Vector2)
		draw_circle(local_target, 12.0, Color(color.r, color.g, color.b, 0.08))
		draw_arc(local_target, 14.0, 0.0, TAU, 24, color, 1.6)

func _draw_preview_lob_line(direction: Vector2, length: float, radius: float, color: Color) -> void:
	var start: Vector2 = direction * 12.0
	var end: Vector2 = start + direction * length
	var mid: Vector2 = start.lerp(end, 0.5) + direction.orthogonal() * -22.0
	draw_line(start, mid, Color(color.r, color.g, color.b, color.a * 0.92), 1.8, true)
	draw_line(mid, end, Color(color.r, color.g, color.b, color.a * 0.92), 1.8, true)
	draw_circle(end, radius, Color(color.r, color.g, color.b, 0.08))
	draw_arc(end, radius, 0.0, TAU, 34, color, 1.5)
	draw_arc(end, maxf(radius - 10.0, 10.0), 0.0, TAU, 34, Color(color.r, color.g, color.b, color.a * 0.58), 1.1)

func _draw_preview_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.09))
	draw_arc(center, radius, 0.0, TAU, 40, color, 1.8)
	draw_arc(center, maxf(radius - 10.0, 8.0), 0.0, TAU, 40, Color(color.r, color.g, color.b, color.a * 0.65), 1.2)

func _draw_preview_reticle(center: Vector2, radius: float, color: Color) -> void:
	_draw_preview_circle(center, radius, color)
	draw_line(center + Vector2(-radius - 10.0, 0.0), center + Vector2(-radius + 4.0, 0.0), color, 1.4, true)
	draw_line(center + Vector2(radius - 4.0, 0.0), center + Vector2(radius + 10.0, 0.0), color, 1.4, true)
	draw_line(center + Vector2(0.0, -radius - 10.0), center + Vector2(0.0, -radius + 4.0), color, 1.4, true)
	draw_line(center + Vector2(0.0, radius - 4.0), center + Vector2(0.0, radius + 10.0), color, 1.4, true)

func _get_preview_local_position(primary_key: String, fallback_key: String) -> Vector2:
	var preview_target: Variant = _cast_preview.get(primary_key, _cast_preview.get(fallback_key, Vector2.ZERO))
	if typeof(preview_target) == TYPE_VECTOR2:
		return to_local(preview_target as Vector2)
	return Vector2.ZERO
