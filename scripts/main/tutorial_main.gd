extends Node

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const SNIPER_SCENE: PackedScene = preload("res://scenes/projectiles/SniperShot.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const POWER_SHOT_COOLDOWN_KEY: StringName = &"power_shot"
const DASH_COOLDOWN_KEY: StringName = &"dash"
const ARROW_VOLLEY_COOLDOWN_KEY: StringName = &"arrow_volley"

@onready var arena: Node2D = $Arena
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var tutorial_title: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Title
@onready var tutorial_body: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Body
@onready var tutorial_footer: Label = $UI/TutorialOverlay/TutorialPanel/Margin/VBox/Footer
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner
@onready var power_shot_ability: Node2D = $Entities/Player/AbilityAnchor/PowerShot
@onready var arrow_volley_ability: Node2D = $Entities/Player/AbilityAnchor/ArrowVolley
@onready var frenzy_ability: Node2D = $Entities/Player/AbilityAnchor/Frenzy

var current_level: int = 1
var current_health: float = 100.0
var max_health: float = 100.0
var xp_percent: float = 0.0
var run_time: float = 0.0
var target_label: String = "Training Target"
var primary_mode_label: String = "Power Shot AUTO"
var ability_two_label: String = "Arrow Volley AUTO"
var dash_label: String = "Dash Ready (Space)"
var ultimate_label: String = "Frenzy 100%"
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
	"primary": {"key": "Q", "icon": "power_shot"},
	"dash": {"key": "SPACE", "icon": "dash"},
	"ability_two": {"key": "E", "icon": "power_shot"},
	"ultimate": {"key": "R", "icon": "frenzy"},
}

var _current_target: Node2D
var _last_position: Vector2
var _movement_progress: float = 0.0
var _dash_used: bool = false
var _frenzy_seen: bool = false
var _phase_index: int = 0
var _phase_enemy: Node2D
var _completed: bool = false

var _phases: Array[Dictionary] = [
	{
		"title": "Movement",
		"body": "Move with WASD and cross enough ground to get comfortable with the arena plane.",
		"footer": "Keep moving until the tracker fills.",
	},
	{
		"title": "Primary Fire",
		"body": "Approach the dummy and let Archer auto-fire. The nearest target lock should handle the shot direction.",
		"footer": "Kill the dummy to continue.",
	},
	{
		"title": "Dash",
		"body": "Press Space to use Dash. This is your manual escape and positioning tool.",
		"footer": "Use Dash once to continue.",
	},
	{
		"title": "Auto Abilities",
		"body": "Approach the training group and watch Power Shot and Arrow Volley auto-cast while you keep moving.",
		"footer": "Clear the group to continue.",
	},
	{
		"title": "Frenzy",
		"body": "Press R to activate Frenzy. It boosts move speed, attack speed, and crit pressure for a short burst.",
		"footer": "Activate Frenzy to complete the tutorial.",
	},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	RunConfig.tutorial_requested = false
	if arena.has_method("get_player_spawn_position"):
		player.global_position = arena.get_player_spawn_position()
	if arena.has_method("apply_camera_limits") and player.has_node("Camera2D"):
		arena.apply_camera_limits(player.get_node("Camera2D"))
	_last_position = player.global_position
	if hud:
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.bind_player(player)
		hud.bind_cooldown_system(cooldown_system, POWER_SHOT_COOLDOWN_KEY, DASH_COOLDOWN_KEY, ARROW_VOLLEY_COOLDOWN_KEY, StringName())
		hud.bind_game(self)
	player.move_speed = 224.0
	if frenzy_ability:
		frenzy_ability.current_charge = frenzy_ability.charge_required
	_update_phase()

func _process(delta: float) -> void:
	run_time += delta
	current_health = float(player.get("health"))
	max_health = float(player.get("max_health"))
	if frenzy_ability:
		frenzy_ability.tick(delta)
	_update_targeting()
	_handle_combat()
	_update_dash_state()
	_update_phase_progress()
	_update_status_labels()
	if _completed and (Input.is_action_just_pressed("primary_fire") or Input.is_action_just_pressed("ultimate") or Input.is_action_just_pressed("ui_accept")):
		get_tree().change_scene_to_file("res://scenes/ui/MapSelect.tscn")

func _handle_combat() -> void:
	if _current_target != null and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		_fire_primary_arrow()
		cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, 0.42 / _get_attack_speed_multiplier())
	if cooldown_system.is_ready(POWER_SHOT_COOLDOWN_KEY) and _current_target != null:
		_cast_power_shot()
	if cooldown_system.is_ready(ARROW_VOLLEY_COOLDOWN_KEY):
		_cast_arrow_volley()
	if Input.is_action_just_pressed("dash") and cooldown_system.is_ready(DASH_COOLDOWN_KEY):
		var dash_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if player.start_dash(dash_direction):
			_dash_used = true
			cooldown_system.set_cooldown(DASH_COOLDOWN_KEY, 0.9)
	if Input.is_action_just_pressed("ultimate") and frenzy_ability and frenzy_ability.activate():
		_frenzy_seen = true

