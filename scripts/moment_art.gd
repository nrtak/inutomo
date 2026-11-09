class_name MomentArt
extends RefCounted

static var data: Dictionary = preload("res://assets/moments_anime_frames.json").data
static var cache: Dictionary = {}

static func frame(group: String, key: String) -> Texture2D:
	var id = group + key
	if not cache.has(id):
		var spec: Dictionary = data[group]
		var bounds: Array = spec.frames[key]
		var texture = AtlasTexture.new()
		texture.atlas = load("res://" + spec.atlas)
		texture.region = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
		texture.filter_clip = true
		cache[id] = texture
	return cache[id]

static func resident(person: String) -> Texture2D:
	return frame("residents", person)

static func dog(breed: String, pose: String, dressed: bool = false) -> Texture2D:
	if Art.EXTRA_DOGS.has(breed) or pose in ["Tilt","Stretch","Greet","Tug"]:
		return Art.expression_texture(breed,pose,dressed)
	return frame("dogs" if dressed else "bare_dogs", breed + ":" + pose)

static func prop(kind: String) -> Texture2D:
	return frame("props", kind)

static func background(kind: String) -> Texture2D:
	return load("res://" + {"Home":"assets/backgrounds/home_anime.png", "Recall":"assets/backgrounds/park_practice_anime.png", "Beach":"assets/backgrounds/beach_arrival.png", "Cottage":"assets/backgrounds/cottage_discovery_anime.png", "Lighthouse":"assets/backgrounds/lighthouse_gathering_anime.png"}[kind])
