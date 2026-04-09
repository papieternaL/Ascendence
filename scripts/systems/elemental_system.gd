extends RefCounted
class_name ElementalSystem

const ELEMENTAL_BURST_SCENE: PackedScene = preload("res://scenes/effects/ElementalBurst.tscn")
const LIGHTNING_ARC_SCENE: PackedScene = preload("res://scenes/effects/LightningArc.tscn")

static func ensure_status_store(target: Node) -> Dictionary:
	if target == null:
		return {}
	var statuses: Variant = target.get("elemental_statuses")
	if typeof(statuses) != TYPE_DICTIONARY:
		statuses = {}
		target.set("elemental_statuses", statuses)
	return statuses

static func has_status(target: Node, status_name: String) -> bool:
	var statuses: Dictionary = ensure_status_store(target)
	return statuses.has(status_name)

static func get_status(target: Node, status_name: String) -> Dictionary:
	var statuses: Dictionary = ensure_status_store(target)
	return statuses.get(status_name, {})

static func get_status_stacks(target: Node, status_name: String) -> int:
	return int(get_status(target, status_name).get("stacks", 0))

static func is_frozen(target: Node) -> bool:
	return has_status(target, "freeze")

static func get_speed_multiplier(target: Node) -> float:
	if is_frozen(target):
		return 0.0
	var chill: Dictionary = get_status(target, "chill")
	if chill.is_empty():
		return 1.0
	var slow_mul: float = float(chill.get("slow_mul", 1.0))
	return clamp(0.6 / max(slow_mul, 0.01), 0.2, 1.0)

static func apply_status(target: Node, status_name: String, stacks: int, duration: float, options: Dictionary = {}) -> void:
	if target == null:
		return
	var resolved_status: String = status_name
	if status_name == "freeze" and target.is_in_group("boss"):
		resolved_status = "chill"
	var statuses: Dictionary = ensure_status_store(target)
	var entry: Dictionary = statuses.get(resolved_status, {
		"stacks": 0,
		"duration": 0.0,
		"tick_timer": 0.0,
	})
	if resolved_status == "burn":
		entry["stacks"] = int(entry.get("stacks", 0)) + max(stacks, 1)
	else:
		entry["stacks"] = max(int(entry.get("stacks", 0)), max(stacks, 1))
	entry["duration"] = max(float(entry.get("duration", 0.0)), duration)
	for key in options.keys():
		entry[key] = options[key]
	statuses[resolved_status] = entry
	target.set("elemental_statuses", statuses)

static func tick_target(target: Node, delta: float) -> void:
	if target == null:
		return
	var statuses: Dictionary = ensure_status_store(target)
	if statuses.is_empty():
		return
	var to_remove: Array[String] = []
	for status_name in statuses.keys():
		var entry: Dictionary = statuses[status_name]
		entry["duration"] = float(entry.get("duration", 0.0)) - delta
		if float(entry.get("duration", 0.0)) <= 0.0:
			to_remove.append(status_name)
			continue
		if status_name == "burn":
			entry["tick_timer"] = float(entry.get("tick_timer", 0.0)) + delta
			while float(entry.get("tick_timer", 0.0)) >= 0.5:
				entry["tick_timer"] = float(entry.get("tick_timer", 0.0)) - 0.5
				var tick_damage: float = float(entry.get("tick_damage", 2.0)) * max(int(entry.get("stacks", 1)), 1)
				target.take_damage({
					"amount": tick_damage,
					"is_crit": false,
					"hit_kind": "burn",
					"impact_direction": Vector2.ZERO,
					"suppress_impact_juice": true,
				})
				_spawn_burst(
					entry.get("effects_parent"),
					target.global_position,
					"fire",
					Color(1.0, 0.52, 0.16, 0.92),
					Color(1.0, 0.86, 0.54, 0.82),
					20.0
				)
		statuses[status_name] = entry
	for status_name in to_remove:
		statuses.erase(status_name)
	target.set("elemental_statuses", statuses)

static func process_attack_hit(target: Node, attack: Dictionary) -> void:
	if target == null or attack.is_empty():
		return
	var effects_parent: Node = attack.get("effects_parent")
	if bool(attack.get("proc_burn", false)):
		apply_status(target, "burn", int(attack.get("burn_stacks", 1)), float(attack.get("burn_duration", 3.0)), {
			"tick_damage": float(attack.get("burn_tick_damage", 2.0)),
			"effects_parent": effects_parent,
		})
		_spawn_burst(effects_parent, target.global_position, "fire", Color(1.0, 0.52, 0.16, 0.92), Color(1.0, 0.86, 0.54, 0.82), 18.0)
	if bool(attack.get("proc_chill", false)):
		var chill_options: Dictionary = {
			"slow_mul": float(attack.get("chill_slow_mul", 1.0)),
			"effects_parent": effects_parent,
			"ice_blast_enabled": bool(attack.get("ice_blast_enabled", false)),
			"ice_blast_radius": float(attack.get("ice_blast_radius", 70.0)),
			"ice_blast_damage_ratio": float(attack.get("ice_blast_damage_ratio", 0.05)),
			"freeze_spread_enabled": bool(attack.get("freeze_spread_enabled", false)),
			"freeze_spread_duration": float(attack.get("freeze_spread_duration", 1.5)),
		}
		apply_status(target, "chill", int(attack.get("chill_stacks", 1)), float(attack.get("chill_duration", 2.0)), chill_options)
		_spawn_burst(effects_parent, target.global_position, "ice", Color(0.58, 0.86, 1.0, 0.9), Color(0.88, 0.96, 1.0, 0.84), 20.0)
	if bool(attack.get("proc_lightning", false)):
		_chain_damage(target, attack)

