extends Node

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")
const TRAIL_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/TrailEffect.tscn")
const FALLING_TRUNK_SCENE: PackedScene = preload("res://scenes/effects/FallingTrunk.tscn")
const DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const CombatJuice = preload("res://scripts/systems/combat_juice.gd")
const CastTargeting = preload("res://scripts/systems/cast_targeting.gd")
const FrontendStyle = preload("res://scripts/ui/frontend_style.gd")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const POWER_SHOT_COOLDOWN_KEY: StringName = &"power_shot"
const DASH_COOLDOWN_KEY: StringName = &"dash"
const ARROW_VOLLEY_COOLDOWN_KEY: StringName = &"arrow_volley"

const PHASE_MOVEMENT: String = "movement"
const PHASE_PRIMARY: String = "primary"
const PHASE_POWER_SHOT: String = "power_shot"
const PHASE_ARROW_VOLLEY: String = "arrow_volley"
const PHASE_DASH: String = "dash"
const PHASE_SENTINEL: String = "sentinel"

@export var primary_attack_range: float = 350.0
@export var primary_fire_cooldown: float = 0.8
@export var power_shot_cooldown: float = 12.0
@export var arrow_volley_cooldown: float = 14.4
@export var dash_cooldown: float = 0.9
@export var dash_tutorial_radius: float = 72.0
@export var dash_tutorial_telegraph_duration: float = 0.85
@export var dash_tutorial_falling_duration: float = 0.38

@onready var world: Node2D = $World
@onready var arena: Node2D = $World/Arena
@onready var entities: Node2D = $World/Entities
@onready var player: CharacterBody2D = $World/Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var tutorial_title: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Title
@onready var tutorial_body: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Body
@onready var movement_keys_root: VBoxContainer = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys
@onready var tutorial_footer: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Footer
@onready var movement_key_panels: Dictionary = {
	"move_up": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/TopRow/WBox,
	"move_left": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/ABox,
	"move_down": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/SBox,
	"move_right": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/DBox,
}
@onready var movement_key_labels: Dictionary = {
	"move_up": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/TopRow/WBox/WLabel,
	"move_left": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/ABox/ALabel,
	"move_down": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/SBox/SLabel,
	"move_right": $UI/TutorialOverlay/TutorialPanel/Margin/VBox/MovementKeys/BottomRow/DBox/DLabel,
}
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner
@onready var power_shot_ability: Node2D = $World/Entities/Player/AbilityAnchor/PowerShot
@onready var arrow_volley_ability: Node2D = $World/Entities/Player/AbilityAnchor/ArrowVolley
@onready var sentinel_ability: Node2D = $World/Entities/Player/AbilityAnchor/Sentinel

var current_level: int = 1
var current_health: float = CombatBalance.PLAYER_MAX_HEALTH
var max_health: float = CombatBalance.PLAYER_MAX_HEALTH
var xp_percent: float = 0.0
var run_time: float = 0.0
var target_label: String = "Training Target"
var primary_mode_label: String = "READY"
var ability_one_label: String = "READY"
var ability_two_label: String = "READY"
var dash_label: String = "READY"
var ultimate_label: String = "100%"
var objective_state_label: String = "Tutorial"
var boss_status_label: String = ""
var objective_progress: float = 0.0
var progress_panel_title: String = "TUTORIAL"
var progress_panel_detail: String = ""
var progress_panel_value: float = 0.0
var upgrade_prompt: String = ""
var game_over_prompt: String = ""
var upgrade_choices_display: Array[Dictionary] = []
var selected_upgrade_index_display: int = -1
var ability_slot_data: Dictionary = {
	"primary": {"id": "primary", "action": "primary_fire", "key": "LMB", "targeting_type": "directional", "preview_kind": "line", "icon_id": "bow", "icon_asset_id": "archer_hunters_bow", "label": "Hunter's Bow", "summary": "Hold to fire; snaps toward nearby targets.", "detail": "Hunter's Bow teaches baseline combat with soft-lock assist toward the nearest enemy.", "state_text": "READY"},
	"ability_one": {"id": "ability_one", "action": "ability_1", "key": "Shift", "targeting_type": "directional", "preview_kind": "line", "icon_id": "power_shot", "icon_asset_id": "archer_power_shot", "label": "Power Shot", "summary": "Manual heavy shot toward the cursor.", "detail": "Power Shot uses manual aim for a precise burst when you press Shift.", "state_text": "READY"},
	"ability_two": {"id": "ability_two", "action": "ability_2", "key": "E", "targeting_type": "directional", "preview_kind": "cone", "icon_id": "arrow_volley", "icon_asset_id": "archer_arrow_volley", "label": "Arrow Volley", "summary": "Fan arrows toward the nearest threat.", "detail": "Arrow Volley snaps toward the nearest enemy for pack clears.", "state_text": "READY"},
	"dash": {"id": "dash", "action": "dash", "key": "SPACE", "targeting_type": "directional", "preview_kind": "dash", "icon_id": "dash", "icon_asset_id": "archer_dash", "label": "Dash", "summary": "Dash toward the cursor.", "detail": "Use Dash to cut angles and survive pressure during the run.", "state_text": "READY"},
	"ultimate": {"id": "ultimate", "action": "ultimate", "key": "R", "targeting_type": "instant", "preview_kind": "", "icon_id": "sentinel", "icon_asset_id": "archer_sentinel", "label": "Sentinel", "summary": "Charge-based hawk summon.", "detail": "Sentinel summons a hawk that hunts nearby enemies for a short window.", "state_text": "100%"},
}

