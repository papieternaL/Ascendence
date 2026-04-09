extends CanvasLayer

## Persistent game settings for graphics/UI/gameplay preferences.
## Persists to user://settings.cfg

const SETTINGS_PATH: String = "user://settings.cfg"
const InputBindings = preload("res://scripts/systems/input_bindings.gd")
const CastTargeting = preload("res://scripts/systems/cast_targeting.gd")
const CURSOR_TEXTURE_PATH: String = "res://art/ui/cursor/game_cursor.png"
const CURSOR_BASE_HOTSPOT: Vector2 = Vector2(6.0, 0.0)
const HUD_SCALE_MIN: float = 0.5
const HUD_SCALE_MAX: float = 1.15
const HUD_SCALE_DEFAULT: float = 0.85
const HUD_SCALE_LEGACY_MIGRATION_RATIO: float = 0.5666667

signal settings_changed

var brightness: float = 0.58
var fullscreen: bool = true
var vsync_enabled: bool = true
var reduced_flashes: bool = false
var show_fps: bool = false
var show_damage_numbers: bool = true
var screen_shake: float = 1.0
var hud_scale: float = HUD_SCALE_DEFAULT
var master_volume: float = 0.5
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var cursor_scale: float = 1.0
var cast_mode: String = "quick_cast"

var _overlay: ColorRect
var _fps_label: Label

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_overlay()
	_ensure_fps_label()
	InputBindings.ensure_actions_exist()
	load_settings()
	_apply_window_mode()
	_apply_vsync()
	_apply_brightness()
	_apply_audio_volumes()
	_update_fps_visibility()
	_apply_custom_cursor()

func _ensure_overlay() -> void:
	if _overlay != null:
		return
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func _apply_brightness() -> void:
	_ensure_overlay()
	var delta: float = brightness - 0.5
	if absf(delta) < 0.01:
		_overlay.color = Color(0, 0, 0, 0)
		_overlay.visible = false
		return
	_overlay.visible = true
	if delta > 0:
		_overlay.color = Color(1.0, 0.99, 0.96, minf(0.24, delta * 0.45))
	else:
		_overlay.color = Color(0, 0, 0, minf(0.35, -delta * 0.60))

func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.0, 1.0)
	_apply_brightness()
	settings_changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window_mode()
	settings_changed.emit()

func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	_apply_vsync()
	settings_changed.emit()

func set_reduced_flashes(value: bool) -> void:
	reduced_flashes = value
	settings_changed.emit()

func set_show_fps(value: bool) -> void:
	show_fps = value
	_update_fps_visibility()
	settings_changed.emit()

func set_show_damage_numbers(value: bool) -> void:
	show_damage_numbers = value
	settings_changed.emit()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio_volumes()
	settings_changed.emit()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_volumes()
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_volumes()
	settings_changed.emit()

func set_cursor_scale(value: float) -> void:
	cursor_scale = clampf(value, 0.75, 2.0)
	_apply_custom_cursor()
	settings_changed.emit()

func _ensure_fps_label() -> void:
	if _fps_label != null:
		return
	_fps_label = Label.new()
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.anchor_left = 1.0
	_fps_label.anchor_right = 1.0
	_fps_label.offset_left = -120.0
	_fps_label.offset_top = 10.0
	_fps_label.offset_right = -12.0
	_fps_label.offset_bottom = 32.0
	_fps_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_fps_label)

func _update_fps_visibility() -> void:
	_ensure_fps_label()
	_fps_label.visible = show_fps

func _apply_custom_cursor() -> void:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(CURSOR_TEXTURE_PATH))
	if image == null or image.is_empty():
		return
	var scaled_image: Image = image.duplicate()
	var base_size: Vector2i = scaled_image.get_size()
	var scaled_width: int = max(1, int(round(base_size.x * cursor_scale)))
	var scaled_height: int = max(1, int(round(base_size.y * cursor_scale)))
	if scaled_width != base_size.x or scaled_height != base_size.y:
		scaled_image.resize(scaled_width, scaled_height, Image.INTERPOLATE_NEAREST)
	var scaled_texture: ImageTexture = ImageTexture.create_from_image(scaled_image)
	var scaled_hotspot: Vector2 = CURSOR_BASE_HOTSPOT * cursor_scale
	Input.set_custom_mouse_cursor(scaled_texture, Input.CURSOR_ARROW, scaled_hotspot)
	Input.set_custom_mouse_cursor(scaled_texture, Input.CURSOR_POINTING_HAND, scaled_hotspot)

func _process(_delta: float) -> void:
	if show_fps and _fps_label != null:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()

func set_screen_shake(value: float) -> void:
	screen_shake = clampf(value, 0.0, 1.0)
	settings_changed.emit()

func set_hud_scale(value: float) -> void:
	hud_scale = clampf(value, HUD_SCALE_MIN, HUD_SCALE_MAX)
	settings_changed.emit()

