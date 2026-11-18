extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool,message: String):
	if not value:
		push_error(message)
		failures+=1
func settle():
	for frame in 10: await process_frame
func prepare(game,kind: String,buddy: String = "Momo"):
	var persistent=game.life.surprises.duplicate(true)
	game.life.surprises=IslandSurprises.fresh()
	for key in ["history","visits","completed","found_toy"]: game.life.surprises[key]=persistent[key]
	game.life.surprises.day=IslandLife.today()
	game.life.surprises.kind=kind
	if kind=="Visit": game.life.surprises.buddy=buddy
func run():
	var game=root.get_node("Game")
	game.set_process(false)
	game.storage_path="user://surprise_checks.json"
	game.life=IslandLife.fresh()
	game.health=PuppyHealth.fresh()
	game.items={}
	game.coins=0
	game.points=8
	game.active_seconds=0
	game.fetches=0
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.paused_at=0
	game.resting=false
	game.breed="Puppy"
	game.needs={"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	var legacy=game.life.duplicate(true)
	legacy.erase("surprises")
	check(IslandLife.valid(legacy) and IslandLife.normalized(legacy).surprises==IslandSurprises.fresh(),"Old saves migrate without creating an unwanted task")
	for bad in [{"kind":"Unknown"},{"kind":"Visit","day":"2026-11-17","buddy":"Unknown"},{"kind":"Visit","day":"2026-11-17","buddy":"Momo","accepted":true,"step":1},{"kind":"Toy","day":"2026-11-17","step":2},{"history":{"Momo":"Purchase"}},{"kind":"","accepted":true}]:
		check(not IslandSurprises.valid(bad),"Invalid surprise progress cannot enter saved games")
	var offers=0
	for number in 60:
		game.life.surprises=IslandSurprises.fresh()
		game.puppy_name="Friend"+str(number)
		if IslandSurprises.offer(game): offers+=1
		var rolled=game.life.surprises.duplicate(true)
		IslandSurprises.offer(game)
		check(game.life.surprises==rolled,"Reopening the game does not reroll the day's surprise")
	check(offers>5 and offers<40,"Surprises happen on occasional days rather than every day")
	game.puppy_name="Mochi"
	prepare(game,"Visit")
	var coins=game.coins
	IslandSurprises.respond(game,false)
	check(game.coins==coins and game.life.surprises.kind.is_empty(),"Skipping an invitation has no penalty")
	for visit in 2:
		prepare(game,"Visit")
		check(IslandSurprises.respond(game,true).ok and IslandSurprises.choose_visit(game,"Hello"),"A visiting friend offers a quick cozy activity")
		coins=game.coins
		check(IslandSurprises.finish_visit(game,"Hello").ok and game.coins==coins+5,"A quiet hello earns a friendly thank-you")
		check(not IslandSurprises.finish_visit(game,"Hello").ok and game.coins==coins+5,"A visit reward cannot be claimed twice")
	prepare(game,"Visit")
	check("remembers" in IslandSurprises.info(game).text,"A familiar visitor remembers the player")
	for kind in IslandSurprises.REQUESTS:
		for route in ["Park","Beach"]:
			prepare(game,kind)
			IslandSurprises.respond(game,true)
			check(IslandSurprises.choose_route(game,route),"The player can choose how to follow a neighbor's clue")
			var spot=IslandSurprises.scent_spot(game)
			coins=game.coins
			check(not IslandSurprises.search(game,(spot+1)%3).ok and game.life.surprises.step==1,"An uncertain sniff gives a hint without losing progress")
			check(IslandSurprises.search(game,spot).ok and game.coins==coins,"Finding something requires returning it before a reward")
			game.life.surprises.day="2020-01-01"
			game.save_game()
			game.load_game()
			check(game.life.surprises.step==2 and not IslandSurprises.offer(game),"Unfinished requests survive leaving the game and changing days")
			check(not IslandSurprises.finish_request(game,"Vet Clinic").ok,"A found belonging goes back to its actual owner")
			check(IslandSurprises.finish_request(game,IslandSurprises.REQUESTS[kind].place).ok and game.coins==coins+8,"Returning the belonging gives one thank-you")
	check(game.life.surprises.found_toy and game.life.memories.has("neighbor_helper"),"Helping find a toy leaves a lasting scene detail and memory")
	var view=SubViewport.new()
	view.size=Vector2i(1558,720)
	root.add_child(view)
	var main=load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	for dimensions in [Vector2i(1152,648),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		prepare(game,"Visit")
		IslandSurprises.respond(game,true)
		main.show_page("Home")
		await settle()
		var home_friend: Rect2=main.habitat.playmate.get_global_transform()*main.habitat.playmate.get_rect()
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(home_friend),"An accepted visitor also fits the ordinary Home screen")
		main.show_page("Surprise")
		await settle()
		var surprise=main.world_host.get_node("NeighborSurpriseView")
		surprise.set_process(false)
		main.habitat.puppy.set_process(false)
		check(is_instance_valid(main.habitat.playmate),"The actual visiting dog appears alongside the player's dog")
		var player_rect: Rect2=main.habitat.puppy.sprite.get_global_transform()*main.habitat.puppy.sprite.get_rect()
		var friend_rect: Rect2=main.habitat.playmate.get_global_transform()*main.habitat.playmate.get_rect()
		check(not player_rect.intersects(friend_rect),"Visiting friends have their own space beside the player's dog")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(friend_rect),"Visiting friends fit on screen in either orientation")
		check(not friend_rect.intersects(surprise.panel.get_global_rect()),"Visit choices do not cover the visiting dog")
		surprise.start_visit("Hello")
		surprise._process(1.6)
		check(surprise.phase=="done" and game.life.surprises.kind.is_empty(),"The quick hello plays through to its saved ending")
		prepare(game,"Toy")
		main.show_page("Surprise")
		await settle()
		surprise=main.world_host.get_node("NeighborSurpriseView")
		surprise.choose_route("Park")
		await settle()
		surprise=main.world_host.get_node("NeighborSurpriseView")
		surprise.set_process(false)
		var dog=main.habitat.puppy
		dog.set_process(false)
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(surprise.panel.get_global_rect()),"Surprise choices fit both orientations")
		surprise.inspect(IslandSurprises.scent_spot(game))
		main.open_navigation()
		var position=dog.position
		await settle()
		check(not surprise.is_processing() and not dog.is_processing() and dog.position==position,"Menu pauses a neighbor search and its dog")
		main.close_navigation()
		surprise.set_process(false)
		dog.set_process(false)
		for frame in 900:
			surprise._process(1.0/60)
			dog._process(1.0/60)
			if game.life.surprises.step==2: break
		check(game.life.surprises.step==2,"The dog physically reaches a clue and sniffs out the item")
		main.show_page("Plans:Park")
		await settle()
		main.body.get_child(0).complete_neighbor_request()
		check(game.life.surprises.kind.is_empty() and is_instance_valid(main.resident_overlay),"The neighbor receives the found belonging through the actual location")
		main.resident_overlay.find_children("*","Button",true,false)[0].pressed.emit()
		await settle()
		check(main.page=="Plans:Park" and main.body.get_child(0).plans_mode,"Finishing a request keeps the organized location page")
	prepare(game,"Visit","Pippin")
	game.fetches=0
	game.saved_outings={}
	game.active_outing={}
	main.show_page("Surprise")
	await settle()
	main.world_host.get_node("NeighborSurpriseView").start_visit("Fetch")
	await settle()
	check(main.page=="Fetch" and main.activity_origin=="Home","A longer visit starts a Fetch outing with a clear return Home")
	var fetch=main.body.get_child(0)
	fetch.set_process(false)
	var dog=main.habitat.puppy
	dog.set_process(false)
	check(fetch.companion_name=="Pippin" and is_instance_valid(fetch.companion),"The visiting friend really plays alongside the dog")
	for tick in 30:
		var previous=fetch.companion.position
		fetch.update_companion(1.0/60)
		check(WalkArea.clear_segment(previous,fetch.companion.position,dog.active_barriers(),true),"The Fetch friend follows the same physical boundaries as our dog")
	for round in 3:
		fetch.bar.value=fetch.profile.center
		fetch._throw()
		fetch.timer.stop()
		for frame in 180:
			fetch._process(1.0/60)
			dog._process(1.0/60)
		fetch.timer.timeout.emit()
		fetch.timer.stop()
		for frame in 150:
			fetch._process(1.0/60)
			dog._process(1.0/60)
		fetch.timer.timeout.emit()
	check(fetch.complete and game.life.surprises.kind.is_empty() and game.life.surprises.history.Pippin=="Fetch","Finishing Buddy Fetch completes the visit and remembers the shared game")
	coins=game.coins
	fetch.finish_fetch()
	check(game.coins==coins,"Reopening a completed Fetch cannot duplicate a visitor bonus")
	main.queue_free()
	view.queue_free()
	await process_frame
	print("Neighbor surprise checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
