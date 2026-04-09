extends Node2D
## World-space XP pickups (Love2D-style) + rare vacuum magnet; calls ExperienceSystem.add_xp on collect.

const MAGNET_DROP_CHANCE: float = 0.025

var _xp_system: ExperienceSystem
var _player: Node2D
var _pickup_radius_mul: float = 1.0
var _pulse_time: float = 0.0
var _had_visible_pickups: bool = false

var _orbs: Array = []
var _magnets: Array = []

@export var pickup_radius_base: float = 63.0
@export var orb_collect_radius: float = 20.0
@export var magnet_collect_radius: float = 26.0
@export var orb_lifetime: float = 30.0
@export var magnet_lifetime: float = 18.0
@export var xp_drop_multiplier: float = 1.0

func setup(xp_system: ExperienceSystem, player: Node2D) -> void:
	_xp_system = xp_system
	_player = player

func set_pickup_radius_multiplier(mul: float) -> void:
	_pickup_radius_mul = maxf(mul, 0.25)

func spawn_orb_at(world_position: Vector2, value: int, try_magnet: bool = true) -> void:
	var v: int = maxi(1, int(floor(float(value) * xp_drop_multiplier)))
	var orb: Dictionary = {
		"position": world_position,
		"velocity": Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * 100.0,
		"value": v,
		"lifetime": 0.0,
		"attracted": false,
		"magnet_boost": 1.0,
		"size": randf_range(6.0, 10.0),
		"pulse_phase": randf() * TAU,
	}
	_orbs.append(orb)
	_had_visible_pickups = true
	queue_redraw()
	if try_magnet and randf() < MAGNET_DROP_CHANCE:
		_spawn_magnet_pickup(world_position)

func _spawn_magnet_pickup(world_position: Vector2) -> void:
	var magnet: Dictionary = {
		"position": world_position,
		"velocity": Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * 80.0,
		"lifetime": 0.0,
		"size": randf_range(12.0, 17.0),
		"pulse_phase": randf() * TAU,
	}
	_magnets.append(magnet)
	_had_visible_pickups = true
	queue_redraw()

func _activate_magnet() -> void:
	for i in range(_orbs.size()):
		_orbs[i]["attracted"] = true
		_orbs[i]["magnet_boost"] = 1.8
		var vel: Vector2 = _orbs[i]["velocity"]
		_orbs[i]["velocity"] = vel * 0.3

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_pulse_time += delta
	var changed: bool = false
	var pr: float = pickup_radius_base * _pickup_radius_mul
	var px: float = _player.global_position.x
	var py: float = _player.global_position.y

	var mi: int = 0
	while mi < _magnets.size():
		var mag: Dictionary = _magnets[mi]
		mag["lifetime"] = float(mag["lifetime"]) + delta
		var mv: Vector2 = mag["velocity"]
		mv *= 0.92
		var mdx: float = px - float(mag["position"].x)
		var mdy: float = py - float(mag["position"].y)
		var mdist: float = sqrt(mdx * mdx + mdy * mdy)
		var pull_r: float = pr * 1.35
		if mdist < pull_r and mdist > 0.001:
			var pull: float = 520.0 * (1.0 - minf(1.0, mdist / pull_r))
			mv.x += (mdx / mdist) * pull * delta * 8.0
			mv.y += (mdy / mdist) * pull * delta * 8.0
		mag["velocity"] = mv
		mag["position"] = Vector2(float(mag["position"].x) + mv.x * delta, float(mag["position"].y) + mv.y * delta)
		if mdist < magnet_collect_radius:
			_activate_magnet()
			_magnets.remove_at(mi)
			changed = true
			continue
		if float(mag["lifetime"]) > magnet_lifetime:
			_magnets.remove_at(mi)
			changed = true
			continue
		mi += 1

	var oi: int = 0
	while oi < _orbs.size():
		var ob: Dictionary = _orbs[oi]
		ob["lifetime"] = float(ob["lifetime"]) + delta
		var mb: float = float(ob.get("magnet_boost", 1.0))
		if mb > 1.01:
			mb = maxf(1.0, mb - delta * 0.9)
			ob["magnet_boost"] = mb
		var ov: Vector2 = ob["velocity"]
		ov *= 0.95
		var dx: float = px - float(ob["position"].x)
		var dy: float = py - float(ob["position"].y)
		var dist: float = sqrt(dx * dx + dy * dy)
		if dist < pr * 2.0:
			ob["attracted"] = true
		if bool(ob["attracted"]) or dist < pr * 2.0:
			var speed: float = 800.0 * (1.0 - minf(1.0, dist / maxf(pr * 2.0, 1.0)))
			speed = maxf(speed, 500.0 if bool(ob["attracted"]) else 100.0)
			speed *= float(ob.get("magnet_boost", 1.0))
			if dist > 0.001:
				ov.x += (dx / dist) * speed * delta * 18.0
				ov.y += (dy / dist) * speed * delta * 18.0
		ob["velocity"] = ov
		ob["position"] = Vector2(float(ob["position"].x) + ov.x * delta, float(ob["position"].y) + ov.y * delta)
		dx = px - float(ob["position"].x)
		dy = py - float(ob["position"].y)
		dist = sqrt(dx * dx + dy * dy)
		if dist < orb_collect_radius and _xp_system != null:
			_xp_system.add_xp(int(ob["value"]))
			_orbs.remove_at(oi)
			changed = true
			continue
		if float(ob["lifetime"]) > orb_lifetime:
			_orbs.remove_at(oi)
			changed = true
			continue
		oi += 1

	var has_visible_pickups: bool = not _orbs.is_empty() or not _magnets.is_empty()
	if changed or has_visible_pickups or _had_visible_pickups != has_visible_pickups:
		queue_redraw()
	_had_visible_pickups = has_visible_pickups

