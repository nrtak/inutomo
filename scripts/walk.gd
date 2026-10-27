extends VBoxContainer

signal finished
var habitat: Habitat
var progress: Label
var souvenir: TextureRect
var status: Label
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
	panel.custom_minimum_size.x = 430
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(panel)
	var controls = UI.column(10)
	panel.add_child(controls)
	progress = UI.label("Stop 1 / 3 / Palm trail", 24, UI.TEAL)
	controls.add_child(progress)
	souvenir = TextureRect.new()
	souvenir.texture = load("res://assets/ui/leaf.svg")
	souvenir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	souvenir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	souvenir.custom_minimum_size = Vector2(0, 48)
	controls.add_child(souvenir)
	habitat.set_walk_stop(mini(step, 2))
	status = UI.label("A leafy path, a seashell cove, then a sunset view.", 24)
	controls.add_child(status)
	next_button = UI.button("Walk back up the path" if step == 3 else "Explore " + STOPS[step], _next, Color("bdeab0"))
	controls.add_child(next_button)
	if step > 0:
		progress.text = "Resume / %d of 3 discoveries saved" % step
		status.text = "Your last completed discovery was saved. Let's carry on."

func _next() -> void:
	if busy or complete:
		return
	busy = true
	next_button.disabled = true
	if step == 3:
		await return_up_path()
		return
	progress.text = "Stop %d / 3 / %s" % [step + 1, STOPS[step]]
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
	habitat.discovery.visible = false
	step += 1
	Game.checkpoint_outing(step)
	if step == 3:
		progress.text = "Three discoveries / time to head back"
		next_button.text = "Walk back up the path"
	else:
		next_button.text = "Explore " + STOPS[step]
	busy = false
	next_button.disabled = false

func return_up_path() -> void:
	progress.text = "Heading back / Palm trail"
	status.text = "A gentle stroll back up the coastal path."
	habitat.puppy.target = WalkArea.WALK_STOPS[0]
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	complete = true
	Game.complete_outing("Walk")
	progress.text = "Walk complete / back at Palm trail"
	status.text = "Three memories saved to Journal. Happiness restored, +1 care moment and 10 coins. Shiba Inu affinity up."
	next_button.text = "Back home"
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
		timer.paused = false
