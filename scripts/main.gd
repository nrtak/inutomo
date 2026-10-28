extends Control

var navigation_overlay: Control
var menu_button: Button
var identity_card: PanelContainer
var tip_overlay: Control
var arrival_overlay: Control
var notice_overlay: Control
var notice_tween: Tween
var hud: Control
var camera_button: Button
var photo_overlay: Control
var photo_busy = false
var photo_was_processing = true
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
var message: CommandHint
var action_buttons: Dictionary = {}
var bag_button: Button
var message_card: PanelContainer
var needs_card: PanelContainer
var page_label: Label
var page = "Home"
var age_label: Label
var rest_button: Button
var actions: VBoxContainer
var habitat: Habitat
var intro_step = 0
var intro_text: CommandHint
var intro_progress: Label
var intro_next: Button
const INTRO_PAGES = [
	"Welcome! I’m Nora from the Puppy Club. Let’s meet your little friend.",
	"This is Mochi! A tiny puppy with a big future. Their breed is still a mystery.",
	"Feed, play, care and rest. Little moments help Mochi grow.",
	"Open Island to explore. Find me at the Puppy Club, and follow your journey in the Journal!"
]
var intro_overlay: Control
var status_clock = 0.0
var nav_buttons: Dictionary = {}

func _ready() -> void:
	world_host = Control.new()
	world_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(world_host)
	var margin = MarginContainer.new()
	hud = margin
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
	identity_card = identity
	identity.custom_minimum_size.x = 190
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
	island_button = UI.icon_button("Island", preload("res://assets/ui/island.svg"), request_page.bind("Island"), Color("c2ecf4"))
	island_button.custom_minimum_size.x = 104
	island_button.expand_icon = true
	island_button.add_theme_constant_override("icon_max_width", 32)
	quick_navigation.add_child(island_button)
	menu_button = UI.icon_button("Menu", preload("res://assets/ui/menu.svg"), open_navigation, Color("fff5e2"))
	menu_button.custom_minimum_size.x = 104
	menu_button.expand_icon = true
	menu_button.add_theme_constant_override("icon_max_width", 28)
	quick_navigation.add_child(menu_button)
	camera_button = UI.icon_button("Photo", preload("res://assets/ui/camera.svg"), open_photo_mode, Color("f9d8e2"))
	camera_button.custom_minimum_size.x = 104
	quick_navigation.add_child(camera_button)
	page_label = UI.label("", 30)
	page_label.visible = false
	quick_navigation.add_child(page_label)
	bag_button = UI.button("Bag", request_page.bind("Bag"))
	bag_button.visible = false
	quick_navigation.add_child(bag_button)
	needs_card = UI.card()
	needs_card.custom_minimum_size.x = 460
	needs_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(needs_card)
	var need_col = GridContainer.new()
	need_col.columns = 4
	need_col.add_theme_constant_override("h_separation", 12)
	need_col.add_theme_constant_override("v_separation", 8)
	needs_card.add_child(need_col)
	var colors = [Color("f5ad54"), Color("ef8396"), Color("f5cd55"), Color("65c4e5")]
	for i in Game.NEEDS.size():
		var key: String = Game.NEEDS[i]
		var col = UI.column(2)
		need_col.add_child(col)
		var line = HBoxContainer.new()
		col.add_child(line)
		var icon = UI.button("", show_need_tip.bind(key), Color("fff0cf"))
		icon.icon = load("res://assets/ui/" + ["feed", "play", "rest", "care"][i] + ".svg")
		icon.expand_icon = true
		icon.add_theme_constant_override("icon_max_width", 30)
		icon.custom_minimum_size = Vector2(54, 64)
		icon.tooltip_text = key
		line.add_child(icon)
		meter_labels[key] = UI.label(key, 24)
		meter_labels[key].autowrap_mode = TextServer.AUTOWRAP_OFF
		meter_labels[key].custom_minimum_size.x = 40
		line.add_child(meter_labels[key])
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(90, 10)
		bar.tooltip_text = key
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
	message = UI.hint_label("A little care makes a big world.", 22)
	message.custom_minimum_size.x = 300
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_card.add_child(message)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	var dock_layer = Control.new()
	dock_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(dock_layer)
	var action_dock = CenterContainer.new()
	action_dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	action_dock.offset_left = -116
	action_dock.offset_right = 0
	action_dock.offset_top = -210
	action_dock.offset_bottom = 242
	action_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_layer.add_child(action_dock)
	action_dock.add_child(actions)
	var action_colors = [Color("ffe0a0"), Color("bdeab0"), Color("b7def4"), Color("d9c9f6")]
	for i in 4:
		var kind: String = ["Feed", "Play", "Care", "Rest"][i]
		var b = UI.icon_button(kind, load("res://assets/ui/" + kind.to_lower() + ".svg"), Game.action.bind(kind), action_colors[i])
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 44)
		b.add_theme_constant_override("h_separation", 12)
		b.custom_minimum_size = Vector2(116, 100)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	if not Game.pending_stage.is_empty() and page == "Home" and not is_instance_valid(intro_overlay) and not is_instance_valid(stage_overlay) and not is_instance_valid(resident_overlay) and not is_instance_valid(tip_overlay) and not is_instance_valid(navigation_overlay) and not is_instance_valid(photo_overlay):
		show_growth_moment()
	status_clock += delta
	message_card.visible = false
	if is_instance_valid(intro_overlay):
		return
	if status_clock > 8 and is_instance_valid(habitat) and page == "Home":
		message.text = home_hint() if Game.points == 0 else habitat.puppy.mood + "."
	for kind in action_buttons:
		var button: Button = action_buttons[kind]
		var remaining = float(Game.cooldowns.get(kind, 0))
		button.disabled = remaining > 0
		if kind != "Rest":
			UI.button_caption(button, kind)
			UI.button_wait(button, remaining, 6.0)
	if not Game.save_error.is_empty():
		message.text = Game.save_error