func set_cast_mode(value: String) -> void:
	cast_mode = CastTargeting.normalize_cast_mode(value)
	settings_changed.emit()

func uses_indicator_release_cast() -> bool:
	return CastTargeting.uses_indicator_release_mode(cast_mode)

func uses_range_indicator_cast() -> bool:
	return CastTargeting.uses_ground_targeting_layer(cast_mode)

func get_binding_label(action_name: String) -> String:
	return InputBindings.get_action_display_label(action_name)

func get_bindable_action_defs() -> Array[Dictionary]:
	return InputBindings.get_bindable_action_defs()

func rebind_action(action_name: String, event: InputEvent) -> void:
	InputBindings.rebind_action_unique(action_name, event)
	save_settings()
	settings_changed.emit()

func reset_gameplay_defaults() -> void:
	cast_mode = CastTargeting.MODE_QUICK_CAST
	InputBindings.reset_to_defaults()
	save_settings()
	settings_changed.emit()

func use_reduced_flashes() -> bool:
	return reduced_flashes

func load_settings() -> void:
	InputBindings.ensure_actions_exist()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	brightness = config.get_value("graphics", "brightness", brightness)
	fullscreen = config.get_value("graphics", "fullscreen", fullscreen)
	vsync_enabled = config.get_value("graphics", "vsync_enabled", vsync_enabled)
	reduced_flashes = config.get_value("gameplay", "reduced_flashes", reduced_flashes)
	show_fps = config.get_value("gameplay", "show_fps", show_fps)
	show_damage_numbers = config.get_value("gameplay", "show_damage_numbers", show_damage_numbers)
	cast_mode = CastTargeting.normalize_cast_mode(str(config.get_value("gameplay", "cast_mode", cast_mode)))
	screen_shake = config.get_value("graphics", "screen_shake", screen_shake)
	hud_scale = config.get_value("ui", "hud_scale", hud_scale)
	var hud_scale_v2_migrated: bool = bool(config.get_value("ui", "hud_scale_v2_migrated", false))
	if not hud_scale_v2_migrated:
		hud_scale = clampf(hud_scale * HUD_SCALE_LEGACY_MIGRATION_RATIO, HUD_SCALE_MIN, HUD_SCALE_MAX)
	cursor_scale = config.get_value("ui", "cursor_scale", cursor_scale)
	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	var saved_bindings: Dictionary = {}
	for action_def in InputBindings.get_bindable_action_defs():
		var action_name: String = str(action_def.get("action", ""))
		if config.has_section_key("keybinds", action_name):
			saved_bindings[action_name] = config.get_value("keybinds", action_name, [])
	if not saved_bindings.is_empty():
		var repaired_bindings: bool = InputBindings.apply_serialized_bindings(saved_bindings)
		if repaired_bindings:
			save_settings()
	var repaired_required_actions: bool = InputBindings.ensure_required_actions_bound([
		"move_up",
		"move_left",
		"move_down",
		"move_right",
		"interact",
	])
	if repaired_required_actions:
		save_settings()
	if not hud_scale_v2_migrated:
		save_settings()
	_apply_audio_volumes()
	_update_fps_visibility()

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("graphics", "brightness", brightness)
	config.set_value("graphics", "fullscreen", fullscreen)
	config.set_value("graphics", "screen_shake", screen_shake)
	config.set_value("graphics", "vsync_enabled", vsync_enabled)
	config.set_value("gameplay", "reduced_flashes", reduced_flashes)
	config.set_value("gameplay", "show_fps", show_fps)
	config.set_value("gameplay", "show_damage_numbers", show_damage_numbers)
	config.set_value("gameplay", "cast_mode", cast_mode)
	config.set_value("ui", "hud_scale", hud_scale)
	config.set_value("ui", "hud_scale_v2_migrated", true)
	config.set_value("ui", "cursor_scale", cursor_scale)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	var serialized_bindings: Dictionary = InputBindings.serialize_bindings()
	for action_name in serialized_bindings.keys():
		config.set_value("keybinds", String(action_name), serialized_bindings[action_name])
	config.save(SETTINGS_PATH)

func _apply_window_mode() -> void:
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	if not fullscreen:
		DisplayServer.window_set_size(Vector2i(1920, 1080))

func _apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

func apply_audio_bus_volumes() -> void:
	_apply_audio_volumes()

func _apply_audio_volumes() -> void:
	_set_bus_volume_linear("Master", master_volume)
	_set_bus_volume_linear("Music", music_volume)
	_set_bus_volume_linear("Ambience", music_volume)
	_set_bus_volume_linear("SFX", sfx_volume)
	_set_bus_volume_linear("UI", sfx_volume)

func _set_bus_volume_linear(bus_name: String, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var linear: float = clampf(value, 0.0, 1.0)
	var db: float = -80.0 if linear <= 0.0001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(bus_index, db)
