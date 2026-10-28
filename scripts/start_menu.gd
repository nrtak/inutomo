extends Control

var start_button: Button
var guide_overlay: Control
var settings_overlay: Control
var name_center: CenterContainer
var name_panel: PanelContainer
var name_scroll: ScrollContainer
var name_heading: Label
var name_description: Label
var name_content: VBoxContainer
var keyboard_height_override = -1.0
var previous_keyboard = -1.0
var entering = false
var name_overlay: Control
var name_input: LineEdit
var name_error: Label
var sound_button: Button

func _ready() -> void:
	Game.set_process(false)
	Sound.set_location("Home")
	var background = TextureRect.new()
	background.texture = Art.HOME
	Daylight.apply_to(background)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.20, 0.20, 0.10)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe_edges = UI.safe_insets(40)
	for edge in safe_edges:
		margin.add_theme_constant_override("margin_" + edge, safe_edges[edge])
	add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	margin.add_child(row)
	var panel = UI.card()
	panel.custom_minimum_size.x = 490
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var content = UI.column(24)
	panel.add_child(content)
	content.add_child(UI.label("Puppy Island", 60))
	start_button = UI.button("Continue" if Game.intro_seen else "Start Adventure", enter_game, Color("bdeab0"))
	start_button.custom_minimum_size.y = 88
	content.add_child(start_button)
	var secondary = HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 12)
	content.add_child(secondary)
	var help_button = UI.button("How to Play", show_guide, Color("fff0cf"))
	help_button.add_theme_font_size_override("font_size", 23)
	secondary.add_child(help_button)
	sound_button = UI.button("Settings", show_sound_settings, Color("fff0cf"))
	sound_button.add_theme_font_size_override("font_size", 23)
	secondary.add_child(sound_button)
	var puppy = TextureRect.new()
	puppy.texture = Art.PUPPIES[Game.breed]
	puppy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puppy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	puppy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puppy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(puppy)

func enter_game() -> void:
	if not Game.name_chosen and not Game.intro_seen:
		show_name_picker()
		return
	if entering:
		return
	entering = true
	start_button.disabled = true
	Game.set_process(true)
	var error = get_tree().change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		Game.set_process(false)
		entering = false
		start_button.disabled = false
		start_button.text = "Try Again"

