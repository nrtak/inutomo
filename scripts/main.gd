extends Control

var body: VBoxContainer
var world_host: Control
var meters: Dictionary = {}
var meter_labels: Dictionary = {}
var message: Label
var message_card: PanelContainer
var needs_card: PanelContainer
var page_label: Label
var page = "Home"
var age_label: Label
var rest_button: Button
var actions: HBoxContainer
var habitat: Habitat
var intro_overlay: Control
var status_clock = 0.0
var nav_buttons: Dictionary = {}

func _ready() -> void:
	world_host = Control.new()
	world_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(world_host)
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	if OS.has_feature("ios"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.window_get_size()
		if screen.x > 0 and screen.y > 0:
			var ratio = get_viewport_rect().size / Vector2(screen)
			margin.add_theme_constant_override("margin_left", maxi(20, int(safe.position.x * ratio.x) + 12))
			margin.add_theme_constant_override("margin_right", maxi(20, int((screen.x - safe.end.x) * ratio.x) + 12))
			margin.add_theme_constant_override("margin_top", maxi(20, int(safe.position.y * ratio.y) + 8))
			margin.add_theme_constant_override("margin_bottom", maxi(20, int((screen.y - safe.end.y) * ratio.y) + 8))
	add_child(margin)
	var layout = UI.column(10)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)
	var header = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(header)
	var identity = UI.card()
	identity.custom_minimum_size.x = 300
	identity.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(identity)
	var identity_col = UI.column(2)
	identity.add_child(identity_col)
	identity_col.add_child(UI.label("Mochi", 32))
	age_label = UI.label("", 24)
	identity_col.add_child(age_label)
	var title_space = CenterContainer.new()
	title_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_space.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(title_space)
	var title_card = UI.card()
	title_space.add_child(title_card)
	page_label = UI.label("Puppy Island", 30)
	page_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_card.add_child(page_label)
	needs_card = UI.card()
	needs_card.custom_minimum_size.x = 250
	header.add_child(needs_card)
	var need_col = UI.column(6)
	needs_card.add_child(need_col)
	var colors = [Color("f5ad54"), Color("ef8396"), Color("f5cd55"), Color("65c4e5")]
	for i in Game.NEEDS.size():
		var key: String = Game.NEEDS[i]
		var col = UI.column(2)
		need_col.add_child(col)
		meter_labels[key] = UI.label(key, 24)
		col.add_child(meter_labels[key])
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 10)
		bar.show_percentage = false
		var bg = UI.style(Color("dfcfb8"), 6)
		bg.set_border_width_all(0)
		var fill = UI.style(colors[i], 6)
		fill.set_border_width_all(0)
		for box in [bg, fill]:
			box.content_margin_left = 0
			box.content_margin_right = 0
			box.content_margin_top = 0
			box.content_margin_bottom = 0
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		col.add_child(bar)
		meters[key] = bar
	body = UI.column(8)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	message_card = UI.card()
	message_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(message_card)
	message = UI.label("A little care makes a big world.", 22)
	message.custom_minimum_size.x = 700
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_card.add_child(message)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	var action_colors = [Color("ffe0a0"), Color("bdeab0"), Color("b7def4"), Color("d9c9f6")]
	for i in 4:
		var kind: String = ["Feed", "Play", "Care", "Rest"][i]
		var b = UI.button(kind, Game.action.bind(kind), action_colors[i])
		b.icon = load("res://assets/ui/" + kind.to_lower() + ".svg")
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 44)
		b.add_theme_constant_override("h_separation", 12)
		b.custom_minimum_size.y = 82
		actions.add_child(b)
		if kind == "Rest":
			rest_button = b
	var nav = VBoxContainer.new()
	nav.position = Vector2(margin.get_theme_constant("margin_left"), 150)
	nav.add_theme_constant_override("separation", 10)
	add_child(nav)
	for dest in ["Home", "Island", "Journal", "My Dogs", "Menu"]:
		var b = UI.button(dest, show_page.bind(dest), Color("fff5e2"))
		b.custom_minimum_size.x = 150
		b.custom_minimum_size.y = 72
		b.add_theme_font_size_override("font_size", 26)
		nav.add_child(b)
		nav_buttons[dest] = b
	Game.notice.connect(_notice)
	Game.changed.connect(_update_needs)
	show_page("Home")
	_update_needs()
	if not Game.intro_seen:
		show_intro()
	if not Game.save_error.is_empty():
		_notice(Game.save_error)

func _process(delta: float) -> void:
	status_clock += delta
	if status_clock > 8 and is_instance_valid(habitat) and page == "Home":
		message.text = habitat.puppy.mood + "."
	if not Game.save_error.is_empty():
		message.text = Game.save_error

func _notice(text: String) -> void:
	message.text = text
	status_clock = 0

func _update_needs() -> void:
	for key in meters:
		meters[key].value = Game.needs[key]
		meter_labels[key].text = "%s  %d" % [key, int(Game.needs[key])]
	age_label.text = Game.breed + " · %d / 12" % mini(Game.points, 12)
	rest_button.text = "Wake" if Game.resting else "Rest"

func clear_body() -> void:
	habitat = null
	for parent in [body, world_host]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()

func update_navigation() -> void:
	page_label.text = "Puppy Island" if page == "Home" else page
	actions.visible = page == "Home"
	needs_card.visible = page in ["Home", "Fetch", "Walk"]
	message_card.visible = page == "Home"
	for key in nav_buttons:
		nav_buttons[key].modulate = Color("ffe3a5") if key == page else Color.WHITE

func set_scenery(location: String) -> void:
	habitat = preload("res://scenes/home.tscn").instantiate()
	habitat.location = location
	habitat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(habitat)

