shader_type canvas_item;
uniform bool small_sprite = false;
varying vec4 item_tint;
void vertex() {
	item_tint = COLOR;
}
uniform vec4 bandana : source_color = vec4(0.20, 0.62, 0.58, 1.0);
uniform bool recolor = false;
uniform bool sleeping_cutout = false;
uniform float blink = 0.0;
uniform vec4 eye_centers;
uniform vec2 eye_radius;
vec3 median_color(vec3 a, vec3 b, vec3 c) {
	return max(min(a,b),min(max(a,b),c));
}
void fragment() {
	vec4 pixel;
	if (small_sprite) {
		#include "res://scripts/map_dog_ink.gdshaderinc"
	} else {
		pixel = texture(TEXTURE, UV);
		if (blink > 0.0) {
			vec2 center = UV.x < (eye_centers.x+eye_centers.z)*0.5 ? eye_centers.xy : eye_centers.zw;
			vec2 eye = (UV-center)/eye_radius;
			float edge = 1.0-smoothstep(0.83,1.08,length(eye));
			if (edge > 0.0) {
				vec2 lateral = vec2(eye_radius.x*0.52,0.0);
				vec2 top = center-vec2(0.0,eye_radius.y);
				vec2 bottom = center+vec2(0.0,eye_radius.y);
				vec3 brow = median_color(texture(TEXTURE,top-lateral).rgb,texture(TEXTURE,top).rgb,texture(TEXTURE,top+lateral).rgb);
				vec3 cheek = median_color(texture(TEXTURE,bottom-lateral).rgb,texture(TEXTURE,bottom).rgb,texture(TEXTURE,bottom+lateral).rgb);
				vec3 fur = mix(brow,cheek,smoothstep(-1.0,1.0,eye.y));
				float lid_y = 0.32*eye.x*eye.x-0.18*eye.x;
				float opening = max(0.0,1.0-blink);
				float covered = smoothstep(opening,opening+0.12,abs(eye.y-lid_y));
				pixel.rgb = mix(pixel.rgb,fur,edge*covered*smoothstep(0.0,0.18,blink));
				float ink = (1.0-smoothstep(0.04,0.15,abs(eye.y-lid_y)))*(1.0-smoothstep(0.48,0.76,abs(eye.x)));
				pixel.rgb = mix(pixel.rgb,vec3(0.18,0.12,0.10),edge*ink*blink);
			}
		}
		pixel.a = smoothstep(0.38, 0.76, pixel.a);
	}
	if (recolor && pixel.g > pixel.r * 1.25 && pixel.b > pixel.r * 1.15 && pixel.g > pixel.b * 0.8 && max(pixel.g, pixel.b) - pixel.r > 0.06) {
		float shade = clamp(max(pixel.g, pixel.b) / 0.65, 0.25, 1.25);
		pixel.rgb = bandana.rgb * shade;
	}
	COLOR = pixel * item_tint;
}
