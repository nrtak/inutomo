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
	game.storage_path = "user://locations_test.json"
	game.intro_seen = true
	game.pending_stage = ""
	game.coins = 100
	game.items = {"Treat": 0, "Toy": 0, "Brush": 0}
	game.needs = {"Hunger": 40.0, "Happiness": 40.0, "Energy": 90.0, "Cleanliness": 40.0}
	game.cooldowns = {}
	game.buy_item("Treat")
	check(game.coins == 90 and game.items.Treat == 1, "Shop charges coins and adds the treat")
	game.action("Feed")
	check(game.needs.Hunger == 70 and game.items.Treat == 0, "Feed consumes one treat and gets its bonus")
	game.buy_item("Toy")
	var paid_coins: int = game.coins
	game.buy_item("Toy")
	check(game.coins == paid_coins and game.items.Toy == 1, "Durable items cannot be purchased twice")
	game.action("Play")
	check(game.needs.Happiness == 66, "Owned toy improves Play")
	game.buy_item("Brush")
	game.action("Care")
	check(game.needs.Cleanliness == 66, "Owned brush improves Care")
	game.coins = 0
	game.buy_item("Treat")
	check(game.coins == 0 and game.items.Treat == 0, "Insufficient coins cannot buy an item")
	game.coins = 50
	game.clinic_groom()
	check(game.coins == 38 and game.needs.Cleanliness == 91, "Clinic grooming charges once and restores cleanliness")
	game.needs.Cleanliness = 100
	game.clinic_groom()
	check(game.coins == 38, "Already clean puppies are not charged")
	game.needs.Energy = 10
	check("Rest" in game.clinic_checkup(), "Leah's advice responds to the lowest need")
	game.needs.Energy = 90
	game.resting = false
	game.save_game()
	game.coins = 0
	game.items.Toy = 0
	game.load_game()
	check(game.coins == 38 and game.items.Toy == 1, "Coins and purchases survive save and load")
	var before_outing: int = game.coins
	game.finish_activity("Walk")
	check(game.coins == before_outing + 10, "Completed outings award island coins")
	game.pending_stage = ""
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for place in ["Puppy Club", "Shop", "Vet Clinic", "Lighthouse"]:
		main.show_page(place)
		await process_frame
		check(main.habitat.location == place, place + " has its own scene")
		check(main.habitat.background.texture == Art.BACKGROUNDS[place], place + " uses its own art")
		var hub = main.body.get_child(0)
		check(hub.location == place, "Location actions match the scene")
	for resident in ["Nora", "Ben", "June", "Leah", "Owen"]:
		main.show_page({"Nora": "Puppy Club", "Ben": "Park", "June": "Shop", "Leah": "Vet Clinic", "Owen": "Beach"}[resident])
		var hub = main.body.get_child(0)
		hub.call({"Nora": "talk_to_nora", "Ben": "talk_to_ben", "June": "talk_to_june", "Leah": "checkup", "Owen": "talk_to_owen"}[resident])
		check(is_instance_valid(main.resident_overlay), resident + " opens a resident dialogue")
		check(main.resident_overlay.find_children("ConversationCharacter", "Control", true, false).size() == 1, "Residents use a large borderless portrait stage")
		check(main.resident_overlay.find_children("ConversationText", "PanelContainer", true, false).size() == 1 and not main.hud.visible, "Each conversation has one text panel and hides the HUD")
		await process_frame
		await process_frame
		var portrait_stage = main.resident_overlay.find_children("ConversationCharacter", "Control", true, false)[0]
		var portrait = portrait_stage.get_child(0)
		check(portrait.get_global_rect().end.y >= main.get_viewport_rect().size.y, resident + " portrait continues beyond the screen edge")
		check(portrait.position.y >= -1 and portrait.position.x >= -1, resident + " artwork fits inside its stage")
		check(main.resident_overlay.find_children("SpeechTail", "Polygon2D", true, false).size() == 1, resident + " has a manga speech-bubble tail")
		var speech_panel = main.resident_overlay.find_children("ConversationText", "PanelContainer", true, false)[0]
		check(speech_panel.get_global_rect().position.y < main.get_viewport_rect().size.y * 0.25, resident + " speech bubble sits near the top")
		for button in main.resident_overlay.find_children("*", "Button", true, false):
			if button.text == "Close":
				button.pressed.emit()
				break
		await process_frame
	main.show_page("Vet Clinic")
	main.body.get_child(0).checkup()
	check(is_instance_valid(main.resident_overlay), "Leah opens in a framed dialogue")
	main.queue_free()
	await process_frame
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Location checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
