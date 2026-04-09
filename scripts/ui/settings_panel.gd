class_name SettingsPanel
extends VBoxContainer

signal close_requested
signal hover_sfx_requested

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")
const InputBindings = preload("res://scripts/systems/input_bindings.gd")

const CATEGORY_GRAPHICS: String = "graphics"
const CATEGORY_SOUND: String = "sound"
const CATEGORY_GAMEPLAY: String = "gameplay"

var _active_category: String = CATEGORY_GRAPHICS
var _capture_action: String = ""
var _capture_ignore_next_left_mouse: bool = false

var _title_label: Label
var _capture_hint_label: Label
var _category_buttons: Dictionary = {}
var _category_sections: Dictionary = {}

var _display_mode_button: Button
var _resolution_label: Label
var _brightness_label: Label
var _brightness_slider: HSlider
var _hud_scale_label: Label
var _hud_scale_slider: HSlider
var _cursor_scale_label: Label
var _cursor_scale_slider: HSlider
var _screen_shake_label: Label
var _screen_shake_slider: HSlider
var _vsync_check: CheckButton
var _reduced_flashes_check: CheckButton
var _show_fps_check: CheckButton
var _show_damage_numbers_check: CheckButton

var _master_volume_label: Label
var _master_volume_slider: HSlider
var _music_volume_label: Label
var _music_volume_slider: HSlider
var _sfx_volume_label: Label
var _sfx_volume_slider: HSlider

var _cast_mode_option: OptionButton
var _binding_buttons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_process_input(true)
	_build_ui()
	refresh_from_settings()
	if GameSettings != null and not GameSettings.settings_changed.is_connected(_on_game_settings_changed):
		GameSettings.settings_changed.connect(_on_game_settings_changed)

func _exit_tree() -> void:
	if GameSettings != null and GameSettings.settings_changed.is_connected(_on_game_settings_changed):
		GameSettings.settings_changed.disconnect(_on_game_settings_changed)

func is_capturing_binding() -> bool:
	return not _capture_action.is_empty()

func cancel_binding_capture() -> void:
	if _capture_action.is_empty():
		return
	_capture_action = ""
	_capture_ignore_next_left_mouse = false
	_update_capture_hint()
	_refresh_binding_button_labels()

func refresh_from_settings() -> void:
	if GameSettings == null:
		return
	_brightness_slider.value = GameSettings.brightness
	_hud_scale_slider.value = GameSettings.hud_scale
	_cursor_scale_slider.value = GameSettings.cursor_scale
	_screen_shake_slider.value = GameSettings.screen_shake
	_vsync_check.button_pressed = GameSettings.vsync_enabled
	_reduced_flashes_check.button_pressed = GameSettings.reduced_flashes
	_show_fps_check.button_pressed = GameSettings.show_fps
	_show_damage_numbers_check.button_pressed = GameSettings.show_damage_numbers
	_master_volume_slider.value = GameSettings.master_volume
	_music_volume_slider.value = GameSettings.music_volume
	_sfx_volume_slider.value = GameSettings.sfx_volume
	_select_option_value(_cast_mode_option, GameSettings.cast_mode)
	_update_value_labels()
	_refresh_binding_button_labels()
	_update_category_visibility()
	_apply_theme()

func focus_default_control() -> void:
	if _category_buttons.has(_active_category):
		var button: Button = _category_buttons[_active_category] as Button
		if button != null:
			button.grab_focus()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _capture_action.is_empty():
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			cancel_binding_capture()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _capture_ignore_next_left_mouse:
			_capture_ignore_next_left_mouse = false
			get_viewport().set_input_as_handled()
			return
	var captured: InputEvent = InputBindings.capture_supported_event(event)
	if captured == null:
		return
	GameSettings.rebind_action(_capture_action, captured)
	_capture_action = ""
	_capture_ignore_next_left_mouse = false
	_update_capture_hint()
	_refresh_binding_button_labels()
	get_viewport().set_input_as_handled()

func _begin_binding_capture(action_name: String) -> void:
	_capture_action = action_name
	_capture_ignore_next_left_mouse = true
	_update_capture_hint()
	_refresh_binding_button_labels()

