extends PanelContainer

var host: Control
var words: Label
var join_button: Button
var shown = ""
var home_clock = 0.0
var last_invitation = ""

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
	return host.page=="Home" and Game.paused_at<=0 and Game.is_processing() and not is_instance_valid(host.intro_overlay) and not is_instance_valid(host.stage_overlay) and not is_instance_valid(host.navigation_overlay) and not is_instance_valid(host.resident_overlay) and not is_instance_valid(host.tip_overlay) and not is_instance_valid(host.photo_overlay) and not is_instance_valid(host.notice_overlay)

func _process(delta: float) -> void:
	var home = unobstructed_home()
	var awake = home and is_instance_valid(host.habitat) and not host.habitat.puppy.napping and IslandConnections.available(Game)
	if awake:
		home_clock += delta
		if home_clock>=75:
			home_clock = 0
			IslandConnections.offer(Game)
	var info = IslandConnections.invitation_info(Game)
	visible = home and not info.is_empty() and IslandConnections.available(Game) and is_instance_valid(host.habitat) and not host.habitat.puppy.napping
	if not visible: return
	var current: String = Game.life.connections.invitation
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
	join_button.disabled = IslandConnections.invitation_wait(Game)>0
	arrange()

func respond(join: bool) -> void:
	var result = IslandConnections.respond(Game,join)
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
