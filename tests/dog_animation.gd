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
		dog.home_interactions = true
		dog.position=Vector2(860,600)
		dog.target=dog.position
		var original_name=game.puppy_name
		for i in 100:
			game.puppy_name="Pup"+str(i)
			if IslandLife.personality(game)=="Cuddly": break
		dog.react_to_care("Care")
		dog._process(2.55)
		check(dog.cuddly_settle() and dog.sprite.texture==Art.SLEEP_TEXTURES[breed] and not dog.action_item.visible and not game.resting,"A cuddly dog settles after the brush without starting a nap")
		dog.react_to_care("Pet")
		check(not dog.cuddly_settle(),"A new touch immediately interrupts the post-brush habit")
		dog.reaction_time=0
		dog.position=Vector2(650,600)
		dog.target=dog.position
		game.puppy_name=original_name
		for dressed in [false,true]:
			game.life.accessory = "CoralBandana" if dressed else ""
			game.items.CoralBandana = 1 if dressed else 0
			dog.welcome_player(7200)
			check(dog.welcome_hops==3 and dog.expression_kind=="Greet" and not dog.napping,breed+" wakes for an enthusiastic return greeting")
			var poses: Array = Art.RUN_DATA[breed]["dressed" if dressed else "bare"].toward.regions
			var deltas = [0.24,0.15,0.15,0.2]
			for i in deltas.size():
				dog._process(deltas[i])
				var rect: Array = poses[i]
				check(dog.sprite.texture==Art.run_sheet(breed) and dog.sprite.region_enabled and dog.sprite.region_rect==Rect2(rect[0],rect[1],rect[2],rect[3]),breed+" greets with the matching drawn leg pose "+str(i))
				check((dog.sprite.position.y<0) == (i in [1,2]),breed+" leaves the ground after push-off and lands on its paws")
				check(dog.position.y+dog.sprite.position.y-dog.sprite.get_rect().size.y*dog.sprite.scale.y>=dog.home_headroom-0.01,breed+" stays below the Home controls during the greeting")
		game.set_reduce_motion(true,false)
		dog._process(0.1)
		check(dog.sprite.position==Vector2.ZERO and dog.sprite.rotation==0 and not dog.sprite.region_enabled,"Reduce Motion keeps the stationary greeting")
		game.set_reduce_motion(false,false)
		dog.home_interactions = false
		game.life.accessory = ""
		game.items.CoralBandana = 0
		dog.react_to_care("Feed")
		dog._process(0.15)
		check(dog.reaction_kind=="Feed" and dog.sprite.position==Vector2.ZERO and dog.sprite.texture==MomentArt.dog(breed,"Greet"),breed+" perks up with paws on the floor")
		var anticipation = dog.sprite.texture
		dog._process(0.8)
		check(dog.sprite.texture!=anticipation and dog.sprite.texture==MomentArt.dog(breed,"Sniff"),breed+" lowers its head to eat")
		check(dog.visible_size.y*dog.base_scale<=dog.awake_height(),"Head-down eating never enlarges the dog")
		for elapsed in [1.175,1.7,2.225,2.95]:
			dog.reaction_time=dog.reaction_duration-elapsed
			dog.show_meal_reaction()
			if elapsed==2.95: check(dog.sprite.texture==MomentArt.dog(breed,"Tilt"),"The dog looks back up after eating")
			elif elapsed==1.7: check(is_equal_approx(dog.sprite.scale.y,dog.base_scale),"The dog lifts its muzzle between bites")
			else: check(dog.sprite.scale.y<dog.base_scale*.97 and dog.sprite.position.y==0,"Each bite dips toward the bowl with grounded paws")
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
		dog.react_to_care("Pet")
		dog.notice_point(dog.position-Vector2(100,0))
		dog._process(0.88)
		check(dog.sprite.flip_h and dog.sprite.rotation<0 and dog.sprite.material==dog.pet_material and dog.pet_material.get_shader_parameter("blink")>0.99,"Petting gives a slow blink and leans toward the player's hand")
		dog.react_to_care("Play")
		dog._process(0.12)
		check(dog.sprite.texture==MomentArt.dog(breed,"Stretch") and dog.sprite.position==Vector2.ZERO,"Play starts with a planted, front-paws-down bow")
		dog.reaction_time=0
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
	game.pending_stage = "Growing puppy"
	main._process(0)
	check(main.habitat.puppy.expression_time==0.8,"The welcome does not restart every frame")
	check(not is_instance_valid(main.stage_overlay) and game.is_processing(),"Growth leaves the hello visible and care available")
	main.habitat.puppy._process(0.81)
	main._process(0)
	check(is_instance_valid(main.stage_overlay),"Growth follows the finished hello")
	main.stage_overlay.next_button.pressed.emit()
	main.close_growth_moment()
	game.record_return(7200)
	game.pending_stage = "Adult"
	main._process(0)
	game.needs.Cleanliness = 50
	game.items.Brush = 0
	game.action("Care")
	main._process(0)
	check(main.habitat.puppy.reaction_kind=="Care" and not is_instance_valid(main.stage_overlay),"Care can interrupt the hello before a pending celebration")
	main.habitat.puppy._process(3.1)
	main._process(0)
	check(is_instance_valid(main.stage_overlay),"The pending celebration survives a care interruption")
	main.stage_overlay.next_button.pressed.emit()
	main.close_growth_moment()
	game.set_process(false)
	main.start_activity("Fetch")
	await process_frame
	var fetch = main.body.get_child(0)
	fetch.set_process(false)
	var dog = main.habitat.puppy
	dog.set_process(false)
	var previous_landing = Vector2(INF,INF)
	for round in 3:
		game.set_reduce_motion(round==1,false)
		fetch.bar.value = fetch.profile.center
		fetch._throw()
		check(fetch.landing!=previous_landing,"Each throw uses a different landing area")
		previous_landing = fetch.landing
		var views = {}
		fetch._process(6.0)
		check(fetch.leg=="out" and fetch.busy,"Time alone cannot collect the ball")
		var legs = {}
		for frame in 600:
			if not fetch.busy: break
			fetch._process(1.0/60)
			dog._process(1.0/60)
			views[dog.run_view] = true
			legs[fetch.leg]=true
			if fetch.leg=="pickup": check(dog.fetch_mouth_down and dog.position.distance_to(fetch.pickup_spot)<2,"The dog lowers its muzzle on reaching the ball")
			if fetch.leg=="drop": check(dog.position.distance_to(WalkArea.SPAWNS.Park)<2 and fetch.throw_button.disabled,"The next throw waits for the handoff")
			check(WalkArea.walkable(dog.walk_area,dog.active_barriers(),dog.position),"Fetch follows safe ground")
		check(views.size()>1,"Fetch uses several viewing angles within a run")
		check(dog.position.distance_to(WalkArea.SPAWNS.Park)<2,"The dog returns to the player before a throw ends")
		check(legs.has("pickup") and legs.has("return") and legs.has("drop"),"Every throw has a pickup, carry, and handoff")
		check(not fetch.busy and main.habitat.ball.visible and main.habitat.ball.position.is_equal_approx(fetch.drop_spot) and not dog.fetch_running,"The dropped ball rests at the player's feet")
	check(fetch.complete and fetch.rounds==3,"Varied Fetch still completes and saves all three throws")
	check(game.life.memories.has("first_catch"),"An actual good catch leaves a lasting Journal memory")
	main.queue_free()
	await process_frame
	print("Dog animation checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
