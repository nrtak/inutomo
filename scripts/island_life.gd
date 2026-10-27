class_name IslandLife
extends RefCounted

const PEOPLE = {"Nora": "Care", "Ben": "Fetch", "June": "Feed", "Leah": "Care", "Owen": "Walk"}
const COMMANDS = ["Sit", "Stay", "Come"]
const KEEPSAKES = ["Heart leaf", "Pearl shell", "Sea glass"]
const KEEPSAKE_ICONS = ["leaf", "shell", "sea_glass"]
const PERSONALITIES = ["Curious", "Cuddly", "Playful"]
static func fresh() -> Dictionary:
	return {"accessory": "", "bed": "", "toy": "", "spot": 1, "training": {"Sit": 0, "Stay": 0, "Come": 0}, "friends": {}, "favors": {}, "keepsakes": [], "photos": [], "day": "", "daily": {}, "event_claimed": ""}

static func today() -> String:
	return Time.get_date_string_from_system(false)

static func personality(game: Node) -> String:
	return PERSONALITIES[absi(game.puppy_name.hash()) % PERSONALITIES.size()]

static func favorite(game: Node, category: String) -> String:
	var choices: Array = {"Food": ["Treat", "TrainingTreat", "CelebrationTreat"], "Toys": ["Toy", "PlushToy", "TugRope"]}.get(category, [])
	return choices[absi((game.puppy_name + category).hash()) % choices.size()] if not choices.is_empty() else ""

static func refresh_day(game: Node) -> void:
	if game.life.day != today():
		game.life.day = today()
		game.life.daily = {}

static func record(game: Node, action: String) -> void:
	refresh_day(game)
	game.life.daily[action] = mini(1000, int(game.life.daily.get(action, 0)) + 1)

static func talk(game: Node, person: String) -> void:
	if not PEOPLE.has(person):
		return
	var friend: Dictionary = game.life.friends.get(person, {"hearts": 0, "talked": ""})
	if today() > friend.talked:
		friend.hearts = mini(20, friend.hearts + 1)
		friend.talked = today()
		game.life.friends[person] = friend
		game.save_game()

static func favor(game: Node, person: String) -> String:
	if not PEOPLE.has(person):
		return "Meet an island friend first."
	refresh_day(game)
	var task: Dictionary = game.life.favors.get(person, {})
	if task.get("claimed", "") >= today():
		return "Thank you! Come back another day."
	if task.get("day", "") != today():
		task = {"day": today(), "start": game.life.daily.get(PEOPLE[person], 0), "claimed": task.get("claimed", "")}
		game.life.favors[person] = task
		game.save_game()
		return "A little favor: finish " + PEOPLE[person] + " together, then check back here."
	if int(game.life.daily.get(PEOPLE[person], 0)) <= int(task.start):
		return "Finish " + PEOPLE[person] + " together, then return for your thank-you."
	task.claimed = today()
	game.life.favors[person] = task
	var friend: Dictionary = game.life.friends.get(person, {"hearts": 0, "talked": ""})
	friend.hearts = mini(20, friend.hearts + 2)
	game.life.friends[person] = friend
	game.coins = mini(1000000, game.coins + 8)
	game.remember("Helped " + person + " with a little favor.")
	game.changed.emit()
	game.save_game()
	return person + " says thank you! You earned 8 coins and friendship."

static func favor_status(game: Node, person: String) -> Dictionary:
	refresh_day(game)
	var task: Dictionary = game.life.favors.get(person, {})
	if task.get("claimed", "") >= today():
		return {"state": "claimed", "text": "Thank-you collected today.", "button": "Done today"}
	if task.get("day", "") != today():
		return {"state": "ask", "text": "A little favor is available.", "button": "Ask for a favor"}
	var done = int(game.life.daily.get(PEOPLE[person], 0)) > int(task.start)
	return {"state": "ready" if done else "active", "text": PEOPLE[person] + " together\n" + ("1 of 1 completed. Reward ready!" if done else "0 of 1 completed."), "button": "Collect reward" if done else "Check progress"}

static func delete_photo(game: Node, filename: String) -> String:
	if filename not in game.life.photos or "/" in filename or "\\" in filename or ".." in filename:
		return "That photo is not in this album."
	var path = "user://photos/" + filename
	if FileAccess.file_exists(path):
		var error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			return "Photo could not be deleted. Your album is unchanged."
	game.life.photos.erase(filename)
	if not game.save_game():
		return "Photo deleted. " + game.save_error
	return "Photo deleted. There is room for another memory."

