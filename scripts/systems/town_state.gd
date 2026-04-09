extends Node

const SAVE_PATH: String = "user://town_state.cfg"
const STARTING_COINS: int = 100

const ITEM_HP_POTION: String = "hp_potion"
const QUEST_KILL_TREENT_OVERLORD: String = "kill_treent_overlord"

const ITEM_DEFS: Dictionary = {
	ITEM_HP_POTION: {
		"id": ITEM_HP_POTION,
		"label": "HP Potion",
		"price": 25,
		"description": "Restores 250 HP when used. Press 1 during a run to drink.",
		"stackable": true,
		"heal_amount": 250.0,
	},
}

const QUEST_ORDER: Array[String] = [
	QUEST_KILL_TREENT_OVERLORD,
]

const QUEST_DEFS: Dictionary = {
	QUEST_KILL_TREENT_OVERLORD: {
		"id": QUEST_KILL_TREENT_OVERLORD,
		"title": "Kill the Treent Overlord",
		"location": "Deepwood",
		"status": "In Progress",
		"description": "Defeat the Treent Overlord at the end of the Deepwood route.",
	},
}

const HOTBAR_SLOTS: int = 4
const INVENTORY_SLOTS: int = 16

var _coins: int = STARTING_COINS
var _inventory_counts: Dictionary = {}
var _inventory_layout: Array[String] = []
var _active_quest_id: String = QUEST_KILL_TREENT_OVERLORD
var _hotbar: Array[String] = ["hp_potion", "", "", ""]

func _ready() -> void:
	load_data()

func load_data() -> void:
	_coins = STARTING_COINS
	_inventory_counts.clear()
	_inventory_layout.clear()
	_active_quest_id = QUEST_KILL_TREENT_OVERLORD
	_hotbar = [ITEM_HP_POTION, "", "", ""]
	if not FileAccess.file_exists(SAVE_PATH):
		_sync_inventory_layout_with_counts()
		save_data()
		return
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		_sync_inventory_layout_with_counts()
		save_data()
		return
	_coins = maxi(0, int(config.get_value("town", "coins", STARTING_COINS)))
	var saved_counts: Variant = config.get_value("town", "inventory_counts", {})
	if saved_counts is Dictionary:
		for key in saved_counts.keys():
			var item_id: String = str(key)
			if not ITEM_DEFS.has(item_id):
				continue
			_inventory_counts[item_id] = maxi(0, int(saved_counts[key]))
	var saved_active_quest: String = str(config.get_value("town", "active_quest_id", _active_quest_id))
	if QUEST_DEFS.has(saved_active_quest):
		_active_quest_id = saved_active_quest
	elif not QUEST_ORDER.is_empty():
		_active_quest_id = QUEST_ORDER[0]
	var saved_layout: Variant = config.get_value("town", "inventory_layout", [])
	if saved_layout is Array:
		for i in range(mini(saved_layout.size(), INVENTORY_SLOTS)):
			_inventory_layout.append(str(saved_layout[i]))
	var saved_hotbar: Variant = config.get_value("town", "hotbar", [])
	if saved_hotbar is Array:
		for i in range(mini(saved_hotbar.size(), HOTBAR_SLOTS)):
			_hotbar[i] = str(saved_hotbar[i])
	_ensure_hotbar_size()
	_sync_inventory_layout_with_counts()

func save_data() -> void:
	_sync_inventory_layout_with_counts()
	var config: ConfigFile = ConfigFile.new()
	config.set_value("town", "coins", _coins)
	config.set_value("town", "inventory_counts", _inventory_counts.duplicate(true))
	config.set_value("town", "inventory_layout", Array(_inventory_layout))
	config.set_value("town", "active_quest_id", _active_quest_id)
	config.set_value("town", "hotbar", Array(_hotbar))
	config.save(SAVE_PATH)

func get_coin_balance() -> int:
	return _coins

func add_coins(amount: int) -> void:
	if amount == 0:
		return
	_coins = maxi(0, _coins + amount)
	save_data()

func can_afford(cost: int) -> bool:
	return _coins >= maxi(0, cost)

func purchase_item(item_id: String) -> bool:
	var item_data: Dictionary = ITEM_DEFS.get(item_id, {})
	if item_data.is_empty():
		return false
	var cost: int = int(item_data.get("price", 0))
	if not can_afford(cost):
		return false
	_coins -= cost
	_inventory_counts[item_id] = get_item_count(item_id) + 1
	_sync_inventory_layout_with_counts()
	save_data()
	return true

func consume_item(item_id: String) -> bool:
	var count: int = get_item_count(item_id)
	if count <= 0:
		return false
	_inventory_counts[item_id] = count - 1
	_sync_inventory_layout_with_counts()
	save_data()
	return true

func get_item_count(item_id: String) -> int:
	return maxi(0, int(_inventory_counts.get(item_id, 0)))

func get_available_quests() -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	for quest_id in QUEST_ORDER:
		var quest_data: Dictionary = QUEST_DEFS.get(quest_id, {})
		if quest_data.is_empty():
			continue
		var quest_copy: Dictionary = quest_data.duplicate(true)
		if quest_id == _active_quest_id:
			quest_copy["status"] = "In Progress"
		quests.append(quest_copy)
	return quests

func get_active_quest() -> Dictionary:
	if QUEST_DEFS.has(_active_quest_id):
		var quest_data: Dictionary = QUEST_DEFS[_active_quest_id].duplicate(true)
		quest_data["status"] = "In Progress"
		return quest_data
	if QUEST_ORDER.is_empty():
		return {}
	_active_quest_id = QUEST_ORDER[0]
	save_data()
	return get_active_quest()

