shader_type spatial;
// Stylized stone tiles: per-tile tint variation, soft mortar lines and a vignette
// toward the room edges so the play area reads clearly.
uniform vec4 base_color : source_color = vec4(0.22, 0.2, 0.25, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.12, 0.11, 0.14, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.45, 0.15, 1.0);
uniform float tile = 2.0;
uniform vec2 room_size = vec2(30.0, 24.0);

varying vec3 wp;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz / tile;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float h = hash(id);
	float m = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float mortar = 1.0 - smoothstep(0.015, 0.05, m);
	vec3 c = base_color.rgb * (0.86 + 0.22 * h);
	c = mix(c, mortar_color.rgb, mortar);
	vec2 q = wp.xz / room_size;
	float edge = min(min(q.x, 1.0 - q.x), min(q.y, 1.0 - q.y));
	c *= mix(0.55, 1.0, smoothstep(0.0, 0.18, edge));
	ALBEDO = c;
	ROUGHNESS = 0.85 - 0.2 * h;
}
