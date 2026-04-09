extends Area2D
class_name HubInteractable

@export var interactable_name: String = "INTERACTABLE"
@export var prompt_label: String = "INTERACT"
@export var interaction_radius: float = 64.0
@export var interaction_enabled: bool = true

@onready var interaction_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("hub_interactable")
	_configure_interaction_shape()
	_apply_interaction_enabled_state()
	queue_redraw()

func can_interact() -> bool:
	return interaction_enabled

func interact(_hub: Node, _player: Node) -> void:
	pass

func get_prompt_label() -> String:
	return prompt_label if not prompt_label.is_empty() else "INTERACT"

func get_interactable_name() -> String:
	return interactable_name if not interactable_name.is_empty() else "INTERACTABLE"

func get_prompt_world_position() -> Vector2:
	return global_position + Vector2(0.0, -48.0)

func uses_hub_art_sprite() -> bool:
	var art: Sprite2D = find_child("ArtSprite", true, false) as Sprite2D
	return art != null and art.visible and art.texture != null

func _configure_interaction_shape() -> void:
	if interaction_shape == null:
		return
	var circle: CircleShape2D = interaction_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		interaction_shape.shape = circle
	circle.radius = interaction_radius

func _apply_interaction_enabled_state() -> void:
	if interaction_shape != null:
		interaction_shape.disabled = not interaction_enabled
	monitorable = interaction_enabled
	monitoring = interaction_enabled
