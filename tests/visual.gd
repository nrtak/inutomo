extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://visual_test.json"
	game.intro_seen = true
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for page in ["Home", "Island", "Journal", "My Dogs", "Fetch", "Walk", "Nora"]:
		if page in ["Fetch", "Walk"]:
			main.start_activity(page)
		elif page == "Nora":
			main.show_page("Home")
			main.show_intro()
		else:
			main.show_page(page)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var image = root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://build/screenshots")
		image.save_png("res://build/screenshots/" + page.replace(" ", "_") + ".png")
	quit()
