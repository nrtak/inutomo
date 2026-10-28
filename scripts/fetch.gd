extends VBoxContainer

signal finished
var habitat: Habitat
var bar: ProgressBar
var progress: Label
var status: CommandHint
var throw_button: Button
var phase = 0.0
var busy = false
var rounds = 0
var score = 0
var complete = false
var timer: Timer

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	if habitat == null:
		habitat = preload("res://scenes/home.tscn").instantiate()
		habitat.location = "Park"
		add_child(habitat)
	habitat.puppy.controlled = true
	habitat.puppy.position = WalkArea.SPAWNS.Park
	habitat.puppy.target = habitat.puppy.position
	var checkpoint = Game.begin_outing("Fetch")
	rounds = int(checkpoint.checkpoint)
	score = int(checkpoint.score)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)
	var panel = UI.card()
	panel.custom_minimum_size.x = 430
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(panel)
	var controls = UI.column(8)
	panel.add_child(controls)
	progress = UI.label("Throw 1 of 3", 24, UI.TEAL)
	controls.add_child(progress)
	status = UI.hint_label("Tap in the green zone near 70% power.", 24)
	controls.add_child(status)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 32
	bar.show_percentage = true
	bar.add_theme_stylebox_override("fill", UI.style(UI.PINK, 12))
	controls.add_child(bar)
	var sweet_zone = ColorRect.new()
	sweet_zone.color = Color(0.3, 0.8, 0.4, 0.35)
	sweet_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweet_zone.anchor_left = 0.52
	sweet_zone.anchor_right = 0.88
	sweet_zone.anchor_bottom = 1
	bar.add_child(sweet_zone)
	progress.text = "Throw %d of 3" % mini(3, rounds + 1)
	throw_button = UI.icon_button("Throw the ball", preload("res://assets/ui/play.svg"), _throw, Color("c8eddd"))
	controls.add_child(throw_button)
	if rounds >= 3:
		call_deferred("finish_fetch")

func _process(delta: float) -> void:
	if Game.paused_at > 0:
		return
	if not busy and not complete:
		phase += delta * 2.2
		bar.value = (sin(phase) + 1) * 50

func _throw() -> void:
	if busy or complete:
		return
	busy = true
	throw_button.disabled = true
	var good = absf(bar.value - 70) <= 18
	if good:
		score += 1
	rounds += 1
	progress.text = "Bringing back throw %d of 3" % rounds
	status.text = Game.personalize("Great throw! Go, Mochi!" if good else "A little wobbly, but Mochi is on it!")
	habitat.ball.visible = true
	habitat.ball.position = WalkArea.nearest(habitat.puppy.walk_area, Vector2(370 + bar.value * 3.3, 565))
	habitat.puppy.target = habitat.ball.position
	timer.start(3.0)
	await timer.timeout
	if not is_inside_tree():
		return
	habitat.ball.visible = false
	habitat.puppy.target = WalkArea.SPAWNS.Park
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	Game.checkpoint_outing(rounds, score)
	if rounds >= 3:
		finish_fetch()
	else:
		progress.text = "Throw %d of 3" % (rounds + 1)
		status.text = "Aim for the green zone near 70% power!"
	busy = false
	throw_button.disabled = false

func finish_fetch() -> void:
	if complete:
		return
	complete = true
	Game.complete_outing("Fetch", score)
	progress.text = "Fetch complete! %d of 3 great throws" % score
	status.text = "Happy paws! You earned %d coins." % (10 + score)
	UI.button_caption(throw_button, "Back home")
	throw_button.get_meta("picture").texture = UI.place_icon("Home")
	throw_button.pressed.disconnect(_throw)
	throw_button.pressed.connect(func(): finished.emit())

func _notification(what: int) -> void:
	if not is_instance_valid(timer):
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		timer.paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		timer.paused = get_meta("dialog_paused", false)
