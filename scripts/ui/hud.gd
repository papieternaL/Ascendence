extends Control

const ICON_GLYPH_SCENE: PackedScene = preload("res://scenes/ui/IconGlyph.tscn")
const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const TOWN_POTION_ICON_PATH: String = "res://art/hub/hub_hp_potion.png"
const HUD_RENDER_SCALE_MULT: float = 1.75
const HUD_BASE_BOTTOM_HEIGHT: float = 128.0
const HUD_BASE_LEVEL_BADGE_SIZE: Vector2 = Vector2(68.0, 68.0)
const HUD_BASE_ORB_SIZE: float = 68.0
const HUD_BASE_ORB_MARGIN: float = 2.0
const HUD_BASE_HEALTH_SIZE: Vector2 = Vector2(380.0, 22.0)
const HUD_BASE_XP_HEIGHT: float = 4.0
const HUD_BASE_TIMER_FONT: int = 12
const HUD_BASE_OBJECTIVE_FONT: int = 13
const HUD_BASE_BOSS_FONT: int = 12
const HUD_BASE_HEALTH_FONT: int = 12
const HUD_BASE_LEVEL_FONT: int = 22
const HUD_BASE_ABILITY_ICON_SIZE: float = 58.0
const HUD_BASE_TOOLTIP_TITLE_FONT: int = 14
const HUD_BASE_TOOLTIP_BODY_FONT: int = 12
const HUD_BASE_TOOLTIP_STATE_FONT: int = 12

@onready var timer_panel: PanelContainer = $TopLeft/LeftColumn/TimerPanel
@onready var top_left_root: Control = $TopLeft
@onready var timer_label: Label = $TopLeft/LeftColumn/TimerPanel/Margin/TimerLabel
@onready var objective_hud_panel: PanelContainer = $TopLeft/LeftColumn/ObjectiveHudPanel
@onready var objective_hud_title: Label = $TopLeft/LeftColumn/ObjectiveHudPanel/Margin/ObjStack/ObjTitle
@onready var objective_hud_progress: Label = $TopLeft/LeftColumn/ObjectiveHudPanel/Margin/ObjStack/ObjProgress
@onready var objective_hud_timer: Label = $TopLeft/LeftColumn/ObjectiveHudPanel/Margin/ObjStack/ObjTimer
@onready var menu_button: Button = $TopRight/MenuButton
@onready var top_right_root: Control = $TopRight
@onready var top_center_root: Control = $TopCenter
@onready var center_overlay: CenterContainer = $CenterOverlay
@onready var overlay_stack: VBoxContainer = $CenterOverlay/OverlayStack
@onready var pause_panel: PanelContainer = $CenterOverlay/OverlayStack/PausePanel
@onready var pause_vbox: VBoxContainer = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox
@onready var resume_button: Button = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox/ResumeButton
@onready var profile_button: Button = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox/ProfileButton
@onready var menu_return_button: Button = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox/MenuButton
@onready var profile_panel: PanelContainer = $CenterOverlay/OverlayStack/ProfilePanel
@onready var profile_title_label: Label = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Title
@onready var profile_subtitle_label: Label = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Subtitle
@onready var profile_summary_label: Label = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Columns/SummaryPanel/Margin/SummaryText
@onready var profile_stats_label: Label = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Columns/StatsPanel/Margin/StatsText
@onready var profile_upgrades_label: Label = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Columns/UpgradesPanel/Margin/UpgradesText
@onready var profile_back_button: Button = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Buttons/BackButton
@onready var profile_resume_button: Button = $CenterOverlay/OverlayStack/ProfilePanel/Margin/ProfileStack/Buttons/ResumeButton
@onready var objective_panel: PanelContainer = $TopCenter/ObjectivePanel
@onready var objective_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveLabel
@onready var objective_bar: ProgressBar = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveBar
@onready var boss_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/BossLabel
@onready var primary_slot_panel: PanelContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/PrimarySlot/OrbPanel
@onready var primary_orb_center: CenterContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/PrimarySlot/OrbPanel/Margin/Center
@onready var primary_pill_label: Label = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/PrimarySlot/PillPanel/PillLabel
var ability_one_slot_panel: PanelContainer
var ability_one_orb_center: CenterContainer
var ability_one_pill_label: Label
@onready var dash_slot_panel: PanelContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/DashSlot/OrbPanel
@onready var dash_orb_center: CenterContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/DashSlot/OrbPanel/Margin/Center
@onready var dash_pill_label: Label = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/DashSlot/PillPanel/PillLabel
@onready var ability_two_slot_panel: PanelContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/MissilesSlot/OrbPanel
@onready var ability_two_orb_center: CenterContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/MissilesSlot/OrbPanel/Margin/Center
@onready var ability_two_pill_label: Label = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/MissilesSlot/PillPanel/PillLabel
@onready var ultimate_slot_panel: PanelContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/SniperSlot/OrbPanel
@onready var ultimate_orb_center: CenterContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/SniperSlot/OrbPanel/Margin/Center
@onready var ultimate_pill_label: Label = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/SniperSlot/PillPanel/PillLabel
@onready var health_bar: ProgressBar = $BottomHud/MainColumn/TopRow/CenterBlock/HealthHost/HealthBar
@onready var health_text: Label = $BottomHud/MainColumn/TopRow/CenterBlock/HealthHost/HealthText
@onready var level_badge_panel: PanelContainer = $BottomHud/MainColumn/TopRow/LevelBadge
@onready var level_badge: Label = $BottomHud/MainColumn/TopRow/LevelBadge/LevelLabel
@onready var xp_bar: ProgressBar = $BottomHud/MainColumn/XpBar
@onready var bottom_hud_root: Control = $BottomHud
@onready var bottom_main_column: VBoxContainer = $BottomHud/MainColumn
@onready var bottom_top_row: HBoxContainer = $BottomHud/MainColumn/TopRow
@onready var center_block: VBoxContainer = $BottomHud/MainColumn/TopRow/CenterBlock
@onready var ability_row: HBoxContainer = $BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow
@onready var health_host: Control = $BottomHud/MainColumn/TopRow/CenterBlock/HealthHost
@onready var upgrade_panel: PanelContainer = $CenterOverlay/OverlayStack/UpgradePanel
@onready var upgrade_title_label: Label = $CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/Title
@onready var upgrade_subtitle_label: Label = $CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/Subtitle
@onready var upgrade_cards: Array[PanelContainer] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2,
]
@onready var upgrade_card_stacks: Array[VBoxContainer] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack,
]
@onready var upgrade_card_titles: Array[Label] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack/HeaderBar/Margin/Name,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack/HeaderBar/Margin/Name,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack/HeaderBar/Margin/Name,
]
@onready var upgrade_card_descs: Array[Label] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack/Description,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack/Description,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack/Description,
]
@onready var upgrade_card_icon_centers: Array[CenterContainer] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack/IconWell/Margin/Center,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack/IconWell/Margin/Center,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack/IconWell/Margin/Center,
]
@onready var upgrade_cards_row: HBoxContainer = $CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow
@onready var game_over_panel: PanelContainer = $CenterOverlay/OverlayStack/GameOverPanel
@onready var game_over_label: Label = $CenterOverlay/OverlayStack/GameOverPanel/Margin/GameOverLabel
@onready var ability_tooltip: PanelContainer = $AbilityTooltip
@onready var ability_tooltip_title: Label = $AbilityTooltip/Margin/Stack/Title
@onready var ability_tooltip_body: Label = $AbilityTooltip/Margin/Stack/Body
@onready var ability_tooltip_state: Label = $AbilityTooltip/Margin/Stack/State

var _player: Node
var _cooldown_system: Node
var _game: Node
var _primary_key: StringName
var _ability_one_key: StringName
var _dash_key: StringName
var _ability_two_key: StringName
var _ultimate_key: StringName
var _slot_icons: Dictionary = {}
var _slot_timer_labels: Dictionary = {}
## Each entry: IconGlyph in the card icon well, preferring SpriteCook textures with procedural fallback.
var _objective_markers: Array[Label] = []
var _objective_fill_threshold: StyleBoxFlat
var _objective_fill_boss: StyleBoxFlat
var _upgrade_card_style_cache: Dictionary = {}
var _last_upgrade_panel_visible: bool = false
var _last_upgrade_selected_index: int = -999
var _last_upgrade_title: String = ""
var _last_upgrade_subtitle: String = ""
var _last_upgrade_signature: String = ""
var _last_upgrade_version: int = -1
var _last_objective_callout_visible: bool = false
var _last_objective_callout_signature: String = ""
var _last_profile_signature: String = ""
var _last_profile_visible: bool = false
var _upgrade_card_tags: Array[Label] = []
var _upgrade_card_header_bars: Array[PanelContainer] = []
var _upgrade_card_icons: Array[Control] = []
var _upgrade_card_gradient_overlays: Array[TextureRect] = []
var _upgrade_backdrop: ColorRect
var _upgrade_card_pulse_tweens: Array = []
var _upgrade_intro_tween: Tween
var _pause_settings_button: Button
var _settings_panel: PanelContainer
var _settings_content: SettingsPanel
var _settings_title: Label
var _settings_display_mode_button: Button
var _settings_resolution_label: Label
var _settings_brightness_label: Label
var _settings_brightness_slider: HSlider
var _settings_master_volume_label: Label
var _settings_master_volume_slider: HSlider
var _settings_music_volume_label: Label
var _settings_music_volume_slider: HSlider
var _settings_sfx_volume_label: Label
var _settings_sfx_volume_slider: HSlider
var _settings_hud_scale_label: Label
var _settings_hud_scale_slider: HSlider
var _settings_screen_shake_label: Label
var _settings_screen_shake_slider: HSlider
var _settings_vsync_check: CheckButton
var _settings_reduced_flashes_check: CheckButton
var _settings_show_fps_check: CheckButton
var _settings_show_damage_numbers_check: CheckButton
var _settings_close_button: Button
var _settings_syncing: bool = false
var _quest_tab_panel: PanelContainer
var _quest_tab_title: Label
var _quest_tab_status: Label
var _quest_tab_body: Label
var _inventory_panel: PanelContainer
var _inventory_title_label: Label
var _inventory_gold_label: Label
var _inventory_hint_label: Label
var _inventory_slot_grid: GridContainer
var _inventory_slots: Array[PanelContainer] = []
var _inventory_slot_icons: Array[TextureRect] = []
var _inventory_slot_counts: Array[Label] = []
const BAG_COLS: int = 4
const BAG_ROWS: int = 4
const BAG_SLOT_SIZE: float = 56.0
const HOTBAR_SLOT_SIZE: float = 52.0
var _quest_signature: String = ""
var _inventory_signature: String = ""
var _hotbar_row: HBoxContainer
var _hotbar_slots: Array[PanelContainer] = []
var _hotbar_icons: Array[TextureRect] = []
var _hotbar_counts: Array[Label] = []
var _hotbar_key_labels: Array[Label] = []
var _inventory_slot_item_ids: Array[String] = []
var _hotbar_slot_item_ids: Array[String] = []
var _selected_item_slot_kind: String = ""
var _selected_item_slot_index: int = -1
var _hotbar_signature: String = ""

