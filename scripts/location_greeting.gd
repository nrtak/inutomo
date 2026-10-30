extends Control

var texture: Texture2D
var character_name = ""
var text = ""
var duration = 6.0

func _ready() -> void:
 name = "LocationGreeting"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var safe = UI.safe_insets(24)
 var portrait = ResidentPortrait.new()
 portrait.configure(texture)
 var atlas = portrait.texture
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_SCALE
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 portrait.clip_contents = false
 add_child(portrait)
 var bubble = UI.card()
 bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bubble)
 var bubble_width = minf(340, get_viewport_rect().size.x * 0.23)
 bubble.custom_minimum_size.x = bubble_width
 var content = UI.column(6)
 content.custom_minimum_size.x = bubble_width - 40
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bubble.add_child(content)
 content.add_child(UI.label(character_name, 25, UI.TEAL))
 var speech = UI.label(text, 24)
 speech.custom_minimum_size.x = bubble_width - 40
 content.add_child(speech)
 var tail = Polygon2D.new()
 tail.polygon = PackedVector2Array([Vector2(0,0),Vector2(-22,22),Vector2(35,0)])
 tail.color = Color("fff6e5")
 bubble.add_child(tail)
 var arrange = func():
  var bounds = UI.location_portrait_rect(size, atlas.get_size(), safe)
  portrait.size = bounds.size
  portrait.position = bounds.position
  bubble.position = Vector2(size.x * 0.39, safe.top + 74)
  bubble.size = Vector2(bubble_width, bubble.get_combined_minimum_size().y)
  tail.position = Vector2(24,bubble.size.y-2)
 resized.connect(arrange)
 content.minimum_size_changed.connect(arrange)
 bubble.resized.connect(func(): tail.position = Vector2(24,bubble.size.y-2))
 arrange.call_deferred()
 var fade = create_tween()
 fade.tween_interval(duration)
 fade.tween_property(bubble,"modulate:a",0.0,0.6)
 fade.tween_callback(func(): bubble.visible = false)