var _phase_order: Array[String] = [
	PHASE_MOVEMENT,
	PHASE_PRIMARY,
	PHASE_POWER_SHOT,
	PHASE_ARROW_VOLLEY,
	PHASE_DASH,
	PHASE_SENTINEL,
]
var _current_target: Node2D
var _phase_index: int = 0
var _phase_intro_active: bool = false
var _phase_intro_override: String = ""
var _phase_entities: Array[Node2D] = []
var _dash_zone: Node2D
var _movement_input_seen: bool = false
var _power_shot_seen: bool = false
var _arrow_volley_seen: bool = false
var _sentinel_strike_seen: bool = false
var _completed: bool = false
var _manual_pause: bool = false
var _continue_input_released: bool = false
var _combat_juice: CombatJuice
var _pending_directional_action: String = ""
var _movement_phase_origin: Vector2 = Vector2.ZERO

var _phase_data: Dictionary = {
	PHASE_MOVEMENT: {
		"title": "Movement",
		"body": "Start with the keyboard movement loop first so the run teaches the live controls right away.",
		"footer": "Use WASD movement. Press Enter or click to begin.",
	},
	PHASE_PRIMARY: {
		"title": "Hunter's Bow",
		"body": "Hunter's Bow snaps toward the nearest target. Hold the basic attack to put shots into the dummy.",
		"footer": "Use the basic attack input. Press Enter or click to begin.",
	},
	PHASE_POWER_SHOT: {
		"title": "Power Shot",
		"body": "Power Shot is manual: aim with the cursor and press Shift to land the heavy piercing arrow.",
		"footer": "Use Shift for Power Shot. Press Enter or click to begin.",
	},
	PHASE_ARROW_VOLLEY: {
		"title": "Arrow Volley",
		"body": "Arrow Volley auto-aims toward the nearest enemy. Fire the cone so at least one volley arrow lands.",
		"footer": "Use the Arrow Volley input. Press Enter or click to begin.",
	},
	PHASE_DASH: {
		"title": "Dash",
		"body": "A trunk is about to crash down on your position. Movement is locked for this test, so aim away from the blast and Dash out before it lands.",
		"footer": "Use the Dash input before the trunk slams down. Press Enter or click to begin.",
	},
	PHASE_SENTINEL: {
		"title": "Sentinel",
		"body": "Sentinel is the manual commitment tool. Press R and let the hawk hunt the training pack for you.",
		"footer": "Press R and wait for Sentinel to land a strike. Press Enter or click to begin.",
	},
}

func _ready() -> void:
	AudioDirector.set_music_context("run")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	RunConfig.tutorial_requested = false
	if arena:
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	if entities:
		entities.process_mode = Node.PROCESS_MODE_PAUSABLE
	if projectiles:
		projectiles.process_mode = Node.PROCESS_MODE_PAUSABLE
	if effects:
		effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("Systems"):
		$Systems.process_mode = Node.PROCESS_MODE_PAUSABLE
	var ui_layer: CanvasLayer = get_node_or_null("UI")
	if ui_layer:
		ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	if arena.has_method("apply_camera_limits") and player.has_node("Camera2D"):
		arena.apply_camera_limits(player.get_node("Camera2D"))
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.bind_player(player)
		hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, POWER_SHOT_COOLDOWN_KEY, ARROW_VOLLEY_COOLDOWN_KEY, DASH_COOLDOWN_KEY, StringName())
		hud.bind_game(self)
	_combat_juice = CombatJuice.new()
	add_child(_combat_juice)
	_combat_juice.setup(player)
	_apply_tutorial_theme()
	_continue_input_released = false
	player.move_speed = 224.0
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_damaged.connect(_on_player_damaged)
	if sentinel_ability:
		sentinel_ability.current_charge = 0.0
		sentinel_ability.active_remaining = 0.0
	_start_phase(0)

func _exit_tree() -> void:
	_clear_combat_juice()

func _process(_delta: float) -> void:
	_update_continue_input_state()
	if Input.is_action_just_pressed("ui_cancel") and not _phase_intro_active and not _completed:
		if _cancel_pending_directional_cast():
			_update_status_labels()
			return
		request_toggle_pause()
	if _manual_pause:
		_clear_pending_directional_cast()
		return
	if _completed:
		_clear_pending_directional_cast()
		_update_status_labels()
		if _consume_continue_input():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")
		return
	if _phase_intro_active:
		_clear_pending_directional_cast()
		_update_status_labels()
		if _consume_continue_input():
			_phase_intro_active = false
			_sync_pause_state()
		return
	run_time += get_process_delta_time()
	current_health = float(player.get("health"))
	max_health = float(player.get("max_health"))
	if sentinel_ability:
		sentinel_ability.tick(get_process_delta_time())
	_update_targeting()
	_handle_combat()
	_update_phase_progress()
	_update_dash_state()
	_update_status_labels()

