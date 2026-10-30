class_name PuppySteps
extends RefCounted

const GOALS = [500, 1500, 3000]
const COINS = [3, 4, 5]
static func fresh() -> Dictionary:
	return {"enabled":false,"day":"","today":0,"total":0,"claimed":[]}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("enabled",false) is bool:
		return false
	var day = value.get("day","")
	if not day is String or (not day.is_empty() and not LocalDate.valid(day)):
		return false
	for key in ["today","total"]:
		var number = value.get(key,0)
		if not (number is int or number is float) or not is_finite(float(number)) or number < 0 or number != floorf(number) or number > (100000 if key == "today" else 1000000000):
			return false
	if value.get("total",0) < value.get("today",0) or (day.is_empty() and value.get("total",0) > 0):
		return false
	var claimed = value.get("claimed",[])
	if not claimed is Array or claimed.size() > 3:
		return false
	var seen = []
	for goal in claimed:
		if not (goal is int or goal is float) or not is_finite(float(goal)) or goal != floorf(goal):
			return false
		if int(goal) not in GOALS or int(goal) in seen or goal > value.get("today",0):
			return false
		seen.append(int(goal))
	return true

static func normalized(value: Dictionary) -> Dictionary:
	var result = fresh()
	result.merge(value,true)
	result.today = int(result.today)
	result.total = int(result.total)
	result.claimed = result.claimed.map(func(goal): return int(goal))
	return result

static func accept(game: Node, day: String, count: Variant) -> bool:
	if not game.walking.enabled or not LocalDate.valid(day) or day != IslandLife.today():
		return false
	if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > 100000 or count != floorf(count):
		return false
	if game.walking.day > day:
		return false
	if game.walking.day != day:
		game.walking.day = day
		game.walking.today = 0
		game.walking.claimed = []
	var difference = maxi(0,int(count)-int(game.walking.today))
	game.walking.today = maxi(game.walking.today,int(count))
	game.walking.total = mini(1000000000,int(game.walking.total)+difference)
	game.changed.emit()
	game.save_game()
	return true

static func claim(game: Node, goal: int) -> String:
	if not game.walking.enabled or game.walking.day != IslandLife.today():
		return "Sync today's steps first."
	if goal not in GOALS or goal in game.walking.claimed or game.walking.today < goal:
		return "Keep enjoying your walks. This reward is not ready."
	game.walking.claimed.append(goal)
	game.coins = mini(1000000,game.coins+COINS[GOALS.find(goal)])
	game.needs.Happiness = minf(100,game.needs.Happiness+2)
	game.changed.emit()
	game.save_game()
	return "A little walking reward! +2 Happiness."

static func badge(total: int) -> String:
	if total >= 100000:
		return "Island trail companions"
	if total >= 50000:
		return "Island explorers"
	if total >= 10000:
		return "Trail buddies"
	return "Little walking companions"
