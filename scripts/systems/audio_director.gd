extends Node

const SILENT_DB: float = -60.0
const MUSIC_VOLUME_DB: float = -8.0
const AMBIENCE_VOLUME_DB: float = -22.0
const SFX_POOL_SIZE: int = 14
const UI_POOL_SIZE: int = 8

const MUSIC_TRACKS: Dictionary = {
	"menu": "res://audio/curated/music/mainmenu.mp3",
	"hub": "res://audio/curated/music/hub.mp3",
}

const AMBIENCE_LOOPS: Dictionary = {
	"hub_wind": {
		"paths": ["res://audio/curated/ambience/hub_wind_01.ogg"],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
}

const SFX_EVENTS: Dictionary = {
	"footstep_stone": {
		"paths": [
			"res://audio/curated/footsteps/stone_01.ogg",
			"res://audio/curated/footsteps/stone_02.ogg",
			"res://audio/curated/footsteps/stone_03.ogg",
			"res://audio/curated/footsteps/stone_04.ogg",
			"res://audio/curated/footsteps/stone_05.ogg",
		],
		"pitch_min": 0.96,
		"pitch_max": 1.04,
	},
	"footstep_grass": {
		"paths": [
			"res://audio/curated/footsteps/grass_01.ogg",
			"res://audio/curated/footsteps/grass_02.ogg",
			"res://audio/curated/footsteps/grass_03.ogg",
			"res://audio/curated/footsteps/grass_04.ogg",
			"res://audio/curated/footsteps/grass_05.ogg",
		],
		"pitch_min": 0.96,
		"pitch_max": 1.04,
	},
	"bow_primary": {
		"paths": [
			"res://audio/curated/combat/archer/bow_primary_01.ogg",
			"res://audio/curated/combat/archer/bow_primary_02.ogg",
			"res://audio/curated/combat/archer/bow_primary_03.ogg",
		],
		"pitch_min": 0.97,
		"pitch_max": 1.03,
	},
	"bow_power_shot": {
		"paths": [
			"res://audio/curated/combat/archer/bow_power_shot_01.ogg",
		],
		"pitch_min": 0.99,
		"pitch_max": 1.01,
	},
	"bow_volley": {
		"paths": [
			"res://audio/curated/combat/archer/bow_volley_01.ogg",
			"res://audio/curated/combat/archer/bow_volley_02.ogg",
		],
		"pitch_min": 0.97,
		"pitch_max": 1.03,
	},
	"dash_archer": {
		"paths": [
			"res://audio/curated/combat/archer/dash_archer_01.ogg",
			"res://audio/curated/combat/archer/dash_archer_02.ogg",
		],
		"pitch_min": 0.98,
		"pitch_max": 1.03,
	},
	"arcane_primary": {
		"paths": [
			"res://audio/curated/combat/arcane/arcane_primary_01.ogg",
			"res://audio/curated/combat/arcane/arcane_primary_02.ogg",
			"res://audio/curated/combat/arcane/arcane_primary_03.ogg",
		],
		"pitch_min": 0.98,
		"pitch_max": 1.02,
	},
	"arcane_blink": {
		"paths": [
			"res://audio/curated/combat/arcane/arcane_blink_01.ogg",
			"res://audio/curated/combat/arcane/arcane_blink_02.ogg",
			"res://audio/curated/combat/arcane/arcane_blink_03.ogg",
			"res://audio/curated/combat/arcane/arcane_blink_04.ogg",
			"res://audio/curated/combat/arcane/arcane_blink_05.ogg",
		],
		"pitch_min": 0.98,
		"pitch_max": 1.04,
	},
	"arcane_missiles": {
		"paths": [
			"res://audio/curated/combat/arcane/arcane_missiles_01.ogg",
			"res://audio/curated/combat/arcane/arcane_missiles_02.ogg",
			"res://audio/curated/combat/arcane/arcane_missiles_03.ogg",
		],
		"pitch_min": 0.98,
		"pitch_max": 1.03,
	},
	"arcane_sniper": {
		"paths": [
			"res://audio/curated/combat/arcane/arcane_sniper_01.ogg",
			"res://audio/curated/combat/arcane/arcane_sniper_02.ogg",
		],
		"pitch_min": 0.99,
		"pitch_max": 1.01,
	},
	"dummy_hit_light": {
		"paths": [
			"res://audio/curated/training/dummy_hit_light_01.ogg",
			"res://audio/curated/training/dummy_hit_light_02.ogg",
			"res://audio/curated/training/dummy_hit_light_03.ogg",
			"res://audio/curated/training/dummy_hit_light_04.ogg",
			"res://audio/curated/training/dummy_hit_light_05.ogg",
		],
		"pitch_min": 0.97,
		"pitch_max": 1.03,
	},
	"dummy_hit_heavy": {
		"paths": [
			"res://audio/curated/training/dummy_hit_heavy_01.ogg",
			"res://audio/curated/training/dummy_hit_heavy_02.ogg",
			"res://audio/curated/training/dummy_hit_heavy_03.ogg",
			"res://audio/curated/training/dummy_hit_heavy_04.ogg",
			"res://audio/curated/training/dummy_hit_heavy_05.ogg",
		],
		"pitch_min": 0.97,
		"pitch_max": 1.02,
	},
}

const UI_EVENTS: Dictionary = {
	"ui_hover": {
		"paths": [
			"res://audio/curated/ui/ui_hover_01.ogg",
			"res://audio/curated/ui/ui_hover_02.ogg",
		],
		"pitch_min": 0.99,
		"pitch_max": 1.01,
	},
	"ui_click": {
		"paths": [
			"res://audio/curated/ui/ui_click_01.ogg",
			"res://audio/curated/ui/ui_click_02.ogg",
		],
		"pitch_min": 0.99,
		"pitch_max": 1.01,
	},
	"ui_confirm": {
		"paths": [
			"res://audio/curated/ui/ui_confirm_01.ogg",
			"res://audio/curated/ui/ui_confirm_02.ogg",
		],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
	"ui_cancel": {
		"paths": [
			"res://audio/curated/ui/ui_cancel_01.ogg",
		],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
	"ui_open": {
		"paths": [
			"res://audio/curated/ui/ui_open_01.ogg",
		],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
	"ui_close": {
		"paths": [
			"res://audio/curated/ui/ui_close_01.ogg",
		],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
	"ui_error": {
		"paths": [
			"res://audio/curated/ui/ui_error_01.ogg",
			"res://audio/curated/ui/ui_error_02.ogg",
		],
		"pitch_min": 1.0,
		"pitch_max": 1.0,
	},
}

var _current_music_track_id: String = ""
var _current_music_context: String = ""
var _current_ambience_loop_id: String = ""
var _stream_cache: Dictionary = {}
var _last_variant_index: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _ambience_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_cursor: int = 0
var _ui_pool_cursor: int = 0
var _music_active_index: int = 0
var _music_transition_serial: int = 0
var _ambience_transition_serial: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_build_music_players()
	_build_ambience_player()
	_build_pool(_sfx_pool, SFX_POOL_SIZE, "SFX")
	_build_pool(_ui_pool, UI_POOL_SIZE, "UI")
	if GameSettings != null and GameSettings.has_method("apply_audio_bus_volumes"):
		GameSettings.apply_audio_bus_volumes()

func play_music(track_id: String, fade_seconds: float = 0.4) -> void:
	if track_id.is_empty():
		stop_music(fade_seconds)
		return
	if _current_music_track_id == track_id and _get_active_music_player().playing:
		return
	var resource_path: String = str(MUSIC_TRACKS.get(track_id, ""))
	if resource_path.is_empty():
		return
	var stream: AudioStream = _load_stream(resource_path, true)
	if stream == null:
		return
	var incoming_index: int = 1 - _music_active_index
	var incoming_player: AudioStreamPlayer = _music_players[incoming_index]
	var outgoing_player: AudioStreamPlayer = _music_players[_music_active_index]
	_music_transition_serial += 1
	var transition_serial: int = _music_transition_serial
	incoming_player.stop()
	incoming_player.stream = stream
	incoming_player.volume_db = SILENT_DB
	incoming_player.play()
	_crossfade_music(outgoing_player, incoming_player, fade_seconds, transition_serial)
	_music_active_index = incoming_index
	_current_music_track_id = track_id

func stop_music(fade_seconds: float = 0.4) -> void:
	_music_transition_serial += 1
	var transition_serial: int = _music_transition_serial
	_current_music_track_id = ""
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for player in _music_players:
		if player == null:
			continue
		tween.parallel().tween_property(player, "volume_db", SILENT_DB, maxf(fade_seconds, 0.01))
	tween.finished.connect(func() -> void:
		if transition_serial != _music_transition_serial:
			return
		for player in _music_players:
			if player != null:
				player.stop()
	)

func set_music_context(context_id: String) -> void:
	var same_context: bool = _current_music_context == context_id
	_current_music_context = context_id
	match context_id:
		"menu":
			if not same_context:
				play_music("menu")
			stop_ambience()
		"hub":
			if not same_context:
				play_music("hub")
			stop_ambience()
		_:
			stop_music()
			stop_ambience()

func play_sfx(event_id: String, volume_db: float = 0.0) -> void:
	_play_event_from_registry(event_id, SFX_EVENTS, _sfx_pool, "_sfx_pool_cursor", volume_db)

func play_ui(event_id: String, volume_db: float = 0.0) -> void:
	_play_event_from_registry(event_id, UI_EVENTS, _ui_pool, "_ui_pool_cursor", volume_db)

func play_ambience(loop_id: String, fade_seconds: float = 0.5) -> void:
	if _ambience_player == null:
		return
	if _current_ambience_loop_id == loop_id and _ambience_player.playing:
		return
	var config: Dictionary = AMBIENCE_LOOPS.get(loop_id, {})
	if config.is_empty():
		stop_ambience(fade_seconds)
		return
	var paths: Array = config.get("paths", [])
	if paths.is_empty():
		return
	var stream: AudioStream = _load_stream(str(paths[0]), true)
	if stream == null:
		return
	_ambience_transition_serial += 1
	_current_ambience_loop_id = loop_id
	_ambience_player.stop()
	_ambience_player.stream = stream
	_ambience_player.volume_db = SILENT_DB
	_ambience_player.play()
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_ambience_player, "volume_db", AMBIENCE_VOLUME_DB, maxf(fade_seconds, 0.01))

func stop_ambience(fade_seconds: float = 0.5) -> void:
	_ambience_transition_serial += 1
	var transition_serial: int = _ambience_transition_serial
	_current_ambience_loop_id = ""
	if _ambience_player == null:
		return
	if not _ambience_player.playing:
		return
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_ambience_player, "volume_db", SILENT_DB, maxf(fade_seconds, 0.01))
	tween.finished.connect(func() -> void:
		if transition_serial == _ambience_transition_serial and _current_ambience_loop_id.is_empty() and _ambience_player != null:
			_ambience_player.stop()
	)

func _play_event_from_registry(event_id: String, registry: Dictionary, pool: Array[AudioStreamPlayer], cursor_field: String, volume_db: float) -> void:
	var config: Dictionary = registry.get(event_id, {})
	if config.is_empty():
		return
	var paths: Array = config.get("paths", [])
	if paths.is_empty():
		return
	var chosen_index: int = _choose_variant_index(event_id, paths.size())
	var stream: AudioStream = _load_stream(str(paths[chosen_index]), false)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_next_pool_player(pool, cursor_field)
	if player == null:
		return
	player.stop()
	player.stream = stream
	player.pitch_scale = randf_range(
		float(config.get("pitch_min", 1.0)),
		float(config.get("pitch_max", 1.0))
	)
	player.volume_db = volume_db
	player.play()

func _crossfade_music(outgoing_player: AudioStreamPlayer, incoming_player: AudioStreamPlayer, fade_seconds: float, transition_serial: int) -> void:
	var duration: float = maxf(fade_seconds, 0.01)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if outgoing_player != null and outgoing_player.playing:
		tween.parallel().tween_property(outgoing_player, "volume_db", SILENT_DB, duration)
	tween.parallel().tween_property(incoming_player, "volume_db", MUSIC_VOLUME_DB, duration)
	tween.finished.connect(func() -> void:
		if transition_serial != _music_transition_serial:
			return
		if outgoing_player != null and outgoing_player != incoming_player:
			outgoing_player.stop()
	)

func _build_music_players() -> void:
	for index in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % index
		player.bus = "Music"
		player.volume_db = SILENT_DB
		add_child(player)
		_music_players.append(player)

func _build_ambience_player() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Ambience"
	_ambience_player.volume_db = SILENT_DB
	add_child(_ambience_player)

func _build_pool(pool: Array[AudioStreamPlayer], pool_size: int, bus_name: String) -> void:
	for index in range(pool_size):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "%sPlayer%d" % [bus_name, index]
		player.bus = bus_name
		add_child(player)
		pool.append(player)

func _get_next_pool_player(pool: Array[AudioStreamPlayer], cursor_field: String) -> AudioStreamPlayer:
	if pool.is_empty():
		return null
	var cursor: int = int(get(cursor_field))
	for offset in range(pool.size()):
		var index: int = (cursor + offset) % pool.size()
		var candidate: AudioStreamPlayer = pool[index]
		if candidate != null and not candidate.playing:
			set(cursor_field, (index + 1) % pool.size())
			return candidate
	var fallback: AudioStreamPlayer = pool[cursor % pool.size()]
	set(cursor_field, (cursor + 1) % pool.size())
	return fallback

func _choose_variant_index(event_id: String, variant_count: int) -> int:
	if variant_count <= 1:
		_last_variant_index[event_id] = 0
		return 0
	var last_index: int = int(_last_variant_index.get(event_id, -1))
	var candidate: int = randi() % variant_count
	if candidate == last_index:
		candidate = (candidate + 1 + int(randi() % max(variant_count - 1, 1))) % variant_count
	_last_variant_index[event_id] = candidate
	return candidate

func _load_stream(resource_path: String, looped: bool) -> AudioStream:
	if resource_path.is_empty():
		return null
	var cached: AudioStream = _stream_cache.get(resource_path) as AudioStream
	if cached == null:
		var lower_path: String = resource_path.to_lower()
		if lower_path.ends_with(".mp3"):
			cached = AudioStreamMP3.load_from_file(resource_path)
		elif lower_path.ends_with(".ogg"):
			cached = AudioStreamOggVorbis.load_from_file(resource_path)
		else:
			cached = ResourceLoader.load(resource_path) as AudioStream
		if cached == null:
			return null
		_stream_cache[resource_path] = cached
	if not looped:
		return cached
	var duplicated: AudioStream = cached.duplicate(true) as AudioStream
	if duplicated == null:
		duplicated = cached
	_set_stream_loop(duplicated, true)
	return duplicated

func _set_stream_loop(stream: AudioStream, loop_enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if String(property.name) == "loop":
			stream.set("loop", loop_enabled)
			return

func _get_active_music_player() -> AudioStreamPlayer:
	return _music_players[_music_active_index] if _music_active_index < _music_players.size() else null

func _ensure_audio_buses() -> void:
	var desired_buses: Array[String] = ["Master", "Music", "SFX", "UI", "Ambience"]
	for index in range(desired_buses.size()):
		if index >= AudioServer.get_bus_count():
			AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, desired_buses[index])
		if index > 0:
			AudioServer.set_bus_send(index, "Master")
