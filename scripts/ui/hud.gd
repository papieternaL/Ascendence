extends Control

const ICON_GLYPH_SCENE: PackedScene = preload("res://scenes/ui/IconGlyph.tscn")

@onready var timer_panel: PanelContainer = $TopLeft/TimerPanel
@onready var timer_label: Label = $TopLeft/TimerPanel/Margin/TimerLabel
@onready var menu_button: Button = $TopRight/MenuButton
@onready var pause_panel: PanelContainer = $CenterOverlay/OverlayStack/PausePanel
@onready var resume_button: Button = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox/ResumeButton
@onready var menu_return_button: Button = $CenterOverlay/OverlayStack/PausePanel/Margin/PauseVBox/MenuButton
@onready var objective_panel: PanelContainer = $TopCenter/ObjectivePanel
@onready var objective_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveLabel
@onready var objective_bar: ProgressBar = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveBar
@onready var boss_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/BossLabel
@onready var ability_panel: PanelContainer = $BottomAbility/AbilityPanel
@onready var primary_slot_panel: PanelContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot
@onready var primary_stack: VBoxContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot/Margin/Stack
@onready var primary_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot/Margin/Stack/Name
@onready var primary_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot/Margin/Stack/State
@onready var dash_slot_panel: PanelContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/DashSlot
@onready var dash_stack: VBoxContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/DashSlot/Margin/Stack
@onready var dash_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/DashSlot/Margin/Stack/Name
@onready var dash_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/DashSlot/Margin/Stack/State
@onready var ability_two_slot_panel: PanelContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot
@onready var ability_two_stack: VBoxContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot/Margin/Stack
@onready var ability_two_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot/Margin/Stack/Name
@onready var ability_two_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot/Margin/Stack/State
@onready var ultimate_slot_panel: PanelContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot
@onready var ultimate_stack: VBoxContainer = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot/Margin/Stack
@onready var ultimate_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot/Margin/Stack/Name
@onready var ultimate_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot/Margin/Stack/State
@onready var health_panel: PanelContainer = $BottomHealth/HealthPanel
@onready var health_bar: ProgressBar = $BottomHealth/HealthPanel/Margin/HealthStack/HealthBar
@onready var health_text: Label = $BottomHealth/HealthPanel/Margin/HealthStack/HealthText
@onready var level_badge_panel: PanelContainer = $LevelBadge
@onready var level_badge: Label = $LevelBadge/LevelLabel
@onready var xp_bar: ProgressBar = $BottomXP/XpBar
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
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack/Name,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack/Name,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack/Name,
]
@onready var upgrade_card_descs: Array[Label] = [
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card0/Margin/Stack/Description,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card1/Margin/Stack/Description,
	$CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeStack/CardsRow/Card2/Margin/Stack/Description,
]
@onready var game_over_panel: PanelContainer = $CenterOverlay/OverlayStack/GameOverPanel
@onready var game_over_label: Label = $CenterOverlay/OverlayStack/GameOverPanel/Margin/GameOverLabel

var _player: Node
var _cooldown_system: Node
var _game: Node
var _primary_key: StringName
var _dash_key: StringName
var _ability_two_key: StringName
var _ultimate_key: StringName
var _card_style_default: StyleBoxFlat
var _card_style_selected: StyleBoxFlat
var _slot_icons: Dictionary = {}
var _upgrade_icons: Array[Control] = []

func _ready() -> void:
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	objective_bar.max_value = 1.0
	objective_bar.value = 0.0
	xp_bar.max_value = 1.0
	xp_bar.value = 0.0
	_apply_theme()
	_create_slot_icons()
	_create_upgrade_icons()
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	menu_return_button.pressed.connect(_on_return_to_menu_pressed)
	for i in range(upgrade_cards.size()):
		upgrade_cards[i].mouse_filter = Control.MOUSE_FILTER_STOP
		upgrade_cards[i].gui_input.connect(Callable(self, "_on_upgrade_card_input").bind(i))
		upgrade_cards[i].mouse_entered.connect(Callable(self, "_on_upgrade_card_mouse_entered").bind(i))

func bind_player(player: Node) -> void:
	_player = player
	var max_hp: float = float(player.get("max_health"))
	if max_hp > 0.0:
		health_bar.max_value = max_hp

