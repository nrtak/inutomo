extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool,message: String):
	if not value:
		push_error(message)
		failures+=1
func settle():
	for frame in 8: await process_frame
func close_conversation(main):
	main.resident_overlay.find_children("*","Button",true,false)[0].pressed.emit()
func run():
	var game=root.get_node("Game")
	game.set_process(false)
	game.storage_path="user://ui_polish_checks.json"
	game.life=IslandLife.fresh()
	game.health=PuppyHealth.fresh()
	game.intro_seen=true
	game.name_chosen=true
	game.home_greeted=true
	game.pending_stage=""
	game.resting=false
	game.breed="Puppy"
	game.points=0
	game.active_seconds=0
	game.paused_at=0
	game.cooldowns.clear()
	game.set_reduce_motion(false,false)
	var view=SubViewport.new()
	view.size=Vector2i(1558,720)
	root.add_child(view)
	var main=load("res://scenes/main.tscn").instantiate()
	view.add_child(main)
	for dimensions in [Vector2i(1152,648),Vector2i(1558,720),Vector2i(720,1558)]:
		view.size=dimensions
		UI.safe_override={"left":20 if dimensions.y>dimensions.x else 105,"right":20 if dimensions.y>dimensions.x else 105,"top":60 if dimensions.y>dimensions.x else 20,"bottom":45 if dimensions.y>dimensions.x else 25}
		main.show_page("Home")
		await settle()
		var icons=main.needs_card.find_children("*","Button",true,false)
		check(icons[1].icon==UI.care_icon("Happiness") and UI.CARE_ICONS.Happiness=="heart","The game and widget share a clear heart for happiness")
		for key in main.meter_labels:
			var value=main.meter_labels[key]
			check(is_equal_approx(value.get_global_rect().end.x,value.get_parent().get_global_rect().end.x),"Need values align with the right edge of their own row")
		main.open_navigation()
		await settle()
		var buttons=main.navigation_overlay.find_children("*","Button",true,false)
		var title_button: Button
		for button in buttons:
			if button.text=="Title screen": title_button=button
		check(title_button!=null and title_button.size.y<90,"Title screen is a secondary menu action")
		check(title_button.get_parent() is HBoxContainer,"Leaving the game is separated from the main menu pictures")
		main.close_navigation()
		for location in ["Puppy Club","Park","Beach","Shop","Vet Clinic","Harbor","Keeper’s Cottage"]:
			main.show_page(location)
			await settle()
			var hub=main.body.get_child(0)
			check(hub.talk_button.is_visible_in_tree(),"Conversation is discoverable in both orientations: "+location)
			var bounds=hub.talk_button.get_global_rect()
			check(hub.beach_scroll.get_global_rect().grow(1).encloses(bounds),"The welcome Talk action fits beside the activity cards: "+location+" "+str(dimensions))
			var style=hub.talk_button.get_theme_stylebox("normal") as StyleBoxFlat
			check(style.bg_color==Color("e7dff2"),"Talking has its own quiet lavender color")
			hub.talk_button.pressed.emit()
			check(is_instance_valid(main.resident_overlay),"The Talk action opens the current resident")
			close_conversation(main)
			await process_frame
		for kind in ["Fetch","Walk"]:
			main.show_page("Park" if kind=="Fetch" else "Beach")
			main.start_activity(kind)
			await settle()
			for control in [main.back_button,main.needs_card,main.menu_button]:
				var bounds=control.get_global_rect()
				check(bounds.end.x<=dimensions.x-UI.safe_insets().right+1,"Active outing header remains inside the phone safe area: "+kind+" "+str(dimensions))
			main.show_page("Home")
	main.show_page("Shop")
	main.browse_shop("Food")
	check(main.back_button.text=="‹ Back to Shop","Shop browsing says exactly where Back will go")
	main.go_back()
	check(main.page=="Shop","The Back label matches the actual destination")
	main.show_page("Home")
	var action=main.action_buttons.Feed
	UI.press_feedback(action,.97)
	await create_timer(.12).timeout
	check(action.scale.x<1,"An enabled button provides a gentle press response")
	action.mouse_exited.emit()
	await create_timer(.12).timeout
	check(action.scale.is_equal_approx(Vector2.ONE),"A canceled press cannot leave a button shrunk")
	UI.press_feedback(action,.97)
	action.hide()
	check(action.scale.is_equal_approx(Vector2.ONE),"A hidden button resets an interrupted press")
	action.show()
	game.set_reduce_motion(true,false)
	UI.press_feedback(action,.97)
	check(action.scale.is_equal_approx(Vector2.ONE),"Reduce Motion disables button scaling")
	main.visit("Beach")
	check(main.arrival_overlay==null,"Reduce Motion skips the arrival wash")
	game.set_reduce_motion(false,false)
	main.visit("Home")
	var wash=main.arrival_overlay.get_child(0)
	check(wash.color.a<=.16 and wash.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Arrival never hides the scenery or blocks touches")
	await create_timer(.3).timeout
	check(not is_instance_valid(main.arrival_overlay),"Arrival finishes promptly")
	main.queue_free()
	view.queue_free()
	UI.safe_override.clear()
	await process_frame
	print("UI polish checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
