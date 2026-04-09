class_name HubCombatPlayer
extends "res://scripts/player/player.gd"

signal active_interactable_changed(interactable)
signal interact_requested(interactable)

@export var interaction_range: float = 68.0

var _nearby_interactables: Array[HubInteractable] = []
var _active_interactable: HubInteractable

@onready var interaction_detector: Area2D = $InteractionDetector

func _ready() -> void:
	super._ready()
	var shape: CollisionShape2D = interaction_detector.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		var circle: CircleShape2D = shape.shape as CircleShape2D
		if circle == null:
			circle = CircleShape2D.new()
			shape.shape = circle
		circle.radius = interaction_range
	interaction_detector.area_entered.connect(_on_interaction_area_entered)
	interaction_detector.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_refresh_active_interactable()

func _unhandled_input(event: InputEvent) -> void:
	if not movement_input_enabled:
		return
	if event.is_action_pressed("interact") and _active_interactable != null:
		if is_instance_valid(_active_interactable) and _active_interactable.can_interact():
			interact_requested.emit(_active_interactable)
			get_viewport().set_input_as_handled()

func get_camera() -> Camera2D:
	return $Camera2D as Camera2D

func set_movement_enabled(enabled: bool) -> void:
	set_movement_input_enabled(enabled)
	if not enabled:
		velocity = Vector2.ZERO
		_set_active_interactable(null)
	else:
		_refresh_active_interactable()

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
	if not movement_input_enabled:
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