func home_hint() -> String:
	if Game.resting:
		return Game.personalize("Mochi is resting. Tap Wake when you're ready.")
	return Game.personalize("Start with Feed, Play or Care. Tap the floor to call Mochi over.")

func _notice(text: String) -> void:
	message.text = text
	status_clock = 0
	show_feedback(text)

func show_feedback(text: String) -> void:
	if notice_tween != null and notice_tween.is_valid():
		notice_tween.kill()
	if is_instance_valid(notice_overlay):
		notice_overlay.queue_free()
	var overlay = CenterContainer.new()
	notice_overlay = overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	overlay.offset_top = 145
	overlay.offset_bottom = 235
	add_child(overlay)
	var panel = UI.card()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)
	var text_label = UI.hint_label(text, 22)
	text_label.custom_minimum_size.x = clampf(text.length() * 9.0, 220, 520)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text_label)
	notice_tween = create_tween()
	notice_tween.tween_interval(2.2)
	notice_tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	notice_tween.tween_callback(overlay.queue_free)

func _update_needs() -> void:
	for key in meters:
		meters[key].value = Game.needs[key]
		meter_labels[key].text = str(int(Game.needs[key]))
		meter_labels[key].tooltip_text = "%s: %d" % [key, int(Game.needs[key])]
	name_label.text = Game.puppy_name
	age_label.text = Game.growth_stage() if Game.breed == "Puppy" else Game.breed
	UI.button_caption(rest_button, "Wake" if Game.resting else "Rest")

func clear_body() -> void:
	habitat = null
	for parent in [body, world_host]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()