func _ready() -> void:
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	objective_bar.max_value = 1.0
	objective_bar.value = 0.0
	xp_bar.max_value = 1.0
	xp_bar.value = 0.0
	_create_upgrade_overlay_backdrop()
	_augment_upgrade_card_layout()
	_create_upgrade_card_icons()
	_build_pause_settings_button()
	_build_settings_panel()
	_build_quest_tab()
	_build_inventory_panel()
	_build_ability_one_slot()
	_build_hotbar_row()
	_apply_theme()
	_create_objective_markers()
	_create_slot_icons()
	_wire_ui_hover_sfx()
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	profile_button.pressed.connect(_on_profile_button_pressed)
	menu_return_button.pressed.connect(_on_return_to_menu_pressed)
	profile_back_button.pressed.connect(_on_profile_back_button_pressed)
	profile_resume_button.pressed.connect(_on_resume_button_pressed)
	for i in range(upgrade_cards.size()):
		upgrade_cards[i].mouse_filter = Control.MOUSE_FILTER_STOP
		upgrade_cards[i].gui_input.connect(Callable(self, "_on_upgrade_card_input").bind(i))
		upgrade_cards[i].mouse_entered.connect(Callable(self, "_on_upgrade_card_mouse_entered").bind(i))
	_wire_ability_tooltips()
	if GameSettings != null and not GameSettings.settings_changed.is_connected(_on_game_settings_changed):
		GameSettings.settings_changed.connect(_on_game_settings_changed)
	_sync_settings_controls_from_globals()
	get_viewport().size_changed.connect(_on_hud_viewport_size_changed)
	call_deferred("_apply_hud_scale")

func _wire_ui_hover_sfx() -> void:
	for control in [
		menu_button,
		resume_button,
		profile_button,
		menu_return_button,
		profile_back_button,
		profile_resume_button,
		_pause_settings_button,
		_settings_display_mode_button,
		_settings_vsync_check,
		_settings_reduced_flashes_check,
		_settings_show_fps_check,
		_settings_show_damage_numbers_check,
		_settings_close_button,
	]:
		_wire_hover_sound(control)
	if _settings_content != null and not _settings_content.hover_sfx_requested.is_connected(_play_ui_hover):
		_settings_content.hover_sfx_requested.connect(_play_ui_hover)

func _wire_hover_sound(control: Control) -> void:
	if control == null:
		return
	var hover_callback: Callable = Callable(self, "_play_ui_hover")
	if not control.mouse_entered.is_connected(hover_callback):
		control.mouse_entered.connect(hover_callback)

func _play_ui_hover() -> void:
	AudioDirector.play_ui("ui_hover", -4.0)

func _exit_tree() -> void:
	if GameSettings != null and GameSettings.settings_changed.is_connected(_on_game_settings_changed):
		GameSettings.settings_changed.disconnect(_on_game_settings_changed)

func _create_upgrade_overlay_backdrop() -> void:
	_upgrade_backdrop = ColorRect.new()
	_upgrade_backdrop.name = "UpgradeBackdrop"
	_upgrade_backdrop.layout_mode = 1
	_upgrade_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_upgrade_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_backdrop.color = Color(0.01, 0.02, 0.05, 0.0)
	_upgrade_backdrop.visible = false
	add_child(_upgrade_backdrop)
	move_child(_upgrade_backdrop, 0)

func _build_pause_settings_button() -> void:
	if pause_vbox == null or _pause_settings_button != null:
		return
	_pause_settings_button = Button.new()
	_pause_settings_button.name = "SettingsButton"
	_pause_settings_button.custom_minimum_size = Vector2(0.0, 46.0)
	_pause_settings_button.text = "Settings"
	_pause_settings_button.pressed.connect(_on_settings_button_pressed)
	pause_vbox.add_child(_pause_settings_button)
	var menu_index: int = menu_return_button.get_index() if menu_return_button != null else pause_vbox.get_child_count() - 1
	pause_vbox.move_child(_pause_settings_button, menu_index)

func _build_settings_panel() -> void:
	if overlay_stack == null or _settings_panel != null:
		return
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.visible = false
	_settings_panel.custom_minimum_size = Vector2(720.0, 840.0)
	overlay_stack.add_child(_settings_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	_settings_panel.add_child(margin)
	_settings_content = SettingsPanel.new()
	_settings_content.close_requested.connect(_on_settings_close_pressed)
	_settings_content.hover_sfx_requested.connect(_play_ui_hover)
	margin.add_child(_settings_content)

func _build_quest_tab() -> void:
	if top_right_root == null or _quest_tab_panel != null:
		return
	top_right_root.offset_left = -320.0
	top_right_root.offset_top = 10.0
	top_right_root.offset_right = -14.0
	top_right_root.offset_bottom = 102.0
	_quest_tab_panel = PanelContainer.new()
	_quest_tab_panel.name = "QuestTab"
	_quest_tab_panel.custom_minimum_size = Vector2(306.0, 86.0)
	top_right_root.add_child(_quest_tab_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_quest_tab_panel.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	_quest_tab_title = Label.new()
	_quest_tab_title.text = "QUEST IN PROGRESS"
	stack.add_child(_quest_tab_title)
	_quest_tab_status = Label.new()
	stack.add_child(_quest_tab_status)
	_quest_tab_body = Label.new()
	_quest_tab_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_quest_tab_body)

func _build_inventory_panel() -> void:
	if overlay_stack == null or _inventory_panel != null:
		return
	# --- WoW-style bag frame ---
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.visible = false
	var bag_width: float = BAG_COLS * (BAG_SLOT_SIZE + 4.0) + 28.0
	_inventory_panel.custom_minimum_size = Vector2(bag_width, 0.0)
	overlay_stack.add_child(_inventory_panel)
	FrontendStyle.apply_panel_theme(_inventory_panel, "bag_frame")

	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 10)
	outer_margin.add_theme_constant_override("margin_top", 8)
	outer_margin.add_theme_constant_override("margin_right", 10)
	outer_margin.add_theme_constant_override("margin_bottom", 10)
	_inventory_panel.add_child(outer_margin)

	var bag_vbox: VBoxContainer = VBoxContainer.new()
	bag_vbox.add_theme_constant_override("separation", 6)
	outer_margin.add_child(bag_vbox)

	# Title bar
	var title_bar: PanelContainer = PanelContainer.new()
	title_bar.custom_minimum_size = Vector2(0.0, 28.0)
	bag_vbox.add_child(title_bar)
	FrontendStyle.apply_panel_theme(title_bar, "bag_title_bar")
	_inventory_title_label = Label.new()
	_inventory_title_label.text = "Bag"
	_inventory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inventory_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	FrontendStyle.apply_header(_inventory_title_label, 16, Color(0.82, 0.72, 0.48, 1.0))
	title_bar.add_child(_inventory_title_label)

	# Slot grid
	_inventory_slot_grid = GridContainer.new()
	_inventory_slot_grid.columns = BAG_COLS
	_inventory_slot_grid.add_theme_constant_override("h_separation", 4)
	_inventory_slot_grid.add_theme_constant_override("v_separation", 4)
	bag_vbox.add_child(_inventory_slot_grid)

	_inventory_slots.clear()
	_inventory_slot_icons.clear()
	_inventory_slot_counts.clear()
	_inventory_slot_item_ids.clear()
	for i in range(BAG_COLS * BAG_ROWS):
		var slot: PanelContainer = PanelContainer.new()
		slot.custom_minimum_size = Vector2(BAG_SLOT_SIZE, BAG_SLOT_SIZE)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(Callable(self, "_on_inventory_slot_gui_input").bind(i))
		FrontendStyle.apply_panel_theme(slot, "bag_slot")
		_inventory_slot_grid.add_child(slot)
		_inventory_slots.append(slot)
		_inventory_slot_item_ids.append("")
		var slot_icon: TextureRect = TextureRect.new()
		slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(slot_icon)
		_inventory_slot_icons.append(slot_icon)
		var count_label: Label = Label.new()
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		FrontendStyle.apply_body(count_label, 12, Color(1.0, 1.0, 1.0, 1.0))
		count_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.visible = false
		slot.add_child(count_label)
		_inventory_slot_counts.append(count_label)

	# Gold bar (bottom)
	var gold_bar: PanelContainer = PanelContainer.new()
	gold_bar.custom_minimum_size = Vector2(0.0, 26.0)
	bag_vbox.add_child(gold_bar)
	FrontendStyle.apply_panel_theme(gold_bar, "bag_gold_bar")
	var gold_margin: MarginContainer = MarginContainer.new()
	gold_margin.add_theme_constant_override("margin_left", 6)
	gold_margin.add_theme_constant_override("margin_right", 6)
	gold_bar.add_child(gold_margin)
	_inventory_gold_label = Label.new()
	_inventory_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inventory_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	FrontendStyle.apply_body(_inventory_gold_label, 13, Color(0.92, 0.82, 0.42, 1.0))
	gold_margin.add_child(_inventory_gold_label)

	# Hint
	_inventory_hint_label = Label.new()
	_inventory_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FrontendStyle.apply_small(_inventory_hint_label, 11, Color(0.56, 0.52, 0.42, 0.8))
	bag_vbox.add_child(_inventory_hint_label)

