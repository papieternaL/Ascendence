shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_disabled, diffuse_burley, specular_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_disable;
uniform sampler2D normal_texture : hint_normal, filter_nearest, repeat_disable;
uniform bool use_albedo_texture = false;
uniform bool use_normal_texture = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.22;
uniform float lighting_mix : hint_range(0.0, 1.0) = 1.0;
uniform float unshaded_boost : hint_range(0.0, 1.0) = 0.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 texel = use_albedo_texture ? texture(albedo_texture, UV) : vec4(1.0);
	vec4 final_color = texel * tint;
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = final_color.rgb * unshaded_boost;
	if (use_normal_texture) {
		vec3 normal_tex = texture(normal_texture, UV).rgb * 2.0 - 1.0;
		NORMAL_MAP = mix(vec3(0.0, 0.0, 1.0), normal_tex, normal_strength);
		NORMAL_MAP_DEPTH = 1.0;
	}
}

void light() {
	float diffuse_term = max(dot(NORMAL, LIGHT), 0.0);
	vec3 lit_color = ALBEDO * LIGHT_COLOR.rgb * (ATTENUATION * diffuse_term);
	vec3 unlit_color = ALBEDO * LIGHT_COLOR.rgb * ATTENUATION;
	DIFFUSE_LIGHT += mix(unlit_color, lit_color, lighting_mix);
}

