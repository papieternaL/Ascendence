extends Node

func apply_hit(target: Node, amount: float) -> void:
	if target.has_method("take_damage"):
		target.call("take_damage", amount)