func _build_hotbar_row() -> void:
	if center_block == null or _hotbar_row != null:
		return
	_hotbar_row = HBoxContainer.new()
	_hotbar_row.name = "HotbarRow"
	_hotbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar_row.add_theme_constant_override("separation", 4)
	center_block.add_child(_hotbar_row)
	center_block.move_child(_hotbar_row, 0)

	_hotbar_slots.clear()
	_hotbar_icons.clear()
	_hotbar_counts.clear()
	_hotbar_key_labels.clear()
	_hotbar_slot_item_ids.clear()
	for i in range(4):
		var slot_vbox: VBoxContainer = VBoxContainer.new()
		slot_vbox.add_theme_constant_override("separation", 1)
		_hotbar_row.add_child(slot_vbox)
		var slot: PanelContainer = PanelContainer.new()
		slot.custom_minimum_size = Vector2(HOTBAR_SLOT_SIZE, HOTBAR_SLOT_SIZE)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(Callable(self, "_on_hotbar_slot_gui_input").bind(i))
		FrontendStyle.apply_panel_theme(slot, "bag_slot")
		slot_vbox.add_child(slot)
		_hotbar_slots.append(slot)
		_hotbar_slot_item_ids.append("")
		var icon: TextureRect = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		_hotbar_icons.append(icon)
		var count_label: Label = Label.new()
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		FrontendStyle.apply_body(count_label, 10, Color(1.0, 1.0, 1.0, 1.0))
		count_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		count_label.add_theme_constant_override("outline_size", 2)
		count_label.visible = false
		slot.add_child(count_label)
		_hotbar_counts.append(count_label)
		var key_label: Label = Label.new()
		key_label.text = str(i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FrontendStyle.apply_small(key_label, 9, Color(0.62, 0.58, 0.48, 0.8))
		slot_vbox.add_child(key_label)
		_hotbar_key_labels.append(key_label)

func _build_ability_one_slot() -> void:
	if ability_row == null or ability_one_slot_panel != null:
		return
	var slot_root: VBoxContainer = VBoxContainer.new()
	slot_root.name = "AbilityOneSlot"
	slot_root.add_theme_constant_override("separation", 4)
	var orb_panel: PanelContainer = PanelContainer.new()
	orb_panel.name = "OrbPanel"
	orb_panel.custom_minimum_size = Vector2(68.0, 68.0)
	slot_root.add_child(orb_panel)
	var orb_margin: MarginContainer = MarginContainer.new()
	orb_margin.name = "Margin"
	orb_margin.add_theme_constant_override("margin_left", 4)
	orb_margin.add_theme_constant_override("margin_top", 4)
	orb_margin.add_theme_constant_override("margin_right", 4)
	orb_margin.add_theme_constant_override("margin_bottom", 4)
	orb_panel.add_child(orb_margin)
	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	orb_margin.add_child(center)
	var pill_panel: PanelContainer = PanelContainer.new()
	pill_panel.name = "PillPanel"
	pill_panel.custom_minimum_size = Vector2(44.0, 20.0)
	pill_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_root.add_child(pill_panel)
	var pill_label: Label = Label.new()
	pill_label.name = "PillLabel"
	pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_panel.add_child(pill_label)
	ability_row.add_child(slot_root)
	ability_row.move_child(slot_root, 1)
	ability_row.move_child(ability_two_slot_panel.get_parent(), 2)
	ability_row.move_child(dash_slot_panel.get_parent(), 3)
	ability_row.move_child(ultimate_slot_panel.get_parent(), 4)
	ability_one_slot_panel = orb_panel
	ability_one_orb_center = center
	ability_one_pill_label = pill_label

func _augment_upgrade_card_layout() -> void:
	_upgrade_card_tags.clear()
	_upgrade_card_header_bars.clear()
	_upgrade_card_gradient_overlays.clear()
	for i in range(upgrade_card_stacks.size()):
		var stack: VBoxContainer = upgrade_card_stacks[i]
		stack.add_theme_constant_override("separation", 8)
		var header_bar: PanelContainer = stack.get_node_or_null("HeaderBar") as PanelContainer
		_upgrade_card_header_bars.append(header_bar)
		if i < upgrade_cards.size():
			_upgrade_card_gradient_overlays.append(_ensure_upgrade_card_gradient_overlay(upgrade_cards[i]))
		var tag_label: Label = Label.new()
		tag_label.name = "CardFooter"
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(tag_label)
		_upgrade_card_tags.append(tag_label)
		if i < upgrade_card_descs.size():
			upgrade_card_descs[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			upgrade_card_descs[i].vertical_alignment = VERTICAL_ALIGNMENT_TOP
			upgrade_card_descs[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		if header_bar != null:
			header_bar.custom_minimum_size = Vector2(0.0, 26.0)
		var icon_well: PanelContainer = stack.get_node_or_null("IconWell") as PanelContainer
		if icon_well != null:
			icon_well.custom_minimum_size = Vector2(0.0, 128.0)
			var icon_margin: MarginContainer = icon_well.get_node_or_null("Margin") as MarginContainer
			if icon_margin != null:
				icon_margin.add_theme_constant_override("margin_left", 8)
				icon_margin.add_theme_constant_override("margin_top", 8)
				icon_margin.add_theme_constant_override("margin_right", 8)
				icon_margin.add_theme_constant_override("margin_bottom", 8)

func _create_upgrade_card_icons() -> void:
	_upgrade_card_icons.clear()
	for center in upgrade_card_icon_centers:
		_upgrade_card_icons.append(_create_icon_in_center(center, 102.0))

func _ensure_upgrade_card_gradient_overlay(card: PanelContainer) -> TextureRect:
	if card == null:
		return null
	var overlay: TextureRect = card.get_node_or_null("GradientOverlay") as TextureRect
	if overlay == null:
		overlay = TextureRect.new()
		overlay.name = "GradientOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		overlay.stretch_mode = TextureRect.STRETCH_SCALE
		overlay.layout_mode = 1
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(overlay)
		card.move_child(overlay, 0)
	return overlay

func _update_upgrade_card_gradient(index: int, rarity: String, selected: bool) -> void:
	if index < 0 or index >= _upgrade_card_gradient_overlays.size():
		return
	var overlay: TextureRect = _upgrade_card_gradient_overlays[index]
	if overlay == null:
		return
	var accent: Color = _gradient_overlay_color(rarity, selected)
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(accent.r, accent.g, accent.b, 0.0),
		Color(accent.r, accent.g, accent.b, 0.02),
		Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.16),
		Color(accent.r, accent.g, accent.b, 0.34 if not selected else 0.42),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 0.76, 1.0])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 256
	overlay.texture = texture
	overlay.modulate = Color.WHITE

func _gradient_overlay_color(rarity: String, selected: bool) -> Color:
	var color: Color
	match rarity:
		"common":
			color = Color(0.22, 0.78, 0.34, 1.0)
		"rare":
			color = Color(0.18, 0.56, 0.98, 1.0)
		"epic":
			color = Color(0.56, 0.26, 0.92, 1.0)
		_:
			color = Color(0.42, 0.50, 0.66, 1.0)
	return color.lightened(0.08) if selected else color

func bind_player(player: Node) -> void:
	_player = player
	var max_hp: float = float(player.get("max_health"))
	if max_hp > 0.0:
		health_bar.max_value = max_hp

func bind_cooldown_system(cooldown_system: Node, primary_key: StringName, ability_one_key: StringName, ability_two_key: StringName, dash_key: StringName, ultimate_key: StringName) -> void:
	_cooldown_system = cooldown_system
	_primary_key = primary_key
	_ability_one_key = ability_one_key
	_ability_two_key = ability_two_key
	_dash_key = dash_key
	_ultimate_key = ultimate_key

func bind_game(game: Node) -> void:
	_game = game

func is_settings_panel_open() -> bool:
	return _is_settings_panel_visible()

func _unhandled_input(event: InputEvent) -> void:
	if _is_settings_panel_visible():
		if event.is_action_pressed("ui_cancel") and (_settings_content == null or not _settings_content.is_capturing_binding()):
			_close_settings_panel()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and _can_toggle_hub_pause_from_keyboard():
		if _game != null and _game.has_method("request_toggle_pause"):
			_game.request_toggle_pause()
		get_viewport().set_input_as_handled()

func _on_game_settings_changed() -> void:
	_sync_settings_controls_from_globals()
	_apply_theme()
	_apply_hud_scale()
	_inventory_signature = ""
	_quest_signature = ""
	_hotbar_signature = ""
	_update_inventory_panel()
	_update_hotbar()
	_update_quest_tab()

func _on_hud_viewport_size_changed() -> void:
	call_deferred("_apply_hud_scale")

func _current_hud_scale() -> float:
	var base_scale: float = GameSettings.hud_scale if GameSettings != null else 0.85
	return base_scale * HUD_RENDER_SCALE_MULT

func _is_settings_panel_visible() -> bool:
	return _settings_panel != null and _settings_panel.visible

func _is_inventory_panel_visible() -> bool:
	return _inventory_panel != null and _inventory_panel.visible

func _runtime_flag_true(property_name: String) -> bool:
	return bool(_game.get(property_name)) if _runtime_has_property(property_name) else false

func _can_toggle_hub_pause_from_keyboard() -> bool:
	if not _is_hub_mode():
		return false
	if _is_inventory_panel_visible() or upgrade_panel.visible or game_over_panel.visible:
		return false
	if profile_panel.visible:
		return false
	if _game != null and _game.has_method("is_input_blocked") and bool(_game.call("is_input_blocked")):
		var manual_pause_active: bool = _game.has_method("is_manual_pause_active") and bool(_game.call("is_manual_pause_active"))
		if not manual_pause_active:
			return false
	return true

func _sync_settings_controls_from_globals() -> void:
	if _settings_content == null:
		return
	_settings_content.refresh_from_settings()

func _update_settings_panel_labels() -> void:
	if _settings_content == null:
		return
	_settings_content.refresh_from_settings()

func _open_settings_panel() -> void:
	if _settings_panel == null:
		return
	_sync_settings_controls_from_globals()
	_settings_panel.visible = true
	pause_panel.visible = false
	profile_panel.visible = false
	if _is_hub_mode() and _game != null and _game.has_method("set_input_blocked"):
		_game.set_input_blocked(true)
	if _settings_content != null:
		_settings_content.focus_default_control()

func _close_settings_panel() -> void:
	if _settings_panel == null:
		return
	if _settings_content != null:
		_settings_content.cancel_binding_capture()
	_settings_panel.visible = false
	if GameSettings != null:
		GameSettings.save_settings()
	if _is_hub_mode() and _game != null and _game.has_method("set_input_blocked"):
		var should_keep_blocked: bool = _game.has_method("is_manual_pause_active") and bool(_game.call("is_manual_pause_active"))
		_game.set_input_blocked(should_keep_blocked)

func _apply_control_scale(control: Control, scale_value: float, pivot_ratio: Vector2) -> void:
	if control == null:
		return
	var control_size: Vector2 = control.size
	if control_size.x <= 0.0 or control_size.y <= 0.0:
		control_size = control.get_combined_minimum_size()
	control.pivot_offset = Vector2(control_size.x * pivot_ratio.x, control_size.y * pivot_ratio.y)
	control.scale = Vector2(scale_value, scale_value)

func _apply_hud_scale() -> void:
	var hud_scale: float = _current_hud_scale()
	_apply_control_scale(top_left_root, hud_scale, Vector2.ZERO)
	_apply_control_scale(top_center_root, hud_scale, Vector2(0.5, 0.0))
	_apply_control_scale(top_right_root, hud_scale, Vector2(1.0, 0.0))
	_apply_control_scale(ability_tooltip, hud_scale, Vector2(0.5, 1.0))
	bottom_hud_root.offset_top = -HUD_BASE_BOTTOM_HEIGHT * hud_scale
	bottom_main_column.add_theme_constant_override("separation", int(round(3.0 * hud_scale)))
	bottom_top_row.add_theme_constant_override("separation", int(round(8.0 * hud_scale)))
	center_block.add_theme_constant_override("separation", int(round(4.0 * hud_scale)))
	ability_row.add_theme_constant_override("separation", int(round(8.0 * hud_scale)))
	level_badge_panel.custom_minimum_size = HUD_BASE_LEVEL_BADGE_SIZE * hud_scale
	for orb_panel in [primary_slot_panel, ability_one_slot_panel, ability_two_slot_panel, dash_slot_panel, ultimate_slot_panel]:
		if orb_panel == null:
			continue
		orb_panel.custom_minimum_size = Vector2.ONE * HUD_BASE_ORB_SIZE * hud_scale
		var orb_margin: MarginContainer = orb_panel.get_node_or_null("Margin") as MarginContainer
		if orb_margin != null:
			var margin_value: int = int(round(HUD_BASE_ORB_MARGIN * hud_scale))
			orb_margin.add_theme_constant_override("margin_left", margin_value)
			orb_margin.add_theme_constant_override("margin_top", margin_value)
			orb_margin.add_theme_constant_override("margin_right", margin_value)
			orb_margin.add_theme_constant_override("margin_bottom", margin_value)
	health_host.custom_minimum_size = HUD_BASE_HEALTH_SIZE * hud_scale
	xp_bar.custom_minimum_size = Vector2(0.0, maxf(4.0, round(HUD_BASE_XP_HEIGHT * hud_scale)))
	for icon in _slot_icons.values():
		if icon is Control:
			(icon as Control).custom_minimum_size = Vector2.ONE * HUD_BASE_ABILITY_ICON_SIZE * hud_scale
	if _hotbar_row != null:
		_hotbar_row.add_theme_constant_override("separation", int(round(6.0 * hud_scale)))
	for slot in _hotbar_slots:
		slot.custom_minimum_size = Vector2.ONE * HOTBAR_SLOT_SIZE * hud_scale
	for label in _hotbar_key_labels:
		FrontendStyle.apply_small(label, max(10, int(round(10.0 * hud_scale))), Color(0.68, 0.62, 0.50, 0.9))