func update_navigation() -> void:
	camera_button.visible = page in ["Home", "Park", "Beach", "Puppy Club", "Vet Clinic", "Lighthouse"]
	identity_card.visible = page != "Island"
	bag_button.visible = false
	island_button.visible = page != "Island"
	page_label.text = "Puppy Island" if page == "Home" else page
	actions.visible = page == "Home"
	needs_card.visible = page in ["Home", "Fetch", "Walk"]
	message_card.visible = false
	for key in nav_buttons:
		nav_buttons[key].visible = page not in ["Fetch", "Walk"] or key == "Home"
		nav_buttons[key].modulate = Color("ffe3a5") if key == page else Color.WHITE

func set_scenery(location: String) -> void:
	habitat = preload("res://scenes/home.tscn").instantiate()
	habitat.location = location
	habitat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_host.add_child(habitat)
	if page == "Home" and not Game.pending_home_reaction.is_empty():
		habitat.puppy.react_to_care(Game.pending_home_reaction)
		Game.pending_home_reaction = ""

func show_page(dest: String) -> void:
	if notice_tween != null and notice_tween.is_valid():
		notice_tween.kill()
	if is_instance_valid(notice_overlay):
		notice_overlay.queue_free()
	notice_overlay = null
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
	if dest.begins_with("Life"):
		life_page(dest.get_slice(":", 1) if ":" in dest else "Dog")
		return
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
	show_arrival(place)

