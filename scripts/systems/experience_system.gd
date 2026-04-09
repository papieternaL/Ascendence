extends RefCounted
class_name ExperienceSystem

var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 100
var pending_level_ups: int = 0

func _init() -> void:
	xp_to_next = get_xp_required_for_level(level)

func add_xp(amount: int) -> void:
	var gained: int = max(amount, 0)
	current_xp += gained
	if gained > 0:
		GameEvents.xp_collected.emit(gained)
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		pending_level_ups += 1
		xp_to_next = get_xp_required_for_level(level)
		GameEvents.level_up.emit(level)

func get_xp_required_for_level(target_level: int) -> int:
	var clamped_level: int = maxi(target_level, 1)
	var locked_requirements: Array[int] = [100, 130, 164, 203, 247, 297, 354]
	if clamped_level <= locked_requirements.size():
		return locked_requirements[clamped_level - 1]
	var scaled: float = 100.0 * pow(1.20, float(clamped_level - 1))
	var linear_bonus: float = 10.0 * float(clamped_level - 1)
	return int(floor(scaled + linear_bonus))

func has_pending_level_up() -> bool:
	return pending_level_ups > 0

func consume_level_up() -> bool:
	if pending_level_ups <= 0:
		return false
	pending_level_ups -= 1
	return true

func get_progress() -> float:
	if xp_to_next <= 0:
		return 1.0
	return clamp(float(current_xp) / float(xp_to_next), 0.0, 1.0)
