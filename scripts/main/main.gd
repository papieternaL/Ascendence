extends Node

const ElementalSystem = preload("res://scripts/systems/elemental_system.gd")
const CombatBalance = preload("res://scripts/systems/combat_balance.gd")
const CombatJuice = preload("res://scripts/systems/combat_juice.gd")
const CastTargeting = preload("res://scripts/systems/cast_targeting.gd")
const RarityChargeState = preload("res://scripts/systems/rarity_charge.gd")

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const CHASER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/ChaserEnemy.tscn")
const LUNGER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/LungerEnemy.tscn")
const SKELETON_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/SkeletonEnemy.tscn")
const WOLF_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/WolfEnemy.tscn")
const TREENT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/TreentEnemy.tscn")
const SMALL_TREENT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/SmallTreentEnemy.tscn")
const DEEPWOOD_STALKER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DeepwoodStalkerEnemy.tscn")
const BOSS_ROOT_SCENE: PackedScene = preload("res://scenes/enemies/BossRoot.tscn")
const OBJECTIVE_CORE_SCENE: PackedScene = preload("res://scenes/enemies/ObjectiveCore.tscn")
const PENTAGON_SHRINE_OBJECTIVE_SCENE: PackedScene = preload("res://scenes/objectives/PentagonShrineObjective.tscn")
const TREENT_BOSS_SCENE: PackedScene = preload("res://scenes/enemies/TreentBoss.tscn")
const BOSS_PORTAL_SCENE: PackedScene = preload("res://scenes/main/BossPortal.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/projectiles/Missile.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const ARCANE_BOMB_PROJECTILE_SCENE: PackedScene = preload("res://scenes/effects/ArcaneBombProjectile.tscn")
const ENEMY_BARK_SCENE: PackedScene = preload("res://scenes/projectiles/EnemyBarkShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")
const DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
const TRAIL_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/TrailEffect.tscn")
const GLOW_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/GlowEffect.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/DamageNumber.tscn")
const BOW_RELEASE_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/BowReleaseEffect.tscn")
const SPAWN_INDICATOR_SCENE: PackedScene = preload("res://scenes/effects/SpawnIndicator.tscn")
const FALLING_TRUNK_SCENE: PackedScene = preload("res://scenes/effects/FallingTrunk.tscn")
const BARK_VOLLEY_AOE_SCENE: PackedScene = preload("res://scenes/effects/BarkVolleyAOE.tscn")
const VINE_LANE_SCENE: PackedScene = preload("res://scenes/effects/VineLaneHazard.tscn")
const SPAWN_EXCLUSION_RING_SCENE: PackedScene = preload("res://scenes/effects/SpawnExclusionRing.tscn")
const REWARD_CHEST_SCENE: PackedScene = preload("res://scenes/enemies/RewardChest.tscn")
const DEEPWOOD_HAZARD_DIRECTOR_SCENE: PackedScene = preload("res://scenes/systems/DeepwoodHazardDirector.tscn")

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
const ARCANE_PRIMARY_RANGE: float = 520.0
const ARCANE_PRIMARY_FIRE_COOLDOWN: float = 0.25
const ARCANE_BLINK_COOLDOWN: float = 1.2
const ARCANE_MISSILES_COOLDOWN: float = 5.0
const ARCANE_BOMB_COOLDOWN: float = 8.0
const ARCANE_SNIPER_COOLDOWN: float = 18.0
const ARCANE_SNIPER_DURATION: float = 7.0
const HUB_SCENE_PATH: String = "res://scenes/hub/EsseloriaHub.tscn"
const OBJECTIVE_CORES: String = "destroy_cores"
const OBJECTIVE_PENTAGON_SHRINE: String = "pentagon_shrine"

@export var primary_fire_cooldown: float = 0.8
@export var primary_attack_range: float = 350.0
@export var dash_cooldown: float = 0.9
@export var power_shot_cooldown: float = 12.0
@export var arrow_volley_cooldown: float = 14.4
@export var spawn_warning_time: float = 0.72
@export var enemy_spawn_interval: float = 1.91
@export var max_active_enemies: int = 14
@export var contact_damage_interval: float = 0.68
@export var core_reward_xp: int = 45
@export var major_progress_max: float = 100.0
@export var major_progress_per_kill: float = 0.5
@export var deepwood_objective_slots: int = 3
@export var objective_transition_delay: float = 1.0
@export var objective_thresholds: Array[float] = [25.0, 50.0, 75.0]
@export var objective_completion_progress_bonus: float = 12.0
@export var objective_completion_xp_reward: int = 60
@export var objective_time_limit: float = 70.0
@export var core_objective_time_limit: float = 120.0
@export var shrine_objective_time_limit: float = 70.0
@export var shrine_objective_required_count: int = 3
@export var core_objective_available_count: int = 18
@export var core_objective_required_count: int = 15
@export var enemy_move_speed_multiplier: float = 1.38
@export var enemy_contact_damage_multiplier: float = 1.15
@export var enemy_health_multiplier: float = 1.2
@export var enemy_attack_windup_multiplier: float = 0.72
@export var power_hit_shake_intensity: float = 2.1
@export var crit_hit_shake_intensity: float = 2.4
@export var sentinel_hit_shake_intensity: float = 2.2
@export var elite_hit_shake_intensity: float = 2.6
@export var boss_hit_shake_intensity: float = 3.0
@export var strong_hit_shake_duration: float = 0.11

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

@onready var power_shot_ability: Node2D = $World/Entities/Player/AbilityAnchor/PowerShot
@onready var arrow_volley_ability: Node2D = $World/Entities/Player/AbilityAnchor/ArrowVolley
@onready var sentinel_ability: Node2D = $World/Entities/Player/AbilityAnchor/Sentinel
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
var pending_spawn_count: int = 0
var run_time: float = 0.0
var target_label: String = "None"
var primary_mode_label: String = "READY"
var ability_one_label: String = "READY"
var dash_label: String = "READY"
var ability_two_label: String = "READY"
var ultimate_label: String = "0%"
var objective_state_label: String = "Prepare for the Deepwood trial"
var boss_status_label: String = ""
var objective_progress: float = 0.0
var progress_panel_title: String = "BOSS PROGRESS"
var progress_panel_detail: String = "Build pressure in Deepwood"
var progress_panel_value: float = 0.0
var progress_bar_mode: String = "thresholds"
var progress_threshold_markers: Array[float] = [0.25, 0.5, 0.75]
var progress_bar_show_markers: bool = true
## Top-left objective callout (under run timer)
var objective_hud_visible: bool = false
var objective_hud_headline: String = ""
var objective_hud_progress_line: String = ""
var objective_hud_timer_line: String = ""
var active_primary_element: String = ""
var profile_data: Dictionary = {}
var upgrade_prompt: String = ""
var upgrade_overlay_title: String = ""
var game_over_prompt: String = ""
var upgrade_choices_display: Array[Dictionary] = []
var selected_upgrade_index_display: int = -1
var upgrade_display_version: int = 0
var ability_slot_data: Dictionary = {
	"primary": {"id": "primary", "action": "primary_fire", "key": "LMB", "targeting_type": "directional", "preview_kind": "line", "icon_id": "bow", "icon_asset_id": "archer_hunters_bow", "label": "Hunter's Bow", "summary": "Hold to fire; snaps toward nearby targets.", "detail": "Hunter's Bow fires toward the nearest enemy in range. Hold the attack button or let soft-lock assist fire when your cursor is near a target.", "state_text": "READY"},
	"ability_one": {"id": "ability_one", "action": "ability_1", "key": "Shift", "targeting_type": "directional", "preview_kind": "line", "icon_id": "power_shot", "icon_asset_id": "archer_power_shot", "label": "Power Shot", "summary": "Manual heavy shot toward the cursor.", "detail": "Power Shot fires a guaranteed-critical piercing arrow in the direction you aim. Use Shift when you want a precise lane burst.", "state_text": "READY"},
	"ability_two": {"id": "ability_two", "action": "ability_2", "key": "E", "targeting_type": "directional", "preview_kind": "cone", "icon_id": "arrow_volley", "icon_asset_id": "archer_arrow_volley", "label": "Arrow Volley", "summary": "Fan arrows toward the nearest threat.", "detail": "Arrow Volley snaps toward the nearest enemy so you can clear packs without pixel-perfect aim.", "state_text": "READY"},
	"dash": {"id": "dash", "action": "dash", "key": "SPACE", "targeting_type": "directional", "preview_kind": "dash", "icon_id": "dash", "icon_asset_id": "archer_dash", "label": "Dash", "summary": "Dash toward the cursor.", "detail": "Dash is Archer's manual escape and angle-correction tool. Aim it with the cursor to dodge pressure and keep spacing.", "state_text": "READY"},
	"ultimate": {"id": "ultimate", "action": "ultimate", "key": "R", "targeting_type": "instant", "preview_kind": "", "icon_id": "sentinel", "icon_asset_id": "archer_sentinel", "label": "Sentinel", "summary": "Summon a hawk when the meter is full.", "detail": "Sentinel summons an autonomous hawk that hunts nearby enemies, cores, and roots for a short active window.", "state_text": "0%"},
}

var _xp_system: ExperienceSystem = ExperienceSystem.new()
var _rarity_charge: RarityCharge = RarityChargeState.new()
var _current_target: Node2D
var _boss: Node2D
var _boss_portal: Area2D
var _objective_phase: String = "objectives"
var _active_cores: Array[Node2D] = []
var _core_count_total: int = 0
var _destroyed_core_count: int = 0
var _contact_timer: float = 0.0
var _game_over: bool = false
var _in_boss_arena: bool = false
var _manual_pause: bool = false
var _profile_overlay_open: bool = false
var _inventory_overlay_open: bool = false
var _upgrade_choices: Array[Dictionary] = []
var _selected_upgrade_index: int = 0
var _upgrade_overlay_mode: String = ""
var _upgrade_overlay_context: Dictionary = {}
var _upgrade_rerolls_remaining: int = 2
var _xp_pickup_radius_multiplier: float = 1.0
var _boss_roots: Array[Node2D] = []
var _major_progress: float = 0.0
var _objective_queue: Array[String] = []
var _objective_positions: Array[Vector2] = []
var _current_objective_type: String = ""
var _current_objective_index: int = -1
var _completed_objective_count: int = 0
var _objective_transition_timer: float = 0.0
var _objective_time_remaining: float = 0.0
var _objective_notice_time_remaining: float = 0.0
var _objective_notice_headline: String = ""
var _objective_notice_progress_line: String = ""
var _objective_notice_timer_line: String = ""
var _active_shrine_objectives: Array[Node2D] = []
var _completed_shrine_count: int = 0
var _active_shrine_progress_bonus: float = 16.0
var _active_elite: Node2D
var _reward_chest: Node2D
var _spawn_exclusion_ring: Node2D
var _hazard_director: Node
var _awaiting_reward_chest: bool = false
var _awaiting_elite_encounter: bool = false
var _pending_elite_reward_chest: bool = false
var _trunk_spawn_timer: float = 0.0
var _trunk_interval_phase1: float = 2.2
var _trunk_interval_phase2: float = 1.5
var _trunk_damage_phase1: float = CombatBalance.FALLING_TRUNK_DAMAGE_PHASE1
var _trunk_damage_phase2: float = CombatBalance.FALLING_TRUNK_DAMAGE_PHASE2
var _bark_volley_timer: float = 0.0
var _bark_volley_cooldown: float = 3.5
var _bark_volley_phase2_mult: float = 0.75
var _bark_volley_placement_radius: float = 120.0
var _territory_lane_count: int = 5
var _territory_lane_damage: float = CombatBalance.TERRITORY_LANE_DAMAGE
var _pending_spawn_indicator_ids: Dictionary = {}

var _primary_damage_multiplier: float = 1.0
var _primary_rate_multiplier: float = 1.0
var _move_speed_multiplier: float = 1.0
var _selected_weapon_id: String = RunConfig.CLASS_ARCHER
var _primary_pierce_bonus: int = 0
var _arrow_volley_damage_multiplier: float = 1.0
var _arrow_volley_bonus_arrows: int = 0
var _dash_cooldown_multiplier: float = 1.0
var _dash_charge_count: int = 1
var _dash_charge_max: int = 1
var _dash_recharge_timer: float = 0.0
var _sentinel_duration_bonus: float = 0.0
var _sentinel_damage_bonus: float = 0.0
var _sentinel_attack_rate_multiplier: float = 1.0
var _crit_chance: float = 0.05
var _crit_multiplier: float = 1.5
var _split_shot_enabled: bool = false
var _shots_fired: int = 0
var _arrow_storm_enabled: bool = false
var _ricochet_bounces: int = 0
var _explosive_arrow_volley_enabled: bool = false
var _deadeye_bloom_enabled: bool = false
var _missiles_count_bonus: int = 0
var _missiles_cooldown_multiplier: float = 1.0
var _sniper_damage_multiplier: float = 1.0
var _sniper_pierce_bonus: int = 0
var _sniper_remaining: float = 0.0
var _upgrade_counts: Dictionary = {}
var _upgrade_history: Array[Dictionary] = []
var _burn_damage_multiplier: float = 1.0
var _ice_chill_duration_bonus: float = 0.0
var _ice_slow_mul: float = 1.0
var _freeze_spread_enabled: bool = false
var _ice_blast_enabled: bool = false
var _ice_blast_radius_bonus: float = 0.0
var _lightning_chain_bonus_jumps: int = 0
var _profile_data_dirty: bool = true
var _combat_juice: CombatJuice
var _pending_directional_action: String = ""

func _weapon_is_arcane() -> bool:
	return _selected_weapon_id == RunConfig.CLASS_ARCANE_PISTOL

func _current_targeting_class_id() -> String:
	return CastTargeting.CLASS_ARCANE_PISTOL if _weapon_is_arcane() else CastTargeting.CLASS_ARCHER

func _get_base_move_speed() -> float:
	return ARCANE_BASE_MOVE_SPEED if _weapon_is_arcane() else ARCHER_BASE_MOVE_SPEED

func _build_slot_entry(slot_id: String, ability_data: Dictionary) -> Dictionary:
	return {
		"id": slot_id,
		"action": str(ability_data.get("action", "")),
		"key": str(ability_data.get("key", "")),
		"targeting_type": str(ability_data.get("targeting_type", "")),
		"preview_kind": str(ability_data.get("preview_kind", "")),
		"icon_id": str(ability_data.get("icon", "default")),
		"icon_asset_id": str(ability_data.get("icon_asset_id", ability_data.get("icon", "default"))),
		"label": str(ability_data.get("name", "")),
		"summary": str(ability_data.get("summary", "")),
		"detail": str(ability_data.get("detail", "")),
		"state_text": "READY",
	}

func _build_weapon_ability_slot_data(class_id: String) -> Dictionary:
	var slots: Dictionary = {}
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) != class_id:
			continue
		for ability in class_data.get("abilities", []):
			if not (ability is Dictionary):
				continue
			var ability_data: Dictionary = ability as Dictionary
			match str(ability_data.get("action", "")):
				"primary_fire":
					slots["primary"] = _build_slot_entry("primary", ability_data)
				"ability_1":
					slots["ability_one"] = _build_slot_entry("ability_one", ability_data)
				"ability_2":
					slots["ability_two"] = _build_slot_entry("ability_two", ability_data)
				"dash":
					slots["dash"] = _build_slot_entry("dash", ability_data)
				"ultimate":
					slots["ultimate"] = _build_slot_entry("ultimate", ability_data)
		break
	return slots

