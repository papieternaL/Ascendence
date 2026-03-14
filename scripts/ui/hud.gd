extends Control

@onready var timer_panel: PanelContainer = $TopLeft/TimerPanel
@onready var timer_label: Label = $TopLeft/TimerPanel/Margin/TimerLabel
@onready var objective_panel: PanelContainer = $TopCenter/ObjectivePanel
@onready var objective_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveLabel
@onready var objective_bar: ProgressBar = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/ObjectiveBar
@onready var boss_label: Label = $TopCenter/ObjectivePanel/Margin/ObjectiveStack/BossLabel
@onready var ability_panel: PanelContainer = $BottomAbility/AbilityPanel
@onready var primary_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot/Margin/Stack/Name
@onready var primary_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot/Margin/Stack/State
@onready var missiles_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot/Margin/Stack/Name
@onready var missiles_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot/Margin/Stack/State
@onready var sniper_name_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot/Margin/Stack/Name
@onready var sniper_state_label: Label = $BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot/Margin/Stack/State
@onready var health_panel: PanelContainer = $BottomHealth/HealthPanel
@onready var health_bar: ProgressBar = $BottomHealth/HealthPanel/Margin/HealthStack/HealthBar
@onready var health_text: Label = $BottomHealth/HealthPanel/Margin/HealthStack/HealthText
@onready var level_badge_panel: PanelContainer = $LevelBadge
@onready var level_badge: Label = $LevelBadge/LevelLabel
@onready var xp_bar: ProgressBar = $BottomXP/XpBar
@onready var upgrade_panel: PanelContainer = $CenterOverlay/OverlayStack/UpgradePanel
@onready var upgrade_label: Label = $CenterOverlay/OverlayStack/UpgradePanel/Margin/UpgradeLabel
@onready var game_over_panel: PanelContainer = $CenterOverlay/OverlayStack/GameOverPanel
@onready var game_over_label: Label = $CenterOverlay/OverlayStack/GameOverPanel/Margin/GameOverLabel

var _player: Node
var _cooldown_system: Node
var _game: Node
var _primary_key: StringName
var _missiles_key: StringName
var _ultimate_key: StringName

func _ready() -> void:
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	objective_bar.max_value = 1.0
	objective_bar.value = 0.0
	xp_bar.max_value = 1.0
	xp_bar.value = 0.0
	_apply_theme()

func bind_player(player: Node) -> void:
	_player = player
	var max_hp: float = float(player.get("max_health"))
	if max_hp > 0.0:
		health_bar.max_value = max_hp

func bind_cooldown_system(cooldown_system: Node, primary_key: StringName, missiles_key: StringName, ultimate_key: StringName) -> void:
	_cooldown_system = cooldown_system
	_primary_key = primary_key
	_missiles_key = missiles_key
	_ultimate_key = ultimate_key

func bind_game(game: Node) -> void:
	_game = game

func _process(_delta: float) -> void:
	_update_health()
	_update_cooldowns()
	_update_status()

func _update_health() -> void:
	if _player == null:
		return
	var value: Variant = _player.get("health")
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		health_bar.value = float(value)
		health_text.text = "%d / %d" % [int(round(float(value))), int(round(health_bar.max_value))]

func _update_cooldowns() -> void:
	if _cooldown_system == null:
		return
	var primary_remaining: float = float(_cooldown_system.call("get_remaining", _primary_key))
	var missiles_remaining: float = float(_cooldown_system.call("get_remaining", _missiles_key))
	var ultimate_remaining: float = float(_cooldown_system.call("get_remaining", _ultimate_key))
	primary_name_label.text = "LMB"
	primary_state_label.text = "READY" if primary_remaining <= 0.0 else "%.1fs" % primary_remaining
	missiles_name_label.text = "E"
	missiles_state_label.text = "READY" if missiles_remaining <= 0.0 else "%.1fs" % missiles_remaining
	sniper_name_label.text = "R"
	sniper_state_label.text = "READY" if ultimate_remaining <= 0.0 else "%.1fs" % ultimate_remaining

func _update_status() -> void:
	if _game == null:
		return
	var run_time_value: float = float(_game.get("run_time"))
	timer_label.text = _format_time(run_time_value)
	objective_label.text = str(_game.get("objective_state_label"))
	objective_bar.value = float(_game.get("objective_progress"))
	boss_label.text = str(_game.get("boss_status_label"))
	xp_bar.value = float(_game.get("xp_percent"))
	level_badge.text = str(_game.get("current_level"))
	if _player != null:
		var max_hp_value: float = float(_player.get("max_health"))
		if max_hp_value > 0.0:
			health_bar.max_value = max_hp_value
	var primary_mode: String = str(_game.get("primary_mode_label"))
	primary_state_label.text = primary_mode
	sniper_state_label.text = str(_game.get("ultimate_label"))
	var upgrade_text: String = str(_game.get("upgrade_prompt"))
	upgrade_panel.visible = not upgrade_text.is_empty()
	upgrade_label.text = upgrade_text
	var game_over_text: String = str(_game.get("game_over_prompt"))
	game_over_panel.visible = not game_over_text.is_empty()
	game_over_label.text = game_over_text

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

	_apply_panel_style(timer_panel, panel_style)
	_apply_panel_style(objective_panel, panel_style)
	_apply_panel_style(ability_panel, panel_style)
	_apply_panel_style(health_panel, panel_style)
	_apply_panel_style(level_badge_panel, badge_style)
	_apply_panel_style($BottomAbility/AbilityPanel/Margin/AbilityRow/PrimarySlot, slot_style)
	_apply_panel_style($BottomAbility/AbilityPanel/Margin/AbilityRow/MissilesSlot, slot_style)
	_apply_panel_style($BottomAbility/AbilityPanel/Margin/AbilityRow/SniperSlot, slot_style)
	_apply_panel_style(upgrade_panel, overlay_style)
	_apply_panel_style(game_over_panel, overlay_style)

	health_bar.add_theme_stylebox_override("background", health_bg)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	objective_bar.add_theme_stylebox_override("background", objective_bg)
	objective_bar.add_theme_stylebox_override("fill", objective_fill)
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

func _apply_panel_style(panel: Control, style: StyleBoxFlat) -> void:
	panel.add_theme_stylebox_override("panel", style)
