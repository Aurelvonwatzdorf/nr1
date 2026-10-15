shader_type spatial;
// Gebäude im gezeichneten Look: Toon-Licht plus Fenster, die nachts leuchten.
// Die Fenster entstehen aus der Weltposition (keine Textur nötig). Farbe und
// Fensterdichte setzt jedes Gebäude selbst (instance uniform), so reicht ein
// einziges Material für die ganze Stadt.
render_mode diffuse_toon, specular_toon;

instance uniform vec4 wall_color : source_color = vec4(0.6, 0.6, 0.62, 1.0);
// 0 = keine Fenster (Ruinen), 1 = alle Fenster da.
instance uniform float window_density = 0.6;
// Anteil der Fenster, in denen Licht brennt.
instance uniform float lit_ratio = 0.35;
// Abstand der Fenster (Meter): x waagerecht, y senkrecht.
instance uniform vec2 window_spacing = vec2(2.6, 3.2);

uniform vec3 warm_light : source_color = vec3(1.0, 0.78, 0.45);
uniform vec3 cool_light : source_color = vec3(0.45, 0.85, 1.0);

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 base = wall_color.rgb;
	vec3 emission = vec3(0.0);
	// Nur senkrechte Flächen bekommen Fenster.
	if (abs(world_normal.y) < 0.3 && window_density > 0.0) {
		vec2 side = normalize(vec2(-world_normal.z, world_normal.x));
		vec2 coord = vec2(dot(world_pos.xz, side), world_pos.y - 0.8);
		vec2 cell = floor(coord / window_spacing);
		vec2 inside = fract(coord / window_spacing);
		bool is_window = inside.x > 0.25 && inside.x < 0.75 && inside.y > 0.3 && inside.y < 0.8 && coord.y > 0.6;
		float pick = hash(cell + floor(world_pos.xz * 0.02) * 17.0);
		if (is_window && pick < window_density) {
			base *= 0.35;
			float lit = hash(cell * 1.7 + 3.1);
			if (lit < lit_ratio) {
				vec3 light = mix(warm_light, cool_light, step(0.7, hash(cell + 9.3)));
				emission = light * 1.6;
				base = light * 0.5;
			}
		}
	}
	ALBEDO = base;
	EMISSION = emission;
	ROUGHNESS = 0.9;
}
