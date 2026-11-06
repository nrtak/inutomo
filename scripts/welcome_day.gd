class_name WelcomeDay
extends RefCounted

# This invitation has no calendar deadline. Ordinary play advances it across visits.
static func fresh() -> Dictionary:
	return {"started":false, "lesson":false, "momo":false, "treats":false, "beach":false, "picnic_step":0, "celebrated":false, "picnics":0, "guest":false}

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["started", "lesson", "momo", "treats", "beach", "celebrated", "guest"]:
		if not data.get(key, false) is bool:
			return false
	for key in ["picnic_step", "picnics"]:
		if not IslandAdventure.integer(data.get(key, 0), 3 if key == "picnic_step" else 1000):
			return false
	var state = normalized(data)
	if not state.started and (state.lesson or state.momo or state.treats or state.beach or state.picnic_step > 0 or state.celebrated):
		return false
	if state.picnic_step > 0 and not prepared(state):
		return false
	if state.celebrated != (state.picnics > 0) or (state.picnic_step == 3 and not state.celebrated):
		return false
	return not state.guest or state.celebrated

static func normalized(data: Dictionary) -> Dictionary:
	var state = fresh()
	for key in state:
		if data.has(key):
			state[key] = data[key]
	state.picnic_step = int(state.picnic_step)
	state.picnics = int(state.picnics)
	return state

static func prepared(state: Dictionary) -> bool:
	return state.lesson and state.momo and state.treats and state.beach

static func begin(game: Node) -> String:
	var state: Dictionary = game.life.welcome_day
	if not state.started:
		state.started = true
		state.lesson = int(game.life.training.Come) > 0
		state.momo = IslandAdventure.buddy_visits(game, "Momo") > 0
		state.beach = not game.life.beach.done.is_empty() or game.life.moments.shell
		game.remember("Nora invited us to help with Island Welcome Day.")
		game.changed.emit()
		game.save_game()
	return "Let's make a place for every puppy. Ben, June and Kai are helping, too. Take your time; we'll save your place."

static func record_task(game: Node, task: String) -> void:
	var state: Dictionary = game.life.get("welcome_day", {})
	if not state.get("started", false) or state.get("celebrated", false):
		return
	if task == "Training" and int(game.life.training.Come) > 0:
		state.lesson = true
	elif task == "Playdate" and IslandAdventure.companion(game) == "Momo":
		state.momo = true
	elif task == "Beach":
		state.beach = true
		if game.life.moments.shell:
			state.momo = true

static func pack_treats(game: Node) -> String:
	var state: Dictionary = game.life.welcome_day
	if not state.started:
		return "Nora has an invitation for you at the Puppy Club."
	if state.treats:
		return "Your picnic treats are packed. I'll keep them ready for you!"
	state.treats = true
	IslandLife.talk(game, "June")
	game.remember("June packed little treats for our Welcome Day picnic.")
	game.changed.emit()
	game.save_game()
	return game.puppy_name + " gives the picnic bag a curious sniff. A few little biscuits, a water bowl, and good company. All packed!"

static func picnic_action(game: Node) -> Dictionary:
	var state: Dictionary = game.life.welcome_day
	if not state.started or not prepared(state):
		return {"ok":false, "text":"Visit our island friends before the picnic."}
	if not game.can_explore():
		return {"ok":false, "text":"A little rest or recovery first. The picnic will wait for you."}
	if state.picnic_step == 3:
		return {"ok":false, "text":"A lovely memory together. You can enjoy another picnic whenever you like."}
	if game.cooldowns.get("WelcomePicnic", 0) > 0:
		return {"ok":false, "text":"Let your puppy finish this little moment."}
	state.picnic_step += 1
	game.cooldowns.WelcomePicnic = 3.2
	var lines = ["Momo recognizes " + game.puppy_name + "! Two happy tails and a friendly hello.", "You call, and " + game.puppy_name + " comes back for the ball. Momo is ready for a turn!", "A quiet picnic with a new friend. Nora smiles: you're part of the island now."]
	if state.picnic_step == 3:
		var first = not state.celebrated
		state.celebrated = true
		state.picnics = mini(1000, state.picnics + 1)
		game.needs.Happiness = minf(100, game.needs.Happiness + 6)
		game.needs.Energy = maxf(0, game.needs.Energy - 2)
		if first:
			game.items.PlushToy = 1
			if game.life.toy.is_empty():
				game.life.toy = "PlushToy"
			var buddy: Dictionary = game.life.adventure.buddies.get("Momo", {"visits":0, "bonus_day":""})
			buddy.visits = mini(1000, int(buddy.visits) + 1)
			game.life.adventure.buddies.Momo = buddy
			game.remember("Our first Island Welcome Day with Nora and Momo. A cuddle plush to take home, and a friend who can visit.")
			lines[2] += " A cuddle plush is yours, and Momo can now visit Home."
		else:
			game.remember("Another cozy Welcome Day picnic with Momo.")
	game.care_performed.emit("Come" if state.picnic_step == 2 else "Pet")
	game.changed.emit()
	game.save_game()
	return {"ok":true, "step":state.picnic_step, "text":lines[state.picnic_step - 1]}

static func repeat_picnic(game: Node) -> bool:
	var state: Dictionary = game.life.welcome_day
	if not state.celebrated or state.picnic_step != 3 or game.cooldowns.get("WelcomePicnic", 0) > 0:
		return false
	state.picnic_step = 0
	game.changed.emit()
	game.save_game()
	return true

static func invite_momo(game: Node, visiting: bool = true) -> bool:
	if not game.life.welcome_day.celebrated:
		return false
	game.life.welcome_day.guest = visiting
	game.save_game()
	game.changed.emit()
	return true

static func greeting(game: Node, person: String, fallback: String) -> String:
	var state: Dictionary = game.life.welcome_day
	if not state.started:
		return "Welcome Day is coming. Join us!" if person == "Nora" else fallback
	if state.celebrated:
		return "Momo remembers you. Come picnic again!" if person == "Nora" else fallback
	match person:
		"Nora": return "The picnic is ready. Come join us!" if prepared(state) else "Ben, June and Kai are helping with our picnic."
		"Ben": return "That recall is ready for our picnic game." if state.lesson else "Practice Come for our picnic game."
		"June": return "Your picnic treats are packed!" if state.treats else "Let's pack treats for Welcome Day."
		"Kai": return "See you at the picnic!" if state.beach else "Try a game. Let's welcome little paws!"
	return fallback
