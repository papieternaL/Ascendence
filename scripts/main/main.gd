extends Node

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const CHASER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/ChaserEnemy.tscn")
const LUNGER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/LungerEnemy.tscn")
const TREENT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/TreentEnemy.tscn")
const SMALL_TREENT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/SmallTreentEnemy.tscn")
const BOSS_ROOT_SCENE: PackedScene = preload("res://scenes/enemies/BossRoot.tscn")
const OBJECTIVE_CORE_SCENE: PackedScene = preload("res://scenes/enemies/ObjectiveCore.tscn")
const TREENT_BOSS_SCENE: PackedScene = preload("res://scenes/enemies/TreentBoss.tscn")
const BOSS_PORTAL_SCENE: PackedScene = preload("res://scenes/main/BossPortal.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const ENEMY_BARK_SCENE: PackedScene = preload("res://scenes/projectiles/EnemyBarkShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")
const DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
const TRAIL_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/TrailEffect.tscn")
const SPAWN_INDICATOR_SCENE: PackedScene = preload("res://scenes/effects/SpawnIndicator.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/effects/DamageNumber.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const POWER_SHOT_COOLDOWN_KEY: StringName = &"power_shot"
const DASH_COOLDOWN_KEY: StringName = &"dash"
const ARROW_VOLLEY_COOLDOWN_KEY: StringName = &"arrow_volley"

@export var primary_fire_cooldown: float = 0.4
@export var primary_attack_range: float = 350.0
@export var dash_cooldown: float = 0.9
@export var power_shot_cooldown: float = 6.0
@export var arrow_volley_cooldown: float = 7.2
@export var spawn_warning_time: float = 0.72
@export var enemy_spawn_interval: float = 2.2
@export var max_active_enemies: int = 12
@export var contact_damage_interval: float = 0.8
@export var core_reward_xp: int = 45
@export var major_progress_max: float = 70.0
@export var core_objective_start_pct: float = 0.25
@export var major_progress_per_kill: float = 0.35
@export var major_progress_per_core_bonus: float = 5.6

@onready var arena: Node2D = $Arena
@onready var boss_arena: Node2D = $BossArena
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner

@onready var power_shot_ability: Node2D = $Entities/Player/AbilityAnchor/PowerShot
@onready var arrow_volley_ability: Node2D = $Entities/Player/AbilityAnchor/ArrowVolley
@onready var frenzy_ability: Node2D = $Entities/Player/AbilityAnchor/Frenzy

var current_level: int = 1
var current_health: float = 100.0
var max_health: float = 100.0
var xp_percent: float = 0.0
var wave_number: int = 1
var kills: int = 0
var enemy_count: int = 0
var run_time: float = 0.0
var target_label: String = "None"
var primary_mode_label: String = "Power Shot Ready"
var dash_label: String = "Dash Ready (Space)"
var ability_two_label: String = "Arrow Volley AUTO"
var ultimate_label: String = "Frenzy 0%"
var objective_state_label: String = "Survive the forest assault"
var boss_status_label: String = ""
var objective_progress: float = 0.0
var progress_panel_title: String = "BOSS PROGRESS"
var progress_panel_detail: String = "Build pressure in Deepwood"
var progress_panel_value: float = 0.0
var upgrade_prompt: String = ""
var game_over_prompt: String = ""
var upgrade_choices_display: Array[Dictionary] = []
var selected_upgrade_index_display: int = -1
var ability_slot_data: Dictionary = {
	"primary": {"key": "Q", "icon": "power_shot"},
	"dash": {"key": "SPACE", "icon": "dash"},
	"ability_two": {"key": "E", "icon": "power_shot"},
	"ultimate": {"key": "R", "icon": "frenzy"},
}

var _xp_system: ExperienceSystem = ExperienceSystem.new()
var _current_target: Node2D
var _boss: Node2D
var _boss_portal: Area2D
var _objective_phase: String = "waves"
var _active_cores: Array[Node2D] = []
var _core_count_total: int = 0
var _spawn_timer: float = 0.0
var _contact_timer: float = 0.0
var _game_over: bool = false
var _in_boss_arena: bool = false
var _manual_pause: bool = false
var _upgrade_choices: Array[Dictionary] = []
var _selected_upgrade_index: int = 0
var _boss_roots: Array[Node2D] = []
var _major_progress: float = 0.0

var _primary_damage_multiplier: float = 1.0
var _primary_rate_multiplier: float = 1.0
var _move_speed_multiplier: float = 1.0
var _primary_pierce_bonus: int = 0
var _arrow_volley_damage_multiplier: float = 1.0
var _arrow_volley_bonus_arrows: int = 0
var _dash_cooldown_multiplier: float = 1.0
var _frenzy_duration_bonus: float = 0.0
var _frenzy_crit_bonus: float = 0.0
var _crit_chance: float = 0.05
var _crit_multiplier: float = 1.5
var _split_shot_enabled: bool = false
var _shots_fired: int = 0
var _upgrade_counts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	if boss_arena:
		boss_arena.visible = false
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	_apply_active_arena_limits(arena)
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_opening_wave()
	GameEvents.wave_started.emit(wave_number)
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		hud.bind_cooldown_system(cooldown_system, POWER_SHOT_COOLDOWN_KEY, DASH_COOLDOWN_KEY, ARROW_VOLLEY_COOLDOWN_KEY, StringName())
	if hud.has_method("bind_game"):
		hud.bind_game(self)
	if player.has_signal("died"):
		player.connect("died", Callable(self, "_on_player_died"))
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.player_damaged.connect(_on_player_damaged)
	player.move_speed = 224.0 * _move_speed_multiplier
	if frenzy_ability:
		frenzy_ability.set("duration", 8.0 + _frenzy_duration_bonus)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		request_toggle_pause()
	if frenzy_ability and frenzy_ability.has_method("tick"):
		frenzy_ability.tick(delta)
	_update_status_cache()
	if _game_over:
		if Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		return
	if _manual_pause:
		return
	if _upgrade_choices.size() > 0:
		_handle_upgrade_input()
		return
	if _xp_system.has_pending_level_up():
		_open_upgrade_overlay()
		return
	run_time += delta
	_spawn_timer += delta
	_contact_timer += delta
	_update_objective_flow()
	_update_targeting()
	_handle_combat_input()
	_handle_spawning()
	_handle_enemy_contact_damage()
	var active_arena: Node2D = boss_arena if _in_boss_arena else arena
	if active_arena != null and active_arena.has_method("clamp_position"):
		player.global_position = active_arena.clamp_position(player.global_position)

func _handle_combat_input() -> void:
	if _should_auto_fire_primary():
		_fire_primary_arrow()
		var cooldown: float = primary_fire_cooldown / _get_attack_speed_multiplier()
		cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, cooldown)

	if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(DASH_COOLDOWN_KEY):
		var dash_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if player.start_dash(dash_direction):
			cooldown_system.set_cooldown(DASH_COOLDOWN_KEY, dash_cooldown * _dash_cooldown_multiplier)
			GameEvents.ability_used.emit(DASH_COOLDOWN_KEY)

	if cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY) and _current_target != null:
		_cast_power_shot()

	if cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		_cast_arrow_volley()

	if Input.is_action_just_pressed("ultimate") and frenzy_ability and frenzy_ability.has_method("activate"):
		if frenzy_ability.activate():
			GameEvents.ability_used.emit(&"frenzy")
			_update_status_cache()

