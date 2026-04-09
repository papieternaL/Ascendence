extends Node
class_name DamageSystem

static func resolve_damageable_target(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("take_damage"):
		return target
	if target is Area2D:
		var parent: Node = target.get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null

static func build_hit_payload(base_damage: float, crit_chance: float = 0.0, crit_multiplier: float = 1.5) -> Dictionary:
	var amount_value: float = max(base_damage, 0.0)
	var is_crit: bool = false
	var crit_roll: float = clamp(crit_chance, 0.0, 1.0)
	if crit_roll > 0.0 and randf() <= crit_roll:
		is_crit = true
		amount_value *= max(crit_multiplier, 1.0)
	return {
		"amount": amount_value,
		"is_crit": is_crit,
	}

static func apply_hit(target: Node, attack: Variant) -> Dictionary:
	var resolved: Node = resolve_damageable_target(target)
	if resolved == null:
		return {}
	var payload: Dictionary = {}
	if attack is Dictionary:
		var attack_data: Dictionary = attack
		payload = attack_data.duplicate(true)
	else:
		payload = {
			"amount": float(attack),
			"is_crit": false,
		}
	payload["amount"] = max(float(payload.get("amount", 0.0)), 0.0)
	payload["is_crit"] = bool(payload.get("is_crit", false))
	resolved.call("take_damage", payload)
	return payload
