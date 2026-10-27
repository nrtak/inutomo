extends Control

var navigation_overlay: Control
var menu_button: Button
var island_button: Button
var leave_overlay: Control
var current_place = "Home"
var resident_overlay: Control
var stage_overlay: Control
var name_label: Label
var body: VBoxContainer
var world_host: Control
var meters: Dictionary = {}
var meter_labels: Dictionary = {}
var message: Label
var action_buttons: Dictionary = {}
var bag_button: Button
var message_card: PanelContainer
var needs_card: PanelContainer
var page_label: Label
var page = "Home"
var age_label: Label
var rest_button: Button
var actions: HBoxContainer
var habitat: Habitat
var intro_step = 0
var intro_text: Label
var intro_progress: Label
var intro_next: Button
const INTRO_PAGES = [
	"Welcome to Puppy Island! I’m Nora from the Puppy Club. I’ll help you settle in. Your island story starts right here, with a little friend by your side.",
	"Meet Mochi! This little puppy is still growing, and their breed is a mystery. Spend time together and discover who they’ll become.",
	"At Home, use Feed, Play, Care and Rest. Watch the four needs above: fuller bars mean Mochi feels better. There’s no rush—start with a little care.",
	"Ready to explore? Open Island to play Fetch at the Park or take a Walk at the Beach. Your Journal follows Mochi’s growth. I’ll be at the Puppy Club whenever you want a reminder!"
]
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
	var safe_edges = UI.safe_insets(20)
	for edge in safe_edges:
		margin.add_theme_constant_override("margin_" + edge, safe_edges[edge])
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
	name_label = UI.label(Game.puppy_name, 32)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity_col.add_child(name_label)
	age_label = UI.label("", 24)
	identity_col.add_child(age_label)
	var title_space = CenterContainer.new()
	title_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_space.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(title_space)
	var quick_navigation = HBoxContainer.new()
	quick_navigation.add_theme_constant_override("separation", 12)
	title_space.add_child(quick_navigation)
	island_button = UI.button("Island", request_page.bind("Island"), Color("fff5e2"))
	island_button.custom_minimum_size.x = 160
	island_button.icon = preload("res://assets/ui/map.svg")
	island_button.expand_icon = true
	island_button.add_theme_constant_override("icon_max_width", 32)
	quick_navigation.add_child(island_button)
	menu_button = UI.button("Menu", open_navigation, Color("fff5e2"))
	menu_button.custom_minimum_size.x = 160
	menu_button.icon = preload("res://assets/ui/menu.svg")
	menu_button.expand_icon = true
	menu_button.add_theme_constant_override("icon_max_width", 28)
	quick_navigation.add_child(menu_button)
	page_label = UI.label("", 30)
	page_label.visible = false
	quick_navigation.add_child(page_label)
	bag_button = UI.button("Bag", request_page.bind("Bag"))
	bag_button.visible = false
	quick_navigation.add_child(bag_button)
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
		b.custom_minimum_size.y = 88
		actions.add_child(b)
		action_buttons[kind] = b
		if kind == "Rest":
			rest_button = b
	Game.notice.connect(_notice)
	Game.changed.connect(_update_needs)
	show_page("Home")
	_update_needs()
	if not Game.intro_seen:
		show_intro()
	if not Game.save_error.is_empty():
		_notice(Game.save_error)

func _process(delta: float) -> void:
	if not Game.pending_stage.is_empty() and page == "Home" and not is_instance_valid(intro_overlay) and not is_instance_valid(stage_overlay) and not is_instance_valid(resident_overlay):
		show_growth_moment()
	status_clock += delta
	message_card.visible = page == "Home" and (status_clock < 6 or not Game.save_error.is_empty())
	if is_instance_valid(intro_overlay):
		return
	if status_clock > 8 and is_instance_valid(habitat) and page == "Home":
		message.text = home_hint() if Game.points == 0 else habitat.puppy.mood + "."
	for kind in action_buttons:
		var button: Button = action_buttons[kind]
		var remaining = float(Game.cooldowns.get(kind, 0))
		button.disabled = remaining > 0
		if kind != "Rest":
			button.text = "%s (%ds)" % [kind, ceili(remaining)] if remaining > 0 else kind
	if not Game.save_error.is_empty():
		message.text = Game.save_error

func home_hint() -> String:
	if Game.resting:
		return Game.personalize("Mochi is resting. Tap Wake when you're ready.")
	return Game.personalize("Start with Feed, Play or Care. Tap the floor to call Mochi over.")

func _notice(text: String) -> void:
	message.text = text
	status_clock = 0

func _update_needs() -> void:
	for key in meters:
		meters[key].value = Game.needs[key]
		meter_labels[key].text = "%s  %d" % [key, int(Game.needs[key])]
	name_label.text = Game.puppy_name
	age_label.text = Game.growth_stage() if Game.breed == "Puppy" else Game.breed
	rest_button.text = "Wake" if Game.resting else "Rest"

func clear_body() -> void:
	habitat = null
	for parent in [body, world_host]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()

