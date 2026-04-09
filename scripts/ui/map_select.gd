extends Control

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var deepwood_card: PanelContainer = $ContentRow/MapsColumn/MapCards/DeepwoodCard
@onready var sanctum_card: PanelContainer = $ContentRow/MapsColumn/MapCards/SanctumCard
@onready var preview_title: Label = $ContentRow/PreviewPanel/Margin/VBox/PreviewTitle
@onready var preview_status: Label = $ContentRow/PreviewPanel/Margin/VBox/Status
@onready var description_label: Label = $ContentRow/PreviewPanel/Margin/VBox/Description
@onready var flow_label: Label = $ContentRow/PreviewPanel/Margin/VBox/Flow
@onready var boss_label: Label = $ContentRow/PreviewPanel/Margin/VBox/Boss
@onready var detail_label: Label = $ContentRow/PreviewPanel/Margin/VBox/Detail
@onready var footer_hint: Label = $FooterHint
@onready var start_button: Button = $BottomBar/Buttons/StartButton
@onready var tutorial_button: Button = $BottomBar/Buttons/TutorialButton
@onready var back_button: Button = $BottomBar/Buttons/BackButton

var _map_data: Array[Dictionary] = []
var _preview_index: int = 0
var _selected_index: int = 0
var _card_styles: Dictionary = {}

func _ready() -> void:
	AudioDirector.set_music_context("menu")
	RunConfig.tutorial_requested = false
	_map_data = RunConfig.get_map_data()
	subtitle_label.text = "LOCK THE ROUTE, THEN STEP INTO THE TRIAL."
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
	_wire_hover_sfx()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not start_button.disabled:
		_on_start_pressed()
		get_viewport().set_input_as_handled()

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
	start_button.text = "ENTER %s" % str(data.get("name", "RUN")) if available else "LOCKED"
	var tutorial_allowed: bool = available and RunConfig.selected_class_id == RunConfig.CLASS_ARCHER
	tutorial_button.disabled = not tutorial_allowed
	tutorial_button.text = "TUTORIAL" if tutorial_allowed else "TUTORIAL (ARCHER ONLY)"
	footer_hint.text = "HOVER TO PREVIEW. CLICK TO LOCK THE ROUTE BEFORE YOU BEGIN."
	_refresh_card_styles()

func _refresh_preview() -> void:
	var data: Dictionary = _map_data[_preview_index]
	preview_title.text = str(data.get("name", "MAP"))
	preview_status.text = str(data.get("status", ""))
	description_label.text = str(data.get("description", ""))
	flow_label.text = "FLOW: %s" % str(data.get("flow", ""))
	boss_label.text = "BOSS: %s" % str(data.get("boss", ""))
	detail_label.text = str(data.get("detail", ""))
	_refresh_card_styles()

func _refresh_card_styles() -> void:
	var cards: Array[PanelContainer] = [deepwood_card, sanctum_card]
	for i in range(cards.size()):
		var data: Dictionary = _map_data[i]
		var style_key: String = "locked" if not bool(data.get("available", false)) else "card"
		if i == _selected_index:
			style_key = "selected_card"
		elif i == _preview_index and bool(data.get("available", false)):
			style_key = "preview_card"
		cards[i].add_theme_stylebox_override("panel", _card_styles[style_key])

func _on_card_hovered(index: int) -> void:
	AudioDirector.play_ui("ui_hover", -4.0)
	_set_preview_map(index)

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioDirector.play_ui("ui_click")
		_commit_map_selection(index)
		_set_preview_map(index)

func _on_start_pressed() -> void:
	var selected: Dictionary = _map_data[_selected_index]
	if not bool(selected.get("available", false)):
		AudioDirector.play_ui("ui_error")
		return
	AudioDirector.play_ui("ui_confirm")
	RunConfig.tutorial_requested = false
	RunConfig.selected_map_id = str(selected.get("id", RunConfig.MAP_DEEPWOOD))
	get_tree().change_scene_to_file(RunConfig.get_main_scene_for_selection())

