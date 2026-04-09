extends Node2D

@export var radius: float = 280.0
@export var rotation_speed: float = 1.1
@export var ring_color: Color = Color(0.42, 0.9, 0.92, 0.34)
@export var accent_color: Color = Color(0.88, 0.96, 1.0, 0.8)

var _target: Node2D
var _rotation_phase: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 1
	queue_redraw()

func setup(target: Node2D, next_radius: float) -> void:
	_target = target
	radius = maxf(next_radius, 24.0)
	if _target != null and is_instance_valid(_target):
		global_position = _target.global_position
	queue_redraw()

func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	global_position = _target.global_position
	_rotation_phase = wrapf(_rotation_phase + delta * rotation_speed, 0.0, TAU)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(ring_color.r, ring_color.g, ring_color.b, 0.03))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, 0.18), 1.8)
	for i in range(4):
		var start_angle: float = _rotation_phase + TAU * float(i) / 4.0
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + 0.72, 28, accent_color, 2.3)
		var spark_position: Vector2 = Vector2.RIGHT.rotated(start_angle + 0.72) * radius
		draw_circle(spark_position, 3.0, Color(accent_color.r, accent_color.g, accent_color.b, 0.72))