func bind_cooldown_system(cooldown_system: Node, primary_key: StringName, dash_key: StringName, ability_two_key: StringName, ultimate_key: StringName) -> void:
	_cooldown_system = cooldown_system
	_primary_key = primary_key
	_dash_key = dash_key
	_ability_two_key = ability_two_key
	_ultimate_key = ultimate_key

func bind_game(game: Node) -> void:
	_game = game

func _process(_delta: float) -> void:
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
	var run_time_value: float = _get_runtime_float(["run_time"], 0.0)
	timer_label.text = _format_time(run_time_value)
	objective_label.text = _get_runtime_string(["progress_panel_title", "objective_state_label"], "Forest Assault")
	objective_bar.value = _get_runtime_float(["progress_panel_value", "objective_progress"], 0.0)
	boss_label.text = _get_runtime_string(["progress_panel_detail", "boss_status_label"], "")
	xp_bar.value = _get_runtime_float(["xp_percent"], 0.0)
	level_badge.text = str(int(round(_get_runtime_float(["current_level"], 1.0))))
	if _player != null:
		var max_hp_value: float = float(_player.get("max_health"))
		if max_hp_value > 0.0:
			health_bar.max_value = max_hp_value
	_update_slot_labels()
	_update_upgrade_cards()
	var game_over_text: String = _get_runtime_string(["game_over_prompt"], "")
	game_over_panel.visible = not game_over_text.is_empty()
	game_over_label.text = game_over_text
	var is_paused: bool = bool(_game.get("_manual_pause")) if _runtime_has_property("_manual_pause") else false
	pause_panel.visible = is_paused
	menu_button.visible = not is_paused and upgrade_panel.visible == false and game_over_panel.visible == false

func _update_slot_labels() -> void:
	var slots: Dictionary = _get_ability_slot_data()
	_assign_slot(primary_name_label, primary_state_label, _slot_icons.get("primary"), slots.get("primary", {}), _get_runtime_string(["primary_mode_label"], _get_cooldown_text(_primary_key)))
	_assign_slot(dash_name_label, dash_state_label, _slot_icons.get("dash"), slots.get("dash", {}), _get_runtime_string(["dash_label"], _get_cooldown_text(_dash_key)))
	_assign_slot(ability_two_name_label, ability_two_state_label, _slot_icons.get("ability_two"), slots.get("ability_two", {}), _get_runtime_string(["ability_two_label"], _get_cooldown_text(_ability_two_key)))
	_assign_slot(ultimate_name_label, ultimate_state_label, _slot_icons.get("ultimate"), slots.get("ultimate", {}), _get_runtime_string(["ultimate_label"], _get_cooldown_text(_ultimate_key)))

func _assign_slot(name_label: Label, state_label: Label, icon: Control, slot_data: Dictionary, state_text: String) -> void:
	name_label.text = str(slot_data.get("key", ""))
	state_label.text = state_text
	if icon != null and icon.has_method("configure"):
		icon.call("configure", str(slot_data.get("icon", "default")))

func _update_upgrade_cards() -> void:
	if _game == null:
		return
	var upgrade_choices: Array = _game.get("upgrade_choices_display") if _runtime_has_property("upgrade_choices_display") else []
	var selected_index: int = int(_game.get("selected_upgrade_index_display")) if _runtime_has_property("selected_upgrade_index_display") else -1
	upgrade_panel.visible = not upgrade_choices.is_empty()
	if upgrade_choices.is_empty():
		return
	upgrade_title_label.text = "Level Up"
	upgrade_subtitle_label.text = _get_runtime_string(["upgrade_prompt"], "Choose one upgrade")
	for i in range(upgrade_cards.size()):
		var is_active: bool = i < upgrade_choices.size()
		upgrade_cards[i].visible = is_active
		if not is_active:
			continue
		var choice: Dictionary = upgrade_choices[i]
		upgrade_card_titles[i].text = str(choice.get("name", "Upgrade"))
		upgrade_card_descs[i].text = str(choice.get("description", ""))
		if i < _upgrade_icons.size() and _upgrade_icons[i] != null and _upgrade_icons[i].has_method("configure"):
			_upgrade_icons[i].call("configure", _resolve_upgrade_icon_id(choice), _upgrade_icon_primary(choice), _upgrade_icon_accent(choice))
		var style: StyleBoxFlat = _card_style_selected if i == selected_index else _card_style_default
		upgrade_cards[i].add_theme_stylebox_override("panel", style)

