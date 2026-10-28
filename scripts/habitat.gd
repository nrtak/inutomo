class_name Habitat
extends Control

var location = "Home"
var puppy: PuppyActor
var world: Node2D
var background: TextureRect
var discovery: Sprite2D
var ball: Sprite2D
var view_offset = Vector2.ZERO

func _ready() -> void:
	Sound.set_location(location)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = TextureRect.new()
	background.texture = Art.BACKGROUNDS.get(location, Art.HOME)
	Daylight.apply_to(background, location)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.size = Vector2(1280, 720)
	world = Node2D.new()
	add_child(world)
	world.add_child(background)
	if location == "Home":
		add_home_decor()
	puppy = PuppyActor.new()
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
		bed.position = Vector2([550.0, 650.0, 760.0][Game.life.spot], 505)
		world.add_child(bed)
	if Game.items.get(Game.life.toy, 0) > 0:
		var toy = Sprite2D.new()
		toy.texture = Goods.picture(Game.life.toy)
		toy.scale = Vector2.ONE * (55.0 / toy.texture.get_width())
		toy.position = Vector2(850, 525)
		world.add_child(toy)
	for index in Game.life.keepsakes.size():
		var keepsake = Sprite2D.new()
		var kind = IslandLife.KEEPSAKES.find(Game.life.keepsakes[index])
		keepsake.texture = load("res://assets/ui/" + IslandLife.KEEPSAKE_ICONS[maxi(0, kind)] + ".svg")
		keepsake.scale = Vector2.ONE * 0.35
		keepsake.position = Vector2(1050 + index * 18, 400)
		world.add_child(keepsake)

func _resize_world() -> void:
	if world:
		var zoom = 1.42 if location == "Home" else 1.0
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
		# Ignore taps on furniture, railings, water and other non-walkable scenery.
		if WalkArea.contains(puppy.walk_area, point):
			puppy.request_move(point)

func set_walk_stop(index: int) -> void:
	discovery.texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][index] + ".svg")
	discovery.position = WalkArea.WALK_STOPS[index] + Vector2(0, -8)
	discovery.scale = Vector2.ONE * 0.7
	discovery.visible = true
