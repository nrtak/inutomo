class_name UI
extends RefCounted

const INK = Color("603e29")
const TEAL = Color("429f98")
const PINK = Color("ef8b9b")

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

static func card() -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color("fff6e5")))
	return p

static func column(gap: int = 12) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v

# Dialogue characters sit inside a framed portrait, with the cutout grounded
# against its bottom edge rather than suspended over the game world.
static func character_portrait(texture: Texture2D, character_name: String, role: String) -> VBoxContainer:
	var column = UI.column(0)
	column.custom_minimum_size.x = 240
	var frame = PanelContainer.new()
	frame.name = "CharacterPortraitFrame"
	var border = style(Color("d5ece3"), 18)
	border.content_margin_left = 2
	border.content_margin_right = 2
	border.content_margin_top = 2
	border.content_margin_bottom = 2
	frame.add_theme_stylebox_override("panel", border)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(frame)
	var stage = Control.new()
	stage.clip_contents = true
	stage.custom_minimum_size.y = 270
	frame.add_child(stage)
	var portrait = TextureRect.new()
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(portrait)
	var place_portrait = func():
		var texture_size = Vector2(texture.get_size())
		var scale_factor = minf(stage.size.x / texture_size.x, stage.size.y / texture_size.y)
		portrait.size = texture_size * scale_factor
		portrait.position = Vector2((stage.size.x - portrait.size.x) * 0.5, stage.size.y - portrait.size.y + 5)
	stage.resized.connect(place_portrait)
	var caption = PanelContainer.new()
	caption.add_theme_stylebox_override("panel", style(Color("fff0cf"), 12))
	column.add_child(caption)
	var caption_content = UI.column(2)
	caption.add_child(caption_content)
	var name_label = label(character_name, 25, TEAL)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_content.add_child(name_label)
	var role_label = label(role, 18)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_content.add_child(role_label)
	return column

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
