extends CharacterBody2D
class_name EnemyBase

@export var max_health: float = 25.0
@export var move_speed: float = 90.0
@export var body_color: Color = Color(0.94, 0.6, 0.56, 1.0)
@export var contact_damage: float = 8.0
@export var xp_reward: int = 18
@export var display_name: String = "Enemy"
@export var enemy_kind: String = "enemy"

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D

var health: float
var _flash_remaining: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group(enemy_kind)
	health = max_health
	_update_health_bar()
	queue_redraw()

func _process(delta: float) -> void:
	if _flash_remaining > 0.0:
		_flash_remaining = max(_flash_remaining - delta, 0.0)
		queue_redraw()

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
	_flash_remaining = 0.09
	queue_redraw()

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / 0.09, 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	draw_circle(Vector2(0, 6), 11.0, Color(0.05, 0.14, 0.1, 0.22))
	draw_circle(Vector2.ZERO, 11.0, tint)
	draw_circle(Vector2(0, -3), 4.0, Color(1.0, 1.0, 1.0, 0.18))
