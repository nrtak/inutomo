shader_type canvas_item;
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
uniform vec4 bandana : source_color = vec4(0.20, 0.62, 0.58, 1.0);
uniform bool recolor = false;
uniform bool sleeping_cutout = false;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (recolor && pixel.g > pixel.r * 1.25 && pixel.b > pixel.r * 1.15 && pixel.g > pixel.b * 0.8 && max(pixel.g, pixel.b) - pixel.r > 0.06) {
		float shade = clamp(max(pixel.g, pixel.b) / 0.65, 0.25, 1.25);
		pixel.rgb = bandana.rgb * shade;
	}
	// Registered poses share a clean edge, including newly added trick sheets.
	pixel.a = smoothstep(0.38, 0.76, pixel.a);
	COLOR = pixel * item_tint;
}
