extends SceneTree
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1
func run() -> void:
	var game = root.get_node("Game")
	game.set_process(false)
	game.resting = false
	game.breed = "Golden Retriever"
	seed(12)
	for location in ["Home", "Park", "Beach", "Puppy Club", "Shop", "Vet Clinic", "Lighthouse"]:
		var habitat = load("res://scenes/home.tscn").instantiate()
		habitat.location = location
		habitat.size = Vector2(1280, 720)
		root.add_child(habitat)
		habitat.puppy.set_process(false)
		var polygon: PackedVector2Array = WalkArea.AREAS[location]
		var puppy = habitat.puppy
		check(WalkArea.contains(polygon, puppy.position), location + " spawn is on clear ground")
		for destination in [Vector2(-500, -500), Vector2(1300, 0), Vector2(1700, 1000), Vector2(640, 360)]:
			puppy.controlled = true
			puppy.target = destination
			check(WalkArea.contains(polygon, puppy.target), location + " scripted destinations stay on the path")
			for frame in 180:
				puppy._process(1.0 / 60)
				check(WalkArea.contains(polygon, puppy.position), location + " route never crosses scenery")
		if location == "Beach":
			puppy.position = WalkArea.WALK_STOPS[0]
			puppy.target = WalkArea.WALK_STOPS[1]
			for frame in 180:
				puppy._process(1.0 / 60)
			check(puppy.position.distance_to(WalkArea.WALK_STOPS[1]) <= 1, "Dog can walk down the diagonal")
			puppy.target = WalkArea.WALK_STOPS[0]
			for frame in 180:
				puppy._process(1.0 / 60)
			check(puppy.position.distance_to(WalkArea.WALK_STOPS[0]) <= 1, "The same diagonal remains walkable uphill")
		puppy.controlled = false
		for frame in 1800:
			puppy._process(1.0 / 30)
			check(WalkArea.contains(polygon, puppy.position), location + " wandering stays on clear ground")
		var old_target: Vector2 = puppy.target
		var click = InputEventMouseButton.new()
		click.pressed = true
		click.position = habitat.world.position + Vector2(640, 200) * habitat.world.scale
		habitat._gui_input(click)
		check(puppy.target == old_target, "Tapping scenery does not send the dog toward it")
		for screen_size in [Vector2(1280, 720), Vector2(1560, 720), Vector2(1920, 1080)]:
			habitat.size = screen_size
			habitat._resize_world()
			var ground: Vector2 = WalkArea.SPAWNS[location]
			var screen_point: Vector2 = habitat.world.position + ground * habitat.world.scale
			var restored: Vector2 = (screen_point - habitat.world.position) / habitat.world.scale
			check(restored.distance_to(ground) < 0.01, "Ground and artwork stay aligned after resizing")
		habitat.queue_free()
	for stop in WalkArea.WALK_STOPS:
		check(WalkArea.contains(WalkArea.AREAS.Beach, stop), "All Walk discoveries are reachable from the path")
	check(WalkArea.WALK_STOPS[1].y > WalkArea.WALK_STOPS[0].y, "Upper beach route follows the diagonal")
	check(WalkArea.WALK_STOPS[1].y == WalkArea.WALK_STOPS[2].y, "Foreground beach route runs horizontally")
	await process_frame
	print("Walk area checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
