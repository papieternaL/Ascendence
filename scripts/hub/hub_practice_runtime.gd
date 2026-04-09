class_name HubPracticeRuntime
extends Node

signal player_changed(player: HubCombatPlayer)

const HUB_RECT: Rect2 = Rect2(80.0, 120.0, 1840.0, 1000.0)

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const CastTargeting = preload("res://scripts/systems/cast_targeting.gd")

const ARCHER_PLAYER_SCENE: PackedScene = preload("res://scenes/hub/HubArcherPlayer.tscn")
const ARCANE_PLAYER_SCENE: PackedScene = preload("res://scenes/hub/HubArcanePistolPlayer.tscn")
const TRAINING_DUMMY_SCENE: PackedScene = preload("res://scenes/hub/TrainingDummy.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/projectiles/Missile.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const ARCANE_BOMB_PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/ArcaneBombProjectile.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const POWER_SHOT_COOLDOWN_KEY: StringName = &"power_shot"
const DASH_COOLDOWN_KEY: StringName = &"dash"
const ARROW_VOLLEY_COOLDOWN_KEY: StringName = &"arrow_volley"
const BLINK_COOLDOWN_KEY: StringName = &"arcane_blink"
const MISSILES_COOLDOWN_KEY: StringName = &"arcane_missiles"
const BOMB_COOLDOWN_KEY: StringName = &"arcane_bomb"
const ULTIMATE_COOLDOWN_KEY: StringName = &"arcane_sniper"

const ARCHER_BASE_MOVE_SPEED: float = 224.0
const ARCANE_BASE_MOVE_SPEED: float = 180.0
const ARCHER_PRIMARY_RANGE: float = 350.0
const ARCANE_PRIMARY_RANGE: float = 520.0
const ARCHER_PRIMARY_COOLDOWN: float = 0.8
const ARCHER_DASH_COOLDOWN: float = 0.9
const ARCHER_POWER_SHOT_COOLDOWN: float = 12.0
const ARCHER_ARROW_VOLLEY_COOLDOWN: float = 14.4
const ARCANE_PRIMARY_COOLDOWN: float = 0.25
const ARCANE_BLINK_COOLDOWN: float = 1.2
const ARCANE_MISSILES_COOLDOWN: float = 5.0
const ARCANE_BOMB_COOLDOWN: float = 8.0
const ARCANE_SNIPER_COOLDOWN: float = 18.0
const ARCANE_SNIPER_DURATION: float = 7.0

@onready var entities: Node2D = $"../Entities"
@onready var projectiles: Node2D = $"../Projectiles"
@onready var effects: Node2D = $"../Effects"
@onready var hud: Control = $"../UI/HUD"
@onready var cooldown_system: Node = $"../Systems/CooldownSystem"
@onready var training_dummy_spawn: Marker2D = $"../PracticeDummySpawn"

var hud_mode: String = "hub"
var current_level: int = 1
var xp_percent: float = 0.0
var run_time: float = 0.0
var primary_mode_label: String = "READY"
var ability_one_label: String = "READY"
var dash_label: String = "READY"
var ability_two_label: String = "READY"
var ultimate_label: String = "READY"
var objective_state_label: String = "Hub Training"
var boss_status_label: String = ""
var objective_progress: float = 0.0
var progress_panel_title: String = "TRAINING"
var progress_panel_detail: String = "Practice your loadout"
var progress_panel_value: float = 0.0
var progress_bar_mode: String = "thresholds"
var progress_threshold_markers: Array[float] = []
var progress_bar_show_markers: bool = false
var objective_hud_visible: bool = false
var objective_hud_headline: String = ""
var objective_hud_progress_line: String = ""
var objective_hud_timer_line: String = ""
var game_over_prompt: String = ""
var profile_data: Dictionary = {}
var upgrade_prompt: String = ""
var upgrade_overlay_title: String = ""
var upgrade_choices_display: Array[Dictionary] = []
var selected_upgrade_index_display: int = -1
var upgrade_display_version: int = 0
var ability_slot_data: Dictionary = {}
var _manual_pause: bool = false
var _profile_overlay_open: bool = false

var player: HubCombatPlayer

var _active_class_id: String = ""
var _current_target: Node2D
var _input_blocked: bool = false
var _inventory_overlay_open: bool = false
var _pending_directional_action: String = ""

var _power_shot_ability: Node2D
var _arrow_volley_ability: Node2D
var _sentinel_ability: Node2D
var _arcane_missiles_ability: Node2D
var _arcane_bomb_ability: Node2D
var _arcane_sniper_ability: Node2D

var _dash_charge_count: int = 1
var _dash_charge_max: int = 1
var _dash_recharge_timer: float = 0.0
var _sniper_remaining: float = 0.0

func setup_practice(spawn_position: Vector2) -> void:
	_reset_hub_runtime_state()
	_spawn_or_reload_player(spawn_position)
	_spawn_training_dummy()
	_bind_hud()
	_update_status_cache()

func reload_selected_class(spawn_position: Vector2) -> void:
	_spawn_or_reload_player(spawn_position)
	_bind_hud()
	_update_status_cache()

func get_player() -> HubCombatPlayer:
	return player

func set_input_blocked(blocked: bool) -> void:
	_input_blocked = blocked
	if blocked:
		_clear_pending_directional_cast()
	if player != null and is_instance_valid(player):
		player.set_movement_enabled(not blocked)

func is_input_blocked() -> bool:
	return _input_blocked

func is_manual_pause_active() -> bool:
	return _manual_pause

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_tick_class_runtime(delta)
	if Input.is_action_just_pressed("ui_cancel"):
		if _inventory_overlay_open:
			request_close_inventory()
			_update_status_cache()
			return
		_clear_pending_directional_cast()
	if Input.is_action_just_pressed("inventory"):
		request_toggle_inventory()
	for slot_idx in range(4):
		if Input.is_action_just_pressed("item_slot_%d" % (slot_idx + 1)):
			_use_hotbar_slot(slot_idx)
	if _manual_pause:
		_update_status_cache()
		return
	if _input_blocked:
		_update_status_cache()
		return
	if _inventory_overlay_open:
		_update_status_cache()
		return
	run_time += delta
	player.set_aim_target(player.get_global_mouse_position())
	_update_targeting()
	_handle_combat_input()
	player.global_position = _clamp_to_hub_rect(player.global_position)
	_update_status_cache()

func _spawn_or_reload_player(spawn_position: Vector2) -> void:
	var next_class_id: String = RunConfig.selected_class_id
	if next_class_id != RunConfig.CLASS_ARCANE_PISTOL:
		next_class_id = RunConfig.CLASS_ARCHER
	_active_class_id = next_class_id
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = (_player_scene_for_class(_active_class_id).instantiate() as HubCombatPlayer)
	if player == null:
		return
	player.global_position = _clamp_to_hub_rect(spawn_position)
	entities.add_child(player)
	entities.move_child(player, 0)
	player.global_position = _resolve_safe_spawn_position(player.global_position)
	_resolve_ability_nodes()
	_configure_player_for_class()
	player.set_movement_enabled(not _input_blocked)
	player_changed.emit(player)

func _player_scene_for_class(class_id: String) -> PackedScene:
	return ARCANE_PLAYER_SCENE if class_id == RunConfig.CLASS_ARCANE_PISTOL else ARCHER_PLAYER_SCENE

func _resolve_ability_nodes() -> void:
	_power_shot_ability = player.get_node_or_null("AbilityAnchor/PowerShot") as Node2D
	_arrow_volley_ability = player.get_node_or_null("AbilityAnchor/ArrowVolley") as Node2D
	_sentinel_ability = player.get_node_or_null("AbilityAnchor/Sentinel") as Node2D
	_arcane_missiles_ability = player.get_node_or_null("AbilityAnchor/ArcaneMissiles") as Node2D
	_arcane_bomb_ability = player.get_node_or_null("AbilityAnchor/ArcaneBomb") as Node2D
	_arcane_sniper_ability = player.get_node_or_null("AbilityAnchor/ArcaneSniper") as Node2D

func _configure_player_for_class() -> void:
	if player == null:
		return
	if cooldown_system != null and cooldown_system.get("cooldowns") != null:
		cooldown_system.set("cooldowns", {})
	for child in projectiles.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	_current_target = null
	run_time = 0.0
	xp_percent = 0.0
	current_level = 1
	_dash_charge_max = 1
	_dash_charge_count = 1
	_dash_recharge_timer = 0.0
	_sniper_remaining = 0.0
	_clear_pending_directional_cast()
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		player.move_speed = ARCANE_BASE_MOVE_SPEED
		player.weapon_style = "pistol"
		ability_slot_data = {
			"primary": {"id": "primary", "action": "primary_fire", "key": "LMB", "targeting_type": "directional", "preview_kind": "line", "icon_id": "pistol", "icon_asset_id": "arcane_pistol_primary", "label": "Arcane Pistol", "summary": "Fire magical rounds toward the cursor.", "detail": "Arcane Pistol fires precise magical shots in the aimed direction. Sniper mode upgrades those shots into heavy piercing rounds.", "state_text": "READY"},
			"ability_one": {"id": "ability_one", "action": "ability_1", "key": "Q", "targeting_type": "directional", "preview_kind": "fan", "icon_id": "missiles", "icon_asset_id": "arcane_missiles", "label": "Arcane Missiles", "summary": "Lock one target and fire a homing volley.", "detail": "Arcane Missiles locks onto one enemy near the cursor, then sends the full volley into that target. If the cursor is not near an enemy, it falls back to your current soft-lock or nearest foe.", "state_text": "READY"},
			"ability_two": {"id": "ability_two", "action": "ability_2", "key": "E", "targeting_type": "directional", "preview_kind": "lob_line", "icon_id": "arcane", "icon_asset_id": "arcane_bomb", "label": "Arcane Bomb", "summary": "Lob a glowing bomb forward into a damage field.", "detail": "Arcane Bomb throws a volatile charge in the aimed direction. It bursts into a lingering zone that damages and lightly slows enemies inside it.", "state_text": "READY"},
			"dash": {"id": "dash", "action": "dash", "key": "SPACE", "targeting_type": "directional", "preview_kind": "dash", "icon_id": "blink", "icon_asset_id": "arcane_blink", "label": "Arcane Blink", "summary": "Blink toward the cursor.", "detail": "Blink keeps the gunslinger evasive and opens clean firing angles without breaking ranged spacing.", "state_text": "READY"},
			"ultimate": {"id": "ultimate", "action": "ultimate", "key": "R", "targeting_type": "instant", "preview_kind": "", "icon_id": "sniper", "icon_asset_id": "arcane_sniper", "label": "Arcane Sniper", "summary": "Enter a timed sniper stance.", "detail": "Arcane Sniper replaces base shots with slower, harder-hitting piercing rounds for a short window.", "state_text": "READY"},
		}
		if _arcane_sniper_ability != null:
			_arcane_sniper_ability.set("duration", ARCANE_SNIPER_DURATION)
			_arcane_sniper_ability.set("cooldown", ARCANE_SNIPER_COOLDOWN)
	else:
		player.move_speed = ARCHER_BASE_MOVE_SPEED
		player.weapon_style = "bow"
		ability_slot_data = {
			"primary": {"id": "primary", "action": "primary_fire", "key": "LMB", "targeting_type": "directional", "preview_kind": "line", "icon_id": "bow", "icon_asset_id": "archer_hunters_bow", "label": "Hunter's Bow", "summary": "Manual bow shots toward the cursor.", "detail": "Hunter's Bow keeps the Archer's baseline attack fully cursor-driven in hub practice.", "state_text": "READY"},
			"ability_one": {"id": "ability_one", "action": "ability_1", "key": "Q", "targeting_type": "directional", "preview_kind": "line", "icon_id": "power_shot", "icon_asset_id": "archer_power_shot", "label": "Power Shot", "summary": "Fire a heavy piercing arrow toward the cursor.", "detail": "Power Shot fires a guaranteed-critical piercing arrow in the aimed direction.", "state_text": "READY"},
			"ability_two": {"id": "ability_two", "action": "ability_2", "key": "E", "targeting_type": "directional", "preview_kind": "cone", "icon_id": "arrow_volley", "icon_asset_id": "archer_arrow_volley", "label": "Arrow Volley", "summary": "Fan arrows toward the cursor.", "detail": "Arrow Volley fires a broad cone in the aimed direction.", "state_text": "READY"},
			"dash": {"id": "dash", "action": "dash", "key": "SPACE", "targeting_type": "directional", "preview_kind": "dash", "icon_id": "dash", "icon_asset_id": "archer_dash", "label": "Dash", "summary": "Dash toward the cursor.", "detail": "Dash is Archer's manual escape and angle-correction tool.", "state_text": "READY"},
			"ultimate": {"id": "ultimate", "action": "ultimate", "key": "R", "targeting_type": "instant", "preview_kind": "", "icon_id": "sentinel", "icon_asset_id": "archer_sentinel", "label": "Sentinel", "summary": "Practice-ready hawk summon.", "detail": "Sentinel summons an autonomous hawk that hunts nearby enemies during its active window.", "state_text": "READY"},
		}
		if _sentinel_ability != null:
			_sentinel_ability.set("duration", 8.0)
			_sentinel_ability.set("current_charge", float(_sentinel_ability.get("charge_required")))

func _bind_hud() -> void:
	if hud == null:
		return
	hud.visible = true
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
			hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, MISSILES_COOLDOWN_KEY, BOMB_COOLDOWN_KEY, BLINK_COOLDOWN_KEY, ULTIMATE_COOLDOWN_KEY)
		else:
			hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, POWER_SHOT_COOLDOWN_KEY, ARROW_VOLLEY_COOLDOWN_KEY, DASH_COOLDOWN_KEY, StringName())
	if hud.has_method("bind_game"):
		hud.bind_game(self)

