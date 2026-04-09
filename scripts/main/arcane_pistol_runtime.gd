extends Node

const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const CombatJuice = preload("res://scripts/systems/combat_juice.gd")
const CastTargeting = preload("res://scripts/systems/cast_targeting.gd")

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const CHASER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/ChaserEnemy.tscn")
const OBJECTIVE_CORE_SCENE: PackedScene = preload("res://scenes/enemies/ObjectiveCore.tscn")
const TREENT_BOSS_SCENE: PackedScene = preload("res://scenes/enemies/TreentBoss.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/projectiles/Missile.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const ARCANE_BOMB_PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/ArcaneBombProjectile.tscn")
const ENEMY_BARK_SCENE: PackedScene = preload("res://scenes/projectiles/EnemyBarkShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")
const DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
const TRAIL_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/TrailEffect.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const BLINK_COOLDOWN_KEY: StringName = &"arcane_blink"
const MISSILES_COOLDOWN_KEY: StringName = &"arcane_missiles"
const BOMB_COOLDOWN_KEY: StringName = &"arcane_bomb"
const ULTIMATE_COOLDOWN_KEY: StringName = &"arcane_sniper"
const ARCANE_BASE_MOVE_SPEED: float = 180.0
const HUB_SCENE_PATH: String = "res://scenes/hub/EsseloriaHub.tscn"

@export var primary_fire_cooldown: float = 0.25
@export var blink_cooldown: float = 1.2
@export var arcane_missiles_cooldown: float = 5.0
@export var arcane_bomb_cooldown: float = 8.0
@export var arcane_sniper_cooldown: float = 18.0
@export var arcane_sniper_duration: float = 7.0
@export var enemy_spawn_interval: float = 1.82
@export var max_active_enemies: int = 11
@export var contact_damage_interval: float = 0.68
@export var enemy_move_speed_multiplier: float = 1.38
@export var enemy_contact_damage_multiplier: float = 1.15
@export var enemy_health_multiplier: float = 1.2
@export var enemy_attack_windup_multiplier: float = 0.72
@export var core_objective_kill_threshold: int = 10
@export var core_reward_xp: int = 45

@onready var world: Node2D = $World
@onready var arena: Node2D = $World/Arena
@onready var boss_arena: Node2D = $World/BossArena
@onready var entities: Node2D = $World/Entities
@onready var player: CharacterBody2D = $World/Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var xp_orb_field: Node2D = $World/Entities/XpOrbField
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner

@onready var arcane_missiles_ability: Node2D = $World/Entities/Player/AbilityAnchor/ArcaneMissiles
@onready var arcane_bomb_ability: Node2D = $World/Entities/Player/AbilityAnchor/ArcaneBomb
@onready var arcane_sniper_ability: Node2D = $World/Entities/Player/AbilityAnchor/ArcaneSniper

var current_level: int = 1
var current_health: float = CombatBalance.PLAYER_MAX_HEALTH
var max_health: float = CombatBalance.PLAYER_MAX_HEALTH
var xp_percent: float = 0.0
var wave_number: int = 1
var kills: int = 0
var enemy_count: int = 0
var run_time: float = 0.0
var target_label: String = "None"
var primary_mode_label: String = "READY"
var ability_one_label: String = "READY"
var dash_label: String = "READY"
var ability_two_label: String = "READY"
var ultimate_label: String = "READY"
var objective_state_label: String = "Survive the forest assault"
var boss_status_label: String = ""
var objective_progress: float = 0.0
var progress_panel_title: String = "BOSS PROGRESS"
var progress_panel_detail: String = "Build pressure in Deepwood"
var progress_panel_value: float = 0.0
var profile_data: Dictionary = {}
var upgrade_prompt: String = ""
var game_over_prompt: String = ""
var upgrade_choices_display: Array[Dictionary] = []
var selected_upgrade_index_display: int = -1
var ability_slot_data: Dictionary = {
	"primary": {"id": "primary", "action": "primary_fire", "key": "LMB", "targeting_type": "directional", "preview_kind": "line", "icon_id": "pistol", "icon_asset_id": "arcane_pistol_primary", "label": "Arcane Pistol", "summary": "Fire magical rounds toward the cursor.", "detail": "Arcane Pistol fires precise magical shots in the aimed direction. Sniper mode upgrades those shots into heavy piercing rounds.", "state_text": "READY"},
	"ability_one": {"id": "ability_one", "action": "ability_1", "key": "Q", "targeting_type": "directional", "preview_kind": "fan", "icon_id": "missiles", "icon_asset_id": "arcane_missiles", "label": "Arcane Missiles", "summary": "Lock one target and fire a homing volley.", "detail": "Arcane Missiles locks onto one enemy near the cursor, then sends the full volley into that target. If the cursor is not near an enemy, it falls back to your current soft-lock or nearest foe.", "state_text": "READY"},
	"ability_two": {"id": "ability_two", "action": "ability_2", "key": "E", "targeting_type": "directional", "preview_kind": "lob_line", "icon_id": "arcane", "icon_asset_id": "arcane_bomb", "label": "Arcane Bomb", "summary": "Lob a glowing bomb forward into a damage field.", "detail": "Arcane Bomb throws a volatile charge in the aimed direction. It bursts into a lingering zone that damages and lightly slows enemies inside it.", "state_text": "READY"},
	"dash": {"id": "dash", "action": "dash", "key": "SPACE", "targeting_type": "directional", "preview_kind": "dash", "icon_id": "blink", "icon_asset_id": "arcane_blink", "label": "Arcane Blink", "summary": "Blink toward the cursor.", "detail": "Blink keeps the gunslinger evasive and opens clean firing angles without breaking ranged spacing.", "state_text": "READY"},
	"ultimate": {"id": "ultimate", "action": "ultimate", "key": "R", "targeting_type": "instant", "preview_kind": "", "icon_id": "sniper", "icon_asset_id": "arcane_sniper", "label": "Arcane Sniper", "summary": "Enter a timed sniper stance.", "detail": "Arcane Sniper replaces base shots with slower, harder-hitting piercing rounds for a short window.", "state_text": "READY"},
}

