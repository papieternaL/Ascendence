extends Node
class_name CombatJuice

const FROZEN_TIME_SCALE: float = 0.001
const REDUCED_FLASHES_MULTIPLIER: float = 0.65

var _player: Node
var _freeze_remaining: float = 0.0
var _last_real_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_real_time = Time.get_ticks_usec() * 0.000001
	Engine.time_scale = 1.0

func setup(player: Node) -> void:
	_player = player

func trigger_enemy_hit(data: Dictionary) -> void:
	if bool(data.get("suppress_impact_juice", false)):
		return
	var target: Node = data.get("target") as Node
	if _is_objective_prop(target):
		return
	var profile: Dictionary = _build_enemy_profile(data, target)
	_apply_profile(profile)

func trigger_player_hit(data: Dictionary) -> void:
	var amount: float = float(data.get("amount", 0.0))
	if amount <= 0.0:
		return
	var freeze_duration: float = 0.016
	var shake_intensity: float = 1.8
	if amount >= 200.0:
		freeze_duration = 0.02
		shake_intensity = 2.3
	var scale: float = _get_accessibility_scale()
	_apply_profile({
		"freeze": freeze_duration * scale,
		"shake": shake_intensity * scale,
		"duration": 0.11,
	})

func clear_state() -> void:
	_freeze_remaining = 0.0
	_last_real_time = Time.get_ticks_usec() * 0.000001
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_usec() * 0.000001
	var real_delta: float = clampf(now - _last_real_time, 0.0, 0.1)
	_last_real_time = now
	if _freeze_remaining > 0.0:
		_freeze_remaining = maxf(_freeze_remaining - real_delta, 0.0)
	if _freeze_remaining > 0.0:
		if Engine.time_scale != FROZEN_TIME_SCALE:
			Engine.time_scale = FROZEN_TIME_SCALE
	elif Engine.time_scale != 1.0:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	clear_state()

func _build_enemy_profile(data: Dictionary, target: Node) -> Dictionary:
	var killed: bool = bool(data.get("killed", false))
	var heavy_hit: bool = bool(data.get("heavy_hit", false))
	var freeze_duration: float = 0.0
	var shake_intensity: float = 0.0
	var shake_duration: float = 0.1
	if killed:
		freeze_duration = 0.024
		shake_intensity = 2.2
		shake_duration = 0.13
		if target != null and target.is_in_group("elite"):
			freeze_duration = 0.03
			shake_intensity = 2.8
			shake_duration = 0.15
		elif target != null and target.is_in_group("boss"):
			freeze_duration = 0.036
			shake_intensity = 3.4
			shake_duration = 0.18
	elif heavy_hit:
		freeze_duration = 0.018
		shake_intensity = 1.5
		shake_duration = 0.1
		if target != null and target.is_in_group("elite"):
			freeze_duration = 0.022
			shake_intensity = 1.9
			shake_duration = 0.11
		elif target != null and target.is_in_group("boss"):
			freeze_duration = 0.026
			shake_intensity = 2.3
			shake_duration = 0.12
	if freeze_duration <= 0.0 and shake_intensity <= 0.0:
		return {}
	var scale: float = _get_accessibility_scale()
	return {
		"freeze": freeze_duration * scale,
		"shake": shake_intensity * scale,
		"duration": shake_duration,
	}

func _apply_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	var freeze_duration: float = float(profile.get("freeze", 0.0))
	if freeze_duration > 0.0:
		_freeze_remaining = maxf(_freeze_remaining, freeze_duration)
	var shake_intensity: float = float(profile.get("shake", 0.0))
	if shake_intensity > 0.0 and _player != null and _player.has_method("add_screen_shake"):
		_player.call("add_screen_shake", shake_intensity, float(profile.get("duration", 0.1)))

func _get_accessibility_scale() -> float:
	if GameSettings and GameSettings.use_reduced_flashes():
		return REDUCED_FLASHES_MULTIPLIER
	return 1.0

func _is_objective_prop(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return target.is_in_group("objective_core") or target.is_in_group("reward_chest") or target.is_in_group("boss_root")
