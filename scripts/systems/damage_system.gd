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

static func apply_hit(target: Node, amount: float) -> bool:
	var resolved: Node = resolve_damageable_target(target)
	if resolved == null:
		return false
	resolved.call("take_damage", amount)
	return true
