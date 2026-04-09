extends Node2D

const HUB_RECT: Rect2 = Rect2(80.0, 120.0, 1840.0, 1000.0)
const HUB_CENTER: Vector2 = Vector2(1000.0, 620.0)
## Matches AscensionPortal placement in EsseloriaHub (south gate).
const PORTAL_POINT: Vector2 = Vector2(1000.0, 1000.0)
const PLAZA_RADIUS: float = 188.0
const OUTER_RING_RADIUS: float = 254.0
const PATH_WIDTH: float = 80.0
## Extend the hub fit area a bit so more of the plaza reads on screen while
## keeping the drawn cobble floor matched to the camera bounds.
const CAMERA_PADDING_X: float = 110.0
const CAMERA_PADDING_Y: float = 90.0
const HUB_CAMERA_IDLE_BIAS: Vector2 = Vector2(0.0, -18.0)
const HUB_CAMERA_POSITION_BIAS: Vector2 = Vector2(54.0, 42.0)
const HUB_CAMERA_LOOKAHEAD: Vector2 = Vector2(40.0, 28.0)
const HUB_CAMERA_OFFSET_LIMIT: Vector2 = Vector2(84.0, 64.0)
const HUB_CAMERA_OFFSET_LERP_SPEED: float = 7.5
const OVERLAY_MODE_GENERIC: String = "generic"
const OVERLAY_MODE_MERCHANT: String = "merchant"
const OVERLAY_MODE_QUEST: String = "quest"
const MERCHANT_ITEM_ID: String = "hp_potion"
const POTION_ICON_PATH: String = "res://art/hub/hub_hp_potion.png"
const QUEST_SCROLL_PATH: String = "res://art/hub/hub_quest_scroll.png"
## `Control.layout_mode` for container-managed children (LayoutMode.CONTAINER = 2; enum not always exposed in GDScript).
const CONTROL_LAYOUT_MODE_CONTAINER: int = 2

const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

## Tiled under paths/plaza; set in Inspector from art/hub/cobble_tile.png
@export var cobble_floor_texture: Texture2D
## World size per tile; **0** = match texture width (recommended).
@export var cobble_tile_px: int = 0

@onready var central_plaza: Node2D = $CentralPlaza
@onready var central_plaza_ground: Node2D = $CentralPlaza/Ground
@onready var central_plaza_blockers: Node2D = $CentralPlaza/Blockers
@onready var central_plaza_decor: Node2D = $CentralPlaza/Decor
@onready var sign_arch: Node2D = get_node_or_null("NorthArrival/SignArch") as Node2D
@onready var lantern_post_left: Node2D = get_node_or_null("NorthArrival/LanternPostLeft") as Node2D
@onready var lantern_post_right: Node2D = get_node_or_null("NorthArrival/LanternPostRight") as Node2D
@onready var north_arrival_cargo_left: Node2D = get_node_or_null("NorthArrival/ArrivalCargoLeft") as Node2D
@onready var north_arrival_cargo_right: Node2D = get_node_or_null("NorthArrival/ArrivalCargoRight") as Node2D
@onready var quest_area: Node2D = get_node_or_null("QuestArea") as Node2D
@onready var merchant_area: Node2D = get_node_or_null("CentralPlaza/Decor/MerchantArea") as Node2D
@onready var stone_walls: Node2D = get_node_or_null("CentralPlaza/Decor/StoneWalls") as Node2D
@onready var south_east_canal: Node2D = get_node_or_null("CentralPlaza/Decor/SouthEastCanal") as Node2D
@onready var town_greenery: Node2D = get_node_or_null("CentralPlaza/Decor/TownGreenery") as Node2D
@onready var training_area: Node2D = get_node_or_null("CentralPlaza/Decor/TrainingArea") as Node2D
@onready var quest_building: Sprite2D = get_node_or_null("QuestArea/QuestBuilding") as Sprite2D
@onready var quest_board: Node2D = get_node_or_null("QuestArea/QuestBoard") as Node2D
@onready var quest_notice_sign: Sprite2D = get_node_or_null("QuestArea/QuestNoticeSign") as Sprite2D
@onready var quest_frontage_clutter: Node2D = get_node_or_null("QuestArea/QuestFrontageClutter") as Node2D
@onready var merchant_stock: Node2D = get_node_or_null("CentralPlaza/Decor/MerchantArea/MerchantStock") as Node2D
@onready var merchant_cargo: Node2D = get_node_or_null("CentralPlaza/Decor/MerchantArea/MerchantCargo") as Node2D
@onready var canal_bridge: Sprite2D = get_node_or_null("CentralPlaza/Decor/SouthEastCanal/Bridge") as Sprite2D
@onready var training_props: Node2D = get_node_or_null("CentralPlaza/Decor/TrainingArea/TrainingProps") as Node2D
@onready var weapon_cache: Node2D = get_node_or_null("CentralPlaza/Decor/WeaponCornerDecor/WeaponCache") as Node2D
@onready var weapon_cargo: Node2D = get_node_or_null("CentralPlaza/Decor/WeaponCornerDecor/WeaponCargo") as Node2D
@onready var weapon_station_one: Node2D = get_node_or_null("WeaponStation1") as Node2D
@onready var weapon_station_two: Node2D = get_node_or_null("WeaponStation2") as Node2D
@onready var virtue_statue: Node2D = get_node_or_null("VirtueStatue") as Node2D
@onready var ascension_portal: Node2D = get_node_or_null("AscensionPortal") as Node2D
@onready var quest_giver: Node2D = get_node_or_null("NPCs/QuestGiver") as Node2D
@onready var merchant_keeper: Node2D = get_node_or_null("NPCs/MerchantKeeper") as Node2D
@onready var trainee: Node2D = get_node_or_null("NPCs/Trainee") as Node2D
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var practice_runtime: HubPracticeRuntime = $PracticeRuntime
@onready var ui_layer: CanvasLayer = $UI
@onready var hud: Control = $UI/HUD
@onready var interaction_prompt: PanelContainer = $UI/InteractionPrompt
@onready var center_overlay: Control = $UI/CenterOverlay
@onready var overlay_backdrop: ColorRect = $UI/CenterOverlay/OverlayBackdrop
@onready var overlay_center: CenterContainer = $UI/CenterOverlay/OverlayCenter
@onready var overlay_panel: PanelContainer = $UI/CenterOverlay/OverlayCenter/OverlayPanel
@onready var overlay_margin: MarginContainer = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin
@onready var generic_content: VBoxContainer = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox
@onready var overlay_title: Label = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Title
@onready var overlay_subtitle: Label = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Subtitle
@onready var overlay_status: Label = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Status
@onready var overlay_body: Label = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Body
@onready var overlay_hint: Label = $UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Hint

@onready var overlay_action_buttons: Array[Button] = [
	$UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Actions/Action0,
	$UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Actions/Action1,
	$UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Actions/Action2,
	$UI/CenterOverlay/OverlayCenter/OverlayPanel/Margin/VBox/Actions/Action3,
]

var _overlay_active: bool = false
var _overlay_mode: String = ""
var _overlay_action_handlers: Array[Callable] = []
var _potion_icon_texture: Texture2D
var _quest_scroll_texture: Texture2D
var merchant_content: VBoxContainer
var merchant_title: Label
var merchant_subtitle: Label
var merchant_balance: Label
var merchant_icon_frame: PanelContainer
var merchant_icon: TextureRect
var merchant_item_name: Label
var merchant_item_description: Label
var merchant_owned: Label
var merchant_price: Label
var merchant_buy_button: Button
var merchant_close_button: Button
var merchant_hint: Label
var quest_scroll_root: Control
var quest_scroll_underlay: ColorRect
var quest_scroll_fallback: ColorRect
var quest_scroll_background: TextureRect
var quest_scroll_margin: MarginContainer
var quest_title: Label
var quest_subtitle: Label
var quest_body: Label
var quest_close_button: Button
var quest_hint: Label
var player: HubCombatPlayer
var _hub_camera_offset: Vector2 = HUB_CAMERA_IDLE_BIAS

func _ready() -> void:
	AudioDirector.set_music_context("hub")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ui_layer != null:
		ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if hud != null:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.visible = true
	if practice_runtime != null:
		practice_runtime.process_mode = Node.PROCESS_MODE_ALWAYS
	if practice_runtime != null:
		practice_runtime.player_changed.connect(_on_practice_player_changed)
		practice_runtime.setup_practice(player_spawn.global_position)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	for i in range(overlay_action_buttons.size()):
		overlay_action_buttons[i].pressed.connect(Callable(self, "_on_overlay_action_pressed").bind(i))
		overlay_action_buttons[i].mouse_entered.connect(func() -> void: AudioDirector.play_ui("ui_hover", -4.0))
	_build_overlay_views()
	center_overlay.visible = false
	overlay_backdrop.visible = false
	overlay_center.visible = false
	overlay_panel.visible = false
	_apply_ui_theme()
	_refresh_quest_scroll()
	queue_redraw()

