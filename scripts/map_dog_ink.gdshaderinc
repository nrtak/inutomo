// Shared fragment body. Sample the current sprite, including its active atlas frame.
	float stroke_width = 1.35;
	vec2 footprint = fwidth(UV);
	vec2 offset = footprint * 0.25;
	vec4 a = texture(TEXTURE, UV - offset);
	vec4 b = texture(TEXTURE, UV + offset);
	vec4 c = texture(TEXTURE, UV + vec2(offset.x, -offset.y));
	vec4 d = texture(TEXTURE, UV + vec2(-offset.x, offset.y));
	float coverage = a.a + b.a + c.a + d.a;
	vec3 coat = (a.rgb*a.a + b.rgb*b.a + c.rgb*c.a + d.rgb*d.a) / max(coverage, 0.001);

	// Ink inside the silhouette so tightly cropped animation frames keep their edges.
	vec2 stroke = footprint * stroke_width;
	float horizontal = min(texture(TEXTURE, UV - vec2(stroke.x, 0.0)).a,
			texture(TEXTURE, UV + vec2(stroke.x, 0.0)).a);
	float vertical = min(texture(TEXTURE, UV - vec2(0.0, stroke.y)).a,
			texture(TEXTURE, UV + vec2(0.0, stroke.y)).a);
	float edge = 1.0 - smoothstep(0.04, 0.32, min(horizontal, vertical));
	pixel = vec4(mix(coat, vec3(0.25, 0.17, 0.13), edge * 0.88),
			smoothstep(0.04, 0.70, coverage * 0.25));