func _spawn_training_dummy() -> void:
	if entities == null or training_dummy_spawn == null:
		return
	for child in entities.get_children():
		if child.is_in_group("training_dummy"):
			return
	var dummy: Node2D = TRAINING_DUMMY_SCENE.instantiate() as Node2D
	if dummy == null:
		return
	dummy.global_position = training_dummy_spawn.global_position
	entities.add_child(dummy)

func _tick_class_runtime(delta: float) -> void:
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		if _arcane_sniper_ability != null and _arcane_sniper_ability.has_method("tick"):
			_arcane_sniper_ability.tick(delta)
			_sniper_remaining = float(_arcane_sniper_ability.get_remaining())
		if player != null:
			player.weapon_style = "sniper" if _sniper_remaining > 0.0 else "pistol"
	else:
		if _sentinel_ability != null and _sentinel_ability.has_method("tick"):
			_sentinel_ability.tick(delta)
		if _sentinel_ability != null and not bool(_sentinel_ability.call("is_active")):
			_sentinel_ability.set("current_charge", float(_sentinel_ability.get("charge_required")))
		if player != null:
			player.weapon_style = "bow"

func _update_targeting() -> void:
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	var aim_point: Vector2
	if nearest != null and is_instance_valid(nearest):
		_current_target = nearest
		aim_point = nearest.global_position
	else:
		_current_target = null
		var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if move.length_squared() > 0.01:
			aim_point = player.global_position + move.normalized() * 200.0
		else:
			aim_point = player.global_position + player.aim_direction * 200.0
	player.set_aim_target(aim_point)

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var results: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not (candidate is Node2D):
			continue
		var enemy: Node2D = candidate as Node2D
		if not is_instance_valid(enemy) or not enemy.visible:
			continue
		results.append(enemy)
	results.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	return results

