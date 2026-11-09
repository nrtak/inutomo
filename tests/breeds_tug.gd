extends SceneTree
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1

func check_new_routes(game: Node):
	game.breed = "Puppy"
	game.life = IslandLife.fresh()
	game.walks = 0
	game.fetches = 0
	game.points = 0
	game.active_seconds = 0
	game.cooldowns.clear()
	game.resting = false
	game.needs = {"Hunger":80.0,"Happiness":50.0,"Energy":90.0,"Cleanliness":30.0}
	IslandActivities.beach_action(game,"Shells",1)
	check(game.life.growth_paths.Beagle==0,"Incorrect shell choices cannot encourage Beagle growth")
	IslandActivities.beach_action(game,"Shells",0)
	check(game.life.growth_paths.Beagle==1 and game.prediction()=="Beagle","A completed beach activity encourages Beagle growth")
	IslandActivities.beach_action(game,"Shells",0)
	game.cooldowns.clear()
	IslandActivities.beach_action(game,"Cleanup",0)
	IslandActivities.beach_action(game,"Cleanup",1)
	check(game.life.growth_paths.Beagle==1,"Repeats, cooldowns and partial cleanup do not add breed progress")
	for choice in [1,2]:
		game.cooldowns.clear()
		IslandActivities.beach_action(game,"Cleanup",choice)
	check(game.life.growth_paths.Beagle==2,"Finishing cleanup earns just one Beagle interest")
	IslandLife.playdate_step(game)
	IslandLife.playdate_step(game)
	check(game.life.growth_paths.Corgi==1,"A playdate step earns interest once and respects its breather")
	for step in 2:
		game.cooldowns.clear()
		IslandLife.playdate_step(game)
	game.cooldowns.clear()
	IslandLife.playdate_step(game)
	check(game.life.growth_paths.Corgi==3 and game.prediction()=="Corgi","A finished playdate encourages Corgi growth without repeat rewards")
	game.action("Care")
	game.action("Care")
	check(game.life.growth_paths["Toy Poodle"]==1,"Successful brushing encourages Toy Poodle growth once during its cooldown")
	game.items.Shampoo = 1
	game.cooldowns.clear()
	game.use_item("Shampoo")
	check(game.life.growth_paths["Toy Poodle"]==2 and game.items.Shampoo==0,"Using a real bath item encourages grooming growth")
	game.use_item("Shampoo")
	game.coins = 12
	game.clinic_groom()
	check(game.life.growth_paths["Toy Poodle"]==3 and game.coins==0,"Paid clinic grooming also encourages Toy Poodle growth")
	game.needs.Cleanliness = 50
	game.clinic_groom()
	check(game.life.growth_paths["Toy Poodle"]==3,"Failed purchases and unavailable shampoo do not award growth")
	game.needs.Cleanliness = 100
	game.cooldowns.clear()
	game.action("Care")
	game.items.Shampoo = 1
	game.use_item("Shampoo")
	game.clinic_groom()
	check(game.life.growth_paths["Toy Poodle"]==3 and game.items.Shampoo==1,"Full-cleanliness cuddles and unused items cannot farm growth interests")
	game.needs.Cleanliness = 40
	game.cooldowns.clear()
	game.action("Care")
	check(game.prediction()=="Toy Poodle","Grooming can become the leading growth route")
	var legacy = IslandLife.normalized({"growth_paths":{"Dachshund":4,"Miniature Collie":2}})
	check(legacy.growth_paths.Dachshund==4 and legacy.growth_paths["Miniature Collie"]==2 and legacy.growth_paths.Beagle==0 and legacy.growth_paths.Corgi==0 and legacy.growth_paths["Toy Poodle"]==0,"Existing breed interests survive migration and new routes start at zero")
	game.breed = "Golden Retriever"
	var previous = game.life.growth_paths.duplicate()
	GrowthRoutes.record(game,"Beach")
	GrowthRoutes.record(game,"Playdate")
	GrowthRoutes.record(game,"Grooming")
	check(game.life.growth_paths==previous,"An adult dog's breed stays settled after new activities")
	game.items.Shampoo = 0
	game.cooldowns.clear()
	game.life = IslandLife.fresh()

