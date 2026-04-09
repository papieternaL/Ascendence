extends CharacterBody2D
class_name EnemyBase

const ElementalSystem = preload("res://scripts/systems/elemental_system.gd")

signal damage_taken(world_position: Vector2, amount: float, is_crit: bool)
signal damage_feedback(data: Dictionary)

@export var max_health: float = 250.0
@export var move_speed: float = 90.0
@export var body_color: Color = Color(0.94, 0.6, 0.56, 1.0)
@export var contact_damage: float = 80.0
@export var xp_reward: int = 18
@export var rarity_charge_reward: int = 1
@export var counts_as_kill: bool = true
@export var display_name: String = "Enemy"
@export var enemy_kind: String = "enemy"
@export var boss_progress_reward: float = 0.0
@export var show_health_bar_always: bool = false
@export var show_nameplate: bool = false
@export var health_bar_scale: Vector2 = Vector2.ONE
@export var health_bar_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var nameplate_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var visual_scale: float = 1.14
@export var light_hit_flash_duration: float = 0.07
@export var heavy_hit_flash_duration: float = 0.11
@export var hit_reaction_duration: float = 0.12
@export var light_hit_reaction_intensity: float = 0.45
@export var heavy_hit_reaction_intensity: float = 0.95
@export var hit_reaction_push: float = 3.0
@export var light_knockback_speed: float = 92.0
@export var heavy_knockback_speed: float = 158.0
@export var knockback_decay: float = 880.0
@export var elite_knockback_scale: float = 0.35
@export var boss_knockback_scale: float = 0.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var nameplate: Label = get_node_or_null("Nameplate") as Label

var health: float
var _flash_remaining: float = 0.0
var rooted_remaining: float = 0.0
var _hit_reaction_remaining: float = 0.0
var _hit_reaction_direction: Vector2 = Vector2.ZERO
var _hit_reaction_intensity: float = 0.0
var _flash_duration_current: float = 0.0
var _hit_reaction_duration_current: float = 0.0
var _status_visual_time: float = 0.0
var elemental_statuses: Dictionary = {}
var last_hit_was_crit: bool = false
var _health_bar_base_top: float = 0.0
var _health_bar_base_height: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	add_to_group(enemy_kind)
	health = max_health
	scale *= maxf(visual_scale, 0.1)
	_apply_overhead_presentation()
	_update_health_bar()
	queue_redraw()

func _process(delta: float) -> void:
	_status_visual_time += delta
	if _flash_remaining > 0.0:
		_flash_remaining = max(_flash_remaining - delta, 0.0)
		queue_redraw()
	if rooted_remaining > 0.0:
		rooted_remaining = max(rooted_remaining - delta, 0.0)
	if _hit_reaction_remaining > 0.0:
		_hit_reaction_remaining = max(_hit_reaction_remaining - delta, 0.0)
		queue_redraw()
	ElementalSystem.tick_target(self, delta)

func apply_root(duration: float) -> void:
	rooted_remaining = max(rooted_remaining, duration)

func is_rooted() -> bool:
	return rooted_remaining > 0.0 or ElementalSystem.is_frozen(self)

func get_effective_move_speed() -> float:
	return move_speed * ElementalSystem.get_speed_multiplier(self)

