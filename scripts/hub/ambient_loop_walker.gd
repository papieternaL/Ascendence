extends Node2D

const VISUAL_MODE_HORIZONTAL: int = 0
const VISUAL_MODE_UP: int = 1
const VISUAL_MODE_DOWN: int = 2

@export var visual_root_path: NodePath
@export var waypoints: PackedVector2Array = PackedVector2Array()
@export var move_speed: float = 28.0
@export var pause_duration: float = 0.55
@export var phase_offset: float = 0.0
@export var flip_on_x: bool = true
@export var faces_right_at_positive_scale: bool = false
@export_range(1, 32, 1) var walk_hframes: int = 1
@export_range(1, 32, 1) var walk_vframes: int = 1
@export_range(0, 64, 1) var walk_frame_count: int = 0
@export var walk_fps: float = 8.0
@export var walk_up_texture: Texture2D
@export_range(1, 32, 1) var walk_up_hframes: int = 1
@export_range(1, 32, 1) var walk_up_vframes: int = 1
@export_range(0, 64, 1) var walk_up_frame_count: int = 0
@export var walk_up_fps: float = 0.0
@export var walk_down_texture: Texture2D
@export_range(1, 32, 1) var walk_down_hframes: int = 1
@export_range(1, 32, 1) var walk_down_vframes: int = 1
@export_range(0, 64, 1) var walk_down_frame_count: int = 0
@export var walk_down_fps: float = 0.0
@export_range(0.0, 1.0, 0.01) var up_direction_threshold: float = 0.62
@export_range(0, 63, 1) var idle_frame: int = 0

var _visual_root: Node2D
var _visual_sprite: Sprite2D
var _base_scale: Vector2 = Vector2.ONE
var _target_index: int = 1
var _pause_timer: float = 0.0
var _animation_time: float = 0.0
var _horizontal_texture: Texture2D
var _current_visual_mode: int = VISUAL_MODE_HORIZONTAL

func _ready() -> void:
	_visual_root = get_node_or_null(visual_root_path) as Node2D
	if _visual_root == null:
		for child in get_children():
			if child is Node2D:
				_visual_root = child as Node2D
				break
	if _visual_root != null:
		_base_scale = _visual_root.scale
		_visual_sprite = _visual_root as Sprite2D
		if _visual_sprite != null:
			_horizontal_texture = _visual_sprite.texture
			_apply_visual_mode(VISUAL_MODE_HORIZONTAL)
	if waypoints.size() < 2:
		_set_idle_frame()
		set_process(false)
		return
	position = waypoints[0]
	_target_index = 1
	_pause_timer = maxf(phase_offset, 0.0)
	_animation_time = maxf(phase_offset, 0.0) * maxf(walk_fps, 0.0)
	_update_visual_state(waypoints[_target_index] - position)
	_set_idle_frame()

func _process(delta: float) -> void:
	if waypoints.size() < 2:
		return
	if _pause_timer > 0.0:
		_pause_timer = maxf(0.0, _pause_timer - delta)
		_set_idle_frame()
		return
	var target: Vector2 = waypoints[_target_index]
	var to_target: Vector2 = target - position
	var distance: float = to_target.length()
	if distance <= 0.001:
		_arrive_at_target()
		return
	var direction: Vector2 = to_target / distance
	var step: float = move_speed * delta
	if step >= distance:
		position = target
		_arrive_at_target()
		return
	position += direction * step
	_update_visual_state(direction)
	_advance_walk_animation(delta)

func _arrive_at_target() -> void:
	position = waypoints[_target_index]
	_target_index = (_target_index + 1) % waypoints.size()
	_pause_timer = pause_duration
	_update_visual_state(waypoints[_target_index] - position)
	_set_idle_frame()

