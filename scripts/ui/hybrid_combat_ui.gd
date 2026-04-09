extends CanvasLayer

signal upgrade_selected(id: String)

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@onready var top_panel: PanelContainer = $TopPanel
@onready var title_label: Label = $TopPanel/Margin/Stack/Title
@onready var stats_label: Label = $TopPanel/Margin/Stack/Stats
@onready var combat_label: Label = $TopPanel/Margin/Stack/Combat
@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var health_label: Label = $BottomPanel/Margin/Stack/HealthLabel
@onready var health_bar: ProgressBar = $BottomPanel/Margin/Stack/HealthBar
@onready var overlay: Control = $Overlay
@onready var overlay_panel: PanelContainer = $Overlay/CenterWrap/LevelUpPanel
@onready var overlay_title: Label = $Overlay/CenterWrap/LevelUpPanel/Margin/Stack/Title
@onready var overlay_subtitle: Label = $Overlay/CenterWrap/LevelUpPanel/Margin/Stack/Subtitle
@onready var hint_label: Label = $Overlay/CenterWrap/LevelUpPanel/Margin/Stack/Hint
@onready var choice_buttons: Array[Button] = [
	$Overlay/CenterWrap/LevelUpPanel/Margin/Stack/CardsRow/Choice0,
	$Overlay/CenterWrap/LevelUpPanel/Margin/Stack/CardsRow/Choice1,
	$Overlay/CenterWrap/LevelUpPanel/Margin/Stack/CardsRow/Choice2,
]

var _choices: Array[Dictionary] = []
var _selected_index: int = 0


func _ready() -> void:
	_apply_theme()
	for i in range(choice_buttons.size()):
		choice_buttons[i].pressed.connect(Callable(self, "_on_choice_pressed").bind(i))
	overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not overlay.visible:
		return
	if event.is_action_pressed("ui_left"):
		_selected_index = wrapi(_selected_index - 1, 0, choice_buttons.size())
		_refresh_choice_buttons()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_selected_index = wrapi(_selected_index + 1, 0, choice_buttons.size())
		_refresh_choice_buttons()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_emit_selected_choice()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_and_emit(0)
			KEY_2:
				_select_and_emit(1)
			KEY_3:
				_select_and_emit(2)


func update_hud(data: Dictionary) -> void:
	title_label.text = str(data.get("title", "HYBRID ARCHER COMBAT SLICE"))
	stats_label.text = "HP: %s / %s   LVL: %s   XP: %s / %s" % [
		str(data.get("current_health", 0)),
		str(data.get("max_health", 0)),
		str(data.get("level", 1)),
		str(data.get("xp", 0)),
		str(data.get("xp_required", 0)),
	]
	combat_label.text = "DMG: %s   FIRE CD: %ss   KILLS: %s   ENEMIES: %s" % [
		str(data.get("damage", 0)),
		str(data.get("fire_cooldown", "0.00")),
		str(data.get("kills", 0)),
		str(data.get("enemies", 0)),
	]
	health_bar.max_value = float(data.get("max_health", 1.0))
	health_bar.value = float(data.get("current_health", 0.0))
	health_label.text = "Run Health"


func show_level_up(choices: Array[Dictionary], selected_index: int = 0) -> void:
	_choices = choices.duplicate(true)
	_selected_index = clampi(selected_index, 0, max(choice_buttons.size() - 1, 0))
	overlay.visible = true
	overlay_title.text = "LEVEL UP"
	overlay_subtitle.text = "Choose one upgrade for this hybrid run slice."
	hint_label.text = "LEFT / RIGHT or 1 / 2 / 3, then ENTER"
	for i in range(choice_buttons.size()):
		var button: Button = choice_buttons[i]
		if i < _choices.size():
			var choice: Dictionary = _choices[i]
			button.visible = true
			button.disabled = false
			button.text = "%s\n%s" % [str(choice.get("title", "Upgrade")), str(choice.get("body", ""))]
		else:
			button.visible = false
			button.disabled = true
			button.text = ""
	_refresh_choice_buttons()


func hide_level_up() -> void:
	overlay.visible = false
	_choices.clear()


func show_game_over() -> void:
	overlay.visible = true
	overlay_title.text = "RUN ENDED"
	overlay_subtitle.text = "Press ENTER or left click to restart the hybrid prototype."
	hint_label.text = ""
	_choices.clear()
	for button in choice_buttons:
		button.visible = false


func is_overlay_open() -> bool:
	return overlay.visible


func _select_and_emit(index: int) -> void:
	if not overlay.visible or index >= _choices.size():
		return
	_selected_index = index
	_emit_selected_choice()
	get_viewport().set_input_as_handled()


func _emit_selected_choice() -> void:
	if _selected_index < 0 or _selected_index >= _choices.size():
		return
	upgrade_selected.emit(str(_choices[_selected_index].get("id", "")))


func _on_choice_pressed(index: int) -> void:
	if index >= _choices.size():
		return
	_selected_index = index
	_emit_selected_choice()


func _refresh_choice_buttons() -> void:
	for i in range(choice_buttons.size()):
		var button: Button = choice_buttons[i]
		if not button.visible:
			continue
		FrontendStyle.apply_button_theme(button, i == _selected_index, false)


func _apply_theme() -> void:
	FrontendStyle.apply_panel_theme(top_panel, "frame")
	FrontendStyle.apply_panel_theme(bottom_panel, "frame")
	FrontendStyle.apply_panel_theme(overlay_panel, "overlay")
	FrontendStyle.apply_header(title_label, 18)
	FrontendStyle.apply_body(stats_label, 16)
	FrontendStyle.apply_body(combat_label, 16)
	FrontendStyle.apply_header(overlay_title, 28)
	FrontendStyle.apply_body(overlay_subtitle, 18)
	FrontendStyle.apply_small(hint_label, 14, Color(0.76, 0.80, 0.86, 1.0))
	FrontendStyle.apply_small(health_label, 14, Color(0.82, 0.87, 0.94, 1.0))
	health_bar.show_percentage = false
	health_bar.modulate = Color(0.96, 0.45, 0.42, 1.0)
	for button in choice_buttons:
		FrontendStyle.apply_button_theme(button)
