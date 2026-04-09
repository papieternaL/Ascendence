extends Resource
class_name BossConfig

## Treent Overlord boss tuning (Love2D parity).
## Assign via @export in treent_boss.gd; falls back to script defaults if null.

@export_group("Base Stats")
@export var max_health: float = 3500.0
@export var move_speed: float = 65.0
@export var contact_damage: float = 40.0
@export var xp_reward: int = 220

@export_group("Lunge")
@export var lunge_cooldown: float = 1.1
@export var lunge_charge_duration: float = 0.6
@export var lunge_duration: float = 0.28
@export var lunge_speed: float = 900.0
@export var phase_two_lunge_mult: float = 0.75

@export_group("Bark Barrage")
@export var bark_cooldown: float = 1.8
@export var bark_shots_per_burst: int = 6
@export var bark_delay: float = 0.06
@export var phase_two_bark_mult: float = 0.80

@export_group("Phase 2 - Encompass Root")
@export var phase_two_root_cooldown: float = 8.5
@export var root_duration: float = 1.4
@export var territory_duration: float = 2.8
