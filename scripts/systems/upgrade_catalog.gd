extends RefCounted
class_name UpgradeCatalog

const ARCHER_UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "arch_c_sharpened_tips",
		"name": "Sharpened Tips",
		"rarity": "common",
		"icon": "damage",
		"icon_asset_id": "arch_c_sharpened_tips",
		"description": "Your arrows deal 10% more damage.",
	},
	{
		"id": "arch_c_quick_nock",
		"name": "Quick Nock",
		"rarity": "common",
		"icon": "attack_speed",
		"icon_asset_id": "arch_c_quick_nock",
		"description": "Draw and fire arrows 10% faster.",
	},
	{
		"id": "arch_c_fleetfoot",
		"name": "Fleetfoot",
		"rarity": "common",
		"icon": "move",
		"icon_asset_id": "arch_c_fleetfoot",
		"description": "Move 8% faster.",
	},
	{
		"id": "arch_c_piercing_practice",
		"name": "Piercing Practice",
		"rarity": "common",
		"icon": "pierce",
		"icon_asset_id": "arch_c_piercing_practice",
		"description": "Arrows pierce through 2 additional enemies.",
	},
	{
		"id": "arch_c_hollow_points",
		"name": "Hollow Points",
		"rarity": "common",
		"icon": "crit",
		"icon_asset_id": "arch_c_hollow_points",
		"description": "Critical hits deal 15% more damage.",
	},
	{
		"id": "arch_c_hunters_instinct",
		"name": "Hunter's Instinct",
		"rarity": "common",
		"icon": "crit",
		"icon_asset_id": "arch_c_hunters_instinct",
		"description": "5% increased chance to land critical hits.",
	},
	{
		"id": "arch_c_stamina_training",
		"name": "Stamina Training",
		"rarity": "common",
		"icon": "move",
		"icon_asset_id": "arch_c_stamina_training",
		"description": "Dash recovers 10% faster.",
	},
	{
		"id": "arch_c_xp_magnet",
		"name": "XP Magnet",
		"rarity": "common",
		"icon": "magnet",
		"icon_asset_id": "arch_c_xp_magnet",
		"description": "Collect experience orbs from 15% farther away.",
	},
	{
		"id": "arch_c_ricochet_arrow",
		"name": "Ricochet Arrow",
		"rarity": "common",
		"icon": "ricochet",
		"icon_asset_id": "arch_c_ricochet_arrow",
		"description": "Primary arrows ricochet to 1 nearby enemy. Stacks for extra bounces.",
	},
	{
		"id": "arch_c_fire_attunement",
		"name": "Fire Attunement",
		"rarity": "common",
		"icon": "fire",
		"icon_asset_id": "arch_c_fire_attunement",
		"description": "Primary arrows ignite enemies with burn for 3 seconds.",
		"max_stacks": 1,
	},
	{
		"id": "arch_c_ice_attunement",
		"name": "Ice Attunement",
		"rarity": "common",
		"icon": "ice",
		"icon_asset_id": "arch_c_ice_attunement",
		"description": "Primary arrows apply chill for 2 seconds.",
		"max_stacks": 1,
	},
	{
		"id": "arch_c_lightning_attunement",
		"name": "Lightning Attunement",
		"rarity": "common",
		"icon": "lightning",
		"icon_asset_id": "arch_c_lightning_attunement",
		"description": "Primary arrows chain lightning to 1 nearby target.",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_split_shot",
		"name": "Split Shot",
		"rarity": "rare",
		"icon": "power_shot",
		"icon_asset_id": "arch_r_split_shot",
		"description": "Every 3rd shot fires 2 extra arrows in a spread.",
	},
	{
		"id": "arch_r_thorned_volley",
		"name": "Heavy Volley",
		"rarity": "rare",
		"icon": "power_shot",
		"icon_asset_id": "arch_r_thorned_volley",
		"description": "Arrow Volley deals 35% more damage.",
	},
	{
		"id": "arch_r_expanded_volley",
		"name": "Expanded Volley",
		"rarity": "rare",
		"icon": "arrow_volley",
		"icon_asset_id": "arch_r_expanded_volley",
		"description": "Arrow Volley adds 2 arrows, becoming a tight 5-arrow lane.",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_predatory_focus",
		"name": "Sky Hunter",
		"rarity": "rare",
		"icon": "sentinel_upgrade",
		"icon_asset_id": "arch_r_predatory_focus",
		"description": "Sentinel strikes deal 20% more damage.",
	},
	{
		"id": "arch_r_long_breath",
		"name": "Long Watch",
		"rarity": "rare",
		"icon": "sentinel_upgrade",
		"icon_asset_id": "arch_r_long_breath",
		"description": "Sentinel remains active 3 seconds longer.",
	},
	{
		"id": "arch_r_two_dashes",
		"name": "Two Dashes",
		"rarity": "rare",
		"icon": "dash_charge",
		"icon_asset_id": "arch_r_two_dashes",
		"description": "Gain a second stored Dash charge.",
		},
	{
		"id": "arch_r_fire_intensity",
		"name": "Fire Intensity",
		"rarity": "rare",
		"icon": "fire",
		"icon_asset_id": "arch_r_fire_intensity",
		"description": "Burn deals 25% more damage per tick.",
		"requires_upgrade": "arch_c_fire_attunement",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_ice_depth",
		"name": "Ice Depth",
		"rarity": "rare",
		"icon": "ice",
		"icon_asset_id": "arch_r_ice_depth",
		"description": "Chill lasts longer and slows enemies harder.",
		"requires_upgrade": "arch_c_ice_attunement",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_freeze_spread",
		"name": "Freeze Spread",
		"rarity": "rare",
		"icon": "ice",
		"icon_asset_id": "arch_r_freeze_spread",
		"description": "Ice Blast spreads chill or freeze to nearby enemies.",
		"requires_upgrade": "arch_c_ice_attunement",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_ice_blast",
		"name": "Ice Blast",
		"rarity": "rare",
		"icon": "ice",
		"icon_asset_id": "arch_r_ice_blast",
		"description": "Killing chilled enemies triggers an icy burst on death.",
		"requires_upgrade": "arch_c_ice_attunement",
		"max_stacks": 1,
	},
	{
		"id": "arch_r_lightning_reach",
		"name": "Lightning Reach",
		"rarity": "rare",
		"icon": "lightning",
		"icon_asset_id": "arch_r_lightning_reach",
		"description": "Chain lightning jumps to 2 additional enemies.",
		"requires_upgrade": "arch_c_lightning_attunement",
		"max_stacks": 1,
	},
	{
		"id": "arch_e_arrow_storm",
		"name": "Arrow Storm",
		"rarity": "epic",
		"icon": "arrow_storm",
		"icon_asset_id": "arch_e_arrow_storm",
		"description": "Every 8th primary shot unleashes 6 arrows in a radial storm.",
		"max_stacks": 1,
	},
	{
		"id": "arch_e_explosive_arrow_volley",
		"name": "Explosive Arrow Volley",
		"rarity": "epic",
		"icon": "explosive_volley",
		"icon_asset_id": "arch_e_explosive_arrow_volley",
		"description": "Arrow Volley impacts explode for 60% splash damage in a small radius.",
		"max_stacks": 1,
	},
	{
		"id": "arch_e_storm_volley",
		"name": "Storm Volley",
		"rarity": "epic",
		"icon": "arrow_volley",
		"icon_asset_id": "arch_e_storm_volley",
		"description": "Arrow Volley adds 4 arrows, becoming a tight 7-arrow lane.",
		"max_stacks": 1,
	},
	{
		"id": "arch_e_perfect_predator",
		"name": "Perfect Predator",
		"rarity": "epic",
		"icon": "sentinel_upgrade",
		"icon_asset_id": "arch_e_perfect_predator",
		"description": "Sentinel strikes faster and hit much harder while active.",
		"max_stacks": 1,
	},
	{
		"id": "arch_e_deadeye_bloom",
		"name": "Deadeye Bloom",
		"rarity": "epic",
		"icon": "deadeye_bloom",
		"icon_asset_id": "arch_e_deadeye_bloom",
		"description": "Critical kills release seeking bloom arrows at nearby enemies.",
		"max_stacks": 1,
	},
]

