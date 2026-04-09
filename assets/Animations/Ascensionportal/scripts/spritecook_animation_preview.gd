extends Node2D

@export_file("*.json") var metadata_path: String = "res://SpriteCook/animation_export.spritecook.json"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    var config = SpriteCookSheetLoader.load_json(metadata_path)
    var sheet_path = String(config.get("metadata_path", ""))
    if sheet_path.is_empty():
        return

    var result = SpriteCookSheetLoader.build_sprite_frames(sheet_path)
    if result.is_empty():
        return

    animated_sprite.sprite_frames = result["sprite_frames"]
    animated_sprite.animation = String(result["animation_name"])
    animated_sprite.play()