func show_guide() -> void:
	if is_instance_valid(guide_overlay):
		return
	guide_overlay = Control.new()
	guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(guide_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.08, 0.15, 0.18, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size = Vector2(800, 620)
	center.add_child(panel)
	var content = UI.column(16)
	content.custom_minimum_size.x = 760
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(UI.label("Your first little adventure", 34, UI.TEAL))
	content.add_child(UI.hint_label(Game.personalize("HOME\nFeed, Play, Care and Rest keep Mochi's four needs happy. Higher bars mean better care, including the Hunger bar."), 25))
	content.add_child(UI.hint_label("ISLAND\nTap a location to go there. Start Fetch at the Park or a Walk at the Beach. Outings need 15 Energy and an awake puppy. Completed steps save if you take a break.", 25))
	content.add_child(UI.hint_label("BAG & SHOP\nBrowse Food, Toys, Care, Comfort and Accessories. Give food and treats from your Bag. Choose beds and toys in Decor, and bandanas in Wardrobe. Owned care benefits apply automatically. Normal care stays free.", 25))
	content.add_child(UI.hint_label("GROWTH\nJournal tracks growth and memories. Adulthood needs 40 care moments and 60 minutes together. Walks favor Shiba Inu; Fetch and ties favor Golden Retriever.", 25))
	content.add_child(UI.hint_label("Open Journal for Island Life: training, friends, events and decorating. Tap the camera to take a picture; find it in Photos. Progress saves automatically.", 22))
	content.add_child(UI.button("Got it!", close_guide, Color("bdeab0")))

func close_guide() -> void:
	if is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
	guide_overlay = null

func toggle_sound() -> void:
	Sound.set_enabled(not Game.sound_enabled)
	sound_button.text = "Sound: On" if Game.sound_enabled else "Sound: Off"

func show_name_picker() -> void:
	if is_instance_valid(name_overlay):
		return
	name_overlay = Control.new()
	name_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(name_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_overlay.add_child(shade)
	name_center = CenterContainer.new()
	var center = name_center
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_overlay.add_child(center)
	name_panel = UI.card()
	var panel = name_panel
	panel.custom_minimum_size.x = 760
	center.add_child(panel)
	name_content = UI.column(18)
	var content = name_content
	content.custom_minimum_size.x = 720
	name_scroll = ScrollContainer.new()
	name_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	name_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(name_scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_scroll.add_child(content)
	name_heading = UI.label("A name for your little friend", 34, UI.TEAL)
	content.add_child(name_heading)
	name_description = UI.label("What would you like to call your puppy? Leave it blank to keep Mochi.", 25)
	content.add_child(name_description)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Mochi"
	name_input.max_length = 16
	name_input.custom_minimum_size.y = 76
	name_input.add_theme_font_size_override("font_size", 30)
	name_input.add_theme_color_override("font_color", UI.INK)
	name_input.add_theme_color_override("font_placeholder_color", Color("8b7869"))
	name_input.add_theme_stylebox_override("normal", UI.style(Color.WHITE))
	name_input.add_theme_stylebox_override("focus", UI.style(Color("effcf5")))
	name_input.text_submitted.connect(func(_text: String): confirm_name())
	content.add_child(name_input)
	previous_keyboard = -1
	call_deferred("update_name_layout")
	name_error = UI.label("Up to 16 characters.", 21)
	content.add_child(name_error)
	content.add_child(UI.button("Meet your puppy", confirm_name, Color("bdeab0")))
	content.add_child(UI.button("Back", func():
		name_overlay.queue_free()
		name_overlay = null
	, Color("fff0cf")))

func confirm_name() -> void:
	var old_name = Game.puppy_name
	var old_choice = Game.name_chosen
	Game.choose_name(name_input.text)
	if not Game.save_game():
		name_error.text = Game.save_error
		Game.puppy_name = old_name
		Game.name_chosen = old_choice
		return
	name_input.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	name_overlay.queue_free()
	name_overlay = null
	enter_game()

func _process(_delta: float) -> void:
	if is_instance_valid(name_overlay):
		update_name_layout()

func update_name_layout() -> void:
	if not is_instance_valid(name_overlay):
		return
	var keyboard = maxf(0, keyboard_height_override)
	if keyboard_height_override < 0 and DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		var window_height = maxf(1, DisplayServer.window_get_size().y)
		keyboard = DisplayServer.virtual_keyboard_get_height() * get_viewport_rect().size.y / window_height
	if is_equal_approx(keyboard, previous_keyboard):
		return
	previous_keyboard = keyboard
	name_description.visible = keyboard <= 0
	name_error.visible = keyboard <= 0 or not Game.save_error.is_empty()
	name_heading.add_theme_font_size_override("font_size", 26 if keyboard > 0 else 34)
	name_content.add_theme_constant_override("separation", 10 if keyboard > 0 else 18)
	name_center.offset_bottom = -keyboard
	name_panel.custom_minimum_size.y = clampf(get_viewport_rect().size.y - keyboard - 40, 180, 520)
	call_deferred("reveal_name_input")

func reveal_name_input() -> void:
	if is_instance_valid(name_overlay) and name_input.has_focus():
		name_scroll.ensure_control_visible(name_input)

func show_sound_settings() -> void:
	if is_instance_valid(settings_overlay):
		return
	settings_overlay = Control.new()
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(settings_overlay)
	var shade = ColorRect.new()
	shade.color = Color(0.1, 0.18, 0.22, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(center)
	var panel = UI.card()
	panel.custom_minimum_size.x = 760
	center.add_child(panel)
	var content = UI.column(14)
	content.custom_minimum_size.x = 720
	panel.add_child(content)
	content.add_child(UI.label("Gentle island sounds", 34, UI.TEAL))
	var toggle = UI.button("Sound: On" if Game.sound_enabled else "Sound: Off", func(): pass, Color("ffe0b0"))
	toggle.pressed.connect(func():
		Sound.set_enabled(not Game.sound_enabled)
		toggle.text = "Sound: On" if Game.sound_enabled else "Sound: Off"
	)
	content.add_child(toggle)
	var levels: Dictionary = {}
	for kind in ["effects", "waves"]:
		var value = Game.effects_volume if kind == "effects" else Game.ambience_volume
		var label = UI.label(("Care and footsteps" if kind == "effects" else "Ocean ambience") + ": %d%%" % int(value * 100), 25)
		content.add_child(label)
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = value * 100
		slider.custom_minimum_size.y = 84
		content.add_child(slider)
		levels[kind] = slider
		slider.value_changed.connect(func(number: float):
			if kind == "effects":
				Sound.set_levels(number / 100, Game.ambience_volume, false)
			else:
				Sound.set_levels(Game.effects_volume, number / 100, false)
			label.text = ("Care and footsteps" if kind == "effects" else "Ocean ambience") + ": %d%%" % int(number)
		)
		slider.drag_ended.connect(func(_changed: bool): Game.save_game())
	content.add_child(UI.button("Try a care sound", Sound.play_effect.bind("care", -19), Color("b7def4")))
	content.add_child(UI.button("Done", func():
		Game.save_game()
		settings_overlay.queue_free()
		settings_overlay = null
	, Color("bdeab0")))