func _fire_primary_arrow() -> void:
	var target: Node2D = _current_target
	var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
	if shot == null:
		return

	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = player.global_position.direction_to(player.get_global_mouse_position())
	if target:
		direction = shot.global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	shot.set("direction", direction)
	shot.set("damage", 10.0 * _primary_damage_multiplier)
	shot.set("speed", 500.0)
	shot.set("pierce_count", _primary_pierce_bonus)
	shot.set("crit_chance", _get_crit_chance())
	shot.set("crit_multiplier", _crit_multiplier)
	shot.set("visual_style", "arrow")

	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	projectiles.add_child(shot)
	player.notify_primary_fired()
	_shots_fired += 1
	if _split_shot_enabled and _shots_fired % 3 == 0:
		_fire_split_shot_pair(direction)
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	_spawn_trail(
		player.get_muzzle_global_position(),
		player.get_muzzle_global_position() + direction * 24.0,
		Color(0.96, 0.84, 0.48, 0.48),
		2.0
	)

func _cast_power_shot() -> void:
	if power_shot_ability == null or _current_target == null:
		return
	var shot: Area2D = power_shot_ability.cast(player.get_node("AbilityAnchor") as Node2D, SNIPER_SCENE, projectiles, _current_target, 10.0 * _primary_damage_multiplier, _crit_multiplier)
	if shot == null:
		return
	shot.set("visual_style", "power_arrow")
	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, power_shot_cooldown)
	GameEvents.ability_used.emit(POWER_SHOT_COOLDOWN_KEY)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	_spawn_trail(player.get_muzzle_global_position(), _current_target.global_position, Color(1.0, 0.82, 0.35, 0.52), 4.0)

