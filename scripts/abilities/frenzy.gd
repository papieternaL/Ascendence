extends Node2D

@export var duration: float = 8.0
@export var charge_required: float = 100.0
@export var charge_per_kill: float = 12.0
@export var move_speed_multiplier: float = 1.25
@export var attack_speed_multiplier: float = 1.5
@export var crit_chance_bonus: float = 0.25
@export var damage_taken_multiplier: float = 1.15

var active_remaining: float = 0.0
var current_charge: float = 0.0

func tick(delta: float) -> void:
	active_remaining = max(active_remaining - delta, 0.0)

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

func is_ready() -> bool:
	return active_remaining <= 0.0 and current_charge >= charge_required

func is_active() -> bool:
	return active_remaining > 0.0

func break_on_hit() -> void:
	active_remaining = 0.0

func get_charge_pct() -> float:
	if charge_required <= 0.0:
		return 1.0
	return clamp(current_charge / charge_required, 0.0, 1.0)

func get_remaining() -> float:
	return active_remaining