const ARCANE_UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "charged_rounds",
		"name": "Charged Rounds",
		"rarity": "common",
		"icon": "damage",
		"icon_asset_id": "charged_rounds",
		"description": "Arcane Pistol shots hit 20% harder.",
	},
	{
		"id": "quickdraw",
		"name": "Quickdraw",
		"rarity": "common",
		"icon": "attack_speed",
		"icon_asset_id": "quickdraw",
		"description": "Arcane Pistol fires 15% faster.",
	},
	{
		"id": "spellclock",
		"name": "Spellclock",
		"rarity": "common",
		"icon": "missiles",
		"icon_asset_id": "spellclock",
		"description": "Arcane Missiles recover 18% faster.",
	},
	{
		"id": "phase_stride",
		"name": "Phase Stride",
		"rarity": "common",
		"icon": "blink",
		"icon_asset_id": "phase_stride",
		"description": "Move 12% faster and recover blink positioning more cleanly.",
	},
	{
		"id": "satellite_volley",
		"name": "Satellite Volley",
		"rarity": "rare",
		"icon": "missiles",
		"icon_asset_id": "satellite_volley",
		"description": "Arcane Missiles fires one extra missile per cast.",
	},
	{
		"id": "deadeye",
		"name": "Deadeye",
		"rarity": "rare",
		"icon": "sniper",
		"icon_asset_id": "deadeye",
		"description": "Arcane Sniper gains more damage and one additional pierce.",
	},
]

