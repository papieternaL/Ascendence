extends Control

const ICON_GLYPH_SCENE: PackedScene = preload("res://scenes/ui/IconGlyph.tscn")

@onready var subtitle_label: Label = $Center/Frame/Margin/VBox/Subtitle
@onready var archer_card: PanelContainer = $Center/Frame/Margin/VBox/ContentRow/ClassCards/ArcherCard
@onready var pistol_card: PanelContainer = $Center/Frame/Margin/VBox/ContentRow/ClassCards/PistolCard
@onready var preview_title: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/PreviewTitle
@onready var preview_status: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Status
@onready var preview_description: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/ClassDescription
@onready var ability_buttons: Array[Button] = [
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability0,
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability1,
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability2,
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability3,
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/Abilities/Ability4,
]
@onready var ability_summary: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/AbilitySummary
@onready var ability_detail: Label = $Center/Frame/Margin/VBox/ContentRow/PreviewPanel/Margin/VBox/AbilityDetail
@onready var footer_hint: Label = $Center/Frame/Margin/VBox/FooterHint
@onready var start_button: Button = $BottomBar/Buttons/StartButton
@onready var back_button: Button = $BottomBar/Buttons/BackButton

var _classes: Array[Dictionary] = []
var _preview_index: int = 0
var _selected_index: int = 0
var _selected_ability_index: int = 0
var _card_styles: Dictionary = {}
var _ability_icons: Array[Control] = []

func _ready() -> void:
	RunConfig.reset_for_frontend()
	_classes = RunConfig.get_class_data()
	subtitle_label.text = "Hover a class to preview its loadout. Click to lock it in before heading to map select."
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
		icon.position = Vector2(10.0, 7.0)
		icon.custom_minimum_size = Vector2(28, 28)
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
	start_button.text = "Choose %s" % str(_classes[index].get("name", "Class"))
	footer_hint.text = "Hover abilities to inspect details. Click a class card to lock it, then continue to the map page."
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
		var style_key: String = "default"
		if i == _selected_index:
			style_key = "selected"
		elif i == _preview_index:
			style_key = "preview"
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
		button.text = "      %s  %s" % [str(data.get("key", "")), str(data.get("name", ""))]
		if i < _ability_icons.size() and _ability_icons[i] != null and _ability_icons[i].has_method("configure"):
			_ability_icons[i].call("configure", str(data.get("icon", "default")))
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
		var style: StyleBoxFlat = _card_styles["selected_button"] if i == _selected_ability_index else _card_styles["button"]
		ability_buttons[i].add_theme_stylebox_override("normal", style)
		ability_buttons[i].add_theme_stylebox_override("hover", style)
		ability_buttons[i].add_theme_stylebox_override("pressed", style)

func _on_card_hovered(index: int) -> void:
	_set_preview_class(index)

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_commit_class_selection(index)
		_set_preview_class(index)

func _on_ability_hovered(index: int) -> void:
	_selected_ability_index = index
	_update_ability_preview()

func _on_ability_pressed(index: int) -> void:
	_selected_ability_index = index
	_update_ability_preview()

func _on_start_pressed() -> void:
	RunConfig.selected_class_id = str(_classes[_selected_index].get("id", RunConfig.CLASS_ARCHER))
	get_tree().change_scene_to_file("res://scenes/ui/MapSelect.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _apply_theme() -> void:
	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.04, 0.06, 0.09, 0.96)
	frame_style.border_color = Color(0.22, 0.36, 0.54, 1.0)
	frame_style.set_corner_radius_all(20)
	frame_style.set_border_width_all(3)

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	card_style.border_color = Color(0.24, 0.34, 0.42, 1.0)
	card_style.set_corner_radius_all(18)
	card_style.set_border_width_all(2)

	var preview_card_style: StyleBoxFlat = StyleBoxFlat.new()
	preview_card_style.bg_color = Color(0.09, 0.12, 0.18, 0.98)
	preview_card_style.border_color = Color(0.4, 0.52, 0.64, 1.0)
	preview_card_style.set_corner_radius_all(18)
	preview_card_style.set_border_width_all(2)

	var selected_style: StyleBoxFlat = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.11, 0.15, 0.2, 0.98)
	selected_style.border_color = Color(0.74, 0.62, 0.26, 1.0)
	selected_style.set_corner_radius_all(18)
	selected_style.set_border_width_all(3)

	var preview_style: StyleBoxFlat = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.09, 0.13, 0.18, 0.96)
	preview_style.border_color = Color(0.18, 0.31, 0.46, 1.0)
	preview_style.set_corner_radius_all(18)
	preview_style.set_border_width_all(2)

	var button_style: StyleBoxFlat = StyleBoxFlat.new()
	button_style.bg_color = Color(0.09, 0.11, 0.16, 1.0)
	button_style.border_color = Color(0.18, 0.26, 0.33, 1.0)
	button_style.set_corner_radius_all(10)
	button_style.set_border_width_all(2)

	var selected_button_style: StyleBoxFlat = StyleBoxFlat.new()
	selected_button_style.bg_color = Color(0.14, 0.17, 0.22, 1.0)
	selected_button_style.border_color = Color(0.74, 0.62, 0.26, 1.0)
	selected_button_style.set_corner_radius_all(10)
	selected_button_style.set_border_width_all(2)

	_card_styles = {
		"default": card_style,
		"preview": preview_card_style,
		"selected": selected_style,
		"button": button_style,
		"selected_button": selected_button_style,
	}

	$Center/Frame.add_theme_stylebox_override("panel", frame_style)
	archer_card.add_theme_stylebox_override("panel", selected_style)
	pistol_card.add_theme_stylebox_override("panel", card_style)
	$Center/Frame/Margin/VBox/ContentRow/PreviewPanel.add_theme_stylebox_override("panel", preview_style)
