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
	game.storage_path="user://festival_checks.json"
	game.life=IslandLife.fresh()
	game.health=PuppyHealth.fresh()
	game.items={}
	game.coins=0
	game.points=0
	game.active_seconds=0
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.resting=false
	game.breed="Puppy"
	game.paused_at=0
	game.needs={"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	var legacy=game.life.duplicate(true)
	legacy.erase("festivals")
	legacy.erase("memories")
	check(IslandLife.valid(legacy),"Existing saves accept the optional festival and memory fields")
	check(IslandLife.normalized(legacy).festivals.size()==5,"Older saves receive all five gatherings")
	check(not IslandFestivals.valid({"Run":{"step":4}}),"Impossible progress cannot enter saved events")
	check(not IslandFestivals.valid({"Run":{"step":1,"score":2}}),"Festival score cannot exceed completed steps")
	check(not IslandFestivals.valid({"Run":{"step":3}}),"A completed event needs a saved reward date")
	check(not IslandMemories.valid({"unknown":"2026-11-17"}),"Unknown memories cannot enter the save")
	var rotation={}
	for day in ["2026-11-01","2026-11-02","2026-11-03","2026-11-04","2026-11-05"]: rotation[IslandFestivals.featured(day)]=true
	check(rotation.size()==5,"The featured gathering rotates through all five events")
	for id in IslandFestivals.EVENTS:
		IslandFestivals.begin(game,id)
		check(not IslandFestivals.advance(game,id,2).ok,"Out-of-order event steps cannot grant progress")
		check(IslandFestivals.advance(game,id,0).ok,"A neighbor gathering begins with its first activity")
		game.save_game()
		game.load_game()
		check(game.life.festivals[id].step==1,"Leaving and reloading preserves a festival checkpoint")
		game.resting=true
		check(not IslandFestivals.advance(game,id,1).ok,"Resting dogs keep their event progress without being forced to play")
		game.resting=false
		IslandFestivals.advance(game,id,1,false)
		var before=game.coins
		check(IslandFestivals.advance(game,id,2,false).ok and game.coins==before+15,"Participation receives the same thank-you even without perfect timing")
		IslandFestivals.begin(game,id)
		check(not IslandFestivals.advance(game,id,2).ok and game.coins==before+15,"Reloading or rejoining cannot duplicate a festival reward")
	check(game.life.memories.has("first_festival") and game.life.memories.has("festival_tour"),"A first gathering and all five gatherings leave distinct memories")
	check(game.life.friends.size()>=6,"Celebrations bring different neighbors into the player's friendships")
	game.life.training.Sit=5
	game.cooldowns.Training=0
	IslandLife.train(game,"Sit")
	check(game.life.memories.has("first_trick"),"Already trained dogs can also record their learned-trick memory")
	game.needs.Hunger=10
	check(IslandMemories.suggestion(game).get("focus","")=="Feed","Optional suggestions prioritize a meal over a festival invitation")
	game.needs.Hunger=80
	var view=SubViewport.new()
	view.size=Vector2i(1558,720)
	root.add_child(view)
	var main=load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	await settle()
	for dimensions in [Vector2i(1152,648),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		for id in IslandFestivals.EVENTS:
			game.life=IslandLife.fresh()
			main.show_page("Festival:"+id)
			await settle()
			var festival=main.world_host.get_node("IslandFestivalView")
			festival.set_process(false)
			var dog=main.habitat.puppy
			dog.set_process(false)
			check(main.back_target()=="Life:Events","Every gathering has a consistent return to Festivals")
			check(not festival.speaker_card.get_rect().intersects(festival.footer.get_rect()),"Neighbor speech and activities do not overlap: "+id+str(dimensions)+str(festival.speaker_card.get_rect())+str(festival.footer.get_rect()))
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(festival.footer.get_global_rect()),"Festival controls stay on screen: "+id+str(dimensions)+str(festival.footer.get_global_rect()))
			for button in festival.targets:
				check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"Scene props remain reachable: "+id+str(dimensions)+str(button.get_global_rect()))
			for stage in 3:
				if id=="Run":
					festival.press_action()
					festival.meter.value=50
					festival.press_action()
				else:
					festival.choose_prop((stage+1)%3)
					check(festival.phase=="ready","A different picnic or trick choice gives guidance without losing progress")
					festival.choose_prop(stage)
				if stage==0:
					main.open_navigation()
					var position=dog.position
					await settle()
					check(not festival.is_processing() and not dog.is_processing() and dog.position==position,"Menu pauses both the gathering and the dog")
					main.close_navigation()
					festival.set_process(false)
					dog.set_process(false)
				for frame in 900:
					festival._process(1.0/60)
					dog._process(1.0/60)
					if game.life.festivals[id].step>stage: break
				check(game.life.festivals[id].step==stage+1,"The actual "+id+" activity completes and checkpoints its step")
			check(festival.phase=="done","All three festival activities reach their shared celebration")
			main.go_back()
			await settle()
			check(main.page=="Life:Events","The festival return opens the gatherings list")
	game.resting=true
	main.show_page("Festival:Run")
	await settle()
	check(game.resting and not main.habitat.puppy.controlled,"Opening a gathering never wakes a resting dog")
	game.resting=false
	main.show_page("Puppy Club")
	await settle()
	var club=main.body.get_child(0)
	check(club.primary_actions.get_child_count()==3 and club.choices.get_child_count()==0 and club.talk_button.is_visible_in_tree(),"The Club uses three main activity cards and a separate Talk action, like Beach")
	game.life.delivery.recipient="Nora"
	club.primary_actions.get_child(2).pressed.emit()
	await settle()
	check(main.page=="Life:Club Plans" and main.back_target()=="Puppy Club","Club stories and events have a clear grouped screen and Back destination")
	var plans=main.body.get_child(0)
	check(plans.mode=="Club Plans" and plans.content.find_children("*","Button",true,false).size()>=4,"Welcome Day, festivals, stories and deliveries remain accessible")
	plans.open_club_story("mystery")
	await settle()
	check(main.page=="Puppy Club" and game.life.connections.mystery==1 and is_instance_valid(main.resident_overlay),"The grouped story action still starts Nora's missing-star story")
	main.resident_overlay.find_children("*","Button",true,false)[0].pressed.emit()
	await settle()
	var neighbors=main.world_host.get_node_or_null("ClubNeighbors")
	check(is_instance_valid(neighbors) and neighbors.dogs.size()==2,"Nora's Club already has two familiar dogs on arrival")
	for dog in neighbors.dogs:
		var rect: Rect2=dog.get_global_transform()*dog.get_rect()
		check(Rect2(Vector2.ZERO,Vector2(view.size)).encloses(rect),"Club friends stay visible on portrait screens")
	game.life.festivals=IslandFestivals.fresh()
	main.show_page("Festival:Run")
	await settle()
	var active=main.world_host.get_node("IslandFestivalView")
	active.set_process(false)
	main.habitat.puppy.set_process(false)
	active.press_action()
	active._process(0.5)
	view.size=Vector2i(1152,648)
	await settle()
	check(active.phase=="racing" and active.elapsed==0.5,"Rotating during a race preserves the current lap and timing")
	check(main.back_button.text=="‹ Back to Festivals","Rotation restores a readable landscape return button")
	main.queue_free()
	view.queue_free()
	await process_frame
	print("Festival checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