var _xp_system: ExperienceSystem = ExperienceSystem.new()
var _current_target: Node2D
var _boss: Node2D
var _objective_phase: String = "waves"
var _active_cores: Array[Node2D] = []
var _core_count_total: int = 0
var _spawn_timer: float = 0.0
var _contact_timer: float = 0.0
var _sniper_remaining: float = 0.0
var _game_over: bool = false
var _manual_pause: bool = false
var _profile_overlay_open: bool = false
var _inventory_overlay_open: bool = false
var _upgrade_choices: Array[Dictionary] = []
var _selected_upgrade_index: int = 0
var _upgrade_counts: Dictionary = {}

var _primary_damage_multiplier: float = 1.0
var _primary_rate_multiplier: float = 1.0
var _move_speed_multiplier: float = 1.0
var _missiles_count_bonus: int = 0
var _missiles_cooldown_multiplier: float = 1.0
var _sniper_damage_multiplier: float = 1.0
var _sniper_pierce_bonus: int = 0
var _combat_juice: CombatJuice
var _pending_directional_action: String = ""

func _ready() -> void:
	AudioDirector.set_music_context("run")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	if arena:
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	if boss_arena:
		boss_arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	if entities:
		entities.process_mode = Node.PROCESS_MODE_PAUSABLE
	if projectiles:
		projectiles.process_mode = Node.PROCESS_MODE_PAUSABLE
	if effects:
		effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("Systems"):
		$Systems.process_mode = Node.PROCESS_MODE_PAUSABLE
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_opening_wave()
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, MISSILES_COOLDOWN_KEY, BOMB_COOLDOWN_KEY, BLINK_COOLDOWN_KEY, ULTIMATE_COOLDOWN_KEY)
	if hud.has_method("bind_game"):
		hud.bind_game(self)
	_combat_juice = CombatJuice.new()
	add_child(_combat_juice)
	_combat_juice.setup(player)
	if xp_orb_field != null and xp_orb_field.has_method("setup"):
		xp_orb_field.setup(_xp_system, player)
	if player.has_signal("died"):
		player.connect("died", Callable(self, "_on_player_died"))
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_damaged.connect(_on_player_damaged)
	_apply_meta_progression_modifiers()
	player.move_speed = ARCANE_BASE_MOVE_SPEED * _move_speed_multiplier
	player.weapon_style = "pistol"
	if arcane_sniper_ability:
		arcane_sniper_ability.set("duration", arcane_sniper_duration)
		arcane_sniper_ability.set("cooldown", arcane_sniper_cooldown)

func _exit_tree() -> void:
	_clear_combat_juice()

func _process(delta: float) -> void:
	var settings_open: bool = hud != null and hud.has_method("is_settings_panel_open") and bool(hud.call("is_settings_panel_open"))
	if Input.is_action_just_pressed("ui_cancel"):
		if settings_open:
			_update_status_cache()
			return
		if _inventory_overlay_open:
			request_close_inventory()
			_update_status_cache()
			return
		if _cancel_pending_directional_cast():
			_update_status_cache()
			return
		request_toggle_pause()
	if Input.is_action_just_pressed("inventory"):
		request_toggle_inventory()
	for slot_idx in range(4):
		if Input.is_action_just_pressed("item_slot_%d" % (slot_idx + 1)):
			_use_hotbar_slot(slot_idx)
	if Input.is_action_just_pressed("run_profile"):
		request_toggle_profile()
	if arcane_sniper_ability and arcane_sniper_ability.has_method("tick"):
		arcane_sniper_ability.tick(delta)
		_sniper_remaining = float(arcane_sniper_ability.get_remaining())
	_sync_player_weapon_style()
	_update_status_cache()
	if _game_over:
		_clear_pending_directional_cast()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
			_return_to_hub()
		return
	if _manual_pause or _inventory_overlay_open:
		_clear_pending_directional_cast()
		return
	if _upgrade_choices.size() > 0:
		_clear_pending_directional_cast()
		_handle_upgrade_input()
		return
	if _xp_system.has_pending_level_up():
		_clear_pending_directional_cast()
		_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, RunConfig.CLASS_ARCANE_PISTOL)
		if _upgrade_choices.is_empty():
			return
		_manual_pause = false
		_profile_overlay_open = false
		_selected_upgrade_index = 0
		_sync_upgrade_display()
		get_tree().paused = true
		_update_status_cache()
		return
	run_time += delta
	_spawn_timer += delta
	_contact_timer += delta
	_update_objective_flow()
	_update_targeting()
	_handle_combat_input()
	_handle_spawning()
	_handle_enemy_contact_damage()
	if arena.has_method("clamp_position"):
		player.global_position = arena.clamp_position(player.global_position)

func _handle_combat_input() -> void:
	if GameSettings != null and GameSettings.uses_indicator_release_cast():
		_handle_indicator_release_combat_input()
	else:
		_clear_pending_directional_cast()
		_handle_quick_cast_combat_input()

	if Input.is_action_just_pressed("ultimate") and cooldown_system.is_ready(ULTIMATE_COOLDOWN_KEY):
		if arcane_sniper_ability and arcane_sniper_ability.has_method("activate"):
			arcane_sniper_ability.activate(cooldown_system, ULTIMATE_COOLDOWN_KEY)
			AudioDirector.play_sfx("arcane_sniper", -4.0)
			_sniper_remaining = float(arcane_sniper_ability.get_remaining())

