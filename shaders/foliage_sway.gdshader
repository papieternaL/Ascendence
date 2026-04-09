shader_type canvas_item;

uniform float sway_strength_px : hint_range(0.0, 8.0) = 2.4;
uniform float sway_speed : hint_range(0.1, 4.0) = 1.15;
uniform float gust_strength_px : hint_range(0.0, 6.0) = 0.9;
uniform float detail_strength_px : hint_range(0.0, 3.0) = 0.4;
uniform float canopy_start : hint_range(0.0, 0.9) = 0.3;
uniform float phase_offset : hint_range(0.0, 6.28318) = 0.0;

void vertex() {
	float canopy_height = clamp(1.0 - UV.y, 0.0, 1.0);
	float canopy_mask = smoothstep(canopy_start, 1.0, canopy_height);
	float sway_wave = sin(TIME * sway_speed + phase_offset + canopy_height * 5.2) * sway_strength_px;
	float gust_wave = sin(TIME * (sway_speed * 0.57) + phase_offset * 1.7 + VERTEX.y * 0.05) * gust_strength_px;
	float detail_wave = sin(TIME * (sway_speed * 1.9) + phase_offset * 0.73 + VERTEX.x * 0.09) * detail_strength_px;
	float total_sway = (sway_wave + gust_wave + detail_wave) * canopy_mask;
	VERTEX.x += total_sway;
	VERTEX.y += abs(total_sway) * 0.10;
}
