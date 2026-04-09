extends RefCounted
class_name SpriteCookSheetLoader

static func load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_warning("[SpriteCook] Missing JSON metadata: %s" % path)
        return {}

    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("[SpriteCook] Invalid JSON metadata: %s" % path)
        return {}

    return parsed

static func load_animation_sheet(metadata_path: String) -> Dictionary:
    var metadata = load_json(metadata_path)
    var texture_path = String(metadata.get("texture_path", ""))
    var texture = load(texture_path) as Texture2D
    if texture == null:
        push_warning("[SpriteCook] Missing texture: %s" % texture_path)
        return {}

    var animation_name = String(metadata.get("animation_name", "Animation"))
    var frame_width = int(metadata.get("frame_width", 0))
    var frame_height = int(metadata.get("frame_height", 0))
    var frame_count = int(metadata.get("frame_count", 0))
    var fps = max(1, int(metadata.get("fps", 8)))
    if frame_width <= 0 or frame_height <= 0 or frame_count <= 0:
        push_warning("[SpriteCook] Invalid frame data: %s" % metadata_path)
        return {}

    var frames: Array[Texture2D] = []
    for index in range(frame_count):
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(index * frame_width, 0, frame_width, frame_height)
        frames.append(atlas)

    return {
        "animation_name": animation_name,
        "frame_width": frame_width,
        "frame_height": frame_height,
        "fps": fps,
        "recognized_state": metadata.get("recognized_state", ""),
        "frames": frames,
    }

static func build_sprite_frames(metadata_path: String) -> Dictionary:
    var animation_data = load_animation_sheet(metadata_path)
    if animation_data.is_empty():
        return {}

    var animation_name = String(animation_data.get("animation_name", "Animation"))
    var fps = int(animation_data.get("fps", 8))
    var frames = animation_data.get("frames", [])
    var sprite_frames := SpriteFrames.new()
    sprite_frames.add_animation(animation_name)
    sprite_frames.set_animation_speed(animation_name, fps)
    sprite_frames.set_animation_loop(animation_name, true)
    for frame in frames:
        sprite_frames.add_frame(animation_name, frame)

    return {
        "animation_name": animation_name,
        "sprite_frames": sprite_frames,
        "frame_width": animation_data.get("frame_width", 0),
        "frame_height": animation_data.get("frame_height", 0),
    }

static func build_character_frames(package_path: String) -> Dictionary:
    var package_data = load_json(package_path)
    var animation_paths = package_data.get("animations", {})
    if typeof(animation_paths) != TYPE_DICTIONARY:
        return {}

    var sprite_frames := SpriteFrames.new()
    var frame_width = 0
    var frame_height = 0

    for state_name in ["Idle", "Walk", "Run", "Jump", "Fall"]:
        var metadata_path = String(animation_paths.get(state_name, ""))
        if metadata_path.is_empty():
            continue

        var animation_data = load_animation_sheet(metadata_path)
        if animation_data.is_empty():
            continue

        if not sprite_frames.has_animation(state_name):
            sprite_frames.add_animation(state_name)
        sprite_frames.set_animation_speed(state_name, int(animation_data.get("fps", 8)))
        sprite_frames.set_animation_loop(state_name, true)

        if frame_width <= 0:
            frame_width = int(animation_data.get("frame_width", 0))
        if frame_height <= 0:
            frame_height = int(animation_data.get("frame_height", 0))

        for frame in animation_data.get("frames", []):
            sprite_frames.add_frame(state_name, frame)

    return {
        "source_character_name": String(package_data.get("source_character_name", "Character")),
        "sprite_frames": sprite_frames,
        "frame_width": frame_width,
        "frame_height": frame_height,
    }
