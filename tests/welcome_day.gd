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
	game.storage_path = "user://welcome_day_test.json"
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.resting = false
	game.paused_at = 0
	game.intro_seen = true
	game.name_chosen = true
	game.pending_stage = ""
	game.puppy_name = "Yuki"
	game.breed = "Puppy"
	game.needs = {"Hunger":70.0,"Happiness":60.0,"Energy":95.0,"Cleanliness":80.0}
	game.cooldowns.clear()
	game.items = {"Treat":0,"Toy":0,"Brush":0}
	game.active_outing = {}
	game.saved_outings = {}
	var legacy = IslandLife.fresh()
	legacy.erase("welcome_day")
	check(IslandLife.valid(legacy), "Existing saves remain valid before the invitation")
	check(IslandLife.normalized(legacy).welcome_day == WelcomeDay.fresh(), "Migration adds an unstarted invitation without resetting old progress")
	for invalid in [{"guest":true}, {"started":true,"picnic_step":1}, {"started":true,"celebrated":true}, {"picnic_step":1.5}, {"lesson":"yes"}, {"picnics":INF}]:
		check(not WelcomeDay.valid(invalid), "Invalid or impossible story state is rejected safely")
	check(not WelcomeDay.invite_momo(game), "Home visits require the shared story memory")
	check(not WelcomeDay.picnic_action(game).ok, "Picnic cannot skip the invitation and preparations")
	WelcomeDay.begin(game)
	check(game.life.welcome_day.started and not game.life.welcome_day.lesson, "Nora opens a persistent invitation")
	game.needs.Energy = 5
	IslandLife.train(game, "Come")
	check(not game.life.welcome_day.lesson, "A blocked lesson cannot advance the story")
	game.needs.Energy = 95
	IslandLife.train(game, "Sit")
	check(not game.life.welcome_day.lesson, "The story requires practicing its useful recall command")
	game.cooldowns.clear()
	IslandLife.train(game, "Come")
	check(game.life.welcome_day.lesson, "Actual Come training prepares the picnic recall game")
	IslandAdventure.choose_buddy(game, "Pippin")
	for i in 3:
		game.cooldowns.clear()
		IslandLife.playdate_step(game)
	check(not game.life.welcome_day.momo, "Another dog remains a valid friend but does not impersonate Momo")
	game.life.playdate.day = "2020-01-01"
	game.life.playdate.claimed = "2020-01-01"
	IslandAdventure.choose_buddy(game, "Momo")
	for i in 3:
		game.cooldowns.clear()
		IslandLife.playdate_step(game)
	check(game.life.welcome_day.momo, "A completed Momo playdate contributes to Welcome Day")
	WelcomeDay.pack_treats(game)
	game.cooldowns.clear()
	IslandActivities.beach_action(game, "Shells", 0)
	check(WelcomeDay.prepared(game.life.welcome_day), "Real play and visits prepare the picnic")
	check(game.save_game(), "Preparation and the new cooldown persist in a valid save")
	var preparation = game.life.welcome_day.duplicate(true)
	game.life.welcome_day = WelcomeDay.fresh()
	game.load_game()
	check(game.life.welcome_day == preparation, "Returning to the game restores every preparation")
	game.life.day = "2020-01-01"
	IslandLife.refresh_day(game)
	check(WelcomeDay.prepared(game.life.welcome_day), "Midnight never expires story preparations")
	game.resting = true
	check(not WelcomeDay.picnic_action(game).ok and game.life.welcome_day.picnic_step == 0, "The picnic waits for a sleeping dog")
	game.resting = false
	for step in 3:
		game.cooldowns.clear()
		var reply = WelcomeDay.picnic_action(game)
		check(reply.ok and reply.step == step + 1 and "Mochi" not in reply.text, "Picnic uses the current dog name and advances one moment")
		check(not WelcomeDay.picnic_action(game).ok, "Rapid taps cannot skip a picnic animation")
		check(game.save_game(), "Every picnic checkpoint is saveable")
	check(game.life.welcome_day.celebrated and game.items.PlushToy == 1 and game.life.toy == "PlushToy", "First picnic gives a usable toy and equips it only in an empty toy slot")
	var visits = IslandAdventure.buddy_visits(game, "Momo")
	check(visits == 2, "The first shared picnic strengthens Momo's friendship once")
	var earned_coins = game.coins
	game.cooldowns.clear()
	WelcomeDay.picnic_action(game)
	check(IslandAdventure.buddy_visits(game, "Momo") == visits and game.coins == earned_coins, "A completed picnic cannot duplicate rewards")
	game.life.toy = "Toy"
	game.items.Toy = 1
	check(WelcomeDay.repeat_picnic(game), "The picnic can be revisited without a daily gate")
	for step in 3:
		game.cooldowns.clear()
		WelcomeDay.picnic_action(game)
	check(game.life.welcome_day.picnics == 2 and game.life.toy == "Toy" and IslandAdventure.buddy_visits(game,"Momo") == visits, "Repeat picnics preserve the player's decor and do not farm friendship")
	check(WelcomeDay.invite_momo(game), "The picnic unlocks a lasting Home invitation")
	game.save_game()
	game.life = IslandLife.fresh()
	game.load_game()
	check(game.life.welcome_day.guest and game.life.welcome_day.celebrated, "Momo's home invitation survives reload")
	game.pending_stage = ""
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	check(main.habitat.companion_name() == "Momo" and is_instance_valid(main.habitat.playmate), "Home actually shows the invited friend")
	check(WalkArea.contains(main.habitat.puppy.walk_area,main.habitat.playmate.position), "Momo stays on Home's clear floor")
	main.show_page("Life:Welcome Day")
	await process_frame
	await process_frame
	var view = main.world_host.get_node("WelcomeDayView")
	check(main.habitat.background.texture == preload("res://assets/backgrounds/club_picnic_anime.png"), "Picnic uses its new matching anime background")
	check(main.habitat.puppy.current_breed == game.breed and main.habitat.companion_name() == "Momo", "The picnic uses the player's dog alongside the named friend")
	var old_button = view.content.get_child(0)
	for i in 5:
		game.advance(0.01)
		await process_frame
	check(is_instance_valid(old_button) and old_button == view.content.get_child(0), "Routine need updates do not recreate controls or steal taps")
	for dimensions in [Vector2i(1280,720),Vector2i(1558,720),Vector2i(980,550)]:
		root.size = dimensions
		await process_frame
		await process_frame
		view.arrange()
		check(view.actions_panel.get_rect().end.x <= view.size.x and view.actions_panel.get_rect().end.y <= view.size.y, "Picnic actions stay inside the screen")
		check(view.speech_panel.get_rect().end.x < view.actions_panel.position.x, "Speech does not overlap the activity buttons")
		check(view.portrait.position.x >= 0 and view.portrait.position.y > 0, "Nora has deliberate torso framing with head and arms on screen")
	for breed in Art.PUPPIES:
		game.breed = breed
		main.show_page("Life:Welcome Day")
		await process_frame
		await process_frame
		view = main.world_host.get_node("WelcomeDayView")
		var dog_bounds: Rect2 = main.habitat.puppy.sprite.get_global_transform() * main.habitat.puppy.sprite.get_rect()
		check(not view.speech_panel.get_global_rect().intersects(dog_bounds), "Picnic dialogue keeps every current breed visible")
		check(absf(dog_bounds.size.y / main.habitat.world.scale.y - 210) < 5, "All breeds have a consistent picnic presentation size")
	game.breed = "Puppy"
	main.show_page("Life:Welcome Day")
	await process_frame
	view = main.world_host.get_node("WelcomeDayView")
	game.cooldowns.clear()
	WelcomeDay.repeat_picnic(game)
	for step in 3:
		game.cooldowns.clear()
		view.enjoy_picnic()
		if step == 1:
			check(main.habitat.welcome_roll_ready, "Calling the dog opens a hands-on ball interaction")
			var world = main.habitat.world
			var ball_point = world.position + main.habitat.ball.position * world.scale
			var destination = world.position + main.habitat.buddy_origin() * world.scale
			var press = InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			press.position = ball_point
			main.habitat._gui_input(press)
			var drag = InputEventMouseMotion.new()
			drag.position = destination
			main.habitat._gui_input(drag)
			var release = InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_LEFT
			release.position = destination
			main.habitat._gui_input(release)
			check(game.life.welcome_day.picnic_step == 2 and not main.habitat.welcome_roll_ready, "Rolling the ball to Momo advances the shared game")
		await process_frame
		main.habitat._process(0.2)
		check(main.habitat.shared_kind == "Welcome%d" % (step+1), "Each picnic moment has its own visible animation")
		main.habitat._process(4)
		check(not main.habitat.ball.visible, "Picnic props clean up after each animation")
	main.go_back()
	check(main.page == "Puppy Club", "Back returns directly to the Club")
	main.start_welcome_lesson()
	check(main.page == "Moment:Recall" and main.world_host.has_node("IslandMomentView"), "Story shortcut opens Ben's hands-on recall lesson directly")
	main.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Welcome Day checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
