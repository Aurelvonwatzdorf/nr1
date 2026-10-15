shader_type spatial;
// Dunkler Umriss (gezeichneter Look): die Rückseiten etwas aufgebläht zeichnen.
// Für zusammengefasste Meshes, deren Normalen nicht immer die Länge 1 haben.
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.05, 0.04, 0.07, 1.0);
uniform float width = 0.03;

void vertex() {
	VERTEX += normalize(NORMAL) * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
