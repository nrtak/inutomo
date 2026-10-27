class_name Habitat
extends Control

var location = "Home"
var puppy: PuppyActor
var world: Node2D
var background: TextureRect
var discovery: Sprite2D
var ball: Polygon2D

func _ready() -> void:
	Sound.set_location(location)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = TextureRect.new()
	background.texture = Art.BACKGROUNDS.get(location, Art.HOME)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.size = Vector2(1280, 720)
	world = Node2D.new()
	add_child(world)
	world.add_child(background)
	puppy = PuppyActor.new()
	world.add_child(puppy)
	Game.nap_actor = weakref(puppy)
	puppy.walk_area = WalkArea.AREAS.get(location, WalkArea.AREAS.Home)
	puppy.position = WalkArea.SPAWNS.get(location, WalkArea.SPAWNS.Home)
	puppy.target = puppy.position
	puppy.bounds = Rect2(puppy.walk_area[0], Vector2.ZERO)
	for point in puppy.walk_area:
		puppy.bounds = puppy.bounds.expand(point)
	ball = Polygon2D.new()
	var shape = PackedVector2Array()
	for i in 24:
		shape.append(Vector2.from_angle(TAU * i / 24.0) * 16)
	ball.polygon = shape
	ball.color = Color("4cace4")
	ball.visible = false
	world.add_child(ball)
	discovery = Sprite2D.new()
	discovery.visible = false
	world.add_child(discovery)
	resized.connect(_resize_world)
	_resize_world()

func _resize_world() -> void:
	if world:
		var factor = maxf(size.x / 1280.0, size.y / 720.0)
		world.scale = Vector2.ONE * factor
		world.position = (size - Vector2(1280, 720) * factor) * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not puppy.controlled and not Game.resting:
		var point = (event.position - world.position) / world.scale
		# Ignore taps on furniture, railings, water and other non-walkable scenery.
		if WalkArea.contains(puppy.walk_area, point):
			puppy.request_move(point)

func set_walk_stop(index: int) -> void:
	background.modulate = [Color.WHITE, Color("edfaff"), Color("ffe4ce")][index]
	discovery.texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][index] + ".svg")
	discovery.position = WalkArea.WALK_STOPS[index] + Vector2(0, -8)
	discovery.scale = Vector2.ONE * 0.7
	discovery.visible = true
