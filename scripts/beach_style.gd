class_name BeachStyle
extends RefCounted

const BACKGROUND = preload("res://assets/backgrounds/beach_cel.png")
const KAI = preload("res://assets/characters/kai_cel_sheet.png")
const DOGS = preload("res://assets/puppies/beach_cel_dogs.png")
const INK = Color("603e29")
const PAPER = Color("fff6e5")
static var cache: Dictionary = {}

static func resident_frames() -> Array[Texture2D]:
	if cache.has("Kai"):
		return cache.Kai
	var cell = Vector2i(KAI.get_width()/2,KAI.get_height())
	# Explicit registration ignores nearly transparent pixels around the cutout.
	var trim = Rect2i(198,2,502,885)
	var frames: Array[Texture2D] = []
	for column in 2:
		var frame = AtlasTexture.new()
		frame.atlas = KAI
		frame.region = Rect2(Vector2i(column*cell.x,0)+trim.position,trim.size)
		frame.filter_clip = true
		frames.append(frame)
	cache.Kai = frames
	return frames

static func dog_texture(breed: String, asleep: bool) -> Texture2D:
	var key = breed+str(asleep)
	if not cache.has(key):
		var column = ["Puppy","Shiba Inu","Golden Retriever"].find(breed)
		var regions = [Rect2i(51,727,396,234),Rect2i(505,703,429,258),Rect2i(989,688,519,276)] if asleep else [Rect2i(64,146,361,444),Rect2i(516,53,425,538),Rect2i(999,39,474,558)]
		var region: Rect2i = regions[maxi(0,column)]
		var frame = AtlasTexture.new()
		frame.atlas = DOGS
		frame.region = Rect2(region)
		frame.filter_clip = true
		cache[key] = frame
	return cache[key]

static func column_width(view: Vector2, safe: Dictionary) -> float:
	return floorf(clampf((view.x-safe.left-safe.right)*0.34,300,440))

static func portrait_rect(view: Vector2, image: Vector2, safe: Dictionary) -> Rect2:
	var left = safe.left+8.0
	var factor = minf((view.x*0.40-left)/image.x,(view.y-safe.top-16)/image.y)
	var fitted = image*factor
	return Rect2(Vector2(left,view.y+70-fitted.y),fitted)

static func style_button(button: Button, color: Color) -> void:
	if not button.has_meta("beach_original_styles"):
		var original = {}
		for state in ["normal","hover","pressed","disabled"]:
			original[state] = button.get_theme_stylebox(state)
		button.set_meta("beach_original_styles",original)
	for state in ["normal","hover","pressed","disabled"]:
		var fill = color.lightened(0.06) if state == "hover" else (color.darkened(0.05) if state == "pressed" else color)
		if state == "disabled":
			fill = color.lerp(Color("d5d0c3"),0.5)
		var box = UI.style(fill,24)
		box.border_color = INK
		box.set_border_width_all(2)
		button.add_theme_stylebox_override(state,box)
	if button.has_meta("picture") and is_zero_approx(button.get_meta("picture").anchor_right):
		button.get_meta("picture").offset_right = 100
		button.get_meta("caption").offset_left = 112
		button.get_meta("caption").add_theme_font_size_override("font_size",25)
		button.get_meta("picture").offset_top = 12
		button.get_meta("picture").offset_bottom = -12
		if button.get_child_count() >= 3 and button.get_child(2) is Label:
			button.get_child(2).add_theme_color_override("font_color",INK)

static func restore_button(button: Button) -> void:
	if button.has_meta("beach_original_styles"):
		for state in button.get_meta("beach_original_styles"):
			button.add_theme_stylebox_override(state,button.get_meta("beach_original_styles")[state])