func _handle_quick_cast_combat_input() -> void:
	if (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		_fire_arcane_pistol()
	if (Input.is_action_just_pressed("ability_1") or _should_auto_cast_missiles()) and cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
		_cast_arcane_missiles()
	if (Input.is_action_just_pressed("ability_2") or _should_auto_cast_bomb()) and cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
		_cast_arcane_bomb()
	if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(BLINK_COOLDOWN_KEY):
		_cast_arcane_blink()

func _handle_indicator_release_combat_input() -> void:
	_pending_directional_action = CastTargeting.process_indicator_release_input(
		player,
		_pending_directional_action,
		CastTargeting.get_directional_actions(CastTargeting.CLASS_ARCANE_PISTOL),
		Callable(self, "_can_prepare_directional_cast"),
		Callable(self, "_build_directional_cast_preview"),
		Callable(self, "_execute_directional_cast")
	)

func _can_prepare_directional_cast(action_name: String) -> bool:
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

func _execute_directional_cast(action_name: String) -> bool:
	match action_name:
		"primary_fire":
			return _fire_arcane_pistol()
		"ability_1":
			return _cast_arcane_missiles()
		"ability_2":
			return _cast_arcane_bomb()
		"dash":
			return _cast_arcane_blink()
	return false

func _cancel_pending_directional_cast() -> bool:
	if _pending_directional_action.is_empty():
		return false
	_clear_pending_directional_cast()
	return true

func _clear_pending_directional_cast() -> void:
	_pending_directional_action = ""
	CastTargeting.clear_player_preview(player)

func _sync_player_weapon_style() -> void:
	if player == null:
		return
	player.weapon_style = "sniper" if _sniper_remaining > 0.0 else "pistol"

func _build_directional_cast_preview(action_name: String) -> Dictionary:
	var direction: Vector2
	if action_name == "ability_1":
		direction = _get_manual_aim_direction()
	elif action_name == "primary_fire":
		direction = _get_primary_auto_aim_direction(player.get_muzzle_global_position())
	elif action_name == "ability_2":
		var origin: Vector2 = player.global_position
		var ab: Node2D = player.get_node("AbilityAnchor") as Node2D
		if ab != null:
			origin = ab.global_position
		var bomb_radius: float = float(arcane_bomb_ability.get("zone_radius")) if _node_has_property(arcane_bomb_ability, "zone_radius") else 78.0
		var bomb_range: float = float(arcane_bomb_ability.get("throw_distance")) if _node_has_property(arcane_bomb_ability, "throw_distance") else 220.0
		direction = _get_cluster_aim_direction(origin, bomb_radius, bomb_range + bomb_radius)
	else:
		direction = _get_auto_aim_direction(player.global_position)
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
			"primary_range": 520.0,
			"missile_length": 210.0,
			"missile_count": 3 + _missiles_count_bonus,
			"missile_spread_degrees": float(arcane_missiles_ability.get("spread_degrees")) if _node_has_property(arcane_missiles_ability, "spread_degrees") else 12.0,
			"highlight_global_position": missile_target.global_position if missile_target != null and is_instance_valid(missile_target) else null,
			"bomb_length": float(arcane_bomb_ability.get("throw_distance")) if _node_has_property(arcane_bomb_ability, "throw_distance") else 220.0,
			"bomb_radius": float(arcane_bomb_ability.get("zone_radius")) if _node_has_property(arcane_bomb_ability, "zone_radius") else 78.0,
			"dash_length": float(player.get("dash_distance")) if _node_has_property(player, "dash_distance") else 170.0,
		}
	)

func _fire_arcane_pistol() -> bool:
	var shot_scene: PackedScene = BULLET_SCENE
	if _sniper_remaining > 0.0:
		shot_scene = SNIPER_SCENE
	var shot: Area2D = shot_scene.instantiate() as Area2D
	if shot == null:
		return false

	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = _get_primary_auto_aim_direction(shot.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	shot.set("direction", direction)
	if _sniper_remaining > 0.0:
		shot.set("damage", CombatBalance.ARCANE_SNIPER_BASE_DAMAGE * _primary_damage_multiplier * _sniper_damage_multiplier)
		shot.set("speed", 1450.0)
		shot.set("pierce_count", 2 + _sniper_pierce_bonus)
		shot.set("attack_payload", {
			"impact_direction": direction,
			"hit_kind": "sniper",
		})
	else:
		shot.set("damage", CombatBalance.ARCANE_PISTOL_BASE_DAMAGE * _primary_damage_multiplier)
		shot.set("speed", 720.0)
		shot.set("pierce_count", 0)
		shot.set("visual_style", "bullet")
		shot.set("attack_payload", {
			"impact_direction": direction,
			"hit_kind": "arcane",
		})

	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("sniper" if _sniper_remaining > 0.0 else "arcane"))
	projectiles.add_child(shot)
	AudioDirector.play_sfx("arcane_sniper" if _sniper_remaining > 0.0 else "arcane_primary", -4.0 if _sniper_remaining > 0.0 else -6.0)
	_spawn_trail(player.get_muzzle_global_position(), player.get_muzzle_global_position() + direction * (48.0 if _sniper_remaining > 0.0 else 20.0), Color(1.0, 0.8, 0.4, 0.75) if _sniper_remaining > 0.0 else Color(0.62, 0.96, 1.0, 0.55), 4.0 if _sniper_remaining > 0.0 else 2.0)
	var cooldown: float = primary_fire_cooldown / _primary_rate_multiplier
	if _sniper_remaining > 0.0:
		cooldown = 0.62 / _primary_rate_multiplier
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, cooldown)
	return true

