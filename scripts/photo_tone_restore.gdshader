shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/visual_tone_values.gdshaderinc"

varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// New photos already contain the screen finish. Undo it before the shared pass
	// so album pictures receive the same finish once, rather than becoming duller.
	vec3 restored = 2.0 * pixel.rgb / (1.0 + sqrt(max(vec3(0.0), 1.0 - 4.0 * ISLAND_HIGHLIGHT_SOFTNESS * pixel.rgb)));
	float luminance = dot(restored, ISLAND_LUMA);
	restored = mix(vec3(luminance), restored, 1.0 / ISLAND_SATURATION);
	COLOR = vec4(clamp(restored, vec3(0.0), vec3(1.0)), pixel.a) * item_tint;
}
