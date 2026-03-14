extends CharacterBody2D

@export var move_speed: float = 180.0
@export var max_health: float = 100.0

var health: float

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var ability_anchor: Node2D = $AbilityAnchor

func _ready() -> void:
	add_to_group("player")
	health = max_health

func _physics_process(_delta: float) -> void:
	# TODO(Migration): Replace with full movement + aiming + dash/frenzy pipeline.
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	var aim_dir := global_position.direction_to(get_global_mouse_position())
	if aim_dir.length_squared() > 0.0:
		weapon_pivot.rotation = aim_dir.angle()
	move_and_slide()

func get_muzzle_global_position() -> Vector2:
	return muzzle.global_position