func _cast_arcane_missiles() -> bool:
	if not arcane_missiles_ability or not arcane_missiles_ability.has_method("cast"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var cursor_world: Vector2 = _get_cursor_world_position()
	var forward_direction: Vector2 = _get_manual_aim_direction(ability_anchor.global_position)
	var target: Node2D = _get_arcane_missile_target(cursor_world)
	if target == null or not is_instance_valid(target):
		return false
	arcane_missiles_ability.set("missiles_per_cast", 3 + _missiles_count_bonus)
	var spawned: int = arcane_missiles_ability.cast(ability_anchor, MISSILE_SCENE, projectiles, target, forward_direction)
	if spawned > 0:
		for child in projectiles.get_children():
			if child is Area2D and child.has_signal("hit") and not child.is_connected("hit", Callable(self, "_spawn_hit_feedback").bind("arcane")):
				child.set("attack_payload", {
					"impact_direction": Vector2(child.get("direction")) if child.get("direction") != null else Vector2.ZERO,
					"hit_kind": "missile",
					"suppress_impact_juice": true,
				})
				child.connect("hit", Callable(self, "_spawn_hit_feedback").bind("arcane"))
		var missiles_cd: float = arcane_missiles_cooldown * _missiles_cooldown_multiplier
		cooldown_system.set_cooldown(MISSILES_COOLDOWN_KEY, missiles_cd)
		AudioDirector.play_sfx("arcane_missiles", -5.0)
		return true
	return false

func _cast_arcane_bomb() -> bool:
	if not arcane_bomb_ability or not arcane_bomb_ability.has_method("cast_in_direction"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var bomb_radius: float = float(arcane_bomb_ability.get("zone_radius")) if _node_has_property(arcane_bomb_ability, "zone_radius") else 78.0
	var bomb_range: float = float(arcane_bomb_ability.get("throw_distance")) if _node_has_property(arcane_bomb_ability, "throw_distance") else 220.0
	var direction: Vector2 = _get_cluster_aim_direction(ability_anchor.global_position, bomb_radius, bomb_range + bomb_radius)
	var projectile: Node2D = arcane_bomb_ability.call(
		"cast_in_direction",
		ability_anchor,
		ARCANE_BOMB_PROJECTILE_SCENE,
		effects,
		direction
	) as Node2D
	if projectile == null:
		return false
	cooldown_system.set_cooldown(BOMB_COOLDOWN_KEY, arcane_bomb_cooldown)
	AudioDirector.play_sfx("arcane_missiles", -6.5)
	return true

func _cast_arcane_blink() -> bool:
	var blink_direction: Vector2 = _get_auto_aim_direction(player.global_position)
	if not player.start_dash(blink_direction):
		return false
	AudioDirector.play_sfx("arcane_blink", -5.0)
	cooldown_system.set_cooldown(BLINK_COOLDOWN_KEY, blink_cooldown)
	return true

func _spawn_opening_wave() -> void:
	_spawn_enemy(DUMMY_ENEMY_SCENE, Vector2(220, -80))
	_spawn_enemy(CHASER_ENEMY_SCENE, Vector2(310, -20))
	_spawn_enemy(CHASER_ENEMY_SCENE, Vector2(-260, -30))

func _spawn_enemy(scene: PackedScene, offset: Vector2) -> void:
	var spawn_position: Vector2 = player.global_position + offset
	var enemy: Node = spawner.spawn(scene, entities, spawn_position)
	if enemy == null:
		return
	if _is_combat_enemy(enemy) and _node_has_property(enemy, "max_health"):
		var scaled_max_health: float = float(enemy.get("max_health")) * enemy_health_multiplier
		enemy.set("max_health", scaled_max_health)
		if _node_has_property(enemy, "health"):
			enemy.set("health", scaled_max_health)
	if _node_has_property(enemy, "move_speed") and _is_combat_enemy(enemy):
		enemy.set("move_speed", float(enemy.get("move_speed")) * enemy_move_speed_multiplier)
	if _node_has_property(enemy, "contact_damage") and _is_combat_enemy(enemy):
		enemy.set("contact_damage", float(enemy.get("contact_damage")) * enemy_contact_damage_multiplier)
	for property_name in ["projectile_windup", "cast_duration", "attack_cooldown", "lunge_windup", "slam_windup"]:
		if _is_combat_enemy(enemy) and _node_has_property(enemy, property_name):
			enemy.set(property_name, float(enemy.get(property_name)) * enemy_attack_windup_multiplier)
	for property in enemy.get_property_list():
		if String(property.name) == "target_path":
			enemy.set("target_path", player.get_path())
			break
	if enemy.is_in_group("boss"):
		_boss = enemy as Node2D
		if enemy.has_signal("bark_shot"):
			enemy.connect("bark_shot", Callable(self, "_on_boss_bark_shot"))
		if enemy.has_signal("encompass_root"):
			enemy.connect("encompass_root", Callable(self, "_on_encompass_root"))
		if enemy.has_signal("territory_started"):
			enemy.connect("territory_started", Callable(self, "_on_territory_started"))
		if enemy.has_signal("territory_ended"):
			enemy.connect("territory_ended", Callable(self, "_on_territory_ended"))
	elif enemy.is_in_group("objective_core"):
		_active_cores.append(enemy as Node2D)
	if enemy.has_signal("damage_feedback"):
		enemy.connect("damage_feedback", Callable(self, "_on_enemy_damage_feedback"))

func _handle_spawning() -> void:
	if _objective_phase != "waves":
		return
	var active_enemies: int = get_tree().get_nodes_in_group("enemies").size()
	if active_enemies >= max_active_enemies:
		return
	if _spawn_timer < enemy_spawn_interval:
		return
	_spawn_timer = 0.0
	if kills > 0 and kills % 6 == 0:
		wave_number = 1 + int(floor(float(kills) / 6.0))
	var angle: float = randf() * TAU
	var radius: float = 360.0 + randf() * 120.0
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * radius
	var scene: PackedScene = DUMMY_ENEMY_SCENE
	if randi() % 4 != 0:
		scene = CHASER_ENEMY_SCENE
	_spawn_enemy(scene, offset)

func _update_objective_flow() -> void:
	if _objective_phase == "waves" and kills >= core_objective_kill_threshold:
		_begin_core_objective()
	elif _objective_phase == "cores":
		var living_cores: Array[Node2D] = []
		for core in _active_cores:
			if is_instance_valid(core):
				living_cores.append(core)
		_active_cores = living_cores
		if _active_cores.is_empty():
			_spawn_boss()
	elif _objective_phase == "boss":
		if _boss == null or not is_instance_valid(_boss):
			_objective_phase = "cleared"
			_game_over = true
			objective_state_label = "Forest cleared"
			boss_status_label = ""
			game_over_prompt = "Treent Overlord defeated. Click or press R to return to Esseloria."

func _begin_core_objective() -> void:
	if _objective_phase != "waves":
		return
	_objective_phase = "cores"
	objective_state_label = "Destroy the forest cores"
	if arena.has_method("get_core_positions"):
		var core_positions: Array[Vector2] = arena.get_core_positions()
		_core_count_total = core_positions.size()
		for point in core_positions:
			_spawn_enemy(OBJECTIVE_CORE_SCENE, point - player.global_position)

func _spawn_boss() -> void:
	if _objective_phase != "cores":
		return
	_objective_phase = "boss"
	objective_state_label = "Treent Overlord awakened"
	_xp_system.add_xp(core_reward_xp)
	if arena.has_method("get_boss_spawn_position"):
		_spawn_enemy(TREENT_BOSS_SCENE, arena.get_boss_spawn_position() - player.global_position)

func _find_nearest_enemy(origin: Vector2) -> Node2D:
	var best: Node2D
	var best_d2: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var d2: float = origin.distance_squared_to((enemy as Node2D).global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = enemy
	return best

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			list.append(enemy)
	list.sort_custom(Callable(self, "_sort_nodes_by_distance").bind(origin))
	return list

func _get_sorted_enemies_by_cursor_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = _get_sorted_enemies_by_distance(origin)
	list.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
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

func _sort_nodes_by_distance(a: Node2D, b: Node2D, origin: Vector2) -> bool:
	return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)

func _update_targeting() -> void:
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	var aim_point: Vector2
	if nearest != null and is_instance_valid(nearest):
		_current_target = nearest
		aim_point = nearest.global_position
		var label_name: String = str(_current_target.get("display_name"))
		target_label = "%s (%.0f HP)" % [label_name, _current_target.get("health")]
	else:
		_current_target = null
		target_label = "Auto Aim"
		var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if move.length_squared() > 0.01:
			aim_point = player.global_position + move.normalized() * 200.0
		else:
			aim_point = player.global_position + player.aim_direction * 200.0
	player.set_aim_target(aim_point)

func _handle_enemy_contact_damage() -> void:
	if _contact_timer < contact_damage_interval:
		return
	_contact_timer = 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if player.global_position.distance_to(node.global_position) <= 26.0:
			player.take_damage(float(node.get("contact_damage")))
			if _game_over:
				return

func _spawn_hit_feedback(at: Vector2, kind: String = "arcane") -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		match kind:
			"sniper":
				fx.configure(Color(0.86, 0.96, 1.0, 0.96), "heavy", 7.0, 26.0, 0.16)
			"heavy":
				fx.configure(Color(1.0, 0.94, 0.74, 0.96), "heavy", 7.0, 24.0, 0.15)
			_:
				fx.configure(Color(0.74, 0.96, 1.0, 0.82), "arrow", 3.0, 14.0, 0.09)
	effects.add_child(fx)

func _spawn_death_feedback(at: Vector2) -> void:
	var fx: Node2D = DEATH_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.86, 0.56, 0.92), 6.0, 24.0, 0.22)
	effects.add_child(fx)

