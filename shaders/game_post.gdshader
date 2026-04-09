shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float r = dot(c, c);
	float vig = clamp(1.0 - r * vignette_strength * 3.5, 0.0, 1.0);
	/* Darken viewport edges slightly; center stays clear */
	COLOR = vec4(0.02, 0.03, 0.06, (1.0 - vig) * 0.38);
}