const RARITY_WEIGHTS := {
	"common": 70.0,
	"rare": 25.0,
	"epic": 5.0,
}

const ARCHER_ELEMENT_GROUPS := {
	"fire": ["arch_c_fire_attunement", "arch_r_fire_intensity"],
	"ice": ["arch_c_ice_attunement", "arch_r_ice_depth", "arch_r_freeze_spread", "arch_r_ice_blast"],
	"lightning": ["arch_c_lightning_attunement", "arch_r_lightning_reach"],
}

const ARCHER_ATTUNEMENT_TO_ELEMENT := {
	"arch_c_fire_attunement": "fire",
	"arch_c_ice_attunement": "ice",
	"arch_c_lightning_attunement": "lightning",
}

static func get_choices(level: int, acquired: Dictionary = {}, class_id: String = "", options: Dictionary = {}) -> Array[Dictionary]:
	var resolved_class_id: String = class_id if not class_id.is_empty() else RunConfig.selected_class_id
	var source_pool: Array[Dictionary] = _pool_for_class(resolved_class_id)
	var excluded_ids: Dictionary = {}
	for upgrade_id in options.get("excluded_ids", []):
		excluded_ids[str(upgrade_id)] = true
	var active_element: String = ""
	if resolved_class_id == RunConfig.CLASS_ARCHER:
		active_element = get_archer_active_element(acquired)
	var pool: Array[Dictionary] = []
	for entry in source_pool:
		var entry_id: String = str(entry.get("id", ""))
		if excluded_ids.has(entry_id):
			continue
		var entry_element: String = ""
		var is_attunement: bool = false
		var is_element_followup: bool = false
		if resolved_class_id == RunConfig.CLASS_ARCHER:
			entry_element = get_archer_element_for_upgrade(entry_id)
			is_attunement = is_archer_attunement(entry_id)
			is_element_followup = is_archer_element_followup(entry_id)
			if is_attunement and not active_element.is_empty() and entry_element == active_element:
				continue
			if is_element_followup and not active_element.is_empty() and entry_element != active_element:
				continue
		var required_upgrade: String = str(entry.get("requires_upgrade", ""))
		if not required_upgrade.is_empty() and int(acquired.get(required_upgrade, 0)) <= 0:
			continue
		var max_stacks: int = int(entry.get("max_stacks", 0))
		if max_stacks > 0 and int(acquired.get(entry_id, 0)) >= max_stacks:
			continue
		var resolved_entry: Dictionary = entry.duplicate(true)
		if resolved_class_id == RunConfig.CLASS_ARCHER and is_attunement and not active_element.is_empty():
			resolved_entry["description"] = "%s\nSwitch from %s to %s. This replaces %s attunement upgrades." % [
				str(entry.get("description", "")),
				_element_display_name(active_element),
				_element_display_name(entry_element),
				_element_display_name(active_element),
			]
		pool.append(resolved_entry)
	var choice_count: int = max(1, int(options.get("count", 3)))
	var rarity_weights: Dictionary = _build_rarity_weights(level, options)
	var choices: Array[Dictionary] = []
	var safety: int = 0
	while choices.size() < choice_count and not pool.is_empty() and safety < 30:
		safety += 1
		var picked: Dictionary = _pick_weighted(pool, level, rarity_weights)
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

static func _pick_weighted(pool: Array[Dictionary], level: int, rarity_weights: Dictionary = {}) -> Dictionary:
	var total: float = 0.0
	for entry in pool:
		total += _weight_for(entry, level, rarity_weights)
	if total <= 0.0:
		return {}
	var roll: float = randf() * total
	for entry in pool:
		roll -= _weight_for(entry, level, rarity_weights)
		if roll <= 0.0:
			return entry.duplicate(true)
	return pool[0].duplicate(true)

