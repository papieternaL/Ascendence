class_name InputBindings
extends RefCounted

const ACTION_DEFS: Array[Dictionary] = [
	{
		"action": "move_up",
		"label": "Move Up",
		"description": "Move the character upward.",
		"deadzone": 0.2,
		"default": [{"type": "key", "keycode": KEY_W}],
	},
	{
		"action": "move_left",
		"label": "Move Left",
		"description": "Move the character left.",
		"deadzone": 0.2,
		"default": [{"type": "key", "keycode": KEY_A}],
	},
	{
		"action": "move_down",
		"label": "Move Down",
		"description": "Move the character down.",
		"deadzone": 0.2,
		"default": [{"type": "key", "keycode": KEY_S}],
	},
	{
		"action": "move_right",
		"label": "Move Right",
		"description": "Move the character right.",
		"deadzone": 0.2,
		"default": [{"type": "key", "keycode": KEY_D}],
	},
	{
		"action": "primary_fire",
		"label": "Primary Attack",
		"description": "Basic attack / fire weapon.",
		"deadzone": 0.5,
		"default": [{"type": "mouse_button", "button_index": MOUSE_BUTTON_LEFT}],
	},
	{
		"action": "ability_1",
		"label": "Ability 1",
		"description": "Primary active ability (manual aim).",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_SHIFT}],
	},
	{
		"action": "ability_2",
		"label": "Ability 2",
		"description": "Secondary active ability.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_E}],
	},
	{
		"action": "dash",
		"label": "Dash / Blink",
		"description": "Mobility ability.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_SPACE}],
	},
	{
		"action": "ultimate",
		"label": "Ultimate",
		"description": "Ultimate or charge ability.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_R}],
	},
	{
		"action": "interact",
		"label": "Interact",
		"description": "Talk, inspect, or activate world objects.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_F}],
	},
	{
		"action": "run_profile",
		"label": "Run Profile",
		"description": "Open the current run profile.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_TAB}],
	},
	{
		"action": "inventory",
		"label": "Inventory",
		"description": "Open the town inventory and potion pouch.",
		"deadzone": 0.5,
		"default": [{"type": "key", "keycode": KEY_B}],
	},
]

static func ensure_actions_exist() -> void:
	remove_legacy_actions()
	for action_def in ACTION_DEFS:
		var action_name: String = str(action_def.get("action", ""))
		if action_name.is_empty():
			continue
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, float(action_def.get("deadzone", 0.5)))
		if InputMap.action_get_events(action_name).is_empty():
			reset_action_to_default(action_name)

static func get_bindable_action_defs() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	for action_def in ACTION_DEFS:
		defs.append(action_def.duplicate(true))
	return defs

static func remove_legacy_actions() -> void:
	if InputMap.has_action("move_command"):
		InputMap.erase_action("move_command")

static func get_action_def(action_name: String) -> Dictionary:
	for action_def in ACTION_DEFS:
		if str(action_def.get("action", "")) == action_name:
			return action_def
	return {}

static func get_action_label(action_name: String) -> String:
	var action_def: Dictionary = get_action_def(action_name)
	return str(action_def.get("label", action_name.replace("_", " ").capitalize()))

static func reset_to_defaults() -> void:
	for action_def in ACTION_DEFS:
		reset_action_to_default(str(action_def.get("action", "")))

static func reset_action_to_default(action_name: String) -> void:
	var action_def: Dictionary = get_action_def(action_name)
	if action_def.is_empty():
		return
	var events: Array = []
	for event_data in action_def.get("default", []):
		var event: InputEvent = deserialize_event(event_data)
		if event != null:
			events.append(event)
	replace_action_events(action_name, events)

static func replace_action_events(action_name: String, events: Array) -> void:
	if not InputMap.has_action(action_name):
		var action_def: Dictionary = get_action_def(action_name)
		InputMap.add_action(action_name, float(action_def.get("deadzone", 0.5)))
	InputMap.action_erase_events(action_name)
	for event_variant in events:
		var event: InputEvent = event_variant as InputEvent
		if event != null:
			InputMap.action_add_event(action_name, event)

static func serialize_bindings() -> Dictionary:
	var serialized: Dictionary = {}
	for action_def in ACTION_DEFS:
		var action_name: String = str(action_def.get("action", ""))
		var events: Array = []
		for event in InputMap.action_get_events(action_name):
			var event_data: Dictionary = serialize_event(event)
			if not event_data.is_empty():
				events.append(event_data)
		serialized[action_name] = events
	return serialized

static func apply_serialized_bindings(serialized_bindings: Dictionary) -> bool:
	ensure_actions_exist()
	var repaired_defaults: bool = false
	for action_def in ACTION_DEFS:
		var action_name: String = str(action_def.get("action", ""))
		if not serialized_bindings.has(action_name):
			continue
		var next_events: Array = []
		for event_data in serialized_bindings.get(action_name, []):
			var event: InputEvent = deserialize_event(event_data)
			if event != null:
				next_events.append(event)
		if next_events.is_empty():
			reset_action_to_default(action_name)
			repaired_defaults = true
			continue
		replace_action_events(action_name, next_events)
	return repaired_defaults

