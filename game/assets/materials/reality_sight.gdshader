shader_type canvas_item;
// Realitätsblick: Die Welt verliert ihre Farbe, Ränder flimmern bläulich,
// leichte Farbverschiebung wie ein Riss im Bild.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.45, 0.85, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
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
	COLOR = vec4(mix(color, truth, strength), 1.0);
}
