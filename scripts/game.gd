extends Node

signal changed
signal notice(message: String)

const SAVE_PATH = "user://puppy_island.json"
const NEEDS = ["Hunger", "Happiness", "Energy", "Cleanliness"]
const DECAY = [0.045, 0.025, 0.03, 0.035]
const EVOLUTION_POINTS = 12
var needs: Dictionary = {"Hunger": 80.0, "Happiness": 80.0, "Energy": 90.0, "Cleanliness": 85.0}
var puppy_name = "Mochi"
var breed = "Puppy"
var points = 0
var fetches = 0
var walks = 0
var intro_seen = false
var resting = false
var age_seconds = 0.0
var collection: Array = []
var journal: Array = []
var cooldowns: Dictionary = {}
var save_clock = 0.0
var save_error = ""
var storage_path = SAVE_PATH
var paused_at = 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	advance(delta)
	save_clock += delta
	if save_clock >= 15.0:
		save_clock = 0.0
		save_game()

func advance(seconds: float) -> void:
	age_seconds += seconds
	for i in NEEDS.size():
		var key: String = NEEDS[i]
		needs[key] = clampf(float(needs[key]) - seconds * DECAY[i], 0, 100)
	if resting:
		needs.Energy = minf(100.0, float(needs.Energy) + seconds * 0.65)
		if needs.Energy >= 100.0:
			resting = false
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0, cooldowns[key] - seconds)
	changed.emit()

func action(kind: String) -> void:
	if kind == "Rest":
		resting = not resting
		notice.emit("A cozy nap under the island breeze." if resting else "Mochi is ready to explore!")
	else:
		if cooldowns.get(kind, 0.0) > 0:
			notice.emit("Give Mochi a moment before another " + kind.to_lower() + ".")
			return
		var target = {"Feed": "Hunger", "Play": "Happiness", "Care": "Cleanliness"}.get(kind, "")
		if target == "":
			return
		if float(needs[target]) >= 99.0:
			notice.emit("Mochi already feels great! Try another activity.")
			return
		if kind == "Play" and not can_explore():
			notice.emit("A little rest first. Mochi needs at least 15 energy.")
			return
		resting = false
		needs[target] = minf(100, needs[target] + 22.0)
		if kind == "Play":
			needs.Energy = maxf(0, needs.Energy - 6.0)
		cooldowns[kind] = 6.0
		grow("A little " + kind.to_lower() + " made today brighter.")
		notice.emit({"Feed": "Yum! A fresh bowl and a happy tummy.", "Play": "Happy paws, happy heart!", "Care": "All clean and fluffy!"}[kind])
	changed.emit()
	save_game()

func can_explore() -> bool:
	return needs.Energy >= 15.0 and not resting

func finish_activity(kind: String, score: int = 0) -> void:
	if kind == "Fetch":
		fetches += 1
		needs.Happiness = minf(100, needs.Happiness + 12 + score * 2)
	else:
		walks += 1
		needs.Happiness = minf(100, needs.Happiness + 15)
	needs.Energy = maxf(0, needs.Energy - 10)
	needs.Cleanliness = maxf(0, needs.Cleanliness - 8)
	grow("Finished " + kind + " together.")
	changed.emit()
	save_game()

func prediction() -> String:
	return "Shiba Inu" if walks > fetches else "Golden Retriever"

func grow(entry: String) -> void:
	points += 1
	journal.push_front(entry)
	journal = journal.slice(0, 16)
	if breed == "Puppy" and points >= EVOLUTION_POINTS:
		breed = prediction()
		collection.append({"name": puppy_name, "breed": breed})
		journal.push_front("Mochi grew into a " + breed + "!")
		notice.emit("A new chapter! Mochi is now a " + breed + ".")

func save_game() -> bool:
	var data = {"version": 1, "needs": needs, "name": puppy_name, "breed": breed,
		"points": points, "fetches": fetches, "walks": walks, "intro_seen": intro_seen,
		"resting": resting, "age_seconds": age_seconds, "collection": collection,
		"journal": journal, "saved_at": Time.get_unix_time_from_system()}
	var file = FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Could not save. Your progress is still in memory."
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var absolute = ProjectSettings.globalize_path(storage_path)
	if FileAccess.file_exists(storage_path) and valid_save(read_data(storage_path)):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	var result = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	save_error = "" if result == OK else "Could not replace the save file."
	return result == OK

func read_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

func valid_save(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1:
		return false
	if not data.get("needs") is Dictionary:
		return false
	for key in NEEDS:
		var value = data.needs.get(key)
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
	if data.get("breed") not in ["Puppy", "Shiba Inu", "Golden Retriever"]:
		return false
	for key in ["points", "fetches", "walks", "age_seconds", "saved_at"]:
		var value = data.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or value < 0:
			return false
	if not data.get("intro_seen") is bool or not data.get("resting") is bool:
		return false
	if not data.get("collection") is Array or not data.get("journal") is Array:
		return false
	for dog in data.collection:
		if not dog is Dictionary or not dog.get("name") is String or dog.get("breed") not in Art.PUPPIES:
			return false
	for entry in data.journal:
		if not entry is String:
			return false
	return data.get("name") is String

func load_game() -> void:
	var data = read_data(storage_path)
	if not valid_save(data):
		data = read_data(storage_path + ".bak")
	if not valid_save(data):
		if FileAccess.file_exists(storage_path):
			save_error = "Save could not be read. Starting a fresh island."
		return
	for key in NEEDS:
		needs[key] = clampf(float(data.needs[key]), 0, 100)
	puppy_name = data.name.left(24)
	breed = data.breed
	points = mini(int(data.points), 100000)
	fetches = mini(int(data.fetches), 100000)
	walks = mini(int(data.walks), 100000)
	intro_seen = data.intro_seen
	resting = data.resting
	age_seconds = float(data.age_seconds)
	collection = data.collection.slice(0, 32)
	journal = data.journal.slice(0, 16)
	# Offline needs are gentle and capped at two hours; no death or punishment.
	advance(clampf(Time.get_unix_time_from_system() - float(data.saved_at), 0, 7200))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		paused_at = Time.get_unix_time_from_system()
		save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED and paused_at > 0:
		advance(clampf(Time.get_unix_time_from_system() - paused_at, 0, 7200))
		paused_at = 0.0
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
