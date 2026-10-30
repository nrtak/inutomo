shader_type canvas_item;
uniform vec4 tone : source_color = vec4(1.0);
uniform float exposure : hint_range(0.0, 1.2) = 1.0;
uniform float coolness : hint_range(0.0, 1.0) = 0.0;
uniform vec4 lamp_0 = vec4(0.0);
uniform vec4 lamp_1 = vec4(0.0);
uniform vec4 lamp_2 = vec4(0.0);
uniform vec4 lamp_3 = vec4(0.0);
varying vec4 art_modulate;
float lamp_glow(vec2 point, vec4 lamp) {
	if (lamp.z <= 0.0 || lamp.w <= 0.0) { return 0.0; }
	float radius = length((point - lamp.xy) / lamp.zw);
	return exp(-radius * radius * 2.8);
}
void vertex() {
	art_modulate = COLOR;
}
void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float luminance = dot(art.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 night_color = mix(art.rgb, vec3(luminance), coolness * 0.42);
	vec3 lighting = night_color * mix(vec3(1.0), tone.rgb, 0.24) * max(exposure, 0.90);
	float warmth = clamp(lamp_glow(UV, lamp_0) + lamp_glow(UV, lamp_1) + lamp_glow(UV, lamp_2) + lamp_glow(UV, lamp_3), 0.0, 1.0);
	float evening = 1.0 - smoothstep(0.85, 0.98, exposure);
	vec3 lamplight = art.rgb * vec3(1.0, 0.93, 0.80) + vec3(0.14, 0.075, 0.025);
	lighting = mix(lighting, lamplight, warmth * evening * 0.90);
	COLOR = vec4(lighting, art.a) * art_modulate;
}
