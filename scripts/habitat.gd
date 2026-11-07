class_name Habitat
extends Control

signal welcome_ball_rolled

var location = "Home"
var location_presentation = false
var puppy: PuppyActor
var world: Node2D
var background: TextureRect
var discovery: Sprite2D
var ball: Sprite2D
var home_toy: Sprite2D
var playmate: Sprite2D
var playmate_shadow: Sprite2D
var playmate_height: float = 170.0
var visiting_buddy = ""
var playmate_name: Label
var shared_clock = -1.0
var shared_kind = ""
var shared_name = ""
var playdate_tween: Tween
var restoration: Node2D
var decor_targets: Dictionary = {}
var decor_sprites: Dictionary = {}
var view_offset = Vector2.ZERO
var welcome_roll_ready = false
var ball_dragging = false
var ball_origin = Vector2(610,578)
var cinematic = false
var moment_input: Callable

func _ready() -> void:
	Sound.set_location(location)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = TextureRect.new()
	background.texture = BeachStyle.BACKGROUND if location == "Beach" and location_presentation else Art.BACKGROUNDS.get(location, Art.HOME)
	Daylight.apply_to(background, "Beach Arrival" if location == "Beach" and location_presentation else location)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.size = Vector2(1280, 720)
	world = Node2D.new()
	add_child(world)
	world.add_child(background)
	var ambience = AmbientLife.new()
	ambience.location = "Beach Arrival" if location == "Beach" and location_presentation else location
	background.add_child(ambience)
	if location == "Home":
		add_home_decor()
	if location in ["Home","Puppy Club"] and Game.life.connections.mystery==5:
		var memory = load("res://scripts/island_memory_visual.gd").new()
		memory.name = "IslandMemoryVisual"
		memory.location = location
		world.add_child(memory)
	if location == "Keeper’s Cottage":
		restoration = load("res://scripts/restoration_visual.gd").new()
		world.add_child(restoration)
	puppy = PuppyActor.new()
	puppy.presentation_style = "Beach" if location == "Beach" and location_presentation else ""
	puppy.home_interactions = location == "Home"
	world.add_child(puppy)
	Game.nap_actor = weakref(puppy)
	puppy.walk_area = WalkArea.AREAS.get(location, WalkArea.AREAS.Home)
	puppy.barriers = WalkArea.barriers_for(location)
	if location=="Home" and Game.items.get(Game.life.bed,0)>0:
		puppy.bed_barrier = Rect2(IslandLife.home_point(Game,"Rest")+Vector2(-132,-62),Vector2(264,124))
	puppy.position = WalkArea.SPAWNS.get(location, WalkArea.SPAWNS.Home)
	if location == "Home" and Game.resting and not Game.life.bed.is_empty():
		puppy.position.x = [550.0, 650.0, 760.0][Game.life.spot]
	puppy.target = puppy.position
	puppy.bounds = Rect2(puppy.walk_area[0], Vector2.ZERO)
	for point in puppy.walk_area:
		puppy.bounds = puppy.bounds.expand(point)
	ball = Sprite2D.new()
	ball.texture = Goods.picture("Toy")
	ball.material = UI.art_cutout()
	ball.scale = Vector2.ONE * (50.0 / ball.texture.get_width())
	ball.visible = false
	world.add_child(ball)
	discovery = Sprite2D.new()
	discovery.visible = false
	world.add_child(discovery)
	resized.connect(_resize_world)
	_resize_world()
	if location == "Home" and Game.life.welcome_day.guest:
		visiting_buddy = "Momo"
		show_playmate()

func add_home_decor() -> void:
	if Game.items.get(Game.life.bed, 0) > 0:
		var bed = Sprite2D.new()
		bed.texture = Goods.picture(Game.life.bed)
		bed.material = UI.art_cutout()
		bed.scale = Vector2(250.0 / bed.texture.get_width(), 100.0 / bed.texture.get_height())
		bed.position = IslandLife.home_point(Game, "Rest")
		decor_targets.Rest = bed.position
		decor_sprites.Rest = bed
		world.add_child(bed)
	if Game.items.get(Game.life.toy, 0) > 0:
		var toy = Sprite2D.new()
		home_toy = toy
		toy.texture = Goods.picture(Game.life.toy)
		toy.material = UI.art_cutout()
		toy.scale = Vector2.ONE * (55.0 / toy.texture.get_width())
		toy.position = IslandLife.home_point(Game, "Play")
		decor_targets.Play = toy.position
		decor_sprites.Play = toy
		world.add_child(toy)
	if Game.life.bowl:
		var bowl = Sprite2D.new()
		bowl.texture = Goods.picture("PuppyMeal")
		bowl.material = UI.art_cutout()
		bowl.scale = Vector2.ONE * (110.0 / bowl.texture.get_width())
		bowl.position = IslandLife.home_point(Game, "Feed")
		bowl.offset.y = -48
		decor_targets.Feed = bowl.position
		decor_sprites.Feed = bowl
		world.add_child(bowl)
	for index in Game.life.keepsakes.size():
		var keepsake = Sprite2D.new()
		var kind = IslandLife.KEEPSAKES.find(Game.life.keepsakes[index])
		keepsake.texture = load("res://assets/ui/" + IslandLife.KEEPSAKE_ICONS[maxi(0, kind)] + ".svg")
		keepsake.scale = Vector2.ONE * 0.35
		keepsake.position = Vector2(1050 + index * 18, 400)
		world.add_child(keepsake)

