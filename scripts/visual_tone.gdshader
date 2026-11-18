shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
#include "res://scripts/visual_tone_values.gdshaderinc"

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float luminance = dot(color, ISLAND_LUMA);
	color = mix(vec3(luminance), color, ISLAND_SATURATION);
	// Roll off bright paper, sky, and sunlit fur while retaining dark ink lines.
	color -= ISLAND_HIGHLIGHT_SOFTNESS * color * color;
	COLOR = vec4(color, 1.0);
}
