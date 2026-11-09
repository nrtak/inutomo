extends SceneTree
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func check_feeding(game: Node) -> void:
	for breed in GrowthRoutes.BREEDS:
		game.breed = breed
		for growth in [0.0,1.0] if breed == "Puppy" else [1.0]:
			game.points = int(game.EVOLUTION_POINTS*growth)
			game.active_seconds = game.EVOLUTION_SECONDS*growth
			for bowl_spot in 3:
				game.life.bowl_spot = bowl_spot
				for bed_spot in [-1,0,1,2]:
					game.life.bed = "Bed" if bed_spot>=0 else ""
					game.life.spot = maxi(0,bed_spot)
					game.items.Bed = 1 if bed_spot>=0 else 0
					var room = load("res://scenes/home.tscn").instantiate()
					room.size = Vector2(1558,720)
					root.add_child(room)
					var dog = room.puppy
					dog.set_process(false)
					dog.react_to_care("Feed")
					for frame in 1800:
						dog._process(1.0/60)
						if dog.pending_decor_action.is_empty(): break
					var context = breed+" bowl "+str(bowl_spot)+" bed "+str(bed_spot)+" growth "+str(growth)
					check(dog.pending_decor_action.is_empty() and dog.reaction_kind=="Feed","Feeding reaches the side of every bowl, including around beds: "+context+" at "+str(dog.position)+" target "+str(dog.target)+" route "+str(dog.route_points))
					var bowl = room.decor_sprites.Feed
					check(dog.reaction_icon.texture.resource_path.ends_with("heart.svg") and dog.reaction_icon.position.y < -100,"Feeding shows affection above the dog instead of a second bowl under its paws")
					for asleep in [false,true]:
						dog.set_pose(asleep)
						var dog_bounds: Rect2 = dog.sprite.get_global_transform()*dog.sprite.get_rect()
						var meal_bounds: Rect2 = bowl.get_global_transform()*bowl.get_rect()
						check(dog_bounds.has_area() and meal_bounds.has_area(),"Feeding checks measure the visible sprites at phone size")
						check(not dog_bounds.intersects(meal_bounds),"Sitting or sleeping after feeding never covers the bowl: "+context)
					check(not IslandLife.bowl_barrier(game).has_point(dog.position),"Feeding ends outside the bowl footprint")
					check(not WalkArea.walkable(dog.walk_area,dog.active_barriers(),bowl.position),"Autonomous walking cannot target the placed bowl")
					room.queue_free()
					await process_frame
	game.life = IslandLife.fresh()
	game.items.Bed = 0
	game.points = 0
	game.active_seconds = 0
	game.breed = "Puppy"

func run() -> void:
	var game = root.get_node("Game")
	game.set_process(false)
	game.life = IslandLife.fresh()
	game.health = PuppyHealth.fresh()
	game.resting = false
	game.paused_at = 0
	game.points = 0
	game.active_seconds = 0
	game.needs.Energy = 95
	await check_feeding(game)
	var floor = PackedVector2Array([Vector2(350,490),Vector2(950,490),Vector2(950,650),Vector2(350,650)])
	var barriers: Array[Rect2] = [Rect2(580,490,120,90)]
	var start = Vector2(480,530)
	var finish = Vector2(800,530)
	var route = WalkArea.route(floor,barriers,start,finish)
	check(route.size()>1,"Routes go around a bed instead of passing straight through it")
	var previous = start
	for point in route:
		check(WalkArea.walkable(floor,barriers,point),"Every route corner has paw clearance")
		check(WalkArea.clear_segment(previous,point,barriers),"Every leg avoids the furniture footprint")
		previous = point
	var clipped = WalkArea.destination(floor,barriers,Vector2(630,530))
	check(WalkArea.walkable(floor,barriers,clipped),"Tapping furniture chooses the closest reachable edge")
	game.breed = "Puppy"
	var waking = load("res://scripts/puppy.gd").new()
	root.add_child(waking)
	waking.set_process(false)
	waking.controlled = true
	waking.walk_area = floor
	waking.barriers = barriers.duplicate()
	waking.position = Vector2(640,530)
	waking.target = finish
	for frame in 600: waking._process(1.0/60)
	check(waking.position.distance_to(finish)<=1,"A dog starting on furniture can step off instead of becoming trapped")
	waking.queue_free()
	await process_frame
	for breed in GrowthRoutes.BREEDS:
		game.breed = breed
		for fps in [30,60,120]:
			var dog = load("res://scripts/puppy.gd").new()
			root.add_child(dog)
			dog.set_process(false)
			dog.controlled = true
			dog.walk_area = floor
			dog.barriers = barriers.duplicate()
			dog.position = start
			dog.target = finish
			for frame in fps*8:
				var old = dog.position
				dog._process(1.0/fps)
				check(WalkArea.walkable(floor,barriers,dog.position) and WalkArea.clear_segment(old,dog.position,barriers),"Smoothed motion never cuts a furniture corner")
				check(old.distance_to(dog.position)<=150.0/fps+0.36,"A motion step never jumps across the floor")
			check(dog.position.distance_to(finish)<=1,"A detour reaches its destination at every supported frame rate")
			var stopped_phase: float = dog.stride_distance
			dog._process(0.1)
			check(dog.stride_distance==stopped_phase,"Stopping holds the planted paw phase instead of snapping to frame zero")
			dog.target = start
			for frame in fps*8: dog._process(1.0/fps)
			check(dog.position.distance_to(start)<=1,"Furniture detours work in both directions")
			dog.queue_free()
			await process_frame
	check(WalkArea.contains(WalkArea.AREAS.Home,Vector2(660,610)),"The clear foreground rug is available for natural Home movement")
	game.items.Bed = 1
	game.life.bed = "Bed"
	var home = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	var bed = home.decor_sprites.Rest
	var bed_bounds: Rect2 = bed.get_transform()*bed.get_rect()
	check(home.puppy.bed_barrier.encloses(bed_bounds),"The bed barrier covers the actual drawn bed with clearance on every edge")
	home.queue_free()
	await process_frame
	check(not WalkArea.contains(WalkArea.AREAS.Beach,Vector2(420,525)),"The coastal path keeps paws away from the rail footing")
	var map = load("res://scripts/island_map.gd")
	for link in map.PATH_LINKS:
		var a: Vector2 = map.FOOT_POINTS[link[0]]
		var b: Vector2 = map.FOOT_POINTS[link[1]]
		for i in 31:
			var point = a.lerp(b,float(i)/30)
			var fountain_distance = Vector2((point.x-0.51)/0.07,(point.y-0.445)/0.043).length()
			check(fountain_distance>1,"Map routes follow the plaza ring rather than crossing the fountain")
	check(map.FOOT_POINTS.Harbor.x<0.4 and map.FOOT_POINTS.Harbor.y>0.76,"The Harbor marker stands on the wooden pier")
	print("Navigation and smooth motion checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
