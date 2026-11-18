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
	for key in ["history","visits","completed","found_toy","found_basket","door_intro"]: game.life.surprises[key]=persistent[key]
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
	game.life.surprises.day="2020-01-01"
	check(IslandSurprises.info(game).is_empty() and not IslandSurprises.respond(game,true).ok,"Yesterday's unaccepted invitation cannot be opened from today's plans")
	IslandSurprises.offer(game)
	check(game.life.surprises.day==IslandLife.today(),"Ignoring yesterday's visitor leaves room for a new day")
	prepare(game,"Visit")
	IslandSurprises.respond(game,true)
	game.life.surprises.day="2020-01-01"
	check(not IslandSurprises.offer(game) and game.life.surprises.accepted,"An accepted play date is still waiting the next day")
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
	main.show_page("Shop")
	await settle()
	for dimensions in [Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		await settle()
		var basket=main.world_host.get_node("LocationGreeting/ReturnedBasket")
		var tap=InputEventMouseButton.new()
		tap.button_index=MOUSE_BUTTON_LEFT
		tap.position=basket.get_global_rect().get_center()
		tap.pressed=true
		view.push_input(tap,true)
		tap.pressed=false
		view.push_input(tap,true)
		check(is_instance_valid(main.resident_overlay),"June's basket receives a tap at its displayed position in "+str(dimensions))
		if is_instance_valid(main.resident_overlay):
			var basket_dialog=main.resident_overlay.find_children("*","RichTextLabel",true,false).any(func(line): return "my picnic basket" in line.get_parsed_text() and game.puppy_name in line.get_parsed_text())
			check(basket_dialog,"Tapping the basket opens June's personal thank-you in "+str(dimensions))
			main.resident_overlay.find_children("*","Button",true,false)[0].pressed.emit()
			await settle()
		if main.page!="Shop": main.show_page("Shop")
	view.size=Vector2i(1558,720)
	game.life.surprises=IslandSurprises.fresh()
	game.play_days=["2020-01-01",IslandLife.today()]
	game.life.welcome_day.celebrated=true
	game.life.welcome_day.picnics=1
	game.life.welcome_day.started=true
	game.life.welcome_day.guest=true
	game.set_process(true)
	main.show_page("Home")
	await settle()
	main.habitat.puppy.wake_briefly()
	var invitation=main.dog_invitation
	game.pending_stage="Young puppy"
	invitation._process(10)
	check(not is_instance_valid(invitation.door_guest),"A visitor waits while Nora has a growth announcement")
	game.pending_stage=""
	invitation._process(6.1)
	var visitor=invitation.door_guest
	check(is_instance_valid(visitor) and visitor.visible and game.life.surprises.buddy=="Momo" and not invitation.visible,"A first returning visitor appears in the scene without an invitation panel")
	check(is_instance_valid(main.habitat.playmate) and not main.habitat.playmate.visible and not main.habitat.playmate_name.visible and not main.habitat.playmate_shadow.visible,"Momo already visiting after the picnic appears only once at the door")
	main.open_navigation()
	invitation._process(0)
	check(not visitor.visible and main.habitat.playmate.visible,"Leaving the doorway interaction restores the usual Home playmate")
	main.close_navigation()
	await settle()
	invitation._process(0)
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.position=visitor.get_global_rect().get_center()
	click.pressed=true
	view.push_input(click,true)
	click.pressed=false
	view.push_input(click,true)
	check(main.page=="Fetch" and main.body.get_child(0).companion_name=="Momo","A tap on the visible visitor starts a game with that dog")
	game.life.welcome_day=WelcomeDay.fresh()
	game.set_process(false)
	IslandSurprises.clear_active(game.life.surprises)
	game.saved_outings={}
	game.active_outing={}
	game.life.adventure.buddies.Momo={"visits":6,"bonus_day":""}
	IslandSurprises.record_playmate(game,"Momo","Hello")
	var first_page=game.life.picture_pages.buddy.duplicate(true)
	IslandSurprises.record_playmate(game,"Momo","Fetch")
	game.save_game()
	game.load_game()
	check(game.life.picture_pages.buddy==first_page and first_page.buddy=="Momo" and first_page.name==game.puppy_name and first_page.day==IslandLife.today(),"The first best-friend picture keeps the original dog, friend and day")
	main.show_page("Journal")
	await settle()
	var folds=main.body.find_children("*","Button",true,false).filter(func(b): return "Our first best friend" in b.text)
	check(folds.size()==1,"The Journal offers one illustrated page per milestone")
	if folds.size()==1:
		folds[0].pressed.emit()
		var strip=folds[0].get_parent().get_child(folds[0].get_index()+1)
		check(strip.visible and strip.get_child_count()==2,"Opening the memory shows both manga panels")
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
		for frame in 600:
			if not fetch.busy: break
			fetch._process(1.0/60)
			dog._process(1.0/60)
	check(fetch.complete and game.life.surprises.kind.is_empty() and game.life.surprises.history.Pippin=="Fetch","Finishing Buddy Fetch completes the visit and remembers the shared game")
	coins=game.coins
	fetch.finish_fetch()
	check(game.coins==coins,"Reopening a completed Fetch cannot duplicate a visitor bonus")
	main.queue_free()
	view.queue_free()
	await process_frame
	print("Neighbor surprise checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
