extends Node

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const CHASER_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/ChaserEnemy.tscn")
const OBJECTIVE_CORE_SCENE: PackedScene = preload("res://scenes/enemies/ObjectiveCore.tscn")
const TREENT_BOSS_SCENE: PackedScene = preload("res://scenes/enemies/TreentBoss.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/projectiles/Missile.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const ENEMY_BARK_SCENE: PackedScene = preload("res://scenes/projectiles/EnemyBarkShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")
const DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
const TRAIL_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/TrailEffect.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const BLINK_COOLDOWN_KEY: StringName = &"arcane_blink"
const MISSILES_COOLDOWN_KEY: StringName = &"arcane_missiles"
const ULTIMATE_COOLDOWN_KEY: StringName = &"arcane_sniper"

@export var primary_fire_cooldown: float = 0.2
@export var blink_cooldown: float = 1.2
@export var arcane_missiles_cooldown: float = 5.0
@export var arcane_sniper_cooldown: float = 18.0
@export var arcane_sniper_duration: float = 7.0
@export var enemy_spawn_interval: float = 2.4
@export var max_active_enemies: int = 8
@export var contact_damage_interval: float = 0.8
@export var core_objective_kill_threshold: int = 10
@export var core_reward_xp: int = 45

@onready var arena: Node2D = $Arena
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner

@onready var arcane_missiles_ability: Node2D = $Entities/Player/AbilityAnchor/ArcaneMissiles
@onready var arcane_sniper_ability: Node2D = $Entities/Player/AbilityAnchor/ArcaneSniper

var current_level: int = 1
var current_health: float = 100.0
var max_health: float = 100.0
var xp_percent: float = 0.0
var wave_number: int = 1
var kills: int = 0
var enemy_count: int = 0
var run_time: float = 0.0
var target_label: String = "None"
var primary_mode_label: String = "Arcane Pistol"
var dash_label: String = "Arcane Blink Ready (Space)"
var ability_two_label: String = "Arcane Missiles AUTO"
var ultimate_label: String = "Arcane Sniper Ready (R)"
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
	"primary": {"key": "LMB", "icon": "pistol"},
	"dash": {"key": "SPACE", "icon": "blink"},
	"ability_two": {"key": "E", "icon": "missiles"},
	"ultimate": {"key": "R", "icon": "sniper"},
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_opening_wave()
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, BLINK_COOLDOWN_KEY, MISSILES_COOLDOWN_KEY, ULTIMATE_COOLDOWN_KEY)
	if hud.has_method("bind_game"):
		hud.bind_game(self)
	if player.has_signal("died"):
		player.connect("died", Callable(self, "_on_player_died"))
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	player.move_speed *= _move_speed_multiplier
	if arcane_sniper_ability:
		arcane_sniper_ability.set("duration", arcane_sniper_duration)
		arcane_sniper_ability.set("cooldown", arcane_sniper_cooldown)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		request_toggle_pause()
	if arcane_sniper_ability and arcane_sniper_ability.has_method("tick"):
		arcane_sniper_ability.tick(delta)
		_sniper_remaining = float(arcane_sniper_ability.get_remaining())
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
		_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, RunConfig.CLASS_ARCANE_PISTOL)
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
	if _should_auto_fire_primary():
		_fire_arcane_pistol()
		var cooldown: float = primary_fire_cooldown / _primary_rate_multiplier
		if _sniper_remaining > 0.0:
			cooldown = 0.62 / _primary_rate_multiplier
		cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, cooldown)

	if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(BLINK_COOLDOWN_KEY):
		var blink_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if player.start_dash(blink_direction):
			cooldown_system.set_cooldown(BLINK_COOLDOWN_KEY, blink_cooldown)

	if cooldown_system.is_ready(MISSILES_COOLDOWN_KEY) and _current_target != null:
		_cast_arcane_missiles()

	if Input.is_action_just_pressed("ultimate") and cooldown_system.is_ready(ULTIMATE_COOLDOWN_KEY):
		if arcane_sniper_ability and arcane_sniper_ability.has_method("activate"):
			arcane_sniper_ability.activate(cooldown_system, ULTIMATE_COOLDOWN_KEY)
			_sniper_remaining = float(arcane_sniper_ability.get_remaining())

