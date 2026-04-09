extends Control

const ICON_GLYPH_SCENE: PackedScene = preload("res://scenes/ui/IconGlyph.tscn")
const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var archer_card: PanelContainer = $ContentRow/ClassCards/ArcherCard
@onready var pistol_card: PanelContainer = $ContentRow/ClassCards/PistolCard
@onready var preview_title: Label = $ContentRow/PreviewPanel/Margin/VBox/PreviewTitle
@onready var preview_status: Label = $ContentRow/PreviewPanel/Margin/VBox/Status
@onready var preview_description: Label = $ContentRow/PreviewPanel/Margin/VBox/ClassDescription
@onready var ability_buttons: Array[Button] = [
	$ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability0,
	$ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability1,
	$ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability2,
	$ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability3,
	$ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability4,
]
@onready var ability_summary: Label = $ContentRow/PreviewPanel/Margin/VBox/AbilitySummary
@onready var ability_detail: Label = $ContentRow/PreviewPanel/Margin/VBox/AbilityDetail
@onready var footer_hint: Label = $FooterHint
@onready var nav_hint: Label = $NavHint
@onready var start_button: Button = $BottomBar/Buttons/StartButton
@onready var back_button: Button = $BottomBar/Buttons/BackButton

var _classes: Array[Dictionary] = []
var _preview_index: int = 0
var _selected_index: int = 0
var _selected_ability_index: int = 0
var _card_styles: Dictionary = {}
var _ability_icons: Array[Control] = []

func _ready() -> void:
	AudioDirector.set_music_context("menu")
	RunConfig.reset_for_frontend()
	_classes = RunConfig.get_class_data()
	title_label.text = "CHOOSE YOUR WEAPON"
	subtitle_label.text = "HOVER TO PREVIEW EACH LOADOUT. CLICK TO LOCK YOUR WEAPON BEFORE HEADING INTO DEEPWOOD."
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_apply_theme()
	_wire_card(archer_card, 0)
	_wire_card(pistol_card, 1)
	_create_ability_icons()
	for i in range(ability_buttons.size()):
		ability_buttons[i].mouse_entered.connect(Callable(self, "_on_ability_hovered").bind(i))
		ability_buttons[i].pressed.connect(Callable(self, "_on_ability_pressed").bind(i))
	_selected_index = _find_selected_class_index()
	_preview_index = _selected_index
	_selected_ability_index = 0
	_commit_class_selection(_selected_index)
	_refresh_preview()
	_wire_hover_sfx()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()

func _wire_card(card: PanelContainer, index: int) -> void:
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(Callable(self, "_on_card_input").bind(index))
	card.mouse_entered.connect(Callable(self, "_on_card_hovered").bind(index))

func _create_ability_icons() -> void:
	for button in ability_buttons:
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var icon: Control = ICON_GLYPH_SCENE.instantiate() as Control
		if icon == null:
			continue
		icon.position = Vector2(10.0, 3.0)
		icon.custom_minimum_size = Vector2(36, 36)
		button.add_child(icon)
		_ability_icons.append(icon)

func _find_selected_class_index() -> int:
	for i in range(_classes.size()):
		if str(_classes[i].get("id", "")) == RunConfig.selected_class_id:
			return i
	return 0

func _set_preview_class(index: int) -> void:
	if index < 0 or index >= _classes.size():
		return
	_preview_index = index
	_selected_ability_index = 0
	_refresh_preview()

func _commit_class_selection(index: int) -> void:
	if index < 0 or index >= _classes.size():
		return
	_selected_index = index
	RunConfig.selected_class_id = str(_classes[index].get("id", RunConfig.CLASS_ARCHER))
	start_button.text = "EQUIP %s" % str(_classes[index].get("name", "WEAPON"))
	footer_hint.text = "ABILITY HOVERS SHOW THE CURRENT LOADOUT. CLICK A WEAPON TO LOCK IT, THEN CONTINUE."
	_refresh_class_card_styles()

func _refresh_preview() -> void:
	var class_data: Dictionary = _classes[_preview_index]
	preview_title.text = str(class_data.get("name", "CLASS"))
	preview_status.text = str(class_data.get("status", ""))
	preview_description.text = str(class_data.get("description", ""))
	_refresh_class_card_styles()
	_refresh_ability_buttons()

func _refresh_class_card_styles() -> void:
	var cards: Array[PanelContainer] = [archer_card, pistol_card]
	for i in range(cards.size()):
		var style_key: String = "card"
		if i == _selected_index:
			style_key = "selected_card"
		elif i == _preview_index:
			style_key = "preview_card"
		cards[i].add_theme_stylebox_override("panel", _card_styles[style_key])

