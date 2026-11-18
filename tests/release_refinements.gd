extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool,message: String):
	if not value:
		push_error(message)
		failures+=1
func settle():
	for frame in 12: await process_frame
func run():
	var game=root.get_node("Game")
	game.set_process(false)
	game.storage_path="user://release_refinements.json"
	game.life=IslandLife.fresh()
	game.health=PuppyHealth.fresh()
	game.items={}
	game.coins=0
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.paused_at=0
	game.resting=false
	game.breed="Puppy"
	game.needs={"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	var legacy=game.life.duplicate(true)
	legacy.erase("check_in")
	check(IslandLife.valid(legacy) and IslandLife.normalized(legacy).check_in==DailyCheckIn.fresh(),"Legacy saves gain check-in rewards without losing progress")
	for day in 14:
		var date="2030-01-%02d" % (day+1)
		check(DailyCheckIn.record(game,date),"Each forward local day counts once")
		check(not DailyCheckIn.record(game,date),"Reopening the app cannot farm sign-in progress")
	check(game.life.check_in.streak==14 and DailyCheckIn.pending(game)==[3,7,14],"The three streak milestones unlock in order")
	check(not DailyCheckIn.record(game,"2029-12-31"),"A backward clock or time-zone change cannot duplicate a day")
	DailyCheckIn.claim(game)
	check(game.coins==30 and game.items.get("SunshineBandana",0)==1 and game.life.accessory.is_empty(),"Milestones grant coins and an optional cosmetic without dressing the starting dog")
	DailyCheckIn.claim(game)
	check(game.coins==30,"A welcome-back gift is awarded only once")
	DailyCheckIn.record(game,"2030-01-17")
	check(game.life.check_in.streak==1 and game.life.check_in.best==14 and game.life.check_in.claimed.size()==3,"Missing a day preserves all earned gifts and the best streak")
	check(game.save_game(),"New reward progress saves successfully")
	game.load_game()
	check(game.life.check_in.best==14 and game.life.check_in.claimed.size()==3,"Welcome-back gifts survive reloading")
	var lighting=root.get_node("Daylight")
	lighting.set_process(false)
	for weather in IslandWeather.TYPES:
		IslandWeather.preview=weather
		lighting.refresh_weather(true)
		for location in lighting.MOTION:
			var material=lighting.material_for(location)
			check(is_equal_approx(float(material.get_shader_parameter("cloud_cover")),{"Sunny":0.0,"Passing clouds":.48,"Light rain":1.0}[weather]),"Scenery shares the forecast: "+location)
			check(material.get_shader_parameter("indoor")== (location in WeatherLayer.INDOOR),"Rain stays outside sheltered interiors: "+location)
	lighting.apply_minute(720,true)
	var noon=float(lighting.material.get_shader_parameter("exposure"))
	lighting.apply_minute(1320,true)
	check(float(lighting.material.get_shader_parameter("exposure"))<noon*.5,"Night scenery is genuinely darker than noon")
	check(float(lighting.material.get_shader_parameter("night_amount"))>.9,"Night uses its own blue art palette")
	lighting.apply_minute(1100,true)
	check(float(lighting.material.get_shader_parameter("sunset_amount"))==1.0,"Sundown uses an amber and warm brown palette")
	lighting.apply_minute(1320,true)
	var view=SubViewport.new()
	view.size=Vector2i(1558,720)
	root.add_child(view)
	var main=load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		main.show_page("Island")
		await settle()
		var map=main.world_host.get_child(0)
		for place in map.pins:
			var pin=map.pins[place]
			check(pin.size.y>=44,"Building signs retain a comfortable touch target")
			var sign: Control=map.signs[place]
			check(sign.size.y<map.map_rect.size.y*.07,"Signs fit into the painted scenery rather than covering buildings")
			check((pin.position+pin.size*.5).distance_to(map.map_rect.position+map.SIGN_POINTS[place]*map.map_rect.size)<1,"Every sign remains attached to its building or path when the map pans")
		var click=InputEventMouseButton.new()
		click.button_index=MOUSE_BUTTON_LEFT
		click.position=map.landmark_rect("Shop").get_center()
		click.pressed=true
		map.pan_input(click)
		click.pressed=false
		map.pan_input(click)
		check(map.travelling,"The actual building can be tapped directly")
		map._process(map.travel_duration+.1)
		main.show_page("Home")
		await settle()
		check(not main.camera_button.visible and main.travel.get_child_count()==2,"Home shows two travel shortcuts and keeps Photo inside Menu")
		main.open_navigation()
		var buttons=main.navigation_overlay.find_children("*","Button",true,false)
		var photo=buttons.filter(func(button):return button.text=="Take photo")
		check(photo.size()==1,"One clearly named photo action remains available")
		photo[0].pressed.emit()
		check(is_instance_valid(main.photo_overlay),"The simplified menu still opens the real photo tool")
		main.close_photo_mode()
		var dog=main.habitat.puppy
		dog.set_process(false)
		dog.controlled=true
		dog.wake_briefly()
		dog.target=dog.position
		dog.show_action_item(Goods.picture("Toy"))
		dog._process(.6)
		check(dog.action_item.visible and dog.action_item.texture==Goods.picture("Toy") and dog.expression_kind=="Sniff","A found ball appears alongside a real sniff pose")
		game.paused_at=1
		var time=dog.action_item_time
		dog._process(1)
		check(dog.action_item_time==time,"Pausing keeps the item reveal from being skipped")
		game.paused_at=0
		for kind in ["Care","Treat","Play"]:
			dog.controlled=false
			dog.home_interactions=false
			dog.react_to_care(kind)
			dog._process(.1)
			check(dog.action_item.visible and dog.action_item_kind==kind,"Care, treats and play show the actual object being used: "+kind)
	main.show_page("Moment:Lighthouse")
	await settle()
	check(main.habitat.background.material==lighting.material_for("Moment:Lighthouse"),"Lighthouse story artwork also follows night and weather lighting")
	IslandWeather.preview=""
	lighting.refresh(true)
	main.queue_free()
	view.queue_free()
	await process_frame
	print("Release refinement checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
