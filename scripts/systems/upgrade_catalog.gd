extends RefCounted
class_name UpgradeCatalog

const ARCHER_UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "arch_c_sharpened_tips",
		"name": "Sharpened Tips",
		"rarity": "common",
		"icon": "damage",
		"description": "Your arrows deal 10% more damage.",
	},
	{
		"id": "arch_c_quick_nock",
		"name": "Quick Nock",
		"rarity": "common",
		"icon": "attack_speed",
		"description": "Draw and fire arrows 10% faster.",
	},
	{
		"id": "arch_c_fleetfoot",
		"name": "Fleetfoot",
		"rarity": "common",
		"icon": "move",
		"description": "Move 8% faster.",
	},
	{
		"id": "arch_c_piercing_practice",
		"name": "Piercing Practice",
		"rarity": "common",
		"icon": "pierce",
		"description": "Arrows pierce through 2 additional enemies.",
	},
	{
		"id": "arch_c_hollow_points",
		"name": "Hollow Points",
		"rarity": "common",
		"icon": "crit",
		"description": "Critical hits deal 15% more damage.",
	},
	{
		"id": "arch_c_hunters_instinct",
		"name": "Hunter's Instinct",
		"rarity": "common",
		"icon": "crit",
		"description": "5% increased chance to land critical hits.",
	},
	{
		"id": "arch_c_stamina_training",
		"name": "Stamina Training",
		"rarity": "common",
		"icon": "move",
		"description": "Dash recovers 10% faster.",
	},
	{
		"id": "arch_r_split_shot",
		"name": "Split Shot",
		"rarity": "rare",
		"icon": "power_shot",
		"description": "Every 3rd shot fires 2 extra arrows in a spread.",
	},
	{
		"id": "arch_r_thorned_volley",
		"name": "Heavy Volley",
		"rarity": "rare",
		"icon": "power_shot",
		"description": "Arrow Volley deals 35% more damage.",
	},
	{
		"id": "arch_r_piercing_vines",
		"name": "Broadside Volley",
		"rarity": "rare",
		"icon": "power_shot",
		"description": "Arrow Volley fires extra arrows into a wider fan.",
	},
	{
		"id": "arch_r_predatory_focus",
		"name": "Predatory Focus",
		"rarity": "rare",
		"icon": "frenzy_upgrade",
		"description": "During Frenzy, gain 8% additional crit chance.",
	},
	{
		"id": "arch_r_long_breath",
		"name": "Long Breath",
		"rarity": "rare",
		"icon": "frenzy_upgrade",
		"description": "Frenzy lasts 1 second longer.",
	},
]

const ARCANE_UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "charged_rounds",
		"name": "Charged Rounds",
		"rarity": "common",
		"icon": "damage",
		"description": "Arcane Pistol shots hit 20% harder.",
	},
	{
		"id": "quickdraw",
		"name": "Quickdraw",
		"rarity": "common",
		"icon": "attack_speed",
		"description": "Arcane Pistol fires 15% faster.",
	},
	{
		"id": "spellclock",
		"name": "Spellclock",
		"rarity": "common",
		"icon": "missiles",
		"description": "Arcane Missiles recover 18% faster.",
	},
	{
		"id": "phase_stride",
		"name": "Phase Stride",
		"rarity": "common",
		"icon": "blink",
		"description": "Move 12% faster and recover blink positioning more cleanly.",
	},
	{
		"id": "satellite_volley",
		"name": "Satellite Volley",
		"rarity": "rare",
		"icon": "missiles",
		"description": "Arcane Missiles fires one extra missile per cast.",
	},
	{
		"id": "deadeye",
		"name": "Deadeye",
		"rarity": "rare",
		"icon": "sniper",
		"description": "Arcane Sniper gains more damage and one additional pierce.",
	},
]

const RARITY_WEIGHTS := {
	"common": 70.0,
	"rare": 25.0,
	"epic": 5.0,
}

static func get_choices(level: int, acquired: Dictionary = {}, class_id: String = "") -> Array[Dictionary]:
	var resolved_class_id: String = class_id if not class_id.is_empty() else RunConfig.selected_class_id
	var source_pool: Array[Dictionary] = _pool_for_class(resolved_class_id)
	var pool: Array[Dictionary] = []
	for entry in source_pool:
		pool.append(entry.duplicate(true))
	var choices: Array[Dictionary] = []
	var safety: int = 0
	while choices.size() < 3 and not pool.is_empty() and safety < 30:
		safety += 1
		var picked: Dictionary = _pick_weighted(pool, level)
		if picked.is_empty():
			break
		var duplicate_index: int = _find_by_id(pool, str(picked.get("id", "")))
		if duplicate_index >= 0:
			pool.remove_at(duplicate_index)
		var count: int = int(acquired.get(str(picked.get("id", "")), 0))
		if count > 0:
			picked["description"] = "%s\nOwned %dx -> %dx" % [str(picked.get("description", "")), count, count + 1]
		choices.append(picked)
	return choices

static func _pool_for_class(class_id: String) -> Array[Dictionary]:
	if class_id == RunConfig.CLASS_ARCANE_PISTOL:
		return ARCANE_UPGRADE_POOL
	return ARCHER_UPGRADE_POOL

static func _pick_weighted(pool: Array[Dictionary], level: int) -> Dictionary:
	var total: float = 0.0
	for entry in pool:
		total += _weight_for(entry, level)
	if total <= 0.0:
		return {}
	var roll: float = randf() * total
	for entry in pool:
		roll -= _weight_for(entry, level)
		if roll <= 0.0:
			return entry.duplicate(true)
	return pool[0].duplicate(true)

static func _weight_for(entry: Dictionary, level: int) -> float:
	var rarity: String = str(entry.get("rarity", "common"))
	var weight: float = float(RARITY_WEIGHTS.get(rarity, 1.0))
	if rarity == "rare" and level >= 4:
		weight *= 1.2
	return weight

static func _find_by_id(pool: Array[Dictionary], target_id: String) -> int:
	for i in range(pool.size()):
		if str(pool[i].get("id", "")) == target_id:
			return i
	return -1
