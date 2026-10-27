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
	game.storage_path = "user://start_menu_test.json"
	game.intro_seen = false
	game.name_chosen = false
	game.pending_stage = ""
	game.points = 0
	game.active_seconds = 0
	game.breed = "Puppy"
	game.resting = false
	var menu = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	check(menu.start_button.text == "Start Adventure", "First visit offers Start Adventure")
	var energy: float = game.needs.Energy
	await create_timer(0.2).timeout
	check(game.needs.Energy == energy, "Needs pause while viewing the menu")
	menu.show_guide()
	check(is_instance_valid(menu.guide_overlay), "How to Play opens")
	menu.close_guide()
	menu.enter_game()
	check(is_instance_valid(menu.name_overlay), "First adventure asks for a puppy name")
	menu.name_input.text = "Sora"
	menu.confirm_name()
	check(game.puppy_name == "Sora" and game.name_chosen, "Chosen name is applied before Nora welcomes the player")
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Start opens Home")
	check(is_instance_valid(current_scene.intro_overlay), "First visit opens Nora's welcome")
	energy = game.needs.Energy
	await create_timer(0.2).timeout
	check(game.needs.Energy == energy, "Needs pause during Nora's welcome")
	for step in 4:
		check(current_scene.intro_step == step, "Welcome pages advance in order")
		current_scene.advance_intro()
	check(game.intro_seen, "Welcome completes only after the last page")
	check(not is_instance_valid(current_scene.intro_overlay), "Welcome closes")
	check(game.is_processing(), "Needs resume after welcome")
	var puppy = current_scene.habitat.puppy
	game.breed = "Puppy"
	game.resting = false
	puppy._process(0)
	check(puppy.napping and puppy.sprite.texture == Art.PUPPY_SLEEP, "Starting puppy begins asleep")
	var nap_position: Vector2 = puppy.position
	var sleeping_frames = 0
	for tick in 1200:
		puppy._process(0.1)
		if puppy.napping:
			sleeping_frames += 1
	check(sleeping_frames > 900, "Baby puppy sleeps most of the time")
	check(puppy.position.distance_to(nap_position) < 100, "Baby puppy stays near its nap spot")
	puppy.react_to_care("Feed")
	puppy._process(0.1)
	check(not puppy.napping and puppy.sprite.texture == Art.PUPPIES.Puppy, "Care briefly wakes the puppy")
	check(is_equal_approx(puppy.sprite.region_rect.size.y * puppy.base_scale, lerpf(180, 280, game.growth_fraction())), "Baby puppy is much smaller than an adult")
	puppy.controlled = true
	puppy.nap_remaining = 60
	puppy.reaction_time = 0
	puppy.target = puppy.position + Vector2(100, 0)
	var outing_position: Vector2 = puppy.position
	puppy._process(0.5)
	check(not puppy.napping and puppy.position.x > outing_position.x, "Selected outings keep the puppy awake and mobile")
	puppy.controlled = false
	puppy.target = puppy.position
	puppy.settle_time = 0
	game.breed = "Shiba Inu"
	puppy._process(0.1)
	check(is_equal_approx(puppy.sprite.region_rect.size.y * puppy.base_scale, 320), "Adult size stays unchanged")
	current_scene.show_intro()
	check(current_scene.intro_step == 0, "Nora's reminder restarts at the beginning")
	for step in 4:
		current_scene.advance_intro()
	current_scene.show_page("Menu")
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/start_menu.tscn", "Menu button returns to title")
	check(current_scene.start_button.text == "Continue", "Returning players see Continue")
	current_scene.enter_game()
	await process_frame
	await process_frame
	check(not is_instance_valid(current_scene.intro_overlay), "Returning players skip the welcome")
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Start menu checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
