extends Control

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var start_button: Button = $Center/Panel/Margin/VBox/MenuButtons/StartButton
@onready var tutorial_button: Button = $Center/Panel/Margin/VBox/MenuButtons/TutorialButton
@onready var settings_button: Button = $Center/Panel/Margin/VBox/MenuButtons/SettingsButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/MenuButtons/QuitButton
@onready var settings_panel: PanelContainer = $Center/Panel/Margin/VBox/SettingsPanel
@onready var display_mode_button: Button = $Center/Panel/Margin/VBox/SettingsPanel/Margin/SettingsVBox/DisplayModeButton
@onready var resolution_label: Label = $Center/Panel/Margin/VBox/SettingsPanel/Margin/SettingsVBox/ResolutionLabel
@onready var close_settings_button: Button = $Center/Panel/Margin/VBox/SettingsPanel/Margin/SettingsVBox/CloseSettingsButton

func _ready() -> void:
	title_label.text = "ASCENDENCE"
	subtitle_label.text = "Archer-first forest parity slice"
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	display_mode_button.pressed.connect(_on_display_mode_pressed)
	close_settings_button.pressed.connect(_on_close_settings_pressed)
	settings_panel.visible = false
	_update_settings_labels()
	_apply_theme()
	if OS.has_feature("web"):
		quit_button.disabled = true

func _on_start_pressed() -> void:
	RunConfig.reset_for_frontend()
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _on_tutorial_pressed() -> void:
	RunConfig.reset_for_frontend()
	RunConfig.selected_class_id = RunConfig.CLASS_ARCHER
	RunConfig.selected_map_id = RunConfig.MAP_DEEPWOOD
	RunConfig.tutorial_requested = true
	get_tree().change_scene_to_file("res://scenes/main/TutorialMain.tscn")

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	settings_panel.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_display_mode_pressed() -> void:
	var current_mode: int = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_settings_labels()

func _update_settings_labels() -> void:
	var current_mode: int = DisplayServer.window_get_mode()
	var is_fullscreen: bool = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	display_mode_button.text = "Display Mode: %s" % ("Fullscreen" if is_fullscreen else "Windowed")
	resolution_label.text = "Target Resolution: 1920 x 1080"

func _apply_theme() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.06, 0.09, 0.94)
	panel_style.border_color = Color(0.25, 0.38, 0.52, 1.0)
	panel_style.set_corner_radius_all(22)
	panel_style.set_border_width_all(3)

	var subpanel_style: StyleBoxFlat = StyleBoxFlat.new()
	subpanel_style.bg_color = Color(0.07, 0.11, 0.15, 0.96)
	subpanel_style.border_color = Color(0.64, 0.54, 0.24, 1.0)
	subpanel_style.set_corner_radius_all(16)
	subpanel_style.set_border_width_all(2)

	$Center/Panel.add_theme_stylebox_override("panel", panel_style)
	settings_panel.add_theme_stylebox_override("panel", subpanel_style)
