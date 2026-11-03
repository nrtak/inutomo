shader_type canvas_item;
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Keep opaque fur and a short antialiased edge; ignore the soft outer haze.
	pixel.a = smoothstep(0.50, 0.76, pixel.a);
	COLOR = pixel * item_tint;
}