func _start_phase(index: int, intro_override: String = "") -> void:
	_phase_index = clamp(index, 0, _phase_order.size() - 1)
	_phase_intro_override = intro_override
	_continue_input_released = false
	_power_shot_seen = false
	_arrow_volley_seen = false
	_sentinel_strike_seen = false
	_clear_training_objects()
	_reset_player_to_center()
	_movement_phase_origin = player.global_position
	_reset_phase_inputs()
	_configure_phase_targets()
	_configure_phase_cooldowns()
	_phase_intro_active = true
	_sync_pause_state()
	_refresh_tutorial_overlay_text()
	_update_status_labels()

func _reset_phase_inputs() -> void:
	_movement_input_seen = false
	_clear_pending_directional_cast()
	if player.has_method("set_movement_input_enabled"):
		player.set_movement_input_enabled(_get_phase_id() != PHASE_DASH)
	if player.has_method("set_environment_force"):
		player.set_environment_force(Vector2.ZERO)

func _configure_phase_targets() -> void:
	match _get_phase_id():
		PHASE_PRIMARY:
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(520.0, 0.0), 65.0))
		PHASE_POWER_SHOT:
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(280.0, -10.0), 300.0))
		PHASE_ARROW_VOLLEY:
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(250.0, -45.0), 180.0))
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(300.0, 10.0), 190.0))
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(230.0, 70.0), 200.0))
		PHASE_DASH:
			_spawn_dash_zone()
		PHASE_SENTINEL:
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(220.0, -45.0), 70.0))
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(285.0, 0.0), 75.0))
			_phase_entities.append(_spawn_dummy(player.global_position + Vector2(235.0, 70.0), 80.0))

func _configure_phase_cooldowns() -> void:
	if cooldown_system == null:
		return
	cooldown_system.cooldowns.clear()
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, 999.0)
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, 999.0)
	cooldown_system.set_cooldown(DASH_COOLDOWN_KEY, 0.0)
	if sentinel_ability:
		sentinel_ability.current_charge = 0.0
		sentinel_ability.active_remaining = 0.0
	match _get_phase_id():
		PHASE_POWER_SHOT:
			cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, 0.0)
		PHASE_ARROW_VOLLEY:
			cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, 0.0)
		PHASE_DASH:
			cooldown_system.set_cooldown(DASH_COOLDOWN_KEY, 0.0)
		PHASE_SENTINEL:
			if sentinel_ability:
				sentinel_ability.current_charge = sentinel_ability.charge_required

func _reset_player_to_center() -> void:
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	if player.has_method("set_aim_target"):
		player.set_aim_target(player.global_position + Vector2.RIGHT * 200.0)
	if player.has_method("set_environment_force"):
		player.set_environment_force(Vector2.ZERO)
	if player.has_method("set_movement_input_enabled"):
		player.set_movement_input_enabled(true)
	player.clear_root()
	player.dash_remaining = 0.0
	player.velocity = Vector2.ZERO
	_movement_phase_origin = player.global_position

func _handle_combat() -> void:
	if GameSettings != null and GameSettings.uses_indicator_release_cast():
		_handle_indicator_release_combat()
	else:
		_clear_pending_directional_cast()
		_handle_quick_cast_combat()
	if _can_use_sentinel() and Input.is_action_just_pressed("ultimate") and sentinel_ability and sentinel_ability.activate():
		var hawk: Node2D = sentinel_ability.spawn_hawk(player, effects, CombatBalance.ARCHER_BASE_DAMAGE, _get_crit_chance(), 1.5)
		if hawk != null:
			if hawk.has_signal("strike"):
				hawk.connect("strike", Callable(self, "_on_sentinel_strike"))
			if hawk.has_signal("swoop"):
				hawk.connect("swoop", Callable(self, "_spawn_tutorial_trail"))

func _can_use_primary() -> bool:
	return _get_phase_id() in [PHASE_PRIMARY, PHASE_POWER_SHOT, PHASE_ARROW_VOLLEY, PHASE_SENTINEL]

func _can_use_power_shot() -> bool:
	return _get_phase_id() == PHASE_POWER_SHOT

func _can_use_arrow_volley() -> bool:
	return _get_phase_id() == PHASE_ARROW_VOLLEY

func _can_use_dash() -> bool:
	return _get_phase_id() == PHASE_DASH

func _can_use_sentinel() -> bool:
	return _get_phase_id() == PHASE_SENTINEL

func _should_auto_fire_primary() -> bool:
	if not _can_use_primary() or not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	return player.global_position.distance_squared_to(nearest.global_position) <= primary_attack_range * primary_attack_range

