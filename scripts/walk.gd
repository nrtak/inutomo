extends VBoxContainer

signal finished
var habitat: Habitat
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
	var controls = UI.column(10)
	panel.add_child(controls)
	status = UI.label("Three discoveries along the coastal path.", 24)
	controls.add_child(status)
	next_button = UI.button("Explore " + STOPS[0], _next, Color("bdeab0"))
	controls.add_child(next_button)

func _next() -> void:
	if busy or complete:
		return
	busy = true
	next_button.disabled = true
	habitat.puppy.target = Vector2(380 if step % 2 == 0 else 650, 540)
	status.text = "Strolling to " + STOPS[step] + "..."
	timer.start(2.5)
	await timer.timeout
	if not is_inside_tree():
		return
	status.text = MOMENTS[step]
	step += 1
	if step == 3:
		complete = true
		Game.finish_activity("Walk")
		status.text += "\nWalk complete! Shiba Inu affinity up."
		next_button.text = "Back home"
		next_button.pressed.disconnect(_next)
		next_button.pressed.connect(func(): finished.emit())
	else:
		next_button.text = "Explore " + STOPS[step]
	busy = false
	next_button.disabled = false
