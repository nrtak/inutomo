extends SceneTree
var failures = 0
func _initialize(): call_deferred("run")
func check(condition: bool,message: String):
	if not condition:
		push_error(message)
		failures+=1
func in_view(item: Control,view: Vector2i,description: String):
	if not item.is_visible_in_tree(): return
	var rect = item.get_global_rect()
	check(rect.position.x>=19 and rect.position.y>=19 and rect.end.x<=view.x-19 and rect.end.y<=view.y-19,description+" "+str(rect))
func settle():
	for frame in 6: await process_frame

func touch(view, index: int, point: Vector2, pressed: bool, canceled: bool=false):
	var event=InputEventScreenTouch.new()
	event.index=index
	event.position=point
	event.pressed=pressed
	event.canceled=canceled
	view.push_input(event,true)

func drag_touch(view, index: int, point: Vector2):
	var event=InputEventScreenDrag.new()
	event.index=index
	event.position=point
	view.push_input(event,true)

func check_pinch(view, map, place: String):
	var sign: Vector2=map.pins[place].get_global_rect().get_center()
	var spacing=Vector2(70,0)
	var original=map.map_rect
	var anchor=(sign+spacing*.5-original.position)/original.size
	touch(view,2,sign,true)
	touch(view,5,sign+spacing,true)
	drag_touch(view,5,sign+spacing*2)
	check(is_equal_approx(map.zoom_level,2.0),"Two fingers starting on a sign can zoom the island")
	check((map.map_rect.position+anchor*map.map_rect.size).distance_to(sign+spacing)<1,"The island point between the fingers follows their midpoint")
	drag_touch(view,5,sign+spacing*5)
	check(is_equal_approx(map.zoom_level,map.MAX_ZOOM),"Pinch zoom stops at the detail limit")
	drag_touch(view,5,sign+spacing*.5)
	check(is_equal_approx(map.zoom_level,1),"Pinching inward returns to full-screen scale")
	drag_touch(view,5,sign+spacing*2)
	touch(view,5,sign+spacing*2,false)
	var origin: Vector2=map.map_rect.position
	drag_touch(view,2,sign+Vector2(-20,-25))
	check(map.map_rect.position.distance_to(origin)>5,"The remaining finger can pan after a pinch")
	touch(view,2,sign+Vector2(-20,-25),false)
	check(not map.travelling,"Releasing a pinch over a sign never selects that destination")
	var updated_sign: Vector2=map.pins[place].get_global_rect().get_center()
	touch(view,1,updated_sign,true)
	touch(view,1,updated_sign,false,true)
	check(not map.travelling,"An interrupted tap cannot start travel")
	touch(view,1,updated_sign,true)
	touch(view,1,updated_sign,false)
	check(map.travelling and map.target_place==place,"One fresh tap selects the building at its zoomed position")

