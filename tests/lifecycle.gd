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
	game.storage_path = "user://lifecycle_test.json"
	game.paused_at = 0.0
	game.resting = false
	game.needs = {"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	game.save_game()
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved_departure = FileAccess.get_file_as_string(game.storage_path)
	var departure = Time.get_unix_time_from_system() - 120.0
	game.paused_at = departure
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.paused_at == departure, "Repeated pause events preserve the original departure time")
	check(FileAccess.get_file_as_string(game.storage_path) == saved_departure, "Repeated pause events cannot overwrite the last departure snapshot")
	var active_time: float = game.active_seconds
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(absf(game.needs.Hunger - (80.0 - 120.0 * game.DECAY[0] * game.OFFLINE_DECAY_FACTOR)) < 0.02, "Returning accounts for the whole absence exactly once")
	var resumed_needs: Dictionary = game.needs.duplicate()
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(game.needs == resumed_needs and game.active_seconds == active_time, "Duplicate resume events cannot apply decay or growth twice")
	check(game.save_game(), "Recovered progress can be saved")
	var valid_path: String = game.storage_path
	game.storage_path = "user://absent_lifecycle_folder/save.json"
	check(not game.save_game() and not game.save_error.is_empty(), "The save failure is visible")
	game.storage_path = valid_path
	game.load_game()
	check(game.save_error.is_empty(), "Loading healthy progress clears an obsolete save failure")
	# A backup recovery also clears the alert while keeping the recovered progress.
	game.save_game()
	var broken = FileAccess.open(game.storage_path, FileAccess.WRITE)
	broken.store_string("damaged primary save")
	broken.close()
	game.save_error = "An old write failed."
	game.load_game()
	check(game.save_error.is_empty() and game.needs.Hunger > 70, "Backup recovery clears obsolete errors and restores real progress")
	UI.safe_override = {"left":105,"right":85,"top":20,"bottom":30}
	for dimensions in [Vector2i(1152,648),Vector2i(960,540)]:
		var view = SubViewport.new()
		view.size = dimensions
		root.add_child(view)
		var menu = load("res://scenes/start_menu.tscn").instantiate()
		view.add_child(menu)
		menu.show_guide()
		await process_frame
		await process_frame
		var panel: PanelContainer = menu.guide_overlay.find_children("*", "PanelContainer", true, false)[0]
		check_guide_bounds(panel, dimensions)
		await check_guide_close(menu, panel)
		view.size = dimensions - Vector2i(40,30)
		await process_frame
		await process_frame
		check_guide_bounds(panel, view.size)
		await check_guide_close(menu, panel)
		menu.close_guide()
		view.queue_free()
		await process_frame
	UI.safe_override.clear()
	print("Lifecycle and guide checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func check_guide_bounds(panel: PanelContainer, dimensions: Vector2i) -> void:
	var bounds = panel.get_global_rect()
	check(bounds.position.x >= 104.5 and bounds.end.x <= dimensions.x - 84.5, "The guide stays between the phone's side safe areas")
	check(bounds.position.y >= 19.5 and bounds.end.y <= dimensions.y - 29.5, "The guide stays inside the safe screen height, including after a resize")

func check_guide_close(menu: Control, panel: PanelContainer) -> void:
	var scroll: ScrollContainer = menu.guide_overlay.find_children("*", "ScrollContainer", true, false)[0]
	for button in menu.guide_overlay.find_children("*", "Button", true, false):
		if button.text == "Got it!":
			scroll.ensure_control_visible(button)
			await process_frame
			var bounds = panel.get_global_rect()
			var close_bounds: Rect2 = button.get_global_rect()
			check(close_bounds.position.y >= bounds.position.y + 12 and close_bounds.end.y <= bounds.end.y - 12, "The guide's close button remains reachable by scrolling")
			check(close_bounds.position.x >= bounds.position.x and close_bounds.end.x <= bounds.end.x, "Guide controls do not overflow horizontally")
