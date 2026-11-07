extends Control

var host: Control
var step = 1
var pending = -1
var done = false
var props: Array[Sprite2D] = []
var panel: PanelContainer
var content: VBoxContainer
var feedback: Label
var searches: Array[Button] = []
var greeting: Control
var points: Array[Vector2] = []
var modal_paused = false
var dog_was_processing = true
var recovery_button: Button

func _ready() -> void:
	name = "IslandMysteryView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	step = int(Game.life.connections.mystery)
	var spec: Dictionary = IslandConnections.MYSTERY[step]
	var dog = host.habitat.puppy
	dog.controlled = true
	dog.home_interactions = false
	dog.wake_briefly()
	dog.position = WalkArea.nearest(dog.walk_area,Vector2(605,610))
	dog.target = dog.position
	dog.scale = Vector2.ONE*(190.0/(dog.visible_size.y*dog.base_scale))
	dog.reaction_above_head = true
	host.habitat.moment_input = handle_input
	for point in [Vector2(590,575),Vector2(635,600),Vector2(710,610)]:
		points.append(WalkArea.nearest(dog.walk_area,point))
	var pictures: Array = ["leaf","shell","menu_bag"]
	if step==3: pictures = ["club","shell","leaf"]
	for i in 3:
		var item = Sprite2D.new()
		item.texture = load("res://assets/ui/"+pictures[i]+".svg")
		if i==spec.spot:
			item.texture = preload("res://assets/goods/welcome_star.svg") if step==2 else load("res://assets/ui/"+spec.icon+".svg")
			if step==3: item.texture = preload("res://assets/goods/welcome_parcel.svg")
		item.material = UI.art_cutout()
		item.scale = Vector2.ONE*(42.0/item.texture.get_width())
		item.position = points[i]+Vector2(30,-4)
		host.habitat.world.add_child(item)
		props.append(item)
	panel = UI.card()
	add_child(panel)
	content = UI.column(8)
	panel.add_child(content)
	content.add_child(UI.label(spec.title,24,UI.TEAL))
	feedback = UI.label("Follow the clue, then tap a find on the path.",21)
	content.add_child(feedback)
	var captions: Array = {1:["Tree leaf","Path shell","Bench ribbon"],2:["Shore leaf","Washed-up star","Stranded bag"],3:["Paw-mark parcel","Loose shell","Leaf label"]}[step]
	for i in 3:
		var button = UI.location_button(captions[i],props[i].texture,search.bind(i),Color("c8eddd"))
		button.custom_minimum_size = Vector2(0,62)
		button.get_meta("caption").add_theme_font_size_override("font_size",21)
		content.add_child(button)
		searches.append(button)
	recovery_button = UI.button("Rest at Home",host.request_page.bind("Home"),Color("e1d9f6"))
	recovery_button.visible = not IslandConnections.available(Game)
	content.add_child(recovery_button)
	greeting = load("res://scripts/location_greeting.gd").new()
	greeting.texture = {"Ben":Art.BEN,"Kai":Art.KAI,"Owen":Art.OWEN}[spec.person]
	greeting.scene_style = "Anime"
	greeting.character_name = spec.person
	greeting.text = spec.hint
	greeting.duration = 3600
	add_child(greeting)
	resized.connect(arrange)
	arrange.call_deferred()

func arrange() -> void:
	var safe = UI.safe_insets(20)
	var width = clampf(size.x*0.28,290,340)
	panel.position = Vector2(size.x-safe.right-width,safe.top+105)
	panel.custom_minimum_size.x = width
	feedback.custom_minimum_size.x = width-40
	panel.size = Vector2(width,panel.get_combined_minimum_size().y)

func search(index: int) -> void:
	if index<0 or index>=3 or done or pending>=0 or not IslandConnections.available(Game) or obstructed(): return
	pending = index
	host.habitat.puppy.target = points[index]
	feedback.text = IslandConnections.personality_hint(Game,"Discovery")

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for i in props.size():
			var prop = props[i]
			if prop.visible and prop.get_rect().grow(16.0/prop.scale.x).has_point(prop.to_local(host.habitat.get_global_transform()*event.position)):
				search(i)
				break
	return true

func _process(_delta: float) -> void:
	var blocked = obstructed()
	if blocked and not modal_paused:
		modal_paused = true
		dog_was_processing = host.habitat.puppy.is_processing()
		host.habitat.puppy.set_process(false)
	elif not blocked and modal_paused:
		modal_paused = false
		host.habitat.puppy.set_process(dog_was_processing)
	if Game.paused_at>0 or not Game.is_processing() or blocked: return
	recovery_button.visible = not done and not IslandConnections.available(Game)
	for button in searches:
		button.visible = not done and IslandConnections.available(Game)
		button.disabled = pending>=0 or done or not IslandConnections.available(Game)
	if not IslandConnections.available(Game) and pending>=0:
		pending = -1
		host.habitat.puppy.target = host.habitat.puppy.position
		feedback.text = "Your clue is saved. Rest at Home, then come back."
	if pending>=0 and host.habitat.puppy.position.distance_to(host.habitat.puppy.target)<2:
		var result = IslandConnections.advance_mystery(Game,step,IslandConnections.MYSTERY[step].place,pending)
		pending = -1
		feedback.text = result.text if Game.save_error.is_empty() else Game.save_error
		if result.ok:
			done = true
			var dog = host.habitat.puppy
			dog.target = dog.position
			dog.illustrated_pose = "Sniff"
			dog.illustrated_width = 260.0/dog.scale.x
			dog.illustrated_height = 185.0/dog.scale.y
			for prop in props: prop.visible = false
			for button in searches: button.visible = false
			var next = IslandConnections.mystery_step(Game)
			content.add_child(UI.button("Continue at "+next.place,host.request_page.bind(next.place),Color("c8eddd")))
			greeting.visible = false
			arrange.call_deferred()
	elif not IslandConnections.available(Game) and not done:
		feedback.text = "Your clue is saved. Rest at Home, then come back."

func _exit_tree() -> void:
	if is_instance_valid(host.habitat): host.habitat.moment_input = Callable()

func obstructed() -> bool:
	return is_instance_valid(host.navigation_overlay) or is_instance_valid(host.resident_overlay) or is_instance_valid(host.photo_overlay) or is_instance_valid(host.stage_overlay)
