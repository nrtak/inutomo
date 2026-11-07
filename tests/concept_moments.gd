extends SceneTree
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func simulate(view: Control, dog: Node) -> void:
	view.set_process(false)
	dog.set_process(false)
	for frame in 1800:
		dog._process(1.0/60)
		view._process(1.0/60)
		if view.phase in ["ready","done"]: break

func run() -> void:
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://concept_moments_test.json"
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.resting = false
	game.paused_at = 0
	game.intro_seen = true
	game.name_chosen = true
	game.pending_stage = ""
	game.breed = "Puppy"
	game.items = {"Treat":0,"Toy":0,"Brush":0}
	game.needs = {"Hunger":70.0,"Happiness":60.0,"Energy":95.0,"Cleanliness":80.0}
	game.cooldowns.clear()
	game.active_outing = {}
	game.saved_outings = {}
	var legacy = IslandLife.fresh()
	legacy.erase("moments")
	check(IslandLife.valid(legacy) and IslandLife.normalized(legacy).moments == IslandMoments.fresh(), "Legacy progress migrates without losing its story or inventory")
	for malformed in [{"shell":"yes"},{"home":-1},{"recall":INF},{"glass":1}]:
		check(not IslandMoments.valid(malformed),"Invalid moment state cannot enter the save")
	check(not IslandMoments.complete(game,"Cottage").ok and not IslandMoments.complete(game,"Lighthouse").ok,"Keepsake and gathering respect restoration prerequisites")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	for breed in Art.PUPPIES:
		game.breed = breed
		var dog = load("res://scripts/puppy.gd").new()
		root.add_child(dog)
		dog.set_process(false)
		dog.set_pose(false)
		check(dog.sprite.texture == Art.PUPPIES[breed] and "bare" in dog.sprite.texture.atlas.resource_path,"Unequipped dogs have real bare-neck artwork")
		dog.set_pose(true)
		check(dog.sprite.texture == Art.SLEEP_TEXTURES[breed],"Sleep does not restore an unpurchased bandana")
		dog.prepare_walk_frames()
		check(dog.walk_texture == Art.WALKS[breed] and "bare" in dog.walk_texture.resource_path,"Walking uses eight accessory-free poses")
		game.items.CoralBandana = 1
		game.life.accessory = "CoralBandana"
		dog.set_pose(false)
		check(dog.sprite.texture == Art.DRESSED_PUPPIES[breed],"A purchased equipped accessory restores the appropriate clothed artwork")
		dog.illustrated_pose = "Sniff"
		dog._process(0.1)
		check(dog.sprite.texture == MomentArt.dog(breed,"Sniff",true),"New sniff poses also respect equipped accessories")
		game.life.accessory = ""
		dog._process(0.1)
		check(dog.sprite.texture == MomentArt.dog(breed,"Sniff"),"Taking off an accessory restores the bare-neck new pose")
		dog.queue_free()
		await process_frame
	game.breed = "Puppy"
	WelcomeDay.begin(game)
	for kind in ["Home","Recall","Beach"]:
		game.cooldowns.clear()
		main.show_page("Moment:"+kind)
		await process_frame
		await process_frame
		var view = main.world_host.get_node("IslandMomentView")
		check(main.habitat.background.texture == MomentArt.background(kind),"Each interaction uses its actual layered concept scenery")
		var actor_count = view.residents.size()
		check(actor_count == (0 if kind=="Home" else 1),"The correct resident is present without a separate Talk menu")
		view.begin()
		simulate(view,main.habitat.puppy)
		if kind == "Beach":
			check(view.phase == "ready" and main.habitat.puppy.illustrated_pose == "Sniff" and view.prop.visible,"The dogs lead the player to a real tappable find")
			var click = InputEventMouseButton.new()
			click.pressed = true
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = main.habitat.world.position + view.prop.position * main.habitat.world.scale
			check(view.handle_input(click),"The keepsake can be collected directly in the scene")
		check(view.phase == "done","The hands-on interaction reaches its meaningful finish: "+kind)
		main.go_back()
		check(main.page == IslandMoments.PLACES[kind],"Back returns to the correct place")
	check(game.life.moments.home == 1 and game.life.moments.recall == 1 and game.life.training.Come == 1,"Toy play and recall use real care and training progression")
	check(game.life.welcome_day.lesson and game.life.welcome_day.beach and game.life.welcome_day.momo,"Recall and beach friendship contribute to the open Welcome Day invitation")
	check("Pearl shell" in game.life.keepsakes and IslandAdventure.buddy_visits(game,"Momo") == 1,"Discovery adds a keepsake and remembers the shared friendship")
	game.cooldowns.clear()
	IslandMoments.complete(game,"Beach")
	check(game.life.keepsakes.count("Pearl shell") == 1 and IslandAdventure.buddy_visits(game,"Momo") == 1,"Repeating a find cannot duplicate inventory or friendship rewards")
	for action in ["welcome","kit","meet","deliver","lantern","repair_supplies","path_repaired"]:
		IslandStory.advance(game,action)
	game.cooldowns.clear()
	main.show_page("Moment:Cottage")
	await process_frame
	var cottage = main.world_host.get_node("IslandMomentView")
	cottage.begin()
	simulate(cottage,main.habitat.puppy)
	cottage.finish()
	check(game.life.moments.glass and "Sea glass" in game.life.keepsakes,"The cottage scene supplies Ren's existing display task")
	IslandStory.advance(game,"lens_polished")
	IslandStory.advance(game,"beacon_checked")
	check(not IslandMoments.block_reason(game,"Lighthouse").is_empty(),"Gathering also waits for the shared picnic")
	WelcomeDay.pack_treats(game)
	for step in 3:
		game.cooldowns.clear()
		WelcomeDay.picnic_action(game)
	game.cooldowns.clear()
	main.show_page("Moment:Lighthouse")
	await process_frame
	var gathering = main.world_host.get_node("IslandMomentView")
	check(gathering.residents.size()==2 and is_instance_valid(main.habitat.playmate),"Nora, Ren, the current dog and Momo share the lighthouse terrace")
	check(main.habitat.playmate.get_rect().size.y*main.habitat.playmate.scale.y > 150,"Momo remains visibly sized in the gathering rather than shrinking to zero")
	gathering.begin()
	check(gathering.phase=="done" and game.life.moments.gathered and game.items.SunshineBandana==1,"Gathering gives a lasting keepsake without equipping it automatically")
	check(game.life.accessory.is_empty(),"A reward never puts clothing on the dog without the player's choice")
	main.open_photo_mode()
	check(main.page=="Moment:Lighthouse" and gathering.photo_paused and not gathering.panel.visible and not gathering.bubble.visible,"Photo mode keeps the actual scene and hides its interface")
	main.close_photo_mode()
	check(not gathering.photo_paused and gathering.panel.visible,"Leaving photo mode restores interaction")
	var saved = game.save_game()
	check(saved,"Complete story, keepsakes and the new data are saveable")
	game.life = IslandLife.fresh()
	game.load_game()
	check(game.life.moments.gathered and game.life.moments.glass and game.life.moments.shell,"Every new milestone survives reload")
	# Interrupt an actual drag, rather than only exercising the Roll button.
	game.cooldowns.clear()
	game.items.Toy = 1
	game.life.toy = "Toy"
	main.show_page("Moment:Home")
	await process_frame
	var home = main.world_host.get_node("IslandMomentView")
	main.habitat._process(0.016)
	check(not main.habitat.home_toy.visible,"Stored decor stays hidden throughout the hands-on play scene")
	var weather: Node
	var weather_script = load("res://scripts/weather_layer.gd")
	for child in main.habitat.background.get_children():
		if child.get_script() == weather_script: weather = child
	check(weather.location in weather_script.INDOOR and weather_script.WINDOWS[weather.location] == weather_script.WINDOWS.Home,"Home play keeps rain behind the same window as ordinary Home")
	var daylight = root.get_node("Daylight")
	check(daylight.material_for("Moment:Home").get_shader_parameter("lamp_0") == daylight.material_for("Home").get_shader_parameter("lamp_0"),"Home play retains its evening room lighting")
	for interruption in ["Rest","Pause","Photo"]:
		var press = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = main.habitat.world.position + home.prop.position * main.habitat.world.scale
		home.handle_input(press)
		check(home.dragging,"The toy responds to a direct drag before " + interruption)
		home.prop.position = Vector2(850,610)
		match interruption:
			"Rest": game.resting = true
			"Pause": game.paused_at = Time.get_unix_time_from_system()
			"Photo": home.set_photo_mode(true)
		home._process(0.016)
		check(not home.dragging and home.prop.position == home.home_ball_point(),"Interrupted dragging releases and resets the toy: " + interruption)
		game.resting = false
		game.paused_at = 0
		if interruption == "Photo": home.set_photo_mode(false)
	var played_before: int = game.life.moments.home
	home.begin()
	game.needs.Energy = 0
	home._process(0.016)
	check(home.phase == "waiting" and main.habitat.puppy.target == main.habitat.puppy.position and game.life.moments.home == played_before,"An exhausted dog stops its toy route without awarding unfinished play")
	main.show_page("Moment:Lighthouse")
	await process_frame
	var tired_gathering = main.world_host.get_node("IslandMomentView")
	var recovery_button: Button
	for child in tired_gathering.content.get_children():
		if child is Button and child.get_meta("caption").text == "Rest at Home": recovery_button = child
	check(is_instance_valid(recovery_button),"Tired lighthouse visitors are directed to rest instead of repeating finished story prerequisites")
	if is_instance_valid(recovery_button):
		recovery_button.pressed.emit()
		check(main.page == "Home","The recovery action returns directly to Home")
	game.needs.Energy = 95
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720)]:
		var viewport = SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		var phone = load("res://scenes/main.tscn").instantiate()
		viewport.add_child(phone)
		UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
		for kind in IslandMoments.PLACES:
			for breed in Art.PUPPIES:
				game.breed = breed
				game.cooldowns.clear()
				phone.show_page("Moment:"+kind)
				await process_frame
				await process_frame
				var scene = phone.world_host.get_node("IslandMomentView")
				if kind in ["Beach","Cottage"]:
					phone.habitat.puppy.illustrated_pose = "Sniff"
					phone.habitat.puppy._process(0.016)
				var dog_bounds: Rect2 = phone.habitat.puppy.sprite.get_global_transform()*phone.habitat.puppy.sprite.get_rect()
				check(not scene.panel.get_global_rect().intersects(dog_bounds) and not scene.bubble.get_global_rect().intersects(dog_bounds),"Phone dialogue and actions leave each breed visible: "+kind+" "+breed)
				check(scene.panel.get_global_rect().end.x<=dimensions.x-100 and scene.bubble.get_global_rect().end.x<=dimensions.x-100,"Moment controls stay clear of the phone's side safe areas")
		viewport.queue_free()
		await process_frame
	UI.safe_override = {}
	main.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.storage_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
	print("Concept moments checks: ", "PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
