extends Control
var host: Control
var selected = "Home"
var canvas: Control
var map_image: TextureRect
var pins: Dictionary = {}
var map_rect = Rect2()
const PLACES = {
 "Home": {"point": Vector2(0.23, 0.20), "text": "Meals, play, gentle care and cozy naps.", "art": "Home"},
 "Puppy Club": {"point": Vector2(0.54, 0.20), "text": "Meet Nora and choose your next outing.", "art": "Puppy Club"},
 "Park": {"point": Vector2(0.53, 0.49), "text": "Visit the plaza and play three rounds of Fetch.", "art": "Park"},
 "Shop": {"point": Vector2(0.28, 0.50), "text": "Visit June for treats, toys, care goods and comfort.", "art": "Shop"},
 "Vet Clinic": {"point": Vector2(0.80, 0.49), "text": "Leah offers a free checkup and gentle grooming.", "art": "Vet Clinic"},
 "Beach": {"point": Vector2(0.73, 0.77), "text": "Explore three discoveries, then walk back up the path.", "art": "Beach"},
 "Lighthouse": {"point": Vector2(0.90, 0.15), "text": "Locked for a later chapter. View the scenic preview.", "art": "Lighthouse"}
}
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var bg = ColorRect.new()
 bg.color = Color("d6f1f3")
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var safe = UI.safe_insets()
 var margins = {"left": 0, "right": 0, "top": 0, "bottom": 0}
 for edge in margins:
  inset.add_theme_constant_override("margin_" + edge, margins[edge])
 add_child(inset)
 var layout = Control.new()
 inset.add_child(layout)
 canvas = Control.new()
 canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layout.add_child(canvas)
 map_image = TextureRect.new()
 map_image.texture = Art.ISLAND
 Daylight.apply_to(map_image, "Island")
 map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 map_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 canvas.add_child(map_image)
 for place in PLACES:
  var pin = UI.button(place, travel_to.bind(place), UI.PLACE_COLORS[place])
  pin.custom_minimum_size = Vector2(160 if place in ["Park", "Shop", "Home", "Beach"] else 210, 88)
  pin.add_theme_font_size_override("font_size", 22)
  pin.icon = UI.place_icon(place)
  pin.expand_icon = true
  pin.add_theme_constant_override("icon_max_width", 38)
  canvas.add_child(pin)
  pins[place] = pin
 canvas.resized.connect(place_pins)
 selected = host.current_place if host.current_place in PLACES else "Home"
 call_deferred("place_pins")

func place_pins() -> void:
 if canvas.size.x <= 0 or canvas.size.y <= 0:
  return
 var texture_size = Vector2(Art.ISLAND.get_size())
 var factor = maxf(canvas.size.x / texture_size.x, canvas.size.y / texture_size.y)
 var draw_size = texture_size * factor
 map_rect = Rect2((canvas.size - draw_size) * 0.5, draw_size)
 for place in pins:
  var pin: Button = pins[place]
  pin.size = pin.get_combined_minimum_size()
  var center = map_rect.position + PLACES[place].point * map_rect.size
  var safe = UI.safe_insets()
  pin.position = (center - pin.size * 0.5).clamp(Vector2(safe.left, safe.top + 110), (canvas.size - pin.size - Vector2(safe.right, safe.bottom + 24)).max(Vector2(safe.left, safe.top + 110)))

func travel_to(place: String) -> void:
 if not PLACES.has(place):
  return
 selected = place
 host.visit(place)