func _configure_selected_weapon_loadout() -> void:
	_selected_weapon_id = RunConfig.selected_class_id
	if _selected_weapon_id != RunConfig.CLASS_ARCANE_PISTOL:
		_selected_weapon_id = RunConfig.CLASS_ARCHER
	ability_slot_data = _build_weapon_ability_slot_data(_selected_weapon_id)
	if _weapon_is_arcane():
		player.mobility_style = "blink"
		player.weapon_style = "pistol"
		if arcane_sniper_ability != null:
			arcane_sniper_ability.set("duration", ARCANE_SNIPER_DURATION)
			arcane_sniper_ability.set("cooldown", ARCANE_SNIPER_COOLDOWN)
	else:
		player.mobility_style = "dash"
		player.weapon_style = "bow"
		if sentinel_ability != null:
			sentinel_ability.set("duration", 8.0 + _sentinel_duration_bonus)

func _bind_hud_for_selected_weapon() -> void:
	if hud == null:
		return
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		if _weapon_is_arcane():
			hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, MISSILES_COOLDOWN_KEY, BOMB_COOLDOWN_KEY, BLINK_COOLDOWN_KEY, ULTIMATE_COOLDOWN_KEY)
		else:
			hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, POWER_SHOT_COOLDOWN_KEY, ARROW_VOLLEY_COOLDOWN_KEY, DASH_COOLDOWN_KEY, StringName())
	if hud.has_method("bind_game"):
		hud.bind_game(self)

func _get_selected_weapon_name() -> String:
	for class_data in RunConfig.get_class_data():
		if str(class_data.get("id", "")) == _selected_weapon_id:
			return str(class_data.get("name", "WEAPON"))
	return "WEAPON"

func _ready() -> void:
	AudioDirector.set_music_context("run")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	## Gameplay nodes must be PAUSABLE so get_tree().paused stops the world during upgrade overlay.
	## Main + UI stay ALWAYS for upgrade input and HUD.
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
	_dash_charge_count = _dash_charge_max
	if boss_arena:
		boss_arena.visible = false
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	_configure_selected_weapon_loadout()
	_apply_active_arena_limits(arena)
	var ui_layer: CanvasLayer = get_node_or_null("UI")
	if ui_layer:
		ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		ui_layer.visible = true
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.visible = true
	_bind_hud_for_selected_weapon()
	_combat_juice = CombatJuice.new()
	add_child(_combat_juice)
	_combat_juice.setup(player)
	if xp_orb_field != null and xp_orb_field.has_method("setup"):
		xp_orb_field.setup(_xp_system, player)
	if _hazard_director != null and is_instance_valid(_hazard_director):
		_hazard_director.queue_free()
	_hazard_director = DEEPWOOD_HAZARD_DIRECTOR_SCENE.instantiate()
	if _hazard_director != null:
		if _hazard_director.has_method("setup"):
			_hazard_director.setup(player, arena, effects, get_node_or_null("UI"))
		if has_node("Systems"):
			$Systems.add_child(_hazard_director)
		else:
			add_child(_hazard_director)
	if _spawn_exclusion_ring != null and is_instance_valid(_spawn_exclusion_ring):
		_spawn_exclusion_ring.queue_free()
		_spawn_exclusion_ring = null
	if player.has_signal("died"):
		player.connect("died", Callable(self, "_on_player_died"))
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_damaged.connect(_on_player_damaged)
	_apply_meta_progression_modifiers()
	player.move_speed = _get_base_move_speed() * _move_speed_multiplier
	if _weapon_is_arcane():
		player.weapon_style = "pistol"
	else:
		player.weapon_style = "bow"
		if sentinel_ability:
			sentinel_ability.set("duration", 8.0 + _sentinel_duration_bonus)
	if RunConfig.boss_test_requested:
		RunConfig.boss_test_requested = false
		_enter_boss_test()
	else:
		_spawn_opening_wave()
		_setup_deepwood_objectives()
		GameEvents.wave_started.emit(wave_number)

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
	if _game_over:
		_clear_pending_directional_cast()
		_update_status_cache()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
			_return_to_hub()
		return
	if _upgrade_choices.size() > 0:
		_clear_pending_directional_cast()
		_handle_upgrade_input()
		return
	if _xp_system.has_pending_level_up():
		_clear_pending_directional_cast()
		_open_upgrade_overlay()
		_update_status_cache()
		return
	if _manual_pause or _profile_overlay_open or _inventory_overlay_open:
		_clear_pending_directional_cast()
		_update_status_cache()
		return
	run_time += delta
	if _weapon_is_arcane():
		if arcane_sniper_ability and arcane_sniper_ability.has_method("tick"):
			arcane_sniper_ability.tick(delta)
			_sniper_remaining = float(arcane_sniper_ability.get_remaining())
		player.weapon_style = "sniper" if _sniper_remaining > 0.0 else "pistol"
	elif sentinel_ability and sentinel_ability.has_method("tick"):
		sentinel_ability.tick(delta)
	_rarity_charge.tick(run_time)
	if not _weapon_is_arcane():
		_tick_dash_recharge(delta)
	_update_objective_flow()
	_update_deepwood_hazard_runtime()
	_update_targeting()
	_handle_combat_input()
	_handle_spawning()
	_handle_boss_hazards(delta)
	var active_arena: Node2D = boss_arena if _in_boss_arena else arena
	if active_arena != null and active_arena.has_method("clamp_position"):
		player.global_position = active_arena.clamp_position(player.global_position)
	_update_status_cache()

func _handle_combat_input() -> void:
	if GameSettings != null and GameSettings.uses_indicator_release_cast():
		_handle_indicator_release_combat_input()
	else:
		_clear_pending_directional_cast()
		_handle_quick_cast_combat_input()
	if _weapon_is_arcane():
		if Input.is_action_just_pressed("ultimate") and cooldown_system.is_ready(ULTIMATE_COOLDOWN_KEY) and arcane_sniper_ability and arcane_sniper_ability.has_method("activate"):
			if arcane_sniper_ability.activate(cooldown_system, ULTIMATE_COOLDOWN_KEY):
				AudioDirector.play_sfx("arcane_sniper", -4.0)
				_sniper_remaining = float(arcane_sniper_ability.get_remaining())
				GameEvents.ability_used.emit(ULTIMATE_COOLDOWN_KEY)
				_update_status_cache()
		return
	if Input.is_action_just_pressed("ultimate") and sentinel_ability and sentinel_ability.has_method("activate"):
		if sentinel_ability.activate():
			var hawk: Node2D = sentinel_ability.spawn_hawk(
				player,
				effects,
				CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier * (1.0 + _sentinel_damage_bonus),
				_get_crit_chance(),
				_crit_multiplier
			)
			if hawk != null:
				if _node_has_property(hawk, "strike_interval"):
					hawk.set("strike_interval", float(hawk.get("strike_interval")) / max(_sentinel_attack_rate_multiplier, 0.01))
				if hawk.has_signal("strike"):
					hawk.connect("strike", Callable(self, "_on_sentinel_strike"))
				if hawk.has_signal("swoop"):
					hawk.connect("swoop", Callable(self, "_spawn_trail"))
				_spawn_hit_feedback(player.global_position, "sentinel")
				_spawn_glow(player.global_position, Color(1.0, 0.9, 0.46, 0.3), 14.0, 34.0, 0.18, "heat")
			GameEvents.ability_used.emit(&"sentinel")
			_update_status_cache()

func _handle_quick_cast_combat_input() -> void:
	if _weapon_is_arcane():
		if (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
			_fire_arcane_primary()
		if (Input.is_action_just_pressed("ability_1") or _should_auto_cast_missiles()) and cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
			_cast_arcane_missiles()
		if (Input.is_action_just_pressed("ability_2") or _should_auto_cast_bomb()) and cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
			_cast_arcane_bomb()
		if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(BLINK_COOLDOWN_KEY):
			_cast_arcane_blink()
		return
	if (Input.is_action_pressed("primary_fire") or _should_auto_fire_primary()) and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		_fire_primary_arrow()
	if (Input.is_action_just_pressed("ability_1") or _should_auto_cast_power_shot()) and cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY):
		_cast_power_shot()
	if (Input.is_action_just_pressed("ability_2") or _should_auto_cast_arrow_volley()) and cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		_cast_arrow_volley()
	if Input.is_action_just_pressed("dash") and _dash_charge_count > 0:
		_cast_archer_dash()

func _handle_indicator_release_combat_input() -> void:
	_pending_directional_action = CastTargeting.process_indicator_release_input(
		player,
		_pending_directional_action,
		CastTargeting.get_directional_actions(_current_targeting_class_id()),
		Callable(self, "_can_prepare_directional_cast"),
		Callable(self, "_build_directional_cast_preview"),
		Callable(self, "_execute_directional_cast")
	)

func _can_prepare_directional_cast(action_name: String) -> bool:
	if _weapon_is_arcane():
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

func _execute_directional_cast(action_name: String) -> bool:
	if _weapon_is_arcane():
		match action_name:
			"primary_fire":
				return _fire_arcane_primary()
			"ability_1":
				return _cast_arcane_missiles()
			"ability_2":
				return _cast_arcane_bomb()
			"dash":
				return _cast_arcane_blink()
		return false
	match action_name:
		"primary_fire":
			return _fire_primary_arrow()
		"ability_1":
			return _cast_power_shot()
		"ability_2":
			return _cast_arrow_volley()
		"dash":
			return _cast_archer_dash()
	return false

func _cancel_pending_directional_cast() -> bool:
	if _pending_directional_action.is_empty():
		return false
	_clear_pending_directional_cast()
	return true

func _clear_pending_directional_cast() -> void:
	_pending_directional_action = ""
	CastTargeting.clear_player_preview(player)

func _build_directional_cast_preview(action_name: String) -> Dictionary:
	var direction: Vector2
	var preview_origin: Vector2 = player.global_position
	if action_name == "ability_1":
		direction = _get_manual_aim_direction()
	elif action_name == "primary_fire":
		direction = _get_primary_auto_aim_direction(player.get_muzzle_global_position())
	elif action_name == "ability_2":
		var ab: Node2D = player.get_node("AbilityAnchor") as Node2D
		if ab != null:
			preview_origin = ab.global_position
		if _weapon_is_arcane():
			var bomb_radius: float = float(arcane_bomb_ability.get("zone_radius")) if _node_has_property(arcane_bomb_ability, "zone_radius") else 78.0
			var bomb_range: float = float(arcane_bomb_ability.get("throw_distance")) if _node_has_property(arcane_bomb_ability, "throw_distance") else 220.0
			direction = _get_cluster_aim_direction(preview_origin, bomb_radius, bomb_range + bomb_radius)
		else:
			var volley_range: float = float(arrow_volley_ability.get("cast_range")) if arrow_volley_ability != null and arrow_volley_ability.get("cast_range") != null else 350.0
			direction = _get_cluster_aim_direction(preview_origin, 100.0, volley_range)
	else:
		direction = _get_auto_aim_direction(preview_origin)
	if _weapon_is_arcane():
		var missile_target: Node2D = _get_arcane_missile_target(_get_cursor_world_position())
		if action_name == "ability_1" and missile_target != null and is_instance_valid(missile_target):
			var locked_direction: Vector2 = preview_origin.direction_to(missile_target.global_position)
			if locked_direction.length_squared() > 0.0001:
				direction = locked_direction.normalized()
		return CastTargeting.build_preview(
			CastTargeting.CLASS_ARCANE_PISTOL,
			action_name,
			{
				"direction": direction,
				"primary_range": ARCANE_PRIMARY_RANGE,
				"missile_length": 210.0,
				"missile_count": 3 + _missiles_count_bonus,
				"missile_spread_degrees": float(arcane_missiles_ability.get("spread_degrees")) if _node_has_property(arcane_missiles_ability, "spread_degrees") else 12.0,
				"highlight_global_position": missile_target.global_position if missile_target != null and is_instance_valid(missile_target) else null,
				"bomb_length": float(arcane_bomb_ability.get("throw_distance")) if _node_has_property(arcane_bomb_ability, "throw_distance") else 220.0,
				"bomb_radius": float(arcane_bomb_ability.get("zone_radius")) if _node_has_property(arcane_bomb_ability, "zone_radius") else 78.0,
				"dash_length": float(player.get("dash_distance")) if _node_has_property(player, "dash_distance") else 170.0,
			}
		)
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

func _fire_primary_arrow() -> bool:
	var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
	if shot == null:
		return false

	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = _get_primary_auto_aim_direction(shot.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	shot.set("direction", direction)
	shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier)
	shot.set("speed", 500.0)
	shot.set("pierce_count", _primary_pierce_bonus)
	shot.set("crit_chance", _get_crit_chance())
	shot.set("crit_multiplier", _crit_multiplier)
	shot.set("visual_style", "arrow")
	shot.set("attack_payload", _build_primary_attack_payload(direction, "arrow"))

	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("arrow"))
	projectiles.add_child(shot)
	AudioDirector.play_sfx("bow_primary", -6.0)
	player.notify_primary_fired()
	_shots_fired += 1
	if _split_shot_enabled and _shots_fired % 3 == 0:
		_fire_split_shot_pair(direction)
	if _arrow_storm_enabled and _shots_fired % 8 == 0:
		_spawn_arrow_storm()
	_spawn_bow_release_effect(player.get_muzzle_global_position(), direction)
	_spawn_glow(player.get_muzzle_global_position(), Color(1.0, 0.86, 0.46, 0.28), 6.0, 18.0, 0.12)
	_spawn_trail(
		player.get_muzzle_global_position(),
		player.get_muzzle_global_position() + direction * 24.0,
		Color(1.0, 0.88, 0.54, 0.62),
		2.6,
		"arrow"
	)
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, primary_fire_cooldown / _get_attack_speed_multiplier())
	return true

func _cast_power_shot() -> bool:
	if power_shot_ability == null:
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null or not power_shot_ability.has_method("cast_in_direction"):
		return false
	var direction: Vector2 = _get_manual_aim_direction(ability_anchor.global_position)
	var shot: Area2D = power_shot_ability.cast_in_direction(ability_anchor, SNIPER_SCENE, projectiles, direction, CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier, _crit_multiplier)
	if shot == null:
		return false
	shot.set("visual_style", "power_arrow")
	shot.set("attack_payload", {
		"impact_direction": direction,
		"hit_kind": "power",
		"effects_parent": effects,
	})
	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("power"))
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, power_shot_cooldown)
	GameEvents.ability_used.emit(POWER_SHOT_COOLDOWN_KEY)
	AudioDirector.play_sfx("bow_power_shot", -4.5)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	_spawn_glow(player.get_muzzle_global_position(), Color(1.0, 0.78, 0.28, 0.42), 10.0, 28.0, 0.16)
	_spawn_trail(player.get_muzzle_global_position(), player.get_muzzle_global_position() + direction * 280.0, Color(1.0, 0.82, 0.35, 0.68), 4.8, "power")
	return true

func _cast_arrow_volley() -> bool:
	if arrow_volley_ability == null or not arrow_volley_ability.has_method("cast_in_direction"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var volley_range: float = float(arrow_volley_ability.get("cast_range")) if arrow_volley_ability.get("cast_range") != null else 350.0
	var direction: Vector2 = _get_cluster_aim_direction(ability_anchor.global_position, 100.0, volley_range)
	var shots: Array[Area2D] = arrow_volley_ability.cast_in_direction(
		ability_anchor,
		BULLET_SCENE,
		projectiles,
		direction,
		CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier * _arrow_volley_damage_multiplier,
		_get_crit_chance(),
		_crit_multiplier,
		_arrow_volley_bonus_arrows
	)
	if shots.is_empty():
		return false
	for shot in shots:
		var volley_payload: Dictionary = {
			"impact_direction": Vector2(shot.get("direction")),
			"hit_kind": "volley",
			"effects_parent": effects,
		}
		if _explosive_arrow_volley_enabled:
			volley_payload["explosion_radius"] = 72.0
			volley_payload["explosion_damage_ratio"] = 0.6
		shot.set("attack_payload", volley_payload)
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("volley"))
	AudioDirector.play_sfx("bow_volley", -5.5)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	_spawn_glow(player.get_muzzle_global_position(), Color(0.96, 0.8, 0.42, 0.2), 8.0, 20.0, 0.12)
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, arrow_volley_cooldown)
	GameEvents.ability_used.emit(ARROW_VOLLEY_COOLDOWN_KEY)
	return true