func _handle_quick_cast_combat() -> void:
	if _can_use_primary() and (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		_fire_primary_arrow()
	if _can_use_power_shot() and Input.is_action_just_pressed("ability_1") and cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY):
		_cast_power_shot()
	if _can_use_arrow_volley() and Input.is_action_just_pressed("ability_2") and cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		_cast_arrow_volley()
	if _can_use_dash() and Input.is_action_just_pressed("dash") and cooldown_system.is_ready(DASH_COOLDOWN_KEY):
		_cast_dash()

func _handle_indicator_release_combat() -> void:
	_pending_directional_action = CastTargeting.process_indicator_release_input(
		player,
		_pending_directional_action,
		CastTargeting.get_directional_actions(CastTargeting.CLASS_ARCHER),
		Callable(self, "_can_prepare_directional_cast"),
		Callable(self, "_build_directional_cast_preview"),
		Callable(self, "_execute_directional_cast")
	)

func _can_prepare_directional_cast(action_name: String) -> bool:
	match action_name:
		"primary_fire":
			return _can_use_primary() and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY)
		"ability_1":
			return _can_use_power_shot() and cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY)
		"ability_2":
			return _can_use_arrow_volley() and cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY)
		"dash":
			return _can_use_dash() and cooldown_system.is_ready(DASH_COOLDOWN_KEY)
	return false

func _cancel_pending_directional_cast() -> bool:
	if _pending_directional_action.is_empty():
		return false
	_clear_pending_directional_cast()
	return true

func _clear_pending_directional_cast() -> void:
	_pending_directional_action = ""
	CastTargeting.clear_player_preview(player)

func _execute_directional_cast(action_name: String) -> void:
	match action_name:
		"primary_fire":
			_fire_primary_arrow()
		"ability_1":
			_cast_power_shot()
		"ability_2":
			_cast_arrow_volley()
		"dash":
			_cast_dash()

func _build_directional_cast_preview(action_name: String) -> Dictionary:
	var direction: Vector2
	if action_name == "ability_1":
		direction = _get_manual_aim_direction()
	elif action_name == "primary_fire":
		direction = _get_primary_auto_aim_direction(player.get_muzzle_global_position())
	else:
		var origin: Vector2 = player.global_position
		if action_name == "ability_2":
			var ab: Node2D = player.get_node("AbilityAnchor") as Node2D
			if ab != null:
				origin = ab.global_position
		direction = _get_auto_aim_direction(origin)
	return CastTargeting.build_preview(
		CastTargeting.CLASS_ARCHER,
		action_name,
		{
			"direction": direction,
			"primary_range": primary_attack_range,
			"power_shot_range": primary_attack_range + 90.0,
			"volley_length": 220.0,
			"volley_spread_degrees": 26.0,
			"dash_length": float(player.get("dash_distance")) if _node_has_property(player, "dash_distance") else 170.0,
		}
	)

func _fire_primary_arrow() -> void:
	var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
	if shot == null:
		return
	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = _get_primary_auto_aim_direction(shot.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	shot.set("direction", direction)
	shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE)
	shot.set("speed", 500.0)
	shot.set("pierce_count", 0)
	shot.set("crit_chance", _get_crit_chance())
	shot.set("crit_multiplier", 1.5)
	shot.set("visual_style", "arrow")
	shot.set("attack_payload", {"impact_direction": direction, "hit_kind": "arrow"})
	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("arrow"))
	projectiles.add_child(shot)
	AudioDirector.play_sfx("bow_primary", -6.0)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, 0.8 / _get_attack_speed_multiplier())

func _cast_power_shot() -> bool:
	if power_shot_ability == null or not power_shot_ability.has_method("cast_in_direction"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var direction: Vector2 = _get_manual_aim_direction(ability_anchor.global_position)
	var shot: Area2D = power_shot_ability.cast_in_direction(ability_anchor, SNIPER_SCENE, projectiles, direction, CombatBalance.ARCHER_BASE_DAMAGE, 1.5)
	if shot == null:
		return false
	shot.set("visual_style", "power_arrow")
	shot.set("attack_payload", {"impact_direction": direction, "hit_kind": "power"})
	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("power"))
		shot.connect("hit", Callable(self, "_on_power_shot_hit"))
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, 12.0)
	AudioDirector.play_sfx("bow_power_shot", -4.5)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	return true

func _cast_arrow_volley() -> bool:
	if arrow_volley_ability == null or not arrow_volley_ability.has_method("cast_in_direction"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var direction: Vector2 = _get_auto_aim_direction(ability_anchor.global_position)
	var shots: Array[Area2D] = arrow_volley_ability.cast_in_direction(ability_anchor, BULLET_SCENE, projectiles, direction, CombatBalance.ARCHER_BASE_DAMAGE, _get_crit_chance(), 1.5)
	if shots.is_empty():
		return false
	for shot in shots:
		shot.set("attack_payload", {"impact_direction": Vector2(shot.get("direction")), "hit_kind": "volley"})
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("volley"))
			shot.connect("hit", Callable(self, "_on_arrow_volley_hit"))
	AudioDirector.play_sfx("bow_volley", -5.5)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, 14.4)
	return true

func _cast_dash() -> void:
	if not player.start_dash(_get_auto_aim_direction(player.global_position)):
		return
	AudioDirector.play_sfx("dash_archer", -5.0)
	cooldown_system.set_cooldown(DASH_COOLDOWN_KEY, 0.9)

