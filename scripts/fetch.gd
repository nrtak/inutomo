extends VBoxContainer

signal finished
var return_place = "Park"
var habitat: Habitat
var bar: ProgressBar
var progress: Label
var status: CommandHint
var throw_button: Button
var phase = 0.0
var busy = false
var rounds = 0
var score = 0
var complete = false
var timer: Timer
var profile: Dictionary
var run_points: Array[Vector2] = []
var leg = ""
var leg_clock = 0.0
var landing = Vector2.ZERO
var launch = Vector2.ZERO
var catch_shown = false
var good_throw = false
var outing_variant = 0
var sweet_zone: ColorRect
var companion: Sprite2D
var companion_name = ""
var companion_stride = 0.0
var companion_route: Array[Vector2] = []
var companion_goal=Vector2(INF,INF)

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	if habitat == null:
		habitat = preload("res://scenes/home.tscn").instantiate()
		habitat.location = "Park"
		add_child(habitat)
	habitat.puppy.controlled = true
	habitat.puppy.position = WalkArea.SPAWNS.Park
	habitat.puppy.target = habitat.puppy.position
	var checkpoint = Game.begin_outing("Fetch")
	outing_variant=int(checkpoint.get("variant",0))
	profile = IslandConnections.fetch_profile(Game,int(checkpoint.get("variant",0)))
	if outing_variant==2: profile.title="A wandering toss"
	var visitor=Game.life.surprises
	if visitor.kind=="Visit" and visitor.accepted and visitor.route=="Fetch": companion_name=visitor.buddy
	elif outing_variant==2:
		var buddy=IslandAdventure.companion(Game)
		if int(Game.life.adventure.buddies.get(buddy,{}).get("visits",0))>0: companion_name=buddy
	if not companion_name.is_empty():
		companion=Sprite2D.new()
		companion.texture=Art.PUPPIES[IslandAdventure.BUDDIES[companion_name].breed]
		companion.material=UI.art_cutout()
		companion.position=WalkArea.destination(habitat.puppy.walk_area,habitat.puppy.active_barriers(),habitat.puppy.position+Vector2(-180,-65))
		habitat.world.add_child(companion)
		habitat.world.move_child(companion,habitat.puppy.get_index())
		update_companion(0)
	rounds = int(checkpoint.checkpoint)
	score = int(checkpoint.score)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)
	var panel = UI.card()
	panel.custom_minimum_size.x = 430
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(panel)
	var controls = UI.column(8)
	panel.add_child(controls)
	progress = UI.label("Throw 1 of 3", 24, UI.TEAL)
	controls.add_child(progress)
	status = UI.hint_label(throw_hint(), 24)
	controls.add_child(status)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 32
	bar.show_percentage = true
	bar.add_theme_stylebox_override("fill", UI.style(UI.PINK, 12))
	controls.add_child(bar)
	sweet_zone = ColorRect.new()
	sweet_zone.color = Color(0.3, 0.8, 0.4, 0.35)
	sweet_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweet_zone.anchor_left = (profile.center-profile.radius)/100.0
	sweet_zone.anchor_right = (profile.center+profile.radius)/100.0
	sweet_zone.anchor_bottom = 1
	bar.add_child(sweet_zone)
	progress.text = "Throw %d of 3" % mini(3, rounds + 1)
	throw_button = UI.icon_button("Throw the ball", preload("res://assets/manga/ui/play.svg"), _throw, Color("c8eddd"))
	controls.add_child(throw_button)
	if rounds >= 3:
		call_deferred("finish_fetch")

func _process(delta: float) -> void:
	if Game.paused_at > 0:
		return
	if not busy and not complete:
		phase += delta * profile.speed
		bar.value = (sin(phase) + 1) * 50
		sweet_zone.anchor_left=clampf((target_center()-profile.radius)/100.0,0,1)
		sweet_zone.anchor_right=clampf((target_center()+profile.radius)/100.0,0,1)
	update_companion(delta)
	if busy:
		leg_clock += delta
		if not run_points.is_empty() and habitat.puppy.position.distance_to(habitat.puppy.target)<9:
			habitat.puppy.target = run_points.pop_front()
		if leg=="out":
			var flight = clampf(leg_clock/0.65,0,1)
			habitat.ball.position = landing if Game.reduce_motion else launch.lerp(landing,flight)+Vector2(0,-sin(flight*PI)*65)
			habitat.ball.rotation = 0 if Game.reduce_motion else leg_clock*5
			if not catch_shown and run_points.is_empty() and habitat.puppy.position.distance_to(landing)<4:
				catch_shown=true
				if good_throw:
					habitat.puppy.celebrate_success()
					if IslandMemories.unlock(Game,"first_catch"): Game.save_game()
					status.text="Lovely catch! Coming back to you."
				else: Sound.play_effect("play",-27)
		elif leg=="return":
			var dog = habitat.puppy
			var height = dog.awake_height()
			habitat.ball.position = dog.position+Vector2((-1 if dog.sprite.flip_h else 1)*height*0.20,-height*0.52)
			habitat.ball.rotation = 0

func running_path(start: Vector2, finish: Vector2, returning: bool = false) -> Array[Vector2]:
	# Rotate broad arcs through open ground, rather than repeating one flat line.
	var pattern = posmod(int(Game.active_outing.get("variant",0))+rounds+(1 if returning else 0),3)
	var bend = [Vector2(0,-85),Vector2(0,85),Vector2(25,-50)][pattern]
	var control = WalkArea.destination(habitat.puppy.walk_area,habitat.puppy.active_barriers(),(start+finish)*0.5+bend)
	var result: Array[Vector2] = []
	for t in [0.33,0.66,1.0]:
		var point: Vector2 = start.lerp(control,t).lerp(control.lerp(finish,t),t)
		result.append(WalkArea.destination(habitat.puppy.walk_area,habitat.puppy.active_barriers(),point))
	return result

