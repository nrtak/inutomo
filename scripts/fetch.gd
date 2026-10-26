extends VBoxContainer

signal finished
var habitat: Habitat
var bar: ProgressBar
var status: Label
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
	habitat.puppy.position = Vector2(500, 550)
	habitat.puppy.target = habitat.puppy.position
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
	status = UI.label("Three throws! Tap near 70% power.", 24)
	controls.add_child(status)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 32
	bar.show_percentage = true
	bar.add_theme_stylebox_override("fill", UI.style(UI.PINK, 12))
	controls.add_child(bar)
	throw_button = UI.button("Throw the ball", _throw, Color("bdeab0"))
	controls.add_child(throw_button)

func _process(delta: float) -> void:
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
	status.text = "Great throw! Go, Mochi!" if good else "A little wobbly, but Mochi is on it!"
	habitat.ball.visible = true
	habitat.ball.position = Vector2(300 + bar.value * 3.3, 530)
	habitat.puppy.target = habitat.ball.position
	timer.start(3.0)
	await timer.timeout
	if not is_inside_tree():
		return
	habitat.ball.visible = false
	habitat.puppy.target = Vector2(500, 550)
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	if rounds >= 3:
		complete = true
		Game.finish_activity("Fetch", score)
		status.text = "%d / 3 great throws! Happiness up. Golden Retriever affinity up." % score
		throw_button.text = "Back home"
		throw_button.pressed.disconnect(_throw)
		throw_button.pressed.connect(func(): finished.emit())
	else:
		status.text = "Throw %d of 3. Aim for 70%% power!" % (rounds + 1)
	busy = false
	throw_button.disabled = false
