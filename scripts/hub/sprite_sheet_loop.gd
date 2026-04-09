extends Sprite2D

@export_file("*.png") var sheet_path: String = ""
@export_range(1, 64, 1) var frame_count: int = 1
@export_range(0.0, 60.0, 0.1) var frames_per_second: float = 8.0
@export_range(0, 63, 1) var start_frame: int = 0
@export var randomize_start_frame: bool = true

var _animation_time: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_sheet_texture()
	hframes = max(frame_count, 1)
	vframes = 1
	var initial_frame: int = clampi(start_frame, 0, max(frame_count - 1, 0))
	if randomize_start_frame and frame_count > 1:
		initial_frame = randi() % frame_count
	_animation_time = float(initial_frame)
	frame = initial_frame
	set_process(frame_count > 1 and frames_per_second > 0.0 and texture != null)

func _process(delta: float) -> void:
	if texture == null or frame_count <= 1 or frames_per_second <= 0.0:
		return
	_animation_time += delta * frames_per_second
	frame = int(floor(_animation_time)) % frame_count

func _load_sheet_texture() -> void:
	if sheet_path.is_empty():
		return
	var loaded_texture: Texture2D = ResourceLoader.load(sheet_path) as Texture2D
	if loaded_texture == null:
		var global_path: String = ProjectSettings.globalize_path(sheet_path)
		if FileAccess.file_exists(global_path):
			var image: Image = Image.new()
			if image.load(global_path) == OK:
				loaded_texture = ImageTexture.create_from_image(image)
	if loaded_texture != null:
		texture = loaded_texture