func _get_sorted_enemies_by_cursor_distance(origin: Vector2) -> Array[Node2D]:
	return _get_sorted_enemies_by_distance(origin)

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
	var best: Node2D
	var best_d2: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if not is_instance_valid(node) or not node.visible:
			continue
		var d2: float = origin.distance_squared_to(node.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = node
	return best

func _should_auto_fire_primary() -> bool:
	if not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	var max_range: float = ARCANE_PRIMARY_RANGE if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL else ARCHER_PRIMARY_RANGE
	return player.global_position.distance_squared_to(nearest.global_position) <= max_range * max_range

func _should_auto_cast_missiles() -> bool:
	if _active_class_id != RunConfig.CLASS_ARCANE_PISTOL:
		return false
	if not cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const MISSILES_AUTO_RANGE: float = 400.0
	return player.global_position.distance_squared_to(nearest.global_position) <= MISSILES_AUTO_RANGE * MISSILES_AUTO_RANGE

func _should_auto_cast_bomb() -> bool:
	if _active_class_id != RunConfig.CLASS_ARCANE_PISTOL:
		return false
	if not cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const BOMB_AUTO_RANGE: float = 350.0
	return player.global_position.distance_squared_to(nearest.global_position) <= BOMB_AUTO_RANGE * BOMB_AUTO_RANGE

func _should_auto_cast_power_shot() -> bool:
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		return false
	if not cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const POWER_SHOT_AUTO_RANGE: float = 440.0
	return player.global_position.distance_squared_to(nearest.global_position) <= POWER_SHOT_AUTO_RANGE * POWER_SHOT_AUTO_RANGE

func _should_auto_cast_arrow_volley() -> bool:
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		return false
	if not cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		return false
	if _arrow_volley_ability == null:
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	return not _arrow_volley_ability.get_targets_in_range(
		ability_anchor,
		_get_sorted_enemies_by_distance(player.global_position)
	).is_empty()

func _find_best_cluster_position(origin: Vector2, cluster_radius: float, max_range: float) -> Vector2:
	var enemies: Array[Node2D] = _get_sorted_enemies_by_distance(origin)
	if enemies.is_empty():
		return Vector2.INF
	var range_sq: float = max_range * max_range
	var radius_sq: float = cluster_radius * cluster_radius
	var best_pos: Vector2 = Vector2.INF
	var best_count: int = 0
	for anchor in enemies:
		if origin.distance_squared_to(anchor.global_position) > range_sq:
			continue
		var count: int = 0
		for other in enemies:
			if anchor.global_position.distance_squared_to(other.global_position) <= radius_sq:
				count += 1
		if count >= 2 and count > best_count:
			best_count = count
			best_pos = anchor.global_position
	return best_pos

func _get_cluster_aim_direction(from_position: Vector2, cluster_radius: float, max_range: float) -> Vector2:
	var cluster_pos: Vector2 = _find_best_cluster_position(from_position, cluster_radius, max_range)
	if cluster_pos != Vector2.INF:
		var dir: Vector2 = from_position.direction_to(cluster_pos)
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	return _get_auto_aim_direction(from_position)

func _get_arcane_missile_target(cursor_world: Vector2) -> Node2D:
	for enemy in _get_sorted_enemies_by_cursor_distance(cursor_world):
		if cursor_world.distance_squared_to(enemy.global_position) > 240.0 * 240.0:
			continue
		return enemy
	if _current_target != null and is_instance_valid(_current_target):
		return _current_target
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest != null and is_instance_valid(nearest):
		return nearest
	return null

func _handle_combat_input() -> void:
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		_handle_arcane_input()
	else:
		_handle_archer_input()

func _handle_archer_input() -> void:
	if GameSettings != null and GameSettings.uses_indicator_release_cast():
		_handle_archer_indicator_input()
	else:
		if (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
			_fire_archer_primary()
		if (Input.is_action_just_pressed("ability_1") or _should_auto_cast_power_shot()) and cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY):
			_cast_power_shot()
		if (Input.is_action_just_pressed("ability_2") or _should_auto_cast_arrow_volley()) and cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
			_cast_arrow_volley()
		if Input.is_action_just_pressed("dash") and _dash_charge_count > 0:
			_cast_archer_dash()
	if Input.is_action_just_pressed("ultimate") and _sentinel_ability != null and _sentinel_ability.has_method("activate"):
		if _sentinel_ability.activate():
			_sentinel_ability.spawn_hawk(
				player,
				effects,
				CombatBalance.ARCHER_BASE_DAMAGE,
				0.05,
				1.5
			)
	if _dash_charge_count < _dash_charge_max:
		_dash_recharge_timer = max(_dash_recharge_timer - get_process_delta_time(), 0.0)
		if _dash_recharge_timer <= 0.0:
			_dash_charge_count = min(_dash_charge_count + 1, _dash_charge_max)
			if _dash_charge_count < _dash_charge_max:
				_dash_recharge_timer = ARCHER_DASH_COOLDOWN

func _handle_arcane_input() -> void:
	if GameSettings != null and GameSettings.uses_indicator_release_cast():
		_handle_arcane_indicator_input()
	else:
		if (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
			_fire_arcane_primary()
		if (Input.is_action_just_pressed("ability_1") or _should_auto_cast_missiles()) and cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
			_cast_arcane_missiles()
		if (Input.is_action_just_pressed("ability_2") or _should_auto_cast_bomb()) and cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
			_cast_arcane_bomb()
		if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(BLINK_COOLDOWN_KEY):
			_cast_arcane_blink()
	if Input.is_action_just_pressed("ultimate") and cooldown_system.is_ready(ULTIMATE_COOLDOWN_KEY) and _arcane_sniper_ability != null:
		if _arcane_sniper_ability.activate(cooldown_system, ULTIMATE_COOLDOWN_KEY):
			AudioDirector.play_sfx("arcane_sniper", -4.0)
			_sniper_remaining = float(_arcane_sniper_ability.get_remaining())

func _handle_archer_indicator_input() -> void:
	_pending_directional_action = CastTargeting.process_indicator_release_input(
		player,
		_pending_directional_action,
		CastTargeting.get_directional_actions(CastTargeting.CLASS_ARCHER),
		Callable(self, "_can_prepare_archer_cast"),
		Callable(self, "_build_archer_cast_preview"),
		Callable(self, "_execute_archer_cast")
	)

func _can_prepare_archer_cast(action_name: String) -> bool:
	match action_name:
		"primary_fire":
			return cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY)
		"ability_1":
			return cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY)
		"ability_2":
			return cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY)
		"dash":
			return _dash_charge_count > 0
	return false

