extends Control

var host: Control
var portrait: ResidentPortrait
var speech_panel: PanelContainer
var speech: CommandHint
var actions_panel: PanelContainer
var action_scroll: ScrollContainer
var content: VBoxContainer
var picnic_button: Button
var repeat_button: Button
var feedback = ""
var tail: Polygon2D
var shown_state = ""
var rolling_ball = false

func _ready() -> void:
	name = "WelcomeDayView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait = ResidentPortrait.new()
	portrait.configure(Art.NORA)
	portrait.frames = [MomentArt.resident("Nora")]
	portrait.frame_index = 0
	portrait.texture = portrait.frames[0]
	add_child(portrait)
	speech_panel = UI.card()
	speech_panel.name = "NoraSpeech"
	speech_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var speech_style = UI.style(Color("fff6e5"), 30)
	speech_style.content_margin_left = 16
	speech_style.content_margin_right = 16
	speech_style.content_margin_top = 10
	speech_style.content_margin_bottom = 10
	speech_panel.add_theme_stylebox_override("panel", speech_style)
	add_child(speech_panel)
	var words = UI.column(4)
	speech_panel.add_child(words)
	words.add_child(UI.label("Nora", 23, Color("237d82")))
	speech = UI.hint_label("", 21)
	words.add_child(speech)
	tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(0,0),Vector2(-18,19),Vector2(30,0)])
	tail.color = Color("fff6e5")
	speech_panel.add_child(tail)
	var outline = Line2D.new()
	outline.points = tail.polygon
	outline.default_color = UI.INK
	outline.width = 2
	outline.antialiased = true
	tail.add_child(outline)
	actions_panel = UI.card()
	actions_panel.name = "WelcomeActions"
	add_child(actions_panel)
	action_scroll = ScrollContainer.new()
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_panel.add_child(action_scroll)
	content = UI.column(9)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(content)
	resized.connect(arrange)
	speech.minimum_size_changed.connect(arrange)
	Game.changed.connect(refresh_deferred)
	host.habitat.welcome_ball_rolled.connect(finish_ball_game)
	host.habitat.visiting_buddy = "Momo"
	host.habitat.playmate_height = 205
	host.habitat.show_playmate()
	var dog = host.habitat.puppy
	dog.scale = Vector2.ONE * (210.0 / (dog.visible_size.y * dog.base_scale))
	dog.reaction_above_head = true
	host.habitat.puppy.wake_briefly()
	refresh()

func refresh_deferred() -> void:
	var snapshot = str(Game.life.welcome_day) + Game.activity_block_reason()
	if snapshot != shown_state:
		shown_state = snapshot
		refresh.call_deferred()

func refresh() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	shown_state = str(Game.life.welcome_day) + Game.activity_block_reason()
	picnic_button = null
	repeat_button = null
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var state: Dictionary = Game.life.welcome_day
	content.add_child(UI.label("Island Welcome Day", 27, UI.TEAL))
	if not state.started:
		speech.set_hint("Let's help every puppy feel at home. Will you and " + Game.puppy_name + " join our little picnic?")
		content.add_child(UI.label("A new island memory", 23))
		content.add_child(UI.label("Meet a friend, practice together, then enjoy a picnic. Your invitation stays open.", 21))
		add_action("Join Nora's picnic", preload("res://assets/ui/heart.svg"), accept_invitation)
	elif state.picnic_step == 3:
		speech.set_hint(feedback if not feedback.is_empty() else "Momo has a friend to visit now. There's always a place for you both here.")
		content.add_child(UI.label("Our picnic memory", 23, UI.TEAL))
		content.add_child(UI.label("A cuddle plush for Home.\nMomo can come over to play.", 21))
		add_action("Invite Momo Home", Art.PUPPIES["Shiba Inu"], invite_home)
		add_action("A light for everyone", preload("res://assets/ui/lighthouse.svg"), host.request_page.bind("Moment:Lighthouse"), Color("f9d8e2"))
		repeat_button = add_action("Picnic together again", preload("res://assets/ui/heart.svg"), repeat_picnic, Color("fff0bd"))
	elif WelcomeDay.prepared(state):
		speech.set_hint(feedback if not feedback.is_empty() else "Everyone helped make this day. Momo's waiting to say hello!")
		var captions = ["Welcome Momo", "Call and roll the ball", "Share our picnic"]
		var icons = ["heart", "play", "treat"]
		content.add_child(UI.label(["A familiar friend", "A skill to share", "A place for both of you"][state.picnic_step], 23, UI.TEAL))
		if rolling_ball and state.picnic_step == 1:
			picnic_button = add_action("Roll to Momo", preload("res://assets/ui/play.svg"), finish_ball_game)
		else:
			picnic_button = add_action(captions[state.picnic_step], load("res://assets/ui/" + icons[state.picnic_step] + ".svg"), enjoy_picnic)
		var reason = Game.activity_block_reason()
		if not reason.is_empty():
			content.add_child(UI.label(reason + ". We'll wait for you.", 21))
			add_action("Rest at Home", preload("res://assets/ui/rest.svg"), host.request_page.bind("Home"), Color("e1d9f6"))
	else:
		speech.set_hint("Meet Ben, June and Kai. Practice, make a friend, then return for our picnic.")
		content.add_child(UI.label("Getting ready together", 22))
		preparation("Practice Come with Ben", "lesson", "training_treat", host.start_welcome_lesson)
		preparation("Meet Momo at the Club", "momo", "heart", meet_momo)
		preparation("Pack treats with June", "treats", "treat", host.request_page.bind("Shop"))
		preparation("Play at Kai's beach", "beach", "shell", host.request_page.bind("Beach"))
		content.add_child(UI.label("No rush. Your progress stays saved.", 19, UI.TEAL))
	arrange.call_deferred()