func _fire_primary_arrow() -> void:
	var shot: Area2D = BULLET_SCENE.instantiate() as Area2D
	if shot == null:
		return
	shot.global_position = player.get_muzzle_global_position()
	var direction: Vector2 = shot.global_position.direction_to(_current_target.global_position) if _current_target != null else player.aim_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	shot.set("direction", direction)
	shot.set("damage", 10.0)
	shot.set("speed", 500.0)
	shot.set("pierce_count", 0)
	shot.set("crit_chance", _get_crit_chance())
	shot.set("crit_multiplier", 1.5)
	shot.set("visual_style", "arrow")
	if shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	projectiles.add_child(shot)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())

func _cast_power_shot() -> void:
	if power_shot_ability == null or _current_target == null:
		return
	var shot: Area2D = power_shot_ability.cast(player.get_node("AbilityAnchor") as Node2D, SNIPER_SCENE, projectiles, _current_target, 10.0, 1.5)
	if shot:
		shot.set("visual_style", "power_arrow")
	if shot and shot.has_signal("hit"):
		shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	cooldown_system.set_cooldown(POWER_SHOT_COOLDOWN_KEY, 6.0)
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())

func _cast_arrow_volley() -> void:
	if arrow_volley_ability == null:
		return
	var enemies: Array[Node2D] = _get_sorted_enemies_by_distance(player.global_position)
	if enemies.is_empty():
		return
	var shots: Array[Area2D] = arrow_volley_ability.cast(player.get_node("AbilityAnchor") as Node2D, BULLET_SCENE, projectiles, enemies, 10.0, _get_crit_chance(), 1.5)
	if shots.is_empty():
		return
	for shot in shots:
		if shot.has_signal("hit"):
			shot.connect("hit", Callable(self, "_spawn_hit_feedback"))
	player.notify_primary_fired()
	_spawn_arrow_shot_flash(player.get_muzzle_global_position())
	cooldown_system.set_cooldown(ARROW_VOLLEY_COOLDOWN_KEY, 7.2)

func _update_targeting() -> void:
	_current_target = null
	var best_d2: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var target: Node2D = enemy as Node2D
		var d2: float = player.global_position.distance_squared_to(target.global_position)
		if d2 < best_d2:
			best_d2 = d2
			_current_target = target
	if _current_target != null:
		player.set_aim_target(_current_target.global_position)
		target_label = "%s (%.0f HP)" % [str(_current_target.get("display_name")), float(_current_target.get("health"))]
	else:
		target_label = "No Target"

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			list.append(enemy)
	list.sort_custom(_sort_nodes_by_distance.bind(origin))
	return list

func _sort_nodes_by_distance(a: Node2D, b: Node2D, origin: Vector2) -> bool:
	return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)

func _update_dash_state() -> void:
	var dash_remaining: float = float(cooldown_system.get_remaining(DASH_COOLDOWN_KEY))
	dash_label = "Dash Ready (Space)" if dash_remaining <= 0.0 else "Dash %.1fs" % dash_remaining

