extends SceneTree
var failures = 0
class FakePedometer extends RefCounted:
	var supported = true
	var response = {"ready":false}
	var queries = 0
	func is_available():
		return supported
	func query_today():
		queries += 1
	func get_result():
		var value = response
		response = {"ready":false}
		return value
func _initialize():
	call_deferred("run")
func check(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func run():
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://steps_flow_test.json"
	game.walking = PuppySteps.fresh()
	game.health = PuppyHealth.fresh()
	game.life = IslandLife.fresh()
	game.intro_seen = true
	game.pending_stage = ""
	game.resting = false
	game.needs = {"Hunger":80.0,"Happiness":50.0,"Energy":90.0,"Cleanliness":85.0}
	var day = IslandLife.today()
	check(not PuppySteps.accept(game,day,500),"Steps require the optional connection")
	game.walking.enabled = true
	check(PuppySteps.accept(game,day,500) and game.walking.total == 500,"Today's sensor total adds to the shared journey")
	var coins = game.coins
	var growth = game.points
	PuppySteps.claim(game,500)
	check(game.coins == coins+3 and game.needs.Happiness == 52,"First step milestone gives modest coins and happiness")
	PuppySteps.claim(game,500)
	check(game.coins == coins+3,"Walking rewards cannot be claimed twice")
	PuppySteps.accept(game,day,100)
	check(game.walking.today == 500 and game.walking.total == 500,"Repeated or lower sensor totals never duplicate or subtract steps")
	PuppySteps.accept(game,day,3000)
	PuppySteps.claim(game,1500)
	PuppySteps.claim(game,3000)
	check(game.coins == coins+12 and game.points == growth,"All step rewards cap at 12 daily coins without replacing care-based growth")
	check(not PuppySteps.accept(game,day,NAN) and not PuppySteps.accept(game,day,-1) and not PuppySteps.accept(game,day,100001),"Invalid sensor readings are rejected")
	game.save_game()
	game.walking = PuppySteps.fresh()
	game.load_game()
	check(game.walking.total == 3000 and game.walking.claimed.size() == 3,"Steps and claimed rewards survive save/load")
	var yesterday = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(day+"T12:00:00")-86400)
	game.walking.day = yesterday
	PuppySteps.accept(game,day,400)
	check(game.walking.today == 400 and game.walking.total == 3400 and game.walking.claimed.is_empty(),"A new day resets daily progress while preserving the journey")
	check(not PuppySteps.accept(game,yesterday,500),"Old-date callbacks cannot reset rewards")
	var invalid = game.walking.duplicate(true)
	invalid.claimed = [500]
	check(not PuppySteps.valid(invalid),"Unreached step rewards cannot load as claimed")
	check(PuppySteps.valid({}) and PuppySteps.valid(game.walking),"Legacy saves and valid step state are supported")
	var steps = root.get_node("Steps")
	var sensor = FakePedometer.new()
	steps.native = sensor
	game.walking.enabled = false
	steps.enable()
	check(sensor.queries == 1 and game.walking.enabled,"Connecting explicitly starts a step query")
	sensor.response = {"ready":true,"error":"denied"}
	steps._process(0.1)
	check("Settings" in steps.status and not steps.pending,"Denied motion access explains how to recover without blocking the game")
	steps.refresh()
	steps._process(31)
	check(not steps.pending and "retry" in steps.status,"A stalled step query times out with a retry option")
	var timed_out_queries = sensor.queries
	steps._process(0.1)
	check(sensor.queries == timed_out_queries and not steps.pending,"A timeout leaves time to retry instead of immediately restarting the query")
	steps.refresh()
	sensor.response = {"ready":true,"error":"","day":day,"steps":450}
	steps._process(0.1)
	check(game.walking.today == 450,"Successful sensor response reaches the game")
	steps.disable()
	var query_count = sensor.queries
	steps.refresh()
	check(sensor.queries == query_count and not game.walking.enabled,"Disconnected steps never read the sensor")
	sensor.supported = false
	steps.enable()
	check(not game.walking.enabled,"Unsupported devices cannot enable pretend step data")
	steps.native = null
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.show_page("Life:Steps")
	await process_frame
	check(main.body.get_child(0).mode == "Steps","Walking companion has a real game page")
	main.show_page("Park")
	game.resting = true
	game.changed.emit()
	var hub = main.body.get_child(0)
	check(hub.primary_actions.get_child(0).disabled and hub.unavailable.visible,"Unavailable outings have a visible explanation")
	game.resting = false
	game.changed.emit()
	check(not hub.primary_actions.get_child(0).disabled,"Outings become available again after waking")
	main.show_page("Life:Training")
	main.go_back()
	check(main.page == "Park","Training returns to its location")
	main.go_back()
	check(main.page == "Island","Location Back returns to map")
	main.go_back()
	check(main.page == "Home","Map Back returns Home without a location loop")
	main.daily_shortcut({"place":"Home","focus":"Feed"})
	check(main.action_buttons.Feed.has_focus(),"Daily care cards highlight the next action")
	game.needs.Cleanliness = 20
	check("brush" in main.home_hint(),"Home gently suggests care for the lowest need")
	game.needs.Cleanliness = 85
	main.show_page("Beach")
	var first = main.world_host.get_node("LocationGreeting").duration
	main.show_page("Beach")
	check(main.world_host.get_node("LocationGreeting").duration <= first,"Repeat greetings are brief and never block activities")
	game.coins += 4
	game.changed.emit()
	check(is_instance_valid(main.reward_notice),"Earned coins show a small reward notice")
	main.open_photo_mode()
	check(not main.reward_notice.visible,"Photo mode excludes reward notices")
	main.close_photo_mode()
	check(main.reward_notice.visible,"Leaving photo mode restores an unexpired reward notice")
	main.queue_free()
	await process_frame
	UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
	for width in [1280,1558]:
		var phone = SubViewport.new()
		phone.size = Vector2i(width,720)
		root.add_child(phone)
		main = load("res://scenes/main.tscn").instantiate()
		phone.add_child(main)
		main.show_page("Life:Steps")
		await process_frame
		await process_frame
		var browser = main.body.get_child(0)
		var panel = browser.get_child(0)
		var bounds = panel.get_global_rect()
		check(bounds.position.x >= 105 and bounds.end.x <= width-105 and bounds.end.y <=695,"Walking companion fits phone safe areas")
		main.queue_free()
		phone.queue_free()
		await process_frame
	UI.safe_override = {}
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path+suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
	print("Steps and flow checks: ","PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
