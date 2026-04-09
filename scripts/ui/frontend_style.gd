class_name FrontendStyle
extends RefCounted

const FONT_TITLE: FontFile = preload("res://assets/fonts/DepartureMono-1.500/DepartureMono-Regular.otf")
const FONT_HEADER: FontFile = preload("res://assets/fonts/DepartureMono-1.500/DepartureMono-Regular.otf")
const FONT_BODY: FontFile = preload("res://assets/fonts/DepartureMono-1.500/DepartureMono-Regular.otf")
const FONT_READABLE: FontFile = preload("res://assets/fonts/DepartureMono-1.500/DepartureMono-Regular.otf")
const ICONS_BASE_PATH: String = "res://art/ui/icons/"
const CHROME_BASE_PATH: String = "res://art/ui/chrome/"
const ICON_CANVAS_SIZE: int = 96
const ICON_PIXEL_SIZE: int = 48
const ICON_FILL_RATIO: float = 0.92
const ICON_ALPHA_THRESHOLD: float = 0.035
const ICON_SATURATION_BOOST: float = 1.08
const ICON_CONTRAST_BOOST: float = 1.06
const ICON_BRIGHTNESS_SHIFT: float = 0.01
const ICON_COLOR_STEPS: int = 12
const ICON_ALPHA_STEPS: int = 10

static var _icon_texture_cache: Dictionary = {}
static var _chrome_texture_cache: Dictionary = {}

static func apply_title(label: Label, size: int = 72, color: Color = Color(0.95, 0.80, 0.52, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.14, 0.10, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 5)

static func apply_header(label: Label, size: int = 28, color: Color = Color(0.93, 0.90, 0.82, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_HEADER)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 0.9))
	label.add_theme_constant_override("outline_size", 2)

static func apply_body(label: Label, size: int = 18, color: Color = Color(0.88, 0.90, 0.93, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.06, 0.9))
	label.add_theme_constant_override("outline_size", 1)

static func apply_readable_body(label: Label, size: int = 18, color: Color = Color(0.88, 0.90, 0.93, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_READABLE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.06, 0.86))
	label.add_theme_constant_override("outline_size", 1)