func take_damage(attack: Variant) -> void:
	var damage_amount: float = 0.0
	var is_crit: bool = false
	var impact_direction: Vector2 = Vector2.ZERO
	var hit_kind: String = "arrow"
	var suppress_impact_juice: bool = false
	if attack is Dictionary:
		var attack_data: Dictionary = attack
		damage_amount = float(attack_data.get("amount", 0.0))
		is_crit = bool(attack_data.get("is_crit", false))
		impact_direction = Vector2(attack_data.get("impact_direction", Vector2.ZERO))
		hit_kind = str(attack_data.get("hit_kind", "arrow"))
		suppress_impact_juice = bool(attack_data.get("suppress_impact_juice", false))
	else:
		damage_amount = float(attack)
	if damage_amount <= 0.0 or health <= 0.0:
		return
	var heavy_hit: bool = _is_heavy_hit(hit_kind, is_crit)
	health = max(health - damage_amount, 0.0)
	last_hit_was_crit = is_crit
	apply_hit_recoil(impact_direction, heavy_hit)
	_hit_feedback(impact_direction, is_crit, hit_kind)
	_update_health_bar()
	var killed: bool = health <= 0.0
	damage_taken.emit(global_position + Vector2(0.0, -18.0), damage_amount, is_crit)
	damage_feedback.emit({
		"world_position": global_position + Vector2(0.0, -18.0),
		"amount": damage_amount,
		"is_crit": is_crit,
		"hit_kind": hit_kind,
		"heavy_hit": heavy_hit,
		"killed": killed,
		"suppress_impact_juice": suppress_impact_juice,
		"target": self,
	})
	if attack is Dictionary:
		ElementalSystem.process_attack_hit(self, attack)
	if killed:
		die()

func die() -> void:
	ElementalSystem.handle_target_death(self)
	if has_node("/root/GameEvents"):
		GameEvents.enemy_killed.emit(self)
		GameEvents.enemy_died.emit(self)
	queue_free()

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = show_health_bar_always or health < max_health

func _hit_feedback(impact_direction: Vector2 = Vector2.ZERO, is_crit: bool = false, hit_kind: String = "arrow") -> void:
	var heavy_hit: bool = _is_heavy_hit(hit_kind, is_crit)
	var flash_scale: float = 0.8 if GameSettings and GameSettings.use_reduced_flashes() else 1.0
	var reaction_scale: float = 0.75 if GameSettings and GameSettings.use_reduced_flashes() else 1.0
	_flash_duration_current = (heavy_hit_flash_duration if heavy_hit else light_hit_flash_duration) * flash_scale
	_hit_reaction_duration_current = hit_reaction_duration
	_flash_remaining = _flash_duration_current
	_hit_reaction_remaining = _hit_reaction_duration_current
	_hit_reaction_direction = impact_direction.normalized()
	_hit_reaction_intensity = (heavy_hit_reaction_intensity if heavy_hit else light_hit_reaction_intensity) * reaction_scale
	queue_redraw()

