extends Node

signal stage_reached(stage: String)
signal care_performed(kind: String)
signal changed
signal notice(message: String)

const SAVE_PATH = "user://puppy_island.json"
const NEEDS = ["Hunger", "Happiness", "Energy", "Cleanliness"]
const DECAY = [0.008, 0.005, 0.006, 0.0065]
const OFFLINE_DECAY_FACTOR = 0.15
const EVOLUTION_POINTS = 40
const EVOLUTION_SECONDS = 3600.0
const STAGE_POINTS = [0, 8, 20, 40]
const STAGE_SECONDS = [0.0, 600.0, 1800.0, 3600.0]
const STAGE_NAMES = ["Tiny puppy", "Young puppy", "Growing puppy", "Adult"]
var needs: Dictionary = {"Hunger": 80.0, "Happiness": 80.0, "Energy": 90.0, "Cleanliness": 85.0}
var puppy_name = "Mochi"
var name_chosen = false
var sound_enabled = true
var effects_volume = 0.7
var ambience_volume = 0.45
var active_outing: Dictionary = {}
var nap_actor: WeakRef
var pending_stage = ""
var coins = 50
var items: Dictionary = {"Treat": 0, "Toy": 0, "Brush": 0, "TrainingTreat": 0, "Shampoo": 0, "Bed": 0}
const PRICES = {"Treat": 10, "Toy": 25, "Brush": 20, "TrainingTreat": 8, "Shampoo": 12, "Bed": 40}
var breed = "Puppy"
var points = 0
var fetches = 0
var walks = 0
var intro_seen = false
var resting = false
var age_seconds = 0.0
var active_seconds = 0.0
var last_stage = "Tiny puppy"
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
	if paused_at > 0:
		return
	advance(delta)
	save_clock += delta
	if save_clock >= 15.0:
		save_clock = 0.0
		save_game()

func advance(seconds: float, active: bool = true) -> void:
	age_seconds += seconds
	if active:
		active_seconds += seconds
		update_growth()
	for i in NEEDS.size():
		var key: String = NEEDS[i]
		needs[key] = clampf(float(needs[key]) - seconds * DECAY[i] * (1.0 if active else OFFLINE_DECAY_FACTOR), 0, 100)
	if resting:
		needs.Energy = minf(100.0, float(needs.Energy) + seconds * (0.85 if items.get("Bed", 0) > 0 else 0.65))
		if needs.Energy >= 100.0:
			resting = false
	elif active and nap_actor != null and is_instance_valid(nap_actor.get_ref()) and nap_actor.get_ref().napping:
		needs.Energy = minf(100.0, float(needs.Energy) + seconds * 0.12)
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0, cooldowns[key] - seconds)
	changed.emit()

func action(kind: String) -> void:
	if kind == "Rest":
		resting = not resting
		say("A cozy nap under the island breeze." if resting else "Mochi is ready to explore!")
	else:
		if cooldowns.get(kind, 0.0) > 0:
			say("Give Mochi a moment before another " + kind.to_lower() + ".")
			return
		var target = {"Feed": "Hunger", "Play": "Happiness", "Care": "Cleanliness"}.get(kind, "")
		if target == "":
			return
		if float(needs[target]) >= 99.0:
			say("Mochi already feels great! Try another activity.")
			return
		if kind == "Play" and not can_explore():
			say("A little rest first. Mochi needs at least 15 energy.")
			return
		resting = false
		var bonus = 0.0
		if kind == "Feed" and items.Treat > 0 and needs.Hunger < 78.0:
			items.Treat -= 1
			bonus = 8.0
		elif kind == "Play" and items.Toy > 0:
			bonus = 4.0
		elif kind == "Care" and items.Brush > 0:
			bonus = 4.0
		needs[target] = minf(100, needs[target] + 22.0 + bonus)
		if kind == "Play":
			needs.Energy = maxf(0, needs.Energy - 6.0)
		cooldowns[kind] = 6.0
		grow("A little " + kind.to_lower() + " made today brighter.")
		say({"Feed": "Yum! A fresh bowl and a happy tummy.", "Play": "Happy paws, happy heart!", "Care": "All clean and fluffy!"}[kind])
	care_performed.emit(kind)
	changed.emit()
	save_game()

func personalize(text: String) -> String:
	return text.replace("Mochi", puppy_name)

func say(text: String) -> void:
	notice.emit(personalize(text))

func choose_name(text: String) -> void:
	var clean = ""
	for character in text.strip_edges():
		if character.unicode_at(0) >= 32 and character.unicode_at(0) != 127:
			clean += character
	puppy_name = clean.left(16) if not clean.is_empty() else "Mochi"
	name_chosen = true

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
	coins = mini(1000000, coins + 10 + (score if kind == "Fetch" else 0))
	grow("Finished " + kind + " together.")
	changed.emit()
	save_game()

