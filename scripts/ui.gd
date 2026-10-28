class_name UI
extends RefCounted

const INK = Color("603e29")
const TEAL = Color("429f98")
const PINK = Color("ef8b9b")
const PLACE_COLORS = {"Harbor": Color("c2ecf4"), "Keeper’s Cottage": Color("ffdfb5"),"Home": Color("ffdfb5"), "Puppy Club": Color("f9d8e2"), "Park": Color("c8eddd"), "Shop": Color("ffdfb5"), "Vet Clinic": Color("c2ecf4"), "Beach": Color("c2ecf4"), "Lighthouse": Color("e1d9f6")}

static func place_icon(place: String) -> Texture2D:
	var file: String = {"Harbor": "harbor", "Keeper’s Cottage": "cottage","Home": "home", "Puppy Club": "club", "Park": "leaf", "Shop": "menu_bag", "Vet Clinic": "clinic", "Beach": "shell", "Lighthouse": "lighthouse"}.get(place, "island")
	return load("res://assets/ui/" + file + ".svg")

static func resident_icon(texture: Texture2D) -> Texture2D:
	texture = Art.daily_portrait(texture)
	var icon = AtlasTexture.new()
	icon.atlas = texture
	var region = Rect2(texture.get_image().get_used_rect())
	region.size.y *= 0.52
	icon.region = region
	return icon

static func style(color: Color, radius: int = 24) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color("b88b59")
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s

static func label(text: String, font_size: int = 24, color: Color = INK) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, action: Callable, color: Color = TEAL) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_stylebox_override("normal", style(color, 20))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.12), 20))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.12), 20))
	b.add_theme_stylebox_override("disabled", style(Color("b6c9cb"), 20))
	b.add_theme_stylebox_override("focus", style(Color(0.15, 0.7, 0.7, 0.25), 20))
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color("746455"))
	b.pressed.connect(action)
	return b

static func hint_label(text: String, font_size: int = 24, color: Color = INK) -> CommandHint:
	var hint = CommandHint.new()
	hint.bbcode_enabled = true
	hint.fit_content = true
	hint.scroll_active = false
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("normal_font_size", font_size)
	hint.add_theme_font_size_override("bold_font_size", font_size)
	hint.add_theme_color_override("default_color", color)
	hint.set_hint(text)
	return hint

static func card() -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color("fff6e5")))
	return p

static func column(gap: int = 12) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v

# Waist-up portraits at the screen edge, with a speech bubble above and beside them.
static func conversation_body(parent: Control, texture: Texture2D, character_name: String) -> VBoxContainer:
	texture = Art.daily_portrait(texture)
	var safe = safe_insets(24)
	var stage = Control.new()
	stage.name = "ConversationCharacter"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_left = safe.left
	stage.offset_right = -safe.right
	stage.offset_top = safe.top
	stage.offset_bottom = 0
	stage.clip_contents = true
	parent.add_child(stage)
	var portrait = TextureRect.new()
	var cutout = AtlasTexture.new()
	cutout.atlas = texture
	cutout.region = texture.get_image().get_used_rect()
	portrait.texture = cutout
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(portrait)
	var panel = card()
	panel.name = "ConversationText"
	var bubble_style = style(Color("fffdf6"), 38)
	bubble_style.border_color = INK
	bubble_style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", bubble_style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var tail = Polygon2D.new()
	tail.name = "SpeechTail"
	tail.polygon = PackedVector2Array([Vector2(0, -3), Vector2(-24, 26), Vector2(44, -3)])
	tail.color = Color("fffdf6")
	panel.add_child(tail)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_right = -safe.right - 56
	panel.offset_top = safe.top + 20
	parent.add_child(panel)
	var content = column(8)
	panel.add_child(content)
	content.add_child(label(character_name, 29, TEAL))
	var arrange = func():
		var image_size = Vector2(cutout.get_size())
		var factor = minf(stage.size.x * 0.50 / image_size.x, (stage.size.y + 64) / image_size.y)
		portrait.size = image_size * factor
		portrait.position = Vector2((stage.size.x * 0.50 - portrait.size.x) * 0.5, stage.size.y - portrait.size.y + 64)
		var bubble_width = minf(500, stage.size.x * 0.47)
		panel.offset_left = -safe.right - bubble_width - 56
		panel.offset_bottom = safe.top + 20 + panel.get_combined_minimum_size().y
		tail.position = Vector2(40, panel.size.y)
	stage.resized.connect(arrange)
	panel.minimum_size_changed.connect(arrange)
	panel.resized.connect(arrange)
	content.resized.connect(arrange)
	return content