func _process(_delta: float) -> void:
	if upgrade_panel.visible:
		return
	_update_health()
	_update_status()

func _update_health() -> void:
	if _player == null:
		return
	var value: Variant = _player.get("health")
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		health_bar.value = float(value)
		health_text.text = "%d / %d" % [int(round(float(value))), int(round(health_bar.max_value))]

func _update_status() -> void:
	if _game == null:
		return
	var is_paused: bool = bool(_game.get("_manual_pause")) if _runtime_has_property("_manual_pause") else false
	var profile_open: bool = bool(_game.get("_profile_overlay_open")) if _runtime_has_property("_profile_overlay_open") else false
	var inventory_open: bool = _runtime_flag_true("_inventory_overlay_open")
	var overlay_active: bool = upgrade_panel.visible
	var settings_open: bool = _is_settings_panel_visible()
	var hub_mode: bool = _is_hub_mode()
	var game_over_text: String = _get_runtime_string(["game_over_prompt"], "")
	var hub_input_blocked: bool = _game != null and _game.has_method("is_input_blocked") and bool(_game.call("is_input_blocked"))
	var quest_tab_blocked: bool = overlay_active or settings_open or inventory_open or is_paused or profile_open or not game_over_text.is_empty() or (hub_mode and hub_input_blocked)
	profile_button.visible = not hub_mode and _game != null and _game.has_method("request_open_profile")
	pause_panel.visible = is_paused and not profile_open and not inventory_open and not overlay_active and not settings_open
	profile_panel.visible = profile_open and not overlay_active and not settings_open
	var show_inventory_panel: bool = inventory_open and not overlay_active and not settings_open and not game_over_panel.visible
	if _inventory_panel != null:
		_inventory_panel.visible = show_inventory_panel
	if not show_inventory_panel:
		_clear_item_slot_selection(false)
	menu_button.visible = false
	if top_left_root != null:
		top_left_root.visible = not hub_mode and not overlay_active and not settings_open and not inventory_open
	if top_center_root != null:
		top_center_root.visible = not hub_mode and not overlay_active and not settings_open and not inventory_open
	if top_right_root != null:
		top_right_root.visible = not quest_tab_blocked
	if overlay_active:
		if objective_hud_panel != null:
			objective_hud_panel.visible = false
		return
	var run_time_value: float = _get_runtime_float(["run_time"], 0.0)
	timer_label.text = _format_time(run_time_value)
	objective_bar.value = _get_runtime_float(["progress_panel_value", "objective_progress"], 0.0)
	objective_label.text = _get_runtime_string(["progress_panel_title", "objective_state_label"], "Forest Assault")
	boss_label.text = _get_runtime_string(["progress_panel_detail", "boss_status_label"], "")
	_update_progress_bar_presentation()
	xp_bar.value = _get_runtime_float(["xp_percent"], 0.0)
	level_badge.text = str(int(round(_get_runtime_float(["current_level"], 1.0))))
	if _player != null:
		var max_hp_value: float = float(_player.get("max_health"))
		if max_hp_value > 0.0:
			health_bar.max_value = max_hp_value
	_update_slot_labels()
	game_over_panel.visible = not game_over_text.is_empty()
	game_over_label.text = game_over_text
	_update_objective_hud_callout()
	_update_profile_panel()
	_update_inventory_panel()
	_update_hotbar()
	_update_quest_tab()

func refresh_upgrade_overlay() -> void:
	_update_upgrade_cards()

func _update_objective_hud_callout() -> void:
	if _game == null or objective_hud_panel == null:
		return
	var vis: bool = bool(_game.get("objective_hud_visible")) if _runtime_has_property("objective_hud_visible") else false
	if vis != _last_objective_callout_visible:
		_last_objective_callout_visible = vis
		objective_hud_panel.visible = vis
		if vis:
			objective_hud_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tween: Tween = create_tween()
			tween.tween_property(objective_hud_panel, "modulate", Color.WHITE, 0.18)
		else:
			_last_objective_callout_signature = ""
	if not vis:
		return
	var signature: String = "%s|%s|%s" % [
		str(_game.get("objective_hud_headline")),
		str(_game.get("objective_hud_progress_line")),
		str(_game.get("objective_hud_timer_line")),
	]
	if signature == _last_objective_callout_signature:
		return
	_last_objective_callout_signature = signature
	if objective_hud_title != null:
		objective_hud_title.text = str(_game.get("objective_hud_headline"))
	if objective_hud_progress != null:
		objective_hud_progress.text = str(_game.get("objective_hud_progress_line"))
	if objective_hud_timer != null:
		objective_hud_timer.text = str(_game.get("objective_hud_timer_line"))

func _update_slot_labels() -> void:
	var slots: Dictionary = _get_ability_slot_data()
	_assign_ability_orb("primary", primary_pill_label, _slot_icons.get("primary"), slots.get("primary", {}), _get_runtime_string(["primary_mode_label"], _get_cooldown_text(_primary_key)))
	_assign_ability_orb("ability_one", ability_one_pill_label, _slot_icons.get("ability_one"), slots.get("ability_one", {}), _get_runtime_string(["ability_one_label"], _get_cooldown_text(_ability_one_key)))
	_assign_ability_orb("ability_two", ability_two_pill_label, _slot_icons.get("ability_two"), slots.get("ability_two", {}), _get_runtime_string(["ability_two_label"], _get_cooldown_text(_ability_two_key)))
	_assign_ability_orb("dash", dash_pill_label, _slot_icons.get("dash"), slots.get("dash", {}), _get_runtime_string(["dash_label"], _get_cooldown_text(_dash_key)))
	_assign_ability_orb("ultimate", ultimate_pill_label, _slot_icons.get("ultimate"), slots.get("ultimate", {}), _get_runtime_string(["ultimate_label"], _get_cooldown_text(_ultimate_key)))

func _assign_ability_orb(slot_id: String, pill_label: Label, icon: Control, slot_data: Dictionary, state_text: String) -> void:
	var resolved: String = str(slot_data.get("state_text", state_text))
	if pill_label != null:
		pill_label.visible = false
	if icon != null and icon.has_method("configure"):
		icon.call(
			"configure",
			str(slot_data.get("icon_asset_id", slot_data.get("icon_id", slot_data.get("icon", "default")))),
			Color(0.83, 0.9, 1.0, 1.0),
			Color(0.97, 0.77, 0.3, 1.0),
			str(slot_data.get("icon_id", slot_data.get("icon", "default")))
		)
	if icon != null and icon.has_method("set_cooldown_overlay"):
		icon.call(
			"set_cooldown_overlay",
			bool(slot_data.get("cooldown_show", false)),
			float(slot_data.get("cooldown_fill", 0.0)),
			int(slot_data.get("charge_pips_total", 0)),
			int(slot_data.get("charge_pips_filled", 0)),
			float(slot_data.get("cooldown_seconds", 0.0))
		)
	_update_slot_timer_label(slot_id, float(slot_data.get("cooldown_seconds", 0.0)), bool(slot_data.get("cooldown_show", false)))

## Spell Brigade–style pills: digits only (cooldown seconds, charge %, or stack count).
func _format_ability_pill(state_text: String) -> String:
	var t: String = state_text.strip_edges()
	if t.is_empty():
		return "0"
	var upper: String = t.to_upper()
	if upper == "AUTO" or upper == "READY" or upper == "SNIPER":
		return "0"
	if t.ends_with("%"):
		var core: String = t.trim_suffix("%").strip_edges()
		if core.contains("."):
			return str(int(round(float(core))))
		return core if core.is_valid_int() else "0"
	var s_pos: int = t.find("s")
	if s_pos > 0:
		var num_part: String = t.substr(0, s_pos).strip_edges()
		if num_part.is_valid_float():
			return str(max(0, int(ceil(float(num_part)))))
	if " / " in t or "/" in t:
		var chunk: String = t.split(" ", false)[0] if t.contains(" ") else t
		if chunk.contains("/"):
			var parts: PackedStringArray = chunk.split("/")
			if parts.size() >= 1 and parts[0].is_valid_int():
				return str(int(parts[0]))
	return "0"

