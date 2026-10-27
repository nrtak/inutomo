shader_type canvas_item;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Keep opaque fur and a short antialiased edge; ignore the soft outer haze.
	pixel.a = smoothstep(0.50, 0.76, pixel.a);
	COLOR = pixel;
}