func _cast_archer_dash() -> bool:
	var dash_direction: Vector2 = _get_auto_aim_direction(player.global_position)
	if not player.start_dash(dash_direction):
		return false
	AudioDirector.play_sfx("dash_archer", -5.0)
	_consume_dash_charge()
	GameEvents.ability_used.emit(DASH_COOLDOWN_KEY)
	var trail_direction: Vector2 = player.dash_direction if player.dash_direction.length_squared() > 0.0001 else player.aim_direction
	_spawn_trail(player.global_position, player.global_position - trail_direction * 42.0, Color(0.86, 0.92, 1.0, 0.42), 4.0, "dash")
	_spawn_trail(player.global_position, player.global_position - trail_direction * 28.0, Color(0.72, 0.9, 1.0, 0.24), 2.6, "dash")
	_spawn_glow(player.global_position, Color(0.78, 0.9, 1.0, 0.24), 10.0, 26.0, 0.14)
	_spawn_hit_feedback(player.global_position, "flash")
	return true

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

func _fire_arcane_primary() -> bool:
	var shot_scene: PackedScene = SNIPER_SCENE if _sniper_remaining > 0.0 else BULLET_SCENE
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
	player.notify_primary_fired()
	_spawn_trail(
		player.get_muzzle_global_position(),
		player.get_muzzle_global_position() + direction * (48.0 if _sniper_remaining > 0.0 else 20.0),
		Color(1.0, 0.8, 0.4, 0.75) if _sniper_remaining > 0.0 else Color(0.62, 0.96, 1.0, 0.55),
		4.0 if _sniper_remaining > 0.0 else 2.0,
		"arcane"
	)
	cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, 0.62 / _primary_rate_multiplier if _sniper_remaining > 0.0 else ARCANE_PRIMARY_FIRE_COOLDOWN / _primary_rate_multiplier)
	return true

func _cast_arcane_missiles() -> bool:
	if arcane_missiles_ability == null or not arcane_missiles_ability.has_method("cast"):
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
	if spawned <= 0:
		return false
	for child in projectiles.get_children():
		if child is Area2D and child.has_method("get") and child.get("target") != null:
			child.set("attack_payload", {
				"impact_direction": Vector2(child.get("direction")) if child.get("direction") != null else Vector2.ZERO,
				"hit_kind": "missile",
				"suppress_impact_juice": true,
			})
	cooldown_system.set_cooldown(MISSILES_COOLDOWN_KEY, ARCANE_MISSILES_COOLDOWN * _missiles_cooldown_multiplier)
	GameEvents.ability_used.emit(MISSILES_COOLDOWN_KEY)
	AudioDirector.play_sfx("arcane_missiles", -5.0)
	return true

func _cast_arcane_bomb() -> bool:
	if arcane_bomb_ability == null or not arcane_bomb_ability.has_method("cast_in_direction"):
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	var bomb_radius: float = float(arcane_bomb_ability.get("zone_radius")) if arcane_bomb_ability.get("zone_radius") != null else 78.0
	var bomb_range: float = float(arcane_bomb_ability.get("throw_distance")) if arcane_bomb_ability.get("throw_distance") != null else 220.0
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
	cooldown_system.set_cooldown(BOMB_COOLDOWN_KEY, ARCANE_BOMB_COOLDOWN)
	GameEvents.ability_used.emit(BOMB_COOLDOWN_KEY)
	AudioDirector.play_sfx("arcane_missiles", -6.5)
	return true

func _cast_arcane_blink() -> bool:
	if not player.start_dash(_get_auto_aim_direction(player.global_position)):
		return false
	AudioDirector.play_sfx("arcane_blink", -5.0)
	cooldown_system.set_cooldown(BLINK_COOLDOWN_KEY, ARCANE_BLINK_COOLDOWN)
	GameEvents.ability_used.emit(BLINK_COOLDOWN_KEY)
	_spawn_hit_feedback(player.global_position, "flash")
	return true

func _spawn_opening_wave() -> void:
	var opening_scenes: Array[PackedScene] = [
		SKELETON_ENEMY_SCENE,
		SMALL_TREENT_ENEMY_SCENE,
	]
	var offsets: Array[Vector2] = _get_opening_wave_offsets(opening_scenes.size())
	for i in range(min(opening_scenes.size(), offsets.size())):
		_spawn_enemy_telegraphed(opening_scenes[i], offsets[i])

func _spawn_enemy(scene: PackedScene, offset: Vector2) -> void:
	_spawn_enemy_now(scene, player.global_position + offset)

func _spawn_enemy_now(scene: PackedScene, spawn_position: Vector2) -> Node:
	var enemy: Node = spawner.spawn(scene, entities, spawn_position)
	if enemy == null:
		return null
	if enemy.is_in_group("enemies"):
		enemy_count += 1
		_mark_profile_dirty()
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
			enemy.connect("bark_shot", Callable(self, "_on_boss_bark_shot").bind("boss"))
		if enemy.has_signal("encompass_root"):
			enemy.connect("encompass_root", Callable(self, "_on_encompass_root"))
		if enemy.has_signal("territory_started"):
			enemy.connect("territory_started", Callable(self, "_on_territory_started"))
		if enemy.has_signal("territory_ended"):
			enemy.connect("territory_ended", Callable(self, "_on_territory_ended"))
	elif enemy.has_signal("bark_shot"):
		var enemy_kind_label: String = str(enemy.get("enemy_kind")) if _node_has_property(enemy, "enemy_kind") else ""
		enemy.connect("bark_shot", Callable(self, "_on_boss_bark_shot").bind(enemy_kind_label))
	elif enemy.is_in_group("objective_core"):
		_active_cores.append(enemy as Node2D)
	elif enemy.is_in_group("reward_chest"):
		_reward_chest = enemy as Node2D
	elif enemy.is_in_group("boss_root"):
		_boss_roots.append(enemy as Node2D)
	if enemy.has_signal("damage_feedback"):
		enemy.connect("damage_feedback", Callable(self, "_on_enemy_damage_feedback"))
	elif enemy.has_signal("damage_taken"):
		enemy.connect("damage_taken", Callable(self, "_on_damage_taken"))
	return enemy

func _spawn_enemy_telegraphed(scene: PackedScene, offset: Vector2, on_spawned: Callable = Callable()) -> void:
	var spawn_position: Vector2 = player.global_position + offset
	var indicator_position: Vector2 = _get_spawn_indicator_position(spawn_position)
	if SPAWN_INDICATOR_SCENE == null:
		var spawned_enemy: Node = _spawn_enemy_now(scene, spawn_position)
		if on_spawned.is_valid():
			on_spawned.call(spawned_enemy)
		return
	var indicator: Node2D = SPAWN_INDICATOR_SCENE.instantiate() as Node2D
	if indicator == null:
		var fallback_enemy: Node = _spawn_enemy_now(scene, spawn_position)
		if on_spawned.is_valid():
			on_spawned.call(fallback_enemy)
		return
	indicator.global_position = indicator_position
	if _node_has_property(indicator, "delay"):
		indicator.set("delay", spawn_warning_time)
	if _node_has_property(indicator, "radius"):
		indicator.set("radius", 26.0)
	var indicator_id: int = indicator.get_instance_id()
	_pending_spawn_indicator_ids[indicator_id] = true
	pending_spawn_count += 1
	if indicator.has_signal("spawn_requested"):
		indicator.connect("spawn_requested", Callable(self, "_on_spawn_indicator_triggered").bind(spawn_position, scene, indicator_id, on_spawned), CONNECT_ONE_SHOT)
	indicator.tree_exited.connect(Callable(self, "_on_spawn_indicator_exited").bind(indicator_id), CONNECT_ONE_SHOT)
	effects.add_child(indicator)

func _spawn_reward_chest() -> void:
	var chest_position: Vector2 = player.global_position + Vector2(0.0, -96.0)
	if arena != null and arena.has_method("clamp_position"):
		chest_position = arena.clamp_position(chest_position)
	_reward_chest = _spawn_enemy_now(REWARD_CHEST_SCENE, chest_position) as Node2D
	objective_state_label = "Open the reward chest"
	_mark_profile_dirty()

func _handle_spawning() -> void:
	if _objective_phase != "objectives":
		return
	if not spawner.has_method("tick"):
		return
	spawner.tick(get_process_delta_time())
	var active_enemies: int = _get_spawn_pressure_occupancy() + pending_spawn_count
	var should_spawn_now: bool = spawner.should_spawn(active_enemies) or spawner.needs_catch_up_spawn(active_enemies)
	if not should_spawn_now:
		return
	if kills > 0 and kills % 6 == 0:
		wave_number = 1 + int(floor(float(kills) / 6.0))
		GameEvents.wave_started.emit(wave_number)
	var scene: PackedScene = spawner.select_enemy_scene()
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	var offset: Vector2
	if spawner.has_method("is_first_minute_active") and spawner.is_first_minute_active() and spawner.has_method("get_first_minute_spawn_offset"):
		offset = spawner.get_first_minute_spawn_offset(player.global_position)
	elif spawner.has_method("get_spawn_offset_from_viewport") and camera != null:
		offset = spawner.get_spawn_offset_from_viewport(camera, player.global_position)
	else:
		offset = spawner.get_spawn_offset()
	_spawn_enemy_telegraphed(scene, offset)

func _counts_toward_spawn_pressure(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if not node.is_in_group("enemies"):
		return false
	if node.is_in_group("objective_core") or node.is_in_group("reward_chest") or node.is_in_group("boss_root") or node.is_in_group("boss"):
		return false
	return true

func _get_spawn_pressure_occupancy() -> int:
	var occupancy: int = 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if _counts_toward_spawn_pressure(node):
			occupancy += 1
	return occupancy

func _setup_deepwood_objectives() -> void:
	_objective_queue = _roll_deepwood_objective_queue()
	_objective_positions = _roll_objective_positions(_objective_queue.size())
	_completed_objective_count = 0
	_current_objective_index = -1
	_current_objective_type = ""
	_objective_transition_timer = 0.0
	_objective_time_remaining = 0.0
	_objective_notice_time_remaining = 0.0
	_objective_notice_headline = ""
	_objective_notice_progress_line = ""
	_objective_notice_timer_line = ""
	_awaiting_reward_chest = false
	_awaiting_elite_encounter = false
	_pending_elite_reward_chest = false
	_active_elite = null
	_clear_active_shrine_objectives()
	_completed_shrine_count = 0
	_active_shrine_progress_bonus = 16.0
	_destroyed_core_count = 0
	objective_state_label = "Reach %.0f%% pressure to trigger the first objective" % _get_next_objective_threshold()
	objective_progress = 0.0
	_mark_profile_dirty()

func _roll_deepwood_objective_queue() -> Array[String]:
	var queue: Array[String] = [OBJECTIVE_CORES, OBJECTIVE_PENTAGON_SHRINE]
	var objective_pool: Array[String] = [OBJECTIVE_CORES, OBJECTIVE_PENTAGON_SHRINE]
	while queue.size() < max(deepwood_objective_slots, 1):
		queue.append(objective_pool[randi() % objective_pool.size()])
	for _attempt in range(8):
		queue.shuffle()
		if not _has_adjacent_duplicates(queue):
			break
	return queue

func _has_adjacent_duplicates(queue: Array[String]) -> bool:
	for i in range(1, queue.size()):
		if queue[i] == queue[i - 1]:
			return true
	return false

func _roll_objective_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var source_positions: Array[Vector2] = _get_available_objective_positions()
	source_positions.shuffle()
	for i in range(count):
		positions.append(source_positions[i % source_positions.size()])
	return positions

func _get_available_objective_positions() -> Array[Vector2]:
	var source_positions: Array[Vector2] = []
	if arena.has_method("get_objective_positions"):
		source_positions = arena.get_objective_positions()
	if source_positions.is_empty():
		source_positions = [
			Vector2(640, 420),
			Vector2(1360, 420),
			Vector2(1000, 700),
			Vector2(640, 1020),
			Vector2(1360, 1020),
		]
	return source_positions

func _get_shrine_objective_positions() -> Array[Vector2]:
	var count: int = max(shrine_objective_required_count, 1)
	var bounds: Rect2 = arena.get_spawn_bounds() if arena.has_method("get_spawn_bounds") else Rect2(-420.0, -260.0, 2840.0, 1760.0)
	var margin: float = 120.0
	var min_separation: float = max(bounds.size.x, bounds.size.y) * 0.28
	var chosen_positions: Array[Vector2] = []
	var max_attempts: int = 200
	for _i in range(count):
		var best_pos: Vector2 = Vector2.ZERO
		var best_min_dist: float = -1.0
		for _attempt in range(max_attempts):
			var candidate: Vector2 = Vector2(
				randf_range(bounds.position.x + margin, bounds.end.x - margin),
				randf_range(bounds.position.y + margin, bounds.end.y - margin)
			)
			var closest_dist: float = INF
			for existing in chosen_positions:
				closest_dist = minf(closest_dist, candidate.distance_to(existing))
			if chosen_positions.is_empty() or closest_dist > best_min_dist:
				best_min_dist = closest_dist
				best_pos = candidate
			if chosen_positions.is_empty() or closest_dist >= min_separation:
				break
		chosen_positions.append(best_pos)
	return chosen_positions

func _start_next_objective() -> void:
	if _current_objective_type != "":
		return
	_clear_active_shrine_objectives()
	_clear_active_core_entities()
	if _reward_chest != null and is_instance_valid(_reward_chest):
		_reward_chest.queue_free()
		_reward_chest = null
	_awaiting_reward_chest = false
	_clear_active_objective_timer()
	if _completed_objective_count >= _objective_queue.size():
		_current_objective_index = -1
		_current_objective_type = ""
		objective_state_label = "Deepwood objectives complete"
		return
	_current_objective_index = _completed_objective_count
	_current_objective_type = _objective_queue[_current_objective_index]
	_mark_profile_dirty()
	match _current_objective_type:
		OBJECTIVE_CORES:
			_begin_core_objective()
		OBJECTIVE_PENTAGON_SHRINE:
			_begin_pentagon_shrine_objective()
		_:
			_begin_core_objective()

func _update_objective_flow() -> void:
	if _objective_phase == "objectives":
		if _objective_notice_time_remaining > 0.0:
			_objective_notice_time_remaining = max(_objective_notice_time_remaining - get_process_delta_time(), 0.0)
		if _awaiting_elite_encounter:
			return
		if _active_elite != null and is_instance_valid(_active_elite):
			return
		if _pending_elite_reward_chest:
			return
		if _awaiting_reward_chest:
			if (_reward_chest == null or not is_instance_valid(_reward_chest)) and _upgrade_choices.is_empty() and _upgrade_overlay_mode.is_empty():
				_awaiting_reward_chest = false
				_objective_transition_timer = objective_transition_delay
			return
		if _current_objective_type == OBJECTIVE_CORES:
			_tick_active_objective_timer()
			if _current_objective_type != OBJECTIVE_CORES:
				return
			var living_cores: Array[Node2D] = []
			for core in _active_cores:
				if is_instance_valid(core):
					living_cores.append(core)
			_active_cores = living_cores
			_refresh_core_objective_progress()
			if _destroyed_core_count >= core_objective_required_count:
				_complete_active_objective()
			return
		elif _current_objective_type == OBJECTIVE_PENTAGON_SHRINE:
			_tick_active_objective_timer()
			if _current_objective_type != OBJECTIVE_PENTAGON_SHRINE:
				return
			_sync_active_shrine_objectives()
			if _completed_shrine_count >= max(shrine_objective_required_count, 1):
				_complete_active_objective_with_rewards(_active_shrine_progress_bonus, objective_completion_xp_reward)
			return
		if _objective_transition_timer > 0.0:
			_objective_transition_timer = max(_objective_transition_timer - get_process_delta_time(), 0.0)
			if _objective_transition_timer <= 0.0 and _is_next_objective_unlocked():
				_start_next_objective()
			return
		if _is_next_objective_unlocked():
			_start_next_objective()
			return
		if _completed_objective_count >= _objective_queue.size() and _major_progress >= major_progress_max:
			_spawn_boss_portal()
	elif _objective_phase == "portal":
		if _boss_portal == null or not is_instance_valid(_boss_portal):
			_enter_boss_arena()
	elif _objective_phase == "boss":
		if _boss == null or not is_instance_valid(_boss):
			_objective_phase = "cleared"
			_game_over = true
			objective_state_label = "Forest cleared"
			boss_status_label = ""
			game_over_prompt = "Treent Overlord defeated. Click or press R to return to Esseloria."

func _start_active_objective_timer(objective_type: String = "") -> void:
	var resolved_type: String = objective_type if not objective_type.is_empty() else _current_objective_type
	_objective_time_remaining = _get_objective_time_limit(resolved_type)

func _clear_active_objective_timer() -> void:
	_objective_time_remaining = 0.0

func _tick_active_objective_timer() -> void:
	if _current_objective_type.is_empty():
		return
	_objective_time_remaining = max(_objective_time_remaining - get_process_delta_time(), 0.0)
	if _objective_time_remaining <= 0.0:
		_fail_active_objective_due_to_timeout()

func _fail_active_objective_due_to_timeout() -> void:
	if _current_objective_type.is_empty():
		return
	_show_objective_notice("Objective Failed", "Time expired", "")
	match _current_objective_type:
		OBJECTIVE_CORES:
			_clear_active_core_entities()
			_complete_active_objective_with_rewards(0.0, 0)
		OBJECTIVE_PENTAGON_SHRINE:
			_clear_active_shrine_objectives()
			_complete_active_objective_with_rewards(0.0, 0)
		_:
			_complete_active_objective_with_rewards(0.0, 0)

func _refresh_core_objective_progress() -> void:
	objective_progress = clampf(float(_destroyed_core_count) / max(float(core_objective_required_count), 1.0), 0.0, 1.0)
	objective_state_label = "Destroy the forest cores (%d/%d)" % [_destroyed_core_count, core_objective_required_count]

func _clear_active_core_entities() -> void:
	for core in _active_cores:
		if core != null and is_instance_valid(core):
			core.queue_free()
	_active_cores.clear()
	_core_count_total = 0
	_destroyed_core_count = 0

func _clear_active_shrine_objectives() -> void:
	for shrine in _active_shrine_objectives:
		if shrine != null and is_instance_valid(shrine):
			shrine.queue_free()
	_active_shrine_objectives.clear()
	_completed_shrine_count = 0

func _sync_active_shrine_objectives() -> void:
	var living_shrines: Array[Node2D] = []
	var progress_sum: float = 0.0
	var completed_count: int = 0
	for shrine in _active_shrine_objectives:
		if shrine == null or not is_instance_valid(shrine):
			continue
		living_shrines.append(shrine)
		var shrine_progress: float = 0.0
		if shrine.has_method("get_progress"):
			shrine_progress = float(shrine.call("get_progress"))
		elif shrine.has_method("is_completed") and bool(shrine.call("is_completed")):
			shrine_progress = 1.0
		progress_sum += clampf(shrine_progress, 0.0, 1.0)
		if shrine.has_method("is_completed") and bool(shrine.call("is_completed")):
			completed_count += 1
	_active_shrine_objectives = living_shrines
	_completed_shrine_count = completed_count
	objective_progress = progress_sum / float(max(shrine_objective_required_count, 1))

func _get_shrine_status_text() -> String:
	if _completed_shrine_count >= max(shrine_objective_required_count, 1):
		return "all shrine networks complete"
	if _completed_shrine_count > 0:
		return "%d / %d shrines complete" % [_completed_shrine_count, shrine_objective_required_count]
	return "secure all %d shrine networks" % shrine_objective_required_count

func _show_objective_notice(headline: String, progress_line: String, timer_line: String, duration: float = 1.2) -> void:
	_objective_notice_headline = headline
	_objective_notice_progress_line = progress_line
	_objective_notice_timer_line = timer_line
	_objective_notice_time_remaining = duration

func _get_objective_time_limit(objective_type: String) -> float:
	match objective_type:
		OBJECTIVE_CORES:
			return max(core_objective_time_limit, 1.0)
		OBJECTIVE_PENTAGON_SHRINE:
			return max(shrine_objective_time_limit, 1.0)
		_:
			return max(objective_time_limit, 1.0)

func _format_mm_ss(total_seconds: float) -> String:
	var total: int = int(ceil(max(total_seconds, 0.0)))
	var minutes: int = total / 60
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]