static func apply_small(label: Label, size: int = 13, color: Color = Color(0.72, 0.71, 0.68, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func apply_readable_small(label: Label, size: int = 13, color: Color = Color(0.72, 0.71, 0.68, 1.0)) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_READABLE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func make_style(bg: Color, border: Color, radius: int, border_width: int = 2) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	return style

static func _clamp_channel(value: float) -> float:
	return clampf(value, 0.0, 1.0)

static func _shift_color(color: Color, amount: float) -> Color:
	return Color(
		_clamp_channel(color.r + amount),
		_clamp_channel(color.g + amount),
		_clamp_channel(color.b + amount),
		color.a
	)

static func _build_box_style(
	bg: Color,
	border: Color,
	content_margin: int,
	radius: int = 10,
	border_width: int = 2
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style

static func icon_texture_path(icon_asset_id: String) -> String:
	var resolved_id: String = icon_asset_id.strip_edges()
	if resolved_id.is_empty():
		return ""
	return "%s%s.png" % [ICONS_BASE_PATH, resolved_id]

static func make_icon_texture(icon_asset_id: String) -> Texture2D:
	var resolved_id: String = icon_asset_id.strip_edges()
	if resolved_id.is_empty():
		return null
	if _icon_texture_cache.has(resolved_id):
		return _icon_texture_cache[resolved_id] as Texture2D
	var resource_path: String = icon_texture_path(resolved_id)
	var texture: Texture2D = null
	var image: Image = _load_icon_image(resource_path)
	if image != null and not image.is_empty():
		texture = _make_processed_icon_texture(image)
	if texture != null:
		_icon_texture_cache[resolved_id] = texture
	return texture

static func has_icon(icon_asset_id: String) -> bool:
	var resource_path: String = icon_texture_path(icon_asset_id)
	return not resource_path.is_empty() and (FileAccess.file_exists(resource_path) or ResourceLoader.exists(resource_path))

static func _load_icon_image(resource_path: String) -> Image:
	if resource_path.is_empty():
		return null
	if ResourceLoader.exists(resource_path):
		var resource: Resource = load(resource_path)
		if resource is Texture2D:
			var texture_image: Image = (resource as Texture2D).get_image()
			if texture_image != null and not texture_image.is_empty():
				texture_image.convert(Image.FORMAT_RGBA8)
				return texture_image
	if FileAccess.file_exists(resource_path):
		var file_image: Image = Image.load_from_file(resource_path)
		if file_image != null and not file_image.is_empty():
			file_image.convert(Image.FORMAT_RGBA8)
			return file_image
	return null

static func _make_processed_icon_texture(source_image: Image) -> Texture2D:
	if source_image == null or source_image.is_empty():
		return null
	var visible_rect: Rect2i = _find_icon_visible_rect(source_image)
	var squared: Image = _fit_icon_to_square(source_image, visible_rect)
	if squared == null or squared.is_empty():
		return null
	squared.resize(ICON_PIXEL_SIZE, ICON_PIXEL_SIZE, Image.INTERPOLATE_BILINEAR)
	_stylize_icon_image(squared)
	squared.resize(ICON_CANVAS_SIZE, ICON_CANVAS_SIZE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(squared)

static func _find_icon_visible_rect(image: Image) -> Rect2i:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var min_x: int = width
	var min_y: int = height
	var max_x: int = -1
	var max_y: int = -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > ICON_ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(0, 0, width, height)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

static func _fit_icon_to_square(image: Image, visible_rect: Rect2i) -> Image:
	if image == null or image.is_empty():
		return null
	var crop_size: Vector2i = visible_rect.size
	if crop_size.x <= 0 or crop_size.y <= 0:
		crop_size = Vector2i(image.get_width(), image.get_height())
		visible_rect = Rect2i(Vector2i.ZERO, crop_size)
	var cropped: Image = image.get_region(visible_rect)
	var content_side: int = maxi(crop_size.x, crop_size.y)
	var target_side: int = maxi(content_side, int(ceil(float(content_side) / ICON_FILL_RATIO)))
	var canvas: Image = Image.create(target_side, target_side, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.0, 0.0, 0.0, 0.0))
	var offset: Vector2i = Vector2i(
		int(floor(float(target_side - crop_size.x) * 0.5)),
		int(floor(float(target_side - crop_size.y) * 0.5))
	)
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, crop_size), offset)
	return canvas

static func _stylize_icon_image(image: Image) -> void:
	if image == null or image.is_empty():
		return
	var width: int = image.get_width()
	var height: int = image.get_height()
	for y in range(height):
		for x in range(width):
			var color: Color = image.get_pixel(x, y)
			if color.a <= ICON_ALPHA_THRESHOLD:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			var luminance: float = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			var grayscale: Color = Color(luminance, luminance, luminance, color.a)
			var saturated: Color = grayscale.lerp(color, ICON_SATURATION_BOOST)
			var stylized: Color = Color(
				_posterize_channel((saturated.r - 0.5) * ICON_CONTRAST_BOOST + 0.5 + ICON_BRIGHTNESS_SHIFT),
				_posterize_channel((saturated.g - 0.5) * ICON_CONTRAST_BOOST + 0.5 + ICON_BRIGHTNESS_SHIFT),
				_posterize_channel((saturated.b - 0.5) * ICON_CONTRAST_BOOST + 0.5 + ICON_BRIGHTNESS_SHIFT),
				_posterize_alpha(color.a)
			)
			if luminance < 0.18:
				stylized = stylized.darkened(0.08)
			elif luminance > 0.72:
				stylized = stylized.lightened(0.04)
			image.set_pixel(x, y, stylized)

static func _posterize_channel(value: float) -> float:
	var clamped: float = clampf(value, 0.0, 1.0)
	var steps: int = maxi(ICON_COLOR_STEPS - 1, 1)
	return round(clamped * float(steps)) / float(steps)

static func _posterize_alpha(value: float) -> float:
	var clamped: float = clampf(value, 0.0, 1.0)
	var steps: int = maxi(ICON_ALPHA_STEPS, 1)
	return round(clamped * float(steps)) / float(steps)

static func chrome_texture_path(chrome_asset_id: String) -> String:
	var resolved_id: String = chrome_asset_id.strip_edges()
	if resolved_id.is_empty():
		return ""
	return "%s%s.png" % [CHROME_BASE_PATH, resolved_id]

static func make_chrome_texture(chrome_asset_id: String) -> Texture2D:
	var resolved_id: String = chrome_asset_id.strip_edges()
	if resolved_id.is_empty():
		return null
	if _chrome_texture_cache.has(resolved_id):
		return _chrome_texture_cache[resolved_id] as Texture2D
	var resource_path: String = chrome_texture_path(resolved_id)
	var texture: Texture2D = null
	if ResourceLoader.exists(resource_path):
		texture = load(resource_path) as Texture2D
	if texture == null and FileAccess.file_exists(resource_path):
		var image: Image = Image.load_from_file(resource_path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture != null:
		_chrome_texture_cache[resolved_id] = texture
	return texture

static func make_texture_style(region_name: String, _texture_margin: int = 18, content_margin: int = 8) -> StyleBox:
	match region_name:
		"button":
			return _build_box_style(Color(0.05, 0.08, 0.11, 0.92), Color(0.32, 0.38, 0.48, 0.92), content_margin, 6, 1)
		"timer", "large_bar", "upgrade_header":
			return _build_box_style(Color(0.04, 0.07, 0.11, 0.86), Color(0.20, 0.26, 0.34, 0.86), content_margin, 6, 1)
		"small_bar":
			return _build_box_style(Color(0.05, 0.08, 0.12, 0.74), Color(0.54, 0.64, 0.78, 0.92), content_margin, 6, 2)
		"level_badge":
			return _build_box_style(Color(0.05, 0.08, 0.12, 0.92), Color(0.68, 0.78, 0.92, 0.96), content_margin, 26, 1)
		"slot":
			return _build_box_style(Color(0.05, 0.04, 0.03, 0.96), Color(0.44, 0.32, 0.16, 0.94), content_margin, 6, 1)
		"card_common":
			return _build_box_style(Color(0.08, 0.09, 0.13, 0.96), Color(0.30, 0.34, 0.42, 0.84), content_margin, 12, 1)
		"card_rare", "preview_card":
			return _build_box_style(Color(0.08, 0.09, 0.13, 0.96), Color(0.34, 0.52, 0.74, 0.92), content_margin, 12, 1)
		"card_epic":
			return _build_box_style(Color(0.08, 0.09, 0.13, 0.96), Color(0.56, 0.40, 0.80, 0.92), content_margin, 12, 1)
		## Roguelike-style highlight (cyan border, slate body).
		"upgrade_card_selected":
			return _build_box_style(Color(0.07, 0.10, 0.15, 0.97), Color(0.72, 0.86, 0.98, 1.0), content_margin, 12, 2)
		"upgrade_header_bar":
			return _build_box_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), content_margin, 0, 0)
		"upgrade_icon_well":
			return _build_box_style(Color(0.12, 0.15, 0.20, 0.84), Color(0.26, 0.32, 0.42, 0.86), content_margin, 10, 1)
		"selected_card":
			return _build_box_style(Color(0.07, 0.12, 0.11, 0.96), Color(0.34, 0.84, 0.48, 1.0), content_margin, 12, 2)
		"locked":
			return _build_box_style(Color(0.08, 0.10, 0.14, 0.86), Color(0.27, 0.30, 0.36, 1.0), content_margin, 12, 2)
		## Spell Brigade–style HUD: level ring, shield ability slots, thin XP track.
		"spell_level_ring":
			return _build_box_style(Color(0.04, 0.04, 0.06, 0.94), Color(0.52, 0.48, 0.36, 0.96), content_margin, 34, 2)
		"ability_orb":
			return _build_box_style(Color(0.03, 0.025, 0.02, 0.97), Color(0.60, 0.46, 0.22, 0.98), content_margin, 6, 2)
		"hud_xp_track":
			return _build_box_style(Color(0.02, 0.03, 0.05, 0.90), Color(0.0, 0.0, 0.0, 0.0), content_margin, 1, 0)
		"health_bar_spell":
			return _build_box_style(Color(0.03, 0.04, 0.06, 0.94), Color(0.36, 0.30, 0.20, 0.88), content_margin, 5, 2)
		"ability_pill":
			return _build_box_style(Color(0.05, 0.07, 0.10, 0.96), Color(0.18, 0.22, 0.30, 0.86), content_margin, 4, 1)
		## WoW-style bag inventory.
		"bag_frame":
			return _build_box_style(Color(0.06, 0.05, 0.04, 0.97), Color(0.38, 0.30, 0.18, 0.96), content_margin, 4, 2)
		"bag_title_bar":
			return _build_box_style(Color(0.10, 0.08, 0.05, 0.96), Color(0.42, 0.34, 0.20, 0.90), content_margin, 3, 1)
		"bag_slot":
			return _build_box_style(Color(0.08, 0.07, 0.05, 0.94), Color(0.30, 0.26, 0.18, 0.88), content_margin, 3, 1)
		"bag_slot_filled":
			return _build_box_style(Color(0.10, 0.09, 0.06, 0.96), Color(0.48, 0.40, 0.24, 0.94), content_margin, 3, 1)
		"bag_slot_selected":
			return _build_box_style(Color(0.13, 0.10, 0.05, 0.98), Color(0.86, 0.66, 0.24, 1.0), content_margin, 3, 2)
		"bag_gold_bar":
			return _build_box_style(Color(0.04, 0.04, 0.03, 0.92), Color(0.32, 0.28, 0.16, 0.80), content_margin, 3, 1)
		_:
			return _build_box_style(Color(0.05, 0.07, 0.10, 0.94), Color(0.20, 0.26, 0.34, 0.88), content_margin, 8, 1)

