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
	game.points = 0
	game.active_seconds = 0
	for breed in ["Puppy", "Shiba Inu", "Golden Retriever"]:
		game.breed = breed
		var puppy = load("res://scripts/puppy.gd").new()
		root.add_child(puppy)
		puppy.set_process(false)
		puppy.controlled = true
		check(puppy.walk_frames.size() == 8, breed + " has eight walk phases")
		var phase_regions = []
		for frame in 8:
			puppy.stride_distance = (float(frame) / 8 + 0.01) * puppy.stride_length()
			puppy.set_walk_pose()
			phase_regions.append(puppy.sprite.region_rect)
			check(is_zero_approx(puppy.sprite.offset.y + puppy.sprite.region_rect.size.y * 0.5), "Paws align with the ground")
		check(phase_regions[0] != phase_regions[1] and phase_regions[1] != phase_regions[2], "Travel advances paw poses")
		for fps in [30, 60, 120]:
			puppy.position = Vector2(500, 550)
			puppy.target = Vector2(620, 550)
			puppy.move_speed = 0
			puppy.stride_distance = 0
			for frame in fps * 3:
				puppy._process(1.0 / fps)
			check(puppy.position.distance_to(puppy.target) <= 1, "Dog stops at its destination at %d FPS" % fps)
			check(puppy.move_speed == 0 and puppy.sprite.texture == Art.WALKS[breed], "Paw animation stops when travel stops")
		puppy.target = puppy.position - Vector2(100, 0)
		puppy._process(0.1)
		check(puppy.sprite.flip_h, "Dog faces its direction of travel")
		puppy.queue_free()
	await process_frame
	print("Gait checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
