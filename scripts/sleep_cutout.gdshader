shader_type canvas_item;
uniform bool small_sprite = false;
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
void fragment() {
	vec4 pixel;
	if (small_sprite) {
		#include "res://scripts/map_dog_ink.gdshaderinc"
	} else {
		pixel = texture(TEXTURE, UV);
		pixel.a = smoothstep(0.50, 0.76, pixel.a);
	}
	COLOR = pixel * item_tint;
}