func _execute_archer_cast(action_name: String) -> void:
	match action_name:
		"primary_fire":
			_fire_archer_primary()
		"ability_1":
			_cast_power_shot()
		"ability_2":
			_cast_arrow_volley()
		"dash":
			_cast_archer_dash()

func _build_archer_cast_preview(action_name: String) -> Dictionary:
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
			"primary_range": ARCHER_PRIMARY_RANGE,
			"power_shot_range": ARCHER_PRIMARY_RANGE + 90.0,
			"volley_length": 220.0,
			"volley_spread_degrees": 26.0,
			"dash_length": float(player.get("dash_distance")) if _node_has_property(player, "dash_distance") else 170.0,
		}
	)

func _handle_arcane_indicator_input() -> void:
	_pending_directional_action = CastTargeting.process_indicator_release_input(
		player,
		_pending_directional_action,
		CastTargeting.get_directional_actions(CastTargeting.CLASS_ARCANE_PISTOL),
		Callable(self, "_can_prepare_arcane_cast"),
		Callable(self, "_build_arcane_cast_preview"),
		Callable(self, "_execute_arcane_cast")
	)

func _can_prepare_arcane_cast(action_name: String) -> bool:
	match action_name:
		"primary_fire":
			return cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY)
		"ability_1":
			return cooldown_system.is_ready(MISSILES_COOLDOWN_KEY)
		"ability_2":
			return cooldown_system.is_ready(BOMB_COOLDOWN_KEY)
		"dash":
			return cooldown_system.is_ready(BLINK_COOLDOWN_KEY)
	return false

