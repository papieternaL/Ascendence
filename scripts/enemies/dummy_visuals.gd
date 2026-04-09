class_name DummyVisuals
extends RefCounted

static func draw_training_dummy(
	target: CanvasItem,
	flash_remaining: float,
	flash_duration_current: float,
	hit_reaction_remaining: float,
	hit_reaction_duration_current: float,
	hit_reaction_direction: Vector2,
	hit_reaction_intensity: float,
	ring_color: Color
) -> void:
	var flash_mix: float = clamp(flash_remaining / max(flash_duration_current, 0.001), 0.0, 1.0)
	var reaction_mix: float = clamp(hit_reaction_remaining / max(hit_reaction_duration_current, 0.001), 0.0, 1.0)
	var draw_offset: Vector2 = hit_reaction_direction * (1.4 * hit_reaction_intensity * reaction_mix)
	var scale_x: float = 1.0 + (0.08 * hit_reaction_intensity * reaction_mix)
	var scale_y: float = 1.0 - (0.04 * hit_reaction_intensity * reaction_mix)
	var straw: Color = Color(0.90, 0.76, 0.42, 1.0).lerp(Color(1.0, 0.94, 0.88, 1.0), flash_mix)
	var straw_shadow: Color = Color(0.74, 0.58, 0.28, 1.0).lerp(Color(0.96, 0.86, 0.66, 1.0), flash_mix * 0.65)
	var wood: Color = Color(0.45, 0.28, 0.13, 1.0).lerp(Color(0.72, 0.48, 0.22, 1.0), flash_mix * 0.5)
	target.draw_set_transform(draw_offset, 0.0, Vector2(scale_x, scale_y))
	target.draw_circle(Vector2(0.0, 14.0), 18.0, Color(0.04, 0.05, 0.07, 0.26))
	target.draw_rect(Rect2(Vector2(-7.0, 30.0), Vector2(14.0, 12.0)), wood, true)
	target.draw_rect(Rect2(Vector2(-20.0, 40.0), Vector2(40.0, 5.0)), wood.darkened(0.08), true)
	target.draw_line(Vector2(0.0, -18.0), Vector2(0.0, 30.0), wood, 6.0, true)
	target.draw_line(Vector2(-13.0, 4.0), Vector2(13.0, 4.0), wood, 4.0, true)
	target.draw_circle(Vector2(0.0, -22.0), 10.5, straw)
	target.draw_circle(Vector2(0.0, -22.0), 6.4, straw_shadow.lightened(0.12))
	target.draw_rect(Rect2(Vector2(-13.0, -6.0), Vector2(26.0, 28.0)), straw, true)
	target.draw_rect(Rect2(Vector2(-9.0, -2.0), Vector2(18.0, 20.0)), straw_shadow, true)
	target.draw_line(Vector2(-11.0, 26.0), Vector2(-18.0, 38.0), wood, 3.0, true)
	target.draw_line(Vector2(11.0, 26.0), Vector2(18.0, 38.0), wood, 3.0, true)
	target.draw_circle(Vector2(0.0, 8.0), 12.0, Color(0.94, 0.90, 0.84, 0.92))
	target.draw_arc(Vector2(0.0, 8.0), 12.0, 0.0, TAU, 28, ring_color, 3.0)
	target.draw_arc(Vector2(0.0, 8.0), 6.0, 0.0, TAU, 24, Color(0.96, 0.92, 0.84, 0.96), 2.0)
	target.draw_circle(Vector2(0.0, 8.0), 2.6, ring_color.lightened(0.3))
	target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
