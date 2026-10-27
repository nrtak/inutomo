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
	game.storage_path = "user://growth_test.json"
	game.breed = "Puppy"
	game.points = 40
	game.active_seconds = 0
	game.collection = []
	game.journal = []
	game.last_stage = "Tiny puppy"
	game.advance(7200, false)
	check(game.active_seconds == 0 and game.breed == "Puppy", "Offline time cannot rush growth")
	game.advance(599)
	check(game.stage_index() == 0, "Repeated care cannot skip the tiny stage")
	game.advance(1)
	check(game.stage_index() == 1, "Young stage requires ten active minutes")
	game.advance(1200)
	check(game.stage_index() == 2, "Growing stage requires thirty active minutes")
	game.points = 39
	game.advance(1800)
	check(game.breed == "Puppy", "Time alone does not replace care")
	game.grow("A little care.")
	check(game.breed == "Golden Retriever" and game.collection.size() == 1, "Both growth requirements unlock adulthood")
	game.advance(100)
	check(game.collection.size() == 1, "Adulthood is awarded only once")
	check(game.save_game(), "New growth progress saves")
	var stored_time: float = game.active_seconds
	game.active_seconds = 0
	game.load_game()
	check(game.active_seconds == stored_time, "Growth time survives save and load")
	var old_save = game.read_data(game.storage_path)
	old_save.erase("active_seconds")
	check(game.valid_save(old_save), "Older saves remain valid")
	old_save.active_seconds = -1
	check(not game.valid_save(old_save), "Malformed growth time is rejected")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Growth checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