func _create_slot_icons() -> void:
	_slot_icons["primary"] = _create_icon_for_stack(primary_stack, 18.0)
	_slot_icons["dash"] = _create_icon_for_stack(dash_stack, 18.0)
	_slot_icons["ability_two"] = _create_icon_for_stack(ability_two_stack, 18.0)
	_slot_icons["ultimate"] = _create_icon_for_stack(ultimate_stack, 18.0)

func _create_upgrade_icons() -> void:
	for stack in upgrade_card_stacks:
		_upgrade_icons.append(_create_icon_for_stack(stack, 42.0))

func _create_icon_for_stack(stack: VBoxContainer, icon_size: float) -> Control:
	var icon: Control = ICON_GLYPH_SCENE.instantiate() as Control
	if icon == null:
		return null
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(icon)
	stack.move_child(icon, 0)
	return icon

func _get_ability_slot_data() -> Dictionary:
	if _runtime_has_property("ability_slot_data"):
		var data: Variant = _game.get("ability_slot_data")
		if typeof(data) == TYPE_DICTIONARY:
			return data
	return {
		"primary": {"key": "Q", "icon": "power_shot"},
		"dash": {"key": "SPACE", "icon": "dash"},
		"ability_two": {"key": "E", "icon": "power_shot"},
		"ultimate": {"key": "R", "icon": "frenzy"},
	}

func _get_cooldown_text(cooldown_key: StringName) -> String:
	if _cooldown_system == null or cooldown_key.is_empty():
		return ""
	var remaining: float = float(_cooldown_system.call("get_remaining", cooldown_key))
	return "READY" if remaining <= 0.0 else "%.1fs" % remaining

func _resolve_upgrade_icon_id(choice: Dictionary) -> String:
	var explicit_icon: String = str(choice.get("icon", ""))
	if not explicit_icon.is_empty():
		return explicit_icon
	var identifier: String = "%s %s" % [str(choice.get("id", "")), str(choice.get("name", ""))]
	identifier = identifier.to_lower()
	if "crit" in identifier:
		return "crit"
	if "pierce" in identifier or "deadeye" in identifier:
		return "pierce"
	if "speed" in identifier or "nock" in identifier or "quickdraw" in identifier:
		return "attack_speed"
	if "dash" in identifier or "stride" in identifier or "fleet" in identifier:
		return "move"
	if "arrow volley" in identifier or "volley" in identifier or "thorned" in identifier or "broadside" in identifier:
		return "power_shot"
	if "entangle" in identifier or "vine" in identifier:
		return "power_shot"
	if "frenzy" in identifier:
		return "frenzy_upgrade"
	if "missile" in identifier or "spell" in identifier or "arcane" in identifier:
		return "missiles"
	if "power" in identifier or "split" in identifier:
		return "power_shot"
	if "damage" in identifier or "tip" in identifier or "round" in identifier:
		return "damage"
	return "default"

func _upgrade_icon_primary(choice: Dictionary) -> Color:
	var rarity: String = str(choice.get("rarity", "common"))
	match rarity:
		"rare":
			return Color(0.72, 0.86, 1.0, 1.0)
		"epic":
			return Color(0.88, 0.72, 1.0, 1.0)
		_:
			return Color(0.84, 0.9, 1.0, 1.0)

func _upgrade_icon_accent(choice: Dictionary) -> Color:
	var rarity: String = str(choice.get("rarity", "common"))
	match rarity:
		"rare":
			return Color(0.42, 0.76, 1.0, 1.0)
		"epic":
			return Color(0.86, 0.46, 1.0, 1.0)
		_:
			return Color(0.97, 0.77, 0.3, 1.0)

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