func _process(delta: float) -> void:
	_refresh_hub_camera_framing(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not _overlay_active:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_overlay()
		get_viewport().set_input_as_handled()
		return

func apply_camera_limits(camera: Camera2D) -> void:
	if camera == null:
		return
	camera.limit_left = int(HUB_RECT.position.x - CAMERA_PADDING_X)
	camera.limit_top = int(HUB_RECT.position.y - CAMERA_PADDING_Y)
	camera.limit_right = int(HUB_RECT.end.x + CAMERA_PADDING_X)
	camera.limit_bottom = int(HUB_RECT.end.y + CAMERA_PADDING_Y)


## Zoom so the floor rect covers the viewport instead of exposing the backdrop.
func apply_hub_camera_zoom(camera: Camera2D) -> void:
	if camera == null:
		return
	var limit_w: float = float(camera.limit_right - camera.limit_left)
	var limit_h: float = float(camera.limit_bottom - camera.limit_top)
	if limit_w <= 1.0 or limit_h <= 1.0:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var z: float = maxf(vp.x / limit_w, vp.y / limit_h)
	var zoom_value: Vector2 = Vector2(z, z)
	var framing_offset: Vector2 = _hub_camera_offset
	if camera.has_method("set_external_framing"):
		camera.call("set_external_framing", zoom_value, framing_offset)
	else:
		camera.zoom = zoom_value
		camera.position = framing_offset

func _refresh_hub_camera_framing(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var target_offset: Vector2 = _compute_hub_camera_offset()
	var lerp_weight: float = 1.0 - exp(-HUB_CAMERA_OFFSET_LERP_SPEED * maxf(delta, 0.0))
	_hub_camera_offset = _hub_camera_offset.lerp(target_offset, lerp_weight)
	var camera: Camera2D = player.get_camera()
	if camera != null:
		apply_hub_camera_zoom(camera)

func _compute_hub_camera_offset() -> Vector2:
	if player == null or not is_instance_valid(player):
		return HUB_CAMERA_IDLE_BIAS
	var half_size: Vector2 = HUB_RECT.size * 0.5
	var relative_position: Vector2 = player.global_position - HUB_CENTER
	var position_ratio: Vector2 = Vector2(
		clampf(relative_position.x / maxf(half_size.x, 1.0), -1.0, 1.0),
		clampf(relative_position.y / maxf(half_size.y, 1.0), -1.0, 1.0)
	)
	var position_offset: Vector2 = Vector2(
		position_ratio.x * HUB_CAMERA_POSITION_BIAS.x,
		position_ratio.y * HUB_CAMERA_POSITION_BIAS.y
	)
	var velocity: Vector2 = player.velocity
	var speed_ratio: float = clampf(
		velocity.length() / maxf(player.move_speed, 1.0),
		0.0,
		1.0
	)
	var velocity_dir: Vector2 = velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.ZERO
	var lookahead_offset: Vector2 = Vector2(
		velocity_dir.x * HUB_CAMERA_LOOKAHEAD.x * speed_ratio,
		velocity_dir.y * HUB_CAMERA_LOOKAHEAD.y * speed_ratio
	)
	var target_offset: Vector2 = HUB_CAMERA_IDLE_BIAS + position_offset + lookahead_offset
	target_offset.x = clampf(target_offset.x, -HUB_CAMERA_OFFSET_LIMIT.x, HUB_CAMERA_OFFSET_LIMIT.x)
	target_offset.y = clampf(target_offset.y, -HUB_CAMERA_OFFSET_LIMIT.y, HUB_CAMERA_OFFSET_LIMIT.y)
	return target_offset


func _apply_hub_camera_zoom_deferred() -> void:
	if player == null:
		return
	var camera: Camera2D = player.get_camera()
	if camera != null:
		apply_hub_camera_zoom(camera)


func _on_viewport_size_changed() -> void:
	if player == null:
		return
	var camera: Camera2D = player.get_camera()
	if camera != null:
		apply_hub_camera_zoom(camera)


## Cobble and any under-fill match camera limits (no green/black band outside HUB_RECT).
func _floor_draw_rect() -> Rect2:
	return HUB_RECT.grow_individual(
		CAMERA_PADDING_X,
		CAMERA_PADDING_Y,
		CAMERA_PADDING_X,
		CAMERA_PADDING_Y
	)

func _has_all_nodes(nodes: Array) -> bool:
	for node in nodes:
		if node == null:
			return false
	return true

func has_overlay_active() -> bool:
	return _overlay_active

func open_weapon_class_overlay(class_id: String) -> void:
	var class_data: Dictionary = _get_class_data_by_id(class_id)
	if class_data.is_empty():
		_open_overlay(
			"WEAPON DATA UNAVAILABLE",
			"Prototype diagnostics",
			"NO CLASS DATA FOUND",
			"The selected weapon pillar does not have class data wired yet.",
			[
				{
					"text": "CLOSE",
					"callback": Callable(self, "close_overlay"),
					"selected": false,
					"disabled": false,
				},
			]
		)
		return
	var title: String = str(class_data.get("name", "WEAPON")).to_upper()
	var status_line: String = str(class_data.get("status", ""))
	var body: String = _build_weapon_class_body(class_data)
	var is_selected: bool = RunConfig.selected_class_id == class_id
	_open_overlay(
		title,
		"Prepare the next Deepwood run",
		status_line,
		body,
		[
			{
				"text": "EQUIP THIS WEAPON",
				"callback": Callable(self, "_confirm_weapon_class").bind(class_id),
				"selected": is_selected,
				"disabled": false,
			},
			{
				"text": "CLOSE",
				"callback": Callable(self, "close_overlay"),
				"selected": false,
				"disabled": false,
			},
		]
	)

func _get_class_data_by_id(class_id: String) -> Dictionary:
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) == class_id:
			return class_data
	return {}

func _build_weapon_class_body(class_data: Dictionary) -> String:
	var parts: Array[String] = []
	var desc: String = str(class_data.get("description", "")).strip_edges()
	if not desc.is_empty():
		parts.append(desc)
	else:
		parts.append("Prototype weapon summary unavailable.")
	parts.append("")
	parts.append("ABILITIES")
	var abilities: Variant = class_data.get("abilities", [])
	var appended_abilities: bool = false
	if abilities is Array:
		for ability in abilities:
			if not (ability is Dictionary):
				continue
			var ad: Dictionary = ability as Dictionary
			var key: String = str(ad.get("key", ""))
			var action_name: String = str(ad.get("action", ""))
			if not action_name.is_empty():
				key = GameSettings.get_binding_label(action_name)
			var aname: String = str(ad.get("name", ""))
			var summary: String = str(ad.get("summary", ""))
			var detail: String = str(ad.get("detail", ""))
			parts.append("[%s] %s" % [key, aname])
			if not summary.is_empty():
				parts.append("  %s" % summary)
			if not detail.is_empty():
				parts.append("  %s" % detail)
			parts.append("")
			appended_abilities = true
	if not appended_abilities:
		parts.append("No ability details are configured for this weapon yet.")
	return "\n".join(parts).strip_edges()

func _confirm_weapon_class(class_id: String) -> void:
	RunConfig.selected_class_id = class_id
	if practice_runtime != null:
		var reload_position: Vector2 = player.global_position if player != null else player_spawn.global_position
		practice_runtime.reload_selected_class(reload_position)
	close_overlay()

func open_virtue_statue() -> void:
	var lines: Array[String] = []
	for upgrade_id in MetaProgression.UPGRADE_ORDER:
		var data: Dictionary = MetaProgression.UPGRADE_DEFS.get(upgrade_id, {})
		var unlocked: bool = MetaProgression.is_upgrade_unlocked(upgrade_id)
		lines.append("%s  %s" % ["OWNED" if unlocked else "AVAILABLE", str(data.get("summary", ""))])
	if lines.is_empty():
		lines.append("No virtue upgrades are configured yet.")
	_open_overlay(
		"VIRTUE ENHANCEMENT STATUE",
		"Permanent prototype progression",
		"UNLIMITED TEST ACCESS: %s" % ("ON" if MetaProgression.uses_unlimited_test_points() else "OFF"),
		"\n".join(lines),
		[
			_build_virtue_button(MetaProgression.UPGRADE_FORTITUDE),
			_build_virtue_button(MetaProgression.UPGRADE_MIGHT),
			_build_virtue_button(MetaProgression.UPGRADE_SWIFTNESS),
			{
				"text": "CLOSE",
				"callback": Callable(self, "close_overlay"),
				"selected": false,
				"disabled": false,
			},
		]
	)

func open_quest_board() -> void:
	_open_overlay(
		"QUEST BOARD",
		"District dispatch",
		"ACTIVE ASSIGNMENT: DEEPWOOD",
		"The Central District is staging hunters for repeated pushes into the corrupted wood.\n\nInspect the weapon pillars to compare loadouts, review Virtue enhancements, then enter the Ascension Portal when ready.",
		[
			{
				"text": "CLOSE",
				"callback": Callable(self, "close_overlay"),
				"selected": false,
				"disabled": false,
			},
		]
	)

func open_merchant_shop() -> void:
	_show_overlay_mode(OVERLAY_MODE_MERCHANT)
	_refresh_merchant_shop()
	if merchant_buy_button != null and not merchant_buy_button.disabled:
		merchant_buy_button.grab_focus()
	elif merchant_close_button != null:
		merchant_close_button.grab_focus()

func open_quest_scroll() -> void:
	_show_overlay_mode(OVERLAY_MODE_QUEST)
	_refresh_quest_scroll()
	if quest_close_button != null:
		quest_close_button.grab_focus()

func open_portal_panel() -> void:
	var selected: Dictionary = _get_selected_class_data()
	var selected_name: String = str(selected.get("name", "NO WEAPON SELECTED"))
	_open_overlay(
		"ASCENSION PORTAL",
		"Deepwood route",
		"SELECTED WEAPON: %s" % selected_name,
		"Step through the portal to begin the shared Deepwood run. Your equipped weapon changes how you fight, but every loadout enters the same route.",
		[
			{
				"text": "ENTER TRIAL",
				"callback": Callable(self, "start_selected_run"),
				"selected": true,
				"disabled": false,
			},
			{
				"text": "CLOSE",
				"callback": Callable(self, "close_overlay"),
				"selected": false,
				"disabled": false,
			},
		]
	)

func close_overlay(play_sound: bool = true) -> void:
	if play_sound and _overlay_active:
		AudioDirector.play_ui("ui_click")
	_overlay_active = false
	_overlay_mode = ""
	center_overlay.visible = false
	overlay_backdrop.visible = false
	overlay_center.visible = false
	overlay_panel.visible = false
	generic_content.visible = false
	if merchant_content != null:
		merchant_content.visible = false
	if quest_scroll_root != null:
		quest_scroll_root.visible = false
	overlay_title.text = ""
	overlay_subtitle.text = ""
	overlay_status.text = ""
	overlay_body.text = ""
	_overlay_action_handlers.clear()
	for button in overlay_action_buttons:
		button.visible = false
	if practice_runtime != null:
		practice_runtime.set_input_blocked(false)

func start_selected_run() -> void:
	RunConfig.selected_map_id = RunConfig.MAP_DEEPWOOD
	close_overlay()
	get_tree().paused = false
	get_tree().change_scene_to_file(RunConfig.get_main_scene_for_selection())

func _unlock_virtue_upgrade(upgrade_id: String) -> void:
	MetaProgression.unlock_upgrade(upgrade_id)
	open_virtue_statue()

func _build_virtue_button(upgrade_id: String) -> Dictionary:
	var data: Dictionary = MetaProgression.UPGRADE_DEFS.get(upgrade_id, {})
	var unlocked: bool = MetaProgression.is_upgrade_unlocked(upgrade_id)
	return {
		"text": "%s%s" % [str(data.get("label", upgrade_id)).to_upper(), " OWNED" if unlocked else ""],
		"callback": Callable(self, "_unlock_virtue_upgrade").bind(upgrade_id),
		"selected": unlocked,
		"disabled": unlocked,
	}

func _get_selected_class_data() -> Dictionary:
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) == RunConfig.selected_class_id:
			return class_data
	return RunConfig.get_class_data()[0] if not RunConfig.get_class_data().is_empty() else {}

