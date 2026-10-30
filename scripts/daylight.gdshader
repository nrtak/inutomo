shader_type canvas_item;
uniform vec4 tone : source_color = vec4(1.0);
uniform float exposure : hint_range(0.0, 1.2) = 1.0;
uniform float coolness : hint_range(0.0, 1.0) = 0.0;
uniform vec4 lamp_0 = vec4(0.0);
uniform vec4 lamp_1 = vec4(0.0);
uniform vec4 lamp_2 = vec4(0.0);
uniform vec4 lamp_3 = vec4(0.0);
uniform vec4 water_area = vec4(0.0);
uniform vec4 foliage_a = vec4(0.0);
uniform vec4 foliage_b = vec4(0.0);
uniform vec4 falls_a = vec4(0.0);
uniform vec4 falls_b = vec4(0.0);
uniform bool island_land_mask = false;
varying vec4 art_modulate;
float area_mask(vec2 point, vec4 area) {
 if (area.z <= 0.0 || area.w <= 0.0) { return 0.0; }
 vec2 q = (point-area.xy)/area.zw;
 return smoothstep(0.0,0.12,q.x)*smoothstep(0.0,0.12,q.y)*(1.0-smoothstep(0.88,1.0,q.x))*(1.0-smoothstep(0.88,1.0,q.y));
}
float lamp_glow(vec2 point, vec4 lamp) {
	if (lamp.z <= 0.0 || lamp.w <= 0.0) { return 0.0; }
	float radius = length((point - lamp.xy) / lamp.zw);
	return exp(-radius * radius * 2.8);
}
void vertex() {
	art_modulate = COLOR;
}
void fragment() {
	vec4 source = texture(TEXTURE,UV);
 float blue = smoothstep(0.02,0.18,source.b-source.r)*smoothstep(-0.01,0.08,source.b-source.g*0.90);
 float green = smoothstep(0.02,0.16,source.g-max(source.r,source.b));
 float water = area_mask(UV,water_area)*blue;
 if (island_land_mask) {
  float mainland = 1.0-smoothstep(0.92,1.03,length((UV-vec2(0.50,0.46))/vec2(0.44,0.35)));
  float lighthouse_islet = 1.0-smoothstep(0.9,1.02,length((UV-vec2(0.91,0.18))/vec2(0.095,0.15)));
  water *= 1.0-max(mainland,lighthouse_islet);
 }
 float leaves = max(area_mask(UV,foliage_a),area_mask(UV,foliage_b))*green;
 float falls = max(area_mask(UV,falls_a),area_mask(UV,falls_b))*smoothstep(0.50,0.80,source.b)*smoothstep(-0.12,0.04,source.b-source.r);
 vec2 sample_uv = UV;
 sample_uv.x += sin(TIME*0.85+UV.y*13.0)*0.0016*leaves;
 sample_uv.y += sin(UV.x*130.0+TIME*1.1)*0.0007*water;
 sample_uv.x += sin(UV.y*150.0-TIME*2.0)*0.00045*water;
 sample_uv.y += sin(UV.y*210.0-TIME*5.0)*0.001*falls;
 vec4 art = texture(TEXTURE,clamp(sample_uv,vec2(0.001),vec2(0.999)));
 float shimmer = pow(max(0.0,sin(UV.y*390.0-TIME*2.0+sin(UV.x*70.0))),14.0)*water*0.025;
 float stream = (0.5+0.5*sin(UV.y*600.0-TIME*8.0))*falls*0.10;
 art.rgb = mix(art.rgb,vec3(0.92,0.99,1.0),shimmer+stream);
	float luminance = dot(art.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 night_color = mix(art.rgb, vec3(luminance), coolness * 0.42);
	vec3 lighting = night_color * mix(vec3(1.0), tone.rgb, 0.24) * max(exposure, 0.90);
	float warmth = clamp(lamp_glow(UV, lamp_0) + lamp_glow(UV, lamp_1) + lamp_glow(UV, lamp_2) + lamp_glow(UV, lamp_3), 0.0, 1.0);
	float evening = 1.0 - smoothstep(0.85, 0.98, exposure);
	vec3 lamplight = art.rgb * vec3(1.0, 0.93, 0.80) + vec3(0.14, 0.075, 0.025);
	lighting = mix(lighting, lamplight, warmth * evening * 0.90);
	COLOR = vec4(lighting, art.a) * art_modulate;
}
