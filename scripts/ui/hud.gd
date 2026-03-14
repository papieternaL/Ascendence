extends Control

@onready var health_bar: ProgressBar = $HealthBar/ProgressBar
@onready var cooldown_bar: ProgressBar = $CooldownBar/ProgressBar
@onready var top_bar: MarginContainer = $TopBar

var _player: Node
var _cooldown_system: Node
var _primary_key: StringName
var _missiles_key: StringName
var _cooldown_label: Label

func _ready() -> void:
	_cooldown_label = Label.new()
	_cooldown_label.text = "Arcane Missiles: Ready"
	top_bar.add_child(_cooldown_label)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	cooldown_bar.max_value = 1.0
	cooldown_bar.value = 1.0

func bind_player(player: Node) -> void:
	_player = player
	var max_hp := float(player.get("max_health"))
	if max_hp > 0.0:
		health_bar.max_value = max_hp

func bind_cooldown_system(cooldown_system: Node, primary_key: StringName, missiles_key: StringName) -> void:
	_cooldown_system = cooldown_system
	_primary_key = primary_key
	_missiles_key = missiles_key

func _process(_delta: float) -> void:
	_update_health()
	_update_cooldowns()

func _update_health() -> void:
	if _player == null:
		return
	var value := _player.get("health")
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		health_bar.value = float(value)

func _update_cooldowns() -> void:
	if _cooldown_system == null:
		return
	var primary_remaining := float(_cooldown_system.call("get_remaining", _primary_key))
	var missiles_remaining := float(_cooldown_system.call("get_remaining", _missiles_key))
	cooldown_bar.value = 1.0 if primary_remaining <= 0.0 else 0.15
	if missiles_remaining <= 0.0:
		_cooldown_label.text = "Arcane Missiles: Ready (E)"
	else:
		_cooldown_label.text = "Arcane Missiles: %.1fs" % missiles_remaining