func _build_ui() -> void:
	if _title_label != null:
		return
	add_theme_constant_override("separation", 14)
	_title_label = Label.new()
	_title_label.text = "SETTINGS"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	var category_row: HBoxContainer = HBoxContainer.new()
	category_row.add_theme_constant_override("separation", 10)
	add_child(category_row)
	for category_data in [
		{"id": CATEGORY_GRAPHICS, "label": "Graphics"},
		{"id": CATEGORY_SOUND, "label": "Sound"},
		{"id": CATEGORY_GAMEPLAY, "label": "Gameplay"},
	]:
		var button: Button = Button.new()
		button.text = str(category_data.get("label", ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 42.0)
		button.pressed.connect(_on_category_selected.bind(str(category_data.get("id", ""))))
		button.mouse_entered.connect(_emit_hover_sfx)
		category_row.add_child(button)
		_category_buttons[str(category_data.get("id", ""))] = button

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 560.0)
	add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)

	var graphics_section: VBoxContainer = _make_section(content)
	_category_sections[CATEGORY_GRAPHICS] = graphics_section
	_display_mode_button = _make_button_row(graphics_section, "DISPLAY: FULLSCREEN", _on_display_mode_pressed)
	_resolution_label = _make_body_label(graphics_section, "TARGET RESOLUTION: 1920 x 1080", true)
	_brightness_label = _make_body_label(graphics_section, "BRIGHTNESS", false)
	_brightness_slider = _make_slider(graphics_section, 0.0, 1.0, 0.05, _on_brightness_changed)
	_hud_scale_label = _make_body_label(graphics_section, "HUD SCALE", false)
	_hud_scale_slider = _make_slider(graphics_section, GameSettings.HUD_SCALE_MIN, GameSettings.HUD_SCALE_MAX, 0.05, _on_hud_scale_changed)
	_cursor_scale_label = _make_body_label(graphics_section, "CURSOR SIZE", false)
	_cursor_scale_slider = _make_slider(graphics_section, 0.75, 2.0, 0.05, _on_cursor_scale_changed)
	_screen_shake_label = _make_body_label(graphics_section, "SCREEN SHAKE", false)
	_screen_shake_slider = _make_slider(graphics_section, 0.0, 1.0, 0.05, _on_screen_shake_changed)
	_vsync_check = _make_check(graphics_section, "VSync", _on_vsync_toggled)
	_reduced_flashes_check = _make_check(graphics_section, "Reduced Flashes", _on_reduced_flashes_toggled)
	_show_fps_check = _make_check(graphics_section, "Show FPS", _on_show_fps_toggled)
	_show_damage_numbers_check = _make_check(graphics_section, "Show Damage Numbers", _on_show_damage_numbers_toggled)

	var sound_section: VBoxContainer = _make_section(content)
	_category_sections[CATEGORY_SOUND] = sound_section
	_master_volume_label = _make_body_label(sound_section, "MASTER VOLUME", false)
	_master_volume_slider = _make_slider(sound_section, 0.0, 1.0, 0.05, _on_master_volume_changed)
	_music_volume_label = _make_body_label(sound_section, "MUSIC VOLUME", false)
	_music_volume_slider = _make_slider(sound_section, 0.0, 1.0, 0.05, _on_music_volume_changed)
	_sfx_volume_label = _make_body_label(sound_section, "SFX VOLUME", false)
	_sfx_volume_slider = _make_slider(sound_section, 0.0, 1.0, 0.05, _on_sfx_volume_changed)

	var gameplay_section: VBoxContainer = _make_section(content)
	_category_sections[CATEGORY_GAMEPLAY] = gameplay_section
	var gameplay_options_label: Label = Label.new()
	gameplay_options_label.text = "PLAYSTYLE"
	gameplay_section.add_child(gameplay_options_label)
	FrontendStyle.apply_header(gameplay_options_label, 20, Color(0.95, 0.82, 0.52, 1.0))
	var cast_row: HBoxContainer = HBoxContainer.new()
	cast_row.add_theme_constant_override("separation", 12)
	gameplay_section.add_child(cast_row)
	var cast_label: Label = Label.new()
	cast_label.text = "Cast Mode"
	cast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cast_row.add_child(cast_label)
	FrontendStyle.apply_body(cast_label, 14, Color(0.92, 0.86, 0.72, 1.0))
	_cast_mode_option = _make_option_button(
		cast_row,
		[
			{"id": "quick_cast", "label": "Quick Cast"},
			{"id": "quick_cast_indicator", "label": "Quick Cast with Indicator"},
			{"id": "range_indicator", "label": "Range Indicator"},
		],
		_on_cast_mode_selected
	)

	var bindings_header: Label = Label.new()
	bindings_header.text = "KEYBINDS"
	gameplay_section.add_child(bindings_header)
	FrontendStyle.apply_header(bindings_header, 20, Color(0.95, 0.82, 0.52, 1.0))
	for action_def in InputBindings.get_bindable_action_defs():
		var bind_row: HBoxContainer = HBoxContainer.new()
		bind_row.alignment = BoxContainer.ALIGNMENT_CENTER
		bind_row.add_theme_constant_override("separation", 14)
		gameplay_section.add_child(bind_row)
		var label_stack: VBoxContainer = VBoxContainer.new()
		label_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_stack.add_theme_constant_override("separation", 2)
		bind_row.add_child(label_stack)
		var bind_label: Label = Label.new()
		bind_label.text = str(action_def.get("label", ""))
		label_stack.add_child(bind_label)
		FrontendStyle.apply_body(bind_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		var bind_desc: Label = Label.new()
		bind_desc.text = str(action_def.get("description", ""))
		label_stack.add_child(bind_desc)
		FrontendStyle.apply_small(bind_desc, 12, Color(0.76, 0.82, 0.9, 1.0))
		var bind_button: Button = Button.new()
		bind_button.custom_minimum_size = Vector2(170.0, 40.0)
		bind_button.text = "UNBOUND"
		bind_button.pressed.connect(_on_rebind_button_pressed.bind(str(action_def.get("action", ""))))
		bind_button.mouse_entered.connect(_emit_hover_sfx)
		bind_row.add_child(bind_button)
		_binding_buttons[str(action_def.get("action", ""))] = bind_button

	_capture_hint_label = Label.new()
	_capture_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capture_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gameplay_section.add_child(_capture_hint_label)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	add_child(bottom_row)
	var reset_button: Button = Button.new()
	reset_button.text = "RESET GAMEPLAY DEFAULTS"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.custom_minimum_size = Vector2(0.0, 42.0)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_button.mouse_entered.connect(_emit_hover_sfx)
	bottom_row.add_child(reset_button)
	var close_button: Button = Button.new()
	close_button.text = "BACK"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.custom_minimum_size = Vector2(0.0, 42.0)
	close_button.pressed.connect(func() -> void:
		cancel_binding_capture()
		close_requested.emit()
	)
	close_button.mouse_entered.connect(_emit_hover_sfx)
	bottom_row.add_child(close_button)

	_update_capture_hint()
	_apply_theme()

func _make_section(parent: Control) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 12)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(section)
	return section

