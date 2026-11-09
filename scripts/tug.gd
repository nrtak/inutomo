extends Control

var host: Control
var panel: PanelContainer
var hint: CommandHint
var meter: ProgressBar
var pull_button: Button
var rope: Sprite2D
var holding = false
var tension = 0.0
var held_time = 0.0
var rounds = 0
var rewarded = false
var suspended = false
var drag_start = Vector2.ZERO
var drag_strength = 0.0
var button_pull = false
var goal = "pull"
var dog_origin = Vector2(650,610)
var rope_origin = Vector2.ZERO

func _ready() -> void:
	name = "TugGame"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var habitat = host.habitat
	habitat.cinematic = true
	habitat._resize_world()
	for item in habitat.decor_sprites.values(): item.visible = false
	habitat.moment_input = handle_input
	var dog = habitat.puppy
	dog.home_interactions = false
	dog.controlled = true
	dog.position = dog_origin
	dog.target = dog.position
	dog.illustrated_pose = "Tug"
	dog.illustrated_width = 330
	dog.illustrated_height = 300
	dog._process(0)
	rope = Sprite2D.new()
	rope.texture = Goods.picture("TugRope")
	rope.material = UI.art_cutout()
	rope.scale = Vector2.ONE*(150.0/rope.texture.get_width())
	var pose_size = dog.sprite.texture.get_size()
	var mouth = Art.tug_mouth(Game.breed,dog.outfit_equipped())
	rope_origin = dog_origin+(mouth-Vector2(pose_size.x*0.5,pose_size.y))*dog.sprite.scale+Vector2(25,8)
	rope.position = rope_origin
	habitat.world.add_child(rope)
	panel = UI.card()
	add_child(panel)
	var content = UI.column(12)
	panel.add_child(content)
	content.add_child(UI.label("A gentle game of tug",26,UI.TEAL))
	hint = UI.hint_label("Pull gently into the green band. Hold steady, then let go when asked.",22)
	content.add_child(hint)
	var bar = Control.new()
	bar.custom_minimum_size.y = 28
	content.add_child(bar)
	meter = ProgressBar.new()
	meter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meter.show_percentage = false
	bar.add_child(meter)
	var band = ColorRect.new()
	band.color = Color(0.2,0.65,0.35,0.3)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.anchor_left = 0.35
	band.anchor_right = 0.70
	bar.add_child(band)
	pull_button = UI.button("Hold to pull",func():pass,Color("c8eddd"))
	pull_button.button_down.connect(func(): start_pull(Vector2.ZERO,true))
	pull_button.button_up.connect(release_pull)
	content.add_child(pull_button)
	var back = UI.button("Back to Home",host.request_page.bind("Home"),Color("fff0cf"))
	content.add_child(back)
	content.minimum_size_changed.connect(arrange)
	resized.connect(arrange)
	arrange.call_deferred()

func arrange() -> void:
	var safe = UI.safe_insets(20)
	panel.position = Vector2(size.x-safe.right-340,safe.top+100)
	panel.size = Vector2(340,0)
	hint.custom_minimum_size.x = 300
	panel.size.y = panel.get_combined_minimum_size().y
	var world = host.habitat.world
	if world.scale.x>0:
		dog_origin.x = minf(650,(panel.position.x-30-world.position.x)/world.scale.x-190)
		var dog = host.habitat.puppy
		dog.position = dog_origin+Vector2(-tension*12,0)
		dog.target = dog.position
		var pose_size = Art.expression_texture(Game.breed,"Tug",dog.outfit_equipped()).get_size()
		var mouth = Art.tug_mouth(Game.breed,dog.outfit_equipped())
		var factor = minf(330.0/pose_size.x,300.0/pose_size.y)
		rope_origin = dog_origin+(mouth-Vector2(pose_size.x*0.5,pose_size.y))*factor+Vector2(25,8)
		rope.position = rope_origin+Vector2(tension*25,0)

func blocked() -> bool:
	return Game.paused_at>0 or not Game.is_processing() or not Game.can_explore() or is_instance_valid(host.navigation_overlay) or is_instance_valid(host.resident_overlay) or is_instance_valid(host.photo_overlay)

func start_pull(point: Vector2, from_button: bool = false) -> void:
	if rewarded or rounds>=3 or blocked(): return
	holding = true
	button_pull = from_button
	drag_start = point
	drag_strength = 0

func release_pull() -> void:
	var can_score = holding and goal=="release" and not blocked()
	holding = false
	button_pull = false
	drag_strength = 0
	if not can_score and goal=="pull": held_time = 0
	if can_score:
		rounds += 1
		Sound.play_effect("happy",-25)
		held_time = 0
		goal = "pull"
		if rounds>=3:
			finish()
		else:
			hint.set_hint("Lovely! %d of 3 turns. Let the rope relax, then pull gently again." % rounds)
			goal = "rest"

func handle_input(event: InputEvent) -> bool:
	if blocked():
		cancel_pull()
		return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and rope.get_rect().grow(20/rope.scale.x).has_point(rope.to_local(host.habitat.get_global_transform()*event.position)):
			start_pull(event.position)
		elif not event.pressed: release_pull()
		return true
	if event is InputEventMouseMotion and holding and not button_pull:
		drag_strength = clampf(event.position.distance_to(drag_start)/maxf(1,host.habitat.world.scale.x)/160.0,0,1)
	return true

func cancel_pull() -> void:
	holding = false
	button_pull = false
	drag_strength = 0
	tension = 0
	held_time = 0
	goal = "pull"
	if is_instance_valid(meter): meter.value = 0
	if is_instance_valid(pull_button): pull_button.set_pressed_no_signal(false)

func _process(delta: float) -> void:
	if rewarded: return
	var stop = blocked()
	if stop:
		cancel_pull()
		suspended = true
		return
	if suspended:
		suspended = false
		hint.set_hint("Ready when you are. Pull gently for the next turn.")
	if rounds>=3:
		finish()
		return
	var target = 0.0 if goal=="rest" else (0.52 if holding and button_pull else (drag_strength if holding else 0.0))
	tension = move_toward(tension,target,delta*0.65)
	meter.value = tension*100
	if goal=="rest" and tension<0.15:
		goal = "pull"
	if goal=="pull" and holding:
		if tension>=0.35 and tension<=0.70:
			held_time += delta
			if held_time>=0.9:
				goal = "release"
				hint.set_hint("Let go! Give your dog a happy little win.")
		elif tension>0.70:
			held_time = 0
			hint.set_hint("Softer paws. Ease back into the green band.")
		else:
			held_time = 0
	var dog = host.habitat.puppy
	dog.position = dog_origin+Vector2(-tension*12,0)
	dog.target = dog.position
	rope.position = rope_origin+Vector2(tension*25,0)

func finish() -> void:
	if rewarded or rounds<3 or blocked(): return
	# Claim once. The normal Play cooldown and care limits apply to this game too.
	if Game.cooldowns.get("Play",0)>0:
		hint.set_hint("A little breather first. Your tug turns are ready.")
		pull_button.disabled = true
		return
	rewarded = true
	GrowthRoutes.record(Game,"Tug")
	Game.life.tug_games = mini(100000,Game.life.tug_games+1)
	Game.action("Play")
	Game.remember("Shared a gentle tug game and let those happy paws win.")
	Game.save_game()
	host.habitat.puppy.illustrated_pose = "Greet"
	rope.visible = false
	hint.set_hint("Three lovely turns! A happy game together.")
	pull_button.disabled = true

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_pull()
