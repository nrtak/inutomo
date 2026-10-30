extends VBoxContainer

signal finished
var return_place = "Beach"
var habitat: Habitat
var progress: Label
var souvenir: TextureRect
var status: CommandHint
var next_button: Button
var step = 0
var busy = false
var complete = false
var timer: Timer
const STOPS = ["Palm trail", "Seashell cove", "Sunset lookout"]
const MOMENTS = ["Mochi found a heart-shaped leaf.", "Tiny pawprints beside the tide.", "A salty breeze and a new favorite view."]

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	if habitat == null:
		habitat = preload("res://scenes/home.tscn").instantiate()
		habitat.location = "Beach"
		add_child(habitat)
	habitat.puppy.controlled = true
	habitat.puppy.position = WalkArea.SPAWNS.Beach
	habitat.puppy.target = habitat.puppy.position
	var checkpoint = Game.begin_outing("Walk")
	step = int(checkpoint.checkpoint)
	if step > 0:
		habitat.puppy.position = WalkArea.WALK_STOPS[step - 1]
		habitat.puppy.target = habitat.puppy.position
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)
	var panel = UI.card()
	panel.custom_minimum_size.x = 310
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(panel)
	var controls = UI.column(10)
	panel.add_child(controls)
	progress = UI.label("●○○  Palm trail", 24, UI.TEAL)
	controls.add_child(progress)
	souvenir = TextureRect.new()
	souvenir.texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][mini(step, 2)] + ".svg")
	souvenir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	souvenir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	souvenir.custom_minimum_size = Vector2(0, 78)
	controls.add_child(souvenir)
	habitat.set_walk_stop(mini(step, 2))
	status = UI.hint_label("Find three little treasures.", 22)
	controls.add_child(status)
	next_button = UI.icon_button("Head back" if step == 3 else "Explore", load("res://assets/ui/leaf.svg"), _next, Color("bdeab0"))
	next_button.get_meta("picture").texture = preload("res://assets/ui/home.svg") if step == 3 else souvenir.texture
	controls.add_child(next_button)
	if step > 0:
		progress.text = "%d of 3 discoveries saved" % step
		status.text = "Ready to carry on?"

func _next() -> void:
	if busy or complete:
		return
	busy = true
	next_button.disabled = true
	if step == 3:
		await return_up_path()
		return
	progress.text = "●".repeat(step + 1) + "○".repeat(2 - step) + "  " + STOPS[step]
	souvenir.texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][step] + ".svg")
	habitat.set_walk_stop(step)
	habitat.puppy.target = WalkArea.WALK_STOPS[step]
	status.text = "Strolling to " + STOPS[step] + "..."
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	status.text = Game.personalize(MOMENTS[step])
	Game.remember(MOMENTS[step])
	IslandLife.discover(Game, step)
	habitat.puppy.react_to_discovery()
	status.text += {"Curious":" A curious little sniff!", "Cuddly":" A little moment shared with you.", "Playful":" An excited tail wiggle!"}[IslandLife.personality(Game)]
	habitat.discovery.visible = false
	step += 1
	Game.checkpoint_outing(step)
	if step == 3:
		progress.text = "●●●  All found!"
		UI.button_caption(next_button, "Head back")
		next_button.get_meta("picture").texture = UI.place_icon(return_place)
	else:
		UI.button_caption(next_button, "Explore")
		next_button.get_meta("picture").texture = load("res://assets/ui/" + ["leaf", "shell", "sunset"][step] + ".svg")
	busy = false
	next_button.disabled = false

func return_up_path() -> void:
	progress.text = "Heading back to Palm trail"
	status.text = "A gentle stroll back up the coastal path."
	habitat.puppy.target = WalkArea.WALK_STOPS[0]
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	complete = true
	var before = {"coins":Game.coins,"happiness":Game.needs.Happiness,"points":Game.points}
	var rewarded = Game.complete_outing("Walk")
	progress.text = "Walk complete!"
	status.text = ("Three discoveries saved.\n"+Game.outing_result(before)) if rewarded else "Progress saved. No additional reward was issued."
	UI.button_caption(next_button, "Back to "+return_place)
	next_button.get_meta("picture").texture = UI.place_icon(return_place)
	next_button.pressed.disconnect(_next)
	next_button.pressed.connect(func(): finished.emit())
	busy = false
	next_button.disabled = false

func _notification(what: int) -> void:
	if not is_instance_valid(timer):
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		timer.paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		timer.paused = get_meta("dialog_paused", false)