func _make_body_label(parent: Control, text: String, centered: bool) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(label)
	FrontendStyle.apply_body(label, 14, Color(0.92, 0.86, 0.72, 1.0))
	return label

func _make_button_row(parent: Control, text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.pressed.connect(callback)
	button.mouse_entered.connect(_emit_hover_sfx)
	parent.add_child(button)
	FrontendStyle.apply_button_theme(button, false, false, true)
	return button

func _make_slider(parent: Control, min_value: float, max_value: float, step: float, callback: Callable) -> HSlider:
	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(240.0, 24.0)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value_changed.connect(callback)
	parent.add_child(slider)
	return slider

func _make_check(parent: Control, text: String, callback: Callable) -> CheckButton:
	var check: CheckButton = CheckButton.new()
	check.text = text
	check.custom_minimum_size = Vector2(0.0, 34.0)
	check.toggled.connect(callback)
	check.mouse_entered.connect(_emit_hover_sfx)
	parent.add_child(check)
	check.add_theme_font_override("font", FrontendStyle.FONT_BODY)
	check.add_theme_font_size_override("font_size", 14)
	check.add_theme_color_override("font_color", Color(0.88, 0.90, 0.93, 1.0))
	return check

func _make_option_button(parent: Control, options: Array[Dictionary], callback: Callable) -> OptionButton:
	var option_button: OptionButton = OptionButton.new()
	option_button.custom_minimum_size = Vector2(220.0, 40.0)
	for option_data in options:
		option_button.add_item(str(option_data.get("label", "")))
		var item_index: int = option_button.item_count - 1
		option_button.set_item_metadata(item_index, str(option_data.get("id", "")))
	option_button.item_selected.connect(callback)
	option_button.mouse_entered.connect(_emit_hover_sfx)
	parent.add_child(option_button)
	FrontendStyle.apply_button_theme(option_button, false, false, true)
	return option_button

func _select_option_value(option_button: OptionButton, value: String) -> void:
	if option_button == null:
		return
	for i in range(option_button.item_count):
		if str(option_button.get_item_metadata(i)) == value:
			option_button.select(i)
			return

func _apply_theme() -> void:
	FrontendStyle.apply_header(_title_label, 32, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_small(_capture_hint_label, 12, Color(0.84, 0.88, 0.96, 1.0))
	for category_id in _category_buttons.keys():
		var is_selected: bool = String(category_id) == _active_category
		FrontendStyle.apply_button_theme(_category_buttons[category_id] as Button, is_selected, false, true)
	for bind_button in _binding_buttons.values():
		FrontendStyle.apply_button_theme(bind_button as Button, false, false, true)
	if _display_mode_button != null:
		FrontendStyle.apply_button_theme(_display_mode_button, false, false, true)

func _update_category_visibility() -> void:
	for category_id in _category_sections.keys():
		var section: VBoxContainer = _category_sections[category_id] as VBoxContainer
		if section != null:
			section.visible = String(category_id) == _active_category
	_apply_theme()

func _update_value_labels() -> void:
	if GameSettings == null:
		return
	_display_mode_button.text = "DISPLAY: %s" % ("FULLSCREEN" if GameSettings.fullscreen else "WINDOWED")
	_resolution_label.text = "TARGET RESOLUTION: 1920 x 1080"
	_brightness_label.text = "BRIGHTNESS: %d%%" % int(round(_brightness_slider.value * 100.0))
	_hud_scale_label.text = "HUD SCALE: %d%%" % int(round(_hud_scale_slider.value * 100.0))
	_cursor_scale_label.text = "CURSOR SIZE: %d%%" % int(round(_cursor_scale_slider.value * 100.0))
	_screen_shake_label.text = "SCREEN SHAKE: %d%%" % int(round(_screen_shake_slider.value * 100.0))
	_master_volume_label.text = "MASTER VOLUME: %d%%" % int(round(_master_volume_slider.value * 100.0))
	_music_volume_label.text = "MUSIC VOLUME: %d%%" % int(round(_music_volume_slider.value * 100.0))
	_sfx_volume_label.text = "SFX VOLUME: %d%%" % int(round(_sfx_volume_slider.value * 100.0))

func _refresh_binding_button_labels() -> void:
	for action_name in _binding_buttons.keys():
		var bind_button: Button = _binding_buttons[action_name] as Button
		if bind_button == null:
			continue
		if _capture_action == String(action_name):
			bind_button.text = "PRESS A KEY..."
			continue
		bind_button.text = InputBindings.get_action_display_label(String(action_name))

func _update_capture_hint() -> void:
	if _capture_hint_label == null:
		return
	if _capture_action.is_empty():
		_capture_hint_label.text = "Click a binding, then press a keyboard key or mouse button. Press Esc to cancel."
		return
	_capture_hint_label.text = "Waiting for %s..." % InputBindings.get_action_label(_capture_action)

func _on_game_settings_changed() -> void:
	refresh_from_settings()

func _on_category_selected(category_id: String) -> void:
	_active_category = category_id
	_update_category_visibility()

func _on_display_mode_pressed() -> void:
	if GameSettings != null:
		GameSettings.set_fullscreen(not GameSettings.fullscreen)
	_update_value_labels()

func _on_brightness_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_brightness(value)
	_update_value_labels()

func _on_hud_scale_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_hud_scale(value)
	_update_value_labels()

func _on_cursor_scale_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_cursor_scale(value)
	_update_value_labels()

func _on_screen_shake_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_screen_shake(value)
	_update_value_labels()

func _on_vsync_toggled(toggled_on: bool) -> void:
	if GameSettings != null:
		GameSettings.set_vsync_enabled(toggled_on)

func _on_reduced_flashes_toggled(toggled_on: bool) -> void:
	if GameSettings != null:
		GameSettings.set_reduced_flashes(toggled_on)

func _on_show_fps_toggled(toggled_on: bool) -> void:
	if GameSettings != null:
		GameSettings.set_show_fps(toggled_on)

func _on_show_damage_numbers_toggled(toggled_on: bool) -> void:
	if GameSettings != null:
		GameSettings.set_show_damage_numbers(toggled_on)

func _on_master_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_master_volume(value)
	_update_value_labels()

func _on_music_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_music_volume(value)
	_update_value_labels()

func _on_sfx_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_sfx_volume(value)
	_update_value_labels()

func _on_cast_mode_selected(index: int) -> void:
	if GameSettings == null:
		return
	GameSettings.set_cast_mode(str(_cast_mode_option.get_item_metadata(index)))

func _on_rebind_button_pressed(action_name: String) -> void:
	call_deferred("_begin_binding_capture", action_name)

func _on_reset_pressed() -> void:
	if GameSettings != null:
		GameSettings.reset_gameplay_defaults()
	cancel_binding_capture()
	refresh_from_settings()

func _emit_hover_sfx() -> void:
	hover_sfx_requested.emit()