func _apply_theme() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.12, 0.9)
	panel_style.border_color = Color(0.16, 0.28, 0.38, 1.0)
	panel_style.set_corner_radius_all(16)
	panel_style.set_border_width_all(2)

	var overlay_style: StyleBoxFlat = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.03, 0.05, 0.08, 0.94)
	overlay_style.border_color = Color(0.78, 0.61, 0.24, 1.0)
	overlay_style.set_corner_radius_all(18)
	overlay_style.set_border_width_all(2)

	var slot_style: StyleBoxFlat = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.08, 0.11, 0.16, 0.96)
	slot_style.border_color = Color(0.2, 0.26, 0.33, 1.0)
	slot_style.set_corner_radius_all(12)
	slot_style.set_border_width_all(2)

	var health_bg: StyleBoxFlat = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.09, 0.1, 0.12, 1.0)
	health_bg.border_color = Color(0.36, 0.12, 0.1, 1.0)
	health_bg.set_corner_radius_all(10)
	health_bg.set_border_width_all(2)

	var health_fill: StyleBoxFlat = StyleBoxFlat.new()
	health_fill.bg_color = Color(0.85, 0.2, 0.14, 1.0)
	health_fill.set_corner_radius_all(8)

	var objective_bg: StyleBoxFlat = StyleBoxFlat.new()
	objective_bg.bg_color = Color(0.06, 0.1, 0.13, 1.0)
	objective_bg.border_color = Color(0.12, 0.24, 0.31, 1.0)
	objective_bg.set_corner_radius_all(8)
	objective_bg.set_border_width_all(2)

	var objective_fill: StyleBoxFlat = StyleBoxFlat.new()
	objective_fill.bg_color = Color(0.38, 0.72, 0.96, 1.0)
	objective_fill.set_corner_radius_all(6)

	var xp_bg: StyleBoxFlat = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.05, 0.07, 0.09, 1.0)
	xp_bg.border_color = Color(0.16, 0.2, 0.24, 1.0)
	xp_bg.set_border_width_all(1)

	var xp_fill: StyleBoxFlat = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.35, 0.78, 0.96, 1.0)

	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.09, 0.14, 1.0)
	badge_style.border_color = Color(0.42, 0.46, 0.62, 1.0)
	badge_style.set_corner_radius_all(20)
	badge_style.set_border_width_all(2)

	_card_style_default = StyleBoxFlat.new()
	_card_style_default.bg_color = Color(0.08, 0.11, 0.16, 0.98)
	_card_style_default.border_color = Color(0.2, 0.26, 0.33, 1.0)
	_card_style_default.set_corner_radius_all(16)
	_card_style_default.set_border_width_all(2)

	_card_style_selected = StyleBoxFlat.new()
	_card_style_selected.bg_color = Color(0.13, 0.16, 0.22, 1.0)
	_card_style_selected.border_color = Color(0.78, 0.61, 0.24, 1.0)
	_card_style_selected.set_corner_radius_all(16)
	_card_style_selected.set_border_width_all(3)

	_apply_panel_style(timer_panel, panel_style)
	_apply_panel_style(objective_panel, panel_style)
	_apply_panel_style(ability_panel, panel_style)
	_apply_panel_style(health_panel, panel_style)
	_apply_panel_style(level_badge_panel, badge_style)
	_apply_panel_style(primary_slot_panel, slot_style)
	_apply_panel_style(dash_slot_panel, slot_style)
	_apply_panel_style(ability_two_slot_panel, slot_style)
	_apply_panel_style(ultimate_slot_panel, slot_style)
	_apply_panel_style(upgrade_panel, overlay_style)
	_apply_panel_style(game_over_panel, overlay_style)
	_apply_panel_style(pause_panel, overlay_style)
	for card in upgrade_cards:
		_apply_panel_style(card, _card_style_default)

	health_bar.add_theme_stylebox_override("background", health_bg)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	objective_bar.add_theme_stylebox_override("background", objective_bg)
	objective_bar.add_theme_stylebox_override("fill", objective_fill)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

func _apply_panel_style(panel: Control, style: StyleBoxFlat) -> void:
	panel.add_theme_stylebox_override("panel", style)

func _on_upgrade_card_input(event: InputEvent, index: int) -> void:
	if _game == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _game.has_method("request_upgrade_selection"):
			_game.request_upgrade_selection(index)

func _on_upgrade_card_mouse_entered(index: int) -> void:
	if _game != null and _game.has_method("request_upgrade_hover"):
		_game.request_upgrade_hover(index)

func _on_menu_button_pressed() -> void:
	if _game != null and _game.has_method("request_toggle_pause"):
		_game.request_toggle_pause()

func _on_resume_button_pressed() -> void:
	if _game != null and _game.has_method("request_resume_game"):
		_game.request_resume_game()

func _on_return_to_menu_pressed() -> void:
	if _game != null and _game.has_method("request_return_to_menu"):
		_game.request_return_to_menu()