func _begin_core_objective() -> void:
	objective_state_label = "Destroy the forest cores"
	_destroyed_core_count = 0
	if arena.has_method("get_core_positions"):
		var core_positions: Array[Vector2] = arena.get_core_positions(core_objective_available_count)
		_core_count_total = core_positions.size()
		for point in core_positions:
			_spawn_enemy_now(OBJECTIVE_CORE_SCENE, point)
	_refresh_core_objective_progress()
	_start_active_objective_timer()
	_show_objective_notice(
		"Destroy the Forest Cores",
		"Cores destroyed: %d / %d" % [_destroyed_core_count, core_objective_required_count],
		"Time left: %s" % _format_mm_ss(_objective_time_remaining),
		1.5
	)

func _begin_pentagon_shrine_objective() -> void:
	_clear_active_shrine_objectives()
	_completed_shrine_count = 0
	_active_shrine_progress_bonus = 16.0
	var shrine_positions: Array[Vector2] = _get_shrine_objective_positions()
	for center in shrine_positions:
		var shrine: Node2D = PENTAGON_SHRINE_OBJECTIVE_SCENE.instantiate() as Node2D
		if shrine == null:
			continue
		_active_shrine_objectives.append(shrine)
		if shrine.has_method("set_player"):
			shrine.set_player(player)
		if _node_has_property(shrine, "persist_after_completion"):
			shrine.set("persist_after_completion", true)
		if _node_has_property(shrine, "player_time_limit"):
			shrine.set("player_time_limit", 0.0)
		if _node_has_property(shrine, "boss_progress_bonus"):
			_active_shrine_progress_bonus = float(shrine.get("boss_progress_bonus"))
		if shrine.has_signal("objective_started"):
			shrine.connect("objective_started", Callable(self, "_on_deepwood_objective_started").bind(shrine))
		if shrine.has_signal("objective_progressed"):
			shrine.connect("objective_progressed", Callable(self, "_on_deepwood_objective_progressed").bind(shrine))
		if shrine.has_signal("objective_completed"):
			shrine.connect("objective_completed", Callable(self, "_on_deepwood_objective_completed").bind(shrine))
		if shrine.has_signal("objective_failed"):
			shrine.connect("objective_failed", Callable(self, "_on_deepwood_objective_failed").bind(shrine))
		entities.add_child(shrine)
		if shrine.has_method("start_objective"):
			shrine.start_objective(center)
	if _active_shrine_objectives.is_empty():
		return
	_sync_active_shrine_objectives()
	_start_active_objective_timer()
	_show_objective_notice(
		"Shrine Network",
		"Shrines completed: %d / %d" % [_completed_shrine_count, shrine_objective_required_count],
		"Time left: %s" % _format_mm_ss(_objective_time_remaining),
		1.5
	)

func _complete_active_objective() -> void:
	var progress_bonus: float = objective_completion_progress_bonus
	if _current_objective_type == OBJECTIVE_PENTAGON_SHRINE:
		progress_bonus = _active_shrine_progress_bonus
	_complete_active_objective_with_rewards(progress_bonus, objective_completion_xp_reward)

func _complete_active_objective_with_rewards(progress_bonus: float, xp_reward: int) -> void:
	if _current_objective_type.is_empty():
		return
	var completed_objective_type: String = _current_objective_type
	_clear_active_objective_timer()
	_clear_active_core_entities()
	if completed_objective_type == OBJECTIVE_PENTAGON_SHRINE:
		_clear_active_shrine_objectives()
	_add_major_progress(progress_bonus)
	if xp_reward > 0:
		_xp_system.add_xp(xp_reward)
	_completed_objective_count += 1
	_current_objective_type = ""
	_current_objective_index = -1
	_mark_profile_dirty()
	var objective_succeeded: bool = progress_bonus > 0.0 or xp_reward > 0
	if completed_objective_type == OBJECTIVE_CORES and objective_succeeded:
		_upgrade_rerolls_remaining += 1
	if objective_succeeded and _should_start_elite_encounter():
		_start_elite_encounter()
		return
	if completed_objective_type == OBJECTIVE_CORES and objective_succeeded:
		_spawn_reward_chest()
		_awaiting_reward_chest = true
		return
	_objective_transition_timer = objective_transition_delay

func _spawn_boss_portal() -> void:
	if _objective_phase != "objectives":
		return
	_objective_phase = "portal"
	objective_state_label = "Enter the boss portal"
	_mark_profile_dirty()
	if _boss_portal != null and is_instance_valid(_boss_portal):
		return
	_boss_portal = BOSS_PORTAL_SCENE.instantiate() as Area2D
	if _boss_portal == null:
		return
	if arena.has_method("get_portal_spawn_position"):
		_boss_portal.global_position = arena.get_portal_spawn_position()
	else:
		_boss_portal.global_position = Vector2(960, 420)
	_boss_portal.connect("portal_entered", Callable(self, "_enter_boss_arena"))
	entities.add_child(_boss_portal)

func _should_start_elite_encounter() -> bool:
	return _completed_objective_count > 0 and _completed_objective_count < _objective_queue.size()

func _start_elite_encounter() -> void:
	_awaiting_elite_encounter = true
	_pending_elite_reward_chest = false
	_active_elite = null
	_clear_pending_spawn_indicators()
	_clear_non_elite_enemies()
	objective_state_label = "Elite Encounter - defeat the Deepwood Stalker"
	_mark_profile_dirty()
	_show_objective_notice("Elite Encounter", "Defeat the Deepwood Stalker", "", 1.5)
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	var offset: Vector2
	if spawner.has_method("get_spawn_offset_from_viewport") and camera != null:
		offset = spawner.get_spawn_offset_from_viewport(camera, player.global_position)
	else:
		offset = spawner.get_spawn_offset()
	_spawn_enemy_telegraphed(DEEPWOOD_STALKER_ENEMY_SCENE, offset, Callable(self, "_on_elite_spawned"))

func _on_elite_spawned(enemy: Node) -> void:
	_awaiting_elite_encounter = false
	if enemy is Node2D and is_instance_valid(enemy):
		_active_elite = enemy as Node2D
		objective_state_label = "Elite Encounter - defeat the Deepwood Stalker"
		_mark_profile_dirty()

func _clear_non_elite_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == null or not is_instance_valid(node):
			continue
		if node.is_in_group("objective_core") or node.is_in_group("reward_chest") or node.is_in_group("boss_root") or node.is_in_group("elite"):
			continue
		enemy_count = max(enemy_count - 1, 0)
		node.queue_free()

func _clear_pending_spawn_indicators() -> void:
	for child in effects.get_children():
		if child != null and is_instance_valid(child) and child.has_signal("spawn_requested"):
			child.queue_free()

func _on_deepwood_objective_started(objective_id: StringName, _shrine: Node2D = null) -> void:
	if String(objective_id) == OBJECTIVE_PENTAGON_SHRINE:
		_sync_active_shrine_objectives()
		objective_state_label = "Shrine Network - %s" % _get_shrine_status_text()

func _on_deepwood_objective_progressed(objective_id: StringName, _value: float, _detail: String, _shrine: Node2D = null) -> void:
	if String(objective_id) != OBJECTIVE_PENTAGON_SHRINE:
		return
	_sync_active_shrine_objectives()
	objective_state_label = "Shrine Network - %s" % _get_shrine_status_text()
	_mark_profile_dirty()

func _on_deepwood_objective_completed(objective_id: StringName, boss_progress_bonus: float, _shrine: Node2D = null) -> void:
	if String(objective_id) != OBJECTIVE_PENTAGON_SHRINE:
		return
	_active_shrine_progress_bonus = boss_progress_bonus
	_sync_active_shrine_objectives()
	objective_state_label = "Shrine Network - %s" % _get_shrine_status_text()
	if _completed_shrine_count >= max(shrine_objective_required_count, 1):
		_complete_active_objective_with_rewards(
			_active_shrine_progress_bonus,
			objective_completion_xp_reward
		)

func _on_deepwood_objective_failed(objective_id: StringName, _shrine: Node2D = null) -> void:
	if String(objective_id) != OBJECTIVE_PENTAGON_SHRINE:
		return
	_clear_active_shrine_objectives()
	## Advance run with no boss/XP reward (time expired).
	_show_objective_notice("Objective Failed", "Time expired", "")
	_complete_active_objective_with_rewards(0.0, 0)

func _enter_boss_arena() -> void:
	if _in_boss_arena:
		return
	_in_boss_arena = true
	_objective_phase = "boss"
	objective_state_label = "Treent Overlord awakened"
	if _boss_portal != null and is_instance_valid(_boss_portal):
		_boss_portal.queue_free()
	_clear_scene_for_boss_transition()
	enemy_count = 0
	arena.visible = false
	if boss_arena:
		boss_arena.visible = true
		player.global_position = boss_arena.get_player_spawn_position()
	_apply_active_arena_limits(boss_arena)
	GameEvents.wave_started.emit(99)
	_spawn_boss()

func _enter_boss_test() -> void:
	_major_progress = major_progress_max
	_objective_queue.clear()
	_objective_positions.clear()
	_current_objective_type = ""
	_current_objective_index = -1
	_completed_objective_count = 0
	_objective_transition_timer = 0.0
	_enter_boss_arena()

func _spawn_boss() -> void:
	if _objective_phase != "boss":
		return
	if boss_arena.has_method("get_boss_spawn_position"):
		_spawn_enemy_now(TREENT_BOSS_SCENE, boss_arena.get_boss_spawn_position())

