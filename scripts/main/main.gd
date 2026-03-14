extends Node

const DUMMY_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/DummyEnemy.tscn")
const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/Bullet.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/projectiles/Missile.tscn")
const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/HitEffect.tscn")

const PRIMARY_COOLDOWN_KEY: StringName = &"primary_fire"
const MISSILES_COOLDOWN_KEY: StringName = &"arcane_missiles"

@export var primary_fire_cooldown: float = 0.2
@export var arcane_missiles_cooldown: float = 5.0

@onready var arena: Node2D = $Arena
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var hud: Control = $UI/HUD
@onready var cooldown_system: Node = $Systems/CooldownSystem

@onready var arcane_missiles_ability: Node2D = $Entities/Player/AbilityAnchor/ArcaneMissiles

func _ready() -> void:
	_spawn_demo_enemies()
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if hud.has_method("bind_cooldown_system"):
		hud.bind_cooldown_system(cooldown_system, PRIMARY_COOLDOWN_KEY, MISSILES_COOLDOWN_KEY)

func _process(_delta: float) -> void:
	_handle_combat_input()

func _handle_combat_input() -> void:
	if Input.is_action_pressed("primary_fire") and cooldown_system.is_ready(PRIMARY_COOLDOWN_KEY):
		_fire_arcane_pistol()
		cooldown_system.set_cooldown(PRIMARY_COOLDOWN_KEY, primary_fire_cooldown)

	if Input.is_action_just_pressed("ability_2") and cooldown_system.is_ready(MISSILES_COOLDOWN_KEY):
		_cast_arcane_missiles()
		cooldown_system.set_cooldown(MISSILES_COOLDOWN_KEY, arcane_missiles_cooldown)

func _fire_arcane_pistol() -> void:
	var target := _find_nearest_enemy(player.global_position)
	var bullet := BULLET_SCENE.instantiate() as Area2D
	if bullet == null:
		return

	bullet.global_position = player.get_muzzle_global_position()
	if target:
		bullet.set("direction", bullet.global_position.direction_to(target.global_position))
	else:
		bullet.set("direction", player.global_position.direction_to(player.get_global_mouse_position()))

	if bullet.has_signal("hit"):
		bullet.hit.connect(_spawn_hit_feedback)
	projectiles.add_child(bullet)

func _cast_arcane_missiles() -> void:
	if not arcane_missiles_ability or not arcane_missiles_ability.has_method("cast"):
		return
	var targets := _get_sorted_enemies_by_distance(player.global_position)
	var spawned: int = arcane_missiles_ability.cast(player.get_node("AbilityAnchor") as Node2D, MISSILE_SCENE, projectiles, targets)
	if spawned > 0:
		for child in projectiles.get_children():
			if child is Area2D and child.has_signal("hit") and not child.hit.is_connected(_spawn_hit_feedback):
				child.hit.connect(_spawn_hit_feedback)

func _spawn_demo_enemies() -> void:
	if entities.get_node_or_null("DummyEnemyA") != null:
		return
	var offsets := [Vector2(220, 120), Vector2(310, 160), Vector2(260, 260), Vector2(360, 240)]
	for i in offsets.size():
		var enemy := DUMMY_ENEMY_SCENE.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.name = "DummyEnemy%s" % char(65 + i)
		enemy.global_position = player.global_position + offsets[i]
		entities.add_child(enemy)

func _find_nearest_enemy(origin: Vector2) -> Node2D:
	var best: Node2D
	var best_d2 := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var d2 := origin.distance_squared_to((enemy as Node2D).global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = enemy
	return best

func _get_sorted_enemies_by_distance(origin: Vector2) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			list.append(enemy)
	list.sort_custom(func(a: Node2D, b: Node2D):
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	return list

func _spawn_hit_feedback(at: Vector2) -> void:
	var fx := HIT_EFFECT_SCENE.instantiate() as Node2D
	if fx == null:
		return
	fx.global_position = at
	effects.add_child(fx)