func update_navigation() -> void:
	bag_button.visible = false
	island_button.visible = page != "Island"
	page_label.text = "Puppy Island" if page == "Home" else page
	actions.visible = page == "Home"
	needs_card.visible = page in ["Home", "Fetch", "Walk"]
	message_card.visible = page == "Home"
	for key in nav_buttons:
		nav_buttons[key].visible = page not in ["Fetch", "Walk"] or key == "Home"
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
	if dest in Art.BACKGROUNDS:
		current_place = dest
	clear_body()
	update_navigation()
	match dest:
		"Home":
			set_scenery("Home")
			var open_space = Control.new()
			open_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
			open_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
			body.add_child(open_space)
			if Game.points == 0:
				_notice(home_hint())
		"Island": island()
		"Journal": journal_page()
		"My Dogs": dogs_page()
		"Puppy Club", "Shop", "Vet Clinic", "Lighthouse", "Park", "Beach": location_page(dest)
		"Bag": goods_page(false)

func start_activity(kind: String) -> void:
	if not Game.can_explore():
		_notice(Game.personalize("Rest at Home first. Mochi needs to be awake with 15 energy."))
		return
	clear_body()
	page = kind
	current_place = "Park" if kind == "Fetch" else "Beach"
	update_navigation()
	set_scenery("Park" if kind == "Fetch" else "Beach")
	var scene = load("res://scenes/" + kind.to_lower() + ".tscn").instantiate()
	scene.habitat = habitat
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.finished.connect(show_page.bind("Home"))
	body.add_child(scene)
	_notice("Finish together to earn a growth moment.")

func island() -> void:
	var map = load("res://scripts/island_map.gd").new()
	map.host = self
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(map)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

func visit(place: String) -> void:
	match place:
		"Home": show_page("Home")
		"Park": show_page("Park")
		"Beach": show_page("Beach")
		"Puppy Club", "Shop", "Vet Clinic": show_page(place)
		"Lighthouse (Later)", "Lighthouse": show_page("Lighthouse")