func show_page(dest: String) -> void:
	if dest == "Menu":
		if not Game.save_game():
			_notice(Game.save_error)
			return
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
		return
	page = dest
	clear_body()
	update_navigation()
	match dest:
		"Home":
			set_scenery("Home")
			var open_space = Control.new()
			open_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
			open_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
			body.add_child(open_space)
		"Island": island()
		"Journal": journal_page()
		"My Dogs": dogs_page()

func start_activity(kind: String) -> void:
	if not Game.can_explore():
		_notice("Rest at Home first. Mochi needs to be awake with 15 energy.")
		return
	clear_body()
	page = kind
	update_navigation()
	set_scenery("Park" if kind == "Fetch" else "Beach")
	var scene = load("res://scenes/" + kind.to_lower() + ".tscn").instantiate()
	scene.habitat = habitat
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.finished.connect(show_page.bind("Home"))
	body.add_child(scene)
	_notice("Finish together to earn a growth moment.")

func island() -> void:
	var bg = TextureRect.new()
	bg.texture = Art.ISLAND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(bg)
	var pin_layer = Control.new()
	pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(pin_layer)
	var places = [
		["Home", Vector2(0.26, 0.30)], ["Puppy Club", Vector2(0.57, 0.27)],
		["Park", Vector2(0.45, 0.49)], ["Shop · later", Vector2(0.20, 0.57)],
		["Vet Clinic · later", Vector2(0.72, 0.48)], ["Beach", Vector2(0.75, 0.72)],
		["Lighthouse · later", Vector2(0.83, 0.19)]]
	for place in places:
		var place_name: String = place[0]
		var b = UI.button(place_name, visit.bind(place_name), Color("fff6e5"))
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(170, 68)
		pin_layer.add_child(b)
		b.anchor_left = place[1].x
		b.anchor_top = place[1].y
		b.anchor_right = b.anchor_left
		b.anchor_bottom = b.anchor_top
		b.offset_left = -85
		b.offset_right = 85
		b.offset_top = -34
		b.offset_bottom = 34
		if "later" in place_name:
			b.disabled = true
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

func visit(place: String) -> void:
	match place:
		"Home": show_page("Home")
		"Park": start_activity("Fetch")
		"Beach": start_activity("Walk")
		"Puppy Club": show_intro()

func page_panel() -> VBoxContainer:
	var bg = TextureRect.new()
	bg.texture = Art.HOME
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.75, 0.78, 0.76)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(bg)
	var inset = MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 175)
	inset.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(inset)
	var panel = UI.card()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inset.add_child(panel)
	var col = UI.column(12)
	panel.add_child(col)
	return col

func journal_page() -> void:
	var col = page_panel()
	col.add_child(UI.label("Mochi's Growth Journey", 30))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var content = UI.column(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(UI.label("Puppy  →  Growing  →  Adult     %d / %d care moments" % [mini(Game.points, Game.EVOLUTION_POINTS), Game.EVOLUTION_POINTS], 24))
	content.add_child(UI.label("Likely breed: " + Game.prediction() if Game.breed == "Puppy" else "Grown into: " + Game.breed, 28, UI.TEAL))
	content.add_child(UI.label("Walks favor Shiba Inu. Fetch favors Golden Retriever; ties favor Golden. At 12 care moments, Mochi grows into the predicted breed.", 23))
	content.add_child(UI.label("Walks: %d    Fetch: %d    Feed, Play, Care or finish an outing to grow." % [Game.walks, Game.fetches], 22))
	content.add_child(UI.label("Little memories", 26))
	if Game.journal.is_empty():
		content.add_child(UI.label("Your first chapter is waiting. Try a little care at Home.", 22))
	for entry in Game.journal:
		content.add_child(UI.label("• " + str(entry), 22))

func dogs_page() -> void:
	var col = page_panel()
	col.add_child(UI.label("My Dogs / A growing family", 30))
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(row)
	for dog_breed in ["Puppy", "Shiba Inu", "Golden Retriever"]:
		var unlocked = dog_breed == "Puppy"
		for dog in Game.collection:
			if dog.breed == dog_breed:
				unlocked = true
		var dog_col = UI.column(8)
		dog_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(dog_col)
		var portrait = TextureRect.new()
		portrait.texture = Art.PUPPIES[dog_breed]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait.custom_minimum_size = Vector2(0, 130)
		portrait.modulate = Color.WHITE if unlocked else Color(0.35, 0.35, 0.35, 0.4)
		dog_col.add_child(portrait)
		var name_label = UI.label(dog_breed + (" · Mochi" if unlocked else " · Undiscovered"), 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dog_col.add_child(name_label)
	col.add_child(UI.label("One puppy, one growth path. More adoptions will arrive later.", 21))

func show_intro() -> void:
	if is_instance_valid(intro_overlay):
		return
	intro_overlay = Control.new()
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(intro_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size = Vector2(850, 390)
	center.add_child(panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var portrait = TextureRect.new()
	portrait.texture = Art.NORA
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size.x = 240
	row.add_child(portrait)
	var col = UI.column(18)
	col.custom_minimum_size.x = 520
	row.add_child(col)
	col.add_child(UI.label("Nora / Puppy Club", 32, UI.TEAL))
	col.add_child(UI.label("Welcome to Puppy Island! Meet Mochi, your new little companion.\n\nFeed, play, care and rest together. Try Fetch at the Park or a coastal Walk. Every little moment helps Mochi grow.\n\nYour Journal shows who Mochi might become!", 25))
	col.add_child(UI.button("Let's go home!", func():
		Game.intro_seen = true
		Game.save_game()
		intro_overlay.queue_free()
		intro_overlay = null
	))
