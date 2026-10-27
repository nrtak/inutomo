extends HBoxContainer

var host: Control
var mode = "Dog"
var feedback = ""
var training_buttons: Dictionary = {}
var content: VBoxContainer
var album_overlay: Control
const MODES = ["Dog", "Wardrobe", "Training", "Friends", "Finds", "Home", "Events", "Photos"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render()

func _process(_delta: float) -> void:
	for command in training_buttons:
		var button: Button = training_buttons[command]
		button.disabled = Game.cooldowns.get("Training", 0) > 0
		UI.button_wait(button, Game.cooldowns.get("Training", 0), 20.0)

func choose(value: String) -> void:
	mode = value
	feedback = ""
	if is_instance_valid(host.habitat):
		host.habitat.puppy.preview_accessory = ""
	render()

func render() -> void:
	training_buttons.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var compact = mode in ["Wardrobe", "Home", "Training"]
	if is_instance_valid(host.habitat):
		host.habitat.view_offset.x = -minf(220, host.size.x * 0.16) if compact else 0.0
		host.habitat._resize_world()
	if compact:
		var space = Control.new()
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(space)
	var panel = UI.card()
	panel.custom_minimum_size.x = 440 if compact else 0
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END if compact else Control.SIZE_EXPAND_FILL
	add_child(panel)
	var layout = UI.column(10)
	layout.custom_minimum_size.x = 400 if compact else 0
	panel.add_child(layout)
	var top = HBoxContainer.new()
	layout.add_child(top)
	var title = UI.label(("Decorating" if mode == "Home" else mode) if compact else "Island life", 28, UI.TEAL)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var back = UI.button("Home", host.show_page.bind("Home"), Color("ffdfb5"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.custom_minimum_size = Vector2(120, 60)
	top.add_child(back)
	var tabs = GridContainer.new()
	tabs.columns = 4 if compact else 8
	tabs.add_theme_constant_override("h_separation", 5)
	tabs.add_theme_constant_override("v_separation", 5)
	layout.add_child(tabs)
	for section in MODES:
		var icon_name: String = {"Dog": "club", "Wardrobe": "bandana_coral", "Training": "training_treat", "Friends": "heart", "Finds": "shell", "Home": "home", "Events": "sunset", "Photos": "camera"}[section]
		var tab = UI.icon_button(section, load("res://assets/ui/" + icon_name + ".svg"), choose.bind(section), Color("ffe0a0") if section == mode else Color("c2ecf4"))
		tab.custom_minimum_size = Vector2(0, 72)
		tab.get_meta("caption").add_theme_font_size_override("font_size", 20)
		tab.get_meta("caption").autowrap_mode = TextServer.AUTOWRAP_OFF
		tab.get_meta("caption").text = {"Wardrobe": "Style", "Home": "Décor"}.get(section, section)
		tab.add_theme_font_size_override("font_size", 16)
		for state in ["normal", "hover", "pressed"]:
			var box = UI.style(Color("ffe0a0") if section == mode else Color("c2ecf4"), 15)
			box.content_margin_left = 8
			box.content_margin_right = 8
			box.content_margin_top = 8
			box.content_margin_bottom = 8
			tab.add_theme_stylebox_override(state, box)
		tabs.add_child(tab)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	content = UI.column(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	match mode:
		"Dog": dog_page()
		"Wardrobe": wardrobe()
		"Training": training()
		"Friends": friends()
		"Finds": finds()
		"Home": decorating()
		"Events": events()
		"Photos": photos()

func tile(text: String, icon: Texture2D, action: Callable, color: Color = Color("c8eddd")) -> Button:
	var button = UI.icon_button(text, icon, action, color)
	button.custom_minimum_size.y = 102
	content.add_child(button)
	return button

func respond(text: String) -> void:
	feedback = text
	render()
	host.show_feedback(text)

func dog_page() -> void:
	content.add_child(UI.label(Game.puppy_name + " is " + IslandLife.personality(Game).to_lower() + ".", 28, UI.TEAL))
	var descriptions = {"Curious": "Always sniffing for a new discovery.", "Cuddly": "Happiest with gentle pats and cozy company.", "Playful": "Always ready for a little game."}
	content.add_child(UI.label(descriptions[IslandLife.personality(Game)], 24))
	content.add_child(UI.label("Favorite treats and toy", 24, UI.TEAL))
	var row = HBoxContainer.new()
	content.add_child(row)
	for category in ["Food", "Toys"]:
		var favorite = IslandLife.favorite(Game, category)
		var picture = UI.picture_button(Goods.ITEMS[favorite].name, Goods.picture(favorite), host.show_page.bind("Shop"))
		row.add_child(picture)
	tile("Take a photo", preload("res://assets/ui/camera.svg"), host.open_photo_mode)

func wardrobe() -> void:
	content.add_child(UI.hint_label("Preview a color before you buy.", 23))
	tile("Original teal", preload("res://assets/ui/club.svg"), func():
		Game.life.accessory = ""
		host.habitat.puppy.preview_accessory = ""
		Game.save_game()
		respond("Wearing the original teal bandana.")
	, Color("c8eddd"))
	for kind in Goods.ITEMS:
		if Goods.ITEMS[kind].category != "Accessories":
			continue
		var item: Dictionary = Goods.ITEMS[kind]
		var row = HBoxContainer.new()
		content.add_child(row)
		row.add_child(UI.button(item.name, preview.bind(kind), item.color.lightened(0.25)))
		row.add_child(UI.button("Wear" if Game.items.get(kind, 0) > 0 else "Buy", wear.bind(kind), Color("c8eddd")))
		content.add_child(UI.label("Owned" if Game.items.get(kind, 0) > 0 else str(item.price) + " coins", 21))

func preview(kind: String) -> void:
	host.habitat.puppy.preview_accessory = kind
	respond("Previewing " + Goods.ITEMS[kind].name.to_lower() + ".")

func wear(kind: String) -> void:
	if Game.items.get(kind, 0) == 0:
		var result = Game.buy_item(kind)
		if Game.items.get(kind, 0) == 0:
			respond(result)
			return
	Game.life.accessory = kind
	host.habitat.puppy.preview_accessory = ""
	Game.save_game()
	respond("Wearing " + Goods.ITEMS[kind].name.to_lower() + ".")

func training() -> void:
	content.add_child(UI.label("Ben's little lessons", 27, UI.TEAL))
	content.add_child(UI.label("Five gentle practices teach each command. Take a breather between lessons.", 23))
	for command in IslandLife.COMMANDS:
		var button = tile(command, preload("res://assets/ui/training_treat.svg"), func(): respond(IslandLife.train(Game, command)))
		training_buttons[command] = button
		content.add_child(UI.label(str(Game.life.training[command]) + " of 5 lessons", 22))

func friends() -> void:
	content.add_child(UI.label("Little favors, growing friendships", 27, UI.TEAL))
	var residents = {"Nora": Art.NORA, "Ben": Art.BEN, "June": Art.JUNE, "Leah": Art.LEAH, "Owen": Art.OWEN}
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for person in residents:
		var box = UI.column(8)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(box)
		var hearts = Game.life.friends.get(person, {}).get("hearts", 0)
		var portrait_button = UI.picture_button(person + " · " + str(hearts) + " hearts", UI.resident_icon(residents[person]), func():
			friend_conversation(person, residents[person])
		)
		portrait_button.custom_minimum_size.y = 160
		box.add_child(portrait_button)
		var status = IslandLife.favor_status(Game, person)
		box.add_child(UI.hint_label(status.text, 22, UI.TEAL))
		var favor_button = UI.button(status.button, friend_conversation.bind(person, residents[person], true), Color("f9d8e2"))
		favor_button.custom_minimum_size.y = 64
		favor_button.disabled = status.state == "claimed"
		box.add_child(favor_button)
		if status.state == "active":
			var destination: String = {"Care": "Home", "Feed": "Home", "Fetch": "Park", "Walk": "Beach"}[IslandLife.PEOPLE[person]]
			var go = UI.button("Go to " + destination, host.show_page.bind(destination), Color("c2ecf4"))
			go.custom_minimum_size.y = 64
			box.add_child(go)

func friend_conversation(person: String, portrait: Texture2D, asking_favor: bool = false) -> void:
	IslandLife.talk(Game, person)
	var reply = IslandLife.favor(Game, person) if asking_favor else "Lovely to see you and " + Game.puppy_name + "! Shall we make another little island memory?"
	render()
	host.show_resident(portrait, person, {"Nora": "Puppy Club organizer", "Ben": "Trainer", "June": "Shopkeeper", "Leah": "Veterinarian", "Owen": "Neighbor"}[person], reply)

func finds() -> void:
	content.add_child(UI.label("Beach keepsakes", 27, UI.TEAL))
	content.add_child(UI.hint_label("Discover them on a Walk. Collected treasures appear at Home.", 23))
	for index in IslandLife.KEEPSAKES.size():
		var item: String = IslandLife.KEEPSAKES[index]
		tile(item if item in Game.life.keepsakes else "Still to discover", load("res://assets/ui/" + IslandLife.KEEPSAKE_ICONS[index] + ".svg"), host.show_page.bind("Beach"), Color("c2ecf4"))

func decorating() -> void:
	for category in ["Comfort", "Toys"]:
		content.add_child(UI.label("Resting spot" if category == "Comfort" else "Playtime toy", 23))
		var choices = GridContainer.new()
		choices.columns = 2
		choices.add_theme_constant_override("h_separation", 8)
		choices.add_theme_constant_override("v_separation", 8)
		choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(choices)
		for kind in Goods.ITEMS:
			if Goods.ITEMS[kind].category == category and Game.items.get(kind, 0) > 0:
				var selected = kind == Game.life["bed" if category == "Comfort" else "toy"]
				var button = UI.icon_button(Goods.ITEMS[kind].name, Goods.picture(kind), decorate.bind(kind), Color("ffdfb5") if selected else Color("c8eddd"))
				button.custom_minimum_size = Vector2(180, 102)
				button.add_theme_font_size_override("font_size", 18)
				button.get_meta("caption").add_theme_font_size_override("font_size", 20)
				choices.add_child(button)
	var positions = HBoxContainer.new()
	content.add_child(positions)
	for index in 3:
		positions.add_child(UI.button(["Left", "Middle", "Right"][index], move_bed.bind(index), Color("c2ecf4")))
	tile("Clear decorations", preload("res://assets/ui/home.svg"), func():
		Game.life.bed = ""
		Game.life.toy = ""
		Game.save_game()
		host.show_page("Life:Home")
	)
	content.add_child(UI.hint_label("Buy beds and toys at June's Shop. Their care benefits stay active while owned.", 22))

func decorate(kind: String) -> void:
	if Game.items.get(kind, 0) <= 0:
		return
	Game.life["bed" if Goods.ITEMS[kind].category == "Comfort" else "toy"] = kind
	Game.save_game()
	host.show_page("Life:Home")

func move_bed(index: int) -> void:
	Game.life.spot = index
	Game.save_game()
	host.show_page("Life:Home")

func events() -> void:
	IslandLife.refresh_day(Game)
	var event = IslandLife.event_info()
	content.add_child(UI.label(event.name, 30, UI.TEAL))
	content.add_child(UI.label("A small celebration today. Enjoy each activity to earn 15 coins.", 23))
	for action in event.tasks:
		var done = Game.life.daily.get(action, 0) > 0
		content.add_child(UI.hint_label(("✓  " if done else "○  ") + action + " together", 26))
	tile("Celebrate", preload("res://assets/ui/heart.svg"), func(): respond(IslandLife.claim_event(Game)), Color("f9d8e2"))

func photos() -> void:
	var take = tile("Take a photo", preload("res://assets/ui/camera.svg"), host.open_photo_mode)
	take.custom_minimum_size.x = 240
	take.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(UI.label(str(Game.life.photos.size()) + " of 20 memories. Tap a photo to view it.", 23))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	content.add_child(grid)
	for filename in Game.life.photos:
		var box = UI.column(8)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(box)
		var path = "user://photos/" + filename
		if not FileAccess.file_exists(path):
			box.add_child(UI.label("Photo unavailable on this device.", 23))
			box.add_child(UI.button("Remove from album", confirm_delete.bind(filename), Color("f9d8e2")))
			continue
		var image = Image.load_from_file(path)
		if image == null or image.is_empty():
			box.add_child(UI.label("Photo could not be opened.", 23))
			box.add_child(UI.button("Remove from album", confirm_delete.bind(filename), Color("f9d8e2")))
			continue
		if image.get_width() > 640:
			image.resize(640, maxi(1, roundi(image.get_height() * 640.0 / image.get_width())), Image.INTERPOLATE_LANCZOS)
		var picture = UI.picture_button("View photo", ImageTexture.create_from_image(image), show_photo.bind(filename))
		picture.custom_minimum_size.y = 210
		box.add_child(picture)
		var remove = UI.button("Delete", confirm_delete.bind(filename), Color("f9d8e2"))
		remove.custom_minimum_size = Vector2(130, 60)
		remove.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(remove)

func new_album_overlay() -> Control:
	close_album_overlay()
	album_overlay = Control.new()
	album_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(album_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.05, 0.10, 0.14, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_overlay.add_child(shade)
	return album_overlay

func close_album_overlay() -> void:
	if is_instance_valid(album_overlay):
		album_overlay.queue_free()
	album_overlay = null

func show_photo(filename: String) -> void:
	if filename not in Game.life.photos:
		return
	var image = Image.load_from_file("user://photos/" + filename)
	if image == null or image.is_empty():
		respond("Photo could not be opened.")
		return
	var overlay = new_album_overlay()
	var safe = UI.safe_insets()
	var picture = TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = safe.left
	picture.offset_right = -safe.right
	picture.offset_top = safe.top
	picture.offset_bottom = -110 - safe.bottom
	overlay.add_child(picture)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -90 - safe.bottom
	row.offset_bottom = -safe.bottom
	overlay.add_child(row)
	row.add_child(UI.button("Close", close_album_overlay, Color("c8eddd")))
	row.add_child(UI.button("Delete", confirm_delete.bind(filename), Color("f9d8e2")))
	for button in row.get_children():
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size = Vector2(160, 68)

func confirm_delete(filename: String) -> void:
	var overlay = new_album_overlay()
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size.x = 560
	center.add_child(panel)
	var column = UI.column(14)
	column.custom_minimum_size.x = 520
	panel.add_child(column)
	column.add_child(UI.label("Delete this photo?", 30, UI.TEAL))
	column.add_child(UI.label("It will be removed from this device's island album. This cannot be undone.", 25))
	var row = HBoxContainer.new()
	column.add_child(row)
	row.add_child(UI.button("Cancel", close_album_overlay, Color("c8eddd")))
	row.add_child(UI.button("Delete photo", func():
		close_album_overlay()
		respond(IslandLife.delete_photo(Game, filename))
	, Color("f9d8e2")))

func _exit_tree() -> void:
	close_album_overlay()