func _update_upgrade_cards() -> void:
	if _game == null:
		return
	var upgrade_choices: Array = _game.get("upgrade_choices_display") if _runtime_has_property("upgrade_choices_display") else []
	var selected_index: int = int(_game.get("selected_upgrade_index_display")) if _runtime_has_property("selected_upgrade_index_display") else -1
	var display_version: int = int(_game.get("upgrade_display_version")) if _runtime_has_property("upgrade_display_version") else -1
	var panel_visible: bool = not upgrade_choices.is_empty()
	var was_visible: bool = _last_upgrade_panel_visible
	if upgrade_panel.visible != panel_visible:
		upgrade_panel.visible = panel_visible
	if _upgrade_backdrop != null:
		_upgrade_backdrop.visible = panel_visible
	if top_left_root != null:
		top_left_root.visible = not panel_visible
	if top_center_root != null:
		top_center_root.visible = not panel_visible
	if top_right_root != null:
		top_right_root.visible = not panel_visible
	if bottom_hud_root != null:
		bottom_hud_root.visible = not panel_visible
	if menu_button != null:
		menu_button.visible = not panel_visible and menu_button.visible
	if ability_tooltip != null and panel_visible:
		ability_tooltip.visible = false
	if not panel_visible:
		_last_upgrade_panel_visible = false
		_last_upgrade_selected_index = -999
		_last_upgrade_title = ""
		_last_upgrade_subtitle = ""
		_last_upgrade_signature = ""
		_last_upgrade_version = -1
		if _upgrade_intro_tween != null:
			_upgrade_intro_tween.kill()
		_stop_upgrade_card_pulses()
		if _upgrade_backdrop != null:
			_upgrade_backdrop.color = Color(0.01, 0.02, 0.05, 0.0)
			_upgrade_backdrop.visible = false
		return
	var title_text: String = _get_runtime_string(["upgrade_overlay_title"], "Level Up")
	var subtitle_text: String = _build_upgrade_overlay_subtitle()
	var signature: String = ""
	if display_version >= 0:
		if _last_upgrade_panel_visible and _last_upgrade_version == display_version:
			return
	else:
		signature = _build_upgrade_choices_signature(upgrade_choices)
		if _last_upgrade_panel_visible and _last_upgrade_selected_index == selected_index and _last_upgrade_title == title_text and _last_upgrade_subtitle == subtitle_text and _last_upgrade_signature == signature:
			return
	_last_upgrade_panel_visible = true
	_last_upgrade_selected_index = selected_index
	_last_upgrade_title = title_text
	_last_upgrade_subtitle = subtitle_text
	_last_upgrade_signature = signature
	_last_upgrade_version = display_version
	upgrade_title_label.text = title_text
	upgrade_subtitle_label.text = subtitle_text
	for i in range(upgrade_cards.size()):
		var is_active: bool = i < upgrade_choices.size()
		upgrade_cards[i].visible = is_active
		if not is_active:
			if i < _upgrade_card_tags.size():
				_upgrade_card_tags[i].text = ""
			continue
		var choice: Dictionary = upgrade_choices[i]
		var content: Dictionary = _build_minimal_upgrade_card_content(choice)
		upgrade_card_titles[i].text = str(choice.get("name", "Upgrade")).to_upper()
		upgrade_card_descs[i].text = str(content.get("mechanic", ""))
		if i < _upgrade_card_icons.size():
			var icon: Control = _upgrade_card_icons[i]
			if icon != null and icon.has_method("configure"):
				icon.call(
					"configure",
					str(choice.get("icon_asset_id", choice.get("icon", "default"))),
					Color(1.0, 1.0, 1.0, 1.0),
					_upgrade_icon_accent_color(str(choice.get("rarity", "common"))),
					str(choice.get("icon", "default"))
				)
			if icon != null and icon.has_method("set_cooldown_overlay"):
				icon.call("set_cooldown_overlay", false, 0.0, 0, 0)
		if i < _upgrade_card_tags.size():
			_upgrade_card_tags[i].text = str(content.get("tag", ""))
		_apply_upgrade_card_state(i, choice, i == selected_index)
	if not was_visible:
		_play_upgrade_overlay_intro(selected_index)
	else:
		_refresh_upgrade_card_pulse(selected_index)

func _build_upgrade_overlay_subtitle() -> String:
	var prompt: String = _get_runtime_string(["upgrade_prompt"], "")
	if prompt.contains("\n"):
		var lines: PackedStringArray = prompt.split("\n", false)
		if not lines.is_empty():
			return lines[lines.size() - 1]
	if not prompt.is_empty():
		return prompt
	return "Choose one upgrade"

func _build_minimal_upgrade_card_content(choice: Dictionary) -> Dictionary:
	return {
		"tag": "%s UPGRADE" % str(choice.get("rarity", "common")).to_upper(),
		"mechanic": _upgrade_mechanic_text(choice),
	}

func _upgrade_mechanic_text(choice: Dictionary) -> String:
	var description: String = str(choice.get("description", "")).strip_edges()
	if description.contains("\n"):
		return description.split("\n", false)[0]
	return description

func _apply_upgrade_card_state(index: int, choice: Dictionary, selected: bool) -> void:
	if index < 0 or index >= upgrade_cards.size():
		return
	var card: PanelContainer = upgrade_cards[index]
	var rarity: String = str(choice.get("rarity", "common"))
	card.add_theme_stylebox_override("panel", _get_cached_upgrade_card_style(choice, selected))
	var pivot_size: Vector2 = card.size if card.size.x > 0.0 and card.size.y > 0.0 else card.custom_minimum_size
	card.pivot_offset = pivot_size * 0.5
	card.scale = Vector2(1.03, 1.03) if selected else Vector2.ONE
	card.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.92, 0.95, 1.0, 0.98)
	FrontendStyle.apply_header(upgrade_card_titles[index], 16, Color(1.0, 1.0, 1.0, 1.0))
	FrontendStyle.apply_body(upgrade_card_descs[index], 12, Color(0.90, 0.93, 0.98, 0.98))
	if index < _upgrade_card_tags.size():
		FrontendStyle.apply_small(_upgrade_card_tags[index], 11, _upgrade_tag_color(rarity))
	if index < _upgrade_card_header_bars.size() and _upgrade_card_header_bars[index] != null:
		_upgrade_card_header_bars[index].add_theme_stylebox_override("panel", _make_upgrade_header_style_for_choice(choice, selected))
	_update_upgrade_card_gradient(index, rarity, selected)

func _upgrade_tag_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.80, 0.98, 0.84, 1.0)
		"rare":
			return Color(0.80, 0.94, 1.0, 1.0)
		"epic":
			return Color(0.94, 0.84, 1.0, 1.0)
		_:
			return Color(0.88, 0.92, 0.98, 1.0)

func _upgrade_icon_accent_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.58, 0.96, 0.66, 1.0)
		"rare":
			return Color(0.62, 0.84, 1.0, 1.0)
		"epic":
			return Color(0.86, 0.70, 1.0, 1.0)
		_:
			return Color(0.94, 0.96, 1.0, 1.0)

func _make_upgrade_header_style_for_choice(choice: Dictionary, selected: bool) -> StyleBoxFlat:
	var rarity: String = str(choice.get("rarity", "common"))
	var style: StyleBoxFlat = _make_upgrade_header_style()
	match rarity:
		"common":
			style.border_color = Color(0.44, 0.82, 0.54, 0.84)
		"rare":
			style.border_color = Color(0.36, 0.66, 0.98, 0.88)
		"epic":
			style.border_color = Color(0.72, 0.48, 0.98, 0.88)
		_:
			style.border_color = Color(0.64, 0.72, 0.84, 0.80)
	if selected:
		style.border_color = style.border_color.lerp(Color(0.88, 0.96, 1.0, 1.0), 0.35)
	return style

