extends Control

const BitmapFontLibrary = preload("res://scripts/ui/bitmap_font_library.gd")
const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")

@onready var title_label: Label = $Title
@onready var start_button: Button = $MenuButtons/StartButton
@onready var hub_button: Button = $MenuButtons/HubButton
@onready var tutorial_button: Button = $MenuButtons/TutorialButton
@onready var boss_test_button: Button = $MenuButtons/BossTestButton
@onready var settings_button: Button = $MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuButtons/QuitButton
@onready var footer_hint: Label = $FooterHint
@onready var settings_overlay: Control = $SettingsOverlay
@onready var settings_backdrop: ColorRect = $SettingsOverlay/Backdrop
@onready var settings_panel: PanelContainer = $SettingsOverlay/Center/Panel
@onready var settings_host: VBoxContainer = $SettingsOverlay/Center/Panel/Margin/VBox

var _settings_content: SettingsPanel

func _ready() -> void:
	AudioDirector.set_music_context("menu")
	title_label.text = "ASCENDENCE"
	footer_hint.text = "PRESS ENTER OR CLICK TO CONTINUE"
	start_button.pressed.connect(_on_start_pressed)
	hub_button.pressed.connect(_on_hub_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	boss_test_button.pressed.connect(_on_boss_test_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_overlay.visible = false
	_build_settings_content()
	_apply_theme()
	_wire_button_hover_sfx()
	if OS.has_feature("web"):
		quit_button.disabled = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, true)

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay.visible:
		if event.is_action_pressed("ui_cancel") and (_settings_content == null or not _settings_content.is_capturing_binding()):
			_on_close_settings_pressed()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()

func _build_settings_content() -> void:
	if settings_host == null or _settings_content != null:
		return
	for child in settings_host.get_children():
		child.queue_free()
	_settings_content = SettingsPanel.new()
	_settings_content.close_requested.connect(_on_close_settings_pressed)
	_settings_content.hover_sfx_requested.connect(_on_any_button_hovered)
	settings_host.add_child(_settings_content)

func _on_start_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	RunConfig.reset_for_frontend()
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")

func _on_hub_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	RunConfig.reset_for_frontend()
	get_tree().change_scene_to_file("res://scenes/hub/EsseloriaHub.tscn")

func _on_tutorial_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	RunConfig.reset_for_frontend()
	RunConfig.selected_class_id = RunConfig.CLASS_ARCHER
	RunConfig.selected_map_id = RunConfig.MAP_DEEPWOOD
	RunConfig.tutorial_requested = true
	get_tree().change_scene_to_file("res://scenes/main/TutorialMain.tscn")

func _on_boss_test_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	RunConfig.reset_for_frontend()
	RunConfig.selected_class_id = RunConfig.CLASS_ARCHER
	RunConfig.selected_map_id = RunConfig.MAP_DEEPWOOD
	RunConfig.boss_test_requested = true
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_settings_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	if _settings_content != null:
		_settings_content.refresh_from_settings()
		_settings_content.focus_default_control()
	settings_overlay.visible = true

func _on_close_settings_pressed() -> void:
	if _settings_content != null:
		_settings_content.cancel_binding_capture()
	if GameSettings:
		GameSettings.save_settings()
	settings_overlay.visible = false
	AudioDirector.play_ui("ui_click")

func _on_quit_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	get_tree().quit()

func _wire_button_hover_sfx() -> void:
	var hover_callback: Callable = Callable(self, "_on_any_button_hovered")
	for button in [
		start_button,
		hub_button,
		tutorial_button,
		boss_test_button,
		settings_button,
		quit_button,
	]:
		if button != null and not button.mouse_entered.is_connected(hover_callback):
			button.mouse_entered.connect(hover_callback)

func _on_any_button_hovered() -> void:
	AudioDirector.play_ui("ui_hover", -4.0)

func _apply_theme() -> void:
	FrontendStyle.apply_title(title_label, 72)
	BitmapFontLibrary.apply_short_label(title_label, "title")
	FrontendStyle.apply_small(footer_hint, 14, Color(0.87, 0.82, 0.68, 1.0))
	FrontendStyle.apply_button_theme(start_button, false, false, true)
	FrontendStyle.apply_button_theme(hub_button, false, false, true)
	FrontendStyle.apply_button_theme(tutorial_button, false, false, true)
	FrontendStyle.apply_button_theme(boss_test_button, false, false, true)
	FrontendStyle.apply_button_theme(settings_button, false, false, true)
	FrontendStyle.apply_button_theme(quit_button, true, quit_button.disabled, true)
	_apply_settings_overlay_theme()

func _apply_settings_overlay_theme() -> void:
	if settings_backdrop != null:
		settings_backdrop.color = Color(0.01, 0.02, 0.04, 0.96)
	if settings_panel == null:
		return
	settings_panel.custom_minimum_size = Vector2(720.0, 840.0)
	FrontendStyle.apply_panel_theme(settings_panel, "overlay")
