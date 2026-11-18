class_name DailyCheckIn
extends RefCounted

const MILESTONES=[3,7,14]
static func fresh() -> Dictionary:
	return {"last_day":"","streak":0,"best":0,"earned":[],"claimed":[]}

static func valid(data: Variant) -> bool:
	if not data is Dictionary or not IslandAdventure.date(data.get("last_day","")): return false
	for key in ["streak","best"]:
		if not IslandAdventure.integer(data.get(key,0),36500): return false
	if data.get("best",0)<data.get("streak",0): return false
	for key in ["earned","claimed"]:
		var values=data.get(key,[])
		if not values is Array or values.size()>3: return false
		var seen=[]
		for value in values:
			if value not in MILESTONES or value in seen: return false
			seen.append(value)
	for value in data.get("claimed",[]):
		if value not in data.get("earned",[]): return false
	for value in data.get("earned",[]):
		if value>data.get("best",0): return false
	return (data.get("streak",0)==0)==data.get("last_day","").is_empty()

static func normalized(data: Dictionary) -> Dictionary:
	var result=fresh()
	result.merge(data.duplicate(true),true)
	for key in ["streak","best"]: result[key]=int(result[key])
	return result

static func record(game: Node, date: String) -> bool:
	var state: Dictionary=game.life.check_in
	if not LocalDate.valid(date) or date<=state.last_day: return false
	var consecutive=not state.last_day.is_empty() and Time.get_unix_time_from_datetime_string(date)-Time.get_unix_time_from_datetime_string(state.last_day)==86400
	state.streak=mini(36500,int(state.streak)+1) if consecutive else 1
	state.best=maxi(int(state.best),int(state.streak))
	state.last_day=date
	for goal in MILESTONES:
		if state.streak>=goal and goal not in state.earned: state.earned.append(goal)
	return true

static func pending(game: Node) -> Array:
	return game.life.check_in.earned.filter(func(goal):return goal not in game.life.check_in.claimed)

static func claim(game: Node) -> String:
	var ready=pending(game)
	if ready.is_empty(): return "Your welcome-back gifts are safely saved."
	var coins=0
	var cosmetic=false
	for goal in ready:
		if goal==14 and game.items.get("SunshineBandana",0)==0:
			game.items.SunshineBandana=1
			cosmetic=true
		else: coins+={3:10,7:20,14:15}[int(goal)]
		game.life.check_in.claimed.append(goal)
	var earned=mini(coins,1000000-game.coins)
	game.coins+=earned
	game.changed.emit()
	game.save_game()
	return ("A Sunshine bandana is waiting in your Bag. Wear it whenever you like. " if cosmetic else "")+(IslandLife.coin_reward_text(earned) if coins>0 else "Thank you for visiting your little friend!")