func _cast_arrow_volley() -> void:
	if arrow_volley_ability == null:
		return
	var enemies: Array[Node2D] = _get_sorted_enemies_by_distance(player.global_position)
	if enemies.is_empty():
		return
	var shots: Array[Area2D] = arrow_volley_ability.cast(
		player.get_node("AbilityAnchor") as Node2D,
		BULLET_SCENE,
		projectiles,
		enemies,
		10.0 * _primary_damage_multiplier * _arrow_volley_damage_multiplier,
		_get_crit_chance(),
		_crit_multiplier,
		_arrow_volley_bonus_arrows
	)
	if shots.is_empty():
		return
	for shot in shots:
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, arrow_volley_cooldown)
	GameEvents.ability_used.emit(ARROW_VOLLEY_COOLDOWN_KEY)

func _spawn_opening_wave() -> void:
	_spawn_enemy_telegraphed(CHASER_ENEMY_SCENE, Vector2(260, -100))
	_spawn_enemy_telegraphed(CHASER_ENEMY_SCENE, Vector2(360, -40))
	_spawn_enemy_telegraphed(LUNGER_ENEMY_SCENE, Vector2(-320, -40))
	_spawn_enemy_telegraphed(TREENT_ENEMY_SCENE, Vector2(-420, 120))

func _spawn_enemy(scene: PackedScene, offset: Vector2) -> void:
	_spawn_enemy_now(scene, player.global_position + offset)

func _spawn_enemy_now(scene: PackedScene, spawn_position: Vector2) -> void:
	var enemy: Node = spawner.spawn(scene, entities, spawn_position)
	if enemy == null:
		return
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
	elif enemy.has_signal("bark_shot"):
		enemy.connect("bark_shot", Callable(self, "_on_boss_bark_shot"))
	elif enemy.is_in_group("objective_core"):
		_active_cores.append(enemy as Node2D)
	elif enemy.is_in_group("boss_root"):
		_boss_roots.append(enemy as Node2D)
	if enemy.has_signal("damage_taken"):
		enemy.connect("damage_taken", Callable(self, "_on_damage_taken"))

func _spawn_enemy_telegraphed(scene: PackedScene, offset: Vector2) -> void:
	var spawn_position: Vector2 = player.global_position + offset
	var telegraph: Node2D = SPAWN_INDICATOR_SCENE.instantiate() as Node2D
	if telegraph == null:
		_spawn_enemy_now(scene, spawn_position)
		return
	telegraph.global_position = spawn_position
	telegraph.set("delay", spawn_warning_time)
	telegraph.connect("spawn_requested", Callable(self, "_on_spawn_indicator_triggered").bind(scene))
	effects.add_child(telegraph)

