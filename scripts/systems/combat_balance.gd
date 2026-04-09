class_name CombatBalance
extends RefCounted

const SCALE: float = 10.0

const PLAYER_MAX_HEALTH: float = 100.0 * SCALE

const ARCHER_BASE_DAMAGE: float = 10.0 * SCALE
const ARCANE_PISTOL_BASE_DAMAGE: float = 4.0 * SCALE
const ARCANE_SNIPER_BASE_DAMAGE: float = 38.0 * SCALE
const BURN_TICK_DAMAGE: float = 2.0 * SCALE

const FALLING_TRUNK_DAMAGE_PHASE1: float = 40.0 * SCALE
const FALLING_TRUNK_DAMAGE_PHASE2: float = 60.0 * SCALE
const BARK_WAVE_DAMAGE: float = 24.0 * SCALE
const BARK_VOLLEY_DAMAGE: float = 25.0 * SCALE
const TERRITORY_LANE_DAMAGE: float = 55.0 * SCALE

static func scale(value: float) -> float:
	return value * SCALE
