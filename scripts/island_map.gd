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
const MAX_ZOOM = 3.0
const TAP_SLOP = 10.0
const MOUSE_POINTER = -1
var zoom_level = 1.0
var view_origin = Vector2.ZERO
var previous_view_size = Vector2.ZERO
var pointers: Dictionary = {}
var press_position = Vector2.ZERO
var can_tap = false
var pinch_span = 0.0
var pinch_zoom = 1.0
var pinch_anchor = Vector2.ZERO
var pan_hint: Label
var signs: Dictionary = {}
const LANDMARKS = {
 "Home":Rect2(.145,.16,.15,.15),"Puppy Club":Rect2(.455,.07,.17,.24),
 "Shop":Rect2(.24,.42,.15,.18),"Vet Clinic":Rect2(.686,.38,.18,.18),
 "Lighthouse":Rect2(.86,.045,.10,.19),"Keeper’s Cottage":Rect2(.905,.198,.075,.095),
 "Park":Rect2(.465,.36,.095,.13),"Beach":Rect2(.59,.63,.29,.18),"Harbor":Rect2(.33,.73,.15,.17)
}
const SIGN_POINTS = {
 "Home":Vector2(.213,.247),"Puppy Club":Vector2(.568,.255),"Shop":Vector2(.312,.49),
 "Vet Clinic":Vector2(.79,.493),"Lighthouse":Vector2(.86,.19),"Keeper’s Cottage":Vector2(.86,.31),
 "Park":Vector2(.60,.53),"Beach":Vector2(.635,.666),"Harbor":Vector2(.395,.75)
}

const FOOT_POINTS = {
 "Home":Vector2(0.29,0.329), "Puppy Club":Vector2(0.491,0.324),
 "Park":Vector2(0.525,0.53), "Shop":Vector2(0.391,0.563),
 "Vet Clinic":Vector2(0.708,0.55), "Beach":Vector2(0.712,0.80),
 "Harbor":Vector2(0.317,0.823), "Keeper’s Cottage":Vector2(0.937,0.295),
 "West path":Vector2(0.37,0.38), "Club path":Vector2(0.54,0.38),
 "Shop path":Vector2(0.43,0.55), "East path":Vector2(0.61,0.50),
 "South path":Vector2(0.505,0.645), "Beach path":Vector2(0.57,0.71),
 "Harbor path":Vector2(0.46,0.68), "Clinic side":Vector2(0.84,0.54),
 "Clinic corner":Vector2(0.86,0.47), "Cottage path":Vector2(0.846,0.405),
 "Bridge path":Vector2(0.875,0.34),
 "West plaza":Vector2(0.42,0.44), "Lower plaza":Vector2(0.455,0.51),
 "Club bend":Vector2(0.585,0.395), "East plaza":Vector2(0.61,0.445),
 "Clinic approach":Vector2(0.69,0.55), "Pier path":Vector2(0.425,0.72),
 "Home entry":Vector2(0.295,0.34), "Home steps":Vector2(0.30,0.36), "Home landing":Vector2(0.325,0.39)
}
const PATH_LINKS = [
 ["Home","Home entry"],["Home entry","Home steps"],["Home steps","Home landing"],["Home landing","West path"],["West path","West plaza"],
 ["West plaza","Lower plaza"],["Lower plaza","Park"],
 ["Puppy Club","Club path"],["Club path","Club bend"],
 ["Club bend","East plaza"],["East plaza","East path"],
 ["Shop","Shop path"],["Shop path","Park"],
 ["Vet Clinic","Clinic approach"],["Clinic approach","East path"],["East path","Park"],
 ["Park","South path"],["South path","Beach path"],["Beach path","Beach"],
 ["South path","Harbor path"],["Harbor path","Pier path"],["Pier path","Harbor"],
 ["Vet Clinic","Clinic side"],["Clinic side","Clinic corner"],
 ["Clinic corner","Cottage path"],["Cottage path","Bridge path"],
 ["Bridge path","Keeper’s Cottage"]
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
 "Lighthouse": {"point": Vector2(0.77, 0.13), "text": "Help Ren restore the beacon, then visit the observation room.", "art": "Lighthouse"}
}
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var bg = TextureRect.new()
 var sea = GradientTexture2D.new()
 sea.gradient = Gradient.new()
 sea.gradient.colors = PackedColorArray([Color("71c6ed"),Color("20b8d7")])
 sea.fill_from = Vector2(0,0)
 sea.fill_to = Vector2(0,1)
 bg.texture = sea
 Daylight.apply_to(bg,"Map surround")
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margins = {"left": 0, "right": 0, "top": 0, "bottom": 0}
 for edge in margins:
  inset.add_theme_constant_override("margin_" + edge, margins[edge])
 add_child(inset)
 var layout = Control.new()
 inset.add_child(layout)
 canvas = Control.new()
 canvas.clip_contents = true
 canvas.mouse_filter = Control.MOUSE_FILTER_STOP
 canvas.gui_input.connect(pan_input)
 canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layout.add_child(canvas)
 map_image = TextureRect.new()
 map_image.texture = Art.ISLAND
 Daylight.apply_to(map_image, "Island")
 map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 map_image.stretch_mode = TextureRect.STRETCH_SCALE
 map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
  # Use the same gesture surface over signs and scenery. Buttons still support focus and activation.
  pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
  pin.custom_minimum_size=Vector2(64,44)
  for state in ["normal","hover","pressed","disabled","focus"]:
   pin.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  for state in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:
   pin.add_theme_color_override(state,Color.TRANSPARENT)
  var plaque=Panel.new()
  plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var wood=UI.style(Color("eee0c3"),2)
  wood.set_border_width_all(1)
  wood.border_color=Color("755a40")
  plaque.add_theme_stylebox_override("panel",wood)
  pin.add_child(plaque)
  if place in ["Park","Harbor","Lighthouse","Keeper’s Cottage"]:
   var post=ColorRect.new()
   post.color=Color("8f7353")
   post.mouse_filter=Control.MOUSE_FILTER_IGNORE
   plaque.add_child(post)
   plaque.move_child(post,0)
   post.set_meta("sign_post",true)
  var words=UI.label(caption,16,Color("574330"))
  words.autowrap_mode=TextServer.AUTOWRAP_OFF
  words.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  plaque.add_child(words)
  signs[place]=plaque
  canvas.add_child(pin)
  pin.z_index = 10
  pins[place] = pin
 canvas.resized.connect(place_pins)
 selected = host.current_place if host.current_place in PLACES else "Home"
 map_dog = PuppyActor.new()
 map_dog.controlled = true
 map_dog.include_actor_scale_in_width_limit = true
 map_dog.z_index = 1
 canvas.add_child(map_dog)
 map_dog.sleep_material.set_shader_parameter("small_sprite",true)
 map_dog.style_material.set_shader_parameter("small_sprite",true)
 map_dog.set_process(false)
 Game.stage_reached.connect(func(_stage):
  map_dog.set_breed()
  place_pins()
 )
 pan_hint = UI.label("Drag to explore · Pinch to zoom",20,UI.INK)
 pan_hint.custom_minimum_size=Vector2(320,30)
 pan_hint.autowrap_mode=TextServer.AUTOWRAP_OFF
 pan_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(pan_hint)
 call_deferred("place_pins")

