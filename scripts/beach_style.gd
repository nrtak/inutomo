class_name BeachStyle
extends RefCounted

const BACKGROUND = preload("res://assets/backgrounds/beach_arrival.png")
const KAI = preload("res://assets/characters/kai_idle_sheet.png")
const INK = Color("603e29")
const PAPER = Color("fff6e5")
const ACTIVITIES = preload("res://assets/ui/beach_activities.png")
static var activity_cache: Dictionary = {}

static func activity_picture(index: int) -> Texture2D:
	index = clampi(index,0,2)
	if not activity_cache.has(index):
		var frame = AtlasTexture.new()
		frame.atlas = ACTIVITIES
		var cell = ACTIVITIES.get_width()/3.0
		frame.region = Rect2(index*cell,0,cell,ACTIVITIES.get_height())
		frame.filter_clip = true
		activity_cache[index] = frame
	return activity_cache[index]

# Beach layout and the other locations share the same actor artwork.
static func resident_frames() -> Array[Texture2D]:
	return Art.resident_frames(Art.KAI)

static func dog_texture(breed: String, asleep: bool) -> Texture2D:
	return Art.SLEEP_TEXTURES[breed] if asleep else Art.PUPPIES[breed]

static func column_width(view: Vector2, safe: Dictionary) -> float:
	return floorf(clampf((view.x-safe.left-safe.right)*0.34,300,440))

static func portrait_rect(view: Vector2, image: Vector2, safe: Dictionary) -> Rect2:
	var left = safe.left+8.0
	var factor = minf(floorf(view.x*0.46-left)/image.x,(view.y-safe.top-96)/image.y)
	var fitted = image*factor
	return Rect2(Vector2(left,view.y+2-fitted.y),fitted)

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