func _execute_arcane_cast(action_name: String) -> void:
	match action_name:
		"primary_fire":
			_fire_arcane_primary()
		"ability_1":
			_cast_arcane_missiles()
		"ability_2":
			_cast_arcane_bomb()
		"dash":
			_cast_arcane_blink()

func _build_arcane_cast_preview(action_name: String) -> Dictionary:
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
	var missile_target: Node2D = _get_arcane_missile_target(_get_cursor_world_position())
	if action_name == "ability_1" and missile_target != null and is_instance_valid(missile_target):
		var locked_direction: Vector2 = player.global_position.direction_to(missile_target.global_position)
		if locked_direction.length_squared() > 0.0001:
			direction = locked_direction.normalized()
	return CastTargeting.build_preview(
		CastTargeting.CLASS_ARCANE_PISTOL,
		action_name,
		{
			"direction": direction,
			"primary_range": ARCANE_PRIMARY_RANGE,
			"missile_length": 210.0,
			"missile_count": 3,
			"missile_spread_degrees": float(_arcane_missiles_ability.get("spread_degrees")) if _node_has_property(_arcane_missiles_ability, "spread_degrees") else 12.0,
			"highlight_global_position": missile_target.global_position if missile_target != null and is_instance_valid(missile_target) else null,
			"bomb_length": float(_arcane_bomb_ability.get("throw_distance")) if _node_has_property(_arcane_bomb_ability, "throw_distance") else 220.0,
			"bomb_radius": float(_arcane_bomb_ability.get("zone_radius")) if _node_has_property(_arcane_bomb_ability, "zone_radius") else 78.0,
			"dash_length": float(player.get("dash_distance")) if _node_has_property(player, "dash_distance") else 170.0,
		}
	)

func _clear_pending_directional_cast() -> void:
	_pending_directional_action = ""
	if player != null and is_instance_valid(player):
		CastTargeting.clear_player_preview(player)

func _fire_archer_primary() -> void:
	var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
	if shot == null:
		return
	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = _get_primary_auto_aim_direction(shot.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	shot.set("direction", direction.normalized())
	shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE)
	shot.set("speed", 500.0)
	shot.set("pierce_count", 0)
	shot.set("crit_chance", 0.05)
	shot.set("crit_multiplier", 1.5)
	shot.set("visual_style", "arrow")
	shot.set("attack_payload", {
		"impact_direction": direction.normalized(),
		"hit_kind": "arrow",
	})
	projectiles.add_child(shot)
	AudioDirector.play_sfx("bow_primary", -6.0)
	player.notify_primary_fired()
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, ARCHER_PRIMARY_COOLDOWN)

func _cast_power_shot() -> void:
	if _power_shot_ability == null or not _power_shot_ability.has_method("cast_in_direction"):
		return
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return
	var direction: Vector2 = _get_manual_aim_direction(ability_anchor.global_position)
	var shot: Area2D = _power_shot_ability.cast_in_direction(
		ability_anchor,
		SNIPER_SCENE,
		projectiles,
		direction,
		CombatBalance.ARCHER_BASE_DAMAGE,
		1.5
	)
	if shot == null:
		return
	shot.set("visual_style", "power_arrow")
	shot.set("attack_payload", {
		"impact_direction": direction,
		"hit_kind": "power",
	})
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, ARCHER_POWER_SHOT_COOLDOWN)
	AudioDirector.play_sfx("bow_power_shot", -4.5)
	player.notify_primary_fired()