func _find_nearest_enemy(origin: Vector2) -> Node2D:
	if float(player.get("rooted_remaining")) > 0.0:
		var root_target: Node2D = _find_nearest_node_in_group(origin, &"boss_root")
		if root_target != null:
			return root_target
	var best: Node2D
	var best_d2: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if _in_boss_arena and not node.is_in_group("boss"):
			continue
		var d2: float = origin.distance_squared_to(node.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = node
	return best

func _is_combat_enemy(enemy: Node) -> bool:
	return enemy.is_in_group("enemies") and not enemy.is_in_group("objective_core") and not enemy.is_in_group("reward_chest") and not enemy.is_in_group("boss_root")

func _find_nearest_node_in_group(origin: Vector2, group_name: StringName) -> Node2D:
	var best: Node2D
	var best_d2: float = INF
	for node in get_tree().get_nodes_in_group(group_name):
		if not (node is Node2D):
			continue
		var target: Node2D = node as Node2D
		var d2: float = origin.distance_squared_to(target.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = target
	return best

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			var node: Node2D = enemy as Node2D
			if _in_boss_arena and not node.is_in_group("boss"):
				continue
			list.append(node)
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
	return

func _handle_boss_hazards(delta: float) -> void:
	if not _in_boss_arena or boss_arena == null or not boss_arena.has_method("get_random_arena_position"):
		return
	var boss_phase: int = 1
	if _boss != null and is_instance_valid(_boss):
		boss_phase = int(_boss.get("phase"))
	var interval: float = _trunk_interval_phase2 if boss_phase >= 2 else _trunk_interval_phase1
	var damage: float = _trunk_damage_phase2 if boss_phase >= 2 else _trunk_damage_phase1
	_trunk_spawn_timer += delta
	if _trunk_spawn_timer >= interval:
		_trunk_spawn_timer = 0.0
		var pos: Vector2 = boss_arena.get_random_arena_position()
		var trunk: Node2D = FALLING_TRUNK_SCENE.instantiate() as Node2D
		if trunk != null and trunk.has_method("setup"):
			trunk.set("damage", damage)
			trunk.setup(pos)
			effects.add_child(trunk)
	if boss_phase >= 2:
		var bark_cooldown: float = _bark_volley_cooldown * _bark_volley_phase2_mult
		_bark_volley_timer += delta
		if _bark_volley_timer >= bark_cooldown:
			_bark_volley_timer = 0.0
			var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * (randf() * _bark_volley_placement_radius)
			var aoe_pos: Vector2 = player.global_position + offset
			var aoe: Node2D = BARK_VOLLEY_AOE_SCENE.instantiate() as Node2D
			if aoe != null and aoe.has_method("setup"):
				aoe.setup(aoe_pos)
				effects.add_child(aoe)
	for child in effects.get_children():
		if child.has_method("get_damage_if_player_hit"):
			var dmg: float = child.get_damage_if_player_hit(player.global_position)
			if dmg > 0.0:
				player.take_damage(dmg)
				if _game_over:
					return

func _update_deepwood_hazard_runtime() -> void:
	if _hazard_director == null or not is_instance_valid(_hazard_director):
		return
	if _hazard_director.has_method("set_progress_ratio"):
		_hazard_director.set_progress_ratio(clampf(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0))
	if _hazard_director.has_method("set_run_active"):
		var hazards_active: bool = _objective_phase == "objectives" and not _awaiting_reward_chest and not _is_elite_interstitial_active() and not _in_boss_arena and not _game_over
		_hazard_director.set_run_active(hazards_active)

func _spawn_hit_feedback(at: Vector2, kind: String = "arrow") -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		match kind:
			"arrow":
				fx.configure(Color(1.0, 0.9, 0.56, 0.52), "arrow", 2.0, 11.0, 0.07)
			"heavy":
				fx.configure(Color(1.0, 0.94, 0.74, 0.98), "heavy", 7.0, 26.0, 0.16)
			"power":
				fx.configure(Color(1.0, 0.78, 0.3, 0.92), "power", 5.0, 20.0, 0.14)
			"sentinel":
				fx.configure(Color(1.0, 0.9, 0.46, 0.9), "sentinel", 5.0, 18.0, 0.13)
			"sniper":
				fx.configure(Color(0.88, 0.96, 1.0, 0.96), "heavy", 8.0, 28.0, 0.16)
			"volley":
				fx.configure(Color(0.98, 0.86, 0.52, 0.72), "volley", 3.0, 13.0, 0.08)
			_:
				fx.configure(Color(1.0, 0.84, 0.4, 0.88), "arrow", 3.0, 15.0, 0.1)
	effects.add_child(fx)
	if kind == "arrow":
		_spawn_glow(at, Color(1.0, 0.9, 0.56, 0.08), 4.0, 10.0, 0.06)
	elif kind == "heavy" or kind == "sniper":
		_spawn_glow(at, Color(1.0, 0.94, 0.72, 0.22), 8.0, 22.0, 0.12, "heat")
	elif kind == "power":
		_spawn_glow(at, Color(1.0, 0.8, 0.34, 0.24), 8.0, 20.0, 0.12, "heat")
	elif kind == "sentinel":
		_spawn_glow(at, Color(1.0, 0.88, 0.44, 0.18), 6.0, 16.0, 0.1)

func _spawn_arrow_shot_flash(at: Vector2) -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.9, 0.56, 0.82), "flash", 3.0, 10.0, 0.08)
	effects.add_child(fx)

func _spawn_bow_release_effect(at: Vector2, direction: Vector2) -> void:
	var fx: Node2D = BOW_RELEASE_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at - direction.normalized() * 8.0 if direction.length_squared() > 0.0001 else at
	if fx.has_method("configure"):
		fx.configure(direction, Color(1.0, 0.92, 0.66, 0.92))
	effects.add_child(fx)

func _spawn_glow(at: Vector2, tint: Color, start_radius: float, end_radius: float, duration: float, shader_style: String = "pulse") -> void:
	var glow: Node2D = GLOW_EFFECT_SCENE.instantiate() as Node2D
	if glow == null:
		return
	glow.global_position = at
	if glow.has_method("configure"):
		glow.configure(tint, start_radius, end_radius, duration, shader_style)
	effects.add_child(glow)

func _spawn_death_feedback(at: Vector2) -> void:
	var fx: Node2D = DEATH_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.86, 0.54, 0.92), 6.0, 26.0, 0.24)
	effects.add_child(fx)

func _spawn_trail(from: Vector2, to: Vector2, tint: Color, width: float, style: String = "trail") -> void:
	var fx: Node2D = TRAIL_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	if fx.has_method("setup"):
		fx.setup(Vector2.ZERO, to - from, tint, width, style)
	fx.global_position = from
	effects.add_child(fx)

func _on_sentinel_strike(at: Vector2, is_crit: bool) -> void:
	_spawn_hit_feedback(at, "sentinel")
	_spawn_glow(at, Color(1.0, 0.9, 0.46, 0.18), 8.0, 20.0, 0.12)
	if is_crit:
		_spawn_glow(at, Color(1.0, 0.92, 0.52, 0.38), 12.0, 34.0, 0.2)

func _on_enemy_killed(enemy: Node) -> void:
	var counts_as_kill: bool = bool(enemy.get("counts_as_kill")) if _node_has_property(enemy, "counts_as_kill") else true
	if enemy.is_in_group("enemies"):
		enemy_count = max(enemy_count - 1, 0)
	if counts_as_kill:
		kills += 1
	if enemy is Node2D:
		_spawn_death_feedback((enemy as Node2D).global_position)
	var is_elite: bool = enemy.is_in_group("elite")
	var reward: int = int(enemy.get("xp_reward"))
	if not is_elite and reward > 0 and enemy is Node2D and xp_orb_field != null and xp_orb_field.has_method("spawn_orb_at"):
		xp_orb_field.spawn_orb_at((enemy as Node2D).global_position, reward)
	elif not is_elite and reward > 0:
		_xp_system.add_xp(reward)
	var rarity_reward: int = int(enemy.get("rarity_charge_reward")) if _node_has_property(enemy, "rarity_charge_reward") else 0
	if rarity_reward > 0:
		_rarity_charge.add_charge(run_time, rarity_reward)
	if sentinel_ability and counts_as_kill:
		sentinel_ability.add_charge(float(sentinel_ability.get("charge_per_kill")))
	if _deadeye_bloom_enabled and counts_as_kill and enemy is Node2D and bool(enemy.get("last_hit_was_crit")):
		call_deferred("_spawn_deadeye_bloom", (enemy as Node2D).global_position)
	if enemy.is_in_group("objective_core"):
		var remaining_cores: Array[Node2D] = []
		for core in _active_cores:
			if is_instance_valid(core) and core != enemy:
				remaining_cores.append(core)
		_active_cores = remaining_cores
		_destroyed_core_count += 1
		_refresh_core_objective_progress()
	elif enemy.is_in_group("boss_root"):
		var living_roots: Array[Node2D] = []
		for root in _boss_roots:
			if is_instance_valid(root) and root != enemy:
				living_roots.append(root)
		_boss_roots = living_roots
		if _boss_roots.is_empty():
			player.clear_root()
	elif enemy.is_in_group("reward_chest"):
		_reward_chest = null
		_open_upgrade_overlay("reward", {
			"title": "Rare Chest",
			"min_rarity": "rare",
			"count": 3,
		})
	elif enemy.is_in_group("elite"):
		if enemy == _active_elite:
			_active_elite = null
			_awaiting_elite_encounter = false
			_pending_elite_reward_chest = true
			var elite_progress_reward: float = float(enemy.get("boss_progress_reward")) if _node_has_property(enemy, "boss_progress_reward") else 8.0
			_add_major_progress(elite_progress_reward)
			_spawn_reward_chest()
			_awaiting_reward_chest = true
	elif enemy.is_in_group("boss"):
		_boss = null
		_objective_phase = "cleared"
		_game_over = true
		objective_state_label = "Forest cleared"
		boss_status_label = ""
		game_over_prompt = "Treent Overlord defeated. Click or press R to return to Esseloria."
	elif counts_as_kill:
		_add_major_progress(major_progress_per_kill)
	_mark_profile_dirty()
	if _xp_system.has_pending_level_up() and _upgrade_choices.is_empty() and _upgrade_overlay_mode.is_empty():
		_open_upgrade_overlay()

func _on_player_died() -> void:
	_clear_combat_juice()
	get_tree().paused = false
	_game_over = true
	game_over_prompt = "You fell. Click or press R to return to Esseloria."

func _handle_upgrade_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		_selected_upgrade_index = posmod(_selected_upgrade_index - 1, _upgrade_choices.size())
		_sync_upgrade_display()
		_update_status_cache()
	elif Input.is_action_just_pressed("move_right"):
		_selected_upgrade_index = posmod(_selected_upgrade_index + 1, _upgrade_choices.size())
		_sync_upgrade_display()
		_update_status_cache()
	elif Input.is_action_just_pressed("dash"):
		_reroll_upgrade_choices()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
		_commit_selected_upgrade()

func request_upgrade_selection(index: int) -> void:
	if _upgrade_choices.is_empty():
		return
	if index < 0 or index >= _upgrade_choices.size():
		return
	_selected_upgrade_index = index
	_sync_upgrade_display()
	_commit_selected_upgrade()

func request_upgrade_hover(index: int) -> void:
	if _upgrade_choices.is_empty():
		return
	if index < 0 or index >= _upgrade_choices.size():
		return
	_selected_upgrade_index = index
	_sync_upgrade_display()
	_update_status_cache()

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
	_mark_profile_dirty()
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
		if player != null and player.has_method("heal"):
			player.heal(heal_amount)
			AudioDirector.play_ui("ui_confirm", -2.0) if AudioDirector != null else null

func request_resume_game() -> void:
	if _upgrade_choices.is_empty():
		_clear_combat_juice()
		_manual_pause = false
		_profile_overlay_open = false
		_inventory_overlay_open = false
		get_tree().paused = false
		_mark_profile_dirty()
		_update_status_cache()

func request_open_profile() -> void:
	if _upgrade_choices.is_empty() and not _game_over:
		_clear_combat_juice()
		_manual_pause = true
		_profile_overlay_open = true
		_inventory_overlay_open = false
		get_tree().paused = true
		_mark_profile_dirty()
		_update_status_cache()

func request_close_profile() -> void:
	if _profile_overlay_open:
		_clear_combat_juice()
		_profile_overlay_open = false
		_manual_pause = true
		_inventory_overlay_open = false
		get_tree().paused = true
		_mark_profile_dirty()
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

func is_manual_pause_active() -> bool:
	return _manual_pause

func has_upgrade_overlay_active() -> bool:
	return not _upgrade_choices.is_empty()

func _apply_upgrade(upgrade_id: String, consume_level_up: bool = true) -> void:
	if upgrade_id.is_empty():
		return
	if _selected_weapon_id == RunConfig.CLASS_ARCHER and UpgradeCatalog.is_archer_attunement(upgrade_id):
		_switch_archer_attunement(upgrade_id)
	else:
		_upgrade_counts[upgrade_id] = int(_upgrade_counts.get(upgrade_id, 0)) + 1
	_record_upgrade_history(upgrade_id)
	_rebuild_upgrade_state_from_counts()
	if consume_level_up and _xp_system.has_pending_level_up():
		_xp_system.consume_level_up()

func _apply_meta_progression_modifiers() -> void:
	if RunConfig.boss_test_requested:
		return
	var modifiers: Dictionary = MetaProgression.get_run_modifiers() if MetaProgression else {}
	_primary_damage_multiplier *= float(modifiers.get("damage_multiplier", 1.0))
	_move_speed_multiplier *= float(modifiers.get("move_speed_multiplier", 1.0))
	var health_bonus: float = float(modifiers.get("health_bonus", 0.0))
	player.max_health = CombatBalance.PLAYER_MAX_HEALTH + health_bonus
	player.health = player.max_health

func _switch_archer_attunement(upgrade_id: String) -> void:
	var next_element: String = UpgradeCatalog.get_archer_element_for_upgrade(upgrade_id)
	var current_element: String = UpgradeCatalog.get_archer_active_element(_upgrade_counts)
	if next_element.is_empty():
		return
	if not current_element.is_empty() and current_element != next_element:
		for remove_id in UpgradeCatalog.get_archer_upgrade_group_for_element(current_element):
			_upgrade_counts.erase(remove_id)
		_remove_upgrade_history_ids(UpgradeCatalog.get_archer_upgrade_group_for_element(current_element))
	_upgrade_counts[upgrade_id] = 1

func _record_upgrade_history(upgrade_id: String) -> void:
	var entry: Dictionary = UpgradeCatalog.get_upgrade_definition(upgrade_id, _selected_weapon_id)
	if entry.is_empty():
		entry = {"id": upgrade_id, "name": upgrade_id, "rarity": "common", "description": ""}
	_upgrade_history.append(entry)
	_mark_profile_dirty()

func _remove_upgrade_history_ids(ids: Array[String]) -> void:
	if ids.is_empty():
		return
	var kept: Array[Dictionary] = []
	for entry in _upgrade_history:
		if not ids.has(str(entry.get("id", ""))):
			kept.append(entry)
	_upgrade_history = kept
	_mark_profile_dirty()

func _reset_upgrade_modifiers() -> void:
	_primary_damage_multiplier = 1.0
	_primary_rate_multiplier = 1.0
	_move_speed_multiplier = 1.0
	_missiles_count_bonus = 0
	_missiles_cooldown_multiplier = 1.0
	_sniper_damage_multiplier = 1.0
	_sniper_pierce_bonus = 0
	_sniper_remaining = 0.0
	_primary_pierce_bonus = 0
	_arrow_volley_damage_multiplier = 1.0
	_arrow_volley_bonus_arrows = 0
	_dash_cooldown_multiplier = 1.0
	_dash_charge_max = 1
	_sentinel_duration_bonus = 0.0
	_sentinel_damage_bonus = 0.0
	_sentinel_attack_rate_multiplier = 1.0
	_crit_chance = 0.05
	_crit_multiplier = 1.5
	_split_shot_enabled = false
	_arrow_storm_enabled = false
	_ricochet_bounces = 0
	_explosive_arrow_volley_enabled = false
	_deadeye_bloom_enabled = false
	active_primary_element = ""
	_burn_damage_multiplier = 1.0
	_ice_chill_duration_bonus = 0.0
	_ice_slow_mul = 1.0
	_freeze_spread_enabled = false
	_ice_blast_enabled = false
	_ice_blast_radius_bonus = 0.0
	_lightning_chain_bonus_jumps = 0

func _rebuild_upgrade_state_from_counts() -> void:
	var previous_dash_max: int = _dash_charge_max
	var previous_dash_count: int = _dash_charge_count
	_reset_upgrade_modifiers()
	var ids: Array[String] = []
	for upgrade_id in _upgrade_counts.keys():
		ids.append(str(upgrade_id))
	ids.sort()
	for upgrade_id in ids:
		for _count in range(int(_upgrade_counts.get(upgrade_id, 0))):
			_apply_upgrade_effect_only(upgrade_id)
	if previous_dash_max <= 0:
		_dash_charge_count = _dash_charge_max
	elif _dash_charge_max > previous_dash_max:
		_dash_charge_count = min(previous_dash_count + (_dash_charge_max - previous_dash_max), _dash_charge_max)
	else:
		_dash_charge_count = min(previous_dash_count, _dash_charge_max)
	if _dash_charge_count >= _dash_charge_max:
		_dash_recharge_timer = 0.0
	elif _dash_recharge_timer <= 0.0:
		_dash_recharge_timer = dash_cooldown * _dash_cooldown_multiplier
	player.move_speed = _get_base_move_speed() * _move_speed_multiplier
	if _weapon_is_arcane():
		if arcane_sniper_ability != null:
			arcane_sniper_ability.set("duration", ARCANE_SNIPER_DURATION)
			arcane_sniper_ability.set("cooldown", ARCANE_SNIPER_COOLDOWN)
	else:
		_sniper_remaining = 0.0
	if sentinel_ability and not _weapon_is_arcane():
		sentinel_ability.set("duration", 8.0 + _sentinel_duration_bonus)