func _on_tutorial_pressed() -> void:
	var selected: Dictionary = _map_data[_selected_index]
	if not bool(selected.get("available", false)):
		AudioDirector.play_ui("ui_error")
		return
	if RunConfig.selected_class_id != RunConfig.CLASS_ARCHER:
		AudioDirector.play_ui("ui_error")
		return
	AudioDirector.play_ui("ui_confirm")
	RunConfig.selected_map_id = str(selected.get("id", RunConfig.MAP_DEEPWOOD))
	RunConfig.tutorial_requested = true
	get_tree().change_scene_to_file("res://scenes/main/TutorialMain.tscn")

func _on_back_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _wire_hover_sfx() -> void:
	var hover_callback: Callable = Callable(self, "_on_ui_hovered")
	for button in [start_button, tutorial_button, back_button]:
		if button != null and not button.mouse_entered.is_connected(hover_callback):
			button.mouse_entered.connect(hover_callback)

func _on_ui_hovered() -> void:
	AudioDirector.play_ui("ui_hover", -4.0)

func _apply_theme() -> void:
	FrontendStyle.apply_title(title_label, 40)
	FrontendStyle.apply_small(subtitle_label, 14, Color(0.88, 0.84, 0.72, 1.0))
	FrontendStyle.apply_small(footer_hint, 13, Color(0.84, 0.80, 0.70, 1.0))
	FrontendStyle.apply_header($ContentRow/MapsColumn/MapsLabel, 24, Color(0.94, 0.86, 0.72, 1.0))
	FrontendStyle.apply_header(preview_title, 32, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_body(preview_status, 14, Color(0.88, 0.82, 0.66, 1.0))
	FrontendStyle.apply_body(description_label, 15)
	FrontendStyle.apply_body(flow_label, 15, Color(0.94, 0.86, 0.72, 1.0))
	FrontendStyle.apply_body(boss_label, 15, Color(0.94, 0.86, 0.72, 1.0))
	FrontendStyle.apply_body(detail_label, 14, Color(0.84, 0.87, 0.92, 1.0))
	for label in [
		$ContentRow/MapsColumn/MapCards/DeepwoodCard/Margin/VBox/Name,
		$ContentRow/MapsColumn/MapCards/SanctumCard/Margin/VBox/Name,
	]:
		FrontendStyle.apply_header(label, 22, Color(0.93, 0.90, 0.82, 1.0))
	for label in [
		$ContentRow/MapsColumn/MapCards/DeepwoodCard/Margin/VBox/Status,
		$ContentRow/MapsColumn/MapCards/SanctumCard/Margin/VBox/Status,
	]:
		FrontendStyle.apply_body(label, 14, Color(0.88, 0.82, 0.66, 1.0))
	for label in [
		$ContentRow/MapsColumn/MapCards/DeepwoodCard/Margin/VBox/Summary,
		$ContentRow/MapsColumn/MapCards/SanctumCard/Margin/VBox/Summary,
	]:
		FrontendStyle.apply_body(label, 13, Color(0.84, 0.87, 0.92, 1.0))
	FrontendStyle.apply_panel_theme($ContentRow/PreviewPanel, "frame")
	FrontendStyle.apply_button_theme(back_button, false, false, true)
	FrontendStyle.apply_button_theme(tutorial_button, false, tutorial_button.disabled, true)
	FrontendStyle.apply_button_theme(start_button, true, start_button.disabled, true)
	_card_styles = {
		"card": FrontendStyle.make_texture_style("card_common", 30, 12),
		"preview_card": FrontendStyle.make_texture_style("card_rare", 30, 12),
		"selected_card": FrontendStyle.make_texture_style("selected_card", 30, 12),
		"locked": FrontendStyle.make_texture_style("locked", 30, 12),
	}
