extends PanelContainer

var host: Control
var words: Label
var join_button: Button
var shown = ""
var home_clock = 0.0
var last_invitation = ""
var surprise_shown = false
var door_guest: TextureButton

func _ready() -> void:
	name = "DogInvitation"
	add_theme_stylebox_override("panel",UI.style(Color("fff6e5"),24))
	var column = UI.column(6)
	add_child(column)
	words = UI.label("",21)
	column.add_child(words)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	column.add_child(row)
	join_button = UI.button("Join",respond.bind(true),Color("c8eddd"))
	join_button.custom_minimum_size = Vector2(190,48)
	join_button.add_theme_font_size_override("font_size",20)
	row.add_child(join_button)
	var later = UI.button("Later",respond.bind(false),Color("f9d8e2"))
	later.custom_minimum_size = Vector2(78,48)
	later.add_theme_font_size_override("font_size",20)
	row.add_child(later)
	host.resized.connect(arrange)
	arrange()
	visible = false

func unobstructed_home() -> bool:
	return host.page=="Home" and Game.paused_at<=0 and Game.is_processing() and not host.has_open_overlay() and not is_instance_valid(host.notice_overlay)

func _process(delta: float) -> void:
	var home = unobstructed_home()
	var awake = home and is_instance_valid(host.habitat) and not host.habitat.puppy.napping and IslandConnections.available(Game)
	if awake:
		home_clock += delta
		if home_clock>=6 and Game.life.surprises.day<IslandLife.today() and IslandSurprises.eligible(Game) and host.habitat.puppy.ready_for_growth_moment():
			IslandSurprises.offer(Game)
		if home_clock>=75:
			home_clock = 0
			if not IslandSurprises.offer(Game) and IslandSurprises.info(Game).is_empty(): IslandConnections.offer(Game)
	var surprise=IslandSurprises.info(Game)
	surprise_shown=not surprise.is_empty()
	var info=surprise if surprise_shown else IslandConnections.invitation_info(Game)
	var at_door=awake and Game.life.surprises.kind=="Visit" and Game.life.surprises.day==IslandLife.today() and not Game.life.surprises.accepted and IslandSurprises.eligible(Game) and host.habitat.puppy.ready_for_growth_moment()
	if at_door and (not is_instance_valid(door_guest) or door_guest.get_parent()!=host.habitat or door_guest.get_meta("buddy")!=Game.life.surprises.buddy):
		if is_instance_valid(door_guest): door_guest.queue_free()
		show_door_guest()
	if is_instance_valid(door_guest):
		door_guest.visible=at_door
		if host.page=="Home" and is_instance_valid(host.habitat.playmate):
			var show_playmate=not at_door or host.habitat.visiting_buddy!=Game.life.surprises.buddy
			if host.habitat.playmate.visible!=show_playmate:
				for part in [host.habitat.playmate,host.habitat.playmate_shadow,host.habitat.playmate_name]:
					part.visible=show_playmate
	if at_door:
		visible=false
		return
	visible = home and not info.is_empty() and IslandConnections.available(Game) and is_instance_valid(host.habitat) and not host.habitat.puppy.napping
	if surprise_shown and Game.life.surprises.kind=="Visit" and not Game.life.surprises.accepted: visible=false
	if not visible: return
	var current: String = "Surprise:"+Game.life.surprises.kind+Game.life.surprises.buddy if surprise_shown else Game.life.connections.invitation
	if current!=last_invitation:
		last_invitation = current
		var dog = host.habitat.puppy
		dog.reaction_above_head = true
		# A waking puppy offers the invitation; sleeping puppies keep their nap.
		if not dog.napping:
			if current=="Toy" and Game.items.get(Game.life.toy,0)>0: dog.begin_toy_visit()
			else: dog.react_to_care(info.reaction)
	words.text = info.text
	join_button.text = info.join
	join_button.disabled = not IslandSurprises.eligible(Game) if surprise_shown else IslandConnections.invitation_wait(Game)>0
	arrange()

func show_door_guest() -> void:
	var habitat: Habitat=host.habitat
	var buddy: String=Game.life.surprises.buddy
	door_guest=TextureButton.new()
	door_guest.name="DoorVisitor"
	door_guest.set_meta("buddy",buddy)
	door_guest.ignore_texture_size=true
	door_guest.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	door_guest.texture_normal=Art.PUPPIES[IslandAdventure.BUDDIES[buddy].breed]
	door_guest.material=UI.art_cutout()
	door_guest.tooltip_text="Play with "+buddy
	door_guest.accessibility_name=door_guest.tooltip_text
	habitat.add_child(door_guest)
	var ball=TextureRect.new()
	ball.texture=Goods.picture("Toy")
	ball.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ball.material=UI.art_cutout()
	door_guest.add_child(ball)
	var caption=UI.label(door_guest.tooltip_text,18,Color.WHITE)
	caption.add_theme_constant_override("outline_size",5)
	caption.add_theme_color_override("font_outline_color",UI.INK)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_bottom=26
	door_guest.add_child(caption)
	var guest=door_guest
	var place_guest=func():
		var height=clampf(habitat.size.y*.21,108,178)
		guest.size=Vector2.ONE*height
		guest.position=Vector2(habitat.size.x*.68-height*.5,habitat.size.y*.56-height)
		ball.size=guest.size*.28
		ball.position=guest.size*Vector2(.71,.74)
	habitat.resized.connect(place_guest)
	guest.tree_exiting.connect(func(): habitat.resized.disconnect(place_guest),CONNECT_ONE_SHOT)
	place_guest.call()
	var dog=habitat.puppy
	var door_point=habitat.world.to_local(guest.global_position+guest.size*Vector2(.35,.95))
	dog.target=WalkArea.destination(dog.walk_area,dog.active_barriers(),door_point)
	dog.attention_left=door_point.x<dog.position.x
	dog.attention_time=2
	dog.decision=7
	Sound.play_effect("visitor",-23)
	guest.pressed.connect(func():
		if not unobstructed_home() or not IslandSurprises.eligible(Game) or Game.life.surprises.buddy!=buddy or Game.life.surprises.accepted: return
		if IslandSurprises.respond(Game,true).ok and IslandSurprises.choose_visit(Game,"Fetch"):
			host.start_activity("Fetch")
	)

func respond(join: bool) -> void:
	var result = IslandSurprises.respond(Game,join) if surprise_shown else IslandConnections.respond(Game,join)
	if not result.ok:
		host.show_feedback(result.text)
		return
	home_clock = 0
	last_invitation = ""
	visible = false
	if not result.page.is_empty():
		if result.page=="Scent Trail": host.start_scent_trail()
		else: host.request_page(result.page)
	elif join:
		host.show_feedback(result.text)

func arrange() -> void:
	var safe = UI.safe_insets(20)
	var width = clampf(host.size.x*0.30,300,370)
	custom_minimum_size.x = width
	words.custom_minimum_size.x = width-40
	size = Vector2(width,get_combined_minimum_size().y)
	position = Vector2(safe.left,host.size.y-safe.bottom-size.y-8)
	if host.size.y>host.size.x: position.y-=260
