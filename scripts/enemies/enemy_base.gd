extends CharacterBody2D
class_name EnemyBase

@export var max_health: float = 25.0
@export var move_speed: float = 90.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D

var health: float

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_update_health_bar()

func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	_hit_feedback()
	_update_health_bar()
	if health <= 0.0:
		die()

func die() -> void:
	if has_node("/root/GameEvents"):
		GameEvents.enemy_killed.emit(self)
	queue_free()

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = health < max_health

func _hit_feedback() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1.6, 0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.09)
