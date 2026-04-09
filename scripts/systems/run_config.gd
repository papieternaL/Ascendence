extends Node

const CLASS_ARCHER: String = "archer"
const CLASS_ARCANE_PISTOL: String = "arcane_pistol"

const MAP_DEEPWOOD: String = "deepwood"
const MAP_BOSS_SANCTUM: String = "boss_sanctum"

var selected_class_id: String = CLASS_ARCHER
var selected_map_id: String = MAP_DEEPWOOD
var tutorial_requested: bool = false
var boss_test_requested: bool = false

func reset_for_frontend() -> void:
	tutorial_requested = false
	boss_test_requested = false

func _binding_label(action_name: String) -> String:
	return GameSettings.get_binding_label(action_name)

func get_class_data() -> Array[Dictionary]:
	return [
		{
			"id": CLASS_ARCHER,
			"name": "ARCHER",
			"status": "WEAPON LOADOUT",
			"description": "A fast ranged bow loadout built around cursor-aimed pressure, burst follow-ups, and clean repositioning on the shared Deepwood route.",
			"abilities": [
				{
					"action": "primary_fire",
					"key": _binding_label("primary_fire"),
					"targeting_type": "directional",
					"preview_kind": "line",
					"name": "Hunter's Bow",
					"icon": "bow",
					"icon_asset_id": "archer_hunters_bow",
					"summary": "Manual bow shots aimed with the cursor.",
					"detail": "Hunter's Bow fires wherever you aim the cursor. Crit and pierce scaling still define most of the baseline damage curve, but you decide when and where each shot goes.",
				},
				{
					"action": "ability_1",
					"key": _binding_label("ability_1"),
					"targeting_type": "directional",
					"preview_kind": "line",
					"name": "Power Shot",
					"icon": "power_shot",
					"icon_asset_id": "archer_power_shot",
					"summary": "Heavy piercing arrow toward the cursor.",
					"detail": "Power Shot fires a harder-hitting piercing arrow with guaranteed critical behavior. It is the deliberate burst tool for boss punish windows and lane picks.",
				},
				{
					"action": "dash",
					"key": _binding_label("dash"),
					"targeting_type": "directional",
					"preview_kind": "dash",
					"name": "Dash",
					"icon": "dash",
					"icon_asset_id": "archer_dash",
					"summary": "Manual repositioning tool aimed with the cursor.",
					"detail": "Dash is the skill-expression button. Aim it with the cursor to cut angles, escape roots, and preserve spacing during boss mechanics.",
				},
				{
					"action": "ability_2",
					"key": _binding_label("ability_2"),
					"targeting_type": "directional",
					"preview_kind": "cone",
					"name": "Arrow Volley",
					"icon": "arrow_volley",
					"icon_asset_id": "archer_arrow_volley",
					"summary": "Manual cone volley toward the cursor.",
					"detail": "Arrow Volley fires a tight 3-arrow lane in the aimed direction. It replaces the old Entangle slot and keeps Archer purely ranged.",
				},
				{
					"action": "ultimate",
					"key": _binding_label("ultimate"),
					"targeting_type": "instant",
					"preview_kind": "",
					"name": "Sentinel",
					"icon": "sentinel",
					"icon_asset_id": "archer_sentinel",
					"summary": "Charge-based hawk summon that hunts nearby enemies for a short window.",
					"detail": "Sentinel summons an autonomous hawk that tracks and strikes nearby enemies, cores, and roots while the active window lasts.",
				},
			],
		},
		{
			"id": CLASS_ARCANE_PISTOL,
			"name": "ARCANE PISTOL",
			"status": "WEAPON LOADOUT",
			"description": "A magical gunslinger loadout focused on cursor-aimed shots, missile bursts, bomb control, and precision sniper windows on the same Deepwood route.",
			"abilities": [
				{
					"action": "primary_fire",
					"key": _binding_label("primary_fire"),
					"targeting_type": "directional",
					"preview_kind": "line",
					"name": "Arcane Pistol",
					"icon": "pistol",
					"icon_asset_id": "arcane_pistol_primary",
					"summary": "Precise ranged shots aimed with the cursor.",
					"detail": "Arcane Pistol fires magical bullets in a fast, readable ranged cadence. Arcane Sniper upgrades that same manual aim loop instead of replacing it.",
				},
				{
					"action": "ability_1",
					"key": _binding_label("ability_1"),
					"targeting_type": "directional",
					"preview_kind": "fan",
					"name": "Arcane Missiles",
					"icon": "missiles",
					"icon_asset_id": "arcane_missiles",
					"summary": "Single-target volley that locks one enemy on cast.",
					"detail": "Arcane Missiles locks onto one enemy near the cursor, then fires the full missile volley into that target. If the cursor is not near an enemy, it falls back to your current soft-lock or nearest foe.",
				},
				{
					"action": "ability_2",
					"key": _binding_label("ability_2"),
					"targeting_type": "directional",
					"preview_kind": "lob_line",
					"name": "Arcane Bomb",
					"icon": "arcane",
					"icon_asset_id": "arcane_bomb",
					"summary": "Lob a glowing bomb forward to create a slowing damage field.",
					"detail": "Arcane Bomb throws a volatile arcane charge in the aimed direction. On impact it blooms into a purple zone that pulses damage and lightly slows enemies standing inside it.",
				},
				{
					"action": "dash",
					"key": _binding_label("dash"),
					"targeting_type": "directional",
					"preview_kind": "dash",
					"name": "Arcane Blink",
					"icon": "blink",
					"icon_asset_id": "arcane_blink",
					"summary": "Instant repositioning step.",
					"detail": "Blink keeps the gunslinger evasive without becoming a melee class. It preserves the fast ranged identity already prototyped in Godot.",
				},
				{
					"action": "ultimate",
					"key": _binding_label("ultimate"),
					"targeting_type": "instant",
					"preview_kind": "",
					"name": "Arcane Sniper",
					"icon": "sniper",
					"icon_asset_id": "arcane_sniper",
					"summary": "Timed transformation into a heavy piercing sniper weapon.",
					"detail": "Arcane Sniper replaces base shots with slower, harder-hitting, piercing rounds for a short window. The full runtime is preserved for future class rollout.",
				},
			],
		},
	]

func get_map_data() -> Array[Dictionary]:
	return [
		{
			"id": MAP_DEEPWOOD,
			"name": "DEEPWOOD",
			"status": "PLAYABLE",
			"available": true,
			"description": "The first forest slice. Fight through waves, destroy the cores, then step into the boss portal.",
			"boss": "Treent Overlord",
			"flow": "Waves -> Major progress -> Cores -> Portal -> Boss",
			"detail": "Deepwood is the active biome. It is where Archer progression, objectives, and the Treent boss are being finalized for the live 2D run flow.",
		},
		{
			"id": MAP_BOSS_SANCTUM,
			"name": "BOSS SANCTUM",
			"status": "COMING LATER",
			"available": false,
			"description": "A dedicated future run focused on chained boss execution.",
			"boss": "TBD",
			"flow": "Locked",
			"detail": "This page exists so the frontend flow is not hardcoded to a single biome. It stays locked until the forest slice is stable.",
		},
	]

func get_main_scene_for_selection() -> String:
	return "res://scenes/main/Main.tscn"