func _handle_spawning() -> void:
	if _objective_phase != "waves" and _objective_phase != "cores":
		return
	var active_enemies: int = get_tree().get_nodes_in_group("enemies").size()
	if active_enemies >= max_active_enemies:
		return
	if _spawn_timer < enemy_spawn_interval:
		return
	_spawn_timer = 0.0
	if kills > 0 and kills % 6 == 0:
		wave_number = 1 + int(floor(float(kills) / 6.0))
		GameEvents.wave_started.emit(wave_number)
	var angle: float = randf() * TAU
	var radius: float = 420.0 + randf() * 180.0
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * radius
	var roll: int = randi() % 10
	var scene: PackedScene = CHASER_ENEMY_SCENE
	if roll <= 2:
		scene = LUNGER_ENEMY_SCENE
	elif roll <= 4:
		scene = TREENT_ENEMY_SCENE
	elif roll <= 5:
		scene = SMALL_TREENT_ENEMY_SCENE
	_spawn_enemy_telegraphed(scene, offset)

func _update_objective_flow() -> void:
	if _objective_phase == "waves" and _major_progress >= major_progress_max * core_objective_start_pct:
		_begin_core_objective()
	elif _objective_phase == "cores":
		var living_cores: Array[Node2D] = []
		for core in _active_cores:
			if is_instance_valid(core):
				living_cores.append(core)
		_active_cores = living_cores
		if _active_cores.is_empty() and _major_progress >= major_progress_max:
			_spawn_boss_portal()
	elif _objective_phase == "portal":
		if _boss_portal == null or not is_instance_valid(_boss_portal):
			_enter_boss_arena()
	elif _objective_phase == "boss":
		if _boss == null or not is_instance_valid(_boss):
			_objective_phase = "cleared"
			objective_state_label = "Forest cleared"
			boss_status_label = ""
			game_over_prompt = "Treent Overlord defeated. Click or press R to restart."

func _begin_core_objective() -> void:
	if _objective_phase != "waves":
		return
	_objective_phase = "cores"
	objective_state_label = "Destroy the forest cores"
	if arena.has_method("get_core_positions"):
		var core_positions: Array[Vector2] = arena.get_core_positions()
		_core_count_total = core_positions.size()
		for point in core_positions:
			_spawn_enemy_now(OBJECTIVE_CORE_SCENE, point)

func _spawn_boss_portal() -> void:
	if _objective_phase != "cores":
		return
	_objective_phase = "portal"
	objective_state_label = "Enter the boss portal"
	_xp_system.add_xp(core_reward_xp)
	if _boss_portal != null and is_instance_valid(_boss_portal):
		return
	_boss_portal = BOSS_PORTAL_SCENE.instantiate() as Area2D
	if _boss_portal == null:
		return
	_boss_portal.global_position = Vector2(960, 420)
	_boss_portal.connect("portal_entered", Callable(self, "_enter_boss_arena"))
	entities.add_child(_boss_portal)

func _enter_boss_arena() -> void:
	if _in_boss_arena:
		return
	_in_boss_arena = true
	_objective_phase = "boss"
	objective_state_label = "Treent Overlord awakened"
	if _boss_portal != null and is_instance_valid(_boss_portal):
		_boss_portal.queue_free()
	_clear_scene_for_boss_transition()
	arena.visible = false
	if boss_arena:
		boss_arena.visible = true
		player.global_position = boss_arena.get_player_spawn_position()
	_apply_active_arena_limits(boss_arena)
	GameEvents.wave_started.emit(99)
	_spawn_boss()

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

func _sort_nodes_by_distance(a: Node2D, b: Node2D, origin: Vector2) -> bool:
	return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)

func _update_targeting() -> void:
	_current_target = _find_nearest_enemy(player.global_position)
	var aim_point: Vector2 = player.get_global_mouse_position()
	if _current_target != null:
		var d2: float = player.global_position.distance_squared_to(_current_target.global_position)
		if d2 <= 520.0 * 520.0:
			aim_point = _current_target.global_position
			var label_name: String = str(_current_target.get("display_name"))
			target_label = "%s (%.0f HP)" % [label_name, _current_target.get("health")]
		else:
			_current_target = null
			target_label = "Mouse Aim"
	else:
		target_label = "Mouse Aim"
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

func _spawn_hit_feedback(at: Vector2) -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.84, 0.4, 0.92), "arrow", 5.0, 22.0, 0.14)
	effects.add_child(fx)