func _spawn_trail(from: Vector2, to: Vector2, tint: Color, width: float) -> void:
	var fx: Node2D = TRAIL_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	if fx.has_method("setup"):
		fx.setup(Vector2.ZERO, to - from, tint, width)
	fx.global_position = from
	effects.add_child(fx)

func _on_enemy_damage_feedback(data: Dictionary) -> void:
	if bool(data.get("heavy_hit", false)) and not bool(data.get("suppress_impact_juice", false)):
		var kind: String = str(data.get("hit_kind", "arcane"))
		if kind != "sniper":
			_spawn_hit_feedback(Vector2(data.get("world_position", Vector2.ZERO)), "heavy")
	if _combat_juice != null:
		_combat_juice.trigger_enemy_hit(data)

func _on_enemy_killed(enemy: Node) -> void:
	var counts_as_kill: bool = bool(enemy.get("counts_as_kill")) if _node_has_property(enemy, "counts_as_kill") else true
	if counts_as_kill:
		kills += 1
	if enemy is Node2D:
		_spawn_death_feedback((enemy as Node2D).global_position)
	var reward: int = int(enemy.get("xp_reward"))
	_xp_system.add_xp(reward)
	if enemy.is_in_group("objective_core"):
		var remaining_cores: Array[Node2D] = []
		for core in _active_cores:
			if is_instance_valid(core) and core != enemy:
				remaining_cores.append(core)
		_active_cores = remaining_cores
		objective_state_label = "Destroy the forest cores (%d left)" % _active_cores.size()
	elif enemy.is_in_group("boss"):
		_boss = null
		_objective_phase = "cleared"
		_game_over = true
		objective_state_label = "Forest cleared"
		boss_status_label = ""
		game_over_prompt = "Treent Overlord defeated. Click or press R to return to Esseloria."
	if _xp_system.has_pending_level_up() and _upgrade_choices.is_empty():
		_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, RunConfig.CLASS_ARCANE_PISTOL)
		if _upgrade_choices.is_empty():
			return
		_clear_combat_juice()
		_manual_pause = false
		_profile_overlay_open = false
		_selected_upgrade_index = 0
		_sync_upgrade_display()
		get_tree().paused = true

func _on_player_died() -> void:
	_clear_combat_juice()
	get_tree().paused = false
	_game_over = true
	game_over_prompt = "You fell. Click or press R to return to Esseloria."

func _on_player_damaged(amount: float) -> void:
	_spawn_hit_feedback(player.global_position, "arcane")
	if _combat_juice != null:
		_combat_juice.trigger_player_hit({
			"amount": amount,
		})

