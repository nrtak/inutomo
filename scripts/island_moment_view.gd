extends Control

var host: Control
var kind = "Home"
var phase = "waiting"
var waypoints: Array[Vector2] = []
var bubble: PanelContainer
var speech: CommandHint
var panel: PanelContainer
var content: VBoxContainer
var primary: Button
var prop: Sprite2D
var dragging = false
var elapsed = 0.0
var photo_paused = false
var photo_actor_processing = true
var photo_habitat_processing = true
var last_block = ""
var residents: Array[Sprite2D] = []
var return_point = Vector2(610,610)

func _ready() -> void:
	name = "IslandMomentView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var habitat = host.habitat
	habitat.cinematic = true
	habitat.background.texture = MomentArt.background(kind)
	# Each new painting has its own registered water/treetop masks.
	for child in habitat.background.get_children():
		if child is AmbientLife:
			child.location = "Moment:" + kind
		elif child.get_script() == load("res://scripts/weather_layer.gd"):
			child.location = "Moment:" + kind
	habitat.background.material = Daylight.material_for("Moment:" + kind) if kind != "Lighthouse" else null
	if is_instance_valid(habitat.restoration):
		habitat.restoration.visible = false
	habitat._resize_world()
	habitat.moment_input = handle_input
	var dog = habitat.puppy
	dog.walk_area = PackedVector2Array([Vector2(400,500),Vector2(1000,500),Vector2(1000,660),Vector2(400,660)])
	dog.position = Vector2(880,630) if kind == "Recall" else return_point
	dog.target = dog.position
	dog.bounds = Rect2(400,500,600,160)
	dog.home_interactions = false
	dog.wake_briefly()
	dog.awake_remaining = 3600
	dog.decision = 3600
	dog.scale = Vector2.ONE * (210.0 / (dog.visible_size.y * dog.base_scale))
	dog.illustrated_width = 300.0 / dog.scale.x
	dog.illustrated_height = 250.0 / dog.scale.y
	dog.reaction_above_head = true
	if kind == "Home":
		dog.walk_area = PackedVector2Array([Vector2(430,570),Vector2(850,570),Vector2(920,635),Vector2(430,655)])
		dog.illustrated_pose = "Bow"
		# Keep bowls and floor toys out of the hands-on play lane.
		for item in habitat.decor_sprites.values(): item.visible = false
	if kind in ["Beach", "Lighthouse"]:
		habitat.visiting_buddy = "Momo"
		habitat.playmate_height = 200
		habitat.show_playmate()
		habitat.playmate.position = Vector2(850,630) if kind == "Beach" else Vector2(780,640)
		habitat.playmate_name.visible = false
	match kind:
		"Recall": add_resident("Ben", Vector2(250,620), 370)
		"Beach": add_resident("Kai", Vector2(235,640), 360)
		"Cottage": add_resident("Ren", Vector2(250,640), 360, true)
		"Lighthouse":
			dog.position = Vector2(570,640)
			dog.target = dog.position
			add_resident("Nora", Vector2(250,660), 310)
			add_resident("Ren", Vector2(1040,660), 315)
			dog.modulate = Color("fff0e3")
			habitat.playmate.modulate = Color("fff0e3")
			for person in residents: person.modulate = Color("fff0e3")
	prop = Sprite2D.new()
	prop.texture = Goods.picture("Toy") if kind == "Home" else MomentArt.prop("Shell" if kind == "Beach" else ("Star" if kind == "Lighthouse" else "Glass"))
	prop.material = UI.art_cutout()
	prop.scale = Vector2.ONE * ((64.0 if kind == "Home" else 54.0) / prop.texture.get_width())
	prop.position = Vector2(745,610) if kind == "Home" else (Vector2(735,641) if kind == "Beach" else Vector2(830,630))
	prop.visible = kind in ["Home", "Lighthouse"]
	if kind == "Lighthouse": prop.position = Vector2(675,650)
	habitat.world.add_child(prop)
	build_ui()
	resized.connect(arrange)
	refresh()

func add_resident(person: String, feet: Vector2, height: float, flipped: bool = false) -> void:
	var shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/puppies/shadow.svg")
	shadow.scale = Vector2(1.75,0.8)
	shadow.position = feet + Vector2(0,-4)
	host.habitat.world.add_child(shadow)
	var actor = Sprite2D.new()
	actor.texture = MomentArt.resident(person)
	actor.material = UI.art_cutout()
	actor.offset.y = -actor.texture.get_height() * 0.5
	actor.scale = Vector2.ONE * (height / actor.texture.get_height())
	actor.position = feet
	actor.flip_h = flipped
	host.habitat.world.add_child(actor)
	residents.append(actor)