func _update_visual_state(direction: Vector2) -> void:
	if _visual_root == null:
		return
	_sync_visual_mode(direction)
	if _current_visual_mode == VISUAL_MODE_UP or _current_visual_mode == VISUAL_MODE_DOWN:
		_visual_root.scale = Vector2(absf(_base_scale.x), _base_scale.y)
		return
	if not flip_on_x:
		return
	if direction.x > 0.05:
		_set_horizontal_facing(true)
	elif direction.x < -0.05:
		_set_horizontal_facing(false)

func _set_horizontal_facing(face_right: bool) -> void:
	var sign: float = 1.0 if face_right == faces_right_at_positive_scale else -1.0
	_visual_root.scale = Vector2(sign * absf(_base_scale.x), _base_scale.y)

func _sync_visual_mode(direction: Vector2) -> void:
	if _visual_sprite == null:
		return
	var desired_mode: int = _determine_visual_mode(direction)
	if desired_mode == _current_visual_mode:
		return
	_apply_visual_mode(desired_mode)
	_set_idle_frame()

func _determine_visual_mode(direction: Vector2) -> int:
	var vertical_strength: float = absf(direction.y)
	var horizontal_strength: float = absf(direction.x)
	if direction.y <= -0.08 and walk_up_texture != null and vertical_strength >= up_direction_threshold and vertical_strength > horizontal_strength:
		return VISUAL_MODE_UP
	if direction.y >= 0.08 and walk_down_texture != null and vertical_strength >= up_direction_threshold and vertical_strength > horizontal_strength:
		return VISUAL_MODE_DOWN
	return VISUAL_MODE_HORIZONTAL

func _apply_visual_mode(mode: int) -> void:
	if _visual_sprite == null:
		return
	_current_visual_mode = mode
	if mode == VISUAL_MODE_UP and walk_up_texture != null:
		_visual_sprite.texture = walk_up_texture
		_visual_sprite.hframes = max(walk_up_hframes, 1)
		_visual_sprite.vframes = max(walk_up_vframes, 1)
		return
	if mode == VISUAL_MODE_DOWN and walk_down_texture != null:
		_visual_sprite.texture = walk_down_texture
		_visual_sprite.hframes = max(walk_down_hframes, 1)
		_visual_sprite.vframes = max(walk_down_vframes, 1)
		return
	_visual_sprite.texture = _horizontal_texture
	_visual_sprite.hframes = max(walk_hframes, 1)
	_visual_sprite.vframes = max(walk_vframes, 1)

func _advance_walk_animation(delta: float) -> void:
	if _visual_sprite == null:
		return
	var frame_total: int = _resolve_frame_total()
	var fps: float = _resolve_animation_fps()
	if frame_total <= 1 or fps <= 0.0:
		return
	_animation_time += delta * fps
	_visual_sprite.frame = int(floor(_animation_time)) % frame_total

func _set_idle_frame() -> void:
	if _visual_sprite == null:
		return
	var frame_total: int = _resolve_frame_total()
	if frame_total <= 1:
		return
	_animation_time = 0.0
	_visual_sprite.frame = clampi(idle_frame, 0, frame_total - 1)

func _resolve_frame_total() -> int:
	if _current_visual_mode == VISUAL_MODE_UP:
		if walk_up_frame_count > 0:
			return walk_up_frame_count
		return max(_visual_sprite.hframes * _visual_sprite.vframes, 1)
	if _current_visual_mode == VISUAL_MODE_DOWN:
		if walk_down_frame_count > 0:
			return walk_down_frame_count
		return max(_visual_sprite.hframes * _visual_sprite.vframes, 1)
	if walk_frame_count > 0:
		return walk_frame_count
	if _visual_sprite == null:
		return 1
	return max(_visual_sprite.hframes * _visual_sprite.vframes, 1)

func _resolve_animation_fps() -> float:
	if _current_visual_mode == VISUAL_MODE_UP and walk_up_texture != null and walk_up_fps > 0.0:
		return walk_up_fps
	if _current_visual_mode == VISUAL_MODE_DOWN and walk_down_texture != null and walk_down_fps > 0.0:
		return walk_down_fps
	return walk_fps
