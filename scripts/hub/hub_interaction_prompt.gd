extends PanelContainer

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel

var _target: HubInteractable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_apply_theme()

func set_target(target: HubInteractable) -> void:
	_target = target
	if _target == null or not is_instance_valid(_target):
		visible = false
		return
	name_label.text = _target.get_interactable_name()
	hint_label.text = "%s  %s" % [GameSettings.get_binding_label("interact"), _target.get_prompt_label()]
	visible = true
	queue_sort()

func clear_target() -> void:
	_target = null
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	if _target == null or not is_instance_valid(_target):
		clear_target()
		return
	var world_position: Vector2 = _target.get_prompt_world_position()
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	var prompt_size: Vector2 = size
	position = Vector2(
		clampf(screen_position.x - prompt_size.x * 0.5, 20.0, get_viewport_rect().size.x - prompt_size.x - 20.0),
		clampf(screen_position.y - prompt_size.y, 20.0, get_viewport_rect().size.y - prompt_size.y - 20.0)
	)

func _apply_theme() -> void:
	FrontendStyle.apply_panel_theme(self, "frame")
	FrontendStyle.apply_header(name_label, 15, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_small(hint_label, 12, Color(0.90, 0.92, 0.96, 1.0))
	var style: StyleBox = get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		flat.bg_color = Color(0.07, 0.10, 0.15, 0.94)
		flat.border_color = Color(0.62, 0.74, 0.88, 0.98)
		add_theme_stylebox_override("panel", flat)
