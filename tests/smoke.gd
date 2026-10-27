extends SceneTree

var failures = 0
var game: Node

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://test_puppy_island.json"
	game.puppy_name = "Mochi"
	game.items = {"Treat": 0, "Toy": 0, "Brush": 0}
	game.coins = 50
	game.needs = {"Hunger": 40.0, "Happiness": 40.0, "Energy": 70.0, "Cleanliness": 40.0}
	game.points = 0
	game.active_seconds = 0
	game.breed = "Puppy"
	game.walks = 0
	game.fetches = 0
	game.collection = []
	game.journal = []
	game.cooldowns = {}
	game.action("Feed")
	check(game.needs.Hunger == 62.0, "Feed restores hunger")
	game.action("Feed")
	check(game.points == 1, "Cooldown prevents duplicate growth")
	game.action("Care")
	check(game.needs.Cleanliness == 62.0, "Care restores cleanliness")
	game.action("Rest")
	game.advance(10)
	check(game.needs.Energy > 75, "Rest restores energy over time")
	game.action("Rest")
	game.finish_activity("Walk")
	check(game.prediction() == "Shiba Inu", "Walks favor Shiba")
	game.finish_activity("Fetch", 3)
	check(game.prediction() == "Golden Retriever", "Fetch and tie favor Golden")
	game.walks = 10
	game.points = game.EVOLUTION_POINTS - 1
	game.active_seconds = game.EVOLUTION_SECONDS
	game.finish_activity("Walk")
	check(game.breed == "Shiba Inu" and game.collection.size() == 1, "Evolution enters collection once")
	game.finish_activity("Walk")
	check(game.collection.size() == 1, "No duplicate evolution")
	check(game.save_game(), "Save succeeds")
	var saved_points: int = game.points
	game.points = 0
	game.load_game()
	check(game.points == saved_points and game.breed == "Shiba Inu", "Save round-trip")
	check(not game.valid_save({"version": 1, "needs": []}), "Reject malformed saves")
	var f = FileAccess.open(game.storage_path, FileAccess.WRITE)
	f.store_string("broken")
	f.close()
	game.points = 0
	game.load_game()
	check(game.points == saved_points, "Corrupt save recovers from backup")
	game.breed = "Puppy"
	game.points = game.EVOLUTION_POINTS - 1
	game.active_seconds = game.EVOLUTION_SECONDS
	game.walks = 0
	game.fetches = 3
	game.finish_activity("Fetch", 1)
	check(game.breed == "Golden Retriever", "Golden evolution")
	game.advance(100000)
	for value in game.needs.values():
		check(value >= 0 and value <= 100, "Needs stay within bounds")
	game.needs.Energy = 5
	check(not game.can_explore(), "Low energy blocks outings")
	game.needs.Energy = 90
	game.resting = false
	game.pending_stage = ""
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if is_instance_valid(main.intro_overlay):
		main.intro_overlay.queue_free()
		main.intro_overlay = null
	for page in ["Island", "Journal", "My Dogs", "Home"]:
		main.show_page(page)
		await process_frame
		check(main.body.get_child_count() > 0, page + " scene renders")
	game.needs.Hunger = 40.0
	game.cooldowns.clear()
	game.action("Feed")
	await process_frame
	check(main.habitat.puppy.reaction_kind == "Feed" and main.habitat.puppy.reaction_time > 0, "Successful care triggers puppy reaction")
	check(main.action_buttons.Feed.disabled, "Care cooldown is visible on the button")
	var care_points: int = game.points
	game.action("Feed")
	check(game.points == care_points, "Repeated care during cooldown awards no growth")
	game.advance(7)
	await process_frame
	check(not main.action_buttons.Feed.disabled, "Care button becomes available after cooldown")
	main.start_activity("Fetch")
	await process_frame
	var fetch = main.body.get_child(0)
	for i in 3:
		fetch._throw()
		await create_timer(5.7).timeout
	check(fetch.complete and fetch.rounds == 3, "Fetch completes three rounds")
	main.start_activity("Walk")
	await process_frame
	var walk = main.body.get_child(0)
	for i in 3:
		walk._next()
		await create_timer(2.7).timeout
	check(not walk.complete, "Walk waits for the return trip before awarding completion")
	var before_return: Vector2 = main.habitat.puppy.position
	walk._next()
	await create_timer(2.7).timeout
	check(walk.complete, "Walk completes all stops and the return trip")
	check(main.habitat.puppy.position.y < before_return.y, "Dog walks back up the coastal path")
	var discoveries = 0
	for memory in game.journal:
		for moment in walk.MOMENTS:
			if moment in memory:
				discoveries += 1
	check(discoveries == 3, "All three Walk discoveries enter the Journal")
	# Leaving an outing during an await must not access freed UI or award growth.
	main.start_activity("Fetch")
	await process_frame
	main.body.get_child(0)._throw()
	main.show_page("Home")
	await create_timer(3.2).timeout
	main.queue_free()
	await process_frame
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Puppy Island checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