func build_ui() -> void:
	bubble = UI.card()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	var words = UI.column(4)
	bubble.add_child(words)
	words.add_child(UI.label({"Home":Game.puppy_name,"Recall":"Ben","Beach":"Kai","Cottage":"Ren","Lighthouse":"Nora & Ren"}[kind],23,Color("237d82")))
	speech = UI.hint_label("",21)
	words.add_child(speech)
	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(12,0),Vector2(-4,18),Vector2(40,0)])
	tail.color = Color("fff6e5")
	bubble.add_child(tail)
	bubble.resized.connect(func(): tail.position.y = bubble.size.y-2)
	panel = UI.card()
	add_child(panel)
	content = UI.column(8)
	panel.add_child(content)
	speech.minimum_size_changed.connect(arrange)

func refresh() -> void:
	primary = null
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.add_child(UI.label(IslandMoments.TITLES[kind],25,UI.TEAL))
	last_block = IslandMoments.block_reason(Game, kind)
	if phase == "done":
		add_button("Take a photo", preload("res://assets/ui/camera.svg"), host.open_photo_mode)
		if kind in ["Home","Recall","Beach"]:
			add_button("Play together again",preload("res://assets/ui/heart.svg"),restart)
		elif kind == "Lighthouse":
			add_button("See our keepsake",preload("res://assets/ui/bandana_sunshine.svg"),host.request_page.bind("Life:Wardrobe"))
	elif not last_block.is_empty():
		speech.set_hint(last_block)
		if not Game.can_explore():
			add_button("Rest at Home",preload("res://assets/ui/rest.svg"),host.request_page.bind("Home"))
		elif kind == "Lighthouse" and (not Game.life.story.get("beacon_checked",false) or not Game.life.welcome_day.celebrated):
			var place = "Keeper’s Cottage" if not Game.life.story.get("beacon_checked",false) else "Life:Welcome Day"
			add_button("Visit Ren" if place == "Keeper’s Cottage" else "Visit Nora's picnic",preload("res://assets/ui/heart.svg"),host.request_page.bind(place))
		elif kind == "Cottage" and not Game.life.story.get("path_repaired",false):
			add_button("Help with the path",UI.place_icon("Keeper’s Cottage"),host.request_page.bind("Keeper’s Cottage"))
	else:
		if phase == "waiting":
			speech.set_hint({"Home":"A play bow! Drag the ball along the rug, or tap Roll the ball.","Recall":"Call warmly. Watch those paws follow the clear route around the cones.","Beach":"Momo caught a scent! Let's follow our little explorers.","Cottage":"There's something beside the old mosaic. Shall we follow that nose?","Lighthouse":"You helped bring this light back. There's a place here for all of us."}[kind])
			primary = add_button({"Home":"Roll the ball","Recall":"Call Come","Beach":"Sniff together","Cottage":"Follow that scent","Lighthouse":"Share the light"}[kind],preload("res://assets/ui/heart.svg"),begin)
		elif phase == "ready":
			speech.set_hint("Look beside those little paws. Tap the keepsake to look closer.")
			primary = add_button("Look closer",MomentArt.prop("Shell" if kind == "Beach" else "Glass"),finish)
		else:
			speech.set_hint("Here they come!" if kind == "Recall" else "Follow those happy paws.")
	if kind == "Recall":
		var lesson = UI.button("Other lessons",host.request_page.bind("Life:Training"),Color("fff0bd"))
		lesson.custom_minimum_size.y = 48
		lesson.add_theme_font_size_override("font_size",20)
		content.add_child(lesson)
	arrange.call_deferred()

func add_button(caption: String, picture: Texture2D, action: Callable) -> Button:
	var button = UI.location_button(caption,picture,action,Color("c8eddd"))
	button.custom_minimum_size = Vector2(0,62)
	button.add_theme_font_size_override("font_size",1)
	button.get_meta("picture").offset_right = 65
	button.get_meta("caption").offset_left = 76
	button.get_meta("caption").add_theme_font_size_override("font_size",21)
	content.add_child(button)
	return button

func begin() -> void:
	if phase != "waiting" or not IslandMoments.block_reason(Game,kind).is_empty(): return
	dragging = false
	var dog = host.habitat.puppy
	dog.illustrated_pose = ""
	dog.reaction_time = 0
	dog.wake_briefly()
	dog.awake_remaining = 3600
	dog.decision = 3600
	if kind == "Lighthouse":
		finish()
		return
	phase = "outbound"
	match kind:
		"Home": waypoints = [WalkArea.nearest(dog.walk_area,prop.position)]
		"Recall": waypoints = [Vector2(850,595),Vector2(850,515),Vector2(760,515),Vector2(650,525),Vector2(530,515)]
		"Beach": waypoints = [Vector2(610,630)]
		"Cottage": waypoints = [Vector2(700,620)]
	dog.target = waypoints.pop_front()
	refresh()

func finish() -> void:
	if phase == "done": return
	var result = IslandMoments.complete(Game,kind)
	if not result.ok:
		speech.set_hint(result.text)
		return
	phase = "done"
	host.habitat.puppy.target = host.habitat.puppy.position
	host.habitat.puppy.decision = 3600
	if kind == "Home":
		host.habitat.puppy.illustrated_pose = "Bow"
		prop.position = Vector2(745,610)
		prop.visible = true
	refresh()
	speech.set_hint(result.text if Game.save_error.is_empty() else Game.save_error)