func _spawn_arrow_shot_flash(at: Vector2) -> void:
	var fx: Node2D = HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	if fx.has_method("configure"):
		fx.configure(Color(1.0, 0.9, 0.56, 0.82), "flash", 3.0, 10.0, 0.08)
	effects.add_child(fx)

func _spawn_death_feedback(at: Vector2) -> void:
	var fx: Node2D = DEATH_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	effects.add_child(fx)

func _spawn_trail(from: Vector2, to: Vector2, tint: Color, width: float) -> void:
	var fx: Node2D = TRAIL_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	if fx.has_method("setup"):
		fx.setup(Vector2.ZERO, to - from, tint, width)
	fx.global_position = from
	effects.add_child(fx)

func _on_enemy_killed(enemy: Node) -> void:
	kills += 1
	if enemy is Node2D:
		_spawn_death_feedback((enemy as Node2D).global_position)
	var reward: int = int(enemy.get("xp_reward"))
	_xp_system.add_xp(reward)
	if frenzy_ability:
		frenzy_ability.add_charge(float(frenzy_ability.get("charge_per_kill")))
	if enemy.is_in_group("objective_core"):
		_add_major_progress(major_progress_per_core_bonus)
		var remaining_cores: Array[Node2D] = []
		for core in _active_cores:
			if is_instance_valid(core) and core != enemy:
				remaining_cores.append(core)
		_active_cores = remaining_cores
		objective_state_label = "Destroy the forest cores (%d left)" % _active_cores.size()
	elif enemy.is_in_group("boss_root"):
		var living_roots: Array[Node2D] = []
		for root in _boss_roots:
			if is_instance_valid(root) and root != enemy:
				living_roots.append(root)
		_boss_roots = living_roots
		if _boss_roots.is_empty():
			player.clear_root()
	elif enemy.is_in_group("boss"):
		_boss = null
		_objective_phase = "cleared"
		objective_state_label = "Forest cleared"
		boss_status_label = ""
		game_over_prompt = "Treent Overlord defeated. Click or press R to restart."
	else:
		_add_major_progress(major_progress_per_kill)
	if _xp_system.has_pending_level_up() and _upgrade_choices.is_empty():
		_open_upgrade_overlay()

func _on_player_died() -> void:
	get_tree().paused = false
	_game_over = true
	game_over_prompt = "You fell. Click or press R to restart."

func _handle_upgrade_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		_selected_upgrade_index = posmod(_selected_upgrade_index - 1, _upgrade_choices.size())
		_sync_upgrade_display()
	elif Input.is_action_just_pressed("move_right"):
		_selected_upgrade_index = posmod(_selected_upgrade_index + 1, _upgrade_choices.size())
		_sync_upgrade_display()
	elif Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate"):
		_apply_upgrade(_upgrade_choices[_selected_upgrade_index].get("id", ""))
		_upgrade_choices.clear()
		_sync_upgrade_display()
		get_tree().paused = false
		_upgrade_prompt()

func request_upgrade_selection(index: int) -> void:
	if _upgrade_choices.is_empty():
		return
	if index < 0 or index >= _upgrade_choices.size():
		return
	_selected_upgrade_index = index
	_sync_upgrade_display()
	_apply_upgrade(_upgrade_choices[_selected_upgrade_index].get("id", ""))
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
	_manual_pause = not _manual_pause
	get_tree().paused = _manual_pause
	_update_status_cache()

func request_resume_game() -> void:
	if _upgrade_choices.is_empty():
		_manual_pause = false
		get_tree().paused = false
		_update_status_cache()

func request_return_to_menu() -> void:
	_manual_pause = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func is_manual_pause_active() -> bool:
	return _manual_pause

func has_upgrade_overlay_active() -> bool:
	return not _upgrade_choices.is_empty()

