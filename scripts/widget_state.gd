class_name WidgetState
extends RefCounted

const SCHEMA = 1
const MAX_AWAY_SECONDS = 7200.0
const IMAGE_SIZE = 384

static func snapshot(game: Node, saved_at: float, artwork: String) -> Dictionary:
	var values: Array = []
	var rates: Array = []
	for i in game.NEEDS.size():
		values.append(clampf(float(game.needs[game.NEEDS[i]]), 0.0, 100.0))
		rates.append(float(game.DECAY[i]) * game.OFFLINE_DECAY_FACTOR)
	var comfortable = false
	for item in ["Bed", "CloudBed", "CoolingMat", "Blanket"]:
		comfortable = comfortable or game.items.get(item, 0) > 0
	return {"schemaVersion": SCHEMA, "updatedAt": saved_at, "needs": values,
		"decayRates": rates, "restRate": (0.85 if comfortable else 0.65) if game.resting else 0.0,
		"breed": game.breed, "stage": game.growth_stage(), "growth": game.growth_fraction(),
		"artwork": artwork}

static func artwork_key(game: Node) -> String:
	var accessory: String = game.life.get("accessory", "")
	if game.items.get(accessory, 0) <= 0 or not Goods.ITEMS.has(accessory):
		accessory = ""
	return game.breed + ":" + accessory

static func artwork_image(game: Node) -> Image:
	var picture: Image = Art.PUPPIES[game.breed].get_image()
	if picture.is_compressed():
		picture.decompress()
	picture = picture.get_region(picture.get_used_rect())
	var factor = minf(float(IMAGE_SIZE - 16) / picture.get_width(), float(IMAGE_SIZE - 16) / picture.get_height())
	picture.resize(maxi(1, roundi(picture.get_width() * factor)), maxi(1, roundi(picture.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
	picture.convert(Image.FORMAT_RGBA8)
	var accessory: String = game.life.get("accessory", "")
	var recolor = game.items.get(accessory, 0) > 0 and Goods.ITEMS.has(accessory) and Goods.ITEMS[accessory].has("color")
	for y in picture.get_height():
		for x in picture.get_width():
			var pixel = picture.get_pixel(x, y)
			# Match the in-game bandana shader, including its clean alpha edge.
			if recolor and pixel.g > pixel.r * 1.25 and pixel.b > pixel.r * 1.15 and pixel.g > pixel.b * 0.8 and maxf(pixel.g, pixel.b) - pixel.r > 0.06:
				var shade = clampf(maxf(pixel.g, pixel.b) / 0.65, 0.25, 1.25)
				var tint: Color = Goods.ITEMS[accessory].color
				pixel.r = clampf(tint.r * shade, 0.0, 1.0)
				pixel.g = clampf(tint.g * shade, 0.0, 1.0)
				pixel.b = clampf(tint.b * shade, 0.0, 1.0)
			pixel.a = smoothstep(0.38, 0.76, pixel.a)
			picture.set_pixel(x, y, pixel)
	var canvas = Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	# Fit the whole seated pose; paws share a stable baseline in both widgets.
	canvas.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i((IMAGE_SIZE - picture.get_width()) / 2, IMAGE_SIZE - 8 - picture.get_height()))
	return canvas