func buy_item(kind: String) -> String:
	if not PRICES.has(kind):
		return "Choose an item from the shelves."
	var limit = Goods.ITEMS[kind].limit
	if items.get(kind, 0) >= limit:
		return "Your treat jar is full." if kind == "Treat" else "You already have this."
	if coins < PRICES[kind]:
		return "A few more coins first. Finish a Walk or Fetch to earn some."
	coins -= PRICES[kind]
	items[kind] = items.get(kind, 0) + 1
	remember("Picked up a " + kind.to_lower() + " at June's shop.")
	changed.emit()
	save_game()
	return Goods.ITEMS[kind].name + " added to your Bag. " + Goods.ITEMS[kind].description

func use_item(kind: String) -> String:
	if kind not in ["Treat", "TrainingTreat", "Shampoo"] or items.get(kind, 0) <= 0:
		return "That item is not available."
	if cooldowns.get("Goods", 0) > 0:
		return personalize("Give Mochi a moment before another item.")
	var need = {"Treat": "Hunger", "TrainingTreat": "Happiness", "Shampoo": "Cleanliness"}[kind]
	if needs[need] >= 99:
		return "Already feeling great. Your item stays in the Bag."
	items[kind] -= 1
	needs[need] = minf(100, needs[need] + {"Treat": 8, "TrainingTreat": 12, "Shampoo": 25}[kind])
	if kind == "Treat":
		needs.Happiness = minf(100, needs.Happiness + 4)
	resting = false
	cooldowns.Goods = 12.0
	remember("Enjoyed " + Goods.ITEMS[kind].name.to_lower() + ".")
	care_performed.emit({"Treat": "Feed", "TrainingTreat": "Play", "Shampoo": "Care"}[kind])
	changed.emit()
	save_game()
	return Goods.ITEMS[kind].name + " used. " + need + " restored."

func begin_outing(kind: String) -> Dictionary:
	if active_outing.get("kind", "") != kind:
		active_outing = {"kind": kind, "checkpoint": 0, "score": 0}
		save_game()
	return active_outing.duplicate()

func checkpoint_outing(checkpoint: int, score: int = 0) -> void:
	if active_outing.is_empty():
		return
	active_outing.checkpoint = checkpoint
	active_outing.score = score
	save_game()

func complete_outing(kind: String, score: int = 0) -> bool:
	if active_outing.get("kind", "") != kind or int(active_outing.get("checkpoint", 0)) < 3:
		return false
	active_outing = {}
	finish_activity(kind, score)
	return true

func clinic_checkup() -> String:
	var lowest = NEEDS[0]
	for key in NEEDS:
		if needs[key] < needs[lowest]:
			lowest = key
	var advice = {"Hunger": "A meal at Home would feel lovely.", "Happiness": "A little Play, Fetch or a Walk would brighten the day.", "Energy": "A cozy Rest at Home is a good next step.", "Cleanliness": "Try Care at Home, or a gentle grooming here."}[lowest]
	return personalize("Let's check on Mochi!\n\nHunger: %d / Happiness: %d\nEnergy: %d / Cleanliness: %d\n\n" % [needs.Hunger, needs.Happiness, needs.Energy, needs.Cleanliness]) + ("All four needs look comfortable. Keep up the gentle care!" if needs[lowest] >= 75 else advice)

func clinic_groom() -> String:
	if needs.Cleanliness >= 99:
		return personalize("Mochi already feels clean and fluffy!")
	if coins < 12:
		return "Grooming costs 12 coins. Care at Home is always free."
	coins -= 12
	needs.Cleanliness = minf(100, needs.Cleanliness + 25)
	remember("A gentle grooming at Leah's clinic.")
	care_performed.emit("Care")
	changed.emit()
	save_game()
	return "Fresh and fluffy! Cleanliness restored."

func prediction() -> String:
	return "Shiba Inu" if walks > fetches else "Golden Retriever"

func stage_index() -> int:
	if breed != "Puppy":
		return 3
	for index in [2, 1]:
		if points >= STAGE_POINTS[index] and active_seconds >= STAGE_SECONDS[index]:
			return index
	return 0

func growth_stage() -> String:
	return STAGE_NAMES[stage_index()]

func growth_fraction() -> float:
	if breed != "Puppy":
		return 1.0
	return minf(clampf(float(points) / EVOLUTION_POINTS, 0, 1), clampf(active_seconds / EVOLUTION_SECONDS, 0, 1))

func next_growth_hint() -> String:
	if breed != "Puppy":
		return "Keep making little memories together."
	var next = stage_index() + 1
	var care_left = maxi(0, STAGE_POINTS[next] - points)
	var minutes_left = ceili(maxf(0, STAGE_SECONDS[next] - active_seconds) / 60.0)
	return "Next: %s / %d more care moments and %d more minutes together." % [STAGE_NAMES[next], care_left, minutes_left]

func remember(entry: String) -> void:
	var minutes = int(active_seconds / 60)
	journal.push_front("[%02d:%02d] %s" % [minutes / 60, minutes % 60, personalize(entry)])
	journal = journal.slice(0, 32)

func grow(entry: String) -> void:
	points += 1
	remember(entry)
	update_growth()