func _update_targeting() -> void:
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	var aim_point: Vector2
	if nearest != null and is_instance_valid(nearest):
		_current_target = nearest
		aim_point = nearest.global_position
		var target_name: String = str(_current_target.get("display_name"))
		if target_name.is_empty():
			target_name = "Dummy"
		target_label = "%s (%.0f HP)" % [target_name, float(_current_target.get("health"))]
	else:
		_current_target = null
		target_label = "Auto Aim"
		var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if move.length_squared() > 0.01:
			aim_point = player.global_position + move.normalized() * 200.0
		else:
			aim_point = player.global_position + player.aim_direction * 200.0
	player.set_aim_target(aim_point)

func _update_phase_progress() -> void:
	match _get_phase_id():
		PHASE_MOVEMENT:
			_track_movement_inputs()
			objective_progress = 1.0 if _movement_input_seen else clampf(player.global_position.distance_to(_movement_phase_origin) / 80.0, 0.0, 1.0)
			if _movement_input_seen:
				_advance_phase()
		PHASE_PRIMARY:
			objective_progress = 1.0 if _are_phase_targets_cleared() else 0.35
			if _are_phase_targets_cleared():
				_advance_phase()
		PHASE_POWER_SHOT:
			objective_progress = 1.0 if _power_shot_seen else 0.25
			if _power_shot_seen:
				_advance_phase()
		PHASE_ARROW_VOLLEY:
			objective_progress = 1.0 if _arrow_volley_seen else 0.25
			if _arrow_volley_seen:
				_advance_phase()
		PHASE_DASH:
			objective_progress = 0.0
			_update_dash_phase()
		PHASE_SENTINEL:
			objective_progress = 1.0 if _sentinel_strike_seen else 0.0
			if _sentinel_strike_seen:
				_complete_tutorial()

func _track_movement_inputs() -> void:
	var movement_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var moved_distance: float = player.global_position.distance_to(_movement_phase_origin)
	if moved_distance >= 32.0 and (movement_input.length_squared() > 0.0001 or player.velocity.length_squared() > 1.0):
		_movement_input_seen = true

func _update_dash_phase() -> void:
	if _dash_zone == null or not is_instance_valid(_dash_zone):
		_spawn_dash_zone()
		return
	if _dash_zone.has_method("is_in_impact_phase") and bool(_dash_zone.call("is_in_impact_phase")):
		var radius: float = float(_dash_zone.call("get_radius")) if _dash_zone.has_method("get_radius") else dash_tutorial_radius
		var distance: float = player.global_position.distance_to(_dash_zone.global_position)
		if distance > radius:
			objective_progress = 1.0
			_advance_phase()
			return
		if _dash_zone.has_method("get_impact_elapsed") and float(_dash_zone.call("get_impact_elapsed")) >= 0.12:
			_restart_current_phase("Too slow. Press Enter or click, then dash out of the blast before it lands.")
			return

func _advance_phase() -> void:
	var next_index: int = _phase_index + 1
	if next_index >= _phase_order.size():
		_complete_tutorial()
		return
	_start_phase(next_index)

func _restart_current_phase(message: String) -> void:
	_start_phase(_phase_index, message)

func _complete_tutorial() -> void:
	_completed = true
	_continue_input_released = false
	_clear_pending_directional_cast()
	_clear_training_objects()
	_phase_intro_active = false
	_sync_pause_state()
	objective_state_label = "Tutorial Complete"
	objective_progress = 1.0
	tutorial_title.text = "Tutorial Complete"
	tutorial_body.text = "You have the core Archer loop: keyboard movement, soft-lock bow fire, manual Shift Power Shot, auto-aim Arrow Volley, Dash, and manual R Sentinel."
	tutorial_footer.text = "Press Enter or click to continue to map selection."

func _spawn_dummy(position: Vector2, health_amount: float) -> Node2D:
	var enemy: Node = spawner.spawn(DUMMY_ENEMY_SCENE, entities, position)
	if enemy == null:
		return null
	enemy.set("display_name", "Training Dummy")
	enemy.set("max_health", CombatBalance.scale(health_amount))
	enemy.set("health", CombatBalance.scale(health_amount))
	if enemy.has_signal("damage_feedback"):
		enemy.connect("damage_feedback", Callable(self, "_on_enemy_damage_feedback"))
	return enemy as Node2D

func _spawn_dash_zone() -> void:
	var zone: Node2D = FALLING_TRUNK_SCENE.instantiate() as Node2D
	if zone == null:
		return
	zone.set("impact_radius", dash_tutorial_radius)
	zone.set("damage", 0.0)
	zone.set("telegraph_duration", dash_tutorial_telegraph_duration)
	zone.set("falling_duration", dash_tutorial_falling_duration)
	if zone.has_method("setup"):
		zone.setup(player.global_position)
	effects.add_child(zone)
	_dash_zone = zone

func _are_phase_targets_cleared() -> bool:
	for enemy in _phase_entities:
		if enemy != null and is_instance_valid(enemy):
			return false
	return true

