extends Node

signal enemy_killed(enemy: Node)
signal enemy_died(enemy: Node)
signal player_damaged(amount: float)
signal ability_used(ability_id: StringName)
signal xp_collected(amount: int)
signal wave_started(wave_number: int)
signal level_up(level: int)

# TODO(Migration): convert from global Lua callbacks to signal-driven events.