func _apply_upgrade_effect_only(upgrade_id: String) -> void:
	match upgrade_id:
		"charged_rounds":
			_primary_damage_multiplier *= 1.2
		"quickdraw":
			_primary_rate_multiplier *= 1.15
		"spellclock":
			_missiles_cooldown_multiplier *= 0.82
		"phase_stride":
			_move_speed_multiplier *= 1.12
		"satellite_volley":
			_missiles_count_bonus += 1
		"deadeye":
			_sniper_damage_multiplier *= 1.25
			_sniper_pierce_bonus += 1
		"arch_c_sharpened_tips":
			_primary_damage_multiplier *= 1.10
		"arch_c_quick_nock":
			_primary_rate_multiplier *= 1.10
		"arch_c_fleetfoot":
			_move_speed_multiplier *= 1.08
		"arch_c_piercing_practice":
			_primary_pierce_bonus += 2
		"arch_c_hollow_points":
			_crit_multiplier *= 1.15
		"arch_c_hunters_instinct":
			_crit_chance += 0.05
		"arch_c_stamina_training":
			_dash_cooldown_multiplier *= 0.90
		"arch_c_xp_magnet":
			_xp_pickup_radius_multiplier *= 1.15
		"arch_c_ricochet_arrow":
			_ricochet_bounces += 1
		"arch_c_fire_attunement":
			active_primary_element = "fire"
		"arch_c_ice_attunement":
			active_primary_element = "ice"
		"arch_c_lightning_attunement":
			active_primary_element = "lightning"
		"arch_r_split_shot":
			_split_shot_enabled = true
		"arch_r_thorned_volley":
			_arrow_volley_damage_multiplier *= 1.35
		"arch_r_expanded_volley":
			_arrow_volley_bonus_arrows = maxi(_arrow_volley_bonus_arrows, 2)
		"arch_r_predatory_focus":
			_sentinel_damage_bonus += 0.20
		"arch_r_long_breath":
			_sentinel_duration_bonus += 3.0
		"arch_r_two_dashes":
			_dash_charge_max = 2
		"arch_r_fire_intensity":
			_burn_damage_multiplier *= 1.25
		"arch_r_ice_depth":
			_ice_chill_duration_bonus += 1.0
			_ice_slow_mul *= 1.10
		"arch_r_freeze_spread":
			_freeze_spread_enabled = true
		"arch_r_ice_blast":
			_ice_blast_enabled = true
			_ice_blast_radius_bonus += 25.0
		"arch_r_lightning_reach":
			_lightning_chain_bonus_jumps += 2
		"arch_e_arrow_storm":
			_arrow_storm_enabled = true
		"arch_e_explosive_arrow_volley":
			_explosive_arrow_volley_enabled = true
		"arch_e_storm_volley":
			_arrow_volley_bonus_arrows = maxi(_arrow_volley_bonus_arrows, 4)
		"arch_e_perfect_predator":
			_sentinel_damage_bonus += 0.45
			_sentinel_attack_rate_multiplier *= 1.35
		"arch_e_deadeye_bloom":
			_deadeye_bloom_enabled = true

