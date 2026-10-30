class_name Habitat
extends Control

var location = "Home"
var location_presentation = false
var puppy: PuppyActor
var world: Node2D
var background: TextureRect
var discovery: Sprite2D
var ball: Sprite2D
var home_toy: Sprite2D
var playmate: Sprite2D
var playdate_tween: Tween
var restoration: Node2D
var decor_targets: Dictionary = {}
var decor_sprites: Dictionary = {}
var view_offset = Vector2.ZERO

func _ready() -> void:
	Sound.set_location(location)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = TextureRect.new()
	background.texture = preload("res://assets/backgrounds/beach_arrival.png") if location == "Beach" and location_presentation else Art.BACKGROUNDS.get(location, Art.HOME)
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
	if location == "Keeper’s Cottage":
		restoration = load("res://scripts/restoration_visual.gd").new()
		world.add_child(restoration)
	puppy = PuppyActor.new()
	puppy.home_interactions = location == "Home"
	world.add_child(puppy)
	Game.nap_actor = weakref(puppy)
	puppy.walk_area = WalkArea.AREAS.get(location, WalkArea.AREAS.Home)
	puppy.position = WalkArea.SPAWNS.get(location, WalkArea.SPAWNS.Home)
	if location == "Home" and Game.resting and not Game.life.bed.is_empty():
		puppy.position.x = [550.0, 650.0, 760.0][Game.life.spot]
	puppy.target = puppy.position
	puppy.bounds = Rect2(puppy.walk_area[0], Vector2.ZERO)
	for point in puppy.walk_area:
		puppy.bounds = puppy.bounds.expand(point)
	ball = Sprite2D.new()
	ball.texture = preload("res://assets/ui/play.svg")
	ball.scale = Vector2.ONE * 0.5
	ball.visible = false
	world.add_child(ball)
	discovery = Sprite2D.new()
	discovery.visible = false
	world.add_child(discovery)
	resized.connect(_resize_world)
	_resize_world()

func add_home_decor() -> void:
	if Game.items.get(Game.life.bed, 0) > 0:
		var bed = Sprite2D.new()
		bed.texture = Goods.picture(Game.life.bed)
		bed.scale = Vector2(250.0 / bed.texture.get_width(), 100.0 / bed.texture.get_height())
		bed.position = IslandLife.home_point(Game, "Rest")
		decor_targets.Rest = bed.position
		decor_sprites.Rest = bed
		world.add_child(bed)
	if Game.items.get(Game.life.toy, 0) > 0:
		var toy = Sprite2D.new()
		home_toy = toy
		toy.texture = Goods.picture(Game.life.toy)
		toy.scale = Vector2.ONE * (55.0 / toy.texture.get_width())
		toy.position = IslandLife.home_point(Game, "Play")
		decor_targets.Play = toy.position
		decor_sprites.Play = toy
		world.add_child(toy)
	if Game.life.bowl:
		var bowl = Sprite2D.new()
		bowl.texture = Goods.picture("PuppyMeal")
		bowl.scale = Vector2.ONE * (110.0 / bowl.texture.get_width())
		bowl.position = IslandLife.home_point(Game, "Feed")
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
		var zoom = 1.42 if location == "Home" or not is_zero_approx(view_offset.x) else 1.0
		var factor = maxf(size.x / 1280.0, size.y / 720.0) * zoom
		world.scale = Vector2.ONE * factor
		var focus = Vector2(650, 410) if location == "Home" else Vector2(640, 360)
		world.position = size * 0.5 - focus * factor + view_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not puppy.controlled:
		var point = (event.position - world.position) / world.scale
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
		return
	playmate = Sprite2D.new()
	playmate.texture = Art.PUPPIES.Puppy
	var style = ShaderMaterial.new()
	style.shader = preload("res://scripts/dog_style.gdshader")
	style.set_shader_parameter("recolor", true)
	style.set_shader_parameter("bandana", Color("ef8b9b"))
	playmate.material = style
	playmate.scale = Vector2.ONE * (170.0 / playmate.texture.get_height())
	playmate.offset.y = -playmate.texture.get_height() * 0.5
	playmate.position = Vector2(770, 580)
	world.add_child(playmate)

func animate_playdate(step: int) -> void:
	show_playmate()
	if playdate_tween != null and playdate_tween.is_valid():
		playdate_tween.kill()
	ball.visible = false
	playmate.rotation = 0
	playmate.modulate = Color.WHITE
	playmate.region_enabled = false
	playmate.texture = Art.PUPPIES.Puppy
	playmate.scale = Vector2.ONE * (170.0 / playmate.texture.get_height())
	playmate.offset = Vector2(0, -playmate.texture.get_height() * 0.5)
	playmate.position = Vector2(770, 580)
	playdate_tween = create_tween()
	if step == 1:
		playdate_tween.tween_property(playmate,"position",Vector2(700,580),0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
		playmate.texture = Art.PUPPY_SLEEP
		playmate.region_enabled = true
		playmate.region_rect = Rect2(Art.PUPPY_SLEEP_REGION)
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

func _process(_delta: float) -> void:
	if is_instance_valid(home_toy) and is_instance_valid(puppy):
		home_toy.visible = not puppy.carrying_toy

func present_location_dog() -> void:
	if not location_presentation:
		return
	puppy.controlled = true
	puppy.location_portrait = true
	puppy.position = WalkArea.nearest(puppy.walk_area, Vector2(660, 650))
	puppy.target = puppy.position
	puppy.scale = Vector2.ONE * (1.85 if Game.breed == "Puppy" else 1.05)

func decor_contains(action: String, point: Vector2) -> bool:
	var prop = decor_sprites.get(action) as Sprite2D
	if not is_instance_valid(prop) or not prop.visible:
		return false
	var local_point = prop.to_local(world.to_global(point))
	return prop.get_rect().grow(6.0 / maxf(0.01, prop.scale.x)).has_point(local_point)