func _handle_upgrade_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		_selected_upgrade_index = posmod(_selected_upgrade_index - 1, _upgrade_choices.size())
		_sync_upgrade_display()
	elif Input.is_action_just_pressed("move_right"):
		_selected_upgrade_index = posmod(_selected_upgrade_index + 1, _upgrade_choices.size())
		_sync_upgrade_display()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
		_apply_upgrade(_upgrade_choices[_selected_upgrade_index].get("id", ""))
		_upgrade_choices.clear()
		_sync_upgrade_display()
		get_tree().paused = false
		_upgrade_prompt()

func _apply_upgrade(upgrade_id: String) -> void:
	_upgrade_counts[upgrade_id] = int(_upgrade_counts.get(upgrade_id, 0)) + 1
	match upgrade_id:
		"charged_rounds":
			_primary_damage_multiplier *= 1.2
		"quickdraw":
			_primary_rate_multiplier *= 1.15
		"spellclock":
			_missiles_cooldown_multiplier *= 0.82
		"satellite_volley":
			_missiles_count_bonus += 1
		"phase_stride":
			_move_speed_multiplier *= 1.12
			player.move_speed = ARCANE_BASE_MOVE_SPEED * _move_speed_multiplier
		"deadeye":
			_sniper_damage_multiplier *= 1.25
			_sniper_pierce_bonus += 1
	if _xp_system.has_pending_level_up():
		_xp_system.consume_level_up()