func _open_overlay(title_text: String, subtitle_text: String, status_text: String, body_text: String, buttons: Array) -> void:
	_show_overlay_mode(OVERLAY_MODE_GENERIC)
	overlay_title.text = title_text
	overlay_subtitle.text = subtitle_text
	overlay_status.text = status_text
	overlay_body.text = body_text
	overlay_hint.text = "PRESS %s OR ESC TO CLOSE" % GameSettings.get_binding_label("interact")
	_overlay_action_handlers.clear()
	for i in range(overlay_action_buttons.size()):
		var button: Button = overlay_action_buttons[i]
		if i >= buttons.size():
			button.visible = false
			continue
		var data: Dictionary = buttons[i]
		button.visible = true
		button.text = str(data.get("text", "ACTION"))
		_overlay_action_handlers.append(data.get("callback", Callable()))
		FrontendStyle.apply_button_theme(
			button,
			bool(data.get("selected", false)),
			bool(data.get("disabled", false)),
			true
		)
	while _overlay_action_handlers.size() < overlay_action_buttons.size():
		_overlay_action_handlers.append(Callable())

func _on_overlay_action_pressed(index: int) -> void:
	if index < 0 or index >= _overlay_action_handlers.size():
		return
	AudioDirector.play_ui("ui_click")
	var handler: Callable = _overlay_action_handlers[index]
	if handler.is_valid():
		handler.call()

func _on_player_active_interactable_changed(interactable: HubInteractable) -> void:
	if _overlay_active:
		if interaction_prompt.has_method("clear_target"):
			interaction_prompt.call("clear_target")
		return
	if interactable == null:
		if interaction_prompt.has_method("clear_target"):
			interaction_prompt.call("clear_target")
		return
	if interaction_prompt.has_method("set_target"):
		interaction_prompt.call("set_target", interactable)

func _on_player_interact_requested(interactable: HubInteractable) -> void:
	if _overlay_active:
		return
	if interactable == null or not is_instance_valid(interactable):
		return
	interactable.interact(self, player)

func _apply_ui_theme() -> void:
	FrontendStyle.apply_panel_theme(overlay_panel, "overlay")
	FrontendStyle.apply_header(overlay_title, 24, Color(0.95, 0.82, 0.52, 1.0))
	FrontendStyle.apply_body(overlay_subtitle, 15, Color(0.88, 0.90, 0.94, 1.0))
	FrontendStyle.apply_small(overlay_status, 13, Color(0.92, 0.88, 0.72, 1.0))
	FrontendStyle.apply_body(overlay_body, 15, Color(0.90, 0.93, 0.96, 1.0))
	FrontendStyle.apply_small(overlay_hint, 13, Color(0.86, 0.88, 0.92, 1.0))
	var style: StyleBox = overlay_panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		flat.bg_color = Color(0.07, 0.10, 0.15, 1.0)
		flat.border_color = Color(0.62, 0.74, 0.88, 1.0)
		overlay_panel.add_theme_stylebox_override("panel", flat)
	overlay_backdrop.color = Color(0.01, 0.02, 0.04, 0.86)
	for button in overlay_action_buttons:
		FrontendStyle.apply_button_theme(button, false, false, true)
		button.visible = false
	if merchant_content != null:
		FrontendStyle.apply_header(merchant_title, 24, Color(0.95, 0.82, 0.52, 1.0))
		FrontendStyle.apply_body(merchant_subtitle, 15, Color(0.88, 0.90, 0.94, 1.0))
		FrontendStyle.apply_small(merchant_balance, 13, Color(0.92, 0.88, 0.72, 1.0))
		FrontendStyle.apply_panel_theme(merchant_icon_frame, "ability_orb")
		FrontendStyle.apply_header(merchant_item_name, 21, Color(0.95, 0.90, 0.82, 1.0))
		FrontendStyle.apply_body(merchant_item_description, 15, Color(0.90, 0.93, 0.96, 1.0))
		FrontendStyle.apply_small(merchant_owned, 13, Color(0.86, 0.88, 0.92, 1.0))
		FrontendStyle.apply_small(merchant_price, 13, Color(0.95, 0.82, 0.52, 1.0))
		FrontendStyle.apply_small(merchant_hint, 13, Color(0.86, 0.88, 0.92, 1.0))
		FrontendStyle.apply_button_theme(merchant_buy_button, false, false, true)
		FrontendStyle.apply_button_theme(merchant_close_button, false, false, true)
	if quest_scroll_fallback != null:
		quest_scroll_fallback.color = Color(0.90, 0.82, 0.64, 1.0)
	if quest_title != null:
		_apply_scroll_label_theme(quest_title, 26, Color(0.26, 0.14, 0.06, 1.0), 2)
		_apply_scroll_label_theme(quest_subtitle, 16, Color(0.40, 0.24, 0.10, 1.0), 1)
		_apply_scroll_label_theme(quest_body, 18, Color(0.26, 0.18, 0.10, 1.0), 1, true)
		_apply_scroll_label_theme(quest_hint, 13, Color(0.36, 0.24, 0.12, 1.0))
		FrontendStyle.apply_button_theme(quest_close_button, false, false, true)

func _show_overlay_mode(mode: String) -> void:
	var reopening_same_mode: bool = _overlay_active and _overlay_mode == mode
	_overlay_mode = mode
	_overlay_active = true
	center_overlay.visible = true
	overlay_backdrop.visible = true
	overlay_center.visible = true
	generic_content.visible = mode == OVERLAY_MODE_GENERIC
	overlay_panel.visible = mode != OVERLAY_MODE_QUEST
	if merchant_content != null:
		merchant_content.visible = mode == OVERLAY_MODE_MERCHANT
	if quest_scroll_root != null:
		quest_scroll_root.visible = mode == OVERLAY_MODE_QUEST
	if practice_runtime != null:
		practice_runtime.set_input_blocked(true)
	if interaction_prompt.has_method("clear_target"):
		interaction_prompt.call("clear_target")
	if not reopening_same_mode:
		AudioDirector.play_ui("ui_click")

func _on_practice_player_changed(next_player: HubCombatPlayer) -> void:
	if player != null and is_instance_valid(player):
		var previous_camera: Camera2D = player.get_camera()
		if previous_camera != null and previous_camera.has_method("clear_external_framing"):
			previous_camera.call("clear_external_framing")
		if player.active_interactable_changed.is_connected(_on_player_active_interactable_changed):
			player.active_interactable_changed.disconnect(_on_player_active_interactable_changed)
		if player.interact_requested.is_connected(_on_player_interact_requested):
			player.interact_requested.disconnect(_on_player_interact_requested)
	player = next_player
	_hub_camera_offset = HUB_CAMERA_IDLE_BIAS
	if player == null:
		return
	player.active_interactable_changed.connect(_on_player_active_interactable_changed)
	player.interact_requested.connect(_on_player_interact_requested)
	call_deferred("_sync_player_camera")