func page_panel() -> VBoxContainer:
	var bg = TextureRect.new()
	bg.texture = Art.HOME
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.75, 0.78, 0.76)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(bg)
	var inset = MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 0)
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
	col.add_child(UI.label(Game.puppy_name + "'s Growth Journey", 30))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var content = UI.column(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(UI.label(Game.growth_stage(), 28, UI.TEAL))
	var progress = ProgressBar.new()
	progress.custom_minimum_size.y = 24
	progress.value = Game.growth_fraction() * 100
	content.add_child(progress)
	content.add_child(UI.label("Tiny puppy / Young puppy / Growing puppy / Adult", 23))
	content.add_child(UI.label(Game.next_growth_hint(), 24))
	content.add_child(UI.label("Care moments: %d / %d    Time together: %d / 60 minutes" % [mini(Game.points, Game.EVOLUTION_POINTS), Game.EVOLUTION_POINTS, mini(60, int(Game.active_seconds / 60))], 22))
	var prediction = "Breed is still a mystery. Try a Walk or Fetch together."
	if Game.breed != "Puppy":
		prediction = "Grown into: " + Game.breed
	elif Game.walks + Game.fetches > 0:
		prediction = "Likely breed: " + Game.prediction() + " / still growing!"
	content.add_child(UI.label(prediction, 26, UI.TEAL))
	content.add_child(UI.label("Walks: %d    Fetch: %d. Walks favor Shiba Inu; Fetch and ties favor Golden Retriever." % [Game.walks, Game.fetches], 22))
	content.add_child(UI.label("Growth needs care and time in the game. Time away does not rush growth. Memory times show hours and minutes together.", 21))
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
		var name_label = UI.label(dog_breed + (" / " + Game.puppy_name if unlocked else " / Undiscovered"), 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dog_col.add_child(name_label)
	col.add_child(UI.label("One puppy, one growth path. More adoptions will arrive later.", 21))

func show_intro() -> void:
	if is_instance_valid(intro_overlay):
		return
	intro_step = 0
	Game.set_process(false)
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
	row.add_child(UI.character_portrait(Art.NORA, "Nora", "Puppy Club organizer"))
	var col = UI.column(18)
	col.custom_minimum_size.x = 520
	row.add_child(col)
	intro_progress = UI.label("", 21, UI.TEAL)
	col.add_child(intro_progress)
	intro_text = UI.label("", 27)
	intro_text.custom_minimum_size.y = 200
	col.add_child(intro_text)
	intro_next = UI.button("Next", advance_intro, Color("bdeab0"))
	col.add_child(intro_next)
	update_intro()

func update_intro() -> void:
	intro_progress.text = "Welcome / %d of %d" % [intro_step + 1, INTRO_PAGES.size()]
	intro_text.text = Game.personalize(INTRO_PAGES[intro_step])
	intro_next.text = "Let's go home!" if intro_step == INTRO_PAGES.size() - 1 else "Next"

func advance_intro() -> void:
	if intro_step < INTRO_PAGES.size() - 1:
		intro_step += 1
		update_intro()
		return
	Game.intro_seen = true
	Game.save_game()
	intro_overlay.queue_free()
	intro_overlay = null
	Game.set_process(true)
	show_page("Home")

func show_growth_moment() -> void:
	stage_overlay = Control.new()
	stage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage_overlay)
	Game.set_process(false)
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.22, 0.23, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size = Vector2(730, 0)
	center.add_child(panel)
	var content = UI.column(14)
	content.custom_minimum_size.x = 690
	panel.add_child(content)
	content.add_child(UI.label("A little bigger, a little braver!", 32, UI.TEAL))
	var portrait = TextureRect.new()
	portrait.texture = Art.PUPPIES[Game.breed]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size.y = 180
	content.add_child(portrait)
	var detail = Game.breed if Game.pending_stage == "Adult" else Game.pending_stage
	content.add_child(UI.label(Game.puppy_name + " has grown into a " + detail + "." if Game.pending_stage == "Adult" else Game.puppy_name + " reached the " + detail.to_lower() + " stage.", 28))
	content.add_child(UI.label("A new chapter is saved in your Journal. Thank you for all the little moments together.", 24))
	content.add_child(UI.button("Keep growing together", close_growth_moment, Color("bdeab0")))
	Sound.play_effect("growth", -17)

func close_growth_moment() -> void:
	Game.pending_stage = ""
	Game.save_game()
	stage_overlay.queue_free()
	stage_overlay = null
	Game.set_process(true)

func location_page(location: String) -> void:
	if location == "Shop":
		goods_page(true)
		return
	set_scenery(location)
	var hub = load("res://scripts/location_hub.gd").new()
	hub.host = self
	hub.location = location
	hub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(hub)

func show_resident(texture: Texture2D, character_name: String, role: String, text: String) -> void:
	if is_instance_valid(resident_overlay):
		return
	var was_processing = Game.is_processing()
	Game.set_process(false)
	resident_overlay = Control.new()
	resident_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(resident_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resident_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resident_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size = Vector2(850, 390)
	center.add_child(panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	row.add_child(UI.character_portrait(texture, character_name, role))
	var content = UI.column(18)
	content.custom_minimum_size.x = 520
	row.add_child(content)
	var speech = UI.label(text, 25)
	speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(speech)
	content.add_child(UI.button("See you soon!", func():
		resident_overlay.queue_free()
		resident_overlay = null
		Game.set_process(was_processing)
	, Color("bdeab0")))

func goods_page(shop: bool) -> void:
	set_scenery("Shop" if shop else "Home")
	var browser = load("res://scripts/goods_browser.gd").new()
	browser.host = self
	browser.shopping = shop
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(browser)

func request_page(dest: String) -> void:
	if page in ["Fetch", "Walk"] and body.get_child_count() > 0 and not body.get_child(0).complete:
		if is_instance_valid(leave_overlay):
			return
		leave_overlay = Control.new()
		leave_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(leave_overlay)
		var shade = ColorRect.new()
		shade.color = Color(0.1, 0.18, 0.22, 0.55)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		leave_overlay.add_child(shade)
		var center = CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		leave_overlay.add_child(center)
		var panel = UI.card()
		panel.custom_minimum_size.x = 740
		center.add_child(panel)
		var content = UI.column(16)
		content.custom_minimum_size.x = 700
		panel.add_child(content)
		content.add_child(UI.label("Take a break from this outing?", 32, UI.TEAL))
		content.add_child(UI.label("Completed throws and discoveries are saved. The current step will restart when you return from the map.", 25))
		content.add_child(UI.button("Keep playing", close_leave_prompt, Color("bdeab0")))
		content.add_child(UI.button("Leave outing", func():
			close_leave_prompt()
			show_page(dest)
		, Color("ffe0b0")))
		return
	show_page(dest)

func close_leave_prompt() -> void:
	if is_instance_valid(leave_overlay):
		leave_overlay.queue_free()
	leave_overlay = null

func open_navigation() -> void:
	if is_instance_valid(navigation_overlay):
		return
	navigation_overlay = Control.new()
	navigation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(navigation_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size.x = 920
	center.add_child(panel)
	var content = UI.column(16)
	content.custom_minimum_size.x = 880
	panel.add_child(content)
	content.add_child(UI.label("Your island", 34, UI.TEAL))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	var pictures = {"Home": Art.HOME, "Island": Art.ISLAND, "Bag": preload("res://assets/ui/bag.svg"), "Journal": preload("res://assets/ui/journal.svg"), "My Dogs": Art.PUPPIES[Game.breed], "Menu": preload("res://assets/ui/title.svg")}
	for destination in ["Home", "Island", "Bag", "Journal", "My Dogs", "Menu"]:
		var label = "Title screen" if destination == "Menu" else destination
		var button = UI.picture_button(label, pictures[destination], func():
			close_navigation()
			request_page(destination)
		, destination in ["Home", "Island"])
		grid.add_child(button)
	content.add_child(UI.button("Close", close_navigation, Color("bdeab0")))

func close_navigation() -> void:
	if is_instance_valid(navigation_overlay):
		navigation_overlay.queue_free()
	navigation_overlay = null
