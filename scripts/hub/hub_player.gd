extends CharacterBody2D

signal active_interactable_changed(interactable)
signal interact_requested(interactable)

@export var move_speed: float = 220.0
@export var interaction_range: float = 68.0

var facing_direction: Vector2 = Vector2.DOWN
var _move_input: Vector2 = Vector2.ZERO
var _movement_enabled: bool = true
var _nearby_interactables: Array[HubInteractable] = []
var _active_interactable: HubInteractable

@onready var camera: Camera2D = $Camera2D
@onready var interaction_detector: Area2D = $InteractionDetector

func _physics_process(_delta: float) -> void:
	_move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down") if _movement_enabled else Vector2.ZERO
	velocity = _move_input * move_speed
	move_and_slide()
	if _move_input.length_squared() > 0.0001:
		facing_direction = _move_input.normalized()
	_refresh_active_interactable()
	queue_redraw()

func get_camera() -> Camera2D:
	return camera

func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not _movement_enabled:
		velocity = Vector2.ZERO
		_set_active_interactable(null)
	else:
		_refresh_active_interactable()

func _ready() -> void:
	var shape: CollisionShape2D = interaction_detector.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		var circle: CircleShape2D = shape.shape as CircleShape2D
		if circle != null:
			circle.radius = interaction_range
	interaction_detector.area_entered.connect(_on_interaction_area_entered)
	interaction_detector.area_exited.connect(_on_interaction_area_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _movement_enabled:
		return
	if (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")) and _active_interactable != null:
		if is_instance_valid(_active_interactable) and _active_interactable.can_interact():
			interact_requested.emit(_active_interactable)
			get_viewport().set_input_as_handled()

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is HubInteractable:
		var interactable: HubInteractable = area as HubInteractable
		if not _nearby_interactables.has(interactable):
			_nearby_interactables.append(interactable)
		_refresh_active_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is HubInteractable:
		var interactable: HubInteractable = area as HubInteractable
		_nearby_interactables.erase(interactable)
		_refresh_active_interactable()

func _refresh_active_interactable() -> void:
	if not _movement_enabled:
		_set_active_interactable(null)
		return
	var best: HubInteractable
	var best_distance: float = INF
	for interactable in _nearby_interactables:
		if interactable == null or not is_instance_valid(interactable):
			continue
		if not interactable.can_interact():
			continue
		var dist: float = global_position.distance_squared_to(interactable.global_position)
		if dist < best_distance:
			best_distance = dist
			best = interactable
	_set_active_interactable(best)

func _set_active_interactable(next_interactable: HubInteractable) -> void:
	if _active_interactable == next_interactable:
		return
	_active_interactable = next_interactable
	active_interactable_changed.emit(_active_interactable)

func _draw() -> void:
	var facing: Vector2 = facing_direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.DOWN
	var stride: float = sin(Time.get_ticks_msec() * 0.014) * minf(_move_input.length(), 1.0)
	var right: Vector2 = facing.orthogonal()
	var body_center: Vector2 = Vector2(0.0, 4.0)
	var cloak_top: Vector2 = body_center - facing * 10.0
	var cloak_left: Vector2 = body_center + right * 10.0 + facing * 8.0
	var cloak_right: Vector2 = body_center - right * 10.0 + facing * 8.0
	var hem_sway: Vector2 = right * stride * 2.0
	var head_offset: Vector2 = Vector2(facing.x * 1.5, -12.0 + facing.y * 1.5)
	var eye_shift: Vector2 = right * 2.0
	draw_circle(Vector2(0.0, 12.0), 13.0, Color(0.04, 0.05, 0.09, 0.24))
	draw_colored_polygon(
		PackedVector2Array([
			cloak_top,
			cloak_left + hem_sway,
			body_center + Vector2(0.0, 16.0),
			cloak_right - hem_sway,
		]),
		Color(0.18, 0.24, 0.42, 1.0)
	)
	draw_colored_polygon(
		PackedVector2Array([
			body_center + facing * 2.0,
			cloak_left * 0.65 + body_center * 0.35,
			body_center + Vector2(0.0, 11.0),
			cloak_right * 0.65 + body_center * 0.35,
		]),
		Color(0.28, 0.38, 0.62, 0.96)
	)
	draw_circle(head_offset, 6.5, Color(0.96, 0.86, 0.66, 1.0))
	draw_circle(head_offset + Vector2(-1.5, -4.0), 2.4, Color(0.64, 0.40, 0.18, 1.0))
	if facing.y < 0.55:
		draw_circle(head_offset + eye_shift * 0.4 + Vector2(-1.5, 0.3), 0.85, Color(0.12, 0.16, 0.24, 0.9))
		draw_circle(head_offset - eye_shift * 0.4 + Vector2(-1.5, 0.3), 0.85, Color(0.12, 0.16, 0.24, 0.9))
	var foot_color: Color = Color(0.14, 0.16, 0.22, 0.92)
	draw_circle(Vector2(-4.0 + stride * 1.2, 18.0), 2.6, foot_color)
	draw_circle(Vector2(4.0 - stride * 1.2, 18.0), 2.6, foot_color)
