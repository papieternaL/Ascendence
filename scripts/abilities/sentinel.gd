extends Node2D

const HAWK_SCENE: PackedScene = preload("res://scenes/abilities/SentinelHawk.tscn")

@export var duration: float = 8.0
@export var charge_required: float = 100.0
@export var charge_per_kill: float = 12.0
@export var hawk_seek_range: float = 560.0
@export var strike_interval: float = 0.42
@export var hawk_speed: float = 760.0
@export var strike_damage_multiplier: float = 2.6

var active_remaining: float = 0.0
var current_charge: float = 0.0
var active_hawk: Node2D

func tick(delta: float) -> void:
	active_remaining = max(active_remaining - delta, 0.0)
	if active_remaining <= 0.0 and active_hawk != null and is_instance_valid(active_hawk):
		active_hawk.queue_free()
		active_hawk = null

func add_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	current_charge = clamp(current_charge + amount, 0.0, charge_required)

func activate() -> bool:
	if not is_ready():
		return false
	active_remaining = duration
	current_charge = 0.0
	return true

func spawn_hawk(player: Node2D, parent: Node, base_damage: float, crit_chance: float, crit_multiplier: float) -> Node2D:
	if active_remaining <= 0.0 or player == null or parent == null:
		return null
	if active_hawk != null and is_instance_valid(active_hawk):
		active_hawk.queue_free()
		active_hawk = null
	var hawk: Node2D = HAWK_SCENE.instantiate() as Node2D
	if hawk == null:
		return null
	hawk.global_position = player.global_position + Vector2(0.0, -34.0)
	if hawk.has_method("setup"):
		hawk.setup(
			player,
			duration,
			hawk_seek_range,
			strike_interval,
			hawk_speed,
			base_damage * strike_damage_multiplier,
			crit_chance,
			crit_multiplier
		)
	parent.add_child(hawk)
	active_hawk = hawk
	return hawk

func is_ready() -> bool:
	return active_remaining <= 0.0 and current_charge >= charge_required

func is_active() -> bool:
	return active_remaining > 0.0

func get_charge_pct() -> float:
	if charge_required <= 0.0:
		return 1.0
	return clamp(current_charge / charge_required, 0.0, 1.0)

func get_remaining() -> float:
	return active_remaining