func _fire_arcane_pistol() -> void:
	var target: Node2D = _current_target
	var shot_scene: PackedScene = BULLET_SCENE
	if _sniper_remaining > 0.0:
		shot_scene = SNIPER_SCENE
	var shot: Area2D = shot_scene.instantiate() as Area2D
	if shot == null:
		return

	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = player.global_position.direction_to(player.get_global_mouse_position())
	if target:
		direction = shot.global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	shot.set("direction", direction)
	if _sniper_remaining > 0.0:
		shot.set("damage", 38.0 * _primary_damage_multiplier * _sniper_damage_multiplier)
		shot.set("speed", 1450.0)
		shot.set("pierce_count", 2 + _sniper_pierce_bonus)
	else:
		shot.set("damage", 16.0 * _primary_damage_multiplier)
		shot.set("speed", 720.0)
		shot.set("pierce_count", 0)

	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	projectiles.add_child(shot)
	_spawn_trail(player.get_muzzle_global_position(), player.get_muzzle_global_position() + direction * (48.0 if _sniper_remaining > 0.0 else 20.0), Color(1.0, 0.8, 0.4, 0.75) if _sniper_remaining > 0.0 else Color(0.62, 0.96, 1.0, 0.55), 4.0 if _sniper_remaining > 0.0 else 2.0)

func _cast_arcane_missiles() -> void:
	if not arcane_missiles_ability or not arcane_missiles_ability.has_method("cast"):
		return
	var targets: Array[Node2D] = _get_sorted_enemies_by_distance(player.global_position)
	arcane_missiles_ability.set("missiles_per_cast", 3 + _missiles_count_bonus)
	var spawned: int = arcane_missiles_ability.cast(player.get_node("AbilityAnchor") as Node2D, MISSILE_SCENE, projectiles, targets)
	if spawned > 0:
		for child in projectiles.get_children():
			if child is Area2D and child.has_signal("hit") and not child.is_connected("hit", Callable(self, "_spawn_hit_feedback")):
				child.connect("hit", Callable(self, "_spawn_hit_feedback"))
		var missiles_cd: float = arcane_missiles_cooldown * _missiles_cooldown_multiplier
		cooldown_system.set_cooldown(MISSILES_COOLDOWN_KEY, missiles_cd)

func _spawn_opening_wave() -> void:
	_spawn_enemy(DUMMY_ENEMY_SCENE, Vector2(220, -80))
	_spawn_enemy(CHASER_ENEMY_SCENE, Vector2(310, -20))
	_spawn_enemy(CHASER_ENEMY_SCENE, Vector2(-260, -30))

func _spawn_enemy(scene: PackedScene, offset: Vector2) -> void:
	var spawn_position: Vector2 = player.global_position + offset
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
	elif enemy.is_in_group("objective_core"):
		_active_cores.append(enemy as Node2D)

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
		objective_state_label = "Forest cleared"
		boss_status_label = ""
		game_over_prompt = "Treent Overlord defeated. Click or press R to restart."
	if _xp_system.has_pending_level_up() and _upgrade_choices.is_empty():
		_upgrade_choices = UpgradeCatalog.get_choices(_xp_system.level, _upgrade_counts, RunConfig.CLASS_ARCANE_PISTOL)
		_selected_upgrade_index = 0
		_sync_upgrade_display()
		get_tree().paused = true

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
			player.move_speed = 180.0 * _move_speed_multiplier
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
	primary_mode_label = "Arcane Sniper" if _sniper_remaining > 0.0 else "Arcane Pistol"
	var blink_remaining: float = float(cooldown_system.get_remaining(BLINK_COOLDOWN_KEY))
	dash_label = "Arcane Blink Ready (Space)" if blink_remaining <= 0.0 else "Arcane Blink %.1fs" % blink_remaining
	var missiles_remaining: float = float(cooldown_system.get_remaining(MISSILES_COOLDOWN_KEY))
	ability_two_label = "Arcane Missiles AUTO" if missiles_remaining <= 0.0 else "Arcane Missiles %.1fs" % missiles_remaining
	if _sniper_remaining > 0.0:
		ultimate_label = "Arcane Sniper %.1fs" % _sniper_remaining
	else:
		var remaining: float = float(cooldown_system.get_remaining(ULTIMATE_COOLDOWN_KEY))
		ultimate_label = "Arcane Sniper Ready (R)" if remaining <= 0.0 else "Arcane Sniper %.1fs" % remaining
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
	_upgrade_prompt()

func _should_auto_fire_primary() -> bool:
	if _current_target == null or not cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		return false
	return player.global_position.distance_squared_to(_current_target.global_position) <= 520.0 * 520.0

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
