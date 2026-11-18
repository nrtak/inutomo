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
uniform vec4 falls_c = vec4(0.0);
uniform vec4 falls_d = vec4(0.0);
uniform bool motion_enabled = true;
uniform bool island_land_mask = false;
uniform float water_shimmer = 0.065;
uniform float cloud_cover : hint_range(0.0,1.0) = 0.0;
uniform float wetness : hint_range(0.0,1.0) = 0.0;
uniform bool indoor = false;
uniform vec4 weather_window = vec4(0.0,0.0,1.0,1.0);
uniform float sky_height = 0.35;
uniform float night_amount : hint_range(0.0,1.0) = 0.0;
uniform float sunset_amount : hint_range(0.0,1.0) = 0.0;
uniform float dawn_amount : hint_range(0.0,1.0) = 0.0;
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
 float motion_time = motion_enabled ? TIME : 0.0;
	vec4 source = texture(TEXTURE,UV);
 float blue = smoothstep(0.02,0.18,source.b-source.r)*smoothstep(-0.01,0.08,source.b-source.g*0.90);
 float green = smoothstep(0.02,0.16,source.g-max(source.r,source.b));
 float water = area_mask(UV,water_area)*blue;
 if (island_land_mask) {
  float mainland = 1.0-smoothstep(0.92,1.03,length((UV-vec2(0.50,0.46))/vec2(0.44,0.35)));
  float lighthouse_islet = 1.0-smoothstep(0.9,1.02,length((UV-vec2(0.91,0.18))/vec2(0.095,0.15)));
  water *= 1.0-max(mainland,lighthouse_islet);
 }
 float leaves = float(motion_enabled)*max(area_mask(UV,foliage_a),area_mask(UV,foliage_b))*green;
 float falls = max(max(area_mask(UV,falls_a),area_mask(UV,falls_b)),max(area_mask(UV,falls_c),area_mask(UV,falls_d)))*smoothstep(0.50,0.80,source.b)*smoothstep(-0.12,0.04,source.b-source.r);
 // Only the two explicitly marked treetops drift with the prevailing wind.
 // Blend advancing samples so leaf motion never reverses or snaps on a loop.
 float wind_phase = fract(motion_time * 0.025);
 float other_phase = fract(wind_phase + 0.5);
 float wind_blend = abs(wind_phase * 2.0 - 1.0);
 vec4 wind_a = texture(TEXTURE,clamp(UV-vec2(wind_phase*0.007,0.0),vec2(0.001),vec2(0.999)));
 vec4 wind_b = texture(TEXTURE,clamp(UV-vec2(other_phase*0.007,0.0),vec2(0.001),vec2(0.999)));
 vec4 art = mix(source,mix(wind_a,wind_b,wind_blend),leaves);
 // Traveling light crests move to the right; the background image stays fixed.
 float crest = pow(max(0.0,sin(UV.x*240.0-motion_time*1.2+UV.y*35.0)),18.0);
 float shimmer = crest*water*water_shimmer;
 float stream = pow(0.5+0.5*sin(UV.y*100.0-motion_time*2.0),4.0)*falls*0.10;
 art.rgb = mix(art.rgb,vec3(0.92,0.99,1.0),shimmer+stream);
	float luminance = dot(art.rgb, vec3(0.2126, 0.7152, 0.0722));
	float outdoors = indoor ? area_mask(UV,weather_window) : 1.0;
	float sky = (1.0-smoothstep(sky_height-0.07,sky_height+0.035,UV.y));
	// Replace brilliant blue and warm sunset washes with a quiet overcast sky.
	// Dark ink and green canopy remain intact rather than being painted over.
	float sky_color = smoothstep(0.0,0.12,art.b-art.r)*smoothstep(0.0,0.08,art.b-art.g)
		+smoothstep(0.62,0.88,luminance)*(1.0-smoothstep(0.01,0.14,art.g-art.b))
		+smoothstep(0.02,0.20,art.r-art.b)*smoothstep(0.42,0.70,luminance);
	vec3 grey_sky = mix(vec3(0.68,0.73,0.77),vec3(0.52,0.60,0.67),wetness);
	grey_sky*=0.87+0.18*luminance;
	art.rgb=mix(art.rgb,grey_sky,clamp(sky_color,0.0,1.0)*sky*cloud_cover*outdoors*0.94);
	// Diffuse rain light softens painted sunlight; a cool, damp wash reaches the landscape.
	luminance=dot(art.rgb,vec3(0.2126,0.7152,0.0722));
	art.rgb=mix(art.rgb,vec3(luminance)*vec3(0.94,0.99,1.05),cloud_cover*outdoors*0.27);
	art.rgb*=1.0-outdoors*(cloud_cover*0.09+wetness*0.10);
	vec3 night_color = mix(art.rgb, vec3(luminance)*0.85, coolness * 0.38);
	float local_exposure=indoor ? mix(max(exposure,0.56),exposure,outdoors) : exposure;
	vec3 lighting = night_color * mix(vec3(1.0), tone.rgb, 0.52) * local_exposure;
	float open_sky=sky*clamp(sky_color,0.0,1.0)*outdoors;
	float horizon=clamp(UV.y/max(sky_height,0.01),0.0,1.0);
	// Sunset changes the painted palette: amber sky, rose clouds, warm brown shadows.
	vec3 amber_sky=mix(vec3(0.65,0.36,0.36),vec3(0.99,0.69,0.39),horizon);
	vec3 dusk_art=mix(vec3(0.22,0.14,0.19),vec3(0.96,0.73,0.50),pow(luminance,0.86));
	dusk_art=mix(art.rgb,dusk_art,0.65);
	dusk_art=mix(dusk_art,amber_sky*(0.87+0.18*luminance),open_sky*0.94);
	dusk_art=mix(dusk_art,vec3(dot(dusk_art,vec3(0.2126,0.7152,0.0722))),cloud_cover*0.24);
	lighting=mix(lighting,dusk_art,sunset_amount*(indoor ? mix(0.45,1.0,outdoors) : 1.0));
	vec3 dawn_sky=mix(vec3(0.52,0.55,0.72),vec3(1.0,0.77,0.58),horizon);
	lighting=mix(lighting,dawn_sky*(0.87+0.15*luminance),open_sky*dawn_amount);
	// Moonlit blues retain linework and value differences without a black veil.
	vec3 blue_art=mix(vec3(0.065,0.115,0.22),vec3(0.34,0.46,0.66),pow(luminance,0.85));
	vec3 blue_sky=mix(vec3(0.075,0.135,0.27),vec3(0.20,0.31,0.47),horizon);
	blue_sky=mix(blue_sky,vec3(0.22,0.29,0.40),cloud_cover*0.32);
	blue_art=mix(blue_art,blue_sky*(0.88+0.16*luminance),open_sky*0.90);
	lighting=mix(lighting,blue_art,night_amount*(indoor ? mix(0.58,1.0,outdoors) : 1.0));
	float warmth = clamp(lamp_glow(UV, lamp_0) + lamp_glow(UV, lamp_1) + lamp_glow(UV, lamp_2) + lamp_glow(UV, lamp_3), 0.0, 1.0);
	float evening = 1.0 - smoothstep(0.85, 0.98, exposure);
	vec3 lamplight = art.rgb * vec3(1.0, 0.93, 0.80) + vec3(0.14, 0.075, 0.025);
	lighting = mix(lighting, lamplight, warmth * evening * 0.90);
	COLOR = vec4(lighting, art.a) * art_modulate;
}