func _update_phase_progress() -> void:
	match _phase_index:
		0:
			_movement_progress += player.global_position.distance_to(_last_position)
			_last_position = player.global_position
			objective_progress = clamp(_movement_progress / 220.0, 0.0, 1.0)
			if _movement_progress >= 220.0:
				_advance_phase()
		1:
			objective_progress = 1.0 if _phase_enemy == null or not is_instance_valid(_phase_enemy) else 0.35
			if _phase_enemy == null or not is_instance_valid(_phase_enemy):
				_advance_phase()
		2:
			objective_progress = 1.0 if _dash_used else 0.0
			if _dash_used:
				_advance_phase()
		3:
			var remaining: int = get_tree().get_nodes_in_group("enemies").size()
			objective_progress = 1.0 if remaining == 0 else clamp(1.0 - float(remaining) / 3.0, 0.0, 1.0)
			if remaining == 0:
				if frenzy_ability:
					frenzy_ability.current_charge = frenzy_ability.charge_required
				_advance_phase()
		4:
			objective_progress = 1.0 if _frenzy_seen else 0.0
			if _frenzy_seen:
				_complete_tutorial()

func _update_phase() -> void:
	var phase: Dictionary = _phases[_phase_index]
	tutorial_title.text = str(phase.get("title", "Tutorial"))
	tutorial_body.text = str(phase.get("body", ""))
	tutorial_footer.text = str(phase.get("footer", ""))
	objective_state_label = "Tutorial: %s" % str(phase.get("title", ""))
	_clear_enemies()
	match _phase_index:
		1:
			_phase_enemy = _spawn_dummy(player.global_position + Vector2(170, -20), 55.0)
		3:
			_spawn_dummy(player.global_position + Vector2(170, -40), 55.0)
			_spawn_dummy(player.global_position + Vector2(220, 10), 60.0)
			_spawn_dummy(player.global_position + Vector2(130, 60), 65.0)

func _advance_phase() -> void:
	_phase_index += 1
	if _phase_index >= _phases.size():
		_complete_tutorial()
		return
	_update_phase()

func _complete_tutorial() -> void:
	_completed = true
	objective_state_label = "Tutorial Complete"
	objective_progress = 1.0
	tutorial_title.text = "Tutorial Complete"
	tutorial_body.text = "You have the core Archer loop: movement, auto-fire, Dash, auto abilities, and Frenzy."
	tutorial_footer.text = "Press Enter, click, or press R to continue to map selection."

func _spawn_dummy(position: Vector2, health_amount: float) -> Node2D:
	var enemy: Node = spawner.spawn(DUMMY_ENEMY_SCENE, entities, position)
	if enemy == null:
		return null
	enemy.set("max_health", health_amount)
	enemy.set("health", health_amount)
	return enemy as Node2D

func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	_phase_enemy = null

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

func _get_attack_speed_multiplier() -> float:
	return float(frenzy_ability.get("attack_speed_multiplier")) if frenzy_ability and frenzy_ability.is_active() else 1.0

func _get_crit_chance() -> float:
	var crit: float = 0.05
	if frenzy_ability and frenzy_ability.is_active():
		crit += float(frenzy_ability.get("crit_chance_bonus"))
	return crit

func request_toggle_pause() -> void:
	pass

func request_resume_game() -> void:
	pass

func request_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func is_manual_pause_active() -> bool:
	return false

func has_upgrade_overlay_active() -> bool:
	return false

func _update_status_labels() -> void:
	var power_shot_remaining: float = float(cooldown_system.get_remaining(POWER_SHOT_COOLDOWN_KEY))
	var arrow_volley_remaining: float = float(cooldown_system.get_remaining(ARROW_VOLLEY_COOLDOWN_KEY))
	primary_mode_label = "Power Shot AUTO" if power_shot_remaining <= 0.0 else "Power Shot %.1fs" % power_shot_remaining
	ability_two_label = "Arrow Volley AUTO" if arrow_volley_remaining <= 0.0 else "Arrow Volley %.1fs" % arrow_volley_remaining
	if frenzy_ability and frenzy_ability.is_active():
		ultimate_label = "Frenzy %.1fs" % frenzy_ability.get_remaining()
	else:
		var frenzy_pct: int = int(round(frenzy_ability.get_charge_pct() * 100.0)) if frenzy_ability else 0
		ultimate_label = "Frenzy Ready (R)" if frenzy_ability and frenzy_ability.is_ready() else "Frenzy %d%%" % frenzy_pct
	progress_panel_title = objective_state_label
	progress_panel_detail = tutorial_footer.text
	progress_panel_value = objective_progress
