extends SceneTree

var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1

func run():
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://dog_animation_checks.json"
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.items = {}
	game.resting = false
	game.paused_at = 0
	game.intro_seen = true
	game.name_chosen = true
	game.pending_stage = ""
	game.set_reduce_motion(false,false)
	game.home_greeted = true
	game.welcome_away_seconds = 0
	for gap in [-1.0,60.0,1799.0,INF]: game.record_return(gap)
	check(game.home_greeted and game.welcome_away_seconds==0,"Short visits and invalid clocks do not trigger a big welcome")
	var points = game.points
	var coins = game.coins
	game.record_return(7200)
	check(not game.home_greeted and game.welcome_away_seconds==7200,"A longer absence queues one welcome")
	check(game.points==points and game.coins==coins,"Welcome presentation never changes progression or currency")
	for breed in Art.PUPPIES:
		game.breed = breed
		game.life.accessory = ""
		var dog = load("res://scripts/puppy.gd").new()
		root.add_child(dog)
		dog.set_process(false)
		dog.position = Vector2(650,600)
		dog.target = dog.position
		dog.welcome_player(7200)
		check(dog.welcome_hops==3 and dog.expression_kind=="Greet" and not dog.napping,breed+" wakes for an enthusiastic return greeting")
		dog._process(0.5)
		check(dog.sprite.position.y<0,breed+" jumps visibly to greet the player")
		game.set_reduce_motion(true,false)
		dog._process(0.1)
		check(dog.sprite.position==Vector2.ZERO and dog.sprite.rotation==0,"Reduce Motion removes welcome hops")
		game.set_reduce_motion(false,false)
		dog.react_to_care("Feed")
		dog._process(0.15)
		check(dog.reaction_kind=="Feed" and dog.sprite.position.y<0,breed+" anticipates a meal")
		var anticipation = dog.sprite.texture
		dog._process(0.8)
		check(dog.sprite.texture!=anticipation and dog.sprite.texture==MomentArt.dog(breed,"Sniff"),breed+" lowers its head to eat")
		check(dog.visible_size.y*dog.base_scale<=dog.awake_height(),"Head-down eating never enlarges the dog")
		game.set_reduce_motion(true,false)
		dog._process(0.1)
		check(dog.sprite.position==Vector2.ZERO and dog.sprite.rotation==0,"Reduce Motion keeps eating still")
		game.set_reduce_motion(false,false)
		dog.home_interactions = true
		dog.arriving_at_decor = true
		dog.position = IslandLife.feeding_point(game)
		dog.target = dog.position
		dog.react_to_care("Feed")
		dog.arriving_at_decor = false
		dog._process(1.1)
		game.set_reduce_motion(true,false)
		dog._process(0.1)
		check(dog.sprite.position==Vector2.ZERO,"Reduce Motion disables meal leaning as well as bouncing")
		game.set_reduce_motion(false,false)
		dog._process(2.5)
		check(is_zero_approx(dog.sprite.position.x),"The dog settles back after its meal without a lingering sideways offset")
		dog.home_interactions = false
		dog.target=dog.position
		dog.reaction_time=0
		dog.napping=false
		var resting_position=dog.position
		dog.notice_point(dog.position-Vector2(100,0))
		dog._process(0.05)
		check(dog.sprite.flip_h and dog.expression_kind=="Tilt" and dog.position==resting_position,"An awake dog notices a nearby touch without sliding")
		game.set_reduce_motion(true,false)
		dog._process(0.05)
		check(is_zero_approx(dog.sprite.rotation),"Reduce Motion keeps attention gestures still")
		game.set_reduce_motion(false,false)
		dog.attention_time=0
		dog.begin_expression("Greet",1)
		dog._process(0.4)
		var previous_height=dog.sprite.get_rect().size.y*dog.sprite.scale.y
		dog.react_to_care("Feed")
		dog.reaction_time=dog.reaction_duration-1.0
		dog._process(1.0/60)
		var rendered_height=dog.sprite.get_rect().size.y*dog.sprite.scale.y
		check(rendered_height>dog.visible_size.y*dog.base_scale and rendered_height<previous_height,"Pose changes ease through their displayed size instead of snapping")
		game.resting = true
		dog.expression_time = 0
		dog.welcome_player(7200)
		check(dog.expression_time==0,"A resting dog is allowed to sleep through a return")
		game.resting = false
		dog.controlled = true
		dog.fetch_running = true
		for dressed in [false,true]:
			game.life.accessory = "CoralBandana" if dressed else ""
			game.items.CoralBandana = 1 if dressed else 0
			for angle in ["toward","away"]:
				for phase in 4:
					dog.stride_distance = (phase+0.1)/4.0*dog.stride_length()
					dog.set_run_pose(angle)
					var box: Rect2 = dog.sprite.region_rect
					check(box.has_area() and box.position.x>=0 and box.end.x<=dog.sprite.texture.get_width() and box.end.y<=dog.sprite.texture.get_height(),"Run frames stay within their atlas")
					check(is_zero_approx(dog.sprite.offset.y+box.size.y*0.5),"Run paws stay grounded")
					check(dog.outfit_equipped()==dressed,"Run poses preserve the purchased accessory state")
		dog.queue_free()
	await process_frame
	game.life = IslandLife.fresh()
	game.breed = "Puppy"
	game.home_greeted = true
	game.active_outing = {}
	game.saved_outings = {}
	game.needs = {"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game.record_return(7200)
	game.set_process(true)
	main._process(0)
	check(game.home_greeted and game.welcome_away_seconds==0 and main.habitat.puppy.welcome_hops==3,"Returning to an open Home screen consumes one welcome")
	main.habitat.puppy.expression_time = 0.8
	main._process(0)
	check(main.habitat.puppy.expression_time==0.8,"The welcome does not restart every frame")
	game.set_process(false)
	main.start_activity("Fetch")
	await process_frame
	var fetch = main.body.get_child(0)
	fetch.set_process(false)
	var dog = main.habitat.puppy
	dog.set_process(false)
	var previous_landing = Vector2(INF,INF)
	for round in 3:
		fetch.bar.value = fetch.profile.center
		fetch._throw()
		fetch.timer.stop()
		check(fetch.landing!=previous_landing,"Each throw uses a different landing area")
		previous_landing = fetch.landing
		var views = {}
		for frame in 180:
			fetch._process(1.0/60)
			dog._process(1.0/60)
			views[dog.run_view] = true
			check(WalkArea.walkable(dog.walk_area,dog.active_barriers(),dog.position),"Fetch follows safe ground")
		check(dog.position.distance_to(fetch.landing)<2,"The dog reaches the ball before turning back")
		check(views.size()>1,"Fetch uses several viewing angles within a run")
		fetch.timer.timeout.emit()
		fetch.timer.stop()
		for frame in 150:
			fetch._process(1.0/60)
			dog._process(1.0/60)
		check(dog.position.distance_to(WalkArea.SPAWNS.Park)<2,"The dog returns to the player before a throw ends")
		fetch.timer.timeout.emit()
		check(not fetch.busy and not main.habitat.ball.visible and not dog.fetch_running,"A throw settles cleanly")
	check(fetch.complete and fetch.rounds==3,"Varied Fetch still completes and saves all three throws")
	check(game.life.memories.has("first_catch"),"An actual good catch leaves a lasting Journal memory")
	main.queue_free()
	await process_frame
	print("Dog animation checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
