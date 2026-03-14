extends Control

@onready var health_bar: ProgressBar = $HealthBar/ProgressBar

var _player: Node

func bind_player(player: Node) -> void:
	_player = player
	# TODO(Migration): subscribe HUD widgets to player stats + cooldown resources.

func _process(_delta: float) -> void:
	if _player == null:
		return
	var value := _player.get("health")
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		health_bar.value = float(value)
