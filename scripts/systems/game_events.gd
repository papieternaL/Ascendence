extends Node

signal enemy_killed(enemy: Node)
signal player_damaged(amount: float)
signal level_up(level: int)

# TODO(Migration): convert from global Lua callbacks to signal-driven events.