static func _make_button_style(selected: bool, hovered: bool, pressed: bool, disabled: bool, content_margin: int) -> StyleBox:
	var bg: Color = Color(0.05, 0.08, 0.11, 0.94)
	var border: Color = Color(0.28, 0.34, 0.42, 0.92)
	if selected:
		bg = Color(0.08, 0.11, 0.16, 0.96)
		border = Color(0.72, 0.84, 0.96, 0.98)
	if hovered:
		bg = _shift_color(bg, 0.05)
		border = _shift_color(border, 0.04)
	if pressed:
		bg = _shift_color(bg, -0.03)
		border = _shift_color(border, 0.08)
	if disabled:
		bg = Color(0.08, 0.10, 0.13, 0.84)
		border = Color(0.24, 0.27, 0.32, 1.0)
	return _build_box_style(bg, border, content_margin, 6, 1)

static func apply_button_theme(button: Button, selected: bool = false, disabled: bool = false, compact: bool = false) -> void:
	if button == null:
		return
	button.add_theme_font_override("font", FONT_HEADER)
	button.add_theme_font_size_override("font_size", 16 if compact else 18)
	var normal: StyleBox = _make_button_style(selected, false, false, false, 8)
	var hover: StyleBox = _make_button_style(selected, true, false, false, 8)
	var pressed: StyleBox = _make_button_style(selected, false, true, false, 8)
	var disabled_style: StyleBox = _make_button_style(selected, false, false, true, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", Color(0.94, 0.91, 0.82, 1.0) if not selected else Color(0.98, 0.92, 0.66, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.90, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.97, 0.90, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.58, 0.62, 1.0))
	button.disabled = disabled

static func apply_panel_theme(panel: Control, kind: String = "frame") -> void:
	if panel == null:
		return
	var style: StyleBox
	match kind:
		"overlay":
			style = make_texture_style("large_bar", 26, 10)
		"card":
			style = make_texture_style("card_common", 28, 12)
		"selected_card":
			style = make_texture_style("selected_card", 28, 12)
		"preview_card":
			style = make_texture_style("preview_card", 28, 12)
		"ability_slot":
			style = make_texture_style("slot", 24, 8)
		"upgrade_header_bar":
			style = make_texture_style("upgrade_header_bar", 8, 4)
		"upgrade_icon_well":
			style = make_texture_style("upgrade_icon_well", 10, 8)
		"spell_level_ring":
			style = make_texture_style("spell_level_ring", 4, 6)
		"ability_orb":
			style = make_texture_style("ability_orb", 4, 6)
		"hud_xp_track":
			style = make_texture_style("hud_xp_track", 2, 2)
		"health_bar_spell":
			style = make_texture_style("health_bar_spell", 4, 6)
		"ability_pill":
			style = make_texture_style("ability_pill", 2, 4)
		"health":
			style = make_texture_style("large_bar", 26, 10)
		"bag_frame":
			style = make_texture_style("bag_frame", 8, 6)
		"bag_title_bar":
			style = make_texture_style("bag_title_bar", 4, 4)
		"bag_slot":
			style = make_texture_style("bag_slot", 2, 2)
		"bag_slot_filled":
			style = make_texture_style("bag_slot_filled", 2, 2)
		"bag_slot_selected":
			style = make_texture_style("bag_slot_selected", 2, 2)
		"bag_gold_bar":
			style = make_texture_style("bag_gold_bar", 4, 4)
		"frame":
			style = make_texture_style("large_bar", 26, 10)
		_:
			style = make_texture_style("large_bar", 26, 10)
	panel.add_theme_stylebox_override("panel", style)

static func draw_cosmic_background(target: CanvasItem, size: Vector2, time: float) -> void:
	target.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.07, 1.0), true)
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.48)
	for i in range(4):
		var radius: float = 220.0 + float(i) * 170.0 + sin(time * 0.22 + float(i)) * 16.0
		var color: Color = Color(0.10, 0.14, 0.21, 0.08 - float(i) * 0.01)
		target.draw_circle(center, radius, color)
	for i in range(24):
		var x: float = fmod(float(i * 193) + sin(time * 0.18 + float(i) * 0.7) * 40.0 + size.x, size.x)
		var y: float = fmod(float(i * 127) + cos(time * 0.12 + float(i) * 0.45) * 32.0 + size.y, size.y)
		var r: float = 1.2 + float(i % 3)
		var alpha: float = 0.22 + float(i % 5) * 0.07
		var color: Color = Color(0.42, 0.74, 0.84, alpha)
		if i % 4 == 0:
			color = Color(0.76, 0.88, 0.95, alpha + 0.08)
		target.draw_circle(Vector2(x, y), r, color)
	var vignette_color: Color = Color(0.0, 0.0, 0.0, 0.18)
	target.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 120.0)), vignette_color, true)
	target.draw_rect(Rect2(Vector2.ZERO, Vector2(120.0, size.y)), vignette_color, true)
	target.draw_rect(Rect2(Vector2(size.x - 120.0, 0.0), Vector2(120.0, size.y)), vignette_color, true)
	target.draw_rect(Rect2(Vector2(0.0, size.y - 120.0), Vector2(size.x, 120.0)), vignette_color, true)
