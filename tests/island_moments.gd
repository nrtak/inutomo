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
	game.storage_path = "user://island_moments_test.json"
	game.first_day = {"Care": false, "Nora": false, "Outing": false}
	game.cooldowns = {}
	game.points = 0
	game.walks = 0
	game.fetches = 0
	game.resting = false
	game.needs = {"Hunger": 80.0, "Happiness": 50.0, "Energy": 90.0, "Cleanliness": 85.0}
	game.action("Feed")
	check(game.first_day.Care, "Successful care completes the first goal")
	game.meet_nora()
	var memories = game.journal.size()
	game.meet_nora()
	check(game.first_day.Nora and game.journal.size() == memories, "Meeting Nora counts once")
	game.finish_activity("Walk")
	check(game.first_day.Outing, "A completed outing completes the third goal")
	var points = game.points
	var coins = game.coins
	var happiness = game.needs.Happiness
	game.island_moment("Park")
	check(game.needs.Happiness == happiness + 3 and game.cooldowns.IslandMoment == 30, "Sitting practice gives a small happiness boost")
	game.island_moment("Beach")
	check(game.needs.Happiness == happiness + 3 and game.points == points and game.coins == coins, "Repeat activities cannot farm growth or coins")
	game.save_game()
	game.first_day = {"Care": false, "Nora": false, "Outing": false}
	game.cooldowns = {}
	game.load_game()
	check(game.first_day.values().count(true) == 3 and game.cooldowns.IslandMoment > 0, "Goals and activity cooldown survive reload")
	var legacy = game.read_data(game.storage_path)
	legacy.erase("first_day")
	check(game.valid_save(legacy), "Older saves remain valid")
	legacy.first_day = {"Care": "yes"}
	check(not game.valid_save(legacy), "Malformed goal flags are rejected")
	var actor = load("res://scripts/puppy.gd").new()
	root.add_child(actor)
	game.nap_actor = weakref(actor)
	actor.napping = true
	game.set_process(true)
	check(game.pet_puppy() and actor.napping and actor.sleepy_reaction, "Petting gives a sleeping puppy a gentle reaction")
	actor._process(0.1)
	check(actor.reaction_icon.visible and actor.napping, "A sleeping puppy shows affection without leaving the nap")
	check(actor.sprite.region_rect == Rect2(Art.PUPPY_SLEEP_REGION), "Sleeping paws use the opaque artwork baseline instead of faint padding")
	game.resting = true
	game.items.Treat = 1
	game.cooldowns.erase("Goods")
	game.needs.Hunger = 50
	game.use_item("Treat")
	actor._process(0.1)
	check(game.resting and actor.sleepy_reaction and actor.reaction_kind == "Treat", "Treats react without cancelling Rest")
	game.cooldowns.erase("Pet")
	actor.napping = false
	game.resting = false
	check(game.pet_puppy() and actor.reaction_kind == "Pet", "An awake puppy responds to a gentle pat")
	check(not game.pet_puppy(), "Petting has a cooldown")
	game.set_process(false)
	for kind in ["Pet", "Treat", "Sniff", "Sit"]:
		actor.react_to_care(kind)
		check(actor.reaction_icon.texture != null, "Each new reaction has an icon")
	for breed in ["Shiba Inu", "Golden Retriever"]:
		game.breed = breed
		game.resting = true
		actor._process(0.1)
		check(actor.sprite.texture == Art.SLEEP_TEXTURES[breed], "Rest selects the matching adult sleeping artwork")
		check(is_equal_approx(actor.visible_size.x * actor.base_scale, 390), "Adult sleeping poses use a consistent visible size")
		actor.react_to_care("Pet")
		actor._process(0.1)
		check(actor.sleepy_reaction and actor.reaction_icon.visible and game.resting, "Adult dogs react to petting while resting")
		actor.react_to_care("Treat")
		actor._process(0.1)
		check(actor.sprite.texture == Art.SLEEP_TEXTURES[breed] and game.resting, "Adult treat reactions keep the sleeping pose")
		game.resting = false
		actor.react_to_care("Rest")
		actor._process(0.1)
		check(actor.sprite.texture == Art.PUPPIES[breed] and actor.sprite.material == null, "Wake restores the adult standing pose and normal material")
	actor.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Island moments checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