func _apply_upgrade(upgrade_id: String) -> void:
	_upgrade_counts[upgrade_id] = int(_upgrade_counts.get(upgrade_id, 0)) + 1
	match upgrade_id:
		"arch_c_sharpened_tips":
			_primary_damage_multiplier *= 1.10
		"arch_c_quick_nock":
			_primary_rate_multiplier *= 1.10
		"arch_c_fleetfoot":
			_move_speed_multiplier *= 1.08
			player.move_speed = 224.0 * _move_speed_multiplier
		"arch_c_piercing_practice":
			_primary_pierce_bonus += 2
		"arch_c_hollow_points":
			_crit_multiplier *= 1.15
		"arch_c_hunters_instinct":
			_crit_chance += 0.05
		"arch_c_stamina_training":
			_dash_cooldown_multiplier *= 0.90
		"arch_r_split_shot":
			_split_shot_enabled = true
		"arch_r_thorned_volley":
			_arrow_volley_damage_multiplier *= 1.35
		"arch_r_piercing_vines":
			_arrow_volley_bonus_arrows += 2
		"arch_r_predatory_focus":
			_frenzy_crit_bonus += 0.08
		"arch_r_long_breath":
			_frenzy_duration_bonus += 1.0
			if frenzy_ability:
				frenzy_ability.set("duration", 8.0 + _frenzy_duration_bonus)
	if _xp_system.has_pending_level_up():
		_xp_system.consume_level_up()

func _update_status_cache() -> void:
	current_level = _xp_system.level
	current_health = float(player.get("health"))
	max_health = float(player.get("max_health"))
	xp_percent = _xp_system.get_progress()
	enemy_count = get_tree().get_nodes_in_group("enemies").size()
	var power_shot_remaining: float = float(cooldown_system.get_remaining(POWER_SHOT_COOLDOWN_KEY))
	primary_mode_label = "Power Shot AUTO" if power_shot_remaining <= 0.0 else "Power Shot %.1fs" % power_shot_remaining
	var dash_remaining: float = float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY))
	dash_label = "Dash Ready (Space)" if dash_remaining <= 0.0 else "Dash %.1fs" % dash_remaining
	var arrow_volley_remaining: float = float(cooldown_system.get_remaining(ARROW_VOLLEY_COOLDOWN_KEY))
	ability_two_label = "Arrow Volley AUTO" if arrow_volley_remaining <= 0.0 else "Arrow Volley %.1fs" % arrow_volley_remaining
	if frenzy_ability and frenzy_ability.is_active():
		ultimate_label = "Frenzy %.1fs" % frenzy_ability.get_remaining()
	else:
		var frenzy_pct: int = int(round((frenzy_ability.get_charge_pct() if frenzy_ability else 0.0) * 100.0))
		ultimate_label = "Frenzy Ready (R)" if frenzy_ability and frenzy_ability.is_ready() else "Frenzy %d%%" % frenzy_pct
	match _objective_phase:
		"waves":
			objective_state_label = "Forest assault: %.0f / %.0f progress" % [_major_progress, major_progress_max]
			objective_progress = clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0)
			progress_panel_title = "BOSS PROGRESS"
			progress_panel_detail = "Deepwood pressure %.0f / %.0f" % [_major_progress, major_progress_max]
			progress_panel_value = objective_progress
		"cores":
			objective_state_label = "Destroy the forest cores (%d left) | %.0f / %.0f progress" % [_active_cores.size(), _major_progress, major_progress_max]
			objective_progress = clamp(_major_progress / max(major_progress_max, 1.0), 0.0, 1.0)
			progress_panel_title = "BOSS PROGRESS"
			progress_panel_detail = "%d cores remain before the portal opens" % _active_cores.size()
			progress_panel_value = objective_progress
		"portal":
			objective_state_label = "Enter the boss portal"
			objective_progress = 1.0
			progress_panel_title = "BOSS PORTAL"
			progress_panel_detail = "Step through to face the Treent Overlord"
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
			progress_panel_detail = "Deepwood boss defeated"
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
		if _objective_phase == "boss" and not _boss_roots.is_empty():
			boss_status_label = "Destroy roots to break free"
			progress_panel_detail = boss_status_label
	_upgrade_prompt()

func _should_auto_fire_primary() -> bool:
	if _current_target == null or not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	return player.global_position.distance_squared_to(_current_target.global_position) <= primary_attack_range * primary_attack_range

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
	_spawn_boss_roots()