func update_growth() -> void:
	if breed == "Puppy" and points >= EVOLUTION_POINTS and active_seconds >= EVOLUTION_SECONDS:
		breed = prediction()
		collection.append({"name": puppy_name, "breed": breed})
		remember("Mochi grew into a " + breed + "!")
		say("A new chapter! Mochi is now a " + breed + ".")
	var stage = growth_stage()
	if stage != last_stage:
		var promoted = STAGE_NAMES.find(stage) > STAGE_NAMES.find(last_stage)
		last_stage = stage
		if promoted:
			pending_stage = stage
			stage_reached.emit(stage)
			if breed == "Puppy":
				remember("A new chapter: " + stage + ".")

func save_game() -> bool:
	var data = {"version": 1, "needs": needs, "name": puppy_name, "breed": breed,
		"coins": coins, "items": items, "cooldowns": cooldowns, "active_outing": active_outing,
		"effects_volume": effects_volume, "ambience_volume": ambience_volume,
		"name_chosen": name_chosen, "sound_enabled": sound_enabled, "pending_stage": pending_stage,
		"active_seconds": active_seconds, "points": points, "fetches": fetches, "walks": walks, "intro_seen": intro_seen,
		"resting": resting, "age_seconds": age_seconds, "collection": collection,
		"journal": journal, "saved_at": Time.get_unix_time_from_system()}
	var file = FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Could not save. Your progress is still in memory."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		save_error = "Could not finish saving. Your progress is still in memory."
		return false
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
	if not data.get("name_chosen", false) is bool or not data.get("sound_enabled", true) is bool:
		return false
	if data.get("pending_stage", "") not in ["", "Young puppy", "Growing puppy", "Adult"]:
		return false
	var saved_coins = data.get("coins", 50)
	if not (saved_coins is int or saved_coins is float) or not is_finite(float(saved_coins)) or saved_coins < 0 or saved_coins > 1000000 or float(saved_coins) != floorf(saved_coins):
		return false
	var saved_items = data.get("items", {"Treat": 0, "Toy": 0, "Brush": 0})
	if not saved_items is Dictionary:
		return false
	for kind in PRICES:
		var count = saved_items.get(kind, 0)
		if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > Goods.ITEMS[kind].limit or float(count) != floorf(count):
			return false
	for key in ["effects_volume", "ambience_volume"]:
		var level = data.get(key, 0.7 if key == "effects_volume" else 0.45)
		if not (level is float or level is int) or not is_finite(float(level)) or level < 0 or level > 1:
			return false
	var saved_cooldowns = data.get("cooldowns", {})
	if not saved_cooldowns is Dictionary:
		return false
	for key in saved_cooldowns:
		var remaining = saved_cooldowns[key]
		if key not in ["Feed", "Play", "Care", "Goods"] or not (remaining is float or remaining is int) or not is_finite(float(remaining)) or remaining < 0 or remaining > 12:
			return false
	var outing = data.get("active_outing", {})
	if not outing is Dictionary:
		return false
	if not outing.is_empty():
		if outing.get("kind") not in ["Fetch", "Walk"]:
			return false
		for key in ["checkpoint", "score"]:
			var number = outing.get(key)
			if not (number is float or number is int) or not is_finite(float(number)) or number < 0 or number > 3 or float(number) != floorf(number):
				return false
		if outing.score > outing.checkpoint or (outing.kind == "Walk" and outing.score != 0):
			return false
	var active_time = data.get("active_seconds", 0.0)
	if not (active_time is float or active_time is int) or not is_finite(float(active_time)) or active_time < 0:
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
	puppy_name = data.name.left(16)
	coins = int(data.get("coins", 50))
	items = {}
	for kind in PRICES:
		items[kind] = int(data.get("items", {}).get(kind, 0))
	cooldowns = data.get("cooldowns", {}).duplicate()
	active_outing = data.get("active_outing", {}).duplicate()
	effects_volume = float(data.get("effects_volume", 0.7))
	ambience_volume = float(data.get("ambience_volume", 0.45))
	name_chosen = data.get("name_chosen", data.intro_seen)
	sound_enabled = data.get("sound_enabled", true)
	pending_stage = data.get("pending_stage", "")
	breed = data.breed
	points = mini(int(data.points), 100000)
	fetches = mini(int(data.fetches), 100000)
	walks = mini(int(data.walks), 100000)
	intro_seen = data.intro_seen
	resting = data.resting
	age_seconds = float(data.age_seconds)
	active_seconds = float(data.get("active_seconds", 0.0))
	last_stage = growth_stage()
	collection = data.collection.slice(0, 32)
	journal = data.journal.slice(0, 32)
	# Offline needs are gentle and capped at two hours; no death or punishment.
	advance(clampf(Time.get_unix_time_from_system() - float(data.saved_at), 0, 7200), false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		paused_at = Time.get_unix_time_from_system()
		save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED and paused_at > 0:
		advance(clampf(Time.get_unix_time_from_system() - paused_at, 0, 7200), false)
		paused_at = 0.0
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
