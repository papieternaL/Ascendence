class_name CastTargeting
extends RefCounted

const CLASS_ARCHER: String = "archer"
const CLASS_ARCANE_PISTOL: String = "arcane_pistol"

const MODE_QUICK_CAST: String = "quick_cast"
const MODE_QUICK_CAST_INDICATOR: String = "quick_cast_indicator"
const MODE_RANGE_INDICATOR: String = "range_indicator"

const _ARCHER_DIRECTIONAL_ACTIONS: Array[String] = [
	"primary_fire",
	"ability_1",
	"ability_2",
	"dash",
]

const _ARCANE_DIRECTIONAL_ACTIONS: Array[String] = [
	"primary_fire",
	"ability_1",
	"ability_2",
	"dash",
]

const _PREVIEW_LIBRARY: Dictionary = {
	CLASS_ARCHER: {
		"primary_fire": {
			"targeting_type": "directional",
			"preview_kind": "line",
			"length_key": "primary_range",
			"default_length": 350.0,
			"width": 2.2,
			"color": Color(1.0, 0.88, 0.52, 0.8),
		},
		"ability_1": {
			"targeting_type": "directional",
			"preview_kind": "line",
			"length_key": "power_shot_range",
			"default_length": 440.0,
			"width": 3.0,
			"color": Color(1.0, 0.78, 0.32, 0.9),
		},
		"ability_2": {
			"targeting_type": "directional",
			"preview_kind": "cone",
			"length_key": "volley_length",
			"default_length": 220.0,
			"spread_key": "volley_spread_degrees",
			"default_spread": 26.0,
			"color": Color(1.0, 0.82, 0.42, 0.78),
		},
		"dash": {
			"targeting_type": "directional",
			"preview_kind": "dash",
			"length_key": "dash_length",
			"default_length": 170.0,
			"color": Color(0.74, 0.92, 1.0, 0.82),
		},
	},
	CLASS_ARCANE_PISTOL: {
		"primary_fire": {
			"targeting_type": "directional",
			"preview_kind": "line",
			"length_key": "primary_range",
			"default_length": 520.0,
			"width": 2.2,
			"color": Color(0.68, 0.96, 1.0, 0.82),
		},
		"ability_1": {
			"targeting_type": "directional",
			"preview_kind": "fan",
			"length_key": "missile_length",
			"default_length": 210.0,
			"count_key": "missile_count",
			"default_count": 3,
			"spread_key": "missile_spread_degrees",
			"default_spread": 12.0,
			"color": Color(0.76, 0.62, 1.0, 0.78),
			"highlight_key": "highlight_global_position",
		},
		"ability_2": {
			"targeting_type": "directional",
			"preview_kind": "lob_line",
			"length_key": "bomb_length",
			"default_length": 220.0,
			"radius_key": "bomb_radius",
			"default_radius": 76.0,
			"color": Color(0.82, 0.42, 1.0, 0.82),
		},
		"dash": {
			"targeting_type": "directional",
			"preview_kind": "dash",
			"length_key": "dash_length",
			"default_length": 170.0,
			"color": Color(0.76, 0.96, 1.0, 0.84),
		},
	},
}

static func normalize_cast_mode(value: String) -> String:
	match value:
		MODE_QUICK_CAST_INDICATOR, MODE_RANGE_INDICATOR:
			return value
		"hold_release":
			return MODE_QUICK_CAST_INDICATOR
		_:
			return MODE_QUICK_CAST

static func uses_indicator_release_mode(value: String) -> bool:
	return normalize_cast_mode(value) != MODE_QUICK_CAST

static func uses_ground_targeting_layer(value: String) -> bool:
	return normalize_cast_mode(value) == MODE_RANGE_INDICATOR

static func get_directional_actions(class_id: String) -> Array[String]:
	match class_id:
		CLASS_ARCANE_PISTOL:
			return _ARCANE_DIRECTIONAL_ACTIONS.duplicate()
		_:
			return _ARCHER_DIRECTIONAL_ACTIONS.duplicate()

static func build_preview(class_id: String, action_name: String, context: Dictionary = {}) -> Dictionary:
	var class_library: Dictionary = _PREVIEW_LIBRARY.get(class_id, {}) as Dictionary
	var preview_def: Dictionary = class_library.get(action_name, {}) as Dictionary
	if preview_def.is_empty():
		return {}
	var preview: Dictionary = {
		"targeting_type": str(preview_def.get("targeting_type", "directional")),
		"kind": str(preview_def.get("preview_kind", "")),
		"direction": Vector2(context.get("direction", Vector2.RIGHT)),
		"color": preview_def.get("color", Color(0.74, 0.92, 1.0, 0.78)),
	}
	if preview_def.has("length_key"):
		var length_key: String = str(preview_def.get("length_key", ""))
		preview["length"] = float(context.get(length_key, preview_def.get("default_length", 180.0)))
	if preview_def.has("width"):
		preview["width"] = float(preview_def.get("width", 2.2))
	if preview_def.has("spread_key"):
		var spread_key: String = str(preview_def.get("spread_key", ""))
		preview["spread_degrees"] = float(context.get(spread_key, preview_def.get("default_spread", 18.0)))
	if preview_def.has("count_key"):
		var count_key: String = str(preview_def.get("count_key", ""))
		preview["count"] = int(context.get(count_key, preview_def.get("default_count", 1)))
	if preview_def.has("radius_key"):
		var radius_key: String = str(preview_def.get("radius_key", ""))
		preview["radius"] = float(context.get(radius_key, preview_def.get("default_radius", 72.0)))
	if preview_def.has("highlight_key"):
		var highlight_key: String = str(preview_def.get("highlight_key", ""))
		if context.has(highlight_key):
			preview["highlight_global_position"] = context.get(highlight_key)
	return preview

static func make_ground_preview(preview_kind: String, ground_position: Vector2, radius: float, color: Color, extra: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = extra.duplicate(true)
	preview["targeting_type"] = "ground"
	preview["kind"] = preview_kind
	preview["ground_position"] = ground_position
	preview["radius"] = radius
	preview["color"] = color
	return preview

static func process_indicator_release_input(
	player: Node,
	pending_action: String,
	action_names: Array[String],
	can_prepare: Callable,
	build_preview_callable: Callable,
	execute_callable: Callable
) -> String:
	if Input.is_action_just_pressed("ui_cancel"):
		clear_player_preview(player)
		return ""
	for action_name in action_names:
		if Input.is_action_just_pressed(action_name) and bool(can_prepare.call(action_name)):
			pending_action = action_name
			break
	if pending_action.is_empty():
		clear_player_preview(player)
		return ""
	var preview_data: Dictionary = build_preview_callable.call(pending_action)
	set_player_preview(player, preview_data)
	if Input.is_action_just_released(pending_action):
		var action_to_execute: String = pending_action
		clear_player_preview(player)
		pending_action = ""
		execute_callable.call(action_to_execute)
	return pending_action

static func clear_player_preview(player: Node) -> void:
	if player != null and is_instance_valid(player) and player.has_method("clear_cast_preview"):
		player.call("clear_cast_preview")

static func set_player_preview(player: Node, preview: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or not player.has_method("set_cast_preview"):
		return
	if preview.is_empty():
		clear_player_preview(player)
		return
	player.call("set_cast_preview", preview)
