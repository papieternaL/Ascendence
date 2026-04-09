extends Control

const BitmapFontLibrary = preload("res://scripts/ui/bitmap_font_library.gd")
const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

@export var damage_preview_text: String = "128!"
@export var level_up_text: String = "LEVEL UP"
@export var upgrade_title_text: String = "RICOCHET ARROW"
@export var crit_preview: bool = true

@onready var damage_preview: Label = $Margin/VBox/DamagePreview
@onready var level_up_preview: Label = $Margin/VBox/LevelUpPreview
@onready var upgrade_title_preview: Label = $Margin/VBox/UpgradeTitlePreview
@onready var note_label: Label = $Margin/VBox/Note

var _bg_time: float = 0.0

func _ready() -> void:
	damage_preview.text = damage_preview_text
	damage_preview.label_settings = BitmapFontLibrary.make_damage_label_settings(crit_preview)
	damage_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	level_up_preview.text = level_up_text
	BitmapFontLibrary.apply_short_label(level_up_preview, "level_up")
	level_up_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	upgrade_title_preview.text = upgrade_title_text
	BitmapFontLibrary.apply_short_label(upgrade_title_preview, "upgrade_title")
	upgrade_title_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	note_label.text = "If this still looks like the fallback font, switch the PNG import to Font Data (Monospace Image Font)."
	FrontendStyle.apply_small(note_label, 13, Color(0.86, 0.88, 0.92, 1.0))
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	queue_redraw()

func _process(delta: float) -> void:
	_bg_time += delta
	queue_redraw()

func _draw() -> void:
	FrontendStyle.draw_cosmic_background(self, size, _bg_time)
