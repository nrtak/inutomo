extends Control

var host: Control
var event_id = "Run"
var spec: Dictionary
var state: Dictionary
var phase = "ready"
var elapsed = 0.0
var race_progress = 0.0
var cheered = false
var good_cheer = false
var expected_step = 0
var narration: CommandHint
var step_label: Label
var action_button: Button
var meter: ProgressBar
var choices: HBoxContainer
var speaker_card: PanelContainer
var footer: PanelContainer
var targets: Array[Button] = []
var buddies: Array[Sprite2D] = []
var buddy_distance = 0.0
var race_start = Vector2(390,575)
var race_finish = Vector2(820,575)
var destination = Vector2.ZERO
var result_text = ""
var player_finish = 0.0
var picnic_props: Array[Sprite2D] = []

func _ready() -> void:
	name="IslandFestivalView"
	set_meta("screen_layout_manual",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	spec=IslandFestivals.EVENTS[event_id]
	state=IslandFestivals.begin(Game,event_id)
	var dog=host.habitat.puppy
	dog.controlled=Game.can_explore()
	if Game.can_explore(): dog.wake_briefly()
	dog.expression_time=0
	if event_id=="Shells":
		host.habitat.use_scenery(BeachStyle.BACKGROUND,"Beach Arrival")
		dog.walk_area=WalkArea.AREAS.Park
		dog.barriers.clear()
	dog.position=WalkArea.destination(dog.walk_area,dog.active_barriers(),Vector2(640,600))
	dog.target=dog.position
	if event_id=="Picnic":
		var blanket=Sprite2D.new()
		blanket.texture=preload("res://assets/manga/goods/festival_blanket.svg")
		blanket.position=Vector2(640,610)
		host.habitat.world.add_child(blanket)
		host.habitat.world.move_child(blanket,1)
		var textures=[preload("res://assets/manga/goods/picnic_cel.svg"),preload("res://assets/manga/ui/water_bowl.svg"),Goods.picture("Toy")]
		for i in 3:
			var prop=Sprite2D.new()
			prop.texture=textures[i]
			prop.position=Vector2(470+i*165,620)
			prop.scale=Vector2.ONE*(68.0/prop.texture.get_width())
			host.habitat.world.add_child(prop)
			picnic_props.append(prop)
	speaker_card=UI.card()
	add_child(speaker_card)
	var speech=UI.column(6)
	speaker_card.add_child(speech)
	var neighbors=HBoxContainer.new()
	neighbors.add_theme_constant_override("separation",12)
	speech.add_child(neighbors)
	for person in spec.neighbors:
		var picture=TextureRect.new()
		picture.texture=UI.resident_icon(IslandFestivals.PORTRAITS[person])
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size=Vector2(72,76)
		picture.material=UI.art_cutout()
		neighbors.add_child(picture)
	var names=UI.label(" & ".join(spec.neighbors),22,UI.TEAL)
	names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	neighbors.add_child(names)
	narration=UI.hint_label(spec.intro,22)
	speech.add_child(narration)
	footer=UI.card()
	add_child(footer)
	var column=UI.column(8)
	footer.add_child(column)
	step_label=UI.label("",24,UI.TEAL)
	column.add_child(step_label)
	meter=ProgressBar.new()
	meter.custom_minimum_size.y=24
	meter.show_percentage=false
	meter.add_theme_stylebox_override("fill",UI.style(Color("9ebca1"),8))
	column.add_child(meter)
	var zone=ColorRect.new()
	zone.color=Color(.25,.65,.38,.32)
	zone.mouse_filter=Control.MOUSE_FILTER_IGNORE
	zone.anchor_left=.35
	zone.anchor_right=.75
	zone.anchor_bottom=1
	meter.add_child(zone)
	choices=HBoxContainer.new()
	choices.add_theme_constant_override("separation",10)
	column.add_child(choices)
	action_button=UI.button("",press_action,Color("c8eddd"))
	action_button.clip_text=true
	action_button.custom_minimum_size.y=62
	column.add_child(action_button)
	if event_id in ["Run","Picnic","Tricks"]:
		for breed in ["Shiba Inu","Golden Retriever"]:
			var buddy=Sprite2D.new()
			buddy.texture=Art.PUPPIES[breed]
			buddy.material=UI.art_cutout()
			buddy.set_meta("breed",breed)
			buddy.offset.y=-buddy.texture.get_height()*0.5
			buddy.scale=Vector2.ONE*(145.0/buddy.texture.get_height())
			host.habitat.world.add_child(buddy)
			buddies.append(buddy)
	if event_id in ["Shells","Lanterns"]:
		for i in 3:
			var button=UI.button("",choose_prop.bind(i),Color("fff6e4"))
			button.icon=preload("res://assets/manga/ui/lantern.svg") if event_id=="Lanterns" else [preload("res://assets/manga/ui/festival_shell_pink.svg"),preload("res://assets/manga/ui/beach_shell.svg"),preload("res://assets/manga/ui/festival_shell_spiral.svg")][i]
			button.expand_icon=true
			button.add_theme_constant_override("icon_max_width",68)
			button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
			for style in ["normal","hover","pressed","disabled","focus"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
			button.tooltip_text=("Lantern " if event_id=="Lanterns" else "Shell ")+str(i+1)
			button.custom_minimum_size=Vector2(80,84)
			add_child(button)
			targets.append(button)
	resized.connect(arrange)
	footer.minimum_size_changed.connect(func(): arrange.call_deferred())
	speaker_card.minimum_size_changed.connect(func(): arrange.call_deferred())
	refresh()
	arrange.call_deferred()

func refresh() -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	var done=state.step>=3
	phase="done" if done else "ready"
	expected_step=int(state.step)
	step_label.text="A day to remember" if done else "%d of 3 · %s" % [state.step+1,spec.steps[state.step]]
	meter.visible=event_id=="Run" and not done
	action_button.visible=event_id=="Run" or done
	action_button.text="Back to Festivals" if done else "Start this lap"
	action_button.disabled=false
	if done: narration.text=result_text if not result_text.is_empty() else "Thank you for joining us! Your reward and memory are saved. Come again another day."
	if not done and event_id in ["Picnic","Tricks"]:
		var labels=["Snacks","Water","Toy"] if event_id=="Picnic" else ["Sit","Paw","Bow"]
		var icons=[Goods.picture("Treat"),preload("res://assets/manga/ui/water_bowl.svg"),Goods.picture("Toy")] if event_id=="Picnic" else [preload("res://assets/manga/ui/training_treat.svg"),preload("res://assets/manga/ui/heart.svg"),preload("res://assets/manga/ui/club.svg")]
		for i in 3:
			var button=UI.picture_button(labels[i],icons[i],choose_prop.bind(i))
			button.add_theme_stylebox_override("normal",UI.style(Color("fff0bd") if i==state.step else Color("eee5d9")))
			button.custom_minimum_size=Vector2(110,105)
			button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			choices.add_child(button)
	for i in targets.size():
		targets[i].disabled=done or i<state.step
		targets[i].visible=event_id!="Shells" or i>=state.step
		targets[i].modulate=Color("f4d684") if i<state.step else Color.WHITE
	for buddy in buddies:
		buddy.texture=Art.PUPPIES[buddy.get_meta("breed")]
		buddy.region_enabled=false
		buddy.offset=Vector2(0,-buddy.texture.get_height()*.5)
		buddy.scale=Vector2.ONE*(145.0/buddy.texture.get_height())
	for i in picnic_props.size(): picnic_props[i].visible=i<state.step
	arrange.call_deferred()
	queue_redraw()

func prop_point(index: int) -> Vector2:
	var points=[Vector2(420,610),Vector2(640,625),Vector2(860,600)]
	return WalkArea.destination(host.habitat.puppy.walk_area,host.habitat.puppy.active_barriers(),points[index])

func arrange() -> void:
	if not is_instance_valid(footer): return
	var safe=UI.safe_insets(20)
	var portrait=size.y>size.x
	var dog=host.habitat.puppy
	dog.scale=Vector2.ONE*(minf(2.3,280.0/maxf(1,dog.awake_height()*host.habitat.world.scale.y)) if portrait else 1.0)
	dog.screen_width_limit=size.x*.42/maxf(.01,host.habitat.world.scale.y*dog.scale.x) if portrait else INF
	var width=minf(580,size.x-safe.left-safe.right) if portrait else minf(480,(size.x-safe.left-safe.right-28)*.5)
	speaker_card.size=Vector2(width,speaker_card.get_combined_minimum_size().y)
	speaker_card.position=Vector2(safe.left,safe.top+92)
	narration.custom_minimum_size.x=width-40
	footer.size=Vector2(width,footer.get_combined_minimum_size().y)
	footer.position=Vector2(safe.left if portrait else size.x-safe.right-width,size.y-safe.bottom-footer.size.y if portrait else safe.top+92)
	for i in targets.size():
		var point=host.habitat.world.to_global(prop_point(i))
		targets[i].size=Vector2(80,84)
		var lower=speaker_card.get_rect().end.y+10 if portrait else maxf(speaker_card.get_rect().end.y,footer.get_rect().end.y)+20
		var upper=footer.position.y-90 if portrait else size.y-safe.bottom-90
		targets[i].position=(point-Vector2(40,62)).clamp(Vector2(safe.left,lower),Vector2(size.x-safe.right-80,maxf(lower,upper)))
	for i in buddies.size():
		if phase!="racing": buddies[i].position=Vector2(340+i*600,600) if event_id!="Run" else Vector2(390,535+i*80)
		var height=buddies[i].region_rect.size.y if buddies[i].region_enabled else buddies[i].texture.get_height()
		buddies[i].scale=Vector2.ONE*(145.0/height)*(1.6 if portrait else 1.0)
	queue_redraw()

func choose_prop(index: int) -> void:
	if phase!="ready" or Game.paused_at>0 or get_meta("dialog_paused",false): return
	if not Game.can_explore():
		narration.text="Let's rest or visit Leah first. We can celebrate when you're ready."
		return
	if index!=state.step:
		narration.text="First, "+spec.steps[state.step].to_lower()+". There's no rush."
		return
	host.habitat.puppy.controlled=true
	expected_step=int(state.step)
	phase="approach"
	elapsed=0
	destination=prop_point(index)
	host.habitat.puppy.target=destination
	for button in targets: button.disabled=true
	for button in choices.get_children(): button.disabled=true
	if event_id in ["Picnic","Tricks"]: begin_performance()

func press_action() -> void:
	if phase=="done":
		host.request_page("Life:Events")
		return
	if Game.paused_at>0 or get_meta("dialog_paused",false) or not Game.can_explore():
		narration.text="A little rest first. Your place in the gathering will wait."
		return
	if phase=="racing":
		if cheered: return
		cheered=true
		good_cheer=meter.value>=35 and meter.value<=75
		host.habitat.puppy.activity_speed=210.0 if good_cheer else 145.0
		narration.text="A lovely cheer! Those little paws found a burst of confidence." if good_cheer else "Your dog hears you cheering. Keep going, little friend!"
		action_button.disabled=true
		Sound.play_effect("happy",-26)
		return
	if phase!="ready": return
	phase="racing"
	elapsed=0
	race_progress=0
	cheered=false
	good_cheer=false
	player_finish=0
	expected_step=int(state.step)
	var dog=host.habitat.puppy
	dog.controlled=true
	dog.position=race_start
	dog.motion_velocity=Vector2.ZERO
	dog.target=race_finish
	dog.fetch_running=true
	dog.activity_speed=135.0
	dog.expression_time=0
	narration.text="Cheer when the marker reaches the green zone! Every finish earns a welcome."
	action_button.text="Cheer for "+Game.puppy_name
	for i in buddies.size(): buddies[i].position=Vector2(390,535+i*80)

func begin_performance() -> void:
	phase="performing"
	elapsed=0
	var dog=host.habitat.puppy
	dog.target=dog.position
	if event_id=="Tricks":
		if state.step==0: dog.begin_expression("Tilt",1.1)
		else:
			dog.trick_command="Paw" if state.step==1 else "Bow"
			dog.trick_elapsed=1.0
	else: dog.begin_expression("Sniff" if event_id=="Shells" else "Greet",1.1)
	Sound.play_effect("discovery" if event_id=="Shells" else "happy",-27)

func finish_step() -> void:
	var result=IslandFestivals.advance(Game,event_id,expected_step,good_cheer if event_id=="Run" else true)
	var dog=host.habitat.puppy
	dog.fetch_running=false
	dog.activity_speed=0
	dog.trick_command=""
	dog.target=dog.position
	var placing=""
	if event_id=="Run":
		var rank=1+int(player_finish>3.15)+int(player_finish>3.7)
		placing="%s place! Every finish is worth cheering. " % ["First","Second","Third"][rank-1]
	result_text=placing+result.text
	narration.text=result.text
	if result.ok: dog.celebrate_success()
	refresh()

func _process(delta: float) -> void:
	if Game.paused_at>0 or get_meta("dialog_paused",false): return
	if not Game.can_explore() and phase in ["racing","approach","performing"]:
		host.habitat.puppy.fetch_running=false
		host.habitat.puppy.target=host.habitat.puppy.position
		refresh()
		narration.text="Let's rest first. Your completed steps are saved."
		return
	elapsed+=delta
	if phase=="racing":
		meter.value=(sin(elapsed*2.0)+1)*50
		for i in buddies.size():
			var progress=clampf(elapsed/(3.15+i*0.55),0,1)
			var next=Vector2(390+430*progress,535+i*80)
			buddy_distance+=buddies[i].position.distance_to(next)
			buddies[i].position=next
			var breed: String=buddies[i].get_meta("breed")
			var data: Dictionary=Art.WALK_DATA[breed]
			var frame=int(fmod(elapsed*2.2,1.0)*8)
			var box: Array=data.regions[frame]
			buddies[i].texture=Art.WALKS[breed]
			buddies[i].region_enabled=true
			buddies[i].region_rect=Rect2(box[0],box[1],box[2],box[3])
			buddies[i].offset=Vector2(box[2]*0.5-data.anchors[frame],-box[3]*0.5)
			buddies[i].scale=Vector2.ONE*(145.0/data.height)*(1.6 if size.y>size.x else 1.0)
		if host.habitat.puppy.position.distance_to(race_finish)<3:
			if player_finish==0: player_finish=elapsed
			if elapsed>=3.8: finish_step()
	elif phase=="approach" and host.habitat.puppy.position.distance_to(destination)<3: begin_performance()
	elif phase=="performing" and elapsed>=1.15: finish_step()

func _draw() -> void:
	var safe=UI.safe_insets(20)
	var y=safe.top+80
	var colors=[Color("dfada9"),Color("a9c0ae"),Color("b5c6d5"),Color("e3c58b")]
	draw_line(Vector2(safe.left,y),Vector2(size.x-safe.right,y),UI.INK,2,true)
	for i in range(12):
		var x=lerpf(safe.left,size.x-safe.right,float(i)/12)
		draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+24,y+27),Vector2(x+48,y)]),colors[i%4])
	if event_id=="Run" and is_instance_valid(host.habitat):
		var point=host.habitat.world.to_global(race_finish)
		draw_line(point-Vector2(0,55),point+Vector2(0,24),Color("fff4dc"),7,true)
	if event_id=="Lanterns":
		for i in mini(state.get("step",0),targets.size()):
			draw_circle(targets[i].get_rect().get_center(),52,Color(1,.82,.45,.17))
