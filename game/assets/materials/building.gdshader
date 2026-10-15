shader_type spatial;
// Die ganze Stadt in einem Material (gezeichneter Look: Toon-Licht).
// Damit die Grafikkarte wenig Arbeit hat, fasst der CityGenerator viele Teile zu
// wenigen großen Meshes zusammen. Was jedes Teil braucht, steht in den Ecken:
//   COLOR.rgb = Farbe, COLOR.a = 1 / (1 + Leuchtkraft)  (1 = leuchtet nicht)
//   UV.x = Fensterdichte (0 = keine), UV.y = Anteil erleuchteter Fenster
//   UV2  = Fensterabstand (Meter: waagerecht, senkrecht)
// Die Fenster entstehen aus der Weltposition (keine Textur nötig).
render_mode diffuse_toon, specular_toon;

uniform vec3 warm_light : source_color = vec3(1.0, 0.78, 0.45);
uniform vec3 cool_light : source_color = vec3(0.45, 0.85, 1.0);

varying vec3 world_pos;
varying vec3 world_normal;
varying vec4 tint;
varying vec2 window_data;
varying vec2 spacing;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tint = COLOR;
	window_data = UV;
	spacing = max(UV2, vec2(0.5));
}

void fragment() {
	vec3 base = tint.rgb;
	vec3 emission = vec3(0.0);
	float glow = 1.0 / max(tint.a, 0.05) - 1.0;
	if (glow > 0.05) {
		emission = base * glow;
	} else if (abs(world_normal.y) < 0.3 && window_data.x > 0.0) {
		// Nur senkrechte Flächen bekommen Fenster.
		vec2 side = normalize(vec2(-world_normal.z, world_normal.x));
		vec2 coord = vec2(dot(world_pos.xz, side), world_pos.y - 0.8);
		vec2 cell = floor(coord / spacing);
		vec2 inside = fract(coord / spacing);
		bool is_window = inside.x > 0.25 && inside.x < 0.75 && inside.y > 0.3 && inside.y < 0.8 && coord.y > 0.6;
		float pick = hash(cell + floor(world_pos.xz * 0.02) * 17.0);
		if (is_window && pick < window_data.x) {
			base *= 0.35;
			if (hash(cell * 1.7 + 3.1) < window_data.y) {
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
