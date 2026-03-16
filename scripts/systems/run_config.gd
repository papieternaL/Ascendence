extends Node

const CLASS_ARCHER: String = "archer"
const CLASS_ARCANE_PISTOL: String = "arcane_pistol"

const MAP_DEEPWOOD: String = "deepwood"
const MAP_BOSS_SANCTUM: String = "boss_sanctum"

var selected_class_id: String = CLASS_ARCHER
var selected_map_id: String = MAP_DEEPWOOD
var tutorial_requested: bool = false

func reset_for_frontend() -> void:
	tutorial_requested = false

func get_class_data() -> Array[Dictionary]:
	return [
		{
			"id": CLASS_ARCHER,
			"name": "ARCHER",
			"status": "ACTIVE PARITY TARGET",
			"description": "Nearest-lock auto-fire archer with fast execution and real Love2D kit parity.",
			"abilities": [
				{
					"key": "PRIMARY",
					"name": "Hunter's Bow",
					"icon": "power_shot",
					"summary": "Auto-fire arrows at the nearest valid target in range.",
					"detail": "Your primary attack automatically looses arrows at the nearest enemy or objective in range. Crit and pierce scaling define most of the baseline damage curve.",
				},
				{
					"key": "Q",
					"name": "Power Shot",
					"icon": "power_shot",
					"summary": "Heavy piercing arrow auto-cast on cooldown.",
					"detail": "Power Shot fires a harder-hitting piercing arrow with guaranteed critical behavior. It gives Archer high single-lane pressure without adding manual input tax.",
				},
				{
					"key": "SPACE",
					"name": "Dash",
					"icon": "dash",
					"summary": "Manual repositioning tool for execution checks.",
					"detail": "Dash is the skill-expression button. Use it to cut angles, escape roots, and preserve spacing during boss mechanics.",
				},
				{
					"key": "E",
					"name": "Arrow Volley",
					"icon": "power_shot",
					"summary": "Auto-cast fan of arrows into clustered enemies.",
					"detail": "Arrow Volley fires a spread of arrows into the nearest pack. It replaces the old Entangle slot and keeps Archer purely ranged.",
				},
				{
					"key": "R",
					"name": "Frenzy",
					"icon": "frenzy",
					"summary": "Charge-based burst form with faster shots and stronger crit pressure.",
					"detail": "Frenzy is a charge ult. It spikes move speed, attack speed, and crit pressure for a short execution window, then falls off cleanly.",
				},
			],
		},
		{
			"id": CLASS_ARCANE_PISTOL,
			"name": "ARCANE PISTOL",
			"status": "SECOND CLASS PATH",
			"description": "Magical gunslinger preserved as the next class after Archer parity stabilizes.",
			"abilities": [
				{
					"key": "PRIMARY",
					"name": "Arcane Pistol",
					"icon": "pistol",
					"summary": "Precise ranged shots with sniper-mode upgrade path.",
					"detail": "Arcane Pistol fires magical bullets in a fast, readable ranged cadence. The class is preserved and still has its own dedicated runtime scene.",
				},
				{
					"key": "E",
					"name": "Arcane Missiles",
					"icon": "missiles",
					"summary": "Magical volley that curves into enemies after launch.",
					"detail": "Arcane Missiles launches a visible arc of projectiles that begin homing after a short delay, making the class feel intelligent rather than hitscan-heavy.",
				},
				{
					"key": "SPACE",
					"name": "Arcane Blink",
					"icon": "blink",
					"summary": "Instant repositioning step.",
					"detail": "Blink keeps the gunslinger evasive without becoming a melee class. It preserves the fast ranged identity already prototyped in Godot.",
				},
				{
					"key": "R",
					"name": "Arcane Sniper",
					"icon": "sniper",
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
			"detail": "Deepwood is the active parity biome. It is where Archer progression, objectives, and the Treent boss are being brought in line with the Love2D design.",
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
	if selected_class_id == CLASS_ARCANE_PISTOL:
		return "res://scenes/main/ArcanePistolMain.tscn"
	return "res://scenes/main/Main.tscn"