static func icon_button(text: String, texture: Texture2D, action: Callable, color: Color = TEAL) -> Button:
	var tile = button(text, action, color)
	tile.custom_minimum_size = Vector2(100, 110)
	tile.tooltip_text = text
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		tile.add_theme_color_override(state, Color.TRANSPARENT)
	var picture = TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 16
	picture.offset_right = -16
	picture.offset_top = 9
	picture.offset_bottom = -36
	tile.add_child(picture)
	var caption = label(text, 22)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -36
	caption.offset_bottom = -7
	tile.add_child(caption)
	tile.set_meta("caption", caption)
	tile.set_meta("picture", picture)
	var wait_bar = ProgressBar.new()
	wait_bar.show_percentage = false
	wait_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wait_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	wait_bar.offset_left = 18
	wait_bar.offset_right = -18
	wait_bar.offset_top = -7
	wait_bar.offset_bottom = -2
	var track = style(Color("dfcfb8"), 3)
	var fill = style(TEAL, 3)
	for box in [track, fill]:
		box.set_border_width_all(0)
		box.content_margin_left = 0
		box.content_margin_right = 0
		box.content_margin_top = 0
		box.content_margin_bottom = 0
	wait_bar.add_theme_stylebox_override("background", track)
	wait_bar.add_theme_stylebox_override("fill", fill)
	wait_bar.visible = false
	tile.add_child(wait_bar)
	tile.set_meta("wait_bar", wait_bar)
	return tile

static func button_wait(tile: Button, remaining: float, duration: float) -> void:
	if tile.has_meta("wait_bar"):
		var bar: ProgressBar = tile.get_meta("wait_bar")
		bar.visible = remaining > 0
		bar.value = (1.0 - remaining / duration) * 100.0
		bar.tooltip_text = "Ready when the bar fills"

static func button_caption(tile: Button, text: String) -> void:
	tile.text = text
	if tile.has_meta("caption"):
		tile.get_meta("caption").text = text
		tile.get_meta("picture").modulate.a = 0.45 if tile.disabled else 1.0

static var safe_override: Dictionary = {}
static func safe_insets(minimum: int = 20) -> Dictionary:
	var edges = {"left": minimum, "right": minimum, "top": minimum, "bottom": minimum}
	if not safe_override.is_empty():
		for edge in edges:
			edges[edge] = maxi(minimum, int(safe_override.get(edge, minimum)))
	elif OS.has_feature("ios"):
		var safe = DisplayServer.get_display_safe_area()
		var window = DisplayServer.window_get_size()
		var tree = Engine.get_main_loop() as SceneTree
		if tree != null and window.x > 0 and window.y > 0:
			var ratio = tree.root.get_visible_rect().size / Vector2(window)
			edges.left = maxi(minimum, int(safe.position.x * ratio.x) + 12)
			edges.right = maxi(minimum, int((window.x - safe.end.x) * ratio.x) + 12)
			edges.top = maxi(minimum, int(safe.position.y * ratio.y) + 8)
			edges.bottom = maxi(minimum, int((window.y - safe.end.y) * ratio.y) + 8)
	return edges

static func picture_button(text: String, texture: Texture2D, action: Callable, cover: bool = false) -> Button:
	var tile = button(text, action, Color("fff0d2"))
	tile.custom_minimum_size = Vector2(280, 200)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tile.add_theme_color_override(state, Color.TRANSPARENT)
	var picture = TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 10
	picture.offset_right = -10
	picture.offset_top = 10
	picture.offset_bottom = -52
	tile.add_child(picture)
	var caption = label(text, 26)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.anchor_top = 1
	caption.anchor_right = 1
	caption.anchor_bottom = 1
	caption.offset_top = -48
	caption.offset_bottom = -7
	tile.add_child(caption)
	return tile
