extends Control

var texture: Texture2D
var character_name = ""
var text = ""
var duration = 6.0
var scene_style = ""
var talk: Callable

func _ready() -> void:
 name = "LocationGreeting"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var portrait = ResidentPortrait.new()
 portrait.configure(texture)
 var atlas = portrait.texture
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_SCALE
 portrait.mouse_filter = Control.MOUSE_FILTER_STOP if talk.is_valid() else Control.MOUSE_FILTER_IGNORE
 portrait.tooltip_text = "Tap to hear " + character_name + "'s story"
 portrait.gui_input.connect(func(event: InputEvent):
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and talk.is_valid():
   talk.call()
 )
 portrait.clip_contents = false
 add_child(portrait)
 var bubble = UI.card()
 var style = UI.style(BeachStyle.PAPER,42)
 style.border_color = BeachStyle.INK
 style.set_border_width_all(3)
 style.content_margin_left = 16
 style.content_margin_right = 16
 style.content_margin_top = 8
 style.content_margin_bottom = 8
 bubble.add_theme_stylebox_override("panel",style)
 bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bubble)
 var bubble_width = minf(340, get_viewport_rect().size.x * 0.23)
 bubble.custom_minimum_size.x = bubble_width
 var content = UI.column(4)
 content.custom_minimum_size.x = bubble_width - 32
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bubble.add_child(content)
 content.add_child(UI.label(character_name, 24, BeachStyle.INK))
 var speech = UI.hint_label(text, 22)
 speech.custom_minimum_size.x = bubble_width - 32
 content.add_child(speech)
 var tail = Polygon2D.new()
 tail.polygon = PackedVector2Array([Vector2(0,0),Vector2(-22,22),Vector2(35,0)])
 tail.color = Color("fff6e5")
 bubble.add_child(tail)
 if not scene_style.is_empty():
  var contour = Line2D.new()
  contour.points = tail.polygon
  contour.width = 3
  contour.default_color = BeachStyle.INK
  contour.antialiased = true
  tail.add_child(contour)
 var arrange = func():
  var edges = UI.safe_insets(24)
  var speech_width = minf(340,size.x*0.23)
  bubble.custom_minimum_size.x = speech_width
  content.custom_minimum_size.x = speech_width-32
  speech.custom_minimum_size.x = speech_width-32
  var bounds = BeachStyle.portrait_rect(size,atlas.get_size(),edges) if scene_style == "Beach" else UI.location_portrait_rect(size, atlas.get_size(), edges)
  portrait.size = bounds.size
  portrait.position = bounds.position
  var actions_width = BeachStyle.column_width(size,edges) if scene_style == "Beach" else 400.0
  var speech_left = minf(size.x*(0.35 if scene_style == "Beach" else 0.39),size.x-edges.right-actions_width-16-speech_width)
  bubble.position = Vector2(maxf(edges.left,speech_left),edges.top+68)
  bubble.size = Vector2(speech_width,bubble.get_combined_minimum_size().y)
  tail.position = Vector2(24,bubble.size.y-2)
 resized.connect(arrange)
 content.minimum_size_changed.connect(arrange)
 bubble.resized.connect(func(): tail.position = Vector2(24,bubble.size.y-2))
 arrange.call_deferred()
 var fade = create_tween()
 fade.tween_interval(duration)
 fade.tween_property(bubble,"modulate:a",0.0,0.6)
 fade.tween_callback(func(): bubble.visible = false)