func _draw() -> void:
	var t: float = _pulse_time
	for mag: Dictionary in _magnets:
		var pulse_m: float = sin(t * 4.0 + float(mag["pulse_phase"])) * 0.25 + 0.75
		var sz_m: float = float(mag["size"]) * pulse_m
		var p_m: Vector2 = to_local(Vector2(float(mag["position"].x), float(mag["position"].y)))
		draw_circle(p_m, sz_m * 2.3, Color(0.38, 0.78, 1.0, 0.16))
		draw_circle(p_m, sz_m * 1.3, Color(0.55, 0.86, 1.0, 0.28))
		draw_circle(p_m, sz_m, Color(0.46, 0.84, 1.0, 0.96))
		draw_circle(p_m, sz_m * 0.44, Color(1.0, 1.0, 1.0, 0.8))
		for arc_index in range(2):
			var base_angle: float = t * (1.4 + float(arc_index) * 0.3) + float(arc_index) * PI
			draw_arc(p_m, sz_m * 1.55, base_angle, base_angle + PI * 0.72, 26, Color(0.82, 0.96, 1.0, 0.88), 2.3)
		for spark_index in range(4):
			var orbit_angle: float = -t * (1.0 + float(spark_index) * 0.08) + TAU * float(spark_index) / 4.0
			var orbit_offset: Vector2 = Vector2.RIGHT.rotated(orbit_angle) * (sz_m * 1.6)
			draw_circle(p_m + orbit_offset, 1.7, Color(0.94, 0.98, 1.0, 0.7))
		draw_arc(p_m, sz_m * 0.94, 0.0, TAU, 28, Color(0.88, 0.98, 1.0, 0.6), 1.7)

	for ob: Dictionary in _orbs:
		var pulse_o: float = sin(t * 6.0 + float(ob["pulse_phase"])) * 0.3 + 0.7
		var sz_o: float = float(ob["size"]) * pulse_o
		var p_o: Vector2 = to_local(Vector2(float(ob["position"].x), float(ob["position"].y)))
		## Purple / cyan orb (Spell Brigade-ish)
		draw_circle(p_o, sz_o * 1.5, Color(0.55, 0.35, 0.95, 0.22))
		draw_circle(p_o, sz_o, Color(0.45, 0.75, 1.0, 0.95))
		draw_circle(p_o, sz_o * 0.4, Color(1.0, 1.0, 1.0, 0.82))
