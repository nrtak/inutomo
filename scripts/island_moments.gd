class_name IslandMoments
extends RefCounted

const PLACES = {"Home":"Home", "Recall":"Park", "Beach":"Beach", "Cottage":"Keeper’s Cottage", "Lighthouse":"Lighthouse"}
const TITLES = {"Home":"Little moments together", "Recall":"Learning with Ben", "Beach":"A discovery with friends", "Cottage":"A little help for Ren", "Lighthouse":"A light for everyone"}

static func fresh() -> Dictionary:
	return {"home":0, "recall":0, "shell":false, "glass":false, "gathered":false}

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["home", "recall"]:
		if not IslandAdventure.integer(data.get(key, 0), 1000):
			return false
	for key in ["shell", "glass", "gathered"]:
		if not data.get(key, false) is bool:
			return false
	return true

static func normalized(data: Dictionary) -> Dictionary:
	var state = fresh()
	for key in state:
		if data.has(key): state[key] = data[key]
	state.home = int(state.home)
	state.recall = int(state.recall)
	return state

static func block_reason(game: Node, kind: String) -> String:
	if kind not in PLACES:
		return "Choose an island moment."
	if not game.can_explore():
		return "A little rest or recovery first. This moment will wait."
	if kind == "Cottage" and not game.life.story.get("path_repaired", false):
		return "Help Ren repair the cottage path first."
	if kind == "Lighthouse":
		if not game.life.story.get("beacon_checked", false):
			return "Help Ren finish the lighthouse restoration first."
		if not game.life.welcome_day.celebrated:
			return "Share Nora's Welcome Day picnic first, then bring your friends here."
	var cooldown: String = {"Home":"Play", "Recall":"Training"}.get(kind, "IslandMoment")
	return "A short breather before another little game." if game.cooldowns.get(cooldown, 0) > 0 else ""

static func complete(game: Node, kind: String) -> Dictionary:
	var blocked = block_reason(game, kind)
	if not blocked.is_empty():
		return {"ok":false, "text":blocked}
	var state: Dictionary = game.life.moments
	var message = ""
	match kind:
		"Home":
			game.action("Play")
			state.home = mini(1000, state.home + 1)
			message = game.puppy_name + " brings the toy back for another turn!"
			if state.home == 1:
				game.remember("Our first hands-on toy game at Home.")
		"Recall":
			IslandLife.train(game, "Come")
			state.recall = mini(1000, state.recall + 1)
			message = "A lovely recall! Ben celebrates the little steps with you."
		"Beach":
			if not state.shell:
				state.shell = true
				GrowthRoutes.record(game,"Beach")
				var buddy: Dictionary = game.life.adventure.buddies.get("Momo",{"visits":0,"bonus_day":""})
				buddy.visits = mini(1000,int(buddy.visits)+1)
				game.life.adventure.buddies.Momo = buddy
				IslandLife.discover(game, 1)
				game.remember("Followed a scent with Momo and Kai to a pearl shell.")
			IslandLife.record(game, "Discovery")
			IslandAdventure.record_task(game, "Beach")
			message = "A pearl shell! Momo found it with " + game.puppy_name + "."
		"Cottage":
			if not state.glass:
				state.glass = true
				IslandLife.discover(game, 2)
				game.remember("Our dog found sea glass beside Ren's sailing-boat mosaic.")
			message = "Ren recognizes the sea glass. You can use this keepsake for his light display."
		"Lighthouse":
			if not state.gathered:
				state.gathered = true
				game.items.SunshineBandana = 1
				game.remember("A light for everyone: Nora, Ren, Momo and our dog gathered by the restored lighthouse.")
			message = "A light to come home to. Your sunshine bandana keeps this day with you."
	if kind not in ["Home", "Recall"]:
		game.cooldowns.IslandMoment = 5.0
		game.needs.Happiness = minf(100, game.needs.Happiness + 3)
		game.care_performed.emit("Pet")
	game.changed.emit()
	game.save_game()
	return {"ok":true, "text":message}
