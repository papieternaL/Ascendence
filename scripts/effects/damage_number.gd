extends Label

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")
const BitmapFontLibrary = preload("res://scripts/ui/bitmap_font_library.gd")

@export var drift_velocity: Vector2 = Vector2(0.0, -56.0)
@export var lifetime: float = 0.7
@export var crit_scale: float = 1.22
@export var normal_label_settings: LabelSettings
@export var crit_label_settings: LabelSettings

var _remaining: float = 0.0
static var _default_normal_settings: LabelSettings
static var _default_crit_settings: LabelSettings

func setup(amount: float, is_crit: bool) -> void:
	text = str(int(round(amount)))
	modulate = Color(1.0, 0.95, 0.60, 1.0) if is_crit else Color(0.98, 1.0, 1.0, 1.0)
	scale = Vector2.ONE * (crit_scale if is_crit else 1.08)
	var next_settings: LabelSettings = _get_label_settings(is_crit)
	if label_settings != next_settings:
		label_settings = next_settings
	_remaining = lifetime

func _ready() -> void:
	_remaining = lifetime if _remaining <= 0.0 else _remaining
	if label_settings == null:
		label_settings = _get_label_settings(false)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _process(delta: float) -> void:
	position += drift_velocity * delta
	_remaining -= delta
	modulate.a = clamp(_remaining / lifetime, 0.0, 1.0)
	if _remaining <= 0.0:
		queue_free()

func _get_label_settings(is_crit: bool) -> LabelSettings:
	if is_crit and crit_label_settings != null:
		return crit_label_settings
	if not is_crit and normal_label_settings != null:
		return normal_label_settings
	return BitmapFontLibrary.make_damage_label_settings(is_crit)

func _build_default_label_settings(is_crit: bool) -> LabelSettings:
	if is_crit and _default_crit_settings != null:
		return _default_crit_settings
	if not is_crit and _default_normal_settings != null:
		return _default_normal_settings
	var settings: LabelSettings = LabelSettings.new()
	settings.font = FrontendStyle.FONT_BODY
	settings.font_size = 28 if is_crit else 24
	settings.outline_size = 7 if is_crit else 6
	settings.outline_color = Color(0.02, 0.03, 0.05, 1.0)
	settings.font_color = Color(1.0, 0.95, 0.60, 1.0) if is_crit else Color(0.98, 1.0, 1.0, 1.0)
	if is_crit:
		_default_crit_settings = settings
	else:
		_default_normal_settings = settings
	return settings
