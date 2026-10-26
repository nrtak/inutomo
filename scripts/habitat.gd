class_name Habitat
extends Control

var location = "Home"
var puppy: PuppyActor
var world: Node2D
var ball: Polygon2D

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background = TextureRect.new()
	background.texture = {"Home": Art.HOME, "Park": Art.PARK, "Beach": Art.BEACH}.get(location, Art.HOME)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	world = Node2D.new()
	add_child(world)
	puppy = PuppyActor.new()
	world.add_child(puppy)
	ball = Polygon2D.new()
	var shape = PackedVector2Array()
	for i in 24:
		shape.append(Vector2.from_angle(TAU * i / 24.0) * 16)
	ball.polygon = shape
	ball.color = Color("4cace4")
	ball.visible = false
	world.add_child(ball)
	resized.connect(_resize_world)
	_resize_world()

func _resize_world() -> void:
	if world:
		var factor = minf(size.x / 1280.0, size.y / 720.0)
		world.scale = Vector2.ONE * factor
		world.position = (size - Vector2(1280, 720) * factor) * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not puppy.controlled and not Game.resting:
		var point = (event.position - world.position) / world.scale
		puppy.target = Vector2(clampf(point.x, 350, 900), clampf(point.y, 510, 550))
		puppy.decision = 3