func pan_input(event: InputEvent) -> void:
 if travelling or event.device == InputEvent.DEVICE_ID_EMULATION or not map_rect.has_area():
  return
 if event is InputEventScreenTouch:
  if event.pressed:
   begin_pointer(event.index,event.position)
  else:
   end_pointer(event.index,event.position,event.canceled)
 elif event is InputEventScreenDrag:
  move_pointer(event.index,event.position)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:
   begin_pointer(MOUSE_POINTER,event.position)
  else:
   end_pointer(MOUSE_POINTER,event.position,event.canceled)
 elif event is InputEventMouseMotion:
  move_pointer(MOUSE_POINTER,event.position)

func begin_pointer(id: int, point: Vector2) -> void:
 pointers[id]=point
 can_tap=pointers.size()==1
 if can_tap:
  press_position=point
 elif pointers.size()==2:
  start_pinch()

func start_pinch() -> void:
 var points=pointers.values()
 pinch_span=points[0].distance_to(points[1])
 pinch_zoom=zoom_level
 pinch_anchor=((points[0]+points[1])*.5-map_rect.position)/map_rect.size

func move_pointer(id: int, point: Vector2) -> void:
 if not pointers.has(id): return
 var previous: Vector2=pointers[id]
 pointers[id]=point
 if pointers.size()>=2:
  var points=pointers.values()
  var span: float=points[0].distance_to(points[1])
  if pinch_span<1.0:
   start_pinch()
   return
  var new_zoom=clampf(pinch_zoom*span/pinch_span,1.0,MAX_ZOOM)
  view_origin=(points[0]+points[1])*.5-pinch_anchor*map_rect.size*(new_zoom/zoom_level)
  zoom_level=new_zoom
 else:
  if can_tap:
   if point.distance_to(press_position)<TAP_SLOP: return
   can_tap=false
   previous=press_position
  view_origin+=point-previous
 place_pins()

