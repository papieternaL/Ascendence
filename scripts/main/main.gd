extends Node

@onready var arena: Node2D = $Arena
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var ui_layer: CanvasLayer = $UI
@onready var hud: Control = $UI/HUD
@onready var systems: Node = $Systems
@onready var damage_system: Node = $Systems/DamageSystem
@onready var cooldown_system: Node = $Systems/CooldownSystem
@onready var spawner: Node = $Systems/Spawner

func _ready() -> void:
	# TODO(Migration): Wire full bootstrap ordering for save/meta/profile + run-state systems.
	# `GameEvents` is available as an autoload singleton from project settings.
	if hud.has_method("bind_player"):
		hud.bind_player(player)