func _clear_training_objects() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	for child in projectiles.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	_phase_entities.clear()
	_current_target = null
	_dash_zone = null
	_clear_pending_directional_cast()

func _spawn_hit_feedback(at: Vector2, kind: String = "arrow") -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		if kind == "power":
			fx.configure(Color(1.0, 0.78, 0.3, 0.96), "power", 8.0, 28.0, 0.18)
		elif kind == "sentinel":
			fx.configure(Color(1.0, 0.9, 0.46, 0.94), "sentinel", 8.0, 24.0, 0.16)
		elif kind == "sniper":
			fx.configure(Color(0.88, 0.96, 1.0, 0.96), "heavy", 8.0, 28.0, 0.16)
		elif kind == "heavy":
			fx.configure(Color(1.0, 0.94, 0.74, 0.96), "heavy", 7.0, 26.0, 0.16)
		else:
			fx.configure(Color(1.0, 0.84, 0.4, 0.92), "arrow", 5.0, 22.0, 0.14)
	effects.add_child(fx)

func _spawn_death_feedback(at: Vector2) -> void:
	var fx: Node2D = DEATH_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.86, 0.54, 0.92), 6.0, 24.0, 0.22)
	effects.add_child(fx)

func _on_sentinel_strike(at: Vector2, _is_crit: bool) -> void:
	_sentinel_strike_seen = true
	_spawn_hit_feedback(at, "sentinel")

func _on_power_shot_hit(_at: Vector2) -> void:
	if _get_phase_id() == PHASE_POWER_SHOT:
		_power_shot_seen = true

func _on_arrow_volley_hit(_at: Vector2) -> void:
	if _get_phase_id() == PHASE_ARROW_VOLLEY:
		_arrow_volley_seen = true

func _on_enemy_damage_feedback(data: Dictionary) -> void:
	if bool(data.get("heavy_hit", false)) and not bool(data.get("suppress_impact_juice", false)):
		var kind: String = str(data.get("hit_kind", "arrow"))
		if kind not in ["power", "sentinel", "sniper"]:
			_spawn_hit_feedback(Vector2(data.get("world_position", Vector2.ZERO)), "heavy")
	if _combat_juice != null:
		_combat_juice.trigger_enemy_hit(data)

func _on_enemy_killed(enemy: Node) -> void:
	if enemy is Node2D:
		_spawn_death_feedback((enemy as Node2D).global_position)

func _on_player_damaged(amount: float) -> void:
	_spawn_hit_feedback(player.global_position, "arrow")
	if _combat_juice != null:
		_combat_juice.trigger_player_hit({
			"amount": amount,
		})

func _spawn_tutorial_trail(from: Vector2, to: Vector2, tint: Color, width: float) -> void:
	var fx: Node2D = TRAIL_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	if fx.has_method("setup"):
		fx.setup(Vector2.ZERO, to - from, tint, width)
	fx.global_position = from
	effects.add_child(fx)

func _spawn_arrow_shot_flash(at: Vector2) -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.9, 0.56, 0.82), "flash", 3.0, 10.0, 0.08)
	effects.add_child(fx)

func _get_attack_speed_multiplier() -> float:
	return 1.0

func _get_crit_chance() -> float:
	return 0.05

func request_toggle_pause() -> void:
	_manual_pause = not _manual_pause
	_sync_pause_state()

func request_resume_game() -> void:
	_manual_pause = false
	_sync_pause_state()

func request_return_to_menu() -> void:
	_clear_combat_juice()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func is_manual_pause_active() -> bool:
	return _manual_pause

func has_upgrade_overlay_active() -> bool:
	return false

func _sync_pause_state() -> void:
	if _manual_pause or _phase_intro_active:
		_clear_combat_juice()
	get_tree().paused = _manual_pause or _phase_intro_active

func _clear_combat_juice() -> void:
	if _combat_juice != null:
		_combat_juice.clear_state()

func _update_dash_state() -> void:
	var dash_remaining: float = float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY))
	dash_label = "READY" if dash_remaining <= 0.0 else "%.1fs" % dash_remaining