func _on_territory_ended() -> void:
	_clear_boss_roots()

func _upgrade_prompt() -> void:
	if _upgrade_choices.is_empty():
		upgrade_prompt = ""
		upgrade_choices_display.clear()
		selected_upgrade_index_display = -1
		return
	var selected: Dictionary = _upgrade_choices[_selected_upgrade_index]
	upgrade_prompt = "%s\n%s" % [str(selected.get("name", "Upgrade")), str(selected.get("description", ""))]

func _sync_upgrade_display() -> void:
	upgrade_choices_display = []
	for choice in _upgrade_choices:
		upgrade_choices_display.append(choice.duplicate(true))
	selected_upgrade_index_display = _selected_upgrade_index if not _upgrade_choices.is_empty() else -1

func _open_upgrade_overlay() -> void:
	if not _upgrade_choices.is_empty():
		return
	_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, RunConfig.CLASS_ARCHER)
	_selected_upgrade_index = 0
	_sync_upgrade_display()
	_update_status_cache()
	get_tree().paused = true

func _apply_active_arena_limits(active_arena: Node2D) -> void:
	if active_arena == null:
		return
	if active_arena.has_method("apply_camera_limits") and player.has_node("Camera2D"):
		active_arena.apply_camera_limits(player.get_node("Camera2D"))

func _clear_scene_for_boss_transition() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != null and is_instance_valid(node) and not node.is_in_group("boss"):
			node.queue_free()
	for child in projectiles.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	_boss_roots.clear()

func _on_spawn_indicator_triggered(spawn_position: Vector2, scene: PackedScene) -> void:
	_spawn_enemy_now(scene, spawn_position)

func _on_damage_taken(world_position: Vector2, amount: float, is_crit: bool) -> void:
	var number: Label = DAMAGE_NUMBER_SCENE.instantiate() as Label
	if number == null:
		return
	number.global_position = world_position
	if number.has_method("setup"):
		number.setup(amount, is_crit)
	effects.add_child(number)

func _node_has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.name) == property_name:
			return true
	return false

func _get_attack_speed_multiplier() -> float:
	var multiplier: float = _primary_rate_multiplier
	if frenzy_ability and frenzy_ability.is_active():
		multiplier *= float(frenzy_ability.get("attack_speed_multiplier"))
	return multiplier

func _get_crit_chance() -> float:
	var chance: float = _crit_chance
	if frenzy_ability and frenzy_ability.is_active():
		chance += float(frenzy_ability.get("crit_chance_bonus")) + _frenzy_crit_bonus
	return chance

func _fire_split_shot_pair(direction: Vector2) -> void:
	for spread_degrees in [-8.0, 8.0]:
		var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
		if shot == null:
			continue
		var shot_direction: Vector2 = direction.rotated(deg_to_rad(spread_degrees))
		shot.global_position = player.get_muzzle_global_position()
		shot.set("direction", shot_direction)
		shot.set("damage", 10.0 * _primary_damage_multiplier * 0.7)
		shot.set("speed", 500.0)
		shot.set("pierce_count", _primary_pierce_bonus)
		shot.set("crit_chance", _get_crit_chance())
		shot.set("crit_multiplier", _crit_multiplier)
		shot.set("visual_style", "arrow_volley")
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
		projectiles.add_child(shot)

func _add_major_progress(amount: float) -> void:
	_major_progress = min(major_progress_max, _major_progress + max(amount, 0.0))

func _spawn_boss_roots() -> void:
	_clear_boss_roots()
	for angle_degrees in [210.0, 270.0, 330.0]:
		var root_position: Vector2 = player.global_position + Vector2.RIGHT.rotated(deg_to_rad(angle_degrees)) * 90.0
		_spawn_enemy_now(BOSS_ROOT_SCENE, root_position)

func _clear_boss_roots() -> void:
	for root in _boss_roots:
		if root != null and is_instance_valid(root):
			root.queue_free()
	_boss_roots.clear()
	player.clear_root()

func _on_player_damaged(_amount: float) -> void:
	if frenzy_ability and frenzy_ability.is_active():
		frenzy_ability.break_on_hit()