func add_action(caption: String, picture: Texture2D, action: Callable, color: Color = Color("c8eddd")) -> Button:
	var button = UI.location_button(caption, picture, action, color)
	button.custom_minimum_size = Vector2(0, 68)
	button.add_theme_font_size_override("font_size", 1)
	button.get_meta("caption").add_theme_font_size_override("font_size", 21)
	button.get_meta("picture").offset_right = 62
	button.get_meta("caption").offset_left = 72
	content.add_child(button)
	return button

func preparation(caption: String, key: String, icon: String, action: Callable) -> void:
	var done: bool = Game.life.welcome_day[key]
	var button = add_action(("✓ " if done else "") + caption, load("res://assets/ui/" + icon + ".svg"), action, Color("c8eddd") if done else Color("c2ecf4"))
	button.disabled = done

func accept_invitation() -> void:
	feedback = WelcomeDay.begin(Game)
	refresh()

func meet_momo() -> void:
	var reply = IslandAdventure.choose_buddy(Game, "Momo")
	if IslandAdventure.companion(Game) == "Momo":
		host.request_page("Life:Playdate")
	else:
		host.show_feedback(reply)

func enjoy_picnic() -> void:
	if Game.life.welcome_day.picnic_step == 1 and Game.can_explore() and Game.cooldowns.get("WelcomePicnic", 0) <= 0:
		rolling_ball = true
		feedback = "Here comes " + Game.puppy_name + "! Drag the ball toward Momo, or tap Roll to Momo."
		host.habitat.prepare_welcome_roll()
		refresh()
		return
	advance_picnic()

func finish_ball_game() -> void:
	if not rolling_ball or Game.life.welcome_day.picnic_step != 1:
		return
	rolling_ball = false
	advance_picnic()

func advance_picnic() -> void:
	var result = WelcomeDay.picnic_action(Game)
	feedback = result.text if Game.save_error.is_empty() else Game.save_error
	if result.ok:
		if Game.save_error.is_empty():
			feedback = ["Momo knows you now! Look at those happy tails.", "A lovely recall! Momo rolls the ball back for another turn.", "You're part of the island now. There's always a place for you both."][result.step - 1]
		host.habitat.animate_welcome_picnic(result.step)
	refresh()

func repeat_picnic() -> void:
	if WelcomeDay.repeat_picnic(Game):
		feedback = "Another little day together. Momo is happy you came back!"
		refresh()

func invite_home() -> void:
	if WelcomeDay.invite_momo(Game):
		host.request_page("Home")

func arrange() -> void:
	if not is_instance_valid(actions_panel) or not is_instance_valid(speech_panel):
		return
	var safe = UI.safe_insets(20)
	var width = clampf(size.x * 0.29, 295, 370)
	actions_panel.position = Vector2(size.x - safe.right - width, safe.top + 100)
	actions_panel.size = Vector2(width, minf(content.get_combined_minimum_size().y + 32, maxf(120, size.y - safe.top - safe.bottom - 116)))
	action_scroll.custom_minimum_size.x = width - 40
	var speech_width = clampf(size.x * 0.26, 245, 320)
	speech_panel.position = Vector2(maxf(safe.left + 135, size.x * 0.27), safe.top + 90)
	speech_panel.custom_minimum_size.x = speech_width
	speech.custom_minimum_size.x = speech_width - 32
	speech_panel.size = Vector2(speech_width, speech_panel.get_combined_minimum_size().y)
	tail.position = Vector2(14, speech_panel.size.y - 2)
	var height = 340.0 * host.habitat.world.scale.y
	var portrait_width = height * portrait.texture.get_width() / portrait.texture.get_height()
	portrait.size = Vector2(portrait_width, height)
	var feet = host.habitat.world.position + Vector2(250,625)*host.habitat.world.scale
	portrait.position = Vector2(feet.x-portrait_width*0.5, feet.y-height)

func _process(_delta: float) -> void:
	if is_instance_valid(picnic_button):
		picnic_button.disabled = not Game.can_explore() or Game.cooldowns.get("WelcomePicnic", 0) > 0
		UI.button_wait(picnic_button, Game.cooldowns.get("WelcomePicnic", 0), 3.2)
	if is_instance_valid(repeat_button):
		repeat_button.disabled = Game.cooldowns.get("WelcomePicnic", 0) > 0