func _sync_player_camera() -> void:
	if player == null or not is_instance_valid(player):
		return
	var camera: Camera2D = player.get_camera()
	if camera == null or not is_instance_valid(camera):
		return
	camera.global_position = player.global_position
	camera.reset_smoothing()
	apply_camera_limits(camera)
	apply_hub_camera_zoom(camera)
	call_deferred("_apply_hub_camera_zoom_deferred")

func _build_overlay_views() -> void:
	if merchant_content == null:
		merchant_content = VBoxContainer.new()
		merchant_content.name = "MerchantContent"
		merchant_content.visible = false
		merchant_content.add_theme_constant_override("separation", 12)
		overlay_margin.add_child(merchant_content)

		merchant_title = _make_overlay_label(merchant_content, HORIZONTAL_ALIGNMENT_CENTER)
		merchant_subtitle = _make_overlay_label(merchant_content, HORIZONTAL_ALIGNMENT_CENTER)
		merchant_balance = _make_overlay_label(merchant_content, HORIZONTAL_ALIGNMENT_CENTER)

		var item_row: HBoxContainer = HBoxContainer.new()
		item_row.alignment = BoxContainer.ALIGNMENT_CENTER
		item_row.add_theme_constant_override("separation", 18)
		merchant_content.add_child(item_row)

		merchant_icon_frame = PanelContainer.new()
		merchant_icon_frame.custom_minimum_size = Vector2(120.0, 120.0)
		item_row.add_child(merchant_icon_frame)

		merchant_icon = TextureRect.new()
		merchant_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		merchant_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		merchant_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		merchant_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		merchant_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		merchant_icon_frame.add_child(merchant_icon)

		var item_info: VBoxContainer = VBoxContainer.new()
		item_info.custom_minimum_size = Vector2(420.0, 0.0)
		item_info.add_theme_constant_override("separation", 8)
		item_row.add_child(item_info)

		merchant_item_name = _make_overlay_label(item_info, HORIZONTAL_ALIGNMENT_LEFT)
		merchant_item_description = _make_overlay_label(item_info, HORIZONTAL_ALIGNMENT_LEFT)
		merchant_item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		merchant_owned = _make_overlay_label(item_info, HORIZONTAL_ALIGNMENT_LEFT)
		merchant_price = _make_overlay_label(item_info, HORIZONTAL_ALIGNMENT_LEFT)

		var merchant_actions: HBoxContainer = HBoxContainer.new()
		merchant_actions.alignment = BoxContainer.ALIGNMENT_CENTER
		merchant_actions.add_theme_constant_override("separation", 10)
		merchant_content.add_child(merchant_actions)

		merchant_buy_button = Button.new()
		merchant_buy_button.text = "BUY"
		merchant_buy_button.custom_minimum_size = Vector2(150.0, 44.0)
		merchant_buy_button.pressed.connect(_buy_merchant_item)
		merchant_buy_button.mouse_entered.connect(func() -> void: AudioDirector.play_ui("ui_hover", -4.0))
		merchant_actions.add_child(merchant_buy_button)

		merchant_close_button = Button.new()
		merchant_close_button.text = "CLOSE"
		merchant_close_button.custom_minimum_size = Vector2(150.0, 44.0)
		merchant_close_button.pressed.connect(close_overlay)
		merchant_close_button.mouse_entered.connect(func() -> void: AudioDirector.play_ui("ui_hover", -4.0))
		merchant_actions.add_child(merchant_close_button)

		merchant_hint = _make_overlay_label(merchant_content, HORIZONTAL_ALIGNMENT_CENTER)

	if quest_scroll_root == null:
		quest_scroll_root = Control.new()
		quest_scroll_root.name = "QuestScroll"
		quest_scroll_root.visible = false
		quest_scroll_root.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_scroll_root.custom_minimum_size = Vector2(520.0, 620.0)
		quest_scroll_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_center.add_child(quest_scroll_root)

		quest_scroll_underlay = ColorRect.new()
		quest_scroll_underlay.name = "Underlay"
		quest_scroll_underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_scroll_underlay.color = Color(0.01, 0.02, 0.04, 1.0)
		quest_scroll_underlay.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_scroll_underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		quest_scroll_root.add_child(quest_scroll_underlay)

		quest_scroll_fallback = ColorRect.new()
		quest_scroll_fallback.name = "FallbackParchment"
		quest_scroll_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_scroll_fallback.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_scroll_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		quest_scroll_root.add_child(quest_scroll_fallback)

		quest_scroll_background = TextureRect.new()
		quest_scroll_background.name = "Background"
		quest_scroll_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_scroll_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		quest_scroll_background.stretch_mode = TextureRect.STRETCH_SCALE
		quest_scroll_background.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_scroll_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		quest_scroll_root.add_child(quest_scroll_background)

		quest_scroll_margin = MarginContainer.new()
		quest_scroll_margin.name = "ScrollMargin"
		quest_scroll_margin.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_scroll_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		quest_scroll_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_scroll_root.add_child(quest_scroll_margin)

		var scroll_vbox: VBoxContainer = VBoxContainer.new()
		scroll_vbox.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_theme_constant_override("separation", 14)
		quest_scroll_margin.add_child(scroll_vbox)

		quest_title = _make_overlay_label(scroll_vbox, HORIZONTAL_ALIGNMENT_CENTER)
		quest_subtitle = _make_overlay_label(scroll_vbox, HORIZONTAL_ALIGNMENT_CENTER)
		quest_body = _make_overlay_label(scroll_vbox, HORIZONTAL_ALIGNMENT_CENTER)
		quest_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quest_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quest_body.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var quest_actions: HBoxContainer = HBoxContainer.new()
		quest_actions.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_actions.alignment = BoxContainer.ALIGNMENT_CENTER
		quest_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_child(quest_actions)

		quest_close_button = Button.new()
		quest_close_button.text = "CLOSE"
		quest_close_button.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
		quest_close_button.custom_minimum_size = Vector2(150.0, 44.0)
		quest_close_button.pressed.connect(close_overlay)
		quest_close_button.mouse_entered.connect(func() -> void: AudioDirector.play_ui("ui_hover", -4.0))
		quest_actions.add_child(quest_close_button)

		quest_hint = _make_overlay_label(scroll_vbox, HORIZONTAL_ALIGNMENT_CENTER)

