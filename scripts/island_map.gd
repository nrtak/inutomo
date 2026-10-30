extends Control
var host: Control
var selected = "Home"
var canvas: Control
var map_image: TextureRect
var pins: Dictionary = {}
var map_rect = Rect2()
var map_dog: PuppyActor
var travelling = false
var travel_clock = 0.0
var travel_duration = 1.5
var travel_path = PackedVector2Array()
var target_place = ""
const FOOT_POINTS = {
 "Home":Vector2(0.25,0.32), "Puppy Club":Vector2(0.54,0.31),
 "Park":Vector2(0.52,0.47), "Shop":Vector2(0.31,0.57),
 "Vet Clinic":Vector2(0.77,0.55), "Beach":Vector2(0.71,0.78),
 "Harbor":Vector2(0.45,0.77), "Keeper’s Cottage":Vector2(0.86,0.38),
 "West path":Vector2(0.37,0.38), "Club path":Vector2(0.54,0.38),
 "Shop path":Vector2(0.43,0.55), "East path":Vector2(0.65,0.48),
 "South path":Vector2(0.56,0.61), "Beach path":Vector2(0.57,0.70),
 "Harbor path":Vector2(0.49,0.67), "Cottage path":Vector2(0.82,0.48)
}
const PATH_LINKS = [
 ["Home","West path"],["West path","Park"],
 ["Puppy Club","Club path"],["Club path","Park"],
 ["Shop","Shop path"],["Shop path","Park"],
 ["Vet Clinic","East path"],["East path","Park"],
 ["Park","South path"],["South path","Beach path"],["Beach path","Beach"],
 ["South path","Harbor path"],["Harbor path","Harbor"],
 ["Vet Clinic","Cottage path"],["Cottage path","Keeper’s Cottage"]
]
const PLACES = {
 "Harbor": {"point": Vector2(0.43, 0.84), "text": "Meet Owen at the ferry office.", "art": "Harbor"},
 "Keeper’s Cottage": {"point": Vector2(0.90, 0.35), "text": "Meet Ren beside the lighthouse.", "art": "Keeper’s Cottage"},
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
 var ambience = AmbientLife.new()
 ambience.location = "Island"
 map_image.add_child(ambience)
 var places = PLACES.keys()
 for new_place in ["Harbor", "Keeper’s Cottage"]:
  places.erase(new_place)
  places.append(new_place)
 for place in places:
  var caption = "Cottage" if place == "Keeper’s Cottage" else place
  var pin = UI.button(caption, travel_to.bind(place), UI.PLACE_COLORS[place])
  pin.custom_minimum_size = Vector2(160 if place in ["Park", "Shop", "Home", "Beach"] else 210, 80)
  pin.add_theme_font_size_override("font_size", 22)
  pin.icon = UI.place_icon(place)
  pin.expand_icon = true
  pin.add_theme_constant_override("icon_max_width", 38)
  canvas.add_child(pin)
  pins[place] = pin
 canvas.resized.connect(place_pins)
 selected = host.current_place if host.current_place in PLACES else "Home"
 map_dog = PuppyActor.new()
 map_dog.controlled = true
 canvas.add_child(map_dog)
 map_dog.set_process(false)
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

 var occupied: Array[Rect2] = []
 for place in pins:
  var pin: Button = pins[place]
  var safe = UI.safe_insets()
  var lower = Vector2(safe.left, safe.top + 110)
  var upper = canvas.size - pin.size - Vector2(safe.right, safe.bottom + 24)
  var xs = [pin.position.x, lower.x, upper.x]
  var ys = [pin.position.y, lower.y, upper.y]
  for rect in occupied:
   xs.append(rect.position.x - pin.size.x - 12)
   xs.append(rect.end.x + 12)
   ys.append(rect.position.y - pin.size.y - 12)
   ys.append(rect.end.y + 12)
  var best = pin.position
  var distance = INF
  for x in xs:
   for y in ys:
    var candidate = Vector2(x, y)
    if candidate.x < lower.x or candidate.y < lower.y or candidate.x > upper.x or candidate.y > upper.y:
     continue
    var bounds = Rect2(candidate, pin.size)
    var free = true
    for rect in occupied:
     if bounds.grow(5).intersects(rect):
      free = false
      break
    if free and candidate.distance_squared_to(pin.position) < distance:
     best = candidate
     distance = candidate.distance_squared_to(pin.position)
  pin.position = best
  occupied.append(Rect2(best, pin.size))
 if is_instance_valid(map_dog):
  map_dog.scale = Vector2.ONE*clampf(map_rect.size.x/1280.0*0.34,0.28,0.46)
  if not travelling:
   map_dog.position = map_rect.position + FOOT_POINTS.get(foot_location(selected), FOOT_POINTS.Home)*map_rect.size
   map_dog.set_pose(Game.resting)
   map_dog.sprite.flip_h = false

func travel_to(place: String) -> void:
 if not PLACES.has(place) or travelling:
  return
 target_place = place
 var nodes = route_between(selected,place)
 travel_path = PackedVector2Array()
 for node in nodes:
  travel_path.append(FOOT_POINTS[node])
 if travel_path.size() < 2:
  host.visit(place)
  return
 travelling = true
 travel_clock = 0
 var length = 0.0
 for index in range(1,travel_path.size()):
  length += ((travel_path[index]-travel_path[index-1])*map_rect.size).length()
 travel_duration = clampf(length/460.0,1.0,2.2)
 map_dog.wake_briefly()
 for pin in pins.values():
  pin.disabled = true
 host.menu_button.disabled = true
 host.back_button.disabled = true

static func foot_location(place: String) -> String:
 # The locked tower is viewed from the cottage path; the dog never crosses open water.
 return "Keeper’s Cottage" if place == "Lighthouse" else place

static func route_between(origin: String, destination: String) -> Array:
 origin = foot_location(origin)
 destination = foot_location(destination)
 if origin not in FOOT_POINTS or destination not in FOOT_POINTS:
  return []
 var queue = [origin]
 var previous = {origin:""}
 while not queue.is_empty():
  var current = queue.pop_front()
  if current == destination:
   break
  for link in PATH_LINKS:
   var next = link[1] if link[0] == current else (link[0] if link[1] == current else "")
   if next != "" and not previous.has(next):
    previous[next] = current
    queue.append(next)
 if not previous.has(destination):
  return []
 var route = [destination]
 while route[0] != origin:
  route.push_front(previous[route[0]])
 return route

func _process(delta: float) -> void:
 if not travelling or Game.paused_at > 0:
  return
 travel_clock += delta
 var progress = clampf(travel_clock/travel_duration,0,1)
 var eased = smoothstep(0.0,1.0,progress)
 var length = 0.0
 for index in range(1,travel_path.size()):
  length += ((travel_path[index]-travel_path[index-1])*map_rect.size).length()
 var remaining = length*eased
 var next_position = map_rect.position+travel_path[travel_path.size()-1]*map_rect.size
 for index in range(1,travel_path.size()):
  var start = map_rect.position+travel_path[index-1]*map_rect.size
  var end = map_rect.position+travel_path[index]*map_rect.size
  var segment_length = start.distance_to(end)
  if remaining <= segment_length:
   next_position = start.lerp(end,remaining/maxf(0.01,segment_length))
   break
  remaining -= segment_length
 var movement = next_position-map_dog.position
 map_dog.stride_distance += movement.length()/maxf(0.01,map_dog.scale.x)
 map_dog.sprite.flip_h = movement.x < 0 if absf(movement.x) > 0.05 else map_dog.sprite.flip_h
 map_dog.set_walk_pose()
 map_dog.position = next_position
 if progress >= 1.0:
  travelling = false
  selected = target_place
  host.menu_button.disabled = false
  host.back_button.disabled = false
  host.visit(target_place)

func _exit_tree() -> void:
 if is_instance_valid(host):
  if is_instance_valid(host.menu_button):
   host.menu_button.disabled = false
  if is_instance_valid(host.back_button):
   host.back_button.disabled = false
