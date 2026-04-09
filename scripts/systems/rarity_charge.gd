extends RefCounted
class_name RarityCharge

var charges: int = 0
var max_charges: int = 14
var charge_expiry_sec: float = 60.0
var rare_per_charge: float = 0.01
var epic_per_charge: float = 0.004
var max_rare_bonus: float = 0.10
var max_epic_bonus: float = 0.04

var _last_charge_time: float = 0.0

func add_charge(now: float, amount: int = 1) -> void:
	tick(now)
	charges = mini(charges + max(amount, 0), max_charges)
	_last_charge_time = now

func tick(now: float) -> void:
	if charges > 0 and now - _last_charge_time >= charge_expiry_sec:
		charges = 0

func consume(now: float) -> Dictionary:
	tick(now)
	var stored: int = charges
	charges = 0
	return {
		"charges": stored,
		"rareBonus": min(stored * rare_per_charge, max_rare_bonus),
		"epicBonus": min(stored * epic_per_charge, max_epic_bonus),
	}

func get_charges(now: float) -> int:
	tick(now)
	return charges