static func _weight_for(entry: Dictionary, level: int, rarity_weights: Dictionary = {}) -> float:
	var rarity: String = str(entry.get("rarity", "common"))
	var weight: float = float(rarity_weights.get(rarity, RARITY_WEIGHTS.get(rarity, 1.0)))
	if rarity == "rare" and level >= 4:
		weight *= 1.2
	elif rarity == "epic" and level >= 8:
		weight *= 1.15
	return weight

static func _build_rarity_weights(level: int, options: Dictionary) -> Dictionary:
	var weights: Dictionary = RARITY_WEIGHTS.duplicate(true)
	var rarity_bonus: Dictionary = options.get("rarity_bonus", {})
	var rare_bonus: float = clampf(float(rarity_bonus.get("rareBonus", 0.0)), 0.0, 0.20) * 100.0
	var epic_bonus: float = clampf(float(rarity_bonus.get("epicBonus", 0.0)), 0.0, 0.10) * 100.0
	var luck: float = clampf(float(options.get("luck", 0.0)), 0.0, 1.0)
	if luck > 0.0:
		rare_bonus += 6.0 * luck
		epic_bonus += 2.5 * luck
	var common_floor: float = 40.0
	var available_common: float = max(0.0, float(weights.get("common", 0.0)) - common_floor)
	var requested_bonus: float = rare_bonus + epic_bonus
	if requested_bonus > available_common and requested_bonus > 0.0:
		var scale: float = available_common / requested_bonus
		rare_bonus *= scale
		epic_bonus *= scale
	weights["common"] = max(common_floor, float(weights.get("common", 0.0)) - rare_bonus - epic_bonus)
	weights["rare"] = float(weights.get("rare", 0.0)) + rare_bonus
	weights["epic"] = float(weights.get("epic", 0.0)) + epic_bonus
	match str(options.get("min_rarity", "")):
		"rare":
			weights["common"] = 0.0
			if float(weights.get("rare", 0.0)) <= 0.0 and float(weights.get("epic", 0.0)) <= 0.0:
				weights["rare"] = 1.0
		"epic":
			weights["common"] = 0.0
			weights["rare"] = 0.0
			weights["epic"] = max(float(weights.get("epic", 0.0)), 1.0)
	if level >= 10:
		weights["rare"] = float(weights.get("rare", 0.0)) * 1.08
		weights["epic"] = float(weights.get("epic", 0.0)) * 1.12
	return weights

static func _find_by_id(pool: Array[Dictionary], target_id: String) -> int:
	for i in range(pool.size()):
		if str(pool[i].get("id", "")) == target_id:
			return i
	return -1

static func get_archer_active_element(acquired: Dictionary) -> String:
	for upgrade_id in ARCHER_ATTUNEMENT_TO_ELEMENT.keys():
		if int(acquired.get(upgrade_id, 0)) > 0:
			return str(ARCHER_ATTUNEMENT_TO_ELEMENT[upgrade_id])
	return ""

static func is_archer_attunement(upgrade_id: String) -> bool:
	return ARCHER_ATTUNEMENT_TO_ELEMENT.has(upgrade_id)

static func is_archer_element_followup(upgrade_id: String) -> bool:
	if is_archer_attunement(upgrade_id):
		return false
	return not get_archer_element_for_upgrade(upgrade_id).is_empty()

static func get_archer_element_for_upgrade(upgrade_id: String) -> String:
	for element_name in ARCHER_ELEMENT_GROUPS.keys():
		var group: Array = ARCHER_ELEMENT_GROUPS[element_name]
		if group.has(upgrade_id):
			return str(element_name)
	return ""

static func get_archer_upgrade_group_for_element(element_name: String) -> Array[String]:
	var group: Array[String] = []
	var source: Array = ARCHER_ELEMENT_GROUPS.get(element_name, [])
	for upgrade_id in source:
		group.append(str(upgrade_id))
	return group

static func get_upgrade_definition(upgrade_id: String, class_id: String = "") -> Dictionary:
	var resolved_class_id: String = class_id if not class_id.is_empty() else RunConfig.selected_class_id
	var source_pool: Array[Dictionary] = _pool_for_class(resolved_class_id)
	for entry in source_pool:
		if str(entry.get("id", "")) == upgrade_id:
			return entry.duplicate(true)
	return {}

static func _element_display_name(element_name: String) -> String:
	match element_name:
		"fire":
			return "Fire"
		"ice":
			return "Ice"
		"lightning":
			return "Lightning"
		_:
			return "Unknown"
