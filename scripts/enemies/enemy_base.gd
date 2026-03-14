extends CharacterBody2D
class_name EnemyBase

@export var max_health: float = 25.0
@export var move_speed: float = 90.0

@onready var health_bar: ProgressBar = $HealthBar

var health: float

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_update_health_bar()

func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	_update_health_bar()
	if health <= 0.0:
		die()

func die() -> void:
	# TODO(Migration): route to effects/xp/progression systems.
	queue_free()

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = health < max_health
