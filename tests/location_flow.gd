extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool,message: String):
	if not value:
		push_error(message)
		failures+=1
func settle():
	for frame in 10: await process_frame
func run():
	var game=root.get_node("Game")
	game.set_process(false)
	game.storage_path="user://location_flow_checks.json"
	game.life=IslandLife.fresh()
	game.health=PuppyHealth.fresh()
	game.items={}
	game.resting=false
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.paused_at=0
	game.breed="Puppy"
	game.needs={"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	var view=SubViewport.new()
	view.size=Vector2i(1558,720)
	root.add_child(view)
	var main=load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		for advanced in [false,true]:
			game.life=IslandLife.fresh()
			game.life.story={"welcome":true,"met_keeper":true,"kit":true,"delivered":true,"lantern":true,"repair_supplies":true,"path_repaired":true,"lens_polished":true,"beacon_checked":true} if advanced else {}
			if advanced:
				game.life.welcome_day.started=true
				game.life.delivery.recipient="Ben"
				game.life.connections.mystery=1
			for place in main.LOCATION_PAGES:
				if place=="Lighthouse Room" and not advanced: continue
				main.show_page(place)
				await settle()
				var hub=main.body.get_child(0)
				check(hub.primary_actions.get_child_count()<=3 and hub.choices.get_child_count()<=1,"Every arrival keeps at most three main cards and one grouped option: "+place)
				check(is_instance_valid(hub.talk_button) and hub.talk_button.is_visible_in_tree(),"Every destination has a separate Talk action: "+place)
				check(hub.beach_scroll.get_global_rect().grow(1).encloses(hub.talk_button.get_global_rect()),"All Talk buttons remain reachable without scrolling: "+place+str(dimensions))
				var secondary=hub.secondary_store.get_children()
				if secondary.is_empty() or place=="Puppy Club": continue
				var expected=[]
				for button in secondary: expected.append(button.text)
				main.show_page("Plans:"+place)
				await settle()
				var plans=main.body.get_child(0)
				check(plans.plans_mode and main.back_target()==place,"Every grouped page names its return destination: "+place)
				var actual=[]
				for button in plans.primary_actions.get_children(): actual.append(button.text)
				for caption in expected: check(caption in actual,"Grouping preserves secondary actions: "+place+" "+caption)
				main.go_back()
				await settle()
				check(main.page==place,"Back returns to the correct arrival screen: "+place)
	for dimensions in [Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		for place in ["Shop","Vet Clinic","Keeper’s Cottage","Lighthouse Room"]:
			for breed in Art.PUPPIES:
				game.breed=breed
				main.show_page(place)
				await settle()
				var hub=main.body.get_child(0)
				var dog=main.habitat.puppy
				var bounds: Rect2=dog.sprite.get_global_transform()*dog.sprite.get_rect()
				check(Rect2(Vector2.ZERO,Vector2(view.size)).encloses(bounds),"Every dog breed fits its location presentation: "+place+" "+breed)
				for button in hub.primary_actions.get_children()+hub.choices.get_children(): check(not bounds.intersects(button.get_global_rect()),"Location activities stay clear of wide dog breeds: "+place+" "+breed)
	game.breed="Puppy"
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		for condition in PuppyHealth.CONDITIONS:
			game.health=PuppyHealth.fresh()
			PuppyHealth.start(game,condition)
			main.show_page("Vet Clinic")
			await settle()
			var clinic=main.body.get_child(0)
			check(clinic.beach_scroll.get_global_rect().grow(1).encloses(clinic.talk_button.get_global_rect()),"Illness details keep the vet's Talk action reachable: "+condition+str(dimensions)+str(clinic.beach_scroll.get_global_rect())+str(clinic.talk_button.get_global_rect()))
	game.health=PuppyHealth.fresh()
	game.life=IslandLife.fresh()
	main.show_page("Plans:Shop")
	await settle()
	var plans=main.body.get_child(0)
	for button in plans.primary_actions.get_children():
		if button.text=="Care goods": button.pressed.emit(); break
	await settle()
	check(main.page=="Shop Goods" and main.body.get_child(0).category=="Care","Shop care goods remain usable after grouping")
	main.go_back()
	await settle()
	check(main.page=="Plans:Shop","Browsing shop goods returns to the grouped shop page")
	main.show_page("Plans:Vet Clinic")
	await settle()
	plans=main.body.get_child(0)
	for button in plans.primary_actions.get_children():
		if button.text=="Health history": button.pressed.emit(); break
	await settle()
	check(main.page=="Life:Health Record","The vet's health history remains easy to open")
	main.go_back()
	await settle()
	check(main.page=="Plans:Vet Clinic","Health history returns to the vet's grouped care page")
	main.queue_free()
	view.queue_free()
	await process_frame
	print("Location flow checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
