shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float pulse_strength : hint_range(0.0, 1.5) = 0.28;
uniform float pulse_speed : hint_range(0.0, 24.0) = 8.0;
uniform float shimmer_amount : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	vec4 base = COLOR * tint;
	float pulse = 1.0 + sin(TIME * pulse_speed + SCREEN_UV.x * 48.0 + SCREEN_UV.y * 34.0) * pulse_strength;
	float shimmer = 1.0 + sin(TIME * (pulse_speed * 0.6) + SCREEN_UV.y * 92.0) * shimmer_amount;
	base.rgb *= pulse * shimmer;
	base.a *= tint.a;
	COLOR = base;
}
