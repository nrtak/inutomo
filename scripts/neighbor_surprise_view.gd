extends Control

var host: Control
var state: Dictionary
var phase="ready"
var clock=0.0
var selected=-1
var panel: PanelContainer
var speaker: PanelContainer
var words: CommandHint
var choices: VBoxContainer
var targets: Array[Button]=[]
var visit_mode=false

func _ready() -> void:
	name="NeighborSurpriseView"
	set_meta("screen_layout_manual",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	state=Game.life.surprises
	visit_mode=state.kind=="Visit"
	var dog=host.habitat.puppy
	dog.controlled=true
	dog.wake_briefly()
	dog.expression_time=0
	if state.kind!="Visit":
		if state.route=="Beach": host.habitat.use_scenery(BeachStyle.BACKGROUND,"Beach Arrival")
		dog.walk_area=WalkArea.AREAS.Park
		dog.barriers.clear()
		dog.position=Vector2(640,600)
	dog.target=dog.position
	speaker=UI.card()
	add_child(speaker)
	var intro=HBoxContainer.new()
	intro.add_theme_constant_override("separation",12)
	speaker.add_child(intro)
	var person=IslandSurprises.OWNERS[state.buddy] if state.kind=="Visit" else IslandSurprises.REQUESTS[state.kind].person
	var face=UI.resident_icon(IslandFestivals.PORTRAITS[person])
	var portrait=TextureRect.new()
	portrait.texture=face
	portrait.material=UI.art_cutout()
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size=Vector2(70,70)
	portrait.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	intro.add_child(portrait)
	var introduction=UI.label(person+"’s little visit" if visit_mode else person+" could use our help",24,UI.TEAL)
	introduction.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	intro.add_child(introduction)
	panel=UI.card()
	add_child(panel)
	var content=UI.column(10)
	panel.add_child(content)
	words=UI.hint_label("",23)
	content.add_child(words)
	choices=UI.column(8)
	content.add_child(choices)
	for i in 3:
		var button=UI.button("",inspect.bind(i),Color("fff0bd"))
		button.icon=preload("res://assets/manga/ui/menu_bag.svg")
		button.expand_icon=true
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width",60)
		button.tooltip_text="Let "+Game.puppy_name+" sniff this spot"
		button.custom_minimum_size=Vector2(76,76)
		for style in ["normal","hover","pressed","disabled","focus"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
		add_child(button)
		targets.append(button)
	if state.kind=="Visit":
		dog.home_interactions=false
		dog.barriers.clear()
		dog.bed_barrier=Rect2()
		if host.habitat.decor_sprites.has("Feed"): host.habitat.decor_sprites.Feed.visible=false
		host.habitat.visiting_buddy=state.buddy
		host.habitat.surprise_guest_key=state.buddy
		host.habitat.show_playmate()
		var familiar=int(Game.life.adventure.buddies.get(state.buddy,{}).get("visits",0))>=2
		host.habitat.playmate.position=WalkArea.destination(dog.walk_area,dog.active_barriers(),Vector2(745 if familiar else 835,560))
		if familiar:
			host.habitat.playmate.texture=Art.expression_texture(IslandAdventure.BUDDIES[state.buddy].breed,"Greet")
			host.habitat.playmate.offset=Vector2(0,-host.habitat.playmate.texture.get_height()*.5)
			host.habitat.playmate.scale=Vector2.ONE*(170.0/host.habitat.playmate.texture.get_height())
	resized.connect(func(): arrange.call_deferred())
	panel.minimum_size_changed.connect(func(): arrange.call_deferred())
	refresh()

func add_action(text: String, action: Callable, icon: Texture2D) -> void:
	var button=UI.location_button(text,icon,action,Color("c8eddd"))
	button.custom_minimum_size=Vector2(0,86)
	choices.add_child(button)

func refresh(message: String = "") -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for target in targets: target.visible=state.kind in IslandSurprises.REQUESTS and state.step==1 and phase=="ready"
	if phase=="done":
		words.text=message
		add_action("Back to Home",host.request_page.bind("Home"),UI.place_icon("Home"))
	elif state.kind=="Visit":
		words.text=IslandSurprises.info(Game).text+" Choose a quiet hello or a longer ball game."
		add_action("A quick, quiet hello",start_visit.bind("Hello"),preload("res://assets/manga/ui/heart.svg"))
		add_action("Go play Fetch together",start_visit.bind("Fetch"),preload("res://assets/manga/ui/play.svg"))
	elif state.step==0:
		words.text="Which way should we follow the scent of "+IslandSurprises.REQUESTS[state.kind].object+"?"
		add_action("Search the Park",choose_route.bind("Park"),UI.place_icon("Park"))
		add_action("Search the Beach",choose_route.bind("Beach"),UI.place_icon("Beach"))
	elif state.step==1:
		words.text=message if not message.is_empty() else "Let "+Game.puppy_name+" sniff the three spots. Follow that familiar scent!"
	else:
		var spec: Dictionary=IslandSurprises.REQUESTS[state.kind]
		words.text=message if not message.is_empty() else "Found "+spec.object+"! Let's bring it back to "+spec.person+"."
		add_action("Return to "+spec.person,host.request_page.bind("Plans:"+spec.place),UI.place_icon(spec.place))
	arrange.call_deferred()

func choose_route(place: String) -> void:
	if IslandSurprises.choose_route(Game,place): host.show_page("Surprise")
	else: words.text="A little rest first. Your clue is safely saved."

func start_visit(kind: String) -> void:
	if not IslandSurprises.choose_visit(Game,kind):
		words.text="A little rest first. Your friend can wait."
		return
	if kind=="Fetch":
		host.start_activity("Fetch")
		return
	phase="hello"
	clock=0
	for child in choices.get_children(): child.disabled=true
	host.habitat.puppy.celebrate_success()
	words.text="A little sniff, a soft tail wag, and a friendly hello."

func target_point(index: int) -> Vector2:
	return WalkArea.destination(host.habitat.puppy.walk_area,host.habitat.puppy.active_barriers(),[Vector2(420,610),Vector2(640,625),Vector2(860,600)][index])

func inspect(index: int) -> void:
	if phase!="ready" or Game.paused_at>0 or get_meta("dialog_paused",false) or not Game.can_explore(): return
	phase="approach"
	selected=index
	host.habitat.puppy.target=target_point(index)
	for target in targets: target.disabled=true

func _process(delta: float) -> void:
	if Game.paused_at>0 or get_meta("dialog_paused",false): return
	if phase in ["hello","approach","sniff"] and not Game.can_explore():
		phase="ready"
		host.habitat.puppy.target=host.habitat.puppy.position
		for target in targets: target.disabled=false
		refresh("A little rest first. This visit and your clues will wait.")
		return
	clock+=delta
	if phase=="hello" and clock>=1.5:
		var result=IslandSurprises.finish_visit(Game,"Hello")
		if result.ok: phase="done"
		refresh(result.text)
	elif phase=="approach" and host.habitat.puppy.position.distance_to(target_point(selected))<3:
		phase="sniff"
		clock=0
		host.habitat.puppy.begin_expression("Sniff",0.9)
	elif phase=="sniff" and clock>=0.95:
		var result=IslandSurprises.search(Game,selected)
		phase="ready"
		for target in targets: target.disabled=false
		if result.ok: host.habitat.puppy.show_action_item(Goods.picture(IslandSurprises.REQUESTS[state.kind].goods))
		refresh(result.text)

func arrange() -> void:
	if not is_inside_tree() or not is_instance_valid(panel): return
	var safe=UI.safe_insets(20)
	var portrait=size.y>size.x
	var width=minf(680,size.x-safe.left-safe.right) if portrait else minf(430,(size.x-safe.left-safe.right-28)*.5)
	speaker.size=Vector2(width,speaker.get_combined_minimum_size().y)
	speaker.position=Vector2(safe.left,safe.top+92)
	words.custom_minimum_size.x=width-40
	panel.size=Vector2(width,panel.get_combined_minimum_size().y)
	panel.position=Vector2(safe.left if portrait else size.x-safe.right-width,size.y-safe.bottom-panel.size.y if portrait else safe.top+92)
	var dog=host.habitat.puppy
	if visit_mode:
		var floor_y=panel.position.y-26 if portrait else size.y-safe.bottom-16
		var top=speaker.get_rect().end.y+30 if portrait else maxf(speaker.get_rect().end.y,panel.get_rect().end.y)+25
		var height=minf(260 if portrait else 240,maxf(100,floor_y-top))
		var factor=maxf(.01,host.habitat.world.scale.x)
		dog.scale=Vector2.ONE*minf(1.0,height/maxf(1,dog.awake_height()*factor))
		dog.screen_width_limit=size.x*(.4 if portrait else .23)/(factor*dog.scale.x)
		dog.fit_screen_width()
		dog.position=host.habitat.world.to_local(Vector2(size.x*(.27 if portrait else .4),floor_y))
		dog.target=dog.position
		dog.walk_area=PackedVector2Array([dog.position+Vector2(-1,-1),dog.position+Vector2(1,-1),dog.position+Vector2(1,1),dog.position+Vector2(-1,1)])
		var friend=host.habitat.playmate
		if is_instance_valid(friend):
			var friend_size=friend.get_rect().size
			friend.scale=Vector2.ONE*minf(height/(friend_size.y*factor),size.x*(.4 if portrait else .23)/(friend_size.x*factor))
			friend.position=host.habitat.world.to_local(Vector2(size.x*(.74 if portrait else .66),floor_y))
	elif host.habitat.location!="Home":
		dog.scale=Vector2.ONE*(minf(2.3,280.0/maxf(1,dog.awake_height()*host.habitat.world.scale.y)) if portrait else 1.0)
		dog.screen_width_limit=size.x*.42/maxf(.01,host.habitat.world.scale.y*dog.scale.x) if portrait else INF
	for i in targets.size():
		var point=host.habitat.world.to_global(target_point(i))
		var lower=speaker.get_rect().end.y+10 if portrait else maxf(speaker.get_rect().end.y,panel.get_rect().end.y)+20
		var upper=panel.position.y-82 if portrait else size.y-safe.bottom-82
		targets[i].size=Vector2(76,76)
		targets[i].position=(point-Vector2(38,60)).clamp(Vector2(safe.left,lower),Vector2(size.x-safe.right-76,maxf(lower,upper)))