func set_active_quest(quest_id: String) -> void:
	if not QUEST_DEFS.has(quest_id):
		return
	_active_quest_id = quest_id
	save_data()

func get_hotbar_item(slot: int) -> String:
	if slot < 0 or slot >= HOTBAR_SLOTS:
		return ""
	return _hotbar[slot]

func set_hotbar_item(slot: int, item_id: String) -> void:
	if slot < 0 or slot >= HOTBAR_SLOTS:
		return
	if not item_id.is_empty() and not ITEM_DEFS.has(item_id):
		return
	_hotbar[slot] = item_id
	save_data()

func get_hotbar() -> Array[String]:
	_ensure_hotbar_size()
	return _hotbar.duplicate()

func get_inventory_item(slot: int) -> String:
	_sync_inventory_layout_with_counts()
	if slot < 0 or slot >= INVENTORY_SLOTS:
		return ""
	return _inventory_layout[slot]

func get_inventory_layout() -> Array[String]:
	_sync_inventory_layout_with_counts()
	return _inventory_layout.duplicate()

func swap_inventory_slots(first_slot: int, second_slot: int) -> bool:
	_sync_inventory_layout_with_counts()
	if not _is_valid_inventory_slot(first_slot) or not _is_valid_inventory_slot(second_slot):
		return false
	if first_slot == second_slot:
		return false
	var first_item: String = _inventory_layout[first_slot]
	var second_item: String = _inventory_layout[second_slot]
	if first_item.is_empty() and second_item.is_empty():
		return false
	_inventory_layout[first_slot] = second_item
	_inventory_layout[second_slot] = first_item
	save_data()
	return true

func swap_hotbar_slots(first_slot: int, second_slot: int) -> bool:
	_ensure_hotbar_size()
	if not _is_valid_hotbar_slot(first_slot) or not _is_valid_hotbar_slot(second_slot):
		return false
	if first_slot == second_slot:
		return false
	var first_item: String = _hotbar[first_slot]
	var second_item: String = _hotbar[second_slot]
	if first_item.is_empty() and second_item.is_empty():
		return false
	_hotbar[first_slot] = second_item
	_hotbar[second_slot] = first_item
	save_data()
	return true

func swap_inventory_and_hotbar(inventory_slot: int, hotbar_slot: int) -> bool:
	_sync_inventory_layout_with_counts()
	_ensure_hotbar_size()
	if not _is_valid_inventory_slot(inventory_slot) or not _is_valid_hotbar_slot(hotbar_slot):
		return false
	var inventory_item: String = _inventory_layout[inventory_slot]
	var hotbar_item: String = _hotbar[hotbar_slot]
	if inventory_item.is_empty() and hotbar_item.is_empty():
		return false
	_inventory_layout[inventory_slot] = hotbar_item
	_hotbar[hotbar_slot] = inventory_item
	save_data()
	return true

func use_hotbar_item(slot: int) -> Dictionary:
	var item_id: String = get_hotbar_item(slot)
	if item_id.is_empty():
		return {}
	var count: int = get_item_count(item_id)
	if count <= 0:
		return {}
	if not consume_item(item_id):
		return {}
	return ITEM_DEFS.get(item_id, {})

func get_inventory_entries() -> Array[Dictionary]:
	_sync_inventory_layout_with_counts()
	var entries: Array[Dictionary] = []
	for item_id in ITEM_DEFS.keys():
		var item_data: Dictionary = ITEM_DEFS[item_id].duplicate(true)
		item_data["count"] = get_item_count(item_id)
		entries.append(item_data)
	return entries

func _is_valid_inventory_slot(slot: int) -> bool:
	return slot >= 0 and slot < INVENTORY_SLOTS

func _is_valid_hotbar_slot(slot: int) -> bool:
	return slot >= 0 and slot < HOTBAR_SLOTS

func _ensure_hotbar_size() -> void:
	if _hotbar.size() > HOTBAR_SLOTS:
		_hotbar.resize(HOTBAR_SLOTS)
	while _hotbar.size() < HOTBAR_SLOTS:
		_hotbar.append("")

func _ensure_inventory_layout_size() -> void:
	if _inventory_layout.size() > INVENTORY_SLOTS:
		_inventory_layout.resize(INVENTORY_SLOTS)
	while _inventory_layout.size() < INVENTORY_SLOTS:
		_inventory_layout.append("")

func _first_empty_inventory_slot() -> int:
	for i in range(_inventory_layout.size()):
		if _inventory_layout[i].is_empty():
			return i
	return -1

func _sync_inventory_layout_with_counts() -> void:
	_ensure_inventory_layout_size()
	var seen: Dictionary = {}
	for i in range(_inventory_layout.size()):
		var item_id: String = str(_inventory_layout[i])
		if item_id.is_empty():
			_inventory_layout[i] = ""
			continue
		if not ITEM_DEFS.has(item_id) or get_item_count(item_id) <= 0 or seen.has(item_id):
			_inventory_layout[i] = ""
			continue
		seen[item_id] = true
	for item_id in ITEM_DEFS.keys():
		if get_item_count(item_id) <= 0 or seen.has(item_id):
			continue
		var empty_slot: int = _first_empty_inventory_slot()
		if empty_slot == -1:
			break
		_inventory_layout[empty_slot] = item_id
		seen[item_id] = true