func restart() -> void:
	phase = "waiting"
	if kind == "Home": host.habitat.puppy.illustrated_pose = "Bow"
	if kind == "Recall":
		host.habitat.puppy.position = Vector2(880,630)
		host.habitat.puppy.target = host.habitat.puppy.position
	if kind == "Beach": prop.visible = false
	refresh()

func handle_input(event: InputEvent) -> bool:
	if photo_paused or Game.paused_at > 0 or not Game.can_explore():
		cancel_drag()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point = (event.position - host.habitat.world.position) / host.habitat.world.scale
		if phase == "ready" and event.pressed and prop.get_rect().grow(20/prop.scale.x).has_point(prop.to_local(host.habitat.world.to_global(point))):
			finish()
			return true
		if kind == "Home" and phase == "waiting" and IslandMoments.block_reason(Game,kind).is_empty():
			if event.pressed and prop.get_rect().grow(16/prop.scale.x).has_point(prop.to_local(host.habitat.world.to_global(point))):
				dragging = true
			elif not event.pressed and dragging:
				dragging = false
				if WalkArea.contains(host.habitat.puppy.walk_area,point) and point.distance_to(return_point)>50:
					prop.position = point
					begin()
				else: prop.position = Vector2(745,610)
		return true
	if event is InputEventMouseMotion and dragging:
		prop.position = WalkArea.nearest(host.habitat.puppy.walk_area,(event.position-host.habitat.world.position)/host.habitat.world.scale)
		return true
	return false

func cancel_drag() -> void:
	if dragging:
		dragging = false
		prop.position = Vector2(745,610)

func _process(delta: float) -> void:
	if photo_paused or Game.paused_at > 0:
		cancel_drag()
		return
	if dragging and (phase != "waiting" or not IslandMoments.block_reason(Game,kind).is_empty()):
		cancel_drag()
	elapsed += delta
	var dog = host.habitat.puppy
	if not Game.can_explore() and phase in ["outbound","returning","ready"]:
		phase = "waiting"
		waypoints.clear()
		dog.target = dog.position
		prop.visible = kind in ["Home","Lighthouse"]
		refresh()
	if phase in ["outbound","returning"] and dog.position.distance_to(dog.target)<2:
		if not waypoints.is_empty(): dog.target = waypoints.pop_front()
		elif kind == "Home" and phase == "outbound":
			phase = "returning"
			prop.visible = false
			dog.target = return_point
		elif kind in ["Beach","Cottage"]:
			phase = "ready"
			dog.illustrated_pose = "Sniff"
			prop.visible = true
			if kind == "Beach": show_momo_sniff()
			refresh()
		else: finish()
	if kind == "Beach" and phase == "outbound":
		var friend = host.habitat.playmate
		friend.position = friend.position.move_toward(Vector2(850,630),delta*60)
	if IslandMoments.block_reason(Game,kind) != last_block and phase in ["waiting","ready"]:
		refresh()

func show_momo_sniff() -> void:
	var friend = host.habitat.playmate
	friend.texture = MomentArt.dog("Shiba Inu","Sniff")
	friend.region_enabled = false
	friend.offset = Vector2(0,-friend.texture.get_height()*0.5)
	friend.scale = Vector2.ONE * (270.0/friend.texture.get_width())
	friend.flip_h = true
	friend.position = Vector2(850,630)

func arrange() -> void:
	if not is_instance_valid(panel): return
	var safe = UI.safe_insets(20)
	var width = clampf(size.x*0.28,290,350)
	var controls_left = kind in ["Cottage","Lighthouse"]
	panel.position = Vector2(safe.left if controls_left else size.x-safe.right-width,safe.top+95)
	panel.custom_minimum_size.x = width
	panel.size = Vector2(width,panel.get_combined_minimum_size().y)
	var speech_width = clampf(size.x*0.27,240,330)
	bubble.position = Vector2(maxf(panel.position.x+width+16,size.x*0.28) if controls_left else maxf(safe.left+20,size.x*0.28),safe.top+90)
	bubble.custom_minimum_size.x = speech_width
	speech.custom_minimum_size.x = speech_width-40
	bubble.size = Vector2(speech_width,bubble.get_combined_minimum_size().y)

func set_photo_mode(active: bool) -> void:
	if active:
		cancel_drag()
		photo_actor_processing = host.habitat.puppy.is_processing()
		photo_habitat_processing = host.habitat.is_processing()
	photo_paused = active
	panel.visible = not active
	bubble.visible = not active
	host.habitat.puppy.set_process(false if active else photo_actor_processing)
	host.habitat.set_process(false if active else photo_habitat_processing)

func _exit_tree() -> void:
	if is_instance_valid(host.habitat): host.habitat.moment_input = Callable()
