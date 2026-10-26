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
	b.custom_minimum_size = Vector2(0, 76)
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