static func ensure_required_actions_bound(action_names: Array[String]) -> bool:
	ensure_actions_exist()
	var repaired_defaults: bool = false
	for action_name in action_names:
		if action_name.is_empty():
			continue
		if not InputMap.has_action(action_name) or InputMap.action_get_events(action_name).is_empty():
			reset_action_to_default(action_name)
			repaired_defaults = true
	return repaired_defaults

static func capture_supported_event(event: InputEvent) -> InputEvent:
	if event == null:
		return null
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return null
		var clean_key: InputEventKey = InputEventKey.new()
		clean_key.keycode = key_event.keycode
		clean_key.physical_keycode = key_event.physical_keycode
		clean_key.key_label = key_event.key_label
		clean_key.shift_pressed = key_event.shift_pressed
		clean_key.alt_pressed = key_event.alt_pressed
		clean_key.ctrl_pressed = key_event.ctrl_pressed
		clean_key.meta_pressed = key_event.meta_pressed
		clean_key.location = key_event.location
		clean_key.unicode = 0
		clean_key.pressed = false
		clean_key.echo = false
		return clean_key
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return null
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP \
		or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
		or mouse_event.button_index == MOUSE_BUTTON_WHEEL_LEFT \
		or mouse_event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			return null
		var clean_mouse: InputEventMouseButton = InputEventMouseButton.new()
		clean_mouse.button_index = mouse_event.button_index
		clean_mouse.pressed = false
		clean_mouse.double_click = false
		return clean_mouse
	return null

static func rebind_action_unique(action_name: String, next_event: InputEvent) -> void:
	var clean_event: InputEvent = capture_supported_event(next_event)
	if clean_event == null:
		return
	ensure_actions_exist()
	for action_def in ACTION_DEFS:
		var other_action: String = str(action_def.get("action", ""))
		if other_action == action_name:
			continue
		var remaining_events: Array = []
		for event in InputMap.action_get_events(other_action):
			if not events_match(event, clean_event):
				remaining_events.append(event)
		replace_action_events(other_action, remaining_events)
	replace_action_events(action_name, [clean_event])

static func get_action_display_label(action_name: String) -> String:
	var primary_event: InputEvent = get_primary_event(action_name)
	return event_to_label(primary_event)

static func get_primary_event(action_name: String) -> InputEvent:
	if not InputMap.has_action(action_name):
		return null
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	return events[0] if not events.is_empty() else null

static func serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return {
			"type": "key",
			"keycode": key_event.keycode,
			"physical_keycode": key_event.physical_keycode,
			"key_label": key_event.key_label,
			"shift": key_event.shift_pressed,
			"alt": key_event.alt_pressed,
			"ctrl": key_event.ctrl_pressed,
			"meta": key_event.meta_pressed,
			"location": key_event.location,
		}
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		return {
			"type": "mouse_button",
			"button_index": mouse_event.button_index,
		}
	return {}

static func deserialize_event(data: Variant) -> InputEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var event_data: Dictionary = data as Dictionary
	match str(event_data.get("type", "")):
		"key":
			var key_event: InputEventKey = InputEventKey.new()
			key_event.keycode = int(event_data.get("keycode", 0))
			key_event.physical_keycode = int(event_data.get("physical_keycode", 0))
			key_event.key_label = int(event_data.get("key_label", 0))
			key_event.shift_pressed = bool(event_data.get("shift", false))
			key_event.alt_pressed = bool(event_data.get("alt", false))
			key_event.ctrl_pressed = bool(event_data.get("ctrl", false))
			key_event.meta_pressed = bool(event_data.get("meta", false))
			key_event.location = int(event_data.get("location", 0))
			key_event.pressed = false
			return key_event
		"mouse_button":
			var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
			mouse_event.button_index = int(event_data.get("button_index", 0))
			mouse_event.pressed = false
			return mouse_event
		_:
			return null

static func event_to_label(event: InputEvent) -> String:
	if event == null:
		return "UNBOUND"
	if event is InputEventMouseButton:
		var button_index: int = int((event as InputEventMouseButton).button_index)
		match button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MOUSE_BUTTON_XBUTTON1:
				return "MB4"
			MOUSE_BUTTON_XBUTTON2:
				return "MB5"
			_:
				return "MOUSE %d" % button_index
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		var code: int = key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
		if code == KEY_SPACE:
			return "SPACE"
		var label: String = OS.get_keycode_string(code).strip_edges()
		if label.is_empty():
			return "KEY"
		return label.to_upper()
	return "UNBOUND"

static func events_match(a: InputEvent, b: InputEvent) -> bool:
	if a == null or b == null:
		return false
	if a.get_class() != b.get_class():
		return false
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return int((a as InputEventMouseButton).button_index) == int((b as InputEventMouseButton).button_index)
	if a is InputEventKey and b is InputEventKey:
		var a_key: InputEventKey = a as InputEventKey
		var b_key: InputEventKey = b as InputEventKey
		return a_key.keycode == b_key.keycode \
			and a_key.physical_keycode == b_key.physical_keycode \
			and a_key.shift_pressed == b_key.shift_pressed \
			and a_key.alt_pressed == b_key.alt_pressed \
			and a_key.ctrl_pressed == b_key.ctrl_pressed \
			and a_key.meta_pressed == b_key.meta_pressed
	return false
