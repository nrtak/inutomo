extends SceneTree

var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func walk_to_find(view: Control, dog: Node) -> void:
	view.set_process(false)
	dog.set_process(false)
	for frame in 1800:
		dog._process(1.0/60)
		view._process(1.0/60)
		if view.pending<0: break

func run() -> void:
	var game = root.get_node("Game")
	game.storage_path = "user://connections_test.json"
	game.set_process(false)
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.resting = false
	game.paused_at = 0
	game.intro_seen = true
	game.name_chosen = true
	game.pending_stage = ""
	game.puppy_name = "Mochi"
	game.breed = "Puppy"
	game.needs = {"Hunger":80.0,"Happiness":65.0,"Energy":95.0,"Cleanliness":80.0}
	game.cooldowns.clear()
	game.active_outing = {}
	game.saved_outings = {}
	var legacy = IslandLife.fresh()
	legacy.erase("connections")
	check(IslandLife.valid(legacy) and IslandLife.normalized(legacy).connections==IslandConnections.fresh(),"Older progress migrates to an empty bond and mystery without losing anything")
	for bad in [{"shared":INF},{"mystery":6},{"offers":4},{"invitation":"Pet"},{"arrivals":{"Unknown":1}},{"arrivals":{"Nora":-1}},{"mystery":5},{"offer_day":23},{"offers":1}]:
		check(not IslandConnections.valid(bad),"Malformed connection state is rejected")
	check(IslandConnections.offer(game),"A healthy dog can offer a little invitation")
	var waiting: Dictionary = game.life.connections.duplicate(true)
	check(not IslandConnections.offer(game) and game.life.connections==waiting,"An unanswered invitation cannot be replaced or duplicated")
	check(game.save_game(),"A waiting invitation can be saved")
	game.life = IslandLife.fresh()
	game.load_game()
	check(game.life.connections.invitation==waiting.invitation,"The same invitation survives reload")
	var coins: int = game.coins
	var shared: int = game.life.connections.shared
	IslandConnections.respond(game,false)
	check(game.coins==coins and game.life.connections.shared==shared,"Later never penalizes needs, rewards, or bond")
	for offer in 2:
		check(IslandConnections.offer(game),"Different invitations rotate within the quiet daily limit")
		IslandConnections.respond(game,false)
	check(not IslandConnections.offer(game),"Invitation prompts are capped rather than endlessly interrupting play")
	game.life.connections.offer_day = "2099-01-01"
	check(not IslandConnections.offer(game),"A clock rollback cannot mint more invitations")
	game.life.connections = IslandConnections.fresh()
	game.resting = true
	check(not IslandConnections.offer(game),"Resting dogs are never asked to start an activity")
	game.resting = false
	game.life.connections.offer_day = IslandLife.today()
	game.life.connections.offers = 1
	game.life.connections.invitation = "Cuddle"
	var cuddle = IslandConnections.respond(game,true)
	check(cuddle.ok and cuddle.page.is_empty() and game.life.connections.shared==1,"Accepting quiet company is an actual bonding interaction")
	check(game.life.daily.get("Pet",0)==1,"Quiet company counts as pet care on daily activity cards")
	check(not IslandConnections.respond(game,true).ok,"A double tap cannot accept an invitation twice")
	game.life.connections.invitation = "Explore"
	game.cooldowns.Pet = 12
	game.cooldowns.Scent = 0
	check(IslandConnections.invitation_wait(game)==0,"Petting does not block an unrelated exploration invitation")
	game.cooldowns.Scent = 2
	check(not IslandConnections.respond(game,true).ok and game.life.connections.invitation=="Explore","An actual scent cooldown preserves the invitation instead of consuming it")
	game.cooldowns.Scent = 0
	check(IslandConnections.respond(game,true).ok,"Exploration becomes available when its own cooldown clears")
	game.cooldowns.clear()
	for i in 35: IslandConnections.record(game,"Play")
	check(IslandConnections.bond_name(game)=="A familiar team","Shared care changes the relationship description")
	check(not IslandConnections.advance_mystery(game,1,"Park",2).ok,"A clue cannot be collected before accepting the mystery")
	check(IslandConnections.advance_mystery(game,0,"Puppy Club").ok,"Nora starts a persistent mystery")
	check(not IslandConnections.advance_mystery(game,1,"Beach",2).ok,"A clue must be found in the correct location")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	# Every clue is found by walking the actual dog to a clickable prop.
	for step in [1,2,3]:
		main.show_page("Mystery")
		await process_frame
		await process_frame
		var view = main.world_host.get_node("IslandMysteryView")
		var dog = main.habitat.puppy
		var correct: int = IslandConnections.MYSTERY[step].spot
		view.search((correct+1)%3)
		game.set_process(true)
		walk_to_find(view,dog)
		game.set_process(false)
		check(not view.done and game.life.connections.mystery==step,"A wrong find gives a clue instead of advancing or penalizing the player")
		var click = InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = main.habitat.get_global_transform().affine_inverse()*view.props[correct].global_position
		view.handle_input(click)
		game.set_process(true)
		walk_to_find(view,dog)
		game.set_process(false)
		check(view.done and game.life.connections.mystery==step+1,"Finding the real prop advances one saved clue")
		check(WalkArea.contains(dog.walk_area,dog.position),"Discovery keeps paws on walkable ground")
		check(game.save_game(),"Every partial clue remains saveable")
		game.load_game()
		check(game.life.connections.mystery==step+1,"Each mystery checkpoint survives reload")
		main.go_back()
		check(main.page==IslandConnections.MYSTERY[step].place,"Back returns to the location where the clue was found")
	main.show_page("Puppy Club")
	main.body.get_child(0).mystery_action()
	check(game.life.connections.mystery==5 and is_instance_valid(main.resident_overlay),"Nora restores the star through the real location action")
	for button in main.resident_overlay.find_children("*","Button",true,false):
		if button.text=="Close":
			button.pressed.emit()
			break
	await process_frame
	await process_frame
	check(game.life.connections.memory_breed=="Puppy" and game.life.connections.memory_name=="Mochi","The keepsake records the player's actual dog")
	check(game.life.daily.get("Discovery",0)==3,"All three mystery finds count as real discoveries")
	var completed: Dictionary = game.life.connections.duplicate(true)
	check(not IslandConnections.advance_mystery(game,4,"Puppy Club").ok and game.life.connections==completed,"The ending and reward cannot be duplicated")
	for place in ["Home","Puppy Club"]:
		main.show_page(place)
		check(main.habitat.world.has_node("IslandMemoryVisual"),"The completed mystery leaves a real lasting decoration at "+place)
	check("star" in IslandConnections.greeting(game,"Nora","Hello"),"Residents remember the player's completed adventure")
	WelcomeDay.begin(game)
	main.show_page("Puppy Club")
	check(not "star" in main.world_host.get_node("LocationGreeting").text,"An active picnic invitation takes priority over a completed mystery greeting")
	game.life.adventure.buddies.Momo = {"visits":4,"bonus_day":""}
	check("Mochi" in IslandAdventure.buddy_greeting(game,"Momo"),"Familiar dog greetings recognize the player's own dog")
	game.active_outing = {}
	game.saved_outings = {}
	game.fetches = 2
	var outing = game.begin_outing("Fetch")
	check(outing.variant==2,"New Fetch visits rotate their play pattern")
	game.checkpoint_outing(1,1)
	game.save_game()
	game.active_outing = {}
	game.saved_outings = {}
	game.load_game()
	game.fetches = 0
	check(game.begin_outing("Fetch").variant==2,"Resuming a Fetch game retains its original pattern")
	check(not game.valid_outing({"kind":"Fetch","checkpoint":1,"score":1,"variant":INF}),"Invalid Fetch patterns cannot enter saved progress")
	var profiles = []
	for variant in 3: profiles.append(IslandConnections.fetch_profile(game,variant).center)
	check(profiles[0]!=profiles[1] and profiles[1]!=profiles[2],"Fetch variants have visibly different target zones")
	for nature in IslandLife.PERSONALITIES:
		for i in 200:
			game.puppy_name = "Dog"+str(i)
			if IslandLife.personality(game)==nature: break
		check(not IslandConnections.personality_hint(game,"Home").is_empty(),"Each personality has an invitation and activity response")
		check(IslandConnections.fetch_profile(game,0).radius==(24.0 if nature=="Cuddly" else (20.0 if nature=="Curious" else 18.0)),"Personality changes actual play tolerance")
	game.puppy_name = "Mochi"
	game.active_outing = {}
	game.saved_outings = {}
	game.cooldowns.clear()
	main.show_page("Home")
	if is_instance_valid(main.notice_overlay):
		main.notice_overlay.queue_free()
		main.notice_overlay = null
	game.set_process(true)
	main.habitat.puppy.napping = false
	main.habitat.puppy.awake_remaining = 300
	game.life.connections.invitation = "Cuddle"
	main.dog_invitation._process(0.016)
	check(main.dog_invitation.visible,"A waiting invitation has a usable Join and Later card at Home")
	main.habitat.puppy.napping = true
	main.dog_invitation._process(0.016)
	check(not main.dog_invitation.visible,"A saved invitation does not put a request over a sleeping puppy")
	main.habitat.puppy.napping = false
	main.open_navigation()
	var offers: int = game.life.connections.offers
	main.dog_invitation._process(200)
	check(not main.dog_invitation.visible and game.life.connections.offers==offers,"Menu time cannot trigger or display another invitation")
	main.close_navigation()
	main.open_photo_mode()
	main.dog_invitation._process(0.016)
	check(not main.dog_invitation.visible,"Invitations never cover photo mode")
	main.close_photo_mode()
	game.set_process(false)
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720)]:
		var viewport = SubViewport.new()
		viewport.size = dimensions
		root.add_child(viewport)
		var phone = load("res://scenes/main.tscn").instantiate()
		viewport.add_child(phone)
		UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
		for step in [1,2,3]:
			game.life.connections.mystery = step
			phone.show_page("Mystery")
			await process_frame
			await process_frame
			var view = phone.world_host.get_node("IslandMysteryView")
			var panel_rect = view.panel.get_global_rect()
			check(panel_rect.end.x<=dimensions.x-100 and panel_rect.end.y<=dimensions.y-25,"Clue controls remain inside the phone safe area")
			var portrait_rect = view.greeting.get_child(0).get_global_rect()
			for item in view.props:
				var bounds: Rect2 = item.get_global_transform()*item.get_rect()
				check(not portrait_rect.intersects(bounds) and not panel_rect.intersects(bounds),"Finds remain tappable clear of the character and menu: "+str(dimensions)+" clue "+str(step)+" find "+str(item.position)+" portrait "+str(portrait_rect)+" prop "+str(bounds)+" panel "+str(panel_rect))
			var dog = phone.habitat.puppy
			dog.set_pose(false)
			var dog_bounds: Rect2 = dog.sprite.get_global_transform()*dog.sprite.get_rect()
			check(not panel_rect.intersects(dog_bounds),"The player's dog stays clear of the clue panel")
			game.set_process(true)
			dog.set_process(true)
			view.search(0)
			phone.open_navigation()
			view._process(0.016)
			check(not dog.is_processing(),"A location menu pauses the dog during a clue search")
			phone.close_navigation()
			view._process(0.016)
			check(dog.is_processing(),"Closing the menu restores the previous dog movement state")
			game.set_process(false)
		viewport.queue_free()
		await process_frame
	UI.safe_override = {}
	main.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.storage_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
	print("Connection and mystery checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