static func train(game: Node, command: String) -> String:
	if command not in COMMANDS:
		return "Choose Sit, Stay or Come."
	if not game.can_explore():
		return "A little rest first. Training needs 15 Energy."
	if game.cooldowns.get("Training", 0) > 0:
		return "Let those paws take a breather before another lesson."
	if game.life.training[command] >= 5:
		game.care_performed.emit(command if command != "Stay" else "Sit")
		return "A lovely " + command.to_lower() + "! This command is already learned."
	game.cooldowns.Training = 20.0
	game.life.training[command] += 1
	game.needs.Energy = maxf(0, game.needs.Energy - 2)
	game.needs.Happiness = minf(100, game.needs.Happiness + 3)
	game.care_performed.emit(command if command != "Stay" else "Sit")
	game.remember("Practiced " + command.to_lower() + " with Ben.")
	game.changed.emit()
	game.save_game()
	return "Good " + command.to_lower() + "! " + str(game.life.training[command]) + " of 5 lessons."

static func discover(game: Node, index: int) -> void:
	var item: String = KEEPSAKES[clampi(index, 0, 2)]
	if item not in game.life.keepsakes:
		game.life.keepsakes.append(item)
		game.remember("Collected a " + item.to_lower() + " for Home.")

static func event_info() -> Dictionary:
	var weekday = int(Time.get_datetime_dict_from_system(false).weekday)
	if weekday in [0, 1]:
		return {"name": "Puppy Club picnic", "tasks": ["Feed", "Pet", "Walk"]}
	if weekday in [2, 3]:
		return {"name": "Beach playdate", "tasks": ["Walk", "Fetch", "Pet"]}
	return {"name": "Puppy celebration", "tasks": ["Care", "Play", "Feed"]}

static func claim_event(game: Node) -> String:
	refresh_day(game)
	if game.life.event_claimed >= today():
		return "Today's celebration is complete. Enjoy the island!"
	for action in event_info().tasks:
		if game.life.daily.get(action, 0) == 0:
			return "Enjoy each activity on today's event card first."
	game.life.event_claimed = today()
	game.coins = mini(1000000, game.coins + 15)
	game.remember("Enjoyed the " + event_info().name.to_lower() + ".")
	game.changed.emit()
	game.save_game()
	return "A day to remember! You earned 15 coins."

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["accessory", "bed", "toy", "day", "event_claimed"]:
		if not data.get(key, "") is String:
			return false
	for pair in [["accessory", "Accessories"], ["bed", "Comfort"], ["toy", "Toys"]]:
		var item: String = data.get(pair[0], "")
		if item != "" and (not Goods.ITEMS.has(item) or Goods.ITEMS[item].category != pair[1]):
			return false
	var spot = data.get("spot", 1)
	if not (spot is int or spot is float) or spot < 0 or spot > 2 or spot != floorf(spot):
		return false
	for key in ["training", "friends", "favors", "daily"]:
		if not data.get(key, {}) is Dictionary:
			return false
	for command in COMMANDS:
		var level = data.get("training", {}).get(command, 0)
		if not (level is int or level is float) or level < 0 or level > 5 or level != floorf(level):
			return false
	for person in data.get("friends", {}):
		var friend = data.friends[person]
		if not PEOPLE.has(person) or not friend is Dictionary or not friend.get("talked") is String:
			return false
		var hearts = friend.get("hearts")
		if not (hearts is int or hearts is float) or hearts < 0 or hearts > 20 or hearts != floorf(hearts):
			return false
	for person in data.get("favors", {}):
		var task = data.favors[person]
		if not PEOPLE.has(person) or not task is Dictionary or not task.get("day") is String or not task.get("claimed", "") is String:
			return false
		var start = task.get("start")
		if not (start is int or start is float) or start < 0 or start > 1000 or start != floorf(start):
			return false
	for action in data.get("daily", {}):
		var count = data.daily[action]
		if action not in ["Feed", "Play", "Care", "Pet", "Walk", "Fetch", "Rest"] or not (count is int or count is float) or count < 0 or count > 1000 or count != floorf(count):
			return false
	for key in ["keepsakes", "photos"]:
		if not data.get(key, []) is Array or data.get(key, []).size() > (3 if key == "keepsakes" else 20):
			return false
		var unique = {}
		for entry in data.get(key, []):
			if not entry is String or unique.has(entry):
				return false
			unique[entry] = true
	for item in data.get("keepsakes", []):
		if item not in KEEPSAKES:
			return false
	for photo in data.get("photos", []):
		if not photo is String or not photo.begins_with("puppy_photo_") or "/" in photo or "\\" in photo or ".." in photo or not photo.ends_with(".png"):
			return false
	return true

static func normalized(data: Dictionary) -> Dictionary:
	var result = fresh()
	for key in result:
		if data.has(key):
			result[key] = data[key].duplicate(true) if data[key] is Dictionary or data[key] is Array else data[key]
	for command in COMMANDS:
		result.training[command] = int(result.training.get(command, 0))
	result.spot = int(result.spot)
	for person in result.friends:
		result.friends[person].hearts = int(result.friends[person].hearts)
	for person in result.favors:
		result.favors[person].start = int(result.favors[person].start)
	for action in result.daily:
		result.daily[action] = int(result.daily[action])
	return result