static func handle_target_death(target: Node) -> void:
	if target == null:
		return
	var chill: Dictionary = get_status(target, "chill")
	var freeze: Dictionary = get_status(target, "freeze")
	var source: Dictionary = freeze if not freeze.is_empty() else chill
	if source.is_empty():
		return
	if not bool(source.get("ice_blast_enabled", false)):
		return
	var effects_parent: Node = source.get("effects_parent")
	var radius: float = float(source.get("ice_blast_radius", 70.0))
	var damage_ratio: float = float(source.get("ice_blast_damage_ratio", 0.05))
	var damage_amount: float = float(target.get("max_health")) * damage_ratio
	for enemy in target.get_tree().get_nodes_in_group("enemies"):
		if enemy == target or not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if node.global_position.distance_to(target.global_position) > radius:
			continue
		node.take_damage({
			"amount": damage_amount,
			"is_crit": false,
			"hit_kind": "ice_blast",
			"impact_direction": target.global_position.direction_to(node.global_position),
			"suppress_impact_juice": true,
		})
		if bool(source.get("freeze_spread_enabled", false)):
			var applied_status: String = "freeze"
			if node.is_in_group("boss"):
				applied_status = "chill"
			apply_status(node, applied_status, 1, float(source.get("freeze_spread_duration", 1.5)), {
				"slow_mul": float(source.get("slow_mul", 1.0)),
				"effects_parent": effects_parent,
				"ice_blast_enabled": bool(source.get("ice_blast_enabled", false)),
				"ice_blast_radius": radius,
				"ice_blast_damage_ratio": damage_ratio,
				"freeze_spread_enabled": bool(source.get("freeze_spread_enabled", false)),
				"freeze_spread_duration": float(source.get("freeze_spread_duration", 1.5)),
			})
	_spawn_burst(effects_parent, target.global_position, "ice", Color(0.58, 0.86, 1.0, 0.92), Color(0.94, 0.98, 1.0, 0.86), radius)

static func _chain_damage(start_target: Node, attack: Dictionary) -> void:
	if start_target == null:
		return
	var jumps: int = max(int(attack.get("chain_jumps", 0)), 0)
	if jumps <= 0:
		return
	var range_limit: float = float(attack.get("chain_range", 180.0))
	var damage_mul: float = float(attack.get("chain_damage_ratio", 0.35))
	var base_damage: float = float(attack.get("amount", 0.0))
	var effects_parent: Node = attack.get("effects_parent")
	var current: Node2D = start_target as Node2D
	var hit_ids: Dictionary = {start_target.get_instance_id(): true}
	var did_jump: bool = false
	for _i in range(jumps):
		var next_target: Node2D = _find_chain_target(current, range_limit, hit_ids)
		if next_target == null:
			break
		did_jump = true
		hit_ids[next_target.get_instance_id()] = true
		_spawn_lightning_arc(effects_parent, current.global_position, next_target.global_position)
		_spawn_burst(effects_parent, next_target.global_position, "lightning", Color(0.58, 0.86, 1.0, 0.92), Color(1.0, 0.98, 0.9, 0.86), 22.0)
		next_target.take_damage({
			"amount": max(base_damage * damage_mul, 1.0),
			"is_crit": false,
			"hit_kind": "lightning_chain",
			"impact_direction": current.global_position.direction_to(next_target.global_position),
			"suppress_impact_juice": true,
		})
		current = next_target
	if did_jump:
		_spawn_burst(effects_parent, start_target.global_position, "lightning", Color(0.58, 0.86, 1.0, 0.78), Color(1.0, 0.98, 0.9, 0.72), 18.0)

static func _find_chain_target(from_target: Node2D, range_limit: float, hit_ids: Dictionary) -> Node2D:
	var best: Node2D
	var best_d2: float = INF
	for enemy in from_target.get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		var node: Node2D = enemy as Node2D
		if hit_ids.has(node.get_instance_id()):
			continue
		var d2: float = from_target.global_position.distance_squared_to(node.global_position)
		if d2 > range_limit * range_limit:
			continue
		if d2 < best_d2:
			best_d2 = d2
			best = node
	return best

static func _spawn_burst(parent: Variant, world_position: Vector2, style: String, primary: Color, accent: Color, radius: float) -> void:
	if parent == null or not (parent is Node):
		return
	var burst: Node2D = ELEMENTAL_BURST_SCENE.instantiate() as Node2D
	if burst == null:
		return
	burst.global_position = world_position
	if burst.has_method("configure"):
		burst.configure(style, primary, accent, radius)
	(parent as Node).add_child(burst)

static func _spawn_lightning_arc(parent: Variant, from: Vector2, to: Vector2) -> void:
	if parent == null or not (parent is Node):
		return
	var arc: Node2D = LIGHTNING_ARC_SCENE.instantiate() as Node2D
	if arc == null:
		return
	if arc.has_method("setup"):
		arc.setup(Vector2.ZERO, to - from, Color(0.58, 0.86, 1.0, 0.95), 2.4)
	arc.global_position = from
	(parent as Node).add_child(arc)
