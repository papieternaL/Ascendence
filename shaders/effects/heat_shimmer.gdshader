shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tint : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float heat_strength : hint_range(0.0, 1.5) = 0.34;
uniform float flicker_speed : hint_range(0.0, 30.0) = 11.0;

void fragment() {
	vec4 base = COLOR * tint;
	float band = sin(SCREEN_UV.y * 180.0 + TIME * flicker_speed) * 0.5 + 0.5;
	float flicker = sin(TIME * (flicker_speed * 1.7) + SCREEN_UV.x * 96.0) * 0.5 + 0.5;
	float glow = 0.86 + band * heat_strength + flicker * 0.18;
	base.rgb *= glow;
	base.a *= 0.84 + flicker * 0.18;
	COLOR = base;
}
