extends Node

signal updated
var native: Object
var status = "Real iPhone steps are available on a supported iPhone build."
var clock = 0.0
var pending = false
var wait_clock = 0.0

func _ready() -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("PuppyPedometer"):
		native = Engine.get_singleton("PuppyPedometer")
		status = "Connect iPhone steps when you're ready."
		if Game.walking.enabled:
			refresh()

func available() -> bool:
	return is_instance_valid(native) and native.is_available()

func enable() -> void:
	if not available():
		status = "Step counting needs a supported iPhone. All other activities remain available."
		updated.emit()
		return
	Game.walking.enabled = true
	Game.save_game()
	refresh()

func disable() -> void:
	Game.walking.enabled = false
	pending = false
	Game.save_game()
	status = "Step connection is off. Your journey is saved."
	updated.emit()

func refresh() -> void:
	if not Game.walking.enabled or not available() or pending:
		return
	pending = true
	clock = 0
	wait_clock = 0
	status = "Syncing today's iPhone steps…"
	native.query_today()
	updated.emit()

func _process(delta: float) -> void:
	if Game.paused_at > 0:
		return
	clock += delta
	if pending:
		wait_clock += delta
		var result: Dictionary = native.get_result()
		if result.get("ready",false):
			pending = false
			clock = 0
			if result.get("error","") != "":
				status = "Steps unavailable. Allow Motion & Fitness in iPhone Settings, or try Sync again."
			elif PuppySteps.accept(Game,str(result.get("day","")),result.get("steps",-1)):
				status = "Up to date. Carry your iPhone on your walks."
			else:
				status = "The date changed. Tap Sync to refresh today's steps."
			updated.emit()
		elif wait_clock >= 30:
			pending = false
			clock = 0
			status = "Step sync is taking longer. Tap Sync to retry."
			updated.emit()
	elif clock >= 30:
		clock = 0
		refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		pending = false
		call_deferred("refresh")
