shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_alpha_prepass, shadows_disabled;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.34);
uniform float softness : hint_range(0.01, 1.0) = 0.28;
uniform float ellipse_scale : hint_range(0.2, 2.0) = 0.72;

void fragment() {
	vec2 centered = UV * 2.0 - vec2(1.0);
	centered.x /= max(ellipse_scale, 0.001);
	float dist = length(centered);
	float alpha = 1.0 - smoothstep(1.0 - softness, 1.0, dist);
	ALBEDO = shadow_color.rgb;
	ALPHA = shadow_color.a * alpha;
}

