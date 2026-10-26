extends Control

var start_button: Button
var guide_overlay: Control
var entering = false

func _ready() -> void:
	Game.set_process(false)
	var background = TextureRect.new()
	background.texture = Art.HOME
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
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 40)
	if OS.has_feature("ios"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.window_get_size()
		if screen.x > 0 and screen.y > 0:
			var ratio = get_viewport_rect().size / Vector2(screen)
			margin.add_theme_constant_override("margin_left", maxi(40, int(safe.position.x * ratio.x) + 12))
			margin.add_theme_constant_override("margin_right", maxi(40, int((screen.x - safe.end.x) * ratio.x) + 12))
			margin.add_theme_constant_override("margin_bottom", maxi(40, int((screen.y - safe.end.y) * ratio.y) + 12))
	add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	margin.add_child(row)
	var panel = UI.card()
	panel.custom_minimum_size.x = 490
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var content = UI.column(20)
	panel.add_child(content)
	content.add_child(UI.label("WELCOME TO", 21, UI.TEAL))
	content.add_child(UI.label("Puppy Island", 60))
	content.add_child(UI.label("Little paws. Big adventures.", 27))
	var companion = UI.label("Mochi / " + Game.breed, 23, UI.TEAL)
	content.add_child(companion)
	start_button = UI.button("Continue" if Game.intro_seen else "Start Adventure", enter_game, Color("bdeab0"))
	start_button.custom_minimum_size.y = 88
	content.add_child(start_button)
	content.add_child(UI.button("How to Play", show_guide, Color("b7def4")))
	content.add_child(UI.label("Version 0.1  /  Progress saves on this device", 18))
	var puppy = TextureRect.new()
	puppy.texture = Art.PUPPIES[Game.breed]
	puppy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puppy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	puppy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puppy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(puppy)

func enter_game() -> void:
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
	panel.custom_minimum_size = Vector2(800, 0)
	center.add_child(panel)
	var content = UI.column(16)
	content.custom_minimum_size.x = 760
	panel.add_child(content)
	content.add_child(UI.label("Your first little adventure", 34, UI.TEAL))
	content.add_child(UI.label("HOME\nFeed, Play, Care and Rest keep Mochi's four needs happy. Higher bars mean better care, including the Hunger bar.", 25))
	content.add_child(UI.label("ISLAND\nChoose Park for Fetch or Beach for a Walk. Mochi must be awake with at least 15 Energy. In Fetch, tap near 70% power for three throws. On a Walk, explore all three stops.", 25))
	content.add_child(UI.label("GROWTH\nCheck Journal for the predicted breed. More Walks favor Shiba Inu; Fetch and ties favor Golden Retriever. At 12 care moments, Mochi grows. My Dogs records your discovery.", 25))
	content.add_child(UI.label("Progress saves automatically. Tap Menu during play to return here.", 22))
	content.add_child(UI.button("Got it!", close_guide, Color("bdeab0")))

func close_guide() -> void:
	if is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
	guide_overlay = null