func _update_status_cache() -> void:
	if xp_orb_field != null and xp_orb_field.has_method("set_pickup_radius_multiplier"):
		xp_orb_field.set_pickup_radius_multiplier(_xp_pickup_radius_multiplier)
	current_level = _xp_system.level
	current_health = float(player.get("health"))
	max_health = float(player.get("max_health"))
	xp_percent = _xp_system.get_progress()
	var primary_remaining: float = float(cooldown_system.get_remaining(PRIMARY_COOLDOWN_KEY))
	ability_slot_data["primary"]["key"] = GameSettings.get_binding_label("primary_fire")
	ability_slot_data["ability_one"]["key"] = GameSettings.get_binding_label("ability_1")
	ability_slot_data["dash"]["key"] = GameSettings.get_binding_label("dash")
	ability_slot_data["ability_two"]["key"] = GameSettings.get_binding_label("ability_2")
	ability_slot_data["ultimate"]["key"] = GameSettings.get_binding_label("ultimate")
	ability_slot_data["primary"]["cooldown_seconds"] = primary_remaining
	ability_slot_data["primary"]["charge_pips_total"] = 0
	ability_slot_data["primary"]["charge_pips_filled"] = 0
	ability_slot_data["ultimate"]["charge_pips_total"] = 0
	ability_slot_data["ultimate"]["charge_pips_filled"] = 0
	if _weapon_is_arcane():
		var missiles_remaining: float = float(cooldown_system.get_remaining(MISSILES_COOLDOWN_KEY))
		var bomb_remaining: float = float(cooldown_system.get_remaining(BOMB_COOLDOWN_KEY))
		var blink_remaining: float = float(cooldown_system.get_remaining(BLINK_COOLDOWN_KEY))
		var sniper_cooldown_remaining: float = float(cooldown_system.get_remaining(ULTIMATE_COOLDOWN_KEY))
		primary_mode_label = "SNIPER" if _sniper_remaining > 0.0 else "READY"
		ability_one_label = "READY" if missiles_remaining <= 0.0 else "%.1fs" % missiles_remaining
		ability_two_label = "READY" if bomb_remaining <= 0.0 else "%.1fs" % bomb_remaining
		dash_label = "READY" if blink_remaining <= 0.0 else "%.1fs" % blink_remaining
		ultimate_label = "%.1fs" % _sniper_remaining if _sniper_remaining > 0.0 else ("READY" if sniper_cooldown_remaining <= 0.0 else "%.1fs" % sniper_cooldown_remaining)
		ability_slot_data["primary"]["state_text"] = primary_mode_label
		ability_slot_data["ability_one"]["state_text"] = ability_one_label
		ability_slot_data["dash"]["state_text"] = dash_label
		ability_slot_data["ability_two"]["state_text"] = ability_two_label
		ability_slot_data["ultimate"]["state_text"] = ultimate_label
		ability_slot_data["primary"]["cooldown_show"] = primary_remaining > 0.0
		ability_slot_data["primary"]["cooldown_fill"] = clampf(primary_remaining / max(ARCANE_PRIMARY_FIRE_COOLDOWN if _sniper_remaining <= 0.0 else 0.62, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_show"] = missiles_remaining > 0.0
		ability_slot_data["ability_one"]["cooldown_fill"] = clampf(missiles_remaining / max(ARCANE_MISSILES_COOLDOWN * _missiles_cooldown_multiplier, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_seconds"] = missiles_remaining
		ability_slot_data["dash"]["cooldown_show"] = blink_remaining > 0.0
		ability_slot_data["dash"]["cooldown_fill"] = clampf(blink_remaining / max(ARCANE_BLINK_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["dash"]["cooldown_seconds"] = blink_remaining
		ability_slot_data["dash"]["charge_pips_total"] = 0
		ability_slot_data["dash"]["charge_pips_filled"] = 0
		ability_slot_data["ability_two"]["cooldown_show"] = bomb_remaining > 0.0
		ability_slot_data["ability_two"]["cooldown_fill"] = clampf(bomb_remaining / max(ARCANE_BOMB_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ability_two"]["cooldown_seconds"] = bomb_remaining
		ability_slot_data["ability_two"]["charge_pips_total"] = 0
		ability_slot_data["ability_two"]["charge_pips_filled"] = 0
		ability_slot_data["ultimate"]["cooldown_show"] = _sniper_remaining > 0.0 or sniper_cooldown_remaining > 0.0
		ability_slot_data["ultimate"]["cooldown_fill"] = clampf((_sniper_remaining if _sniper_remaining > 0.0 else sniper_cooldown_remaining) / max(ARCANE_SNIPER_DURATION if _sniper_remaining > 0.0 else ARCANE_SNIPER_COOLDOWN, 0.001), 0.0, 1.0)
		ability_slot_data["ultimate"]["cooldown_seconds"] = _sniper_remaining if _sniper_remaining > 0.0 else sniper_cooldown_remaining
	else:
		var power_shot_remaining: float = float(cooldown_system.get_remaining(POWER_SHOT_COOLDOWN_KEY))
		primary_mode_label = "READY" if primary_remaining <= 0.0 else "%.1fs" % primary_remaining
		ability_one_label = "READY" if power_shot_remaining <= 0.0 else "%.1fs" % power_shot_remaining
		if _dash_charge_count >= _dash_charge_max:
			dash_label = "%d/%d" % [_dash_charge_count, _dash_charge_max]
		else:
			dash_label = "%d/%d  %.1fs" % [_dash_charge_count, _dash_charge_max, _dash_recharge_timer]
		var arrow_volley_remaining: float = float(cooldown_system.get_remaining(ARROW_VOLLEY_COOLDOWN_KEY))
		ability_two_label = "READY" if arrow_volley_remaining <= 0.0 else "%.1fs" % arrow_volley_remaining
		if sentinel_ability and sentinel_ability.is_active():
			ultimate_label = "%.1fs" % sentinel_ability.get_remaining()
		else:
			var sentinel_pct: int = int(round((sentinel_ability.get_charge_pct() if sentinel_ability else 0.0) * 100.0))
			ultimate_label = "READY" if sentinel_ability and sentinel_ability.is_ready() else "%d%%" % sentinel_pct
		ability_slot_data["primary"]["state_text"] = primary_mode_label
		ability_slot_data["ability_one"]["state_text"] = ability_one_label
		ability_slot_data["dash"]["state_text"] = dash_label
		ability_slot_data["ability_two"]["state_text"] = ability_two_label
		ability_slot_data["ultimate"]["state_text"] = ultimate_label
		ability_slot_data["primary"]["cooldown_show"] = primary_remaining > 0.0
		ability_slot_data["primary"]["cooldown_fill"] = clampf(primary_remaining / max(primary_fire_cooldown, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_show"] = power_shot_remaining > 0.0
		ability_slot_data["ability_one"]["cooldown_fill"] = clampf(power_shot_remaining / max(power_shot_cooldown, 0.001), 0.0, 1.0)
		ability_slot_data["ability_one"]["cooldown_seconds"] = power_shot_remaining
		var dash_recharge_max: float = max(dash_cooldown * _dash_cooldown_multiplier, 0.001)
		ability_slot_data["dash"]["cooldown_show"] = _dash_charge_count < _dash_charge_max
		ability_slot_data["dash"]["cooldown_fill"] = clampf(_dash_recharge_timer / dash_recharge_max, 0.0, 1.0) if _dash_charge_count < _dash_charge_max else 0.0
		ability_slot_data["dash"]["cooldown_seconds"] = _dash_recharge_timer if _dash_charge_count < _dash_charge_max else 0.0
		ability_slot_data["dash"]["charge_pips_total"] = _dash_charge_max
		ability_slot_data["dash"]["charge_pips_filled"] = _dash_charge_count
		ability_slot_data["ability_two"]["cooldown_show"] = arrow_volley_remaining > 0.0
		ability_slot_data["ability_two"]["cooldown_fill"] = clampf(arrow_volley_remaining / max(arrow_volley_cooldown, 0.001), 0.0, 1.0)
		ability_slot_data["ability_two"]["cooldown_seconds"] = arrow_volley_remaining
		ability_slot_data["ability_two"]["charge_pips_total"] = 0
		ability_slot_data["ability_two"]["charge_pips_filled"] = 0
		if sentinel_ability and sentinel_ability.is_active():
			var active_duration: float = max(float(sentinel_ability.get("duration")), 0.001)
			ability_slot_data["ultimate"]["cooldown_show"] = true
			ability_slot_data["ultimate"]["cooldown_fill"] = clampf(sentinel_ability.get_remaining() / active_duration, 0.0, 1.0)
		else:
			var charge_pct_value: float = sentinel_ability.get_charge_pct() if sentinel_ability else 0.0
			ability_slot_data["ultimate"]["cooldown_show"] = charge_pct_value < 1.0
			ability_slot_data["ultimate"]["cooldown_fill"] = clampf(1.0 - charge_pct_value, 0.0, 1.0)
		ability_slot_data["ultimate"]["cooldown_seconds"] = float(sentinel_ability.get_remaining()) if sentinel_ability != null and sentinel_ability.is_active() else 0.0
		var active_element_label: String = _get_active_element_label()
		ability_slot_data["primary"]["summary"] = "Manual bow pressure toward the cursor."
		ability_slot_data["primary"]["detail"] = "Hunter's Bow fires the Archer's baseline shot wherever you aim. Active attunement: %s." % active_element_label
		ability_slot_data["ability_one"]["summary"] = "Manual piercing burst. %s" % (
			"No attunement active." if active_element_label == "None" else "%s attunement empowers your bow and burst follow-up." % active_element_label
		)
		ability_slot_data["ability_one"]["detail"] = "Power Shot fires a heavy piercing arrow toward the cursor with guaranteed critical behavior. Active attunement: %s." % active_element_label
		ability_slot_data["dash"]["detail"] = "Dash spends one stored charge to reposition instantly toward the cursor. Current charges: %d / %d.%s" % [
			_dash_charge_count,
			_dash_charge_max,
			" Two Dashes grants the extra stored charge." if _dash_charge_max > 1 else "",
		]
		ability_slot_data["ability_two"]["summary"] = "Manual cone volley toward the cursor."
		ability_slot_data["ability_two"]["detail"] = "Arrow Volley fires a broad cone in the aimed direction. Use it to sweep clustered enemies and hold lane space."
	for slot_key in ["ability_one", "ability_two", "dash", "ultimate"]:
		if not ability_slot_data[slot_key].has("charge_pips_total"):
			ability_slot_data[slot_key]["charge_pips_total"] = 0
		if not ability_slot_data[slot_key].has("charge_pips_filled"):
			ability_slot_data[slot_key]["charge_pips_filled"] = 0
	progress_bar_mode = "thresholds"
	progress_bar_show_markers = true
	progress_threshold_markers = _get_progress_threshold_markers()
	match _objective_phase:
		"objectives":
			progress_panel_title = "BOSS PROGRESS"
			progress_panel_value = clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0)
			if _awaiting_reward_chest:
				objective_state_label = "Claim the reward chest"
				objective_progress = progress_panel_value
				progress_panel_detail = ""
			elif _is_elite_interstitial_active():
				objective_state_label = "Elite Encounter - defeat the Deepwood Stalker"
				if _active_elite != null and is_instance_valid(_active_elite):
					var elite_health: float = float(_active_elite.get("health")) if _node_has_property(_active_elite, "health") else 0.0
					var elite_max_health: float = max(float(_active_elite.get("max_health")) if _node_has_property(_active_elite, "max_health") else 1.0, 1.0)
					objective_progress = clampf(1.0 - elite_health / elite_max_health, 0.0, 1.0)
				else:
					objective_progress = 0.0
				progress_panel_detail = ""
			elif _current_objective_type == OBJECTIVE_PENTAGON_SHRINE and not _active_shrine_objectives.is_empty():
				_sync_active_shrine_objectives()
				objective_state_label = "Shrine Network - %s" % _get_shrine_status_text()
				progress_panel_detail = ""
			elif _current_objective_type == OBJECTIVE_CORES:
				objective_state_label = "Destroy the forest cores (%d/%d)" % [_destroyed_core_count, core_objective_required_count]
				objective_progress = clampf(float(_destroyed_core_count) / max(float(core_objective_required_count), 1.0), 0.0, 1.0)
				progress_panel_detail = ""
			elif _completed_objective_count < _objective_queue.size():
				var next_threshold: float = _get_next_objective_threshold()
				objective_state_label = "Build pressure to %.0f%% for the next objective" % next_threshold
				objective_progress = progress_panel_value
				progress_panel_detail = ""
			else:
				objective_state_label = "Deepwood objectives complete"
				objective_progress = progress_panel_value
				progress_panel_detail = ""
		"portal":
			objective_state_label = "Enter the boss portal"
			objective_progress = clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0)
			progress_panel_title = "BOSS PORTAL"
			progress_panel_detail = ""
			progress_panel_value = objective_progress
		"boss":
			objective_state_label = "Defeat the Treent Overlord"
			progress_bar_mode = "boss"
			progress_bar_show_markers = false
			if _boss != null and is_instance_valid(_boss):
				objective_progress = clamp(1.0 - (float(_boss.get("health")) / max(float(_boss.get("max_health")), 1.0)), 0.0, 1.0)
			else:
				objective_progress = 0.0
			progress_panel_title = "TREENT OVERLORD"
			progress_panel_detail = ""
			progress_panel_value = objective_progress
		"cleared":
			objective_state_label = "Forest cleared"
			objective_progress = 1.0
			progress_panel_title = "FOREST CLEARED"
			progress_panel_detail = ""
			progress_panel_value = 1.0
	_refresh_objective_hud_strings()
	if _boss != null and is_instance_valid(_boss):
		var boss_phase: int = int(_boss.get("phase"))
		var boss_mechanic: String = str(_boss.get("territory_label"))
		boss_status_label = "Boss HP %.0f / %.0f | Phase %d%s" % [
			float(_boss.get("health")),
			float(_boss.get("max_health")),
			boss_phase,
			"" if boss_mechanic.is_empty() else " | %s" % boss_mechanic,
		]
	else:
		boss_status_label = ""
		if _objective_phase == "boss" and not _boss_roots.is_empty():
			boss_status_label = "Destroy roots to break free"
	if _profile_overlay_open:
		profile_data = _build_profile_data()
		_profile_data_dirty = false
	elif _profile_data_dirty and profile_data.is_empty():
		profile_data = _build_profile_data()
		_profile_data_dirty = false
	_upgrade_prompt()

func _refresh_objective_hud_strings() -> void:
	objective_hud_visible = false
	objective_hud_headline = ""
	objective_hud_progress_line = ""
	objective_hud_timer_line = ""
	if _objective_phase != "objectives":
		return
	if _objective_notice_time_remaining > 0.0:
		objective_hud_visible = true
		objective_hud_headline = _objective_notice_headline
		objective_hud_progress_line = _objective_notice_progress_line
		objective_hud_timer_line = _objective_notice_timer_line
		return
	if _awaiting_reward_chest:
		return
	if _is_elite_interstitial_active():
		objective_hud_visible = true
		objective_hud_headline = "Elite Encounter"
		if _active_elite != null and is_instance_valid(_active_elite):
			var elite_health: float = float(_active_elite.get("health")) if _node_has_property(_active_elite, "health") else 0.0
			var elite_max_health: float = max(float(_active_elite.get("max_health")) if _node_has_property(_active_elite, "max_health") else 1.0, 1.0)
			objective_hud_progress_line = "Stalker HP: %d%%" % int(round(clampf(elite_health / elite_max_health, 0.0, 1.0) * 100.0))
			objective_hud_timer_line = ""
		else:
			objective_hud_progress_line = "Incoming from the treeline"
			objective_hud_timer_line = ""
		return
	if _completed_objective_count >= _objective_queue.size() or _current_objective_type.is_empty():
		return
	objective_hud_visible = true
	match _current_objective_type:
		OBJECTIVE_PENTAGON_SHRINE:
			_sync_active_shrine_objectives()
			objective_hud_headline = "Shrine Network"
			objective_hud_progress_line = "Shrines completed: %d / %d" % [_completed_shrine_count, shrine_objective_required_count]
			objective_hud_timer_line = "Time left: %s" % _format_mm_ss(_objective_time_remaining)
		OBJECTIVE_CORES:
			objective_hud_headline = "Destroy the forest cores"
			objective_hud_progress_line = "Cores destroyed: %d / %d" % [_destroyed_core_count, core_objective_required_count]
			objective_hud_timer_line = "Time left: %s" % _format_mm_ss(_objective_time_remaining)
		_:
			objective_hud_headline = objective_state_label
			objective_hud_progress_line = "Progress: %d%%" % int(round(objective_progress * 100.0))
			objective_hud_timer_line = "Time left: %s" % _format_mm_ss(_objective_time_remaining)

func _should_auto_fire_primary() -> bool:
	if not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	var max_range: float = ARCANE_PRIMARY_RANGE if _weapon_is_arcane() else primary_attack_range
	return player.global_position.distance_squared_to(nearest.global_position) <= max_range * max_range

func _has_arrow_volley_target_in_range() -> bool:
	if arrow_volley_ability == null:
		return false
	var ability_anchor: Node2D = player.get_node("AbilityAnchor") as Node2D
	if ability_anchor == null:
		return false
	return not arrow_volley_ability.get_targets_in_range(
		ability_anchor,
		_get_sorted_enemies_by_distance(player.global_position)
	).is_empty()

func _should_auto_cast_missiles() -> bool:
	if not _weapon_is_arcane():
		return false
	if not cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const MISSILES_AUTO_RANGE: float = 400.0
	return player.global_position.distance_squared_to(nearest.global_position) <= MISSILES_AUTO_RANGE * MISSILES_AUTO_RANGE

func _should_auto_cast_bomb() -> bool:
	if not _weapon_is_arcane():
		return false
	if not cooldown_system.is_ready(BOMB_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	const BOMB_AUTO_RANGE: float = 350.0
	return player.global_position.distance_squared_to(nearest.global_position) <= BOMB_AUTO_RANGE * BOMB_AUTO_RANGE

func _should_auto_cast_power_shot() -> bool:
	if _weapon_is_arcane():
		return false
	if not cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY):
		return false
	var nearest: Node2D = _find_nearest_enemy(player.global_position)
	if nearest == null or not is_instance_valid(nearest):
		return false
	var max_range: float = primary_attack_range + 90.0
	return player.global_position.distance_squared_to(nearest.global_position) <= max_range * max_range

func _should_auto_cast_arrow_volley() -> bool:
	if _weapon_is_arcane():
		return false
	if not cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		return false
	return _has_arrow_volley_target_in_range()

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

func _on_boss_bark_shot(origin: Vector2, target: Vector2, speed: float, damage: float, source_kind: String = "boss") -> void:
	var bark: Area2D = ENEMY_BARK_SCENE.instantiate() as Area2D
	if bark == null:
		return
	bark.global_position = origin
	bark.set("direction", origin.direction_to(target))
	bark.set("speed", speed)
	bark.set("damage", damage)
	if source_kind == "small_treent":
		bark.set("visual_scale", 1.45)
		bark.set("trail_length", 28.0)
		bark.set("trail_width", 7.5)
	elif source_kind == "deepwood_stalker":
		bark.set("visual_scale", 1.2)
		bark.set("trail_length", 24.0)
		bark.set("trail_width", 6.2)
	projectiles.add_child(bark)

func _on_encompass_root(duration: float) -> void:
	player.apply_root(duration)

func _on_territory_started() -> void:
	boss_status_label = "Treent Overlord | Hold the safe lane"
	_spawn_boss_roots()
	_spawn_territory_vines()

func _on_territory_ended() -> void:
	_clear_boss_roots()
	_clear_territory_vines()

func _upgrade_prompt() -> void:
	if _upgrade_choices.is_empty():
		upgrade_overlay_title = ""
		_upgrade_overlay_mode = ""
		_upgrade_overlay_context.clear()
		upgrade_prompt = ""
		upgrade_choices_display.clear()
		selected_upgrade_index_display = -1
		return
	var selected: Dictionary = _upgrade_choices[_selected_upgrade_index]
	var detail: String = str(selected.get("description", ""))
	var hint: String = "Click, Enter, or R to choose"
	if _upgrade_rerolls_remaining > 0:
		hint += " | SPACE reroll (%d left)" % _upgrade_rerolls_remaining
	if _upgrade_overlay_mode == "reward":
		hint = "Rare chest reward | %s" % hint
	else:
		var stored_charges: int = _rarity_charge.get_charges(run_time)
		if stored_charges > 0:
			hint += " | Stored rarity %d" % stored_charges
	upgrade_prompt = "%s\n%s" % [detail, hint]

func _sync_upgrade_display() -> void:
	upgrade_choices_display = []
	for choice in _upgrade_choices:
		upgrade_choices_display.append(choice.duplicate(true))
	selected_upgrade_index_display = _selected_upgrade_index if not _upgrade_choices.is_empty() else -1
	upgrade_display_version += 1
	if hud != null and hud.has_method("refresh_upgrade_overlay"):
		hud.refresh_upgrade_overlay()

func _commit_selected_upgrade() -> void:
	if _upgrade_choices.is_empty():
		return
	var upgrade_id: String = str(_upgrade_choices[_selected_upgrade_index].get("id", ""))
	var consume_level_up: bool = _upgrade_overlay_mode != "reward"
	_apply_upgrade(upgrade_id, consume_level_up)
	_close_upgrade_overlay()

func _close_upgrade_overlay() -> void:
	_upgrade_choices.clear()
	_sync_upgrade_display()
	_clear_combat_juice()
	get_tree().paused = false
	var was_reward: bool = _upgrade_overlay_mode == "reward"
	_upgrade_overlay_mode = ""
	_upgrade_overlay_context.clear()
	upgrade_overlay_title = ""
	if was_reward and _awaiting_reward_chest:
		_awaiting_reward_chest = false
		_pending_elite_reward_chest = false
		_objective_transition_timer = objective_transition_delay
	_update_status_cache()

func _reroll_upgrade_choices() -> void:
	if _upgrade_choices.is_empty() or _upgrade_rerolls_remaining <= 0:
		return
	var reroll_options: Dictionary = _upgrade_overlay_context.duplicate(true)
	var excluded_ids: Array[String] = []
	for choice in _upgrade_choices:
		excluded_ids.append(str(choice.get("id", "")))
	reroll_options["excluded_ids"] = excluded_ids
	var rerolled: Array[Dictionary] = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, _selected_weapon_id, reroll_options)
	if rerolled.is_empty():
		reroll_options.erase("excluded_ids")
		rerolled = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, _selected_weapon_id, reroll_options)
	if rerolled.is_empty():
		return
	_upgrade_rerolls_remaining = max(_upgrade_rerolls_remaining - 1, 0)
	_upgrade_overlay_context = reroll_options
	_upgrade_choices = rerolled
	_selected_upgrade_index = 0
	_sync_upgrade_display()
	_update_status_cache()

func _open_upgrade_overlay(mode: String = "level_up", options: Dictionary = {}) -> void:
	if not _upgrade_choices.is_empty():
		return
	_upgrade_overlay_mode = mode
	_upgrade_overlay_context = options.duplicate(true)
	if mode == "level_up":
		upgrade_overlay_title = "Level Up"
		if not _upgrade_overlay_context.has("rarity_bonus"):
			_upgrade_overlay_context["rarity_bonus"] = _rarity_charge.consume(run_time)
		if not _upgrade_overlay_context.has("luck"):
			_upgrade_overlay_context["luck"] = clampf(float(_upgrade_history.size()) / 24.0, 0.0, 0.35)
	else:
		upgrade_overlay_title = str(options.get("title", "Rare Chest"))
	_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, _selected_weapon_id, _upgrade_overlay_context)
	if _upgrade_choices.is_empty():
		_upgrade_overlay_mode = ""
		_upgrade_overlay_context.clear()
		upgrade_overlay_title = ""
		return
	_manual_pause = false
	_profile_overlay_open = false
	_selected_upgrade_index = 0
	_sync_upgrade_display()
	_update_status_cache()
	## Pause game so player can only interact with upgrade menu; main has PROCESS_MODE_ALWAYS so upgrade input still runs.
	_clear_combat_juice()
	get_tree().paused = true

func _apply_active_arena_limits(active_arena: Node2D) -> void:
	if active_arena == null:
		return
	if active_arena.has_method("apply_camera_limits") and player.has_node("Camera2D"):
		active_arena.apply_camera_limits(player.get_node("Camera2D"))
	if spawner != null and spawner.has_method("set_spawn_bounds") and active_arena.has_method("get_spawn_bounds"):
		spawner.set_spawn_bounds(active_arena.get_spawn_bounds())

func _clear_scene_for_boss_transition() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != null and is_instance_valid(node) and not node.is_in_group("boss"):
			node.queue_free()
	for child in projectiles.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	_boss_roots.clear()
	_clear_territory_vines()
	_clear_active_shrine_objectives()
	pending_spawn_count = 0
	_pending_spawn_indicator_ids.clear()
	_active_elite = null
	_awaiting_elite_encounter = false
	_pending_elite_reward_chest = false

func _on_spawn_indicator_triggered(_indicator_position: Vector2, spawn_position: Vector2, scene: PackedScene, indicator_id: int, on_spawned: Callable = Callable()) -> void:
	_resolve_pending_spawn_indicator(indicator_id)
	var spawned_enemy: Node = _spawn_enemy_now(scene, spawn_position)
	if on_spawned.is_valid():
		on_spawned.call(spawned_enemy)

func _on_spawn_indicator_exited(indicator_id: int) -> void:
	_resolve_pending_spawn_indicator(indicator_id)

func _resolve_pending_spawn_indicator(indicator_id: int) -> void:
	if not _pending_spawn_indicator_ids.has(indicator_id):
		return
	_pending_spawn_indicator_ids.erase(indicator_id)
	pending_spawn_count = max(pending_spawn_count - 1, 0)

func _get_spawn_indicator_position(spawn_position: Vector2) -> Vector2:
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return spawn_position
	var viewport_size: Vector2 = _get_camera_world_view_size(camera)
	var center: Vector2 = camera.global_position
	var direction: Vector2 = spawn_position - center
	if direction.length_squared() <= 0.0001:
		return center
	var safe_half: Vector2 = viewport_size * 0.5 - Vector2(92.0, 92.0)
	var scale_x: float = 999999.0 if absf(direction.x) <= 0.001 else safe_half.x / absf(direction.x)
	var scale_y: float = 999999.0 if absf(direction.y) <= 0.001 else safe_half.y / absf(direction.y)
	var scale: float = minf(1.0, minf(scale_x, scale_y))
	return center + direction * scale

func _get_camera_world_view_size(camera: Camera2D) -> Vector2:
	if camera == null:
		return Vector2.ZERO
	if camera.has_method("get_world_view_size"):
		return camera.call("get_world_view_size")
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	return Vector2(
		viewport_size.x / maxf(camera.zoom.x, 0.001),
		viewport_size.y / maxf(camera.zoom.y, 0.001)
	)

func _get_opening_wave_offsets(count: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var chosen_positions: Array[Vector2] = []
	for _i in range(count):
		var chosen_offset: Vector2 = Vector2.ZERO
		var fallback_offset: Vector2 = Vector2.ZERO
		var found_separated_position: bool = false
		if spawner != null and spawner.has_method("get_first_minute_spawn_offset"):
			for attempt in range(12):
				var candidate_offset: Vector2 = spawner.get_first_minute_spawn_offset(player.global_position)
				var candidate_position: Vector2 = player.global_position + candidate_offset
				if attempt == 0:
					fallback_offset = candidate_offset
				var separated: bool = true
				for existing_position in chosen_positions:
					if existing_position.distance_to(candidate_position) < 220.0:
						separated = false
						break
				if separated:
					chosen_offset = candidate_offset
					found_separated_position = true
					break
		if not found_separated_position:
			chosen_offset = fallback_offset if fallback_offset != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU) * 340.0
		chosen_positions.append(player.global_position + chosen_offset)
		offsets.append(chosen_offset)
	return offsets

func _on_damage_taken(world_position: Vector2, amount: float, is_crit: bool) -> void:
	_spawn_damage_number(world_position, amount, is_crit)

func _on_enemy_damage_feedback(data: Dictionary) -> void:
	_spawn_damage_number(
		Vector2(data.get("world_position", Vector2.ZERO)),
		float(data.get("amount", 0.0)),
		bool(data.get("is_crit", false))
	)
	if bool(data.get("heavy_hit", false)) and not bool(data.get("suppress_impact_juice", false)):
		var kind: String = str(data.get("hit_kind", "arrow"))
		if kind not in ["power", "sentinel", "sniper"]:
			_spawn_hit_feedback(Vector2(data.get("world_position", Vector2.ZERO)), "heavy")
	if bool(data.get("killed", false)):
		_spawn_glow(Vector2(data.get("world_position", Vector2.ZERO)), Color(1.0, 0.88, 0.52, 0.22), 14.0, 30.0, 0.14)
	if _combat_juice != null:
		_combat_juice.trigger_enemy_hit(data)

func _spawn_damage_number(world_position: Vector2, amount: float, is_crit: bool) -> void:
	if GameSettings and not GameSettings.show_damage_numbers:
		return
	var number: Label = DAMAGE_NUMBER_SCENE.instantiate() as Label
	if number == null:
		return
	number.global_position = world_position
	if number.has_method("setup"):
		number.setup(amount, is_crit)
	effects.add_child(number)

func _maybe_shake_on_enemy_feedback(data: Dictionary) -> void:
	if player == null or not player.has_method("add_screen_shake"):
		return
	var hit_kind: String = str(data.get("hit_kind", "arrow"))
	var is_crit: bool = bool(data.get("is_crit", false))
	var target: Node = data.get("target") as Node
	var intensity: float = 0.0
	if hit_kind == "power":
		intensity = maxf(intensity, power_hit_shake_intensity)
	elif hit_kind == "sentinel":
		intensity = maxf(intensity, sentinel_hit_shake_intensity)
	if is_crit:
		intensity = maxf(intensity, crit_hit_shake_intensity)
	if target != null and is_instance_valid(target):
		if target.is_in_group("elite"):
			intensity = maxf(intensity, elite_hit_shake_intensity)
		if target.is_in_group("boss"):
			intensity = maxf(intensity, boss_hit_shake_intensity)
	if intensity <= 0.0:
		return
	player.add_screen_shake(intensity, strong_hit_shake_duration)

func _node_has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.name) == property_name:
			return true
	return false

func _get_attack_speed_multiplier() -> float:
	return _primary_rate_multiplier

func _get_crit_chance() -> float:
	return _crit_chance

func _build_primary_attack_payload(impact_direction: Vector2, hit_kind: String) -> Dictionary:
	var payload: Dictionary = {
		"impact_direction": impact_direction,
		"hit_kind": hit_kind,
		"effects_parent": effects,
	}
	if _ricochet_bounces > 0:
		payload["ricochet_bounces"] = _ricochet_bounces
		payload["ricochet_range"] = 220.0
	if active_primary_element == "fire":
		payload["proc_burn"] = true
		payload["burn_stacks"] = 1
		payload["burn_duration"] = 3.0
		payload["burn_tick_damage"] = CombatBalance.BURN_TICK_DAMAGE * _burn_damage_multiplier
	if active_primary_element == "ice":
		payload["proc_chill"] = true
		payload["chill_stacks"] = 1
		payload["chill_duration"] = 2.0 + _ice_chill_duration_bonus
		payload["chill_slow_mul"] = _ice_slow_mul
		payload["ice_blast_enabled"] = _ice_blast_enabled
		payload["ice_blast_radius"] = 70.0 + _ice_blast_radius_bonus
		payload["ice_blast_damage_ratio"] = 0.05
		payload["freeze_spread_enabled"] = _freeze_spread_enabled
		payload["freeze_spread_duration"] = 1.5 + _ice_chill_duration_bonus
	if active_primary_element == "lightning":
		payload["proc_lightning"] = true
		payload["chain_jumps"] = 1 + _lightning_chain_bonus_jumps
		payload["chain_range"] = 180.0
		payload["chain_damage_ratio"] = 0.35
	return payload

func _build_profile_data() -> Dictionary:
	var objective_queue_names: Array[String] = []
	for objective_id in _objective_queue:
		objective_queue_names.append(_get_objective_display_name(objective_id))
	var weapon_name: String = _get_selected_weapon_name()
	var summary_lines: Array[String] = [
		"Weapon: %s" % weapon_name,
		"Run Time: %s" % _format_run_time(run_time),
		"Level %d | XP %d%%" % [current_level, int(round(xp_percent * 100.0))],
		"Kills: %d | Enemies: %d" % [kills, enemy_count],
		"Rerolls: %d | Rarity Charge: %d" % [_upgrade_rerolls_remaining, _rarity_charge.get_charges(run_time)],
		"Objective: %s" % objective_state_label,
		"Deepwood Slots: %d / %d" % [_completed_objective_count, max(_objective_queue.size(), 1)],
		"Objective Order: %s" % (", ".join(objective_queue_names) if not objective_queue_names.is_empty() else "Pending"),
	]
	if not _weapon_is_arcane():
		summary_lines.insert(1, "Attunement: %s" % _get_active_element_label())
	var stats_lines: Array[String]
	if _weapon_is_arcane():
		stats_lines = [
			"HP %d / %d" % [int(round(current_health)), int(round(max_health))],
			"Primary Damage %.1f" % (CombatBalance.ARCANE_PISTOL_BASE_DAMAGE * _primary_damage_multiplier),
			"Sniper Damage %.1f" % (CombatBalance.ARCANE_SNIPER_BASE_DAMAGE * _primary_damage_multiplier * _sniper_damage_multiplier),
			"Attack Speed x%.2f" % _get_attack_speed_multiplier(),
			"Move Speed %.0f" % (ARCANE_BASE_MOVE_SPEED * _move_speed_multiplier),
			"Missiles %.2fs | Bomb %.2fs" % [ARCANE_MISSILES_COOLDOWN * _missiles_cooldown_multiplier, ARCANE_BOMB_COOLDOWN],
			"Blink %.2fs | Sniper %.2fs" % [ARCANE_BLINK_COOLDOWN, ARCANE_SNIPER_COOLDOWN],
			"Boss Progress %d%%" % int(round(clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0) * 100.0)),
			"Screen Shake %d%%" % int(round((GameSettings.screen_shake if GameSettings else 1.0) * 100.0)),
		]
	else:
		stats_lines = [
			"HP %d / %d" % [int(round(current_health)), int(round(max_health))],
			"Primary Damage %.1f" % (CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier),
			"Attack Speed x%.2f" % _get_attack_speed_multiplier(),
			"Crit %d%% | Crit Damage x%.2f" % [int(round(_get_crit_chance() * 100.0)), _crit_multiplier],
			"Move Speed %.0f" % (ARCHER_BASE_MOVE_SPEED * _move_speed_multiplier),
			"Dash Charges %d / %d | Recharge %.2fs" % [_dash_charge_count, _dash_charge_max, dash_cooldown * _dash_cooldown_multiplier],
			"Power Shot %.2fs | Arrow Volley %.2fs" % [power_shot_cooldown, arrow_volley_cooldown],
			"Sentinel Duration %.1fs" % (8.0 + _sentinel_duration_bonus),
			"Boss Progress %d%%" % int(round(clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0) * 100.0)),
			"Screen Shake %d%%" % int(round((GameSettings.screen_shake if GameSettings else 1.0) * 100.0)),
		]
	var owned_upgrade_lines: Array[String] = []
	for entry in _upgrade_history:
		owned_upgrade_lines.append("%s [%s]" % [str(entry.get("name", "Upgrade")), str(entry.get("rarity", "common")).capitalize()])
	if owned_upgrade_lines.is_empty():
		owned_upgrade_lines.append("No upgrades acquired yet.")
	return {
		"title": "Run Profile",
		"subtitle": "Deepwood status snapshot",
		"summary_text": "\n".join(summary_lines),
		"stats_text": "\n".join(stats_lines),
		"upgrades_text": "\n".join(owned_upgrade_lines),
	}

func _get_objective_display_name(objective_id: String) -> String:
	match objective_id:
		OBJECTIVE_CORES:
			return "Destroy the Cores"
		OBJECTIVE_PENTAGON_SHRINE:
			return "Shrine Network"
		_:
			return objective_id.capitalize()

func _get_active_element_label() -> String:
	match active_primary_element:
		"fire":
			return "Fire"
		"ice":
			return "Ice"
		"lightning":
			return "Lightning"
		_:
			return "None"

func _format_run_time(total_seconds: float) -> String:
	var seconds: int = int(floor(total_seconds))
	var minutes: int = seconds / 60
	var remainder: int = seconds % 60
	return "%02d:%02d" % [minutes, remainder]

func _fire_split_shot_pair(direction: Vector2) -> void:
	for spread_degrees in [-8.0, 8.0]:
		var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
		if shot == null:
			continue
		var shot_direction: Vector2 = direction.rotated(deg_to_rad(spread_degrees))
		shot.global_position = player.get_muzzle_global_position()
		shot.set("direction", shot_direction)
		shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier * 0.7)
		shot.set("speed", 500.0)
		shot.set("pierce_count", _primary_pierce_bonus)
		shot.set("crit_chance", _get_crit_chance())
		shot.set("crit_multiplier", _crit_multiplier)
		shot.set("visual_style", "arrow_volley")
		shot.set("attack_payload", _build_primary_attack_payload(shot_direction, "volley"))
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("volley"))
		projectiles.add_child(shot)

