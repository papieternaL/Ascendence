extends Node

const SAVE_PATH: String = "user://meta_progression.cfg"

const UPGRADE_FORTITUDE: String = "fortitude"
const UPGRADE_MIGHT: String = "might"
const UPGRADE_SWIFTNESS: String = "swiftness"

const UPGRADE_ORDER: Array[String] = [
	UPGRADE_FORTITUDE,
	UPGRADE_MIGHT,
	UPGRADE_SWIFTNESS,
]

const UPGRADE_DEFS: Dictionary = {
	UPGRADE_FORTITUDE: {
		"label": "FORTITUDE",
		"summary": "Permanent +250 max health for future runs.",
		"health_bonus": 250.0,
		"damage_multiplier": 1.0,
		"move_speed_multiplier": 1.0,
	},
	UPGRADE_MIGHT: {
		"label": "MIGHT",
		"summary": "Permanent +10% outgoing damage for future runs.",
		"health_bonus": 0.0,
		"damage_multiplier": 1.10,
		"move_speed_multiplier": 1.0,
	},
	UPGRADE_SWIFTNESS: {
		"label": "SWIFTNESS",
		"summary": "Permanent +8% movement speed for future runs.",
		"health_bonus": 0.0,
		"damage_multiplier": 1.0,
		"move_speed_multiplier": 1.08,
	},
}

var _unlocked_upgrades: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	_unlocked_upgrades.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var unlocked: Array = config.get_value("meta", "unlocked_upgrades", [])
	for entry in unlocked:
		var upgrade_id: String = str(entry)
		if UPGRADE_DEFS.has(upgrade_id):
			_unlocked_upgrades[upgrade_id] = true

func save_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("meta", "unlocked_upgrades", PackedStringArray(_unlocked_upgrades.keys()))
	config.save(SAVE_PATH)

func is_upgrade_unlocked(id: String) -> bool:
	return bool(_unlocked_upgrades.get(id, false))

func unlock_upgrade(id: String) -> bool:
	if not UPGRADE_DEFS.has(id):
		return false
	if is_upgrade_unlocked(id):
		return false
	_unlocked_upgrades[id] = true
	save_data()
	return true

func get_run_modifiers() -> Dictionary:
	var modifiers: Dictionary = {
		"health_bonus": 0.0,
		"damage_multiplier": 1.0,
		"move_speed_multiplier": 1.0,
	}
	for upgrade_id in UPGRADE_ORDER:
		if not is_upgrade_unlocked(upgrade_id):
			continue
		var data: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
		modifiers["health_bonus"] = float(modifiers.get("health_bonus", 0.0)) + float(data.get("health_bonus", 0.0))
		modifiers["damage_multiplier"] = float(modifiers.get("damage_multiplier", 1.0)) * float(data.get("damage_multiplier", 1.0))
		modifiers["move_speed_multiplier"] = float(modifiers.get("move_speed_multiplier", 1.0)) * float(data.get("move_speed_multiplier", 1.0))
	return modifiers

func uses_unlimited_test_points() -> bool:
	return true