func _cast_arrow_volley() -> void:
	if _arrow_volley_ability == null or not _arrow_volley_ability.has_method("cast_in_direction"):
		return
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return
	var volley_range: float = float(_arrow_volley_ability.get("cast_range")) if _arrow_volley_ability.get("cast_range") != null else 350.0
	var direction: Vector2 = _get_cluster_aim_direction(ability_anchor.global_position, 100.0, volley_range)
	var shots: Array[Area2D] = _arrow_volley_ability.cast_in_direction(
		ability_anchor,
		BULLET_SCENE,
		projectiles,
		direction,
		CombatBalance.ARCHER_BASE_DAMAGE,
		0.05,
		1.5
	)
	if shots.is_empty():
		return
	for shot in shots:
		shot.set("attack_payload", {
			"impact_direction": Vector2(shot.get("direction")),
			"hit_kind": "volley",
		})
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, ARCHER_ARROW_VOLLEY_COOLDOWN)
	AudioDirector.play_sfx("bow_volley", -5.5)
	player.notify_primary_fired()

func _fire_arcane_primary() -> void:
	var shot_scene: PackedScene = BULLET_SCENE if _sniper_remaining <= 0.0 else SNIPER_SCENE
	var shot: Area2D = shot_scene.instantiate() as Area2D
	if shot == null:
		return
	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = _get_primary_auto_aim_direction(shot.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	shot.set("direction", direction.normalized())
	if _sniper_remaining > 0.0:
		shot.set("damage", CombatBalance.ARCANE_SNIPER_BASE_DAMAGE)
		shot.set("speed", 1450.0)
		shot.set("pierce_count", 2)
		shot.set("attack_payload", {
			"impact_direction": direction.normalized(),
			"hit_kind": "sniper",
		})
	else:
		shot.set("damage", CombatBalance.ARCANE_PISTOL_BASE_DAMAGE)
		shot.set("speed", 720.0)
		shot.set("pierce_count", 0)
		shot.set("visual_style", "bullet")
		shot.set("attack_payload", {
			"impact_direction": direction.normalized(),
			"hit_kind": "arcane",
	})
	projectiles.add_child(shot)
	AudioDirector.play_sfx("arcane_sniper" if _sniper_remaining > 0.0 else "arcane_primary", -4.0 if _sniper_remaining > 0.0 else -6.0)
	player.notify_primary_fired()
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, ARCANE_PRIMARY_COOLDOWN if _sniper_remaining <= 0.0 else 0.62)

func _cast_arcane_missiles() -> void:
	if _arcane_missiles_ability == null:
		return
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return
	var target: Node2D = _get_arcane_missile_target(_get_cursor_world_position())
	if target == null or not is_instance_valid(target):
		return
	var spawned: int = _arcane_missiles_ability.cast(
		ability_anchor,
		MISSILE_SCENE,
		projectiles,
		target,
		_get_manual_aim_direction(ability_anchor.global_position)
	)
	if spawned <= 0:
		return
	for child in projectiles.get_children():
		if child is Area2D and child.has_method("get") and child.get("target") != null:
			child.set("attack_payload", {
				"impact_direction": Vector2(child.get("direction")),
				"hit_kind": "missile",
				"suppress_impact_juice": true,
			})
	cooldown_system.set_cooldown(MISSILES_COOLDOWN_KEY, ARCANE_MISSILES_COOLDOWN)
	AudioDirector.play_sfx("arcane_missiles", -5.0)

func _cast_arcane_bomb() -> void:
	if _arcane_bomb_ability == null or not _arcane_bomb_ability.has_method("cast_in_direction"):
		return
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return
	var bomb_radius: float = float(_arcane_bomb_ability.get("zone_radius")) if _node_has_property(_arcane_bomb_ability, "zone_radius") else 78.0
	var bomb_range: float = float(_arcane_bomb_ability.get("throw_distance")) if _node_has_property(_arcane_bomb_ability, "throw_distance") else 220.0
	var direction: Vector2 = _get_cluster_aim_direction(ability_anchor.global_position, bomb_radius, bomb_range + bomb_radius)
	var projectile: Node2D = _arcane_bomb_ability.call(
		"cast_in_direction",
		ability_anchor,
		ARCANE_BOMB_PROJECTILE_SCENE,
		effects,
		direction
	) as Node2D
	if projectile == null:
		return
	cooldown_system.set_cooldown(BOMB_COOLDOWN_KEY, ARCANE_BOMB_COOLDOWN)
	AudioDirector.play_sfx("arcane_missiles", -6.5)

func _cast_archer_dash() -> void:
	if not player.start_dash(_get_auto_aim_direction(player.global_position)):
		return
	AudioDirector.play_sfx("dash_archer", -5.0)
	_dash_charge_count = max(_dash_charge_count - 1, 0)
	if _dash_charge_count < _dash_charge_max and _dash_recharge_timer <= 0.0:
		_dash_recharge_timer = ARCHER_DASH_COOLDOWN

func _cast_arcane_blink() -> void:
	if not player.start_dash(_get_auto_aim_direction(player.global_position)):
		return
	AudioDirector.play_sfx("arcane_blink", -5.0)
	cooldown_system.set_cooldown(BLINK_COOLDOWN_KEY, ARCANE_BLINK_COOLDOWN)