func _resize_world() -> void:
	if world:
		if location == "Beach" and location_presentation:
			world.scale = Vector2.ONE
			world.position = Vector2.ZERO
			background.size = size
			if is_instance_valid(puppy):
				var safe = UI.safe_insets()
				var column_left = size.x-safe.right-BeachStyle.column_width(size,safe)
				puppy.portrait_width = maxf(180,minf(320,(column_left-size.x*0.50-26)*2))
				puppy.portrait_height = minf(325,size.y*0.45)
				puppy.walk_area = PackedVector2Array([Vector2(size.x*0.38,size.y*0.73),Vector2(size.x*0.64,size.y*0.73),Vector2(size.x*0.64,size.y*0.94),Vector2(size.x*0.38,size.y*0.94)])
				puppy.position = Vector2(size.x*0.50,size.y*0.92)
				puppy.target = puppy.position
			return
		var zoom = 1.42 if not cinematic and (location == "Home" or not is_zero_approx(view_offset.x)) else 1.0
		var factor = maxf(size.x / 1280.0, size.y / 720.0) * zoom
		world.scale = Vector2.ONE * factor
		var focus = Vector2(650,410) if location == "Home" and not cinematic else Vector2(640,410 if not is_zero_approx(view_offset.x) else 360)
		world.position = size * 0.5 - focus * factor + view_offset
		background.position.y = maxf(0,-world.position.y/factor) if location in ["Lighthouse","Keeper’s Cottage"] else 0.0
		if is_instance_valid(restoration):
			restoration.position = background.position

func _gui_input(event: InputEvent) -> void:
	if moment_input.is_valid() and moment_input.call(event):
		accept_event()
		return
	if welcome_roll_ready and Game.can_explore() and Game.paused_at <= 0:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var point = (event.position - world.position) / world.scale
			if event.pressed and ball.get_rect().grow(16.0 / maxf(0.01,ball.scale.x)).has_point(ball.to_local(world.to_global(point))):
				ball_dragging = true
				accept_event()
				return
			if not event.pressed and ball_dragging:
				ball_dragging = false
				if point.distance_to(buddy_origin()) <= 85 and point.distance_to(ball_origin) >= 45:
					welcome_roll_ready = false
					welcome_ball_rolled.emit()
				else:
					ball.position = ball_origin
				accept_event()
				return
		elif event is InputEventMouseMotion and ball_dragging:
			ball.position = WalkArea.nearest(puppy.walk_area, (event.position - world.position) / world.scale)
			accept_event()
			return
	if event is InputEventMouseButton and event.pressed and (not puppy.controlled or puppy.location_portrait):
		var point = (event.position - world.position) / world.scale
		if location == "Home" and is_instance_valid(playmate) and playmate.get_rect().has_point(playmate.to_local(world.to_global(point))):
			if Game.pet_puppy():
				animate_shared_game("Mirror tricks")
			accept_event()
			return
		var puppy_point = puppy.sprite.to_local(world.to_global(point))
		if puppy.sprite.get_rect().has_point(puppy_point):
			Game.pet_puppy()
			accept_event()
			return
		if location == "Home":
			for action in decor_targets:
				if decor_contains(action, point):
					interact_decor(action)
					accept_event()
					return
		# Ignore taps on furniture, railings, water and other non-walkable scenery.
		if WalkArea.contains(puppy.walk_area, point):
			puppy.request_move(point)

func interact_decor(action: String) -> void:
	if location != "Home" or action not in decor_targets:
		return
	if action == "Rest" and Game.resting:
		Game.say("Already enjoying a cozy rest.")
		return
	Game.action(action)

func set_walk_stop(index: int) -> void:
	discovery.texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][index] + ".svg")
	discovery.position = WalkArea.WALK_STOPS[index] + Vector2(0, -8)
	discovery.scale = Vector2.ONE * 0.7
	discovery.visible = true