func _update_status_cache() -> void:
	current_level = _xp_system.level
	current_health = float(player.get("health"))
	max_health = float(player.get("max_health"))
	xp_percent = _xp_system.get_progress()
	enemy_count = get_tree().get_nodes_in_group("enemies").size()
	primary_mode_label = "SNIPER" if _sniper_remaining > 0.0 else "READY"
	var missiles_remaining: float = float(cooldown_system.get_remaining(MISSILES_COOLDOWN_KEY))
	ability_one_label = "READY" if missiles_remaining <= 0.0 else "%.1fs" % missiles_remaining
	var bomb_remaining: float = float(cooldown_system.get_remaining(BOMB_COOLDOWN_KEY))
	ability_two_label = "READY" if bomb_remaining <= 0.0 else "%.1fs" % bomb_remaining
	var blink_remaining: float = float(cooldown_system.get_remaining(BLINK_COOLDOWN_KEY))
	dash_label = "READY" if blink_remaining <= 0.0 else "%.1fs" % blink_remaining
	if _sniper_remaining > 0.0:
		ultimate_label = "%.1fs" % _sniper_remaining
	else:
		var remaining: float = float(cooldown_system.get_remaining(ULTIMATE_COOLDOWN_KEY))
		ultimate_label = "READY" if remaining <= 0.0 else "%.1fs" % remaining
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
	ability_slot_data["primary"]["summary"] = "Manual ranged pressure toward the cursor."
	ability_slot_data["primary"]["detail"] = "Arcane Pistol fires toward the cursor. While Arcane Sniper is active, those shots become slower heavy piercing rounds."
	ability_slot_data["ability_one"]["summary"] = "Single-target lock-on volley."
	ability_slot_data["ability_one"]["detail"] = "Arcane Missiles locks one enemy at cast time and sends the full missile volley into that target."
	ability_slot_data["ability_one"]["cooldown_show"] = missiles_remaining > 0.0
	ability_slot_data["ability_one"]["cooldown_fill"] = clampf(missiles_remaining / max(arcane_missiles_cooldown * _missiles_cooldown_multiplier, 0.001), 0.0, 1.0)
	ability_slot_data["ability_one"]["cooldown_seconds"] = missiles_remaining
	var primary_remaining: float = float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY))
	ability_slot_data["primary"]["cooldown_show"] = primary_remaining > 0.0
	ability_slot_data["primary"]["cooldown_fill"] = clampf(primary_remaining / max(primary_fire_cooldown if _sniper_remaining <= 0.0 else 0.62, 0.001), 0.0, 1.0)
	ability_slot_data["ability_two"]["summary"] = "Forward lob into a slowing damage zone."
	ability_slot_data["ability_two"]["detail"] = "Arcane Bomb throws a glowing arcane charge forward. The blast leaves behind a pulsing field that damages and lightly slows enemies inside it."
	ability_slot_data["ability_two"]["cooldown_show"] = bomb_remaining > 0.0
	ability_slot_data["ability_two"]["cooldown_fill"] = clampf(bomb_remaining / max(arcane_bomb_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["ability_two"]["cooldown_seconds"] = bomb_remaining
	ability_slot_data["dash"]["cooldown_show"] = blink_remaining > 0.0
	ability_slot_data["dash"]["cooldown_fill"] = clampf(blink_remaining / max(blink_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["dash"]["detail"] = "Blink repositions instantly toward the cursor and opens clean firing angles."
	ability_slot_data["primary"]["cooldown_seconds"] = primary_remaining
	ability_slot_data["dash"]["cooldown_seconds"] = blink_remaining
	var ultimate_remaining: float = _sniper_remaining if _sniper_remaining > 0.0 else float(cooldown_system.get_remaining(ULTIMATE_COOLDOWN_KEY))
	ability_slot_data["ultimate"]["cooldown_show"] = ultimate_remaining > 0.0
	ability_slot_data["ultimate"]["cooldown_fill"] = clampf(ultimate_remaining / max(arcane_sniper_duration if _sniper_remaining > 0.0 else arcane_sniper_cooldown, 0.001), 0.0, 1.0)
	ability_slot_data["ultimate"]["cooldown_seconds"] = ultimate_remaining
	ability_slot_data["primary"]["charge_pips_total"] = 0
	ability_slot_data["primary"]["charge_pips_filled"] = 0
	ability_slot_data["ability_one"]["charge_pips_total"] = 0
	ability_slot_data["ability_one"]["charge_pips_filled"] = 0
	ability_slot_data["ability_two"]["charge_pips_total"] = 0
	ability_slot_data["ability_two"]["charge_pips_filled"] = 0
	ability_slot_data["dash"]["charge_pips_total"] = 0
	ability_slot_data["dash"]["charge_pips_filled"] = 0
	ability_slot_data["ultimate"]["charge_pips_total"] = 0
	ability_slot_data["ultimate"]["charge_pips_filled"] = 0
	match _objective_phase:
		"waves":
			objective_state_label = "Forest assault: %d / %d kills to cores" % [min(kills, core_objective_kill_threshold), core_objective_kill_threshold]
			objective_progress = clamp(float(kills) / float(max(core_objective_kill_threshold, 1)), 0.0, 1.0)
			progress_panel_title = "BOSS PROGRESS"
			progress_panel_detail = "Core threshold %d / %d" % [min(kills, core_objective_kill_threshold), core_objective_kill_threshold]
			progress_panel_value = objective_progress
		"cores":
			objective_state_label = "Destroy the forest cores (%d left)" % _active_cores.size()
			if _core_count_total > 0:
				objective_progress = clamp(float(_core_count_total - _active_cores.size()) / float(_core_count_total), 0.0, 1.0)
			else:
				objective_progress = 0.0
			progress_panel_title = "BOSS PROGRESS"
			progress_panel_detail = "%d cores remain before boss wake-up" % _active_cores.size()
			progress_panel_value = objective_progress
		"portal":
			progress_panel_title = "BOSS PORTAL"
			progress_panel_detail = "Portal unavailable in Arcane prototype"
			progress_panel_value = 1.0
		"boss":
			objective_state_label = "Defeat the Treent Overlord"
			if _boss != null and is_instance_valid(_boss):
				objective_progress = clamp(1.0 - (float(_boss.get("health")) / max(float(_boss.get("max_health")), 1.0)), 0.0, 1.0)
			else:
				objective_progress = 0.0
			progress_panel_title = "TREENT OVERLORD"
			progress_panel_detail = "Boss health and phase pressure"
			progress_panel_value = objective_progress
		"cleared":
			objective_state_label = "Forest cleared"
			objective_progress = 1.0
			progress_panel_title = "FOREST CLEARED"
			progress_panel_detail = "Prototype route complete"
			progress_panel_value = 1.0
	if _boss != null and is_instance_valid(_boss):
		var boss_phase: int = int(_boss.get("phase"))
		var boss_mechanic: String = str(_boss.get("territory_label"))
		boss_status_label = "Boss HP %.0f / %.0f | Phase %d%s" % [
			float(_boss.get("health")),
			float(_boss.get("max_health")),
			boss_phase,
			"" if boss_mechanic.is_empty() else " | %s" % boss_mechanic,
		]
		if _objective_phase == "boss":
			progress_panel_detail = boss_status_label
	else:
		boss_status_label = ""
	profile_data = {
		"title": "Run Profile",
		"subtitle": "Arcane Pistol prototype snapshot",
		"summary_text": "\n".join([
			"Class: Arcane Pistol",
			"Run Time: %s" % _format_run_time(run_time),
			"Level %d | XP %d%%" % [current_level, int(round(xp_percent * 100.0))],
			"Kills: %d | Enemies: %d" % [kills, enemy_count],
			"Objective: %s" % objective_state_label,
		]),
		"stats_text": "\n".join([
			"HP %d / %d" % [int(round(current_health)), int(round(max_health))],
			"Primary Damage %.1f" % (CombatBalance.ARCANE_PISTOL_BASE_DAMAGE * _primary_damage_multiplier),
			"Sniper Damage %.1f" % (CombatBalance.ARCANE_SNIPER_BASE_DAMAGE * _primary_damage_multiplier * _sniper_damage_multiplier),
			"Attack Speed x%.2f" % _primary_rate_multiplier,
			"Move Speed x%.2f" % _move_speed_multiplier,
			"Missile Cooldown x%.2f" % _missiles_cooldown_multiplier,
			"Bomb Cooldown %.1fs" % arcane_bomb_cooldown,
		]),
		"upgrades_text": _build_upgrade_profile_text(),
	}
	_upgrade_prompt()

func _build_upgrade_profile_text() -> String:
	var lines: Array[String] = []
	for upgrade_id in _upgrade_counts.keys():
		var entry: Dictionary = UpgradeCatalog.get_upgrade_definition(str(upgrade_id), RunConfig.CLASS_ARCANE_PISTOL)
		var name: String = str(entry.get("name", upgrade_id))
		lines.append("%s x%d" % [name, int(_upgrade_counts.get(upgrade_id, 0))])
	if lines.is_empty():
		lines.append("No upgrades acquired yet.")
	lines.sort()
	return "\n".join(lines)

func _format_run_time(total_seconds: float) -> String:
	var seconds: int = int(floor(total_seconds))
	var minutes: int = seconds / 60
	var remainder: int = seconds % 60
	return "%02d:%02d" % [minutes, remainder]

func _should_auto_fire_primary() -> bool:
	if not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const ARCANE_PRIMARY_RANGE: float = 520.0
	return player.global_position.distance_squared_to(nearest.global_position) <= ARCANE_PRIMARY_RANGE * ARCANE_PRIMARY_RANGE

func _should_auto_cast_missiles() -> bool:
	if not cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const MISSILES_AUTO_RANGE: float = 400.0
	return player.global_position.distance_squared_to(nearest.global_position) <= MISSILES_AUTO_RANGE * MISSILES_AUTO_RANGE

func _should_auto_cast_bomb() -> bool:
	if not cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const BOMB_AUTO_RANGE: float = 350.0
	return player.global_position.distance_squared_to(nearest.global_position) <= BOMB_AUTO_RANGE * BOMB_AUTO_RANGE

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

func _on_boss_bark_shot(origin: Vector2, target: Vector2, speed: float, damage: float) -> void:
	var bark: Area2D = ENEMY_BARK_SCENE.instantiate() as Area2D
	if bark == null:
		return
	bark.global_position = origin
	bark.set("direction", origin.direction_to(target))
	bark.set("speed", speed)
	bark.set("damage", damage)
	projectiles.add_child(bark)

func _on_encompass_root(duration: float) -> void:
	player.apply_root(duration)

func _on_territory_started() -> void:
	boss_status_label = "Treent Overlord | Encompass Root"

func _on_territory_ended() -> void:
	pass

func _upgrade_prompt() -> void:
	if _upgrade_choices.is_empty():
		upgrade_prompt = ""
		upgrade_choices_display.clear()
		selected_upgrade_index_display = -1
		return
	var lines: Array[String] = ["Level Up - Move Left/Right, Click or R to confirm"]
	for i in range(_upgrade_choices.size()):
		var prefix: String = "> " if i == _selected_upgrade_index else "  "
		var choice: Dictionary = _upgrade_choices[i]
		lines.append("%s%s: %s" % [prefix, choice.get("name", "Upgrade"), choice.get("description", "")])
	upgrade_prompt = ""
	for i in range(lines.size()):
		if i > 0:
			upgrade_prompt += "\n"
		upgrade_prompt += lines[i]

func _sync_upgrade_display() -> void:
	upgrade_choices_display = []
	for choice in _upgrade_choices:
		upgrade_choices_display.append(choice.duplicate(true))
	selected_upgrade_index_display = _selected_upgrade_index if not _upgrade_choices.is_empty() else -1

func request_upgrade_selection(index: int) -> void:
	if _upgrade_choices.is_empty():
		return
	if index < 0 or index >= _upgrade_choices.size():
		return
	_selected_upgrade_index = index
	_sync_upgrade_display()
	_apply_upgrade(str(_upgrade_choices[_selected_upgrade_index].get("id", "")))
	_upgrade_choices.clear()
	_sync_upgrade_display()
	get_tree().paused = false
	_upgrade_prompt()

func request_upgrade_hover(index: int) -> void:
	if _upgrade_choices.is_empty():
		return
	if index < 0 or index >= _upgrade_choices.size():
		return
	_selected_upgrade_index = index
	_sync_upgrade_display()

func request_toggle_pause() -> void:
	if not _upgrade_choices.is_empty() or _game_over:
		return
	_clear_combat_juice()
	if _profile_overlay_open:
		_profile_overlay_open = false
		_manual_pause = true
	else:
		_manual_pause = not _manual_pause
		if not _manual_pause:
			_profile_overlay_open = false
			_inventory_overlay_open = false
	get_tree().paused = _manual_pause
	_update_status_cache()

func request_toggle_profile() -> void:
	if _game_over or not _upgrade_choices.is_empty() or _inventory_overlay_open:
		return
	if _profile_overlay_open:
		request_close_profile()
	else:
		request_open_profile()

func request_toggle_inventory() -> void:
	if _inventory_overlay_open:
		request_close_inventory()
		return
	if _game_over or not _upgrade_choices.is_empty() or _manual_pause or _profile_overlay_open:
		return
	_clear_combat_juice()
	_inventory_overlay_open = true
	_manual_pause = true
	_profile_overlay_open = false
	get_tree().paused = true
	_update_status_cache()

func request_close_inventory() -> void:
	if not _inventory_overlay_open:
		return
	_clear_combat_juice()
	_inventory_overlay_open = false
	_manual_pause = false
	get_tree().paused = false
	_update_status_cache()

func _use_hotbar_slot(slot: int) -> void:
	if _game_over or _manual_pause or _inventory_overlay_open or _profile_overlay_open:
		return
	if not _upgrade_choices.is_empty():
		return
	if TownState == null:
		return
	var item_data: Dictionary = TownState.use_hotbar_item(slot)
	if item_data.is_empty():
		return
	var item_id: String = str(item_data.get("id", ""))
	if item_id == "hp_potion":
		var heal_amount: float = float(item_data.get("heal_amount", 250.0))
		if _player != null and _player.has_method("heal"):
			_player.heal(heal_amount)
			AudioDirector.play_ui("ui_confirm", -2.0) if AudioDirector != null else null

func request_resume_game() -> void:
	if _upgrade_choices.is_empty():
		_clear_combat_juice()
		_manual_pause = false
		_profile_overlay_open = false
		_inventory_overlay_open = false
		get_tree().paused = false
		_update_status_cache()

func request_open_profile() -> void:
	if _upgrade_choices.is_empty() and not _game_over:
		_clear_combat_juice()
		_manual_pause = true
		_profile_overlay_open = true
		_inventory_overlay_open = false
		get_tree().paused = true
		_update_status_cache()

func request_close_profile() -> void:
	if _profile_overlay_open:
		_clear_combat_juice()
		_profile_overlay_open = false
		_manual_pause = true
		_inventory_overlay_open = false
		get_tree().paused = true
		_update_status_cache()

func request_return_to_menu() -> void:
	_clear_combat_juice()
	_manual_pause = false
	_profile_overlay_open = false
	_inventory_overlay_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _return_to_hub() -> void:
	_clear_combat_juice()
	_manual_pause = false
	_profile_overlay_open = false
	_inventory_overlay_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file(HUB_SCENE_PATH)

func _apply_meta_progression_modifiers() -> void:
	var modifiers: Dictionary = MetaProgression.get_run_modifiers() if MetaProgression else {}
	_primary_damage_multiplier *= float(modifiers.get("damage_multiplier", 1.0))
	_move_speed_multiplier *= float(modifiers.get("move_speed_multiplier", 1.0))
	var health_bonus: float = float(modifiers.get("health_bonus", 0.0))
	player.max_health = CombatBalance.PLAYER_MAX_HEALTH + health_bonus
	player.health = player.max_health

func _clear_combat_juice() -> void:
	if _combat_juice != null:
		_combat_juice.clear_state()

func _node_has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.name) == property_name:
			return true
	return false

func _is_combat_enemy(enemy: Node) -> bool:
	return enemy.is_in_group("enemies") and not enemy.is_in_group("objective_core") and not enemy.is_in_group("boss_root")
