shader_type spatial;
// Ground-projected danger zone. Shapes: 0 = circle, 1 = lane, 2 = arc.
// The fill sweeps outward as `progress` goes 0 -> 1; the hit lands at 1.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 color : source_color = vec4(1.0, 0.25, 0.2, 1.0);
uniform float progress = 0.0;
uniform int shape = 0;
uniform float radius = 1.0;
uniform float lane_length = 1.0;
uniform float lane_width = 1.0;
uniform float half_angle = 0.8;
uniform float edge_w = 0.08;

varying vec2 lp;

void vertex() {
	lp = VERTEX.xz;
}

void fragment() {
	float inside = 0.0;
	float edge = 0.0;
	float fill = 0.0;
	if (shape == 1) {
		float along = lp.x;
		float across = abs(lp.y);
		inside = step(0.0, along) * step(along, lane_length) * step(across, lane_width * 0.5);
		float de = min(min(along, lane_length - along), lane_width * 0.5 - across);
		edge = inside * (1.0 - smoothstep(0.0, edge_w, de));
		fill = inside * step(along, progress * lane_length);
	} else {
		float d = length(lp);
		inside = step(d, radius);
		float de = radius - d;
		if (shape == 2) {
			float ang = abs(atan(lp.y, lp.x));
			inside *= step(ang, half_angle);
			de = min(de, (half_angle - ang) * d);
		}
		edge = inside * (1.0 - smoothstep(0.0, edge_w, de));
		fill = inside * step(d, progress * radius);
	}
	float pulse = progress > 0.8 ? 0.5 + 0.5 * sin(TIME * 40.0) : 0.0;
	float a = inside * 0.16 + fill * (0.22 + 0.25 * progress) + edge * (0.75 + 0.25 * pulse);
	ALBEDO = mix(color.rgb, vec3(1.0, 0.9, 0.8), edge * 0.35 + fill * pulse * 0.2) * (1.0 + edge * 0.8);
	ALPHA = clamp(a, 0.0, 1.0) * color.a;
}