func show_playmate() -> void:
	if is_instance_valid(playmate):
		update_playmate()
		return
	playmate_shadow = Sprite2D.new()
	playmate_shadow.texture = preload("res://assets/puppies/shadow.svg")
	playmate_shadow.scale = Vector2(1.05, 0.65) * (playmate_height / 170.0)
	world.add_child(playmate_shadow)
	playmate = Sprite2D.new()
	playmate.texture = Art.PUPPIES.Puppy
	var style = ShaderMaterial.new()
	style.shader = preload("res://scripts/dog_style.gdshader")
	style.set_shader_parameter("recolor", true)
	style.set_shader_parameter("bandana", Color("ef8b9b"))
	playmate.material = style
	playmate.scale = Vector2.ONE * (playmate_height / playmate.texture.get_height())
	playmate.offset.y = -playmate.texture.get_height() * 0.5
	playmate.position = buddy_origin()
	world.add_child(playmate)
	playmate_name = UI.label("",19,UI.INK)
	world.add_child(playmate_name)
	update_playmate()
	playmate_shadow.position = playmate.position + Vector2(0, -4)

func companion_name() -> String:
	return visiting_buddy if not visiting_buddy.is_empty() else IslandAdventure.companion(Game)

func buddy_origin() -> Vector2:
	return Vector2(775, 505) if location == "Home" else Vector2(770, 580)

