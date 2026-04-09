class_name BitmapFontLibrary
extends RefCounted

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

static var _cached_bitmap_font: Font
static var _cached_damage_label_settings: LabelSettings
static var _cached_damage_crit_label_settings: LabelSettings

static func get_bitmap_font() -> Font:
	if _cached_bitmap_font != null:
		return _cached_bitmap_font
	_cached_bitmap_font = FrontendStyle.FONT_BODY
	return _cached_bitmap_font

static func apply_short_label(label: Label, preset: String = "ui_short") -> void:
	if label == null:
		return
	label.add_theme_font_override("font", get_bitmap_font())
	match preset:
		"title":
			label.add_theme_font_size_override("font_size", 72)
			label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.34, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.04, 0.98))
			label.add_theme_constant_override("outline_size", 7)
		"level_up":
			label.add_theme_font_size_override("font_size", 30)
			label.add_theme_color_override("font_color", Color(0.94, 1.0, 0.42, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.05, 0.96))
			label.add_theme_constant_override("outline_size", 5)
		"upgrade_title":
			label.add_theme_font_size_override("font_size", 22)
			label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.82, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.96))
			label.add_theme_constant_override("outline_size", 4)
		"damage_number":
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
			label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08, 0.92))
			label.add_theme_constant_override("outline_size", 6)
		_:
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08, 0.92))
			label.add_theme_constant_override("outline_size", 3)

static func apply_button_text(button: Button, preset: String = "menu_button", color: Color = Color(0.94, 0.91, 0.82, 1.0)) -> void:
	if button == null:
		return
	button.add_theme_font_override("font", get_bitmap_font())
	match preset:
		"menu_button":
			button.add_theme_font_size_override("font_size", 18)
			button.add_theme_color_override("font_color", color)
			button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.90, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(1.0, 0.97, 0.90, 1.0))
			button.add_theme_color_override("font_disabled_color", Color(0.56, 0.58, 0.62, 1.0))
			button.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.96))
			button.add_theme_constant_override("outline_size", 3)
		_:
			button.add_theme_font_size_override("font_size", 16)
			button.add_theme_color_override("font_color", color)

static func make_damage_label_settings(is_crit: bool = false) -> LabelSettings:
	if is_crit and _cached_damage_crit_label_settings != null:
		return _cached_damage_crit_label_settings
	if not is_crit and _cached_damage_label_settings != null:
		return _cached_damage_label_settings
	var settings: LabelSettings = LabelSettings.new()
	settings.font = get_bitmap_font()
	settings.font_size = 28 if is_crit else 24
	settings.outline_size = 8 if is_crit else 7
	settings.outline_color = Color(0.02, 0.03, 0.05, 1.0)
	settings.font_color = Color(1.0, 0.95, 0.60, 1.0) if is_crit else Color(0.98, 1.0, 1.0, 1.0)
	if is_crit:
		_cached_damage_crit_label_settings = settings
	else:
		_cached_damage_label_settings = settings
	return settings