func _play_upgrade_overlay_intro(selected_index: int) -> void:
	_stop_upgrade_card_pulses()
	if _upgrade_intro_tween != null:
		_upgrade_intro_tween.kill()
	if _upgrade_backdrop != null:
		_upgrade_backdrop.visible = true
		_upgrade_backdrop.color = Color(0.01, 0.02, 0.05, 0.0)
	upgrade_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	upgrade_panel.scale = Vector2(0.985, 0.985)
	upgrade_title_label.scale = Vector2(0.92, 0.92)
	upgrade_title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	upgrade_subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	for i in range(upgrade_cards.size()):
		if not upgrade_cards[i].visible:
			continue
		upgrade_cards[i].scale = Vector2(0.90, 0.90)
		upgrade_cards[i].modulate = Color(1.0, 1.0, 1.0, 0.0)
	_upgrade_intro_tween = create_tween().set_parallel(true)
	if _upgrade_backdrop != null:
		_upgrade_intro_tween.tween_property(_upgrade_backdrop, "color", Color(0.01, 0.02, 0.05, 0.86), 0.20)
	_upgrade_intro_tween.tween_property(upgrade_panel, "modulate", Color.WHITE, 0.18)
	_upgrade_intro_tween.tween_property(upgrade_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_upgrade_intro_tween.tween_property(upgrade_title_label, "modulate", Color.WHITE, 0.16)
	_upgrade_intro_tween.tween_property(upgrade_title_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_intro_tween.tween_property(upgrade_subtitle_label, "modulate", Color.WHITE, 0.16).set_delay(0.05)
	for i in range(upgrade_cards.size()):
		if not upgrade_cards[i].visible:
			continue
		var card: PanelContainer = upgrade_cards[i]
		var target_scale: Vector2 = Vector2(1.07, 1.07) if i == selected_index else Vector2(0.98, 0.98)
		var target_modulate: Color = Color.WHITE if i == selected_index else Color(0.78, 0.82, 0.9, 0.96)
		var delay: float = 0.05 + float(i) * 0.05
		_upgrade_intro_tween.tween_property(card, "modulate", target_modulate, 0.18).set_delay(delay)
		_upgrade_intro_tween.tween_property(card, "scale", target_scale, 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var pulse_delay: Tween = create_tween()
	pulse_delay.tween_interval(0.34)
	pulse_delay.tween_callback(Callable(self, "_refresh_upgrade_card_pulse").bind(selected_index))

func _refresh_upgrade_card_pulse(selected_index: int) -> void:
	_stop_upgrade_card_pulses()
	if selected_index < 0 or selected_index >= upgrade_cards.size():
		return
	var card: PanelContainer = upgrade_cards[selected_index]
	if card == null:
		return
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(card, "modulate", Color(1.04, 1.06, 1.10, 1.0), 0.90).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "modulate", Color.WHITE, 0.90).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_upgrade_card_pulse_tweens.append(tween)

func _stop_upgrade_card_pulses() -> void:
	for tween in _upgrade_card_pulse_tweens:
		if tween != null:
			tween.kill()
	_upgrade_card_pulse_tweens.clear()

func _create_slot_icons() -> void:
	const ORB_ICON: float = 58.0
	_slot_icons["primary"] = _create_icon_in_center(primary_orb_center, ORB_ICON)
	_slot_icons["ability_one"] = _create_icon_in_center(ability_one_orb_center, ORB_ICON)
	_slot_icons["ability_two"] = _create_icon_in_center(ability_two_orb_center, ORB_ICON)
	_slot_icons["dash"] = _create_icon_in_center(dash_orb_center, ORB_ICON)
	_slot_icons["ultimate"] = _create_icon_in_center(ultimate_orb_center, ORB_ICON)
	_create_slot_timer_labels()

func _create_slot_timer_labels() -> void:
	var label_specs: Array[Dictionary] = [
		{"id": "primary", "panel": primary_slot_panel},
		{"id": "ability_one", "panel": ability_one_slot_panel},
		{"id": "ability_two", "panel": ability_two_slot_panel},
		{"id": "dash", "panel": dash_slot_panel},
		{"id": "ultimate", "panel": ultimate_slot_panel},
	]
	for spec in label_specs:
		var panel: PanelContainer = spec.get("panel", null) as PanelContainer
		if panel == null:
			continue
		var timer_label: Label = panel.get_node_or_null("CooldownLabel") as Label
		if timer_label == null:
			timer_label = Label.new()
			timer_label.name = "CooldownLabel"
			timer_label.layout_mode = 1
			timer_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			timer_label.visible = false
			panel.add_child(timer_label)
		_slot_timer_labels[str(spec.get("id", ""))] = timer_label

func _update_slot_timer_label(slot_id: String, seconds: float, visible: bool) -> void:
	var label: Label = _slot_timer_labels.get(slot_id, null) as Label
	if label == null:
		return
	label.visible = visible and seconds > 0.0
	if not label.visible:
		label.text = ""
		return
	label.text = _format_cooldown_seconds(seconds)

func _format_cooldown_seconds(seconds: float) -> String:
	if seconds <= 0.0:
		return ""
	if seconds < 1.0:
		return "%.1f" % seconds
	return str(int(ceil(seconds)))

func _create_objective_markers() -> void:
	for i in range(4):
		var marker: Label = Label.new()
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.text = "!" if i < 3 else "\u2620"
		FrontendStyle.apply_header(marker, 20 if i < 3 else 24, Color(1.0, 0.84, 0.4, 1.0) if i < 3 else Color(0.96, 0.44, 0.38, 1.0))
		marker.visible = false
		objective_bar.add_child(marker)
		_objective_markers.append(marker)

func _update_progress_bar_presentation() -> void:
	var mode: String = _get_runtime_string(["progress_bar_mode"], "legacy")
	var show_markers: bool = bool(_game.get("progress_bar_show_markers")) if _runtime_has_property("progress_bar_show_markers") else false
	var marker_positions: Array = _game.get("progress_threshold_markers") if _runtime_has_property("progress_threshold_markers") else []
	var bar_only: bool = mode == "thresholds" or mode == "boss"
	var hud_scale: float = _current_hud_scale()
	objective_label.visible = not bar_only
	boss_label.visible = not bar_only
	objective_panel.custom_minimum_size = (Vector2(460, 30) if bar_only else Vector2(420, 34)) * hud_scale
	objective_bar.custom_minimum_size = Vector2(0.0, maxf(4.0, round(4.0 * hud_scale)))
	if mode == "boss":
		objective_bar.add_theme_stylebox_override("fill", _objective_fill_boss)
	else:
		objective_bar.add_theme_stylebox_override("fill", _objective_fill_threshold)
	for i in range(_objective_markers.size()):
		var marker: Label = _objective_markers[i]
		var marker_ratio: float = 0.0
		if i < 3 and i < marker_positions.size():
			marker_ratio = clampf(float(marker_positions[i]), 0.0, 1.0)
		elif i == 3:
			marker_ratio = 0.98
		marker.visible = mode == "thresholds" and show_markers
		if not marker.visible:
			continue
		marker.reset_size()
		var bar_w: float = maxf(objective_bar.size.x, 8.0)
		var marker_x: float = marker_ratio * bar_w - marker.size.x * 0.5
		var marker_y: float = floor((objective_bar.size.y - marker.size.y) * 0.5) - (2.0 if i < 3 else 1.0)
		marker.position = Vector2(clampf(marker_x, 0.0, bar_w - marker.size.x), marker_y)

func _create_icon_in_center(host: CenterContainer, icon_size: float) -> Control:
	if host == null:
		return null
	var icon: Control = ICON_GLYPH_SCENE.instantiate() as Control
	if icon == null:
		return null
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.add_child(icon)
	return icon

func _wire_ability_tooltips() -> void:
	var slots: Array[Dictionary] = [
		{"panel": primary_slot_panel, "id": "primary"},
		{"panel": ability_one_slot_panel, "id": "ability_one"},
		{"panel": ability_two_slot_panel, "id": "ability_two"},
		{"panel": dash_slot_panel, "id": "dash"},
		{"panel": ultimate_slot_panel, "id": "ultimate"},
	]
	for slot in slots:
		var panel: PanelContainer = slot.get("panel", null) as PanelContainer
		if panel == null:
			continue
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_entered.connect(Callable(self, "_on_ability_slot_mouse_entered").bind(str(slot.get("id", ""))))
		panel.mouse_exited.connect(Callable(self, "_on_ability_slot_mouse_exited").bind(str(slot.get("id", ""))))

func _on_ability_slot_mouse_entered(slot_id: String) -> void:
	var tooltip_data: Dictionary = _get_ability_tooltip_data(slot_id)
	if tooltip_data.is_empty():
		ability_tooltip.visible = false
		return
	ability_tooltip_title.text = str(tooltip_data.get("title", ""))
	ability_tooltip_body.text = str(tooltip_data.get("body", ""))
	ability_tooltip_state.text = str(tooltip_data.get("state", ""))
	ability_tooltip.visible = true

func _on_ability_slot_mouse_exited(_slot_id: String) -> void:
	ability_tooltip.visible = false

func _get_ability_tooltip_data(slot_id: String) -> Dictionary:
	var slots: Dictionary = _get_ability_slot_data()
	var slot_data: Dictionary = slots.get(slot_id, {})
	var action_name: String = str(slot_data.get("action", ""))
	var key: String = str(slot_data.get("key", ""))
	if key.is_empty() and not action_name.is_empty():
		key = GameSettings.get_binding_label(action_name)
	var title: String = str(slot_data.get("label", ""))
	var summary: String = str(slot_data.get("summary", ""))
	var detail: String = str(slot_data.get("detail", summary))
	var state: String = str(slot_data.get("state_text", ""))
	if action_name.is_empty() and key.is_empty() and title.is_empty():
		return {}
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) != RunConfig.selected_class_id:
			continue
		var abilities: Array = class_data.get("abilities", [])
		for ab in abilities:
			if (not action_name.is_empty() and str(ab.get("action", "")) == action_name) or str(ab.get("key", "")) == key:
				if title.is_empty():
					title = str(ab.get("name", ""))
				if summary.is_empty():
					summary = str(ab.get("summary", ""))
				if detail.is_empty():
					detail = str(ab.get("detail", summary))
				if key.is_empty():
					key = str(ab.get("key", ""))
				break
	var title_text: String = title if not title.is_empty() else key
	if not key.is_empty():
		title_text = "[%s] %s" % [key, title_text]
	return {
		"title": title_text,
		"body": detail if not detail.is_empty() else summary,
		"state": state,
	}

func _get_ability_slot_data() -> Dictionary:
	if _runtime_has_property("ability_slot_data"):
		var data: Variant = _game.get("ability_slot_data")
		if typeof(data) == TYPE_DICTIONARY:
			return data
	return {
		"primary": {"action": "primary_fire", "key": GameSettings.get_binding_label("primary_fire"), "icon_id": "bow", "icon_asset_id": "archer_hunters_bow", "label": "Hunter's Bow", "summary": "Manual bow shot", "detail": "Manual bow shot", "state_text": "READY"},
		"ability_one": {"action": "ability_1", "key": GameSettings.get_binding_label("ability_1"), "icon_id": "power_shot", "icon_asset_id": "archer_power_shot", "label": "Power Shot", "summary": "Heavy arrow", "detail": "Heavy arrow", "state_text": "READY"},
		"dash": {"action": "dash", "key": GameSettings.get_binding_label("dash"), "icon_id": "dash", "icon_asset_id": "archer_dash", "label": "Dash", "summary": "Manual reposition", "detail": "Manual reposition", "state_text": "READY"},
		"ability_two": {"action": "ability_2", "key": GameSettings.get_binding_label("ability_2"), "icon_id": "arrow_volley", "icon_asset_id": "archer_arrow_volley", "label": "Arrow Volley", "summary": "Arrow fan", "detail": "Arrow fan", "state_text": "READY"},
		"ultimate": {"action": "ultimate", "key": GameSettings.get_binding_label("ultimate"), "icon_id": "sentinel", "icon_asset_id": "archer_sentinel", "label": "Sentinel", "summary": "Hawk summon", "detail": "Hawk summon", "state_text": "0%"},
	}

func _get_cooldown_text(cooldown_key: StringName) -> String:
	if _cooldown_system == null or cooldown_key.is_empty():
		return ""
	var remaining: float = float(_cooldown_system.call("get_remaining", cooldown_key))
	return "READY" if remaining <= 0.0 else "%.1fs" % remaining

func _build_upgrade_card_style(choice: Dictionary, selected: bool) -> StyleBox:
	var rarity: String = str(choice.get("rarity", "common"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.96)
	style.border_color = _upgrade_card_border_color(rarity, selected)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2 if selected else 1)
	style.content_margin_left = 14.0
	style.content_margin_top = 14.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 2
	return style

func _upgrade_card_border_color(rarity: String, selected: bool) -> Color:
	if selected:
		return Color(0.78, 0.92, 1.0, 1.0)
	match rarity:
		"common":
			return Color(0.32, 0.60, 0.38, 0.84)
		"rare":
			return Color(0.28, 0.50, 0.78, 0.88)
		"epic":
			return Color(0.56, 0.34, 0.84, 0.88)
		_:
			return Color(0.42, 0.46, 0.56, 0.82)

func _make_upgrade_header_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_corner_radius_all(0)
	style.set_border_width_all(1)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

func _rarity_title_color(choice: Dictionary) -> Color:
	## Near-white titles with a light rarity tint (reference: blocky roguelike cards).
	var rarity: String = str(choice.get("rarity", "common"))
	match rarity:
		"common":
			return Color(0.94, 0.98, 0.93, 1.0)
		"rare":
			return Color(0.88, 0.94, 1.0, 1.0)
		"epic":
			return Color(0.96, 0.88, 1.0, 1.0)
		_:
			return Color(0.95, 0.96, 0.98, 1.0)

func _get_cached_upgrade_card_style(choice: Dictionary, selected: bool) -> StyleBox:
	var rarity: String = str(choice.get("rarity", "common"))
	var cache_key: String = "%s|%s" % [rarity, "selected" if selected else "idle"]
	if _upgrade_card_style_cache.has(cache_key):
		return _upgrade_card_style_cache[cache_key]
	var style: StyleBox = _build_upgrade_card_style(choice, selected)
	_upgrade_card_style_cache[cache_key] = style
	return style

func _build_upgrade_choices_signature(upgrade_choices: Array) -> String:
	var parts: PackedStringArray = []
	for choice_variant in upgrade_choices:
		var choice: Dictionary = choice_variant as Dictionary
		parts.append("%s|%s|%s|%s" % [
			str(choice.get("id", "")),
			str(choice.get("name", "")),
			str(choice.get("description", "")),
			str(choice.get("rarity", "common")),
		])
	return "||".join(parts)

func _get_runtime_string(property_names: Array, fallback: String = "") -> String:
	for property_name in property_names:
		if _runtime_has_property(str(property_name)):
			return str(_game.get(str(property_name)))
	return fallback

func _get_runtime_float(property_names: Array, fallback: float = 0.0) -> float:
	for property_name in property_names:
		if _runtime_has_property(str(property_name)):
			return float(_game.get(str(property_name)))
	return fallback

func _runtime_has_property(property_name: String) -> bool:
	if _game == null:
		return false
	for property in _game.get_property_list():
		if String(property.name) == property_name:
			return true
	return false

func _format_time(total_seconds: float) -> String:
	var seconds: int = int(floor(total_seconds))
	var minutes: int = seconds / 60
	var remainder: int = seconds % 60
	return "%02d:%02d" % [minutes, remainder]

func _is_hub_mode() -> bool:
	return _get_runtime_string(["hud_mode"], "") == "hub"

func _apply_theme() -> void:
	var hud_scale: float = _current_hud_scale()
	FrontendStyle.apply_small(timer_label, max(10, int(round(HUD_BASE_TIMER_FONT * hud_scale))), Color(0.92, 0.95, 1.0, 1.0))
	FrontendStyle.apply_body(objective_label, max(10, int(round(HUD_BASE_OBJECTIVE_FONT * hud_scale))), Color(0.92, 0.95, 1.0, 1.0))
	FrontendStyle.apply_small(boss_label, max(10, int(round(HUD_BASE_BOSS_FONT * hud_scale))), Color(0.72, 0.80, 0.90, 1.0))
	FrontendStyle.apply_header(ability_tooltip_title, max(12, int(round(HUD_BASE_TOOLTIP_TITLE_FONT * hud_scale))), Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_small(ability_tooltip_body, max(10, int(round(HUD_BASE_TOOLTIP_BODY_FONT * hud_scale))), Color(0.94, 0.90, 0.82, 1.0))
	FrontendStyle.apply_small(ability_tooltip_state, max(10, int(round(HUD_BASE_TOOLTIP_STATE_FONT * hud_scale))), Color(0.74, 0.84, 0.98, 1.0))
	FrontendStyle.apply_small(health_text, max(9, int(round(HUD_BASE_HEALTH_FONT * hud_scale))), Color(0.96, 0.98, 1.0, 1.0))
	FrontendStyle.apply_header(level_badge, max(12, int(round(HUD_BASE_LEVEL_FONT * hud_scale))), Color(0.96, 0.98, 1.0, 1.0))
	FrontendStyle.apply_header(upgrade_title_label, 26, Color(0.98, 0.98, 1.0, 1.0))
	FrontendStyle.apply_body(upgrade_subtitle_label, 12, Color(0.88, 0.92, 0.98, 0.98))
	FrontendStyle.apply_header(profile_title_label, 26, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_body(profile_subtitle_label, 14, Color(0.88, 0.90, 0.93, 1.0))
	FrontendStyle.apply_small(profile_summary_label, 13, Color(0.94, 0.92, 0.86, 1.0))
	FrontendStyle.apply_small(profile_stats_label, 13, Color(0.86, 0.90, 0.96, 1.0))
	FrontendStyle.apply_small(profile_upgrades_label, 13, Color(0.95, 0.90, 0.82, 1.0))
	FrontendStyle.apply_header(game_over_label, 24, Color(0.95, 0.82, 0.52, 1.0))
	for label in upgrade_card_titles:
		FrontendStyle.apply_header(label, 15, Color(0.98, 0.98, 1.0, 1.0))
	for label in upgrade_card_descs:
		FrontendStyle.apply_body(label, 12, Color(0.90, 0.93, 0.98, 0.98))

	FrontendStyle.apply_button_theme(menu_button, false, false, true)
	menu_button.custom_minimum_size = Vector2(94.0, 34.0) * hud_scale
	FrontendStyle.apply_button_theme(resume_button, true, false, true)
	FrontendStyle.apply_button_theme(profile_button, false, false, true)
	if _pause_settings_button != null:
		FrontendStyle.apply_button_theme(_pause_settings_button, false, false, true)
	FrontendStyle.apply_button_theme(menu_return_button, false, false, true)
	FrontendStyle.apply_button_theme(profile_back_button, false, false, true)
	FrontendStyle.apply_button_theme(profile_resume_button, true, false, true)
	if _settings_panel != null:
		FrontendStyle.apply_panel_theme(_settings_panel, "overlay")
		FrontendStyle.apply_header(_settings_title, 32, Color(0.95, 0.82, 0.52, 1.0))
		FrontendStyle.apply_body(_settings_resolution_label, 15, Color(0.82, 0.85, 0.9, 1.0))
		FrontendStyle.apply_body(_settings_brightness_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_body(_settings_master_volume_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_body(_settings_music_volume_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_body(_settings_sfx_volume_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_body(_settings_hud_scale_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_body(_settings_screen_shake_label, 14, Color(0.92, 0.86, 0.72, 1.0))
		FrontendStyle.apply_button_theme(_settings_display_mode_button, false, false, true)
		FrontendStyle.apply_button_theme(_settings_close_button, true, false, true)
		for check in [_settings_vsync_check, _settings_reduced_flashes_check, _settings_show_fps_check, _settings_show_damage_numbers_check]:
			if check == null:
				continue
			check.add_theme_font_override("font", FrontendStyle.FONT_BODY)
			check.add_theme_font_size_override("font_size", 14)
			check.add_theme_color_override("font_color", Color(0.88, 0.90, 0.93, 1.0))

	FrontendStyle.apply_panel_theme(timer_panel, "frame")
	if objective_hud_panel != null:
		FrontendStyle.apply_panel_theme(objective_hud_panel, "frame")
	if _quest_tab_panel != null:
		FrontendStyle.apply_panel_theme(_quest_tab_panel, "frame")
		FrontendStyle.apply_small(_quest_tab_title, 11, Color(0.95, 0.82, 0.52, 1.0))
		FrontendStyle.apply_small(_quest_tab_status, 11, Color(0.76, 0.84, 0.96, 1.0))
		FrontendStyle.apply_body(_quest_tab_body, 13, Color(0.92, 0.94, 0.98, 1.0))
	FrontendStyle.apply_panel_theme(level_badge_panel, "spell_level_ring")
	FrontendStyle.apply_panel_theme(primary_slot_panel, "ability_orb")
	if ability_one_slot_panel != null:
		FrontendStyle.apply_panel_theme(ability_one_slot_panel, "ability_orb")
	FrontendStyle.apply_panel_theme(ability_two_slot_panel, "ability_orb")
	FrontendStyle.apply_panel_theme(dash_slot_panel, "ability_orb")
	FrontendStyle.apply_panel_theme(ultimate_slot_panel, "ability_orb")
	var slot_ids: PackedStringArray = PackedStringArray(["PrimarySlot", "AbilityOneSlot", "MissilesSlot", "DashSlot", "SniperSlot"])
	for slot_id in slot_ids:
		var pill_panel: PanelContainer = get_node_or_null("BottomHud/MainColumn/TopRow/CenterBlock/AbilityRow/%s/PillPanel" % slot_id) as PanelContainer
		if pill_panel != null:
			pill_panel.visible = false
			pill_panel.custom_minimum_size = Vector2.ZERO
	for timer_label in _slot_timer_labels.values():
		if timer_label is Label:
			FrontendStyle.apply_header(timer_label as Label, max(10, int(round(12.0 * hud_scale))), Color(0.96, 0.96, 0.98, 1.0))
			(timer_label as Label).add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.96))
			(timer_label as Label).add_theme_constant_override("outline_size", 2)
	for slot in _hotbar_slots:
		FrontendStyle.apply_panel_theme(slot, "bag_slot")
	FrontendStyle.apply_panel_theme(upgrade_panel, "overlay")
	FrontendStyle.apply_panel_theme(game_over_panel, "overlay")
	FrontendStyle.apply_panel_theme(pause_panel, "overlay")
	FrontendStyle.apply_panel_theme(profile_panel, "overlay")
	FrontendStyle.apply_panel_theme(ability_tooltip, "overlay")
	if _inventory_panel != null:
		FrontendStyle.apply_panel_theme(_inventory_panel, "bag_frame")
	upgrade_panel.custom_minimum_size = Vector2(900, 430)
	if upgrade_cards_row != null:
		upgrade_cards_row.add_theme_constant_override("separation", 14)
	for card in upgrade_cards:
		card.custom_minimum_size = Vector2(240, 332)
		FrontendStyle.apply_panel_theme(card, "card")
	for stack in upgrade_card_stacks:
		var header_bar: PanelContainer = stack.get_node_or_null("HeaderBar") as PanelContainer
		var icon_well: PanelContainer = stack.get_node_or_null("IconWell") as PanelContainer
		if header_bar != null:
			header_bar.add_theme_stylebox_override("panel", _make_upgrade_header_style())
		if icon_well != null:
			icon_well.visible = true
			icon_well.custom_minimum_size = Vector2(0.0, 128.0)
			FrontendStyle.apply_panel_theme(icon_well, "upgrade_icon_well")
			var icon_margin: MarginContainer = icon_well.get_node_or_null("Margin") as MarginContainer
			if icon_margin != null:
				icon_margin.add_theme_constant_override("margin_left", 8)
				icon_margin.add_theme_constant_override("margin_top", 8)
				icon_margin.add_theme_constant_override("margin_right", 8)
				icon_margin.add_theme_constant_override("margin_bottom", 8)

	var health_bg: StyleBox = FrontendStyle.make_texture_style("health_bar_spell", 8, 4)
	var xp_bg: StyleBox = FrontendStyle.make_texture_style("hud_xp_track", 4, 2)
	health_bar.add_theme_stylebox_override("background", health_bg)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	objective_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var objective_bg: StyleBoxFlat = StyleBoxFlat.new()
	objective_bg.bg_color = Color(0.04, 0.07, 0.11, 0.84)
	objective_bg.set_corner_radius_all(3)
	objective_bg.set_border_width_all(0)
	objective_bar.add_theme_stylebox_override("background", objective_bg)

	var health_fill: StyleBoxFlat = StyleBoxFlat.new()
	health_fill.bg_color = Color(0.95, 0.34, 0.20, 0.98)
	health_fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", health_fill)

	var objective_fill: StyleBoxFlat = StyleBoxFlat.new()
	objective_fill.bg_color = Color(0.60, 0.90, 0.98, 0.98)
	objective_fill.set_corner_radius_all(3)
	_objective_fill_threshold = objective_fill
	objective_bar.add_theme_stylebox_override("fill", _objective_fill_threshold)

	var boss_fill: StyleBoxFlat = StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.96, 0.28, 0.2, 0.98)
	boss_fill.set_corner_radius_all(3)
	_objective_fill_boss = boss_fill

	var xp_fill: StyleBoxFlat = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.86, 0.92, 1.0, 1.0)
	xp_fill.set_corner_radius_all(1)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

func _on_upgrade_card_input(event: InputEvent, index: int) -> void:
	if _game == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioDirector.play_ui("ui_confirm")
		if _game.has_method("request_upgrade_selection"):
			_game.request_upgrade_selection(index)

func _on_upgrade_card_mouse_entered(index: int) -> void:
	AudioDirector.play_ui("ui_hover", -4.0)
	if _game != null and _game.has_method("request_upgrade_hover"):
		_game.request_upgrade_hover(index)

func _on_menu_button_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	if _is_hub_mode():
		_open_settings_panel()
		return
	if _game != null and _game.has_method("request_toggle_pause"):
		_game.request_toggle_pause()

func _on_settings_button_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	_open_settings_panel()

func _on_resume_button_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	if _game != null and _game.has_method("request_resume_game"):
		_game.request_resume_game()

func _on_profile_button_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	if _game != null and _game.has_method("request_open_profile"):
		_game.request_open_profile()

func _on_profile_back_button_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	if _game != null and _game.has_method("request_close_profile"):
		_game.request_close_profile()

func _on_return_to_menu_pressed() -> void:
	AudioDirector.play_ui("ui_confirm")
	if _game != null and _game.has_method("request_return_to_menu"):
		_game.request_return_to_menu()

func _on_settings_close_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	_close_settings_panel()

func _on_settings_display_mode_pressed() -> void:
	AudioDirector.play_ui("ui_click")
	if GameSettings != null:
		GameSettings.set_fullscreen(not GameSettings.fullscreen)
	_update_settings_panel_labels()

func _on_settings_brightness_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_brightness(value)
	_update_settings_panel_labels()

func _on_settings_master_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_master_volume(value)
	_update_settings_panel_labels()

func _on_settings_music_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_music_volume(value)
	_update_settings_panel_labels()

func _on_settings_sfx_volume_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_sfx_volume(value)
	_update_settings_panel_labels()

func _on_settings_hud_scale_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_hud_scale(value)
	_update_settings_panel_labels()

func _on_settings_screen_shake_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_screen_shake(value)
	_update_settings_panel_labels()

func _on_settings_vsync_toggled(toggled_on: bool) -> void:
	if _settings_syncing:
		return
	AudioDirector.play_ui("ui_click")
	if GameSettings != null:
		GameSettings.set_vsync_enabled(toggled_on)

func _on_settings_reduced_flashes_toggled(toggled_on: bool) -> void:
	if _settings_syncing:
		return
	AudioDirector.play_ui("ui_click")
	if GameSettings != null:
		GameSettings.set_reduced_flashes(toggled_on)

func _on_settings_show_fps_toggled(toggled_on: bool) -> void:
	if _settings_syncing:
		return
	AudioDirector.play_ui("ui_click")
	if GameSettings != null:
		GameSettings.set_show_fps(toggled_on)

func _on_settings_show_damage_numbers_toggled(toggled_on: bool) -> void:
	if _settings_syncing:
		return
	AudioDirector.play_ui("ui_click")
	if GameSettings != null:
		GameSettings.set_show_damage_numbers(toggled_on)

func _update_profile_panel() -> void:
	if _game == null or not profile_panel.visible:
		_last_profile_visible = false
		return
	var data: Dictionary = {}
	if _runtime_has_property("profile_data"):
		var raw: Variant = _game.get("profile_data")
		if typeof(raw) == TYPE_DICTIONARY:
			data = raw
	var signature: String = "%s|%s|%s|%s|%s" % [
		str(data.get("title", "Run Profile")),
		str(data.get("subtitle", "Current run snapshot")),
		str(data.get("summary_text", "")),
		str(data.get("stats_text", "")),
		str(data.get("upgrades_text", "")),
	]
	if _last_profile_visible and signature == _last_profile_signature:
		return
	_last_profile_visible = true
	_last_profile_signature = signature
	profile_title_label.text = str(data.get("title", "Run Profile"))
	profile_subtitle_label.text = str(data.get("subtitle", "Current run snapshot"))
	profile_summary_label.text = str(data.get("summary_text", ""))
	profile_stats_label.text = str(data.get("stats_text", ""))
	profile_upgrades_label.text = str(data.get("upgrades_text", ""))

func _update_quest_tab() -> void:
	if _quest_tab_panel == null:
		return
	var quest_data: Dictionary = TownState.get_active_quest() if TownState != null and TownState.has_method("get_active_quest") else {}
	if quest_data.is_empty():
		_quest_tab_panel.visible = false
		_quest_signature = ""
		return
	var signature: String = "%s|%s|%s|%s" % [
		str(quest_data.get("title", "")),
		str(quest_data.get("location", "")),
		str(quest_data.get("status", "")),
		str(quest_data.get("description", "")),
	]
	if signature == _quest_signature:
		return
	_quest_signature = signature
	_quest_tab_panel.visible = true
	_quest_tab_title.text = "QUEST IN PROGRESS"
	_quest_tab_status.text = "%s  |  %s" % [
		str(quest_data.get("location", "ESSELORIA")).to_upper(),
		str(quest_data.get("status", "In Progress")).to_upper(),
	]
	_quest_tab_body.text = "%s\n%s" % [
		str(quest_data.get("title", "")),
		str(quest_data.get("description", "")),
	]

func _update_inventory_panel() -> void:
	if _inventory_panel == null or not _inventory_panel.visible:
		_inventory_signature = ""
		return
	var layout: Array[String] = TownState.get_inventory_layout() if TownState != null and TownState.has_method("get_inventory_layout") else []
	var balance: int = TownState.get_coin_balance() if TownState != null and TownState.has_method("get_coin_balance") else 0
	var sig_parts: Array[String] = [str(balance)]
	for i in range(_inventory_slots.size()):
		var item_id: String = layout[i] if i < layout.size() else ""
		var count: int = TownState.get_item_count(item_id) if TownState != null and not item_id.is_empty() and TownState.has_method("get_item_count") else 0
		sig_parts.append("%s:%d" % [item_id, count])
	var signature: String = "|".join(sig_parts)
	if signature != _inventory_signature:
		_inventory_signature = signature
		for i in range(_inventory_slots.size()):
			var item_id: String = layout[i] if i < layout.size() else ""
			var count: int = TownState.get_item_count(item_id) if TownState != null and not item_id.is_empty() and TownState.has_method("get_item_count") else 0
			_inventory_slot_item_ids[i] = item_id if count > 0 else ""
			_inventory_slot_icons[i].texture = null
			_inventory_slot_counts[i].visible = false
			_inventory_slot_counts[i].text = ""
			if count <= 0:
				continue
			var tex: Texture2D = _load_item_texture(item_id)
			if tex != null:
				_inventory_slot_icons[i].texture = tex
			if count > 1:
				_inventory_slot_counts[i].text = str(count)
				_inventory_slot_counts[i].visible = true
	_inventory_gold_label.text = "%d Gold" % balance
	_inventory_hint_label.text = "Click a bag or hotbar slot to move items. %s closes." % GameSettings.get_binding_label("inventory")
	_validate_item_slot_selection()
	_refresh_item_slot_styles()

func _update_hotbar() -> void:
	if _hotbar_row == null or TownState == null:
		return
	var hotbar: Array[String] = TownState.get_hotbar() if TownState.has_method("get_hotbar") else []
	var sig_parts: Array[String] = []
	for i in range(4):
		var item_id: String = hotbar[i] if i < hotbar.size() else ""
		var count: int = TownState.get_item_count(item_id) if not item_id.is_empty() else 0
		sig_parts.append("%s:%d" % [item_id, count])
	var signature: String = "|".join(sig_parts)
	if signature != _hotbar_signature:
		_hotbar_signature = signature
		for i in range(4):
			var item_id: String = hotbar[i] if i < hotbar.size() else ""
			var count: int = TownState.get_item_count(item_id) if not item_id.is_empty() else 0
			_hotbar_slot_item_ids[i] = item_id if count > 0 else ""
			_hotbar_icons[i].texture = null
			_hotbar_counts[i].visible = false
			if item_id.is_empty() or count <= 0:
				continue
			var tex: Texture2D = _load_item_texture(item_id)
			if tex != null:
				_hotbar_icons[i].texture = tex
			_hotbar_counts[i].text = str(count)
			_hotbar_counts[i].visible = true
	_refresh_hotbar_key_labels()
	_validate_item_slot_selection()
	_refresh_item_slot_styles()

func _on_inventory_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if not _is_inventory_panel_visible():
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_item_slot_pressed("inventory", slot_index)
			get_viewport().set_input_as_handled()

func _on_hotbar_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if not _is_inventory_panel_visible():
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_item_slot_pressed("hotbar", slot_index)
			get_viewport().set_input_as_handled()

func _handle_item_slot_pressed(kind: String, slot_index: int) -> void:
	var item_id: String = _get_item_slot_item_id(kind, slot_index)
	if _selected_item_slot_kind.is_empty():
		if item_id.is_empty():
			return
		_selected_item_slot_kind = kind
		_selected_item_slot_index = slot_index
		_refresh_item_slot_styles()
		AudioDirector.play_ui("ui_click", -4.0)
		return
	if _selected_item_slot_kind == kind and _selected_item_slot_index == slot_index:
		_clear_item_slot_selection()
		return
	var moved: bool = false
	if TownState != null:
		if _selected_item_slot_kind == "inventory" and kind == "inventory":
			moved = TownState.swap_inventory_slots(_selected_item_slot_index, slot_index)
		elif _selected_item_slot_kind == "hotbar" and kind == "hotbar":
			moved = TownState.swap_hotbar_slots(_selected_item_slot_index, slot_index)
		elif _selected_item_slot_kind == "inventory" and kind == "hotbar":
			moved = TownState.swap_inventory_and_hotbar(_selected_item_slot_index, slot_index)
		elif _selected_item_slot_kind == "hotbar" and kind == "inventory":
			moved = TownState.swap_inventory_and_hotbar(slot_index, _selected_item_slot_index)
	_clear_item_slot_selection(false)
	_inventory_signature = ""
	_hotbar_signature = ""
	_update_inventory_panel()
	_update_hotbar()
	if moved:
		AudioDirector.play_ui("ui_confirm", -4.0)

func _clear_item_slot_selection(refresh_visuals: bool = true) -> void:
	_selected_item_slot_kind = ""
	_selected_item_slot_index = -1
	if refresh_visuals:
		_refresh_item_slot_styles()

func _validate_item_slot_selection() -> void:
	if _selected_item_slot_kind.is_empty():
		return
	if _get_item_slot_item_id(_selected_item_slot_kind, _selected_item_slot_index).is_empty():
		_clear_item_slot_selection(false)

func _get_item_slot_item_id(kind: String, slot_index: int) -> String:
	match kind:
		"inventory":
			if slot_index >= 0 and slot_index < _inventory_slot_item_ids.size():
				return _inventory_slot_item_ids[slot_index]
		"hotbar":
			if slot_index >= 0 and slot_index < _hotbar_slot_item_ids.size():
				return _hotbar_slot_item_ids[slot_index]
	return ""

func _refresh_item_slot_styles() -> void:
	for i in range(_inventory_slots.size()):
		var style_kind: String = "bag_slot_filled" if not _inventory_slot_item_ids[i].is_empty() else "bag_slot"
		if _selected_item_slot_kind == "inventory" and _selected_item_slot_index == i:
			style_kind = "bag_slot_selected"
		FrontendStyle.apply_panel_theme(_inventory_slots[i], style_kind)
	for i in range(_hotbar_slots.size()):
		var style_kind: String = "bag_slot_filled" if not _hotbar_slot_item_ids[i].is_empty() else "bag_slot"
		if _selected_item_slot_kind == "hotbar" and _selected_item_slot_index == i:
			style_kind = "bag_slot_selected"
		FrontendStyle.apply_panel_theme(_hotbar_slots[i], style_kind)

func _refresh_hotbar_key_labels() -> void:
	for i in range(_hotbar_key_labels.size()):
		var action_name: String = "item_slot_%d" % (i + 1)
		var key_text: String = GameSettings.get_binding_label(action_name) if GameSettings != null else str(i + 1)
		_hotbar_key_labels[i].text = key_text

var _item_texture_cache: Dictionary = {}

func _load_item_texture(item_id: String) -> Texture2D:
	if _item_texture_cache.has(item_id):
		return _item_texture_cache[item_id] as Texture2D
	var path: String = ""
	match item_id:
		"hp_potion":
			path = TOWN_POTION_ICON_PATH
	if path.is_empty():
		return null
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null and FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	_item_texture_cache[item_id] = texture
	return texture