func animate_playdate(step: int) -> void:
	shared_clock = -1.0
	discovery.visible = false
	show_playmate()
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()
	ball.visible = false
	playmate.rotation = 0
	playmate.modulate = Color.WHITE
	playmate.region_enabled = false
	playmate.texture = Art.PUPPIES[IslandAdventure.BUDDIES[companion_name()].breed]
	playmate.scale = Vector2.ONE * (170.0 / playmate.texture.get_height())
	playmate.offset = Vector2(0, -playmate.texture.get_height() * 0.5)
	playmate.position = Vector2(770, 580)
	playdate_tween = create_tween()
	if step == 1:
		var familiar = IslandAdventure.buddy_visits(Game,companion_name())>=2
		var arrival = Vector2(680 if familiar else 720,580)
		playdate_tween.tween_method(func(weight: float): show_buddy_walk(Vector2(770,580),arrival,weight),0.0,1.0,0.9 if familiar else 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		playdate_tween.tween_callback(func(): update_playmate(true))
		playdate_tween.tween_property(playmate,"rotation",-0.06,0.3)
		playdate_tween.tween_property(playmate,"rotation",0.0,0.3)
	elif step == 2:
		ball.rotation = 0
		ball.visible = true
		ball.position = Vector2(625,580)
		ball.scale = Vector2.ONE * (38.0 / ball.texture.get_width())
		playdate_tween.tween_property(ball,"position",Vector2(750,580),0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		playdate_tween.parallel().tween_property(ball,"rotation",TAU,0.9)
		playdate_tween.tween_property(ball,"position",Vector2(625,580),0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		playdate_tween.parallel().tween_property(playmate,"position:y",574.0,0.3)
		playdate_tween.tween_property(playmate,"position:y",580.0,0.3)
		playdate_tween.tween_callback(func(): ball.visible = false)
	else:
		playmate.texture = Art.SLEEP_TEXTURES[IslandAdventure.BUDDIES[companion_name()].breed]
		playmate.region_enabled = true
		playmate.region_rect = Rect2(Vector2.ZERO,playmate.texture.get_size())
		playmate.offset = Vector2(0,-playmate.region_rect.size.y*0.5)
		playmate.scale = Vector2.ONE * (110.0 / playmate.region_rect.size.y)
		playdate_tween.tween_property(playmate,"modulate",Color("fff3da"),0.7)

func _exit_tree() -> void:
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()

func roll_sand_ball() -> void:
	if location != "Beach":
		return
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()
	var origin = puppy.position
	var destination = WalkArea.nearest(puppy.walk_area,origin + Vector2(90, 0))
	puppy.wake_briefly()
	puppy.awake_remaining = 20
	puppy.reaction_time = 0
	puppy.target = destination
	puppy.decision = 5
	ball.visible = true
	ball.position = origin
	ball.rotation = 0
	ball.scale = Vector2.ONE * (38.0 / ball.texture.get_width())
	playdate_tween = create_tween()
	playdate_tween.tween_property(ball,"position",destination,1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	playdate_tween.parallel().tween_property(ball,"rotation",TAU,1.3)
	playdate_tween.tween_callback(func(): puppy.target = origin)
	playdate_tween.tween_property(ball,"position",origin,1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	playdate_tween.tween_callback(func(): ball.visible = false)

func _process(delta: float) -> void:
	if welcome_roll_ready and not Game.can_explore():
		welcome_roll_ready = false
		ball_dragging = false
		ball.visible = false
	if shared_clock >= 0 and Game.paused_at<=0:
		shared_clock += delta
		if shared_kind.begins_with("Welcome"):
			update_welcome_picnic()
		else:
			update_shared_game()
	if is_instance_valid(playmate_shadow):
		playmate_shadow.position = playmate.position + Vector2(0, -4)
		var height = playmate.region_rect.size.y if playmate.region_enabled else playmate.texture.get_height()
		playmate_name.position = playmate.position + Vector2(-55, -height * playmate.scale.y - 32)
	if is_instance_valid(home_toy) and is_instance_valid(puppy):
		home_toy.visible = not cinematic and not puppy.carrying_toy

func present_location_dog() -> void:
	if not location_presentation:
		return
	puppy.controlled = true
	puppy.location_portrait = true
	if location == "Beach":
		puppy.scale = Vector2.ONE
		_resize_world()
		puppy.set_pose(Game.resting)
		return
	puppy.position = WalkArea.nearest(puppy.walk_area, Vector2(660, 650))
	puppy.target = puppy.position
	puppy.portrait_scale_height = 320.0
	puppy.scale = Vector2.ONE * minf(1.85,320.0/(puppy.visible_size.y*puppy.base_scale))

func decor_contains(action: String, point: Vector2) -> bool:
	var prop = decor_sprites.get(action) as Sprite2D
	if not is_instance_valid(prop) or not prop.visible:
		return false
	var local_point = prop.to_local(world.to_global(point))
	return prop.get_rect().grow(6.0 / maxf(0.01, prop.scale.x)).has_point(local_point)

func update_playmate(force_idle: bool = false) -> void:
	var name = companion_name()
	var buddy: Dictionary = IslandAdventure.BUDDIES[name]
	if force_idle or (shared_clock < 0 and (playdate_tween == null or not playdate_tween.is_running())):
		playmate.texture = Art.PUPPIES[buddy.breed]
		playmate.region_enabled = false
		playmate.offset = Vector2(0,-playmate.texture.get_height()*0.5)
		playmate.scale = Vector2.ONE*(playmate_height/playmate.texture.get_height())
	playmate.material.set_shader_parameter("bandana",buddy.color)
	playmate_name.text = name
	playmate_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	playmate_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	playmate_name.size = Vector2(110,30)
	playmate_name.position = buddy_origin() + Vector2(-55,-playmate_height-32)

func animate_shared_game(kind: String) -> void:
	show_playmate()
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()
	ball.visible = false
	discovery.visible = false
	shared_kind = kind
	shared_name = companion_name()
	shared_clock = 0
	playmate.rotation = 0
	playmate.modulate = Color.WHITE
	playmate.flip_h = false
	playmate.position = buddy_origin()
	update_shared_game()

func update_shared_game() -> void:
	if shared_clock >= 3.2 or shared_name != companion_name() or not Game.can_explore():
		shared_clock = -1.0
		discovery.visible = false
		playmate.flip_h = false
		playmate.position = buddy_origin()
		update_playmate()
		return
	var breed: String = IslandAdventure.BUDDIES[shared_name].breed
	playmate.region_enabled = true
	if shared_kind == "Mirror tricks":
		var order = [0,1,2,1,0]
		var index = 1 if Game.reduce_motion else int(order[mini(4,int(shared_clock/3.2*5))])
		playmate.texture = Art.trick_sheet(breed)
		playmate.region_rect = Art.trick_frames(breed,"Paw")[index]
		playmate.scale = Vector2.ONE*(170.0/float(Art.TRICK_DATA[breed].height))
	else:
		var travel = smoothstep(0.0,1.0,minf(1.0,shared_clock/1.2))
		playmate.position = Vector2(770,580).lerp(Vector2(715,580),travel)
		if travel < 1 and not Game.reduce_motion:
			var frame = int(55.0*travel/60.0*8)%8
			playmate.texture = Art.WALKS[breed]
			playmate.region_rect = Art.WALK_REGIONS[breed][frame]
			playmate.scale = Vector2.ONE*(170.0/float(Art.WALK_HEIGHTS[breed]))
			playmate.flip_h = true
		else:
			playmate.texture = Art.PUPPIES[breed]
			playmate.region_rect = Rect2(Vector2.ZERO,playmate.texture.get_size())
			playmate.scale = Vector2.ONE*(170.0/playmate.texture.get_height())
			playmate.flip_h = false
		discovery.visible = travel >= 1
		discovery.texture = Goods.picture("Toy")
		discovery.position = Vector2(675,580)
		discovery.scale = Vector2.ONE*(50.0/discovery.texture.get_width())
	playmate.offset = Vector2(0,-playmate.region_rect.size.y*0.5)
	if shared_kind=="Treasure pals" and shared_clock<1.2 and not Game.reduce_motion:
		var frame = int(55.0*smoothstep(0.0,1.0,shared_clock/1.2)/60.0*8)%8
		playmate.offset.x = float(Art.WALK_ANCHORS[breed][frame])-playmate.region_rect.size.x*0.5

func show_buddy_walk(origin: Vector2, destination: Vector2, weight: float) -> void:
	var breed: String = IslandAdventure.BUDDIES[companion_name()].breed
	playmate.position = origin.lerp(destination,weight)
	var stride = (64.0 if breed=="Puppy" else 104.0)*170.0/(180.0 if breed=="Puppy" else 320.0)
	var frame = int(origin.distance_to(playmate.position)/stride*8)%8
	playmate.texture = Art.WALKS[breed]
	playmate.region_enabled = true
	playmate.region_rect = Art.WALK_REGIONS[breed][frame]
	playmate.scale = Vector2.ONE*(170.0/float(Art.WALK_HEIGHTS[breed]))
	playmate.flip_h = destination.x<origin.x
	var anchor: float = Art.WALK_ANCHORS[breed][frame]
	playmate.offset = Vector2((anchor-playmate.region_rect.size.x*0.5)*(-1 if not playmate.flip_h else 1),-playmate.region_rect.size.y*0.5)

func animate_welcome_picnic(step: int) -> void:
	welcome_roll_ready = false
	ball_dragging = false
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()
	show_playmate()
	shared_name = "Momo"
	shared_kind = "Welcome%d" % step
	shared_clock = 0
	puppy.wake_briefly()
	puppy.awake_remaining = 120
	puppy.decision = 120
	puppy.target = Vector2(565,580) if step == 2 else puppy.position
	ball.visible = step == 2
	ball.scale = Vector2.ONE * (42.0 / ball.texture.get_width())
	update_welcome_picnic()

func update_welcome_picnic() -> void:
	if shared_clock >= 3.2 or not Game.can_explore():
		shared_clock = -1
		ball.visible = false
		playmate.position = buddy_origin()
		playmate.flip_h = false
		update_playmate()
		return
	var walking = shared_kind == "Welcome1" and shared_clock < 1.4 and not Game.reduce_motion
	playmate.region_enabled = true
	if walking:
		var frame = int((45.0 * shared_clock / 1.4) / 55.0 * 8) % 8
		playmate.texture = Art.WALKS["Shiba Inu"]
		playmate.region_rect = Art.WALK_REGIONS["Shiba Inu"][frame]
		playmate.scale = Vector2.ONE * (playmate_height / Art.WALK_HEIGHTS["Shiba Inu"])
		playmate.position = Vector2(825,580).lerp(Vector2(780,580), shared_clock / 1.4)
		playmate.flip_h = true
		var anchor: float = Art.WALK_ANCHORS["Shiba Inu"][frame]
		playmate.offset.x = anchor - playmate.region_rect.size.x * 0.5
	else:
		playmate.texture = Art.SLEEP_TEXTURES["Shiba Inu"] if shared_kind == "Welcome3" else Art.PUPPIES["Shiba Inu"]
		playmate.region_rect = Rect2(Vector2.ZERO, playmate.texture.get_size())
		playmate.scale = Vector2.ONE * ((playmate_height * 0.65 if shared_kind == "Welcome3" else playmate_height) / playmate.texture.get_height())
		playmate.flip_h = false
		playmate.position = Vector2(780,580)
		playmate.offset.x = 0
	playmate.offset.y = -playmate.region_rect.size.y * 0.5
	if shared_kind == "Welcome2":
		ball.position = Vector2(735,578).lerp(Vector2(595,578), 1.0 if Game.reduce_motion else minf(1,shared_clock / 2.4))
		ball.rotation = 0 if Game.reduce_motion else shared_clock * 2

func prepare_welcome_roll() -> void:
	shared_clock = -1
	welcome_roll_ready = true
	ball_dragging = false
	ball.position = ball_origin
	ball.visible = true
	ball.scale = Vector2.ONE * (58.0 / ball.texture.get_width())
	puppy.react_to_care("Come")
	puppy.target = Vector2(555,580)
	puppy.awake_remaining = 120
	puppy.decision = 120
