shader_type canvas_item;
// Realitätsblick: Die Welt verliert ihre Farbe, Ränder flimmern bläulich,
// leichte Farbverschiebung wie ein Riss im Bild.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Verankerung: Die Wahrnehmung verzerrt sich (0 = klar, 1 = ganz verankert).
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
// Spiritueller Druck: Bild verschwimmt und dunkelt vom Rand her ein.
uniform float pressure : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.45, 0.85, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	uv += vec2(sin(uv.y * 18.0 + TIME * 1.3), cos(uv.x * 14.0 + TIME)) * 0.004 * distortion;
	vec2 offset = (uv - 0.5) * 0.006 * strength;
	vec3 color;
	color.r = texture(screen_texture, uv + offset).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - offset).b;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 truth = mix(vec3(gray), tint * gray * 1.4, 0.35);
	float edge = smoothstep(0.35, 0.75, length(uv - 0.5));
	float pulse = 0.5 + 0.5 * sin(TIME * 3.0);
	truth += tint * edge * (0.25 + 0.15 * pulse);
	vec3 result = mix(color, truth, strength);
	float flat_gray = dot(result, vec3(0.299, 0.587, 0.114));
	result = mix(result, vec3(flat_gray) * vec3(1.0, 0.97, 0.9), distortion * 0.6);
	if (pressure > 0.0) {
		vec2 spread = vec2(0.006, 0.004) * pressure * (1.0 + 0.3 * sin(TIME * 4.0));
		vec3 blurred = (texture(screen_texture, uv + spread).rgb + texture(screen_texture, uv - spread).rgb
			+ texture(screen_texture, uv + spread.yx).rgb + texture(screen_texture, uv - spread.yx).rgb) * 0.25;
		result = mix(result, blurred, pressure);
		float dark = smoothstep(0.25, 0.75, length(uv - 0.5)) * pressure;
		result = mix(result, vec3(0.9, 0.85, 0.7) * 0.15, dark);
	}
	COLOR = vec4(result, 1.0);
}