func run():
	var game = root.get_node("Game")
	game.storage_path = "user://orientation_checks.json"
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.resting=false
	game.set_process(false)
	UI.safe_override={"left":20,"right":20,"top":60,"bottom":45}
	var view = SubViewport.new()
	view.size=Vector2i(720,1558)
	root.add_child(view)
	var main = load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	for dimensions in [Vector2i(720,1558),Vector2i(1280,720),Vector2i(720,1280)]:
		view.size=dimensions
		main.show_page("Home")
		await settle()
		main.arrange_screen()
		await settle()
		for item in [main.identity_card,main.needs_card,main.menu_button,main.island_button,main.daily_button,main.camera_button]: in_view(item,dimensions,"Home control fits "+str(dimensions))
		for button in main.action_buttons.values(): in_view(button,dimensions,"Care action fits "+str(dimensions))
		var travel_position=main.travel.position
		game.changed.emit()
		check(main.travel.position==travel_position,"Needs updates do not move the portrait navigation row")
		if dimensions.y>dimensions.x:
			check(main.habitat.background.get_global_rect().grow(0.1).encloses(Rect2(Vector2.ZERO,Vector2(dimensions))),"Home scenery fills the portrait screen beneath the safe area")
			check(main.needs_card.get_global_rect().position.y>=main.identity_card.get_global_rect().end.y,"Portrait needs have their own row")
			var previous: Control
			for button in main.action_buttons.values():
				if previous!=null: check(previous.get_global_rect().end.x<=button.get_global_rect().position.x,"Portrait care controls form a separated bottom row")
				previous=button
		main.open_navigation()
		await settle()
		in_view(main.navigation_overlay.get_child(1).get_child(0),dimensions,"Navigation menu fits")
		main.close_navigation()
		for page in ["Island","Beach","Park","Puppy Club","Shop","Vet Clinic","Harbor","Keeper’s Cottage","Journal","Bag","Life:Events"]:
			main.show_page(page)
			main.arrange_screen()
			await settle()
			for item in [main.back_button,main.page_label,main.menu_button]: in_view(item,dimensions,page+" navigation fits")
			if main.body.get_child_count()>0:
				check(main.body.get_child(0).get_global_rect().end.x<=dimensions.x-19,page+" content fits horizontally")
			if dimensions.y>dimensions.x and page in main.LOCATION_PAGES:
				var dog=main.habitat.puppy
				dog._process(0)
				var bounds=dog.sprite.get_global_transform()*dog.sprite.get_rect()
				check(bounds.size.x>100 and bounds.size.y>100,"Location dog remains visible in portrait")
				check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(bounds),"Location dog fits the portrait stage")
				var greeting=main.world_host.get_node_or_null("LocationGreeting")
				if greeting:
					var speaker=greeting.get_child(0)
					var bubble=greeting.get_child(1)
					var gap=bubble.position.x-speaker.get_rect().end.x
					check(speaker.is_visible_in_tree() and gap>=0 and gap<=22,"The arriving resident stands beside the speech bubble")
					check(bubble.get_global_rect().end.x<main.body.get_child(0).beach_scroll.global_position.x,"The greeting clears the activity buttons")
				if page=="Shop":
					main.body.get_child(0).talk_to_june()
					await settle()
					var talk=main.resident_overlay
					var portrait=talk.get_node("ConversationCharacter").get_child(0)
					var bubble=talk.get_node("ConversationText")
					var gap=portrait.global_position.y-bubble.get_global_rect().end.y
					check(gap>=0 and gap<24,"June's dialogue stays just above her head on a tall screen")
					var content=bubble.get_child(1).get_global_rect()
					check(content.position.x-bubble.global_position.x>=28 and content.position.y-bubble.global_position.y>=18,"The text has space inside the rounded dialogue border")
					in_view(bubble,dimensions,"Shop dialogue fits inside the safe area")
					var close_button=bubble.find_children("*","Button",true,false)[0]
					close_button.pressed.emit()
					await settle()
	main.show_page("Park")
	view.size=Vector2i(720,1558)
	game.life.bowl=true
	for breed in GrowthRoutes.BREEDS:
		game.breed=breed
		main.show_page("Home")
		await settle()
		var dog=main.habitat.puppy
		dog.set_process(false)
		dog.napping=false
		dog.nap_remaining=0
		dog.awake_remaining=90
		dog.set_breed()
		for point in dog.walk_area:
			dog.position=point
			dog.set_pose(false)
			var bounds=dog.sprite.get_global_transform()*dog.sprite.get_rect()
			check(bounds.position.x>=-1 and bounds.end.x<=721,"Portrait walking keeps the whole dog visible: "+breed)
		dog.position=WalkArea.nearest(dog.walk_area,Vector2(640,550))
		dog.react_to_care("Feed")
		for frame in 900:
			dog._process(1.0/60)
			if dog.pending_decor_action.is_empty(): break
		check(dog.pending_decor_action.is_empty(),"Portrait feeding reaches the bowl: "+breed)
		var bowl=main.habitat.decor_sprites.Feed
		var bowl_rect=bowl.get_global_transform()*bowl.get_rect()
		check(Rect2(Vector2.ZERO,Vector2(view.size)).encloses(bowl_rect),"Portrait feeding bowl stays on screen")
	game.breed="Puppy"
	main.show_page("Park")
	game.needs.Energy=90
	game.set_process(true)
	main.start_activity("Fetch")
	var fetch=main.body.get_child(0)
	fetch.rounds=1
	fetch.score=1
	fetch._throw()
	for dimensions in [Vector2i(1280,720),Vector2i(720,1558),Vector2i(1280,720)]:
		view.size=dimensions
		await settle()
		check(main.body.get_child(0)==fetch and fetch.rounds==2 and fetch.busy and fetch.leg=="out","Rotation keeps the active Fetch throw")
		in_view(fetch.throw_button,dimensions,"Fetch controls stay reachable after rotation")
		if dimensions.y>dimensions.x:
			check(not main.back_button.get_global_rect().intersects(main.identity_card.get_global_rect()),"Portrait outing identity clears Back")
	main.show_page("Island")
	view.size=Vector2i(720,1558)
	await settle()
	var map=main.world_host.get_child(0)
	var before=map.map_rect.position.x
	var press=InputEventMouseButton.new()
	press.button_index=MOUSE_BUTTON_LEFT
	press.pressed=true
	press.position=Vector2(300,500)
	map.pan_input(press)
	var drag=InputEventMouseMotion.new()
	drag.position=Vector2(40,500)
	map.pan_input(drag)
	check(map.map_rect.position.x<before,"Portrait map can be dragged to other locations")
	map.travel_to("Beach")
	map._process(map.travel_duration*0.5)
	check(map.map_dog.position.x>=0 and map.map_dog.position.x<=720,"Portrait map camera follows the travelling dog")
	map._process(map.travel_duration)
	check(main.page=="Beach","Portrait travel still arrives after one location tap")
	for dimensions in [Vector2i(1280,720),Vector2i(720,1558)]:
		view.size=dimensions
		main.current_place="Park"
		main.show_page("Island")
		await settle()
		map=main.world_host.get_child(0)
		check_pinch(view,map,"Puppy Club")
		map._process(map.travel_duration*.45)
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).has_point(map.map_dog.position),"Zoomed travel keeps the walking dog on the map")
		map._process(map.travel_duration)
		check(main.page=="Puppy Club","Zoomed travel arrives at the tapped building")
	main.queue_free()
	view.queue_free()
	await process_frame
	UI.safe_override={}
	print("Orientation checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
