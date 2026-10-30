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
	for portrait in [Art.NORA, Art.JUNE, Art.BEN, Art.LEAH, Art.OWEN, Art.REN]:
		var today_portrait = Art.daily_portrait(portrait, "2026-10-28")
		check(today_portrait == Art.daily_portrait(portrait, "2026-10-28"), "Character clothing stays consistent during one day")
		check(today_portrait != Art.daily_portrait(portrait, "2026-10-29"), "Character outfits rotate on consecutive local dates")
		check(today_portrait == Art.daily_portrait(today_portrait, "2026-10-28"), "Portrait resolution remains consistent between icons and dialogue")
	check(Art.daily_portrait(Art.HOME, "2026-10-28") == Art.HOME, "Non-character artwork stays unchanged")
	for portrait in [Art.NORA_CORAL, Art.JUNE_MINT, Art.BEN_TRAINING, Art.LEAH_TUNIC, Art.OWEN_PARCEL, Art.REN_SWEATER]:
		check(portrait.get_image().get_pixel(0,0).a == 0, "Alternate portraits preserve transparent backgrounds")
	IslandLife.talk(game,"Kai")
	check(game.life.friends.has("Kai") and IslandLife.valid(game.life), "Kai joins saved friendships")
	check(Art.daily_portrait(Art.KAI) == Art.KAI, "Kai keeps his approved look until alternate outfits are added")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for section in ["Dog", "Wardrobe", "Training", "Friends", "Finds", "Home", "Events", "Photos", "Playdate", "Health Record", "Deliveries"]:
		main.show_page("Life:" + section)
		await process_frame
		check(main.body.get_child(0).mode == section, "Island life opens " + section)
	main.show_page("Life:Training")
	var lessons = main.body.get_child(0)
	lessons.select_lesson("Stay")
	await process_frame
	check(lessons.lesson_command == "Stay" and lessons.training_buttons.has("Stay"), "Selecting a lesson shows its focused practice screen")
	game.resting = false
	game.cooldowns.clear()
	game.needs.Energy = 90
	game.health = PuppyHealth.fresh()
	var before_lesson = int(game.life.training.Stay)
	lessons.practice_lesson()
	check(game.life.training.Stay == before_lesson + 1, "Guided practice advances the selected command once")
	lessons.practice_lesson()
	check(game.life.training.Stay == before_lesson + 1, "Guided practice respects the breather")
	lessons.select_lesson("")
	check(lessons.lesson_command == "" and lessons.training_buttons.is_empty(), "Players can return to the lesson picker")
	game.life.playdate = {"day":"", "step":0, "claimed":"", "visits":0}
	game.cooldowns.clear()
	var playdate_coins = game.coins
	IslandLife.playdate_step(game)
	IslandLife.playdate_step(game)
	check(game.life.playdate.step == 1, "Playdate steps cannot be rushed")
	game.save_game()
	game.life.playdate = {}
	game.load_game()
	check(game.life.playdate.step == 1, "An unfinished playdate survives reload")
	for turn in 2:
		game.cooldowns.clear()
		IslandLife.playdate_step(game)
	check(game.life.playdate.visits == 1 and game.coins == playdate_coins + 5, "Completing three playdate steps rewards once")
	game.cooldowns.clear()
	IslandLife.playdate_step(game)
	check(game.life.playdate.visits == 1 and game.coins == playdate_coins + 5, "Daily playdate rewards cannot be collected twice")
	game.life.playdate = {"day":"", "step":0, "claimed":"", "visits":0}
	PuppyHealth.start(game, "Sore paw")
	IslandLife.playdate_step(game)
	check(game.life.playdate.step == 0, "Injured puppies recover before playdates")
	game.health = PuppyHealth.fresh()
	main.show_page("Life:Playdate")
	await process_frame
	check(main.body.get_child(0).mode == "Playdate", "Puppy Club playdate screen opens")
	check(is_instance_valid(main.habitat.playmate), "Playdates show a second puppy in the world")
	main.habitat.ball.rotation = TAU
	main.habitat.animate_playdate(2)
	check(is_zero_approx(main.habitat.ball.rotation), "Repeated playdate ball animations start with a fresh roll")
	check(main.habitat.ball.visible, "Shared play animates a visible ball")
	main.habitat.animate_playdate(3)
	check(main.habitat.playmate.texture == Art.PUPPY_SLEEP and not main.habitat.ball.visible, "Resting playmates settle down and put the ball away")
	var playdate_view = main.body.get_child(0)
	playdate_view.shown_day = "2000-01-01"
	playdate_view._process(0)
	check(playdate_view.shown_day == IslandLife.today(), "Open daily activities refresh after the local date changes")
	check(not IslandLife.valid({"playdate":{"day":"2026-10-28", "step":3}}), "A finished playdate without its claimed date cannot load")

	check(Goods.featured("2026-10-28") == Goods.featured("2026-10-28"), "Daily picks stay consistent throughout a day")
	check(Goods.featured("2026-10-28") != Goods.featured("2026-10-29"), "Daily picks rotate on a new local date")
	main.browse_shop()
	var shop_preview = main.body.get_child(0)
	shop_preview.select_category("Featured")
	check(shop_preview.rows.size() == 3, "June offers three featured goods")
	var original_accessory = game.life.accessory
	game.items.SunshineBandana = 0
	var preview_coins = game.coins
	shop_preview.show_details("SunshineBandana")
	shop_preview.wear_preview("SunshineBandana")
	check(game.coins == preview_coins and game.life.accessory == original_accessory and game.items.SunshineBandana == 0, "Unowned accessory previews do not buy or equip")
	game.coins = 100
	shop_preview.select_category("Accessories")
	shop_preview.perform("SunshineBandana")
	check(game.items.SunshineBandana == 1 and game.life.accessory == original_accessory, "Buying an accessory leaves the current outfit unchanged")
	shop_preview.wear_preview("SunshineBandana")
	check(game.life.accessory == "SunshineBandana", "Wear equips the purchased preview")
	shop_preview.close_details()
	game.life.accessory = original_accessory
	game.items.SunshineBandana = 0
	game.life.delivery = {"recipient":"", "claimed":"", "completed":0}
	var welcome_before = game.life.story.get("welcome", false)
	game.life.story.welcome = false
	IslandLife.collect_delivery(game)
	check(game.life.delivery.recipient == "", "Parcels require meeting Owen first")
	game.life.story.welcome = true
	IslandLife.collect_delivery(game)
	var recipient = game.life.delivery.recipient
	var destination = IslandLife.delivery_info(game).place
	IslandLife.collect_delivery(game)
	check(game.life.delivery.recipient == recipient, "Collecting again preserves the pending parcel")
	var delivery_coins = game.coins
	IslandLife.deliver_parcel(game, "Harbor")
	check(game.coins == delivery_coins and game.life.delivery.recipient == recipient, "A wrong destination cannot claim delivery rewards")
	game.save_game()
	game.life.delivery = {}
	game.load_game()
	check(game.life.delivery.recipient == recipient, "Pending parcels survive reload")
	main.show_page(destination)
	await process_frame
	var parcel_hub = main.body.get_child(0)
	check(parcel_hub.choices.get_child_count() > 0, "Recipient building opens with parcel actions")
	game.items.Treat = Goods.ITEMS.Treat.limit
	IslandLife.deliver_parcel(game, destination)
	check(game.coins == delivery_coins + 6 and game.life.delivery.completed == 1 and game.items.Treat == Goods.ITEMS.Treat.limit, "Delivery pays once without overflowing a full Bag")
	IslandLife.deliver_parcel(game, destination)
	IslandLife.collect_delivery(game)
	check(game.coins == delivery_coins + 6 and game.life.delivery.recipient == "", "Daily delivery rewards cannot repeat")
	game.life.story.welcome = welcome_before
	main.show_page("Life:Deliveries")
	await process_frame
	check(main.body.get_child(0).mode == "Deliveries", "Harbor parcel board opens")
	check(not IslandLife.valid({"delivery":{"recipient":"Unknown"}}), "Unknown delivery recipients are rejected")
	main.show_page("Life:Friends")
	var friend_browser = main.body.get_child(0)
	for person in IslandLife.PEOPLE:
		var portrait = {"Kai": Art.KAI, "Nora": Art.NORA, "Ben": Art.BEN, "June": Art.JUNE, "Leah": Art.LEAH, "Owen": Art.OWEN, "Ren": Art.REN}[person]
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
	game.resting = false
	game.cooldowns.clear()
	game.needs.Hunger = 30
	game.life.bowl = true
	game.life.bowl_spot = 2
	game.life.toy_spot = 0
	game.life.toy = "Toy"
	game.items.Toy = 1
	game.save_game()
	game.load_game()
	check(game.life.bowl_spot == 2 and game.life.toy_spot == 0 and game.life.bowl, "Bowl and toy positions survive reload")
	main.show_page("Home")
	var room = main.habitat
	check(room.decor_targets.has("Feed") and room.decor_targets.has("Play"), "Placed bowl and toy have Home interactions")
	room.interact_decor("Feed")
	check(room.puppy.pending_decor_action == "Feed", "Feeding sends the puppy toward its bowl")
	for frame in 1500:
		room.puppy._process(1.0 / 60)
		if room.puppy.pending_decor_action == "":
			break
	check(room.puppy.pending_decor_action == "" and room.puppy.reaction_kind == "Feed", "Puppy reaches the bowl before its feeding reaction")
	check(WalkArea.contains(room.puppy.walk_area, room.puppy.position), "Bowl approach remains on safe ground")
	game.resting = true
	room.interact_decor("Rest")
	check(game.resting, "Tapping an occupied bed does not wake the puppy")
	check(not IslandLife.valid({"bowl_spot":4}), "Invalid decoration positions are rejected")
	main.queue_free()
	await process_frame
	UI.safe_override = {"left": 105, "right": 105, "top": 20, "bottom": 25}
	for width in [1280, 1558]:
		var phone = SubViewport.new()
		phone.size = Vector2i(width, 720)
		root.add_child(phone)
		main = load("res://scenes/main.tscn").instantiate()
		phone.add_child(main)
		for section in ["Dog", "Wardrobe", "Training", "Friends", "Finds", "Home", "Events", "Photos", "Playdate", "Health Record", "Deliveries"]:
			main.show_page("Life:" + section)
			await process_frame
			await process_frame
			var view = main.body.get_child(0)
			var compact = section in ["Wardrobe", "Home", "Training", "Playdate"]
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
