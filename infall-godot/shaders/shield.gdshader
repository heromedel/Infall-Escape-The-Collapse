shader_type canvas_item;
// The shield bubble: a soft ellipse with a bright rim, a faint moving lattice, and ripples where shots hit.

uniform vec4 tint : source_color = vec4(0.35, 0.66, 1.0, 1.0);
uniform float strength = 0.6;
uniform float time = 0.0;
uniform vec2 hit_points[4];
uniform float hit_ages[4];

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float inside = 1.0 - smoothstep(0.9, 0.93, d);
	float rim = smoothstep(0.6, 0.92, d) * inside;
	float lattice = 0.5 + 0.5 * sin((p.x * 26.0 + p.y * 15.0) + time * 0.6) * sin((p.y * 30.0 - p.x * 15.0) - time * 0.4);
	lattice = smoothstep(0.75, 1.0, lattice) * 0.25;
	float ripple = 0.0;
	for (int i = 0; i < 4; i++) {
		float age = hit_ages[i];
		if (age < 1.2) {
			float dist = distance(UV, hit_points[i]);
			float wave = age * 0.55;
			float ring = smoothstep(0.06, 0.0, abs(dist - wave)) * (1.0 - age / 1.2);
			float flash = smoothstep(0.18, 0.0, dist) * max(0.0, 1.0 - age * 3.0);
			ripple += (ring * 1.2 + flash * 1.6);
		}
	}
	float alpha = (0.05 + rim * 0.55 + lattice * rim) * strength + ripple * inside * max(strength, 0.6);
	vec3 colour = mix(tint.rgb, vec3(1.0), clamp(ripple * 0.6 + rim * 0.25, 0.0, 1.0));
	COLOR = vec4(colour, clamp(alpha, 0.0, 1.0) * inside);
}
