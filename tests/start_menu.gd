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
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn", "Start opens Home")
	if is_instance_valid(current_scene.intro_overlay):
		current_scene.intro_overlay.queue_free()
		current_scene.intro_overlay = null
	game.intro_seen = true
	current_scene.show_page("Menu")
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/start_menu.tscn", "Menu button returns to title")
	check(current_scene.start_button.text == "Continue", "Returning players see Continue")
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Start menu checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