func _spawn_arrow_storm() -> void:
	for i in range(6):
		var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
		if shot == null:
			continue
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(i) / 6.0)
		shot.global_position = player.global_position
		shot.set("direction", direction)
		shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier * 0.85)
		shot.set("speed", 520.0)
		shot.set("pierce_count", max(0, _primary_pierce_bonus))
		shot.set("crit_chance", _get_crit_chance())
		shot.set("crit_multiplier", _crit_multiplier)
		shot.set("visual_style", "arrow")
		shot.set("attack_payload", _build_primary_attack_payload(direction, "storm"))
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("power"))
		projectiles.add_child(shot)
	_spawn_glow(player.global_position, Color(1.0, 0.88, 0.44, 0.26), 10.0, 28.0, 0.16)

func _spawn_deadeye_bloom(origin: Vector2) -> void:
	var targets: Array[Node2D] = _get_sorted_enemies_by_distance(origin)
	var fired: int = 0
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		if fired >= 3:
			break
		var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
		if shot == null:
			continue
		var direction: Vector2 = origin.direction_to(target.global_position)
		if direction.length_squared() <= 0.0001:
			continue
		shot.global_position = origin
		shot.set("direction", direction)
		shot.set("damage", CombatBalance.ARCHER_BASE_DAMAGE * _primary_damage_multiplier * 0.7)
		shot.set("speed", 560.0)
		shot.set("pierce_count", 0)
		shot.set("crit_chance", _get_crit_chance())
		shot.set("crit_multiplier", _crit_multiplier)
		shot.set("visual_style", "arrow")
		shot.set("attack_payload", _build_primary_attack_payload(direction, "bloom"))
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback").bind("arrow"))
		projectiles.add_child(shot)
		fired += 1

func _consume_dash_charge() -> void:
	_dash_charge_count = max(_dash_charge_count - 1, 0)
	if _dash_charge_count < _dash_charge_max and _dash_recharge_timer <= 0.0:
		_dash_recharge_timer = dash_cooldown * _dash_cooldown_multiplier

func _tick_dash_recharge(delta: float) -> void:
	if _dash_charge_count >= _dash_charge_max:
		_dash_recharge_timer = 0.0
		return
	_dash_recharge_timer = max(_dash_recharge_timer - delta, 0.0)
	if _dash_recharge_timer <= 0.0:
		_dash_charge_count = min(_dash_charge_count + 1, _dash_charge_max)
		if _dash_charge_count < _dash_charge_max:
			_dash_recharge_timer = dash_cooldown * _dash_cooldown_multiplier

func _add_major_progress(amount: float) -> void:
	_major_progress = min(major_progress_max, _major_progress + max(amount, 0.0))
	_mark_profile_dirty()

func _spawn_boss_roots() -> void:
	_clear_boss_roots()
	for angle_degrees in [210.0, 270.0, 330.0]:
		var root_position: Vector2 = player.global_position + Vector2.RIGHT.rotated(deg_to_rad(angle_degrees)) * 90.0
		_spawn_enemy_now(BOSS_ROOT_SCENE, root_position)

func _spawn_territory_vines() -> void:
	_clear_territory_vines()
	var arena_rect: Rect2 = Rect2(240.0, 160.0, 1440.0, 760.0)
	if boss_arena != null and boss_arena.has_method("get_arena_rect"):
		arena_rect = boss_arena.get_arena_rect()
	var lane_centers: Array[float] = []
	if boss_arena != null and boss_arena.has_method("get_lane_centers"):
		lane_centers = boss_arena.get_lane_centers(_territory_lane_count)
	if lane_centers.is_empty():
		for i in range(_territory_lane_count):
			lane_centers.append(arena_rect.position.y + arena_rect.size.y * float(i + 1) / float(_territory_lane_count + 1))
	var safe_lane_index: int = randi_range(0, max(lane_centers.size() - 1, 0))
	for i in range(lane_centers.size()):
		if i == safe_lane_index:
			continue
		var vine: Node2D = VINE_LANE_SCENE.instantiate() as Node2D
		if vine == null:
			continue
		vine.set("damage", _territory_lane_damage)
		if vine.has_method("setup"):
			vine.setup(arena_rect, lane_centers[i])
		effects.add_child(vine)

func _clear_territory_vines() -> void:
	for vine in get_tree().get_nodes_in_group("territory_vines"):
		if vine != null and is_instance_valid(vine):
			vine.queue_free()

func _clear_boss_roots() -> void:
	for root in _boss_roots:
		if root != null and is_instance_valid(root):
			root.queue_free()
	_boss_roots.clear()
	player.clear_root()

func _on_player_damaged(amount: float) -> void:
	_mark_profile_dirty()
	if player == null:
		return
	_spawn_hit_feedback(player.global_position, "flash")
	_spawn_glow(player.global_position, Color(1.0, 0.38, 0.34, 0.22), 10.0, 30.0, 0.14)
	if _combat_juice != null:
		_combat_juice.trigger_player_hit({
			"amount": amount,
		})

func _clear_combat_juice() -> void:
	if _combat_juice != null:
		_combat_juice.clear_state()

func _is_next_objective_unlocked() -> bool:
	if _current_objective_type != "" or _awaiting_reward_chest or _is_elite_interstitial_active():
		return false
	if _completed_objective_count >= _objective_queue.size():
		return false
	return _major_progress >= _get_next_objective_threshold()

func _is_elite_interstitial_active() -> bool:
	return _awaiting_elite_encounter or _pending_elite_reward_chest or (_active_elite != null and is_instance_valid(_active_elite))

func _get_next_objective_threshold() -> float:
	if _completed_objective_count < 0 or objective_thresholds.is_empty():
		return 0.0
	var threshold_index: int = min(_completed_objective_count, objective_thresholds.size() - 1)
	return float(objective_thresholds[threshold_index])

func _get_progress_threshold_markers() -> Array[float]:
	var markers: Array[float] = []
	for threshold in objective_thresholds:
		markers.append(clampf(float(threshold) / max(major_progress_max, 1.0), 0.0, 1.0))
	return markers

func _mark_profile_dirty() -> void:
	_profile_data_dirty = true
