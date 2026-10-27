extends SceneTree
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func run() -> void:
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://expansion_test.json"
	game.life = IslandLife.fresh()
	game.items = {}
	for kind in Goods.ITEMS:
		game.items[kind] = 0
	game.coins = 1000
	game.cooldowns = {}
	game.resting = false
	game.needs = {"Hunger": 40.0, "Happiness": 40.0, "Energy": 80.0, "Cleanliness": 80.0}
	game.intro_seen = true
	game.pending_stage = ""
	var practice_points = game.points
	game.needs.Happiness = 100
	game.needs.Cleanliness = 100
	game.items.Treat = 2
	game.action("Play")
	game.action("Care")
	check(game.points == practice_points and game.needs.Happiness == 100 and game.needs.Cleanliness == 100 and game.items.Treat == 2, "Full-need bonding does not grant growth or consume supplies")
	check(game.cooldowns.Play == 6 and game.cooldowns.Care == 6, "Practice still respects action cooldowns")
	game.cooldowns = {}
	game.needs.Happiness = 40
	game.needs.Cleanliness = 80
	game.buy_item("PuppyMeal")
	game.use_item("PuppyMeal")
	check(game.needs.Hunger == 64 and game.items.PuppyMeal == 0, "Purchased meals restore Hunger and are consumed")
	var points = game.points
	var favorite = IslandLife.favorite(game, "Food")
	check(favorite == IslandLife.favorite(game, "Food"), "Favorites stay consistent")
	game.buy_item("CoralBandana")
	game.life.accessory = "CoralBandana"
	game.buy_item("CloudBed")
	game.life.bed = "CloudBed"
	game.life.spot = 2
	var coins = game.coins
	IslandLife.talk(game, "Nora")
	IslandLife.talk(game, "Nora")
	check(game.life.friends.Nora.hearts == 1, "Friendship from chatting is awarded once per day")
	IslandLife.favor(game, "Nora")
	check(IslandLife.favor_status(game, "Nora").state == "active", "Accepted favors display incomplete progress")
	IslandLife.record(game, "Care")
	check(IslandLife.favor_status(game, "Nora").state == "ready", "Completed favors display a ready reward")
	IslandLife.favor(game, "Nora")
	IslandLife.favor(game, "Nora")
	check(game.coins == coins + 8 and game.life.friends.Nora.hearts == 3, "Favors reward once and grow friendship")
	check(IslandLife.favor_status(game, "Nora").state == "claimed", "Collected favors display done today")
	IslandLife.train(game, "Sit")
	IslandLife.train(game, "Sit")
	check(game.life.training.Sit == 1 and game.points == points, "Training has a cooldown and does not rush growth")
	for index in 3:
		IslandLife.discover(game, index)
		IslandLife.discover(game, index)
	check(game.life.keepsakes.size() == 3, "Keepsakes are collected once")
	for action in IslandLife.event_info().tasks:
		IslandLife.record(game, action)
	coins = game.coins
	IslandLife.claim_event(game)
	IslandLife.claim_event(game)
	check(game.coins == coins + 15, "Daily events award coins only once")
	game.save_game()
	var data = game.read_data(game.storage_path)
	check(game.valid_save(data), "The expanded state survives JSON number conversion")
	game.life = IslandLife.fresh()
	game.load_game()
	check(game.life.training.Sit == 1 and game.life.accessory == "CoralBandana" and game.life.spot == 2, "Training, accessories and decorating survive reload")
	check(game.life.keepsakes.size() == 3 and game.life.friends.Nora.hearts == 3, "Keepsakes and friendships survive reload")
	check(game.life.friends.Nora.hearts is int and game.life.spot is int, "Reloaded counts and positions use whole numbers")
	var legacy = data.duplicate(true)
	legacy.erase("life")
	check(game.valid_save(legacy), "Pre-expansion saves still load")
	var broken = data.duplicate(true)
	broken.life.photos = ["../private.png"]
	check(not game.valid_save(broken), "Album filenames cannot escape app storage")
	broken = data.duplicate(true)
	broken.life.keepsakes = ["Heart leaf", "Heart leaf"]
	check(not game.valid_save(broken), "Duplicate keepsakes cannot fill the collection with repeated entries")
	broken = data.duplicate(true)
	broken.life.photos = ["puppy_photo_1.png", "puppy_photo_1.png"]
	check(not game.valid_save(broken), "Duplicate photo references cannot fill the album")
	broken = data.duplicate(true)
	broken.life.accessory = "LavenderBandana"
	broken.items.LavenderBandana = 0
	var fixture = FileAccess.open(game.storage_path, FileAccess.WRITE)
	fixture.store_string(JSON.stringify(broken))
	fixture.close()
	game.load_game()
	check(game.life.accessory.is_empty(), "Unowned accessory selections are cleared while preserving the rest of the save")
	game.life.accessory = "CoralBandana"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://photos"))
	var photo_name = "puppy_photo_delete_test.png"
	var photo_file = FileAccess.open("user://photos/" + photo_name, FileAccess.WRITE)
	photo_file.store_string("disposable test fixture")
	photo_file.close()
	game.life.photos = [photo_name]
	IslandLife.delete_photo(game, "puppy_photo_not_in_album.png")
	check(game.life.photos.size() == 1 and FileAccess.file_exists("user://photos/" + photo_name), "Deletion refuses photos outside the album")
	IslandLife.delete_photo(game, photo_name)
	check(game.life.photos.is_empty() and not FileAccess.file_exists("user://photos/" + photo_name), "Deleting a photo removes its file and frees an album slot")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for section in ["Dog", "Wardrobe", "Training", "Friends", "Finds", "Home", "Events", "Photos"]:
		main.show_page("Life:" + section)
		await process_frame
		check(main.body.get_child(0).mode == section, "Island life opens " + section)
	main.show_page("Life:Friends")
	var friend_browser = main.body.get_child(0)
	for person in IslandLife.PEOPLE:
		var portrait = {"Nora": Art.NORA, "Ben": Art.BEN, "June": Art.JUNE, "Leah": Art.LEAH, "Owen": Art.OWEN}[person]
		for asking in [false, true]:
			friend_browser.friend_conversation(person, portrait, asking)
			check(is_instance_valid(main.resident_overlay) and not main.hud.visible, "Friend greetings and favors use the large portrait for " + person)
			for button in main.resident_overlay.find_children("*", "Button", true, false):
				if button.text == "Close":
					button.pressed.emit()
					break
			await process_frame
	main.show_page("Home")
	main.open_photo_mode()
	check(not main.hud.visible and is_instance_valid(main.photo_overlay), "Photo mode hides the HUD")
	main.close_photo_mode()
	check(main.hud.visible and not is_instance_valid(main.photo_overlay), "Closing photo mode restores controls")
	main.show_page("Life:Wardrobe")
	var browser = main.body.get_child(0)
	browser.choose("Dog")
	check(is_zero_approx(main.habitat.view_offset.x), "Full-width Island Life screens reset the preview camera")
	browser.choose("Wardrobe")
	check(main.habitat.view_offset.x < 0, "Switching to Wardrobe reframes the puppy beside the panel")
	browser.preview("SunshineBandana")
	check(game.life.accessory == "CoralBandana" and main.habitat.puppy.preview_accessory == "SunshineBandana", "Previewing an unowned accessory does not equip or buy it")
	main.show_page("Home")
	game.resting = true
	main.habitat.puppy.react_to_care("Rest")
	for step in 360:
		main.habitat.puppy._process(1.0 / 60)
	check(main.habitat.puppy.position.distance_to(Vector2(760, 505)) < 1, "Rest walks the puppy to the chosen bed spot")
	check(not main.habitat.puppy.settling_for_rest, "Arriving at the bed finishes settling and allows sleep")
	main.queue_free()
	await process_frame
	UI.safe_override = {"left": 105, "right": 105, "top": 20, "bottom": 25}
	for width in [1280, 1558]:
		var phone = SubViewport.new()
		phone.size = Vector2i(width, 720)
		root.add_child(phone)
		main = load("res://scenes/main.tscn").instantiate()
		phone.add_child(main)
		for section in ["Dog", "Wardrobe", "Training", "Friends", "Finds", "Home", "Events", "Photos"]:
			main.show_page("Life:" + section)
			await process_frame
			await process_frame
			var view = main.body.get_child(0)
			var compact = section in ["Wardrobe", "Home", "Training"]
			var panel: Control = view.get_child(1 if compact else 0)
			var bounds = panel.get_global_rect()
			check(bounds.position.x >= 105 and bounds.end.x <= width - 105, "Island life clears phone cutouts: " + section)
			check(bounds.end.y <= 695, "Island life stays above the phone bottom edge: " + section)
		main.queue_free()
		phone.queue_free()
		await process_frame
	UI.safe_override = {}
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Expansion checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
