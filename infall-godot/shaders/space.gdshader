shader_type canvas_item;
// The space behind a cluster: three depths of stars, drifting nebula, a planet or star of the cluster, and,
// once it exists, the collapse glowing on the horizon. Everything moves with the camera at its own depth.

uniform vec2 camera_offset = vec2(0.0);
uniform float zoom = 1.0;
uniform float seed = 1.0;
uniform vec4 nebula_a : source_color = vec4(0.18, 0.08, 0.3, 1.0);
uniform vec4 nebula_b : source_color = vec4(0.05, 0.18, 0.32, 1.0);
uniform float nebula_amount = 0.6;
uniform vec2 planet_position = vec2(0.78, 0.3);
uniform float planet_radius = 0.16;
uniform vec4 planet_colour : source_color = vec4(0.75, 0.45, 0.35, 1.0);
uniform vec4 planet_shadow : source_color = vec4(0.12, 0.05, 0.08, 1.0);
uniform float planet_kind = 0.0;   // 0 none, 1 planet, 2 star
uniform vec2 light_direction = vec2(-0.6, -0.5);   // where the planet's sunlight comes from
uniform float collapse_glow = 0.0; // 0 to 1: how near the collapse is
uniform vec2 collapse_direction = vec2(-0.7, 0.7);
uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform float time = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21) + seed * 0.123);
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		total += noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

vec3 stars(vec2 uv, float density, float size, float brightness) {
	vec2 cell = floor(uv);
	vec2 local = fract(uv) - 0.5;
	float h = hash(cell);
	if (h > density) {
		return vec3(0.0);
	}
	vec2 jitter = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float d = length(local - jitter * 0.7);
	float twinkle = 0.75 + 0.25 * sin(time * (1.0 + h * 3.0) + h * 40.0);
	float core = smoothstep(size, 0.0, d) * brightness * twinkle;
	vec3 tint = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.85, 0.7), hash(cell + 1.3));
	return tint * core;
}

void fragment() {
	vec2 pixel = UV * screen_size;
	vec2 aspect_uv = pixel / screen_size.y;
	vec3 colour = vec3(0.008, 0.012, 0.028);
	// nebula, far back
	vec2 neb_uv = aspect_uv * 1.6 + camera_offset * 0.00004 + vec2(seed * 3.7, seed * 1.3);
	float n = fbm(neb_uv + vec2(time * 0.004, 0.0));
	float n2 = fbm(neb_uv * 1.9 - vec2(0.0, time * 0.003) + 5.0);
	float cloud = smoothstep(0.38, 0.9, n) * nebula_amount;
	colour += nebula_a.rgb * cloud * 0.9 + nebula_b.rgb * smoothstep(0.45, 0.95, n2) * nebula_amount * 0.8;
	colour += nebula_a.rgb * pow(cloud, 3.0) * 0.6;
	// collapse glow on the horizon
	if (collapse_glow > 0.0) {
		vec2 from_centre = (UV - 0.5) * vec2(screen_size.x / screen_size.y, 1.0);
		float toward = dot(normalize(from_centre + 0.0001), normalize(collapse_direction));
		float edge = smoothstep(0.2, 1.0, toward) * smoothstep(0.1, 1.0, length(from_centre));
		colour += vec3(0.9, 0.35, 0.12) * edge * collapse_glow * 0.35;
		colour = mix(colour, colour * vec3(0.6, 0.45, 0.7), edge * collapse_glow * 0.4);
	}
	// stars at three depths
	colour += stars(pixel * 0.012 + camera_offset * 0.0006, 0.16, 0.035, 0.75);
	colour += stars(pixel * 0.0065 + camera_offset * 0.0012 + 17.0, 0.10, 0.022, 1.1);
	colour += stars(pixel * 0.0032 + camera_offset * 0.0024 + 41.0, 0.08, 0.016, 1.6);
	// planet or star: far away, so it barely moves as the camera pans and doesn't grow with zoom
	if (planet_kind > 0.5) {
		vec2 p = (UV - planet_position - camera_offset * vec2(0.000006, 0.000008)) * vec2(screen_size.x / screen_size.y, 1.0);
		float d = length(p);
		if (planet_kind < 1.5) {
			float body = smoothstep(planet_radius, planet_radius - 0.006, d);
			vec2 light_dir = normalize(light_direction);
			float lit = clamp(dot(normalize(vec3(p, sqrt(max(0.0, planet_radius * planet_radius - d * d)))), normalize(vec3(light_dir, 0.6))), 0.0, 1.0);
			float bands = fbm(vec2(p.x * 5.0, p.y * 15.0) / planet_radius * 0.2 + seed);
			vec3 surface = mix(planet_shadow.rgb, planet_colour.rgb, lit) * (0.85 + 0.25 * bands);
			// distance haze: the planet takes on the colour of the space between, and loses contrast
			surface = mix(surface, colour + nebula_b.rgb * 0.25, 0.28);
			float atmosphere = smoothstep(planet_radius + 0.045, planet_radius, d) * (1.0 - body);
			colour = mix(colour, surface, body * 0.92);
			colour += planet_colour.rgb * atmosphere * 0.18 * (0.4 + lit);
		} else {
			float glow = exp(-d / max(0.001, planet_radius) * 2.2);
			colour += planet_colour.rgb * glow * 1.1;
			colour += vec3(1.0) * smoothstep(planet_radius * 0.3, 0.0, d) * 0.8;
		}
	}
	COLOR = vec4(colour, 1.0);
}