func end_pointer(id: int, point: Vector2, canceled: bool) -> void:
 if not pointers.erase(id): return
 var tapped=can_tap and not canceled and point.distance_to(press_position)<TAP_SLOP
 can_tap=false
 if pointers.size()>=2: start_pinch()
 if not tapped: return
 for place in pins:
  if pins[place].get_rect().has_point(point):
   travel_to(place)
   return
 for place in LANDMARKS:
  if landmark_rect(place).has_point(point):
   travel_to(place)
   return

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
  pointers.clear()
  can_tap=false

func landmark_rect(place: String) -> Rect2:
 var region: Rect2=LANDMARKS[place]
 return Rect2(map_rect.position+region.position*map_rect.size,region.size*map_rect.size)

func place_pins() -> void:
 if canvas.size.x <= 0 or canvas.size.y <= 0:
  return
 var safe = UI.safe_insets()
 # Fill wide phones without squashing the island into a short strip.
 # Keep the upper coastline in view; the extra crop comes mostly from the sea below the harbor.
 var artwork_size = map_image.texture.get_size()
 var zoom = maxf(canvas.size.x/artwork_size.x,canvas.size.y/artwork_size.y)
 var drawn_size = (artwork_size*zoom).max(canvas.size)*zoom_level
 var overflow = drawn_size-canvas.size
 var portrait = canvas.size.y>canvas.size.x
 if previous_view_size!=canvas.size:
  pointers.clear()
  can_tap=false
  if zoom_level>1 and map_rect.has_area():
   var center=(previous_view_size*.5-map_rect.position)/map_rect.size
   view_origin=canvas.size*.5-center*drawn_size
  else:
   view_origin=Vector2(-overflow.x*.5,-overflow.y*.2)
   if portrait:
    view_origin.x=canvas.size.x*.5-FOOT_POINTS[foot_location(selected)].x*drawn_size.x
  previous_view_size=canvas.size
 view_origin=view_origin.clamp(-overflow,Vector2.ZERO)
 map_rect=Rect2(view_origin,drawn_size)
 pan_hint.visible=portrait
 pan_hint.position=Vector2(safe.left,safe.top+84)
 map_image.position = map_rect.position
 map_image.size = map_rect.size
 for place in pins:
  var pin: Button=pins[place]
  var plaque: Panel=signs[place]
  var words=plaque.get_child(plaque.get_child_count()-1)
  var font=clampi(roundi(map_rect.size.x/1558.0*16),14,26)
  pin.add_theme_font_size_override("font_size",font)
  words.add_theme_font_size_override("font_size",font)
  var width=maxf(64,words.get_minimum_size().x+18)
  var height=font+12.0
  plaque.size=Vector2(width,height)
  pin.size=Vector2(width,maxf(44,height))
  pin.position=map_rect.position+SIGN_POINTS[place]*map_rect.size-pin.size*.5
  plaque.position=Vector2(0,(pin.size.y-height)*.5)
  for child in plaque.get_children():
   if child.has_meta("sign_post"):
    child.position=Vector2(width*.5-3,height-1)
    child.size=Vector2(6,16)
  pin.tooltip_text=place
 if is_instance_valid(map_dog):
  map_dog.scale = Vector2.ONE*clampf(map_rect.size.x/zoom_level/1280.0*0.34,0.28,0.46)*zoom_level
  map_dog.screen_width_limit = map_rect.size.x * 0.06
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
 travel_duration = clampf(length/240.0,1.2,5.5)
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
 var blue=float(Daylight.material.get_shader_parameter("night_amount"))
 for sign in signs.values(): sign.modulate=Color.WHITE.lerp(Color("a9b7d0"),blue*.7)
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
 map_dog.stride_distance += minf(movement.length()/maxf(0.01,map_dog.scale.x),delta*map_dog.stride_length()*1.6)
 map_dog.sprite.flip_h = movement.x < 0 if absf(movement.x) > 0.05 else map_dog.sprite.flip_h
 map_dog.set_walk_pose()
 map_dog.position = next_position
 if canvas.size.y>canvas.size.x or zoom_level>1.0:
  var old_origin=map_rect.position
  view_origin.x+=canvas.size.x*.5-map_dog.position.x
  if zoom_level>1.0: view_origin.y+=canvas.size.y*.5-map_dog.position.y
  place_pins()
  map_dog.position+=map_rect.position-old_origin
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
