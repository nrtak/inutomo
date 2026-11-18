extends Control

var texture: Texture2D
var character_name = ""
var text = ""
var duration = 6.0
var scene_style = ""
var talk: Callable

func _ready() -> void:
 name = "LocationGreeting"
 set_meta("screen_layout_manual",true)
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
 var style = UI.speech_style(BeachStyle.PAPER,42)
 style.border_color = BeachStyle.INK
 bubble.add_theme_stylebox_override("panel",style)
 bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bubble)
 var bubble_width = clampf(get_viewport_rect().size.x*0.23,220,340)
 bubble.custom_minimum_size.x = bubble_width
 var content = UI.column(4)
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bubble.add_child(content)
 content.add_child(UI.label(character_name, 24, BeachStyle.INK))
 var speech = UI.hint_label(text, 22)
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
  if size.y>size.x:
   var art_size=atlas.get_size()
   portrait.size=art_size*minf(size.x*.2/art_size.x,190.0/art_size.y)
   var left=edges.left+portrait.size.x+16
   var width=size.x-edges.right-BeachStyle.column_width(size,edges)-16-left
   bubble.custom_minimum_size.x=width
   bubble.position=Vector2(left,edges.top+92)
   bubble.size=Vector2(width,bubble.get_combined_minimum_size().y)
   portrait.position=Vector2(edges.left,bubble.position.y+maxf(0,bubble.size.y*.4-portrait.size.y*.23))
   tail.rotation=PI*.5
   tail.position=Vector2(2,bubble.size.y*.4)
   return
  tail.rotation=0
  # Keep the line length comfortable inside the wider paper margins.
  var speech_width = clampf(size.x*0.23+48,268,388)
  bubble.custom_minimum_size.x = speech_width
  var bounds = BeachStyle.portrait_rect(size,atlas.get_size(),edges) if scene_style == "Beach" else UI.location_portrait_rect(size, atlas.get_size(), edges)
  portrait.size = bounds.size
  portrait.position = bounds.position
  var actions_width = BeachStyle.column_width(size,edges)
  var speech_left = minf(size.x*(0.35 if scene_style == "Beach" else 0.39),size.x-edges.right-actions_width-16-speech_width)
  bubble.position = Vector2(maxf(edges.left,speech_left),edges.top+56)
  bubble.size = Vector2(speech_width,bubble.get_combined_minimum_size().y)
  tail.position = Vector2(24,bubble.size.y-2)
 resized.connect(arrange)
 content.minimum_size_changed.connect(arrange)
 bubble.resized.connect(func(): arrange.call_deferred())
 arrange.call_deferred()
 var fade = create_tween()
 fade.tween_interval(duration)
 fade.tween_property(bubble,"modulate:a",0.0,0.6)
 fade.tween_callback(func(): bubble.visible = false)
