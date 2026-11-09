extends SceneTree

var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1

func reset(game: Node):
	game.set_process(false)
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.breed = "Puppy"
	game.points = 0
	game.fetches = 0
	game.walks = 0
	game.active_seconds = 0
	game.coins = 50
	game.cooldowns.clear()
	game.paused_at = 0
	game.resting = false
	game.pending_stage = ""
	game.intro_seen = true
	game.name_chosen = true
	game.home_greeted = true
	game.active_outing = {}
	game.saved_outings = {}
	game.needs = {"Hunger":60.0,"Happiness":50.0,"Energy":90.0,"Cleanliness":30.0}
	game.items = {}
	for kind in Goods.ITEMS: game.items[kind] = 0

func check_rewards(game: Node):
	for balance in [999999,1000000]:
		reset(game)
		game.coins = balance
		game.life.day = IslandLife.today()
		game.life.daily.Care = 1
		game.life.favors.Nora = {"day":IslandLife.today(),"start":0,"claimed":""}
		var reply = IslandLife.favor(game,"Nora")
		check(game.coins==1000000 and ("1 coin." in reply if balance==999999 else "purse is full" in reply),"Favor feedback reports only coins actually received")
		reset(game)
		game.coins = balance
		game.life.delivery.recipient = "Ben"
		reply = IslandLife.deliver_parcel(game,"Park")
		check(game.coins==1000000 and ("1 coin." in reply if balance==999999 else "purse is full" in reply),"Parcel feedback reports only coins actually received")
		reset(game)
		game.coins = balance
		game.life.day = IslandLife.today()
		for task in IslandLife.event_info().tasks: game.life.daily[task] = 1
		reply = IslandLife.claim_event(game)
		check(game.coins==1000000 and ("1 coin." in reply if balance==999999 else "purse is full" in reply),"Event feedback reports only coins actually received")

func check_care_and_discoveries(game: Node):
	reset(game)
	check(IslandMoments.complete(game,"Beach").ok and game.life.growth_paths.Beagle==1,"The primary shell discovery encourages Beagle growth")
	game.cooldowns.clear()
	IslandMoments.complete(game,"Beach")
	check(game.life.growth_paths.Beagle==1,"Replaying the same shell find cannot duplicate breed interest")
	reset(game)
	game.items.Shampoo = 1
	game.life.adventure.chapters.Leah = {"step":1,"progress":0}
	game.use_item("Shampoo")
	check(game.life.daily.get("Care",0)==1,"A real shampoo care action counts toward care tasks")
	check(game.life.adventure.chapters.Leah.progress==1,"Bathing contributes to Leah's active gentle-care story")
	game.clinic_groom()
	check(game.life.daily.get("Care",0)==2,"Clinic grooming counts toward care tasks")
	game.needs.Cleanliness = 100
	game.clinic_groom()
	check(game.life.daily.get("Care",0)==2,"Unneeded grooming does not claim care tasks")
	check(game.points==0,"Purchased care keeps its existing growth-point rules")

func check_tug(game: Node):
	reset(game)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game.set_process(true)
	main.show_page("Tug")
	var tug = main.world_host.get_node("TugGame")
	tug.set_process(false)
	tug.rounds = 3
	tug.finish()
	var finished_text: String = tug.hint.text
	main.open_navigation()
	tug._process(0.1)
	main.close_navigation()
	tug._process(0.1)
	check(tug.rewarded and tug.hint.text==finished_text,"Closing Menu keeps the completed tug message")
	main.show_page("Home")
	game.cooldowns.clear()
	main.show_page("Tug")
	tug = main.world_host.get_node("TugGame")
	tug.set_process(false)
	game.cooldowns.Play = 1.0
	tug.rounds = 3
	tug.finish()
	check(not tug.rewarded,"A completed tug game respects a remaining Play cooldown")
	game.cooldowns.clear()
	tug._process(0.1)
	check(tug.rewarded and tug.rounds==3 and game.life.tug_games==2,"Three finished tug turns claim once after a breather without requiring a fourth turn")
	main.queue_free()
	await process_frame
	game.set_process(false)

func check_shop_motion(game: Node):
	reset(game)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.browse_shop("Food")
	var shop = main.body.get_child(0)
	game.reduce_motion = true
	var children = main.get_child_count()
	shop.purchase_feedback("Treat")
	check(main.get_child_count()==children,"Reduce Motion removes the flying shop purchase animation")
	check("[color=#247a4d]" in CommandHint.markup("Hold in the green band."),"The green band command uses the same green highlight as the target zone")
	game.reduce_motion = false
	main.queue_free()
	await process_frame

func check_modal_pauses(game: Node):
	reset(game)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game.set_process(true)
	for kind in ["Fetch","Walk"]:
		main.start_activity(kind)
		var activity = main.body.get_child(0)
		var activity_was_processing = activity.is_processing()
		activity.timer.start(10)
		main.show_need_tip("Energy")
		check(not game.is_processing() and not activity.is_processing() and activity.timer.paused,"Reading a needs tip pauses the current outing and its timer: "+kind)
		for button in main.tip_overlay.find_children("*","Button",true,false):
			if button.text=="Got it": button.pressed.emit()
		check(game.is_processing() and activity.is_processing()==activity_was_processing and not activity.timer.paused,"Closing a needs tip resumes the original outing state")
	main.show_page("Scent Trail")
	var trail = main.body.get_child(0)
	main.open_navigation()
	check(not game.is_processing() and not trail.is_processing() and not main.habitat.puppy.is_processing(),"Menu pauses the scent trail instead of completing discoveries behind it")
	main.close_navigation()
	check(game.is_processing() and trail.is_processing() and main.habitat.puppy.is_processing(),"Closing Menu resumes the scent trail")
	game.cooldowns.clear()
	main.show_page("Moment:Home")
	var moment = main.world_host.get_node("IslandMomentView")
	moment.begin()
	moment.dragging = true
	moment.prop.position += Vector2(40,-30)
	main.open_navigation()
	check(not moment.dragging and moment.prop.position==moment.home_ball_point(),"Opening Menu safely releases a toy being dragged")
	check(not game.is_processing() and not moment.is_processing() and not main.habitat.puppy.is_processing(),"Menu pauses a hands-on moment before it awards a result")
	main.close_navigation()
	check(game.is_processing() and moment.is_processing() and main.habitat.puppy.is_processing(),"Closing Menu resumes the hands-on activity")
	main.queue_free()
	await process_frame
	game.set_process(false)

func run():
	var game = root.get_node("Game")
	game.storage_path = "user://deep_regression.json"
	check_rewards(game)
	check_care_and_discoveries(game)
	await check_tug(game)
	await check_shop_motion(game)
	await check_modal_pauses(game)
	print("Deep regression checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