func _update_status_cache() -> void:
	if player == null:
		return
	if _active_class_id == RunConfig.CLASS_ARCANE_PISTOL:
		primary_mode_label = "SNIPER" if _sniper_remaining > 0.0 else "READY"
		var missiles_remaining: float = float(cooldown_system.get_remaining(MISSILES_COOLDOWN_KEY))
		ability_one_label = "READY" if missiles_remaining <= 0.0 else "%.1fs" % missiles_remaining
		var bomb_remaining: float = float(cooldown_system.get_remaining(BOMB_COOLDOWN_KEY))
		ability_two_label = "READY" if bomb_remaining <= 0.0 else "%.1fs" % bomb_remaining
		var blink_remaining: float = float(cooldown_system.get_remaining(BLINK_COOLDOWN_KEY))
		dash_label = "READY" if blink_remaining <= 0.0 else "%.1fs" % blink_remaining
		var sniper_remaining: float = float(cooldown_system.get_remaining(ULTIMATE_COOLDOWN_KEY))
		ultimate_label = "%.1fs" % _sniper_remaining if _sniper_remaining > 0.0 else ("READY" if sniper_remaining <= 0.0 else "%.1fs" % sniper_remaining)
		ability_slot_data["primary"]["key"] = GameSettings.get_binding_label("primary_fire")
		ability_slot_data["ability_one"]["key"] = GameSettings.get_binding_label("ability_1")
		ability_slot_data["ability_two"]["key"] = GameSettings.get_binding_label("ability_2")
		ability_slot_data["dash"]["key"] = GameSettings.get_binding_label("dash")
		ability_slot_data["ultimate"]["key"] = GameSettings.get_binding_label("ultimate")
		ability_slot_data["primary"]["state_text"] = primary_mode_label
		ability_slot_data["ability_one"]["state_text"] = ability_one_label
		ability_slot_data["ability_two"]["state_text"] = ability_two_label
		ability_slot_data["dash"]["state_text"] = dash_label
		ability_slot_data["ultimate"]["state_text"] = ultimate_label
		ability_slot_data["ability_one"]["summary"] = "Single-target lock-on volley."
		ability_slot_data["ability_one"]["detail"] = "Arcane Missiles locks one enemy at cast time and sends the full missile volley into that target."
		ability_slot_data["primary"]["cooldown_show"] = bool(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY) > 0.0)
		ability_slot_data["primary"]["cooldown_fill"] = clampf(float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY)) / max(ARCANE_PRIMARY_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["primary"]["cooldown_seconds"] = float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY))
		ability_slot_data["ability_one"]["cooldown_show"] = missiles_remaining > 0.0
		ability_slot_data["ability_one"]["cooldown_fill"] = clampf(missiles_remaining / max(ARCANE_MISSILES_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_seconds"] = missiles_remaining
		ability_slot_data["ability_two"]["cooldown_show"] = bomb_remaining > 0.0
		ability_slot_data["ability_two"]["cooldown_fill"] = clampf(bomb_remaining / max(ARCANE_BOMB_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ability_two"]["cooldown_seconds"] = bomb_remaining
		ability_slot_data["dash"]["cooldown_show"] = blink_remaining > 0.0
		ability_slot_data["dash"]["cooldown_fill"] = clampf(blink_remaining / max(ARCANE_BLINK_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["dash"]["cooldown_seconds"] = blink_remaining
		ability_slot_data["dash"]["charge_pips_total"] = 0
		ability_slot_data["dash"]["charge_pips_filled"] = 0
		ability_slot_data["ultimate"]["cooldown_show"] = true
		ability_slot_data["ultimate"]["cooldown_fill"] = clampf((_sniper_remaining if _sniper_remaining > 0.0 else sniper_remaining) / max(ARCANE_SNIPER_DURATION if _sniper_remaining > 0.0 else ARCANE_SNIPER_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ultimate"]["cooldown_seconds"] = _sniper_remaining if _sniper_remaining > 0.0 else sniper_remaining
	else:
		var primary_remaining: float = float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY))
		var power_shot_remaining: float = float(cooldown_system.get_remaining(POWER_SHOT_COOLDOWN_KEY))
		var arrow_volley_remaining: float = float(cooldown_system.get_remaining(ARROW_VOLLEY_COOLDOWN_KEY))
		primary_mode_label = "READY" if primary_remaining <= 0.0 else "%.1fs" % primary_remaining
		ability_one_label = "READY" if power_shot_remaining <= 0.0 else "%.1fs" % power_shot_remaining
		if _dash_charge_count >= _dash_charge_max:
			dash_label = "%d/%d" % [_dash_charge_count, _dash_charge_max]
		else:
			dash_label = "%d/%d  %.1fs" % [_dash_charge_count, _dash_charge_max, _dash_recharge_timer]
		ability_two_label = "READY" if arrow_volley_remaining <= 0.0 else "%.1fs" % arrow_volley_remaining
		ultimate_label = "%.1fs" % float(_sentinel_ability.get_remaining()) if _sentinel_ability != null and _sentinel_ability.is_active() else "READY"
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
		ability_slot_data["primary"]["cooldown_fill"] = clampf(primary_remaining / max(ARCHER_PRIMARY_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["primary"]["cooldown_seconds"] = primary_remaining
		ability_slot_data["ability_one"]["cooldown_show"] = power_shot_remaining > 0.0
		ability_slot_data["ability_one"]["cooldown_fill"] = clampf(power_shot_remaining / max(ARCHER_POWER_SHOT_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_seconds"] = power_shot_remaining
		ability_slot_data["dash"]["cooldown_show"] = _dash_charge_count < _dash_charge_max
		ability_slot_data["dash"]["cooldown_fill"] = clampf(_dash_recharge_timer / max(ARCHER_DASH_COOLDOWN, 0.001), 0.0, 1.0) if _dash_charge_count < _dash_charge_max else 0.0
		ability_slot_data["dash"]["cooldown_seconds"] = _dash_recharge_timer if _dash_charge_count < _dash_charge_max else 0.0
		ability_slot_data["dash"]["charge_pips_total"] = _dash_charge_max
		ability_slot_data["dash"]["charge_pips_filled"] = _dash_charge_count
		ability_slot_data["ability_two"]["cooldown_show"] = arrow_volley_remaining > 0.0
		ability_slot_data["ability_two"]["cooldown_fill"] = clampf(arrow_volley_remaining / max(ARCHER_ARROW_VOLLEY_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ability_two"]["cooldown_seconds"] = arrow_volley_remaining
		ability_slot_data["ultimate"]["cooldown_show"] = _sentinel_ability != null and _sentinel_ability.is_active()
		ability_slot_data["ultimate"]["cooldown_fill"] = clampf(float(_sentinel_ability.get_remaining()) / max(float(_sentinel_ability.get("duration")), 0.001), 0.0, 1.0) if _sentinel_ability != null and _sentinel_ability.is_active() else 0.0
		ability_slot_data["ultimate"]["cooldown_seconds"] = float(_sentinel_ability.get_remaining()) if _sentinel_ability != null and _sentinel_ability.is_active() else 0.0
		ability_slot_data["ultimate"]["charge_pips_total"] = 0
		ability_slot_data["ultimate"]["charge_pips_filled"] = 0

func _clamp_to_hub_rect(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, HUB_RECT.position.x, HUB_RECT.end.x),
		clampf(point.y, HUB_RECT.position.y, HUB_RECT.end.y)
	)

func request_toggle_pause() -> void:
	if _inventory_overlay_open:
		request_close_inventory()
		return
	if _input_blocked and not _manual_pause:
		return
	_manual_pause = not _manual_pause
	_profile_overlay_open = false
	_clear_pending_directional_cast()
	set_input_blocked(_manual_pause)
	_update_status_cache()

func request_resume_game() -> void:
	_manual_pause = false
	_profile_overlay_open = false
	_inventory_overlay_open = false
	_clear_pending_directional_cast()
	set_input_blocked(false)
	_update_status_cache()

func request_toggle_inventory() -> void:
	if _inventory_overlay_open:
		request_close_inventory()
		return
	if _input_blocked or player == null or not is_instance_valid(player):
		return
	_inventory_overlay_open = true
	set_input_blocked(true)
	_update_status_cache()

func request_close_inventory() -> void:
	if not _inventory_overlay_open:
		return
	_inventory_overlay_open = false
	set_input_blocked(false)
	_update_status_cache()

func _use_hotbar_slot(slot: int) -> void:
	if _manual_pause or _profile_overlay_open or _inventory_overlay_open or _input_blocked:
		return
	if TownState == null:
		return
	var item_data: Dictionary = TownState.use_hotbar_item(slot)
	if item_data.is_empty():
		return
	var item_id: String = str(item_data.get("id", ""))
	if item_id == "hp_potion" and player != null and is_instance_valid(player) and player.has_method("heal"):
		player.heal(float(item_data.get("heal_amount", 250.0)))
		if AudioDirector != null:
			AudioDirector.play_ui("ui_confirm", -2.0)
	_update_status_cache()

func request_open_profile() -> void:
	pass

func request_close_profile() -> void:
	pass

func request_return_to_menu() -> void:
	_manual_pause = false
	_profile_overlay_open = false
	_inventory_overlay_open = false
	_clear_pending_directional_cast()
	set_input_blocked(false)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func request_upgrade_selection(_index: int) -> void:
	pass

func request_upgrade_hover(_index: int) -> void:
	pass

func _reset_hub_runtime_state() -> void:
	_manual_pause = false
	_profile_overlay_open = false
	_inventory_overlay_open = false
	_input_blocked = false
	_current_target = null
	get_tree().paused = false
	_clear_pending_directional_cast()
	if player != null and is_instance_valid(player):
		player.set_movement_enabled(true)

func _resolve_safe_spawn_position(desired_position: Vector2) -> Vector2:
	var clamped_position: Vector2 = _clamp_to_hub_rect(desired_position)
	if player == null or not is_instance_valid(player):
		return clamped_position
	var collision_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return clamped_position
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(0.0, 48.0),
		Vector2(0.0, 96.0),
		Vector2(-64.0, 32.0),
		Vector2(64.0, 32.0),
		Vector2(-96.0, 64.0),
		Vector2(96.0, 64.0),
		Vector2(-140.0, 0.0),
		Vector2(140.0, 0.0),
		Vector2(-160.0, 80.0),
		Vector2(160.0, 80.0),
	]
	for offset in offsets:
		var candidate: Vector2 = _clamp_to_hub_rect(clamped_position + offset)
		if not _is_spawn_position_blocked(candidate, collision_shape.shape):
			return candidate
	return clamped_position

func _is_spawn_position_blocked(candidate: Vector2, shape: Shape2D) -> bool:
	if player == null or not is_instance_valid(player) or shape == null:
		return false
	player.global_position = candidate
	player.force_update_transform()
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, candidate)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var state: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	return not state.intersect_shape(query, 8).is_empty()

func _node_has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.name) == property_name:
			return true
	return false