func target_center() -> float:
	return profile.center+(sin(phase*.35)*8.0 if outing_variant==2 and not Game.reduce_motion else 0.0)

func update_companion(delta: float) -> void:
	if not is_instance_valid(companion): return
	var breed: String=IslandAdventure.BUDDIES[companion_name].breed
	var offset=Vector2(180 if habitat.puppy.motion_velocity.x<0 else -180,-65)
	var obstacles=habitat.puppy.active_barriers()
	var goal=WalkArea.destination(habitat.puppy.walk_area,obstacles,habitat.puppy.position+offset)
	if companion_goal.distance_to(goal)>12 or companion_route.is_empty():
		companion_route=WalkArea.route(habitat.puppy.walk_area,obstacles,companion.position,goal)
		companion_goal=goal
	var previous=companion.position
	var remaining=210*delta
	while remaining>0 and not companion_route.is_empty():
		var next=companion.position.move_toward(companion_route[0],remaining)
		if not WalkArea.clear_segment(companion.position,next,obstacles,true):
			companion_route.clear()
			break
		remaining-=companion.position.distance_to(next)
		companion.position=next
		if companion.position.distance_to(companion_route[0])<.1: companion_route.pop_front()
		else: break
	var travelled=previous.distance_to(companion.position)
	if travelled>0.01:
		companion_stride+=travelled
		companion.flip_h=companion.position.x<previous.x
		var data: Dictionary=Art.WALK_DATA[breed]
		var frame=int(fmod(companion_stride/100.0,1.0)*8)
		var box: Array=data.regions[frame]
		companion.texture=Art.WALKS[breed]
		companion.region_enabled=true
		companion.region_rect=Rect2(box[0],box[1],box[2],box[3])
		companion.offset=Vector2((box[2]*.5-data.anchors[frame])*(-1 if companion.flip_h else 1),-box[3]*.5)
		companion.scale=Vector2.ONE*(150.0/data.height)
	else:
		companion.texture=Art.PUPPIES[breed]
		companion.region_enabled=false
		companion.offset=Vector2(0,-companion.texture.get_height()*.5)
		companion.scale=Vector2.ONE*(150.0/companion.texture.get_height())

func start_run(finish: Vector2, returning: bool = false) -> void:
	run_points = running_path(habitat.puppy.position,finish,returning)
	habitat.puppy.fetch_running = true
	habitat.puppy.target = run_points.pop_front()
	leg = "return" if returning else "out"
	leg_clock = 0.0
	habitat.puppy.expression_time=0

func _throw() -> void:
	if busy or complete:
		return
	busy = true
	throw_button.disabled = true
	var good = absf(bar.value - target_center()) <= profile.radius
	good_throw=good
	catch_shown=false
	if good:
		score += 1
	rounds += 1
	progress.text = "Bringing back throw %d of 3" % rounds
	status.text = Game.personalize("Great throw! Go, Mochi!" if good else "A little wobbly, but Mochi is on it!")
	habitat.ball.visible = true
	var pattern = posmod(int(Game.active_outing.get("variant",0))+rounds,3)
	landing = WalkArea.destination(habitat.puppy.walk_area,habitat.puppy.active_barriers(),Vector2(620+bar.value*1.4,[520.0,610.0,550.0][pattern]))
	launch = habitat.puppy.position+Vector2(0,-85)
	habitat.ball.position = landing if Game.reduce_motion else launch
	start_run(landing)
	timer.start(3.0)
	await timer.timeout
	if not is_inside_tree():
		return
	start_run(WalkArea.SPAWNS.Park,true)
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	Game.checkpoint_outing(rounds, score)
	leg = ""
	run_points.clear()
	habitat.ball.visible = false
	habitat.puppy.fetch_running = false
	habitat.puppy.target = WalkArea.SPAWNS.Park
	if rounds >= 3:
		finish_fetch()
	else:
		progress.text = "Throw %d of 3" % (rounds + 1)
		status.text = throw_hint()
	busy = false
	throw_button.disabled = false

func finish_fetch() -> void:
	if complete:
		return
	complete = true
	bar.visible = false
	var before = {"coins":Game.coins,"happiness":Game.needs.Happiness,"points":Game.points}
	var rewarded = Game.complete_outing("Fetch", score)
	progress.text = "Fetch complete! %d of 3 great throws" % score
	status.text = Game.outing_result(before) if rewarded else "Progress saved. No additional reward was issued."
	if rewarded and not companion_name.is_empty():
		var visitor=Game.life.surprises
		if visitor.kind=="Visit" and visitor.accepted and visitor.route=="Fetch":
			var visit=IslandSurprises.finish_visit(Game,"Fetch")
			if visit.ok: status.text+="\n"+visit.text
		else:
			IslandSurprises.record_playmate(Game,companion_name,"Fetch")
			Game.remember("Played Fetch alongside "+companion_name+".")
			Game.save_game()
	UI.button_caption(throw_button, "Back to "+return_place)
	throw_button.get_meta("picture").texture = UI.place_icon(return_place)
	throw_button.pressed.disconnect(_throw)
	throw_button.pressed.connect(func(): finished.emit())

func _notification(what: int) -> void:
	if not is_instance_valid(timer):
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		timer.paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		timer.paused = get_meta("dialog_paused", false)

func throw_hint() -> String:
	return (companion_name+" plays alongside you. " if not companion_name.is_empty() else "")+profile.title+". Tap in the green zone near %d%% power." % int(profile.center)
