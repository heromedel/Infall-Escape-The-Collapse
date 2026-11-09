shader_type canvas_item;
// The space behind a cluster: three depths of stars, drifting nebula, a planet or star of the cluster, and,
// once it exists, the collapse glowing on the horizon. The nebula and the planet are real (GV 3I): each pixel finds
// the real place in the battle it shows (back through the camera and out of the squeezed gap) and shows the space
// behind it, at the background's depth. So a planet big behind one squad shows squeezed in the bar and barely, or
// not at all, behind the other. The stars are so far off they look the same from anywhere.

uniform vec2 camera_offset = vec2(0.0);
uniform float zoom = 1.0;
uniform float seed = 1.0;
uniform vec4 nebula_a : source_color = vec4(0.18, 0.08, 0.3, 1.0);
uniform vec4 nebula_b : source_color = vec4(0.05, 0.18, 0.32, 1.0);
uniform float nebula_amount = 0.6;
uniform vec2 planet_position = vec2(0.0, 6000.0);   // in the background's own units (real pixels times depth)
uniform float planet_radius = 1000.0;
uniform vec4 planet_colour : source_color = vec4(0.75, 0.45, 0.35, 1.0);
uniform vec4 planet_shadow : source_color = vec4(0.12, 0.05, 0.08, 1.0);
uniform float planet_kind = 0.0;   // 0 none, 1 planet, 2 star
uniform vec2 light_direction = vec2(-0.6, -0.5);   // where the planet's sunlight comes from
uniform float collapse_glow = 0.0; // 0 to 1: how near the collapse is
uniform vec2 collapse_direction = vec2(-0.7, 0.7);
uniform vec2 screen_size = vec2(1920.0, 1080.0);
// From a screen pixel to the view (the inverse of the camera's canvas transform), and the squeezed gap
uniform vec2 view_x = vec2(1.0, 0.0);
uniform vec2 view_y = vec2(0.0, 1.0);
uniform vec2 view_origin = vec2(0.0);
uniform float squeezed_half = 2290.0;   // half the squeezed part of the gap, real pixels
uniform float bar_scale = 10.0;
uniform float depth = 0.3;              // how far back the nebula and planet are: real pixels to background units
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

// The real place a view point shows: the inverse of Encounter.to_view.
vec2 to_real(vec2 view_point) {
	float bar = squeezed_half / bar_scale;
	float y = view_point.y;
	if (abs(y) <= bar) {
		return vec2(view_point.x, y * bar_scale);
	}
	return vec2(view_point.x, sign(y) * (abs(y) - bar + squeezed_half));
}

void fragment() {
	vec2 pixel = UV * screen_size;
	vec2 aspect_uv = pixel / screen_size.y;
	vec2 view_point = view_origin + view_x * pixel.x + view_y * pixel.y;
	vec2 back = to_real(view_point) * depth;   // where this pixel looks, in the background's units
	vec3 colour = vec3(0.008, 0.012, 0.028);
	// nebula, far back, fixed in real space
	vec2 neb_uv = back / 1400.0 + vec2(seed * 3.7, seed * 1.3);
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
	// planet or star, fixed in real space behind the battle: lit softly from the side facing the battle, its night
	// side melting into the dark, seen through the haze and the nebula between, with a thin lit rim of air.
	if (planet_kind > 0.5) {
		vec2 q = (back - planet_position) / planet_radius;   // the planet's disc is the unit circle
		float d = length(q);
		float soft = max(fwidth(d) * 1.5, 0.002);
		vec2 light_dir = normalize(-planet_position + vec2(0.001));   // lit on the side facing the battle
		if (planet_kind < 1.5) {
			vec3 behind = colour;
			float body = smoothstep(1.0 + soft, 1.0 - soft, d);
			vec3 normal = normalize(vec3(q, sqrt(max(0.0, 1.0 - d * d))));
			vec3 light = normalize(vec3(light_dir, 0.45));
			float lit = smoothstep(-0.25, 0.9, dot(normal, light));
			float limb = pow(clamp(normal.z, 0.0, 1.0), 0.45);
			vec2 surface_uv = vec2(q.x, q.y * 2.6) * 2.2 + seed;
			float warp = fbm(surface_uv * 0.8 + vec2(time * 0.002, 0.0));
			float bands = fbm(vec2(surface_uv.x * 0.6 + warp * 1.4, surface_uv.y * 1.6));
			vec3 surface = mix(planet_colour.rgb * 0.75, planet_colour.rgb * 1.08, bands);
			surface = mix(planet_shadow.rgb, surface, lit) * mix(0.55, 1.0, limb);
			surface = mix(surface, behind * 0.35 + nebula_b.rgb * 0.06, (1.0 - lit) * 0.7);
			float haze = 0.32 + 0.25 * (1.0 - limb);
			surface = mix(surface, behind + nebula_a.rgb * 0.12 + nebula_b.rgb * 0.18, haze);
			colour = mix(colour, surface, body);
			float rim = smoothstep(1.07, 0.995, d) * smoothstep(0.93, 1.0, d);
			colour += mix(planet_colour.rgb, vec3(0.75, 0.85, 1.0), 0.4) * rim * smoothstep(-0.1, 0.8, dot(normalize(q + vec2(0.0001)), light_dir)) * 0.22;
			float front = smoothstep(0.55, 0.95, fbm(back / 900.0 + vec2(seed * 2.1, time * 0.002) + 9.0)) * nebula_amount;
			colour += (nebula_a.rgb * 0.5 + nebula_b.rgb * 0.4) * front * body * 0.6;
		} else {
			float glow = exp(-d * 2.2);
			colour += planet_colour.rgb * glow * 1.1;
			colour += vec3(1.0) * smoothstep(0.3, 0.0, d) * 0.8;
		}
	}
	// A whisper of grain so the gradients don't band
	colour += (hash(pixel + time) - 0.5) * 0.008;
	COLOR = vec4(colour, 1.0);
}