func _update_status_labels() -> void:
	var primary_remaining: float = float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY))
	var power_shot_remaining: float = float(cooldown_system.get_remaining(POWER_SHOT_COOLDOWN_KEY))
	var arrow_volley_remaining: float = float(cooldown_system.get_remaining(ARROW_VOLLEY_COOLDOWN_KEY))
	primary_mode_label = "READY" if primary_remaining <= 0.0 else "%.1fs" % primary_remaining
	ability_one_label = "READY" if power_shot_remaining <= 0.0 else "%.1fs" % power_shot_remaining
	ability_two_label = "READY" if arrow_volley_remaining <= 0.0 else "%.1fs" % arrow_volley_remaining
	if sentinel_ability and sentinel_ability.is_active():
		ultimate_label = "%.1fs" % sentinel_ability.get_remaining()
	else:
		var sentinel_pct: int = int(round(sentinel_ability.get_charge_pct() * 100.0)) if sentinel_ability else 0
		ultimate_label = "READY" if sentinel_ability and sentinel_ability.is_ready() else "%d%%" % sentinel_pct
	dash_label = "READY" if float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY)) <= 0.0 else "%.1fs" % float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY))
	ability_slot_data["primary"]["key"] = GameSettings.get_binding_label("primary_fire")
	ability_slot_data["ability_one"]["key"] = GameSettings.get_binding_label("ability_1")
	ability_slot_data["dash"]["key"] = GameSettings.get_binding_label("dash")
	ability_slot_data["ability_two"]["key"] = GameSettings.get_binding_label("ability_2")
	ability_slot_data["ultimate"]["key"] = GameSettings.get_binding_label("ultimate")
	ability_slot_data["primary"]["state_text"] = primary_mode_label
	ability_slot_data["ability_one"]["state_text"] = ability_one_label
	ability_slot_data["dash"]["state_text"] = dash_label
	ability_slot_data["ability_two"]["state_text"] = ability_two_label
	ability_slot_data["ultimate"]["state_text"] = ultimate_label
	ability_slot_data["primary"]["cooldown_show"] = primary_remaining > 0.0
	ability_slot_data["primary"]["cooldown_fill"] = clampf(primary_remaining / max(primary_fire_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["primary"]["cooldown_seconds"] = primary_remaining
	ability_slot_data["ability_one"]["cooldown_show"] = power_shot_remaining > 0.0
	ability_slot_data["ability_one"]["cooldown_fill"] = clampf(power_shot_remaining / max(power_shot_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["ability_one"]["cooldown_seconds"] = power_shot_remaining
	ability_slot_data["ability_two"]["cooldown_show"] = arrow_volley_remaining > 0.0
	ability_slot_data["ability_two"]["cooldown_fill"] = clampf(arrow_volley_remaining / max(arrow_volley_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["ability_two"]["cooldown_seconds"] = arrow_volley_remaining
	ability_slot_data["dash"]["cooldown_show"] = float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY)) > 0.0
	ability_slot_data["dash"]["cooldown_fill"] = clampf(float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY)) / max(dash_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["dash"]["cooldown_seconds"] = float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY))
	ability_slot_data["ultimate"]["cooldown_seconds"] = float(sentinel_ability.get_remaining()) if sentinel_ability != null and sentinel_ability.is_active() else 0.0
	_refresh_tutorial_overlay_text()
	objective_state_label = "Tutorial: %s" % str(_get_phase_definition().get("title", "Tutorial")) if not _completed else "Tutorial Complete"
	progress_panel_title = objective_state_label
	progress_panel_detail = tutorial_footer.text
	progress_panel_value = objective_progress

func _refresh_tutorial_overlay_text() -> void:
	if _completed:
		return
	var phase: Dictionary = _get_phase_definition()
	var footer_suffix: String = "Press Enter or click to begin." if _phase_intro_active else ""
	tutorial_title.text = str(phase.get("title", "Tutorial"))
	if movement_keys_root != null:
		movement_keys_root.visible = false
	match _get_phase_id():
		PHASE_MOVEMENT:
			if movement_keys_root != null:
				movement_keys_root.visible = true
			tutorial_body.text = "Move with %s. These are the live movement controls for the rest of the game." % _movement_binding_text()
			tutorial_footer.text = footer_suffix if _phase_intro_active else "Use %s to move somewhere in the arena." % _movement_binding_text()
		PHASE_DASH:
			tutorial_body.text = _phase_intro_override if not _phase_intro_override.is_empty() else str(phase.get("body", ""))
			tutorial_footer.text = _phase_intro_footer_text() if _phase_intro_active else "Aim away from the blast, then press %s." % _binding_label("dash")
		_:
			tutorial_body.text = _phase_intro_override if not _phase_intro_override.is_empty() else _phase_body_text()
			tutorial_footer.text = _phase_intro_footer_text() if _phase_intro_active else _phase_active_footer_text()

func _get_phase_id() -> String:
	return _phase_order[_phase_index]

func _get_phase_definition() -> Dictionary:
	return _phase_data.get(_get_phase_id(), {})

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			list.append(enemy)
	list.sort_custom(func(a, b): return origin.distance_squared_to((a as Node2D).global_position) < origin.distance_squared_to((b as Node2D).global_position))
	return list

func _get_cursor_world_position() -> Vector2:
	return player.get_global_mouse_position()

func _get_cursor_direction(from_position: Vector2 = Vector2.INF) -> Vector2:
	var origin: Vector2 = from_position if from_position != Vector2.INF else player.global_position
	var direction: Vector2 = origin.direction_to(_get_cursor_world_position())
	if direction.length_squared() <= 0.0001:
		direction = player.aim_direction if player.aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	return direction.normalized()

func _get_manual_aim_direction(from_position: Vector2 = Vector2.INF) -> Vector2:
	return _get_cursor_direction(from_position)

func _get_auto_aim_direction(from_position: Vector2) -> Vector2:
	var target: Node2D = _find_nearest_enemy(from_position)
	if target != null and is_instance_valid(target):
		var dir: Vector2 = from_position.direction_to(target.global_position)
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	return _get_cursor_direction(from_position)

func _get_primary_auto_aim_direction(from_position: Vector2) -> Vector2:
	var target: Node2D = _find_nearest_enemy(from_position)
	if target != null and is_instance_valid(target):
		var dir: Vector2 = from_position.direction_to(target.global_position)
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length_squared() > 0.01:
		return move.normalized()
	if player.aim_direction.length_squared() > 0.0001:
		return player.aim_direction.normalized()
	return Vector2.RIGHT

func _find_nearest_enemy(origin: Vector2) -> Node2D:
	var enemies: Array[Node2D] = _get_sorted_enemies_by_distance(origin)
	return enemies[0] if not enemies.is_empty() else null

func _find_hovered_enemy(cursor_world: Vector2) -> Node2D:
	var enemies: Array[Node2D] = _get_sorted_enemies_by_distance(cursor_world)
	if enemies.is_empty():
		return null
	var best: Node2D = enemies[0]
	if cursor_world.distance_squared_to(best.global_position) > 120.0 * 120.0:
		return null
	return best

func _binding_label(action_name: String) -> String:
	return GameSettings.get_binding_label(action_name)

func _movement_binding_text() -> String:
	return "%s / %s / %s / %s" % [
		_binding_label("move_up"),
		_binding_label("move_left"),
		_binding_label("move_down"),
		_binding_label("move_right"),
	]

func _phase_body_text() -> String:
	match _get_phase_id():
		PHASE_PRIMARY:
			return "Hold %s to fire Hunter's Bow toward the nearest target." % _binding_label("primary_fire")
		PHASE_POWER_SHOT:
			return "Aim with the cursor and press %s for a manual Power Shot." % _binding_label("ability_1")
		PHASE_ARROW_VOLLEY:
			return "Press %s to fan Arrow Volley toward the nearest enemies." % _binding_label("ability_2")
		PHASE_SENTINEL:
			return "Sentinel is the manual commitment tool. Press %s and let the hawk hunt the training pack for you." % _binding_label("ultimate")
	return str(_get_phase_definition().get("body", ""))

func _phase_active_footer_text() -> String:
	match _get_phase_id():
		PHASE_PRIMARY:
			return "Hold %s to fire toward the soft-locked target." % _binding_label("primary_fire")
		PHASE_POWER_SHOT:
			return "Aim, then press %s for Power Shot." % _binding_label("ability_1")
		PHASE_ARROW_VOLLEY:
			return "Press %s to volley toward nearby enemies." % _binding_label("ability_2")
		PHASE_SENTINEL:
			return "Press %s and wait for Sentinel to land a strike." % _binding_label("ultimate")
	return str(_get_phase_definition().get("footer", ""))

func _phase_intro_footer_text() -> String:
	match _get_phase_id():
		PHASE_MOVEMENT:
			return "Use %s to move. Press Enter or click to begin." % _movement_binding_text()
		PHASE_PRIMARY:
			return "Use %s to fire. Press Enter or click to begin." % _binding_label("primary_fire")
		PHASE_POWER_SHOT:
			return "Use %s to cast Power Shot. Press Enter or click to begin." % _binding_label("ability_1")
		PHASE_ARROW_VOLLEY:
			return "Use %s to cast Arrow Volley. Press Enter or click to begin." % _binding_label("ability_2")
		PHASE_DASH:
			return "Use %s before the trunk lands. Press Enter or click to begin." % _binding_label("dash")
		PHASE_SENTINEL:
			return "Use %s and wait for a strike. Press Enter or click to begin." % _binding_label("ultimate")
	return str(_get_phase_definition().get("footer", ""))

func _update_continue_input_state() -> void:
	if not _is_continue_input_down():
		_continue_input_released = true

func _consume_continue_input() -> bool:
	if not _continue_input_released:
		return false
	if not _is_continue_input_down():
		return false
	_continue_input_released = false
	return true

func _is_continue_input_down() -> bool:
	return Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _apply_tutorial_theme() -> void:
	FrontendStyle.apply_header(tutorial_title, 22, Color(1.0, 1.0, 1.0, 1.0))
	FrontendStyle.apply_body(tutorial_body, 15, Color(0.98, 0.99, 1.0, 1.0))
	FrontendStyle.apply_body(tutorial_footer, 14, Color(0.95, 0.97, 1.0, 1.0))
	for key_label in movement_key_labels.values():
		FrontendStyle.apply_header(key_label, 18, Color(1.0, 1.0, 1.0, 1.0))
	_refresh_movement_key_boxes()

func _refresh_movement_key_boxes() -> void:
	for action_name in movement_key_labels.keys():
		var label: Label = movement_key_labels[action_name] as Label
		if label != null:
			label.text = _binding_label(String(action_name))

func _make_movement_key_style(active: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.72, 0.32, 0.96) if active else Color(0.08, 0.12, 0.18, 0.96)
	style.border_color = Color(0.74, 1.0, 0.80, 1.0) if active else Color(0.40, 0.52, 0.68, 1.0)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style

func _node_has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.name) == property_name:
			return true
	return false