func _draw() -> void:
	var flash_mix: float = clamp(_flash_remaining / max(_flash_duration_current, 0.001), 0.0, 1.0)
	var tint: Color = body_color.lerp(Color(1.0, 0.95, 0.95, 1.0), flash_mix)
	var reaction_mix: float = clamp(_hit_reaction_remaining / max(_hit_reaction_duration_current, 0.001), 0.0, 1.0)
	var draw_offset: Vector2 = _hit_reaction_direction * (hit_reaction_push * _hit_reaction_intensity * reaction_mix)
	var scale_x: float = 1.0 + (0.18 * _hit_reaction_intensity * reaction_mix)
	var scale_y: float = 1.0 - (0.1 * _hit_reaction_intensity * reaction_mix)
	draw_set_transform(draw_offset, 0.0, Vector2(scale_x, scale_y))
	draw_circle(Vector2(0, 6), 11.0, Color(0.05, 0.14, 0.1, 0.22))
	if ElementalSystem.has_status(self, "burn"):
		var burn_stacks: int = max(ElementalSystem.get_status_stacks(self, "burn"), 1)
		var burn_pulse: float = 0.72 + 0.18 * sin(_status_visual_time * 8.0)
		draw_circle(Vector2.ZERO, 15.0 + burn_pulse, Color(1.0, 0.28, 0.08, 0.08 + 0.02 * burn_stacks))
		for i in range(4):
			var orbit_angle: float = _status_visual_time * (1.4 + float(i) * 0.12) + TAU * float(i) / 4.0
			var orbit: Vector2 = Vector2.RIGHT.rotated(orbit_angle) * (8.0 + 1.6 * sin(_status_visual_time * 3.0 + float(i)))
			draw_circle(orbit + Vector2(0.0, -3.0), 2.2 + 0.3 * sin(_status_visual_time * 10.0 + float(i)), Color(1.0, 0.42, 0.1, 0.2))
			draw_circle(orbit + Vector2(0.0, -5.0), 1.2, Color(1.0, 0.84, 0.46, 0.26))
	if ElementalSystem.has_status(self, "chill") or ElementalSystem.has_status(self, "freeze"):
		var chill_alpha: float = 0.08 if ElementalSystem.has_status(self, "chill") else 0.12
		draw_circle(Vector2.ZERO, 16.0 + 1.8 * sin(_status_visual_time * 5.2), Color(0.52, 0.82, 1.0, chill_alpha))
		for i in range(3):
			var drift_angle: float = PI * 0.5 + sin(_status_visual_time * 1.6 + float(i)) * 0.8 + float(i) * 0.9
			var drift_offset: Vector2 = Vector2.RIGHT.rotated(drift_angle) * (7.5 + float(i) * 2.6)
			draw_circle(drift_offset + Vector2(0.0, -6.0 - float(i) * 2.0), 4.0 + float(i) * 0.8, Color(0.76, 0.92, 1.0, 0.05))
	draw_circle(Vector2.ZERO, 11.0, tint)
	draw_circle(Vector2(0, -3), 4.0, Color(1.0, 1.0, 1.0, 0.18))
	if ElementalSystem.has_status(self, "burn"):
		var burn_alpha: float = 0.26 + 0.08 * min(ElementalSystem.get_status_stacks(self, "burn"), 3)
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 22, Color(1.0, 0.46, 0.12, burn_alpha), 2.0)
	if ElementalSystem.has_status(self, "chill"):
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 22, Color(0.52, 0.86, 1.0, 0.72), 2.0)
	if ElementalSystem.has_status(self, "freeze"):
		draw_circle(Vector2.ZERO, 14.5, Color(0.82, 0.96, 1.0, 0.1))
		for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
			var axis: Vector2 = Vector2.RIGHT.rotated(angle) * 12.0
			draw_line(-axis, axis, Color(0.86, 0.96, 1.0, 0.82), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func apply_hit_recoil(direction: Vector2, heavy: bool) -> void:
	if _is_impact_excluded() or direction.length_squared() <= 0.0001:
		return
	var scale: float = 1.0
	if is_in_group("elite"):
		scale *= elite_knockback_scale
	if is_in_group("boss"):
		scale *= boss_knockback_scale
	if scale <= 0.0:
		return
	var recoil_speed: float = heavy_knockback_speed if heavy else light_knockback_speed
	if GameSettings and GameSettings.use_reduced_flashes():
		scale *= 0.7
	_knockback_velocity += direction.normalized() * recoil_speed * scale

func _apply_motion_with_knockback(delta: float) -> void:
	velocity += _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

func _is_heavy_hit(hit_kind: String, is_crit: bool) -> bool:
	if is_crit:
		return true
	return hit_kind in ["power", "sentinel", "sniper", "heavy"]

func _is_impact_excluded() -> bool:
	return is_in_group("objective_core") or is_in_group("reward_chest") or is_in_group("boss_root")

func _apply_overhead_presentation() -> void:
	if health_bar != null:
		_health_bar_base_top = health_bar.offset_top
		_health_bar_base_height = health_bar.offset_bottom - health_bar.offset_top
		var scaled_width: float = 28.0 * maxf(health_bar_scale.x, 0.1)
		health_bar.offset_left = -scaled_width * 0.5
		health_bar.offset_right = scaled_width * 0.5
		health_bar.offset_top = _health_bar_base_top
		health_bar.offset_bottom = _health_bar_base_top + _health_bar_base_height * maxf(health_bar_scale.y, 0.1)
		health_bar.modulate = health_bar_tint
	if nameplate != null:
		nameplate.visible = show_nameplate
		nameplate.text = display_name.to_upper()
		nameplate.modulate = nameplate_tint