func page_panel() -> VBoxContainer:
	var bg = TextureRect.new()
	bg.texture = Art.HOME
	Daylight.apply_to(bg)
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
	col.add_child(UI.button("Island life: training, friends and keepsakes", show_page.bind("Life"), Color("c8eddd")))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var content = UI.column(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(UI.label(Game.growth_stage(), 28, UI.TEAL))
	var puppy_portrait = TextureRect.new()
	puppy_portrait.texture = Art.PUPPIES[Game.breed]
	puppy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puppy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	puppy_portrait.custom_minimum_size = Vector2(0, 130)
	content.add_child(puppy_portrait)
	content.add_child(UI.label("Your first island day", 26, UI.TEAL))
	content.add_child(UI.label("Three little moments, at your own pace.", 22))
	for goal in ["Care", "Nora", "Outing"]:
		var done: bool = Game.first_day.get(goal, false)
		var caption: String = {"Care": "Care for your puppy at Home", "Nora": "Meet Nora at the Puppy Club", "Outing": "Finish a Walk or Fetch"}[goal]
		var destination: String = {"Care": "Home", "Nora": "Puppy Club", "Outing": "Island"}[goal]
		var button = UI.button(("✓  " if done else "○  ") + caption, request_page.bind(destination), Color("bdeab0") if done else Color("fff5e2"))
		button.icon = load("res://assets/ui/" + {"Care": "care", "Nora": "play", "Outing": "map"}[goal] + ".svg")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 32)
		content.add_child(button)
	if Game.first_day.values().count(true) == 3:
		content.add_child(UI.label("You're settling in! Keep making little memories together.", 22, UI.TEAL))
	var progress = ProgressBar.new()
	progress.custom_minimum_size.y = 24
	progress.value = Game.growth_fraction() * 100
	content.add_child(progress)
	content.add_child(UI.label("Tiny puppy → Young puppy → Growing puppy → Adult", 23))
	content.add_child(UI.label(Game.next_growth_hint(), 24))
	content.add_child(UI.label("Care moments: %d of %d\nTime together: %d of 60 minutes" % [mini(Game.points, Game.EVOLUTION_POINTS), Game.EVOLUTION_POINTS, mini(60, int(Game.active_seconds / 60))], 22))
	var prediction = "Breed is still a mystery. Try a Walk or Fetch together."
	if Game.breed != "Puppy":
		prediction = "Grown into: " + Game.breed
	elif Game.walks + Game.fetches > 0:
		prediction = "Likely breed: " + Game.prediction() + ". Still growing!"
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
	col.add_child(UI.label("My Dogs", 30))
	col.add_child(UI.button("Personality, Wardrobe and Photos", show_page.bind("Life"), Color("f9d8e2")))
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
		var name_label = UI.label(dog_breed + ("\n" + Game.puppy_name if unlocked else "\nUndiscovered"), 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dog_col.add_child(name_label)
	col.add_child(UI.label("One puppy, one growth path. More adoptions will arrive later.", 21))

func show_intro() -> void:
	if is_instance_valid(intro_overlay):
		return
	intro_step = 0
	Game.set_process(false)
	hud.visible = false
	intro_overlay = Control.new()
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(intro_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(shade)
	var col = UI.conversation_body(intro_overlay, Art.NORA, "Nora")
	intro_progress = UI.label("", 21, UI.TEAL)
	col.add_child(intro_progress)
	intro_text = UI.hint_label("", 27)
	intro_text.custom_minimum_size.y = 100
	col.add_child(intro_text)
	intro_next = UI.button("Next", advance_intro, Color("bdeab0"))
	intro_next.custom_minimum_size = Vector2(230, 68)
	intro_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(intro_next)
	update_intro()

func update_intro() -> void:
	intro_progress.text = "●".repeat(intro_step + 1) + "○".repeat(INTRO_PAGES.size() - intro_step - 1)
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
	hud.visible = true
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
	if is_instance_valid(notice_overlay):
		notice_overlay.visible = false
	IslandLife.talk(Game, character_name)
	var was_processing = Game.is_processing()
	var hud_was_visible = hud.visible
	hud.visible = false
	Game.set_process(false)
	resident_overlay = Control.new()
	resident_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(resident_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resident_overlay.add_child(shade)
	var content = UI.conversation_body(resident_overlay, texture, character_name)
	var speech = UI.hint_label(text, 25)
	speech.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(speech)
	var close_button = UI.button("Close", func():
		resident_overlay.queue_free()
		resident_overlay = null
		hud.visible = hud_was_visible
		Game.set_process(was_processing)
	, Color("bdeab0"))
	close_button.custom_minimum_size = Vector2(150, 68)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(close_button)

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
	var pictures = {"Home": preload("res://assets/ui/home.svg"), "Island": preload("res://assets/ui/island.svg"), "Bag": preload("res://assets/ui/menu_bag.svg"), "Journal": preload("res://assets/ui/menu_journal.svg"), "My Dogs": Art.PUPPIES[Game.breed], "Menu": preload("res://assets/ui/title.svg")}
	var tile_colors = {"Home": Color("ffdfb5"), "Island": Color("c2ecf4"), "Bag": Color("c8eddd"), "Journal": Color("f9d8e2"), "My Dogs": Color("fff0bd"), "Menu": Color("e1d9f6")}
	for destination in ["Home", "Island", "Bag", "Journal", "My Dogs", "Menu"]:
		var label = "Title screen" if destination == "Menu" else destination
		var button = UI.picture_button(label, pictures[destination], func():
			close_navigation()
			request_page(destination)
		)
		for state in ["normal", "hover", "pressed"]:
			var color: Color = tile_colors[destination]
			button.add_theme_stylebox_override(state, UI.style(color.lightened(0.1) if state == "hover" else (color.darkened(0.08) if state == "pressed" else color), 22))
		grid.add_child(button)
	var close_button = UI.button("Close", close_navigation, Color("bdeab0"))
	close_button.custom_minimum_size = Vector2(180, 68)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override("font_size", 24)
	content.add_child(close_button)

func close_navigation() -> void:
	if is_instance_valid(navigation_overlay):
		navigation_overlay.queue_free()
	navigation_overlay = null

func life_page(section: String) -> void:
	set_scenery("Home")
	var browser = load("res://scripts/life_browser.gd").new()
	browser.host = self
	browser.mode = section if section in browser.MODES else "Dog"
	browser.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(browser)

func open_photo_mode() -> void:
	if is_instance_valid(photo_overlay):
		return
	if page not in ["Home", "Park", "Beach", "Puppy Club", "Vet Clinic", "Lighthouse"]:
		show_page("Home")
	photo_was_processing = Game.is_processing()
	if is_instance_valid(arrival_overlay):
		arrival_overlay.queue_free()
	Game.set_process(false)
	hud.visible = false
	photo_overlay = Control.new()
	photo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(photo_overlay)
	var row = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var safe = UI.safe_insets()
	row.offset_left = safe.left
	row.offset_right = -safe.right
	row.offset_top = -110 - safe.bottom
	row.offset_bottom = -safe.bottom
	photo_overlay.add_child(row)
	row.add_child(UI.icon_button("Back", UI.place_icon("Home"), close_photo_mode, Color("ffdfb5")))
	row.add_child(UI.icon_button("Capture", preload("res://assets/ui/camera.svg"), capture_photo, Color("f9d8e2")))
	row.add_child(UI.icon_button("Album", preload("res://assets/ui/menu_journal.svg"), func():
		if photo_busy:
			return
		close_photo_mode()
		show_page("Life:Photos")
	))

func close_photo_mode() -> void:
	if photo_busy:
		return
	if is_instance_valid(photo_overlay):
		photo_overlay.queue_free()
	photo_overlay = null
	hud.visible = true
	Game.set_process(photo_was_processing)

func capture_photo() -> void:
	if photo_busy:
		return
	if Game.life.photos.size() >= 20:
		show_feedback("Your album has 20 memories. All your photos are kept safely on this device.")
		return
	photo_busy = true
	photo_overlay.visible = false
	if is_instance_valid(notice_overlay):
		notice_overlay.visible = false
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var image = get_viewport().get_texture().get_image()
	var directory = ProjectSettings.globalize_path("user://photos")
	var result = DirAccess.make_dir_recursive_absolute(directory)
	var filename = "puppy_photo_" + str(int(Time.get_unix_time_from_system())) + "_" + str(Time.get_ticks_usec()) + ".png"
	if result == OK:
		result = image.save_png("user://photos/" + filename)
	if result == OK:
		Game.life.photos.push_front(filename)
		if not Game.save_game():
			photo_overlay.visible = true
			photo_busy = false
			show_feedback("Photo saved on this device. " + Game.save_error)
			return
	photo_overlay.visible = true
	photo_busy = false
	show_feedback("Photo saved to your island album." if result == OK else "Photo could not be saved. Please try again.")

func show_need_tip(key: String) -> void:
	if is_instance_valid(tip_overlay):
		return
	var tips = {"Hunger": "Feed a fresh meal at Home. Treats add a little extra.", "Happiness": "Play, pet your puppy, or enjoy a Walk or Fetch together.", "Energy": "Choose Rest for a cozy nap. Wake when you're ready.", "Cleanliness": "Choose Care at Home, or use shampoo from your Bag."}
	tip_overlay = Control.new()
	tip_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tip_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tip_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tip_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size.x = 620
	center.add_child(panel)
	var content = UI.column(16)
	content.custom_minimum_size.x = 580
	panel.add_child(content)
	content.add_child(UI.label(key, 32, UI.TEAL))
	content.add_child(UI.hint_label(tips[key], 27))
	content.add_child(UI.label("Fuller bars mean your puppy feels better.", 23))
	content.add_child(UI.button("Got it", func():
		tip_overlay.queue_free()
		tip_overlay = null
	, Color("bdeab0")))

func show_arrival(place: String) -> void:
	if is_instance_valid(arrival_overlay):
		arrival_overlay.queue_free()
	var overlay = Control.new()
	arrival_overlay = overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var wash = ColorRect.new()
	wash.color = Color("fff6e5")
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(wash)
	var title = UI.label(place, 38, UI.TEAL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(title)
	var transition = create_tween()
	transition.tween_property(wash, "modulate:a", 0.0, 0.35)
	transition.tween_interval(0.5)
	transition.tween_property(overlay, "modulate:a", 0.0, 0.3)
	transition.tween_callback(overlay.queue_free)
