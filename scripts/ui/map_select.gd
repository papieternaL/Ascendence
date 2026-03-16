extends Control

@onready var subtitle_label: Label = $Center/Frame/Margin/VBox/Subtitle
@onready var class_summary_label: Label = $Center/Frame/Margin/VBox/HeaderRow/ClassSummary
@onready var deepwood_card: PanelContainer = $Center/Frame/Margin/VBox/ContentRow/MapsColumn/MapCards/DeepwoodCard
@onready var sanctum_card: PanelContainer = $Center/Frame/Margin/VBox/ContentRow/MapsColumn/MapCards/SanctumCard
@onready var preview_title_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/PreviewTitle
@onready var preview_status_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Status
@onready var preview_desc_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Description
@onready var preview_flow_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Flow
@onready var preview_boss_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Boss
@onready var preview_detail_label: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Detail
@onready var start_button: Button = $BottomBar/Buttons/StartButton
@onready var tutorial_button: Button = $BottomBar/Buttons/TutorialButton
@onready var back_button: Button = $BottomBar/Buttons/BackButton

var _map_data: Array[Dictionary] = []
var _preview_index: int = 0
var _selected_index: int = 0
var _card_styles: Dictionary = {}

func _ready() -> void:
	RunConfig.tutorial_requested = false
	_map_data = RunConfig.get_map_data()
	class_summary_label.text = "CLASS: %s" % _get_selected_class_name()
	subtitle_label.text = "Hover a battleground to preview its route and boss. Click to lock it before starting."
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_apply_theme()
	_wire_card(deepwood_card, 0)
	_wire_card(sanctum_card, 1)
	_selected_index = _find_selected_map_index()
	_preview_index = _selected_index
	_commit_map_selection(_selected_index)
	_refresh_preview()

func _wire_card(card: PanelContainer, index: int) -> void:
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(Callable(self, "_on_card_input").bind(index))
	card.mouse_entered.connect(Callable(self, "_on_card_hovered").bind(index))

func _find_selected_map_index() -> int:
	for i in range(_map_data.size()):
		if str(_map_data[i].get("id", "")) == RunConfig.selected_map_id:
			return i
	return 0

func _set_preview_map(index: int) -> void:
	if index < 0 or index >= _map_data.size():
		return
	_preview_index = index
	_refresh_preview()

func _commit_map_selection(index: int) -> void:
	if index < 0 or index >= _map_data.size():
		return
	_selected_index = index
	var data: Dictionary = _map_data[index]
	RunConfig.selected_map_id = str(data.get("id", RunConfig.MAP_DEEPWOOD))
	var available: bool = bool(data.get("available", false))
	start_button.disabled = not available
	start_button.text = "Enter %s" % str(data.get("name", "Run")) if available else "Locked"
	var tutorial_allowed: bool = available and RunConfig.selected_class_id == RunConfig.CLASS_ARCHER
	tutorial_button.disabled = not tutorial_allowed
	tutorial_button.text = "Tutorial" if tutorial_allowed else "Tutorial (Archer Only)"
	_refresh_card_styles()

func _refresh_preview() -> void:
	var data: Dictionary = _map_data[_preview_index]
	preview_title_label.text = str(data.get("name", "MAP"))
	preview_status_label.text = str(data.get("status", ""))
	preview_desc_label.text = str(data.get("description", ""))
	preview_flow_label.text = "FLOW  %s" % str(data.get("flow", ""))
	preview_boss_label.text = "BOSS  %s" % str(data.get("boss", ""))
	preview_detail_label.text = str(data.get("detail", ""))
	_refresh_card_styles()

func _refresh_card_styles() -> void:
	var cards: Array[PanelContainer] = [deepwood_card, sanctum_card]
	for i in range(cards.size()):
		var data: Dictionary = _map_data[i]
		var style_key: String = "locked" if not bool(data.get("available", false)) else "default"
		if i == _selected_index:
			style_key = "selected"
		elif i == _preview_index and bool(data.get("available", false)):
			style_key = "preview"
		cards[i].add_theme_stylebox_override("panel", _card_styles[style_key])

func _on_card_hovered(index: int) -> void:
	_set_preview_map(index)

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_commit_map_selection(index)
		_set_preview_map(index)

func _on_start_pressed() -> void:
	var selected: Dictionary = _map_data[_selected_index]
	if not bool(selected.get("available", false)):
		return
	RunConfig.tutorial_requested = false
	RunConfig.selected_map_id = str(selected.get("id", RunConfig.MAP_DEEPWOOD))
	get_tree().change_scene_to_file(RunConfig.get_main_scene_for_selection())

func _on_tutorial_pressed() -> void:
	var selected: Dictionary = _map_data[_selected_index]
	if not bool(selected.get("available", false)):
		return
	if RunConfig.selected_class_id != RunConfig.CLASS_ARCHER:
		return
	RunConfig.selected_map_id = str(selected.get("id", RunConfig.MAP_DEEPWOOD))
	RunConfig.tutorial_requested = true
	get_tree().change_scene_to_file("res://scenes/main/TutorialMain.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _get_selected_class_name() -> String:
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) == RunConfig.selected_class_id:
			return str(class_data.get("name", "UNKNOWN"))
	return "UNKNOWN"

func _apply_theme() -> void:
	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.04, 0.06, 0.09, 0.96)
	frame_style.border_color = Color(0.22, 0.36, 0.54, 1.0)
	frame_style.set_corner_radius_all(20)
	frame_style.set_border_width_all(3)

	var default_style: StyleBoxFlat = StyleBoxFlat.new()
	default_style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	default_style.border_color = Color(0.24, 0.34, 0.42, 1.0)
	default_style.set_corner_radius_all(18)
	default_style.set_border_width_all(2)

	var preview_style: StyleBoxFlat = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.09, 0.12, 0.18, 0.98)
	preview_style.border_color = Color(0.4, 0.52, 0.64, 1.0)
	preview_style.set_corner_radius_all(18)
	preview_style.set_border_width_all(2)

	var selected_style: StyleBoxFlat = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.11, 0.15, 0.2, 0.98)
	selected_style.border_color = Color(0.74, 0.62, 0.26, 1.0)
	selected_style.set_corner_radius_all(18)
	selected_style.set_border_width_all(3)

	var locked_style: StyleBoxFlat = StyleBoxFlat.new()
	locked_style.bg_color = Color(0.08, 0.08, 0.1, 0.92)
	locked_style.border_color = Color(0.32, 0.22, 0.22, 1.0)
	locked_style.set_corner_radius_all(18)
	locked_style.set_border_width_all(2)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.13, 0.18, 0.96)
	panel_style.border_color = Color(0.18, 0.31, 0.46, 1.0)
	panel_style.set_corner_radius_all(18)
	panel_style.set_border_width_all(2)

	_card_styles = {
		"default": default_style,
		"preview": preview_style,
		"selected": selected_style,
		"locked": locked_style,
	}

	$Center/Frame.add_theme_stylebox_override("panel", frame_style)
	deepwood_card.add_theme_stylebox_override("panel", default_style)
	sanctum_card.add_theme_stylebox_override("panel", locked_style)
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel.add_theme_stylebox_override("panel", panel_style)