func check_phones(game: Node):
	UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1558,720)]:
		var view = SubViewport.new()
		view.size = dimensions
		root.add_child(view)
		var main = load("res://scenes/main.tscn").instantiate()
		view.add_child(main)
		for breed in GrowthRoutes.BREEDS:
			game.breed = breed
			game.pending_stage = ""
			game.resting = false
			game.life.accessory = ""
			game.cooldowns.clear()
			main.show_page("Home")
			game.changed.emit()
			await process_frame
			await process_frame
			var dog = main.habitat.puppy
			dog.set_process(false)
			dog.set_pose(false)
			var bounds: Rect2 = dog.sprite.get_global_transform()*dog.sprite.get_rect()
			check(not bounds.intersects(main.needs_card.get_global_rect()) and bounds.end.y<=dimensions.y-25,"Every breed fits below the status panel with visible paws: "+breed+" "+str(dimensions))
			check(main.identity_card.get_global_rect().end.y<main.island_button.get_global_rect().position.y,"Long breed names stay clear of Go to Island")
			main.show_page("Tug")
			await process_frame
			await process_frame
			var tug = main.world_host.get_node("TugGame")
			var panel_bounds = tug.panel.get_global_rect()
			var tug_dog = main.habitat.puppy
			tug_dog._process(0)
			bounds = tug_dog.sprite.get_global_transform()*tug_dog.sprite.get_rect()
			check(not bounds.intersects(panel_bounds),"The tug dog stays beside its controls on every phone")
			check(not panel_bounds.intersects(tug.rope.get_global_transform()*tug.rope.get_rect()),"The tug rope remains reachable outside the activity panel")
			check(panel_bounds.end.y<=dimensions.y-25,"Tug controls fit above the safe bottom edge")
		main.show_page("My Dogs")
		await process_frame
		await process_frame
		var footer = main.body.find_children("*","Label",true,false).filter(func(label):return label.text.begins_with("One puppy"))[0]
		check(footer.get_global_rect().end.y<=dimensions.y-25,"The expanded collection keeps its footer visible and scrolls the breed grid")
		view.queue_free()
		await process_frame
	UI.safe_override = {}

