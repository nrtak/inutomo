extends Control
var host: Control
var selected = "Home"
var canvas: Control
var map_image: TextureRect
var preview: TextureRect
var title: Label
var detail: Label
var go_button: Button
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
 var margins = {"left": safe.left, "right": safe.right, "top": maxi(160, safe.top + 120), "bottom": safe.bottom}
 for edge in margins:
  inset.add_theme_constant_override("margin_" + edge, margins[edge])
 add_child(inset)
 var layout = HBoxContainer.new()
 layout.add_theme_constant_override("separation", 14)
 inset.add_child(layout)
 canvas = Control.new()
 canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 layout.add_child(canvas)
 map_image = TextureRect.new()
 map_image.texture = Art.ISLAND
 map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 map_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 canvas.add_child(map_image)
 for place in PLACES:
  var pin = UI.button(place, select.bind(place), Color("fff6e5"))
  pin.custom_minimum_size = Vector2(120 if place in ["Park", "Shop", "Home", "Beach"] else 168, 88)
  pin.add_theme_font_size_override("font_size", 22)
  canvas.add_child(pin)
  pins[place] = pin
 var card = UI.card()
 var compact = get_viewport_rect().size.x < 1400
 card.custom_minimum_size.x = 330 if compact else 390
 layout.add_child(card)
 var content = UI.column(10)
 content.custom_minimum_size.x = 290 if compact else 350
 card.add_child(content)
 title = UI.label("", 26 if compact else 30, UI.TEAL)
 content.add_child(title)
 preview = TextureRect.new()
 preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 preview.custom_minimum_size = Vector2(0, 125 if compact else 165)
 content.add_child(preview)
 detail = UI.label("", 23)
 detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
 content.add_child(detail)
 content.add_child(UI.label("Choose a place, then Go.", 21))
 go_button = UI.button("Go", travel, Color("bdeab0"))
 content.add_child(go_button)
 canvas.resized.connect(place_pins)
 selected = host.current_place if host.current_place in PLACES else "Home"
 select(selected)
 call_deferred("place_pins")

func place_pins() -> void:
 if canvas.size.x <= 0 or canvas.size.y <= 0:
  return
 var texture_size = Vector2(Art.ISLAND.get_size())
 var factor = minf(canvas.size.x / texture_size.x, canvas.size.y / texture_size.y)
 var draw_size = texture_size * factor
 map_rect = Rect2((canvas.size - draw_size) * 0.5, draw_size)
 for place in pins:
  var pin: Button = pins[place]
  pin.size = pin.get_combined_minimum_size()
  var center = map_rect.position + PLACES[place].point * map_rect.size
  pin.position = (center - pin.size * 0.5).clamp(Vector2.ZERO, (canvas.size - pin.size).max(Vector2.ZERO))

func select(place: String) -> void:
 selected = place
 title.text = place + (" / You are here" if place == host.current_place else "")
 preview.texture = Art.BACKGROUNDS[place]
 detail.text = PLACES[place].text
 var outing = "Fetch" if place == "Park" else ("Walk" if place == "Beach" else "")
 if not outing.is_empty() and Game.active_outing.get("kind", "") == outing:
  detail.text += " Your outing checkpoint is saved here."
 go_button.text = "View preview" if place == "Lighthouse" else "Go to " + place
 for key in pins:
  pins[key].modulate = Color("ffe0a0") if key == place else Color.WHITE

func travel() -> void:
 host.visit(selected)