func _refresh_ability_buttons() -> void:
	var abilities: Array = _classes[_preview_index].get("abilities", [])
	for i in range(ability_buttons.size()):
		var button: Button = ability_buttons[i]
		if i >= abilities.size():
			button.visible = false
			continue
		button.visible = true
		var data: Dictionary = abilities[i]
		var bind_label: String = str(data.get("key", ""))
		var action_name: String = str(data.get("action", ""))
		if not action_name.is_empty():
			bind_label = GameSettings.get_binding_label(action_name)
		button.text = "        %s  %s" % [bind_label, str(data.get("name", ""))]
		if i < _ability_icons.size() and _ability_icons[i] != null and _ability_icons[i].has_method("configure"):
			_ability_icons[i].call(
				"configure",
				str(data.get("icon_asset_id", data.get("icon", "default"))),
				Color(0.83, 0.9, 1.0, 1.0),
				Color(0.97, 0.77, 0.3, 1.0),
				str(data.get("icon", "default"))
			)
	_update_ability_preview()

func _update_ability_preview() -> void:
	var abilities: Array = _classes[_preview_index].get("abilities", [])
	if abilities.is_empty():
		ability_summary.text = ""
		ability_detail.text = ""
		return
	_selected_ability_index = clamp(_selected_ability_index, 0, abilities.size() - 1)
	var ability_data: Dictionary = abilities[_selected_ability_index]
	ability_summary.text = str(ability_data.get("summary", ""))
	ability_detail.text = str(ability_data.get("detail", ""))
	for i in range(ability_buttons.size()):
		if not ability_buttons[i].visible:
			continue
		FrontendStyle.apply_button_theme(ability_buttons[i], i == _selected_ability_index, false, true)

func _on_card_hovered(index: int) -> void:
	AudioDirector.play_ui("ui_hover", -4.0)
	_set_preview_class(index)

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioDirector.play_ui("ui_click")
		_commit_class_selection(index)
		_set_preview_class(index)
		if event.double_click:
			_on_start_pressed()

func _on_ability_hovered(index: int) -> void:
	AudioDirector.play_ui("ui_hover", -4.0)
	_selected_ability_index = index
	_update_ability_preview()

func _on_ability_pressed(index: int) -> void:
	AudioDirector.play_ui("ui_click")
	_selected_ability_index = index
	_update_ability_preview()

func _on_start_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	RunConfig.selected_class_id = str(_classes[_selected_index].get("id", RunConfig.CLASS_ARCHER))
	RunConfig.selected_map_id = RunConfig.MAP_DEEPWOOD
	get_tree().change_scene_to_file(RunConfig.get_main_scene_for_selection())

func _on_back_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _wire_hover_sfx() -> void:
	var hover_callback: Callable = Callable(self, "_on_ui_hovered")
	for button in [start_button, back_button]:
		if button != null and not button.mouse_entered.is_connected(hover_callback):
			button.mouse_entered.connect(hover_callback)

func _on_ui_hovered() -> void:
	AudioDirector.play_ui("ui_hover", -4.0)

func _apply_theme() -> void:
	FrontendStyle.apply_title(title_label, 40)
	FrontendStyle.apply_readable_small(subtitle_label, 14, Color(0.88, 0.84, 0.72, 1.0))
	FrontendStyle.apply_readable_small(footer_hint, 13, Color(0.84, 0.80, 0.70, 1.0))
	FrontendStyle.apply_readable_small(nav_hint, 12, Color(0.70, 0.72, 0.76, 1.0))
	FrontendStyle.apply_header(preview_title, 32, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_readable_small(preview_status, 14, Color(0.86, 0.80, 0.66, 1.0))
	FrontendStyle.apply_readable_body(preview_description, 16)
	FrontendStyle.apply_readable_body(ability_summary, 15, Color(0.94, 0.86, 0.72, 1.0))
	FrontendStyle.apply_readable_body(ability_detail, 15, Color(0.84, 0.87, 0.92, 1.0))
	for label in [
		$ContentRow/ClassCards/ArcherCard/Margin/VBox/Name,
		$ContentRow/ClassCards/PistolCard/Margin/VBox/Name,
	]:
		FrontendStyle.apply_header(label, 24, Color(0.93, 0.90, 0.82, 1.0))
	for label in [
		$ContentRow/ClassCards/ArcherCard/Margin/VBox/Status,
		$ContentRow/ClassCards/PistolCard/Margin/VBox/Status,
	]:
		FrontendStyle.apply_readable_small(label, 14, Color(0.88, 0.82, 0.66, 1.0))
	for label in [
		$ContentRow/ClassCards/ArcherCard/Margin/VBox/Summary,
		$ContentRow/ClassCards/PistolCard/Margin/VBox/Summary,
	]:
		FrontendStyle.apply_readable_body(label, 14, Color(0.84, 0.87, 0.92, 1.0))
	_card_styles = {
		"card": FrontendStyle.make_texture_style("card_common", 30, 12),
		"preview_card": FrontendStyle.make_texture_style("card_rare", 30, 12),
		"selected_card": FrontendStyle.make_texture_style("selected_card", 30, 12),
	}
	FrontendStyle.apply_panel_theme($ContentRow/PreviewPanel, "frame")
	FrontendStyle.apply_button_theme(start_button, true, false, true)
	FrontendStyle.apply_button_theme(back_button, false, false, true)
	for button in ability_buttons:
		FrontendStyle.apply_button_theme(button, false, false, true)