func _make_overlay_label(parent: Node, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.layout_mode = CONTROL_LAYOUT_MODE_CONTAINER
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _apply_scroll_label_theme(label: Label, size: int, color: Color, outline: int = 1, autowrap: bool = false) -> void:
	if label == null:
		return
	FrontendStyle.apply_body(label, size, color)
	label.add_theme_color_override("font_outline_color", Color(0.96, 0.90, 0.78, 0.46))
	label.add_theme_constant_override("outline_size", outline)
	if autowrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _refresh_merchant_shop() -> void:
	var item_data: Dictionary = TownState.ITEM_DEFS.get(MERCHANT_ITEM_ID, {})
	if item_data.is_empty():
		merchant_title.text = "GENERAL GOODS"
		merchant_subtitle.text = "Town provisions and field supplies"
		merchant_balance.text = "COINS: %d" % TownState.get_coin_balance()
		merchant_item_name.text = "MERCHANT STOCK UNAVAILABLE"
		merchant_item_description.text = "This shop item is not configured right now."
		merchant_owned.text = "OWNED: 0"
		merchant_price.text = "PRICE: --"
		merchant_hint.text = "PRESS %s OR ESC TO CLOSE" % GameSettings.get_binding_label("interact")
		merchant_icon.texture = _load_optional_texture(POTION_ICON_PATH)
		FrontendStyle.apply_button_theme(merchant_buy_button, false, true, true)
		merchant_buy_button.disabled = true
		FrontendStyle.apply_button_theme(merchant_close_button, false, false, true)
		if merchant_close_button != null:
			merchant_close_button.grab_focus()
		return
	var item_label: String = str(item_data.get("label", "ITEM"))
	var price: int = int(item_data.get("price", 0))
	var owned: int = TownState.get_item_count(MERCHANT_ITEM_ID)
	var affordable: bool = TownState.can_afford(price)
	merchant_title.text = "GENERAL GOODS"
	merchant_subtitle.text = "Town provisions and field supplies"
	merchant_balance.text = "COINS: %d" % TownState.get_coin_balance()
	merchant_item_name.text = item_label
	merchant_item_description.text = str(item_data.get("description", ""))
	merchant_owned.text = "OWNED: %d" % owned
	merchant_price.text = "PRICE: %d COINS" % price
	merchant_hint.text = "CLICK BUY OR PRESS %s / ESC TO CLOSE" % GameSettings.get_binding_label("interact")
	merchant_icon.texture = _load_optional_texture(POTION_ICON_PATH)
	merchant_buy_button.disabled = not affordable
	FrontendStyle.apply_button_theme(merchant_buy_button, false, not affordable, true)
	FrontendStyle.apply_button_theme(merchant_close_button, false, false, true)
	if affordable:
		merchant_buy_button.grab_focus()
	elif merchant_close_button != null:
		merchant_close_button.grab_focus()

func _buy_merchant_item() -> void:
	if not TownState.purchase_item(MERCHANT_ITEM_ID):
		AudioDirector.play_ui("ui_error")
		return
	AudioDirector.play_ui("ui_confirm")
	_refresh_merchant_shop()

func _refresh_quest_scroll() -> void:
	if quest_title == null or quest_scroll_root == null or quest_scroll_margin == null:
		return
	quest_title.text = "QUEST SCROLL"
	quest_subtitle.text = "Available contracts from the guild"
	quest_body.text = _build_quest_scroll_body()
	quest_hint.text = "PRESS %s OR ESC TO CLOSE" % GameSettings.get_binding_label("interact")
	var background: Texture2D = _load_optional_texture(QUEST_SCROLL_PATH)
	quest_scroll_background.texture = background
	var has_texture: bool = background != null
	if quest_scroll_fallback != null:
		quest_scroll_fallback.visible = not has_texture
	const MAX_SCROLL_H: float = 620.0
	const FALLBACK_MIN_W: float = 520.0
	const FALLBACK_MIN_H: float = 560.0
	if has_texture and background != null:
		var sz: Vector2 = background.get_size()
		if sz.x > 1.0 and sz.y > 1.0:
			var h: float = MAX_SCROLL_H
			var w: float = h * (sz.x / sz.y)
			quest_scroll_root.custom_minimum_size = Vector2(w, h)
			var ml: int = int(round(clampf(0.11 * w, 28.0, 72.0)))
			var mt: int = int(round(clampf(0.175 * h, 88.0, 128.0)))
			var mb: int = int(round(clampf(0.125 * h, 56.0, 100.0)))
			quest_scroll_margin.add_theme_constant_override("margin_left", ml)
			quest_scroll_margin.add_theme_constant_override("margin_right", ml)
			quest_scroll_margin.add_theme_constant_override("margin_top", mt)
			quest_scroll_margin.add_theme_constant_override("margin_bottom", mb)
	else:
		quest_scroll_root.custom_minimum_size = Vector2(FALLBACK_MIN_W, FALLBACK_MIN_H)
		quest_scroll_margin.add_theme_constant_override("margin_left", 40)
		quest_scroll_margin.add_theme_constant_override("margin_right", 40)
		quest_scroll_margin.add_theme_constant_override("margin_top", 32)
		quest_scroll_margin.add_theme_constant_override("margin_bottom", 32)

func _build_quest_scroll_body() -> String:
	var parts: Array[String] = []
	for quest_data in TownState.get_available_quests():
		parts.append(str(quest_data.get("title", "")).to_upper())
		parts.append("Route: %s" % str(quest_data.get("location", "")))
		parts.append("Status: %s" % str(quest_data.get("status", "")))
		parts.append("")
		parts.append(str(quest_data.get("description", "")))
		parts.append("")
	var body: String = "\n".join(parts).strip_edges()
	if body.is_empty():
		return "No contracts have been posted yet."
	return body

func _load_optional_texture(resource_path: String) -> Texture2D:
	if resource_path == POTION_ICON_PATH and _potion_icon_texture != null:
		return _potion_icon_texture
	if resource_path == QUEST_SCROLL_PATH and _quest_scroll_texture != null:
		return _quest_scroll_texture
	var texture: Texture2D = null
	if FileAccess.file_exists(resource_path):
		var image: Image = Image.load_from_file(resource_path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture == null and ResourceLoader.exists(resource_path):
		texture = load(resource_path) as Texture2D
	if resource_path == POTION_ICON_PATH:
		_potion_icon_texture = texture
	elif resource_path == QUEST_SCROLL_PATH:
		_quest_scroll_texture = texture
	return texture

func _draw() -> void:
	_draw_cobble_floor()
	_draw_floor_warmth()
	_draw_dirt_paths()
	_draw_ground_contact()
	_draw_asset_grounding()

func _draw_floor_warmth() -> void:
	var floor_r: Rect2 = _floor_draw_rect()
	draw_rect(floor_r, Color(0.94, 0.88, 0.78, 0.07), true)


## Soft contact shadow / packed dirt under major props (matches EsseloriaHub positions).
func _draw_ground_contact() -> void:
	var base: Color = Color(0.18, 0.15, 0.12, 0.13)
	for patch in [
		{"position": HUB_CENTER + Vector2(0.0, 8.0), "radius": Vector2(118.0, 82.0), "color": base},
		{"position": PORTAL_POINT + Vector2(0.0, 22.0), "radius": Vector2(92.0, 52.0), "color": Color(0.18, 0.15, 0.12, 0.10)},
		{"position": Vector2(1390.0, 944.0), "radius": Vector2(128.0, 80.0), "color": Color(0.18, 0.15, 0.12, 0.10)},
		{"position": Vector2(680.0, 420.0), "radius": Vector2(106.0, 52.0), "color": Color(0.18, 0.15, 0.12, 0.08)},
		{"position": Vector2(1320.0, 408.0), "radius": Vector2(96.0, 48.0), "color": Color(0.18, 0.15, 0.12, 0.08)},
	]:
		_draw_soft_patch(patch["position"], patch["radius"], patch["color"])


func _draw_cobble_floor() -> void:
	if cobble_floor_texture == null:
		return
	var floor_r: Rect2 = _floor_draw_rect()
	var tex: Texture2D = cobble_floor_texture
	var src: Vector2 = tex.get_size()
	if src.x < 1.0 or src.y < 1.0:
		return
	var tw: float = float(cobble_tile_px) if cobble_tile_px > 0 else float(tex.get_width())
	var cols: int = int(ceil(floor_r.size.x / tw))
	var rows: int = int(ceil(floor_r.size.y / tw))
	for row in range(rows):
		for col in range(cols):
			var dest_pos: Vector2 = floor_r.position + Vector2(float(col) * tw, float(row) * tw)
			var dest: Rect2 = Rect2(dest_pos, Vector2(tw, tw))
			var clipped: Rect2 = dest.intersection(floor_r)
			if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
				continue
			var src_pos: Vector2 = clipped.position - dest_pos
			var src_rect: Rect2 = Rect2(src_pos * src / Vector2(tw, tw), clipped.size * src / Vector2(tw, tw))
			draw_texture_rect_region(tex, clipped, src_rect)


## Packed-earth tint between cobble paths (reference hub dirt between stones).
func _draw_dirt_paths() -> void:
	var dirt: Color = Color(0.38, 0.31, 0.22, 0.14)
	var moss: Color = Color(0.23, 0.29, 0.18, 0.05)
	var south_from: Vector2 = HUB_CENTER + Vector2(0.0, OUTER_RING_RADIUS)
	var south_to: Vector2 = PORTAL_POINT + Vector2(0.0, -52.0)
	_draw_path_strip(HUB_CENTER + Vector2(0.0, -OUTER_RING_RADIUS), HUB_CENTER + Vector2(0.0, -360.0), PATH_WIDTH + 24.0, dirt, dirt)
	_draw_path_strip(HUB_CENTER + Vector2(OUTER_RING_RADIUS, 0.0), HUB_CENTER + Vector2(360.0, 0.0), PATH_WIDTH + 24.0, dirt, dirt)
	_draw_path_strip(south_from, south_to, PATH_WIDTH + 36.0, dirt, dirt)
	_draw_path_strip(HUB_CENTER + Vector2(-OUTER_RING_RADIUS, 0.0), HUB_CENTER + Vector2(-360.0, 0.0), PATH_WIDTH + 24.0, dirt, dirt)
	for point in [
		HUB_CENTER + Vector2(-244.0, -294.0),
		HUB_CENTER + Vector2(292.0, -278.0),
		HUB_CENTER + Vector2(-404.0, 42.0),
		HUB_CENTER + Vector2(404.0, 46.0),
		PORTAL_POINT + Vector2(0.0, -6.0),
	]:
		_draw_soft_patch(point, Vector2(76.0, 28.0), moss)

func _draw_paths() -> void:
	# Cobblestone-style mid greys; south strip links statue to Ascension Portal.
	var path_color: Color = Color(0.34, 0.36, 0.42, 0.94)
	var path_highlight: Color = Color(0.62, 0.66, 0.72, 0.22)
	var south_from: Vector2 = HUB_CENTER + Vector2(0.0, OUTER_RING_RADIUS)
	var south_to: Vector2 = PORTAL_POINT + Vector2(0.0, -52.0)
	_draw_path_strip(HUB_CENTER + Vector2(0.0, -OUTER_RING_RADIUS), HUB_CENTER + Vector2(0.0, -360.0), PATH_WIDTH, path_color, path_highlight)
	_draw_path_strip(HUB_CENTER + Vector2(OUTER_RING_RADIUS, 0.0), HUB_CENTER + Vector2(360.0, 0.0), PATH_WIDTH, path_color, path_highlight)
	_draw_path_strip(south_from, south_to, PATH_WIDTH + 12.0, path_color, path_highlight)
	_draw_path_strip(HUB_CENTER + Vector2(-OUTER_RING_RADIUS, 0.0), HUB_CENTER + Vector2(-360.0, 0.0), PATH_WIDTH, path_color, path_highlight)

func _draw_central_plaza() -> void:
	for ring in range(5, 0, -1):
		var ratio: float = float(ring) / 5.0
		draw_circle(
			HUB_CENTER,
			PLAZA_RADIUS * ratio,
			Color(0.22 + 0.035 * ratio, 0.24 + 0.035 * ratio, 0.28 + 0.04 * ratio, 0.76)
		)
	_draw_octagon(HUB_CENTER, PLAZA_RADIUS + 34.0, Color(0.40, 0.44, 0.52, 0.32))
	_draw_octagon(HUB_CENTER, PLAZA_RADIUS + 10.0, Color(0.55, 0.60, 0.70, 0.14))
	# Clear ring under Virtue statue focal point (cobblestone plaza emphasis).
	draw_arc(HUB_CENTER, PLAZA_RADIUS + 2.0, 0.0, TAU, 64, Color(0.72, 0.78, 0.88, 0.26), 2.5)
	_draw_octagon(HUB_CENTER, 74.0, Color(0.64, 0.72, 0.82, 0.1))
	draw_circle(HUB_CENTER, 32.0, Color(0.82, 0.88, 0.96, 0.07))
	draw_arc(HUB_CENTER, 116.0, 0.0, TAU, 48, Color(0.78, 0.84, 0.92, 0.1), 2.0)

func _draw_anchor_spaces() -> void:
	# Light rim only; ground contact handles weight. Keep subtle path-adjacent hints.
	for point in [
		HUB_CENTER + Vector2(-280.0, -320.0),
		HUB_CENTER + Vector2(380.0, -280.0),
		HUB_CENTER + Vector2(-400.0, 40.0),
		PORTAL_POINT + Vector2(0.0, -20.0),
	]:
		draw_arc(point, 52.0, 0.0, TAU, 28, Color(0.5, 0.54, 0.6, 0.14), 1.5)

func _draw_outer_accents() -> void:
	# Keep plaza wear subtle so prop-specific grounding reads as intentional foundations.
	for patch in [
		{"position": HUB_CENTER + Vector2(-286.0, -164.0), "radius": Vector2(66.0, 38.0), "color": Color(0.22, 0.22, 0.24, 0.10)},
		{"position": HUB_CENTER + Vector2(292.0, -156.0), "radius": Vector2(62.0, 34.0), "color": Color(0.22, 0.22, 0.24, 0.09)},
		{"position": HUB_CENTER + Vector2(-300.0, 170.0), "radius": Vector2(60.0, 36.0), "color": Color(0.21, 0.21, 0.23, 0.09)},
		{"position": HUB_CENTER + Vector2(276.0, 176.0), "radius": Vector2(56.0, 34.0), "color": Color(0.21, 0.21, 0.23, 0.08)},
	]:
		_draw_soft_patch(patch.position, patch.radius, patch.color)

func _draw_asset_grounding() -> void:
	if _has_all_nodes([sign_arch, lantern_post_left, lantern_post_right]):
		_draw_north_gate_grounding(
			sign_arch.global_position,
			lantern_post_left.global_position,
			lantern_post_right.global_position
		)
	if _has_all_nodes([north_arrival_cargo_left, north_arrival_cargo_right]):
		_draw_north_arrival_grounding(north_arrival_cargo_left.global_position, north_arrival_cargo_right.global_position)
	if _has_all_nodes([merchant_area, merchant_stock, merchant_cargo, merchant_keeper]):
		_draw_merchant_grounding(
			merchant_area.global_position,
			merchant_stock.global_position,
			merchant_cargo.global_position,
			merchant_keeper.global_position
		)
	if _has_all_nodes([quest_building, quest_board, quest_notice_sign, quest_frontage_clutter]):
		_draw_quest_grounding(
			quest_building.global_position,
			quest_board.global_position,
			quest_notice_sign.global_position,
			quest_frontage_clutter.global_position
		)
	if weapon_station_one != null:
		_draw_weapon_station_grounding(weapon_station_one.global_position)
	if weapon_station_two != null:
		_draw_weapon_station_grounding(weapon_station_two.global_position)
	if _has_all_nodes([weapon_cache, weapon_cargo]):
		_draw_weapon_corner_grounding(weapon_cache.global_position, weapon_cargo.global_position)
	if _has_all_nodes([training_area, training_props]):
		_draw_training_grounding(training_area.global_position, training_props.global_position)
	_draw_stone_wall_grounding()
	_draw_canal_grounding()
	_draw_plaza_anchor_grounding()
	_draw_town_greenery_grounding()
	if virtue_statue != null:
		_draw_virtue_grounding(virtue_statue.global_position)
	if quest_giver != null:
		_draw_npc_grounding(quest_giver.global_position + Vector2(0.0, 18.0), Vector2(24.0, 10.0), 0.70)
	if trainee != null:
		_draw_npc_grounding(trainee.global_position + Vector2(0.0, 18.0), Vector2(20.0, 9.0), 0.62)
	if ascension_portal != null:
		_draw_portal_grounding(ascension_portal.global_position)

func _draw_north_gate_grounding(arch_position: Vector2, left_lantern_position: Vector2, right_lantern_position: Vector2) -> void:
	var arch_base: Vector2 = arch_position + Vector2(0.0, 58.0)
	_draw_cobble_transition_bed(arch_base + Vector2(0.0, 6.0), Vector2(110.0, 26.0), 1.15, 0.16)
	_draw_soft_patch(arch_base + Vector2(0.0, 12.0), Vector2(126.0, 34.0), Color(0.09, 0.07, 0.05, 0.10))
	for lantern_base in [left_lantern_position + Vector2(0.0, 18.0), right_lantern_position + Vector2(0.0, 18.0)]:
		_draw_cobble_transition_bed(lantern_base, Vector2(20.0, 8.0), 0.78, 0.06)
		_draw_soft_patch(lantern_base + Vector2(0.0, 2.0), Vector2(24.0, 10.0), Color(0.09, 0.07, 0.05, 0.08))

func _draw_north_arrival_grounding(left_position: Vector2, right_position: Vector2) -> void:
	_draw_cobble_transition_bed(left_position + Vector2(0.0, 18.0), Vector2(36.0, 12.0), 0.85, 0.35)
	_draw_cobble_transition_bed(right_position + Vector2(0.0, 18.0), Vector2(36.0, 12.0), 0.85, 0.35)
	_draw_soft_patch(left_position + Vector2(0.0, 18.0), Vector2(42.0, 16.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(right_position + Vector2(0.0, 18.0), Vector2(42.0, 16.0), Color(0.08, 0.06, 0.05, 0.08))

func _draw_merchant_grounding(
	position: Vector2,
	stock_position: Vector2,
	cargo_position: Vector2,
	keeper_position: Vector2
) -> void:
	var base: Vector2 = position + Vector2(18.0, 86.0)
	_draw_cobble_transition_bed(base + Vector2(0.0, 2.0), Vector2(74.0, 20.0), 0.95, 0.25)
	_draw_cobble_transition_bed(stock_position + Vector2(0.0, 18.0), Vector2(52.0, 13.0), 0.85, 0.22)
	_draw_cobble_transition_bed(cargo_position + Vector2(0.0, 16.0), Vector2(30.0, 11.0), 0.75, 0.18)
	_draw_soft_patch(base + Vector2(0.0, 4.0), Vector2(82.0, 26.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(stock_position + Vector2(0.0, 22.0), Vector2(66.0, 18.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(cargo_position + Vector2(0.0, 18.0), Vector2(40.0, 18.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(keeper_position + Vector2(0.0, 18.0), Vector2(22.0, 10.0), Color(0.08, 0.06, 0.05, 0.07))

func _draw_quest_grounding(
	building_position: Vector2,
	board_position: Vector2,
	sign_position: Vector2,
	clutter_position: Vector2
) -> void:
	var house_base: Vector2 = building_position + Vector2(0.0, 60.0)
	_draw_cobble_transition_bed(house_base + Vector2(0.0, 2.0), Vector2(76.0, 22.0), 1.0, 0.18)
	_draw_soft_patch(house_base + Vector2(0.0, 8.0), Vector2(86.0, 30.0), Color(0.08, 0.06, 0.05, 0.10))
	_draw_perspective_pad(
		house_base,
		Vector2(66.0, 16.0),
		10.0,
		Color(0.38, 0.34, 0.28, 0.14),
		Color(0.17, 0.14, 0.12, 0.18),
		Color(0.82, 0.72, 0.60, 0.07)
	)
	var board_base: Vector2 = board_position + Vector2(0.0, 22.0)
	_draw_cobble_transition_bed(board_base, Vector2(20.0, 8.0), 0.8, 0.0)
	_draw_soft_patch(board_base, Vector2(24.0, 12.0), Color(0.08, 0.06, 0.05, 0.08))
	draw_arc(board_base, 14.0, 0.0, TAU, 24, Color(0.74, 0.68, 0.58, 0.08), 1.2)
	_draw_cobble_transition_bed(sign_position + Vector2(0.0, 16.0), Vector2(24.0, 9.0), 0.7, 0.0)
	_draw_soft_patch(sign_position + Vector2(0.0, 18.0), Vector2(34.0, 14.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_cobble_transition_bed(clutter_position + Vector2(0.0, 15.0), Vector2(36.0, 12.0), 0.8, 0.16)
	_draw_soft_patch(clutter_position + Vector2(0.0, 18.0), Vector2(48.0, 18.0), Color(0.08, 0.06, 0.05, 0.08))

func _draw_weapon_station_grounding(position: Vector2) -> void:
	var base: Vector2 = position + Vector2(0.0, 40.0)
	_draw_cobble_transition_bed(base, Vector2(20.0, 10.0), 0.95, 0.0)
	_draw_soft_patch(base, Vector2(28.0, 15.0), Color(0.08, 0.06, 0.05, 0.09))
	draw_circle(base, 20.0, Color(0.34, 0.30, 0.26, 0.07))
	draw_arc(base, 20.0, 0.0, TAU, 28, Color(0.74, 0.68, 0.58, 0.08), 1.2)

func _draw_weapon_corner_grounding(cache_position: Vector2, cargo_position: Vector2) -> void:
	_draw_cobble_transition_bed(cache_position + Vector2(0.0, 18.0), Vector2(34.0, 12.0), 0.8, 0.12)
	_draw_cobble_transition_bed(cargo_position + Vector2(0.0, 16.0), Vector2(28.0, 10.0), 0.72, 0.08)
	_draw_soft_patch(cache_position + Vector2(0.0, 20.0), Vector2(44.0, 18.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(cargo_position + Vector2(0.0, 18.0), Vector2(38.0, 16.0), Color(0.08, 0.06, 0.05, 0.08))

func _draw_training_grounding(area_position: Vector2, props_position: Vector2) -> void:
	var base: Vector2 = area_position + Vector2(12.0, 20.0)
	_draw_cobble_transition_bed(base + Vector2(0.0, 12.0), Vector2(122.0, 28.0), 0.92, 0.10)
	_draw_cobble_transition_bed(props_position + Vector2(0.0, 18.0), Vector2(142.0, 22.0), 0.86, 0.12)
	_draw_soft_patch(base + Vector2(0.0, 20.0), Vector2(136.0, 42.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_soft_patch(props_position + Vector2(0.0, 24.0), Vector2(162.0, 36.0), Color(0.08, 0.06, 0.05, 0.07))

func _draw_stone_wall_grounding() -> void:
	if stone_walls == null:
		return
	for child in stone_walls.get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child as Sprite2D
		if sprite.texture == null:
			continue
		var scale_abs: Vector2 = Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
		var size: Vector2 = sprite.texture.get_size() * scale_abs
		var pad_radius: Vector2 = Vector2(maxf(38.0, size.x * 0.26), maxf(12.0, size.y * 0.18))
		var pad_offset: Vector2 = Vector2(0.0, maxf(8.0, size.y * 0.18))
		if size.y > size.x:
			pad_radius = Vector2(maxf(14.0, size.x * 0.18), maxf(60.0, size.y * 0.26))
			pad_offset = Vector2(0.0, maxf(10.0, size.y * 0.12))
		_draw_cobble_transition_bed(sprite.global_position + pad_offset, pad_radius * Vector2(0.76, 0.58), 0.72, 0.0)
		_draw_soft_patch(sprite.global_position + pad_offset, pad_radius, Color(0.08, 0.06, 0.05, 0.08))

func _draw_canal_grounding() -> void:
	if south_east_canal == null or canal_bridge == null:
		return
	var landing: Vector2 = canal_bridge.global_position + Vector2(0.0, 18.0)
	_draw_cobble_transition_bed(landing + Vector2(0.0, 4.0), Vector2(86.0, 19.0), 0.7, 0.0)
	_draw_soft_patch(landing + Vector2(0.0, 8.0), Vector2(96.0, 26.0), Color(0.08, 0.06, 0.05, 0.08))
	_draw_perspective_pad(
		landing,
		Vector2(88.0, 16.0),
		-4.0,
		Color(0.34, 0.32, 0.30, 0.16),
		Color(0.16, 0.15, 0.14, 0.18),
		Color(0.76, 0.76, 0.78, 0.06)
	)

func _draw_plaza_anchor_grounding() -> void:
	for point in _get_pillar_positions():
		_draw_cobble_transition_bed(point + Vector2(0.0, 14.0), Vector2(30.0, 12.0), 0.84, 0.0)
		_draw_soft_patch(point + Vector2(0.0, 18.0), Vector2(38.0, 18.0), Color(0.08, 0.06, 0.05, 0.09))

func _draw_virtue_grounding(position: Vector2) -> void:
	var base: Vector2 = position + Vector2(0.0, 34.0)
	_draw_cobble_transition_bed(base + Vector2(0.0, 6.0), Vector2(92.0, 30.0), 1.1, 0.10)
	_draw_soft_patch(base + Vector2(0.0, 10.0), Vector2(108.0, 40.0), Color(0.09, 0.07, 0.05, 0.11))
	_draw_perspective_pad(
		base + Vector2(0.0, 2.0),
		Vector2(78.0, 18.0),
		0.0,
		Color(0.32, 0.28, 0.24, 0.15),
		Color(0.16, 0.14, 0.12, 0.18),
		Color(0.78, 0.72, 0.64, 0.06)
	)

func _draw_npc_grounding(position: Vector2, half_size: Vector2, dirt_strength: float) -> void:
	_draw_cobble_transition_bed(position, half_size, dirt_strength, 0.0)
	_draw_soft_patch(position + Vector2(0.0, 2.0), half_size * Vector2(1.36, 1.18), Color(0.08, 0.06, 0.05, 0.07))

func _draw_town_greenery_grounding() -> void:
	if town_greenery == null:
		return
	_draw_greenery_grounding_from_node(town_greenery)

func _draw_greenery_grounding_from_node(node: Node) -> void:
	for child in node.get_children():
		if not (child is Node2D):
			continue
		var anchor: Node2D = child as Node2D
		var key: String = String(anchor.name).to_lower()
		if key.contains("tree"):
			_draw_tree_grounding(anchor)
		elif key.contains("shrub") or key.contains("bush"):
			_draw_cobble_transition_bed(anchor.global_position + Vector2(0.0, 6.0), Vector2(18.0, 8.0), 0.72, 0.40)
			_draw_soft_patch(anchor.global_position + Vector2(0.0, 8.0), Vector2(22.0, 10.0), Color(0.08, 0.06, 0.05, 0.08))
		elif key.contains("pot"):
			_draw_cobble_transition_bed(anchor.global_position + Vector2(0.0, 8.0), Vector2(12.0, 6.0), 0.6, 0.0)
			_draw_soft_patch(anchor.global_position + Vector2(0.0, 10.0), Vector2(16.0, 8.0), Color(0.08, 0.06, 0.05, 0.07))
		_draw_greenery_grounding_from_node(anchor)

func _draw_tree_grounding(anchor: Node2D) -> void:
	var tree_width: float = 84.0
	var tree_height: float = 120.0
	var sprite: Sprite2D = anchor.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.texture != null:
		var scale_abs: Vector2 = Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
		var sprite_size: Vector2 = sprite.texture.get_size() * scale_abs
		tree_width = maxf(56.0, sprite_size.x)
		tree_height = maxf(72.0, sprite_size.y)
	var pad_width: float = clampf(tree_width * 0.22, 30.0, 68.0)
	var pad_height: float = clampf(tree_height * 0.075, 12.0, 20.0)
	var root_center: Vector2 = anchor.global_position + Vector2(0.0, 8.0)
	_draw_tree_dirt_bed(root_center + Vector2(0.0, 6.0), pad_width, pad_height)
	_draw_cobble_transition_bed(root_center + Vector2(0.0, 5.0), Vector2(pad_width * 1.28, pad_height * 1.12), 1.35, 0.95)
	_draw_tree_cobble_transition(root_center, pad_width, pad_height)
	_draw_soft_patch(root_center + Vector2(0.0, 8.0), Vector2(pad_width * 1.35, pad_height * 1.55), Color(0.10, 0.07, 0.05, 0.11))
	_draw_perspective_pad(
		root_center + Vector2(0.0, 4.0),
		Vector2(pad_width, pad_height),
		6.0,
		Color(0.42, 0.33, 0.23, 0.16),
		Color(0.18, 0.13, 0.10, 0.20),
		Color(0.62, 0.50, 0.34, 0.08)
	)
	_draw_soft_patch(root_center + Vector2(-pad_width * 0.58, 2.0), Vector2(pad_width * 0.42, pad_height * 0.72), Color(0.22, 0.30, 0.16, 0.08))
	_draw_soft_patch(root_center + Vector2(pad_width * 0.54, 0.0), Vector2(pad_width * 0.38, pad_height * 0.68), Color(0.24, 0.32, 0.17, 0.07))
	_draw_soft_patch(root_center + Vector2(0.0, -4.0), Vector2(pad_width * 0.64, pad_height * 0.58), Color(0.36, 0.28, 0.20, 0.06))

func _draw_tree_dirt_bed(center: Vector2, pad_width: float, pad_height: float) -> void:
	var bed_radius: Vector2 = Vector2(pad_width * 1.18, pad_height * 1.34)
	_draw_soft_patch(center + Vector2(0.0, 2.0), bed_radius * Vector2(1.08, 1.12), Color(0.22, 0.16, 0.11, 0.12))
	_draw_soft_patch(center + Vector2(0.0, 4.0), bed_radius, Color(0.48, 0.37, 0.25, 0.20))
	_draw_soft_patch(center + Vector2(0.0, 1.0), bed_radius * Vector2(0.84, 0.78), Color(0.58, 0.44, 0.30, 0.14))
	_draw_soft_patch(center + Vector2(-pad_width * 0.72, -1.0), Vector2(pad_width * 0.32, pad_height * 0.42), Color(0.30, 0.38, 0.18, 0.09))
	_draw_soft_patch(center + Vector2(pad_width * 0.66, 0.0), Vector2(pad_width * 0.28, pad_height * 0.38), Color(0.28, 0.36, 0.18, 0.08))
	draw_arc(
		center + Vector2(0.0, 4.0),
		maxf(14.0, pad_width * 1.04),
		deg_to_rad(12.0),
		deg_to_rad(168.0),
		20,
		Color(0.70, 0.57, 0.41, 0.13),
		1.6,
		true
	)
	draw_arc(
		center + Vector2(0.0, 5.0),
		maxf(16.0, pad_width * 1.08),
		deg_to_rad(202.0),
		deg_to_rad(338.0),
		20,
		Color(0.31, 0.22, 0.16, 0.12),
		1.8,
		true
	)

func _draw_tree_cobble_transition(center: Vector2, pad_width: float, pad_height: float) -> void:
	var dirt_tint: Color = Color(0.42, 0.33, 0.23, 0.145)
	var moss_tint: Color = Color(0.22, 0.30, 0.17, 0.10)
	for ring in range(3):
		var radius_x: float = pad_width * (1.42 + 0.18 * float(ring))
		var radius_y: float = pad_height * (1.42 + 0.16 * float(ring))
		var alpha_scale: float = 1.0 - float(ring) * 0.2
		for segment in range(10):
			if segment % 3 == 1:
				continue
			var angle: float = TAU * float(segment) / 10.0 + float(ring) * 0.12
			var offset: Vector2 = Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
			var patch_center: Vector2 = center + offset * Vector2(1.0, 0.78) + Vector2(0.0, 5.0)
			var patch_radius: Vector2 = Vector2(
				maxf(6.0, pad_width * (0.16 - 0.018 * float(ring))),
				maxf(3.0, pad_height * (0.34 - 0.03 * float(ring)))
			)
			var tint: Color = dirt_tint if segment % 2 == 0 else moss_tint
			tint.a *= alpha_scale
			_draw_soft_patch(patch_center, patch_radius, tint)
	_draw_soft_patch(center + Vector2(-pad_width * 1.02, 7.0), Vector2(pad_width * 0.34, pad_height * 0.56), dirt_tint)
	_draw_soft_patch(center + Vector2(pad_width * 1.04, 9.0), Vector2(pad_width * 0.30, pad_height * 0.50), dirt_tint)
	_draw_soft_patch(center + Vector2(0.0, pad_height * 1.32), Vector2(pad_width * 0.58, pad_height * 0.54), Color(0.34, 0.27, 0.19, 0.11))

func _draw_cobble_transition_bed(center: Vector2, half_size: Vector2, dirt_strength: float = 1.0, moss_strength: float = 0.25) -> void:
	var dirt_tint: Color = Color(0.42, 0.33, 0.23, 0.115 * dirt_strength)
	var moss_tint: Color = Color(0.24, 0.31, 0.18, 0.075 * moss_strength)
	var offsets: Array[Vector2] = [
		Vector2(-1.10, -0.08),
		Vector2(1.12, -0.04),
		Vector2(-0.92, 0.42),
		Vector2(0.94, 0.46),
		Vector2(0.00, 0.80),
		Vector2(-0.34, -0.54),
		Vector2(0.38, -0.50),
	]
	for i in range(offsets.size()):
		var offset: Vector2 = offsets[i]
		var patch_center: Vector2 = center + Vector2(offset.x * half_size.x, offset.y * half_size.y) + Vector2(0.0, 4.0)
		var tint: Color = dirt_tint if i % 2 == 0 else moss_tint
		var radius_scale: Vector2 = Vector2(
			0.34 + 0.06 * float(i % 3),
			0.42 + 0.05 * float((i + 1) % 3)
		)
		_draw_soft_patch(
			patch_center,
			Vector2(maxf(6.0, half_size.x * radius_scale.x), maxf(3.0, half_size.y * radius_scale.y)),
			tint
		)
	_draw_soft_patch(center + Vector2(0.0, half_size.y * 0.18), Vector2(maxf(10.0, half_size.x * 0.54), maxf(4.0, half_size.y * 0.48)), Color(0.40, 0.32, 0.22, 0.08 * dirt_strength))
	_draw_soft_patch(center + Vector2(0.0, half_size.y * 0.96), Vector2(maxf(10.0, half_size.x * 0.62), maxf(4.0, half_size.y * 0.42)), Color(0.34, 0.27, 0.19, 0.075 * dirt_strength))

func _draw_portal_grounding(position: Vector2) -> void:
	var landing: Vector2 = position + Vector2(0.0, 38.0)
	_draw_cobble_transition_bed(landing + Vector2(0.0, 2.0), Vector2(94.0, 22.0), 0.95, 0.0)
	_draw_soft_patch(landing + Vector2(0.0, 9.0), Vector2(112.0, 34.0), Color(0.08, 0.07, 0.06, 0.11))
	_draw_perspective_pad(
		landing,
		Vector2(104.0, 20.0),
		0.0,
		Color(0.34, 0.32, 0.30, 0.18),
		Color(0.16, 0.15, 0.14, 0.20),
		Color(0.74, 0.76, 0.80, 0.08)
	)

func _draw_decor() -> void:
	for pillar_position in _get_pillar_positions():
		_draw_pillar(pillar_position)
	for planter_position in _get_planter_positions():
		_draw_planter(planter_position)
	for banner_position in [
		HUB_CENTER + Vector2(-240.0, -300.0),
		HUB_CENTER + Vector2(300.0, -260.0),
		HUB_CENTER + Vector2(-320.0, 40.0),
		HUB_CENTER + Vector2(0.0, 300.0),
	]:
		_draw_banner(banner_position)

func _draw_path_strip(from: Vector2, to: Vector2, width: float, fill: Color, highlight: Color) -> void:
	var direction: Vector2 = (to - from).normalized()
	var normal: Vector2 = direction.orthogonal() * width
	draw_colored_polygon(
		PackedVector2Array([
			from + normal,
			to + normal,
			to - normal,
			from - normal,
		]),
		fill
	)
	draw_line(from + normal * 0.84, to + normal * 0.84, highlight, 2.0, true)
	draw_line(from - normal * 0.84, to - normal * 0.84, highlight, 2.0, true)

func _draw_octagon(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(8):
		var angle: float = -PI * 0.5 + TAU * float(index) / 8.0
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	draw_polyline(points + PackedVector2Array([points[0]]), color, 3.0, true)

func _draw_soft_patch(position: Vector2, radius: Vector2, color: Color) -> void:
	for ring in range(4, 0, -1):
		var scale: float = float(ring) / 4.0
		var ring_color: Color = color
		ring_color.a *= 0.28 + 0.12 * float(5 - ring)
		var polygon: PackedVector2Array = PackedVector2Array()
		for point in range(18):
			var angle: float = TAU * float(point) / 18.0
			polygon.append(position + Vector2(cos(angle) * radius.x * scale, sin(angle) * radius.y * scale))
		draw_colored_polygon(polygon, ring_color)

func _draw_perspective_pad(center: Vector2, half_size: Vector2, skew: float, fill: Color, edge: Color, highlight: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(-half_size.x, -half_size.y),
		center + Vector2(half_size.x, -half_size.y + skew * 0.16),
		center + Vector2(half_size.x - skew * 0.45, half_size.y),
		center + Vector2(-half_size.x - skew * 0.45, half_size.y - skew * 0.16),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(points + PackedVector2Array([points[0]]), edge, 2.0, true)
	draw_line(
		points[3].lerp(points[2], 0.06),
		points[3].lerp(points[2], 0.94),
		highlight,
		1.4,
		true
	)

func _draw_pillar(position: Vector2) -> void:
	draw_circle(position + Vector2(0.0, 12.0), 22.0, Color(0.02, 0.03, 0.04, 0.22))
	draw_circle(position, 16.0, Color(0.56, 0.60, 0.68, 1.0))
	draw_circle(position + Vector2(0.0, -3.0), 10.0, Color(0.76, 0.82, 0.9, 0.18))
	draw_circle(position + Vector2(0.0, -19.0), 8.0, Color(0.84, 0.72, 0.42, 0.92))

func _draw_planter(position: Vector2) -> void:
	draw_circle(position + Vector2(0.0, 8.0), 26.0, Color(0.02, 0.03, 0.04, 0.18))
	draw_circle(position, 22.0, Color(0.22, 0.28, 0.32, 1.0))
	draw_circle(position, 17.0, Color(0.14, 0.20, 0.15, 0.96))
	for offset in [
		Vector2(-8.0, -4.0),
		Vector2(0.0, -9.0),
		Vector2(8.0, -3.0),
		Vector2(-5.0, 5.0),
		Vector2(6.0, 4.0),
	]:
		draw_circle(position + offset, 4.4, Color(0.28, 0.46, 0.30, 0.98))

func _draw_banner(position: Vector2) -> void:
	draw_line(position + Vector2(0.0, -28.0), position + Vector2(0.0, 22.0), Color(0.56, 0.60, 0.68, 1.0), 4.0, true)
	draw_rect(Rect2(position + Vector2(-10.0, -24.0), Vector2(20.0, 28.0)), Color(0.34, 0.38, 0.62, 0.96), true)
	draw_rect(Rect2(position + Vector2(-7.0, -20.0), Vector2(14.0, 20.0)), Color(0.84, 0.74, 0.44, 0.24), true)

func _get_pillar_positions() -> Array[Vector2]:
	return [
		HUB_CENTER + Vector2(-228.0, -228.0),
		HUB_CENTER + Vector2(228.0, -228.0),
		HUB_CENTER + Vector2(-228.0, 228.0),
		HUB_CENTER + Vector2(228.0, 228.0),
	]

func _get_planter_positions() -> Array[Vector2]:
	return [
		HUB_CENTER + Vector2(0.0, -168.0),
		HUB_CENTER + Vector2(168.0, 0.0),
		HUB_CENTER + Vector2(0.0, 168.0),
		HUB_CENTER + Vector2(-168.0, 0.0),
	]
