extends Node2D

@export var visual_root_path: NodePath
@export var bob_amplitude: float = 1.5
@export var bob_speed: float = 1.4
@export var sway_degrees: float = 1.1
@export var sway_speed: float = 1.2
@export var phase_offset: float = 0.0

var _visual_root: Node2D
var _base_position: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	_visual_root = get_node_or_null(visual_root_path) as Node2D
	if _visual_root == null:
		for child in get_children():
			if child is Node2D:
				_visual_root = child as Node2D
				break
	if _visual_root == null:
		set_process(false)
		return
	_base_position = _visual_root.position
	_base_rotation = _visual_root.rotation

func _process(delta: float) -> void:
	if _visual_root == null:
		return
	_elapsed += delta
	var bob_phase: float = _elapsed * bob_speed + phase_offset
	var sway_phase: float = _elapsed * sway_speed + phase_offset * 1.17
	_visual_root.position = _base_position + Vector2(0.0, sin(bob_phase) * bob_amplitude)
	_visual_root.rotation = _base_rotation + deg_to_rad(sin(sway_phase) * sway_degrees)