func run():
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://breeds_tug_test.json"
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.intro_seen = true
	game.name_chosen = true
	game.home_greeted = true
	game.pending_stage = ""
	game.paused_at = 0
	game.resting = false
	game.breed = "Puppy"
	game.points = 0
	game.active_seconds = 0
	game.walks = 0
	game.fetches = 0
	game.cooldowns.clear()
	check(game.prediction()=="Golden Retriever","Original zero-activity growth route stays compatible")
	game.walks = 2
	check(game.prediction()=="Shiba Inu","Walks still favor Shiba Inu")
	for i in 3: GrowthRoutes.record(game,"Scent")
	check(game.prediction()=="Dachshund","Scent discoveries open the Dachshund growth route")
	for i in 4: GrowthRoutes.record(game,"Training")
	check(game.prediction()=="Miniature Collie","Training opens the Miniature Collie growth route")
	check(not GrowthRoutes.valid({"Dachshund":-1}) and not GrowthRoutes.valid({"Miniature Collie":0.5}),"Malformed growth interests are rejected")
	check(IslandLife.valid({}) and IslandLife.normalized({}).growth_paths==GrowthRoutes.fresh(),"Old saves migrate without adding an accessory or inventing breed progress")
	check_new_routes(game)
	for breed in GrowthRoutes.BREEDS:
		game.breed = breed
		game.life.accessory = ""
		var dog = load("res://scripts/puppy.gd").new()
		root.add_child(dog)
		dog.set_process(false)
		check(not dog.outfit_equipped() and dog.sprite.texture==Art.PUPPIES[breed],"Every breed starts with a bare neck: "+breed)
		check(dog.walk_frames.size()==8 and dog.walk_texture==Art.WALKS[breed],"Every breed has eight matching walk poses")
		if Art.EXTRA_DOGS.has(breed):
			for dressed in [false,true]:
				var pose = Art.expression_texture(breed,"Tug",dressed)
				var mouth = Art.tug_mouth(breed,dressed)
				check(mouth.y>=pose.get_height()*0.55 and Rect2(Vector2.ZERO,pose.get_size()).has_point(mouth),"Tug attaches to the lower muzzle instead of pink ears: "+breed)
		for dressed in [false,true]:
			var atlas: Texture2D = (Art.DRESSED_WALKS if dressed else Art.WALKS)[breed]
			var frames: Array = (Art.DRESSED_WALK_DATA if dressed else Art.WALK_DATA)[breed].regions
			for frame in frames:
				check(Rect2(Vector2.ZERO,atlas.get_size()).encloses(Rect2(frame[0],frame[1],frame[2],frame[3])),"Every registered walk frame stays inside its own atlas: "+breed)
		for asleep in [false,true]:
			dog.set_pose(asleep)
			check(dog.sprite.texture == (Art.SLEEP_TEXTURES if asleep else Art.PUPPIES)[breed],"Sleep and idle use this breed's own bare artwork")
		for pose in ["Tilt","Stretch","Greet","Tug","Bow","Sniff"]:
			check(MomentArt.dog(breed,pose)!=null,"Every breed has its own scene and reaction pose: "+pose)
		for command in ["Paw","Spin","Bow","Roll Over"]:
			check(Art.trick_frames(breed,command).size()>=3,"Every breed keeps all trick animations")
		check(game.save_game(),"All breed saves validate: "+breed)
		game.load_game()
		check(game.breed==breed and game.life.accessory.is_empty(),"Saved breeds remain bare-necked after reload")
		check(WidgetState.artwork_image(game).get_size()==Vector2i(384,384),"Widgets can render each breed")
		dog.queue_free()
		await process_frame
	game.breed = "Puppy"
	game.life = IslandLife.fresh()
	game.points = 0
	game.active_seconds = 0
	game.needs = {"Hunger":80.0,"Happiness":50.0,"Energy":90.0,"Cleanliness":85.0}
	game.cooldowns.clear()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	game.set_process(true)
	main.show_page("Tug")
	var tug = main.world_host.get_node("TugGame")
	tug.set_process(false)
	tug.start_pull(Vector2.ZERO,true)
	tug._process(0.1)
	tug.release_pull()
	check(tug.rounds==0 and game.life.tug_games==0,"An early release cannot claim a tug turn")
	tug.start_pull(Vector2.ZERO,true)
	tug.tension = 0.52
	tug._process(0.4)
	tug.release_pull()
	check(tug.held_time==0 and tug.rounds==0,"Letting go early resets the steady hold rather than accumulating tiny taps")
	tug.start_pull(Vector2.ZERO,true)
	tug._process(0.3)
	main.open_navigation()
	tug._process(1.0)
	check(not tug.holding and tug.tension==0 and tug.rounds==0,"Opening Menu releases the rope and pauses tug progress")
	main.close_navigation()
	for turn in 3:
		for frame in 60: tug._process(1.0/60)
		tug.start_pull(Vector2.ZERO,true)
		for frame in 160: tug._process(1.0/60)
		check(tug.goal=="release","Steady gentle pulling asks the player to release")
		tug.release_pull()
	check(tug.rewarded and tug.rounds==3 and game.life.tug_games==1,"Three pull-and-release turns complete one shared game")
	check(game.life.growth_paths["Miniature Collie"]==1 and game.points==1,"Completed tug credits growth and one normal care moment")
	var points: int = game.points
	tug.finish()
	check(game.points==points and game.life.tug_games==1,"Tug rewards cannot be claimed twice")
	main.show_page("Home")
	var home_dog = main.habitat.puppy
	home_dog.set_process(false)
	home_dog.napping = false
	home_dog.nap_remaining = 0
	home_dog.awake_remaining = 120
	home_dog.reaction_time = 0
	home_dog.target = home_dog.position
	home_dog.begin_expression("Tilt")
	home_dog._process(0.1)
	check(home_dog.sprite.texture==Art.expression_texture("Puppy","Tilt") and home_dog.position==home_dog.target,"A head tilt uses real artwork without sliding the dog")
	home_dog.react_to_care("Care")
	check(home_dog.expression_time==0 and home_dog.reaction_kind=="Care","A care action interrupts an idle expression immediately")
	main.queue_free()
	await process_frame
	game.pending_stage = ""
	game.set_process(true)
	await check_phones(game)
	game.set_process(false)
	for target in GrowthRoutes.fresh():
		game.breed = "Puppy"
		game.life = IslandLife.fresh()
		game.life.growth_paths[target] = 100
		game.points = game.EVOLUTION_POINTS
		game.active_seconds = game.EVOLUTION_SECONDS
		game.last_stage = "Growing puppy"
		game.update_growth()
		check(game.breed==target and game.collection.back().breed==target,"Each added breed evolves and enters My Dogs: "+target)
	print("Breed, expression and tug checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
