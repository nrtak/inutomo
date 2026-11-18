class_name IslandFestivals
extends RefCounted

const EVENTS = {
	"Run":{"name":"Island Fun Run","place":"Park","host":"Ben","neighbors":["Ben","Nora"],"icon":"play","intro":"A friendly race! Cheer in the green zone. Every finish counts.","steps":["A gentle warm-up lap","Around the island green","One happy home stretch"]},
	"Shells":{"name":"Beach Treasure Hunt","place":"Beach","host":"Kai","neighbors":["Kai","June"],"icon":"shell","intro":"Three clues in the sand. Follow our dog's nose and tap a shell.","steps":["A pink shell by the shoreline","A pale shell beside the path","A little spiral shell"]},
	"Picnic":{"name":"Puppy Club Picnic","place":"Puppy Club","host":"Nora","neighbors":["Nora","Leah"],"icon":"feed","intro":"Let's set out snacks, water and a toy for our puppy friends.","steps":["Share the picnic snacks","Set out fresh water","Roll a toy to our friends"]},
	"Lanterns":{"name":"Harbor Lantern Walk","place":"Harbor","host":"Owen","neighbors":["Owen","Ren"],"icon":"sunset","intro":"Help us light three welcoming lanterns along the harbor path.","steps":["Light the harbor lantern","Light the path lantern","Light the welcome lantern"]},
	"Tricks":{"name":"Neighbor Trick Showcase","place":"Park","host":"Ben","neighbors":["Ben","Kai"],"icon":"training_treat","intro":"Sit, paw, then a bow! Little tries get the biggest cheers.","steps":["A patient little sit","Offer a friendly paw","Finish with a cheerful bow"]}
}
const PORTRAITS = {"Ben":Art.BEN,"Nora":Art.NORA,"Kai":Art.KAI,"June":Art.JUNE,"Leah":Art.LEAH,"Owen":Art.OWEN,"Ren":Art.REN}

static func fresh() -> Dictionary:
	var result = {}
	for id in EVENTS: result[id] = {"step":0,"score":0,"best":0,"visits":0,"started":"","claimed":""}
	return result

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size()>EVENTS.size(): return false
	for id in data:
		if id not in EVENTS or not data[id] is Dictionary: return false
		var entry: Dictionary = data[id]
		for key in ["step","score","best"]:
			if not IslandAdventure.integer(entry.get(key,0),3): return false
		if not IslandAdventure.integer(entry.get("visits",0),100000): return false
		if entry.get("score",0)>entry.get("step",0): return false
		for key in ["started","claimed"]:
			if not entry.get(key,"") is String: return false
			if not entry.get(key,"").is_empty() and not LocalDate.valid(entry[key]): return false
		if entry.get("step",0)==3 and entry.get("claimed","").is_empty(): return false
	return true

static func normalized(data: Dictionary) -> Dictionary:
	var result = fresh()
	for id in data:
		result[id].merge(data[id].duplicate(true),true)
		for key in ["step","score","best","visits"]: result[id][key] = int(result[id][key])
	return result

static func featured(date: String = "") -> String:
	if date.is_empty(): date=IslandLife.today()
	var day = int(Time.get_unix_time_from_datetime_string(date)/86400)
	return EVENTS.keys()[posmod(day,EVENTS.size())]

static func begin(game: Node, id: String) -> Dictionary:
	if id not in EVENTS: return {}
	var entry: Dictionary = game.life.festivals[id]
	if entry.step==3 and entry.claimed<IslandLife.today():
		entry.step=0
		entry.score=0
		entry.started=""
	if entry.started.is_empty():
		entry.started=IslandLife.today()
		game.save_game()
	return entry

static func advance(game: Node, id: String, expected: int, success: bool = true) -> Dictionary:
	if id not in EVENTS: return {"ok":false,"text":"Choose an island gathering."}
	var entry: Dictionary = game.life.festivals[id]
	if not game.can_explore() or game.paused_at>0: return {"ok":false,"text":"A little rest or recovery first. The neighbors will wait."}
	if entry.started.is_empty() or entry.step!=expected or expected>=3 or entry.claimed>=IslandLife.today():
		return {"ok":false,"text":"Your celebration progress is already saved."}
	entry.step+=1
	if success: entry.score+=1
	var text = ["Lovely teamwork!","Everyone is cheering you on!","What a lovely day together!"][expected]
	if entry.step==3:
		entry.claimed=IslandLife.today() if IslandLife.today()>=entry.started else entry.started
		entry.visits=mini(100000,entry.visits+1)
		entry.best=maxi(entry.best,entry.score)
		var earned = mini(15,1000000-game.coins)
		game.coins+=earned
		var before_happiness=float(game.needs.Happiness)
		game.needs.Happiness=minf(100,game.needs.Happiness+8)
		var happiness_gained=int(round(game.needs.Happiness-before_happiness))
		game.needs.Energy=maxf(0,game.needs.Energy-3)
		IslandMemories.unlock(game,"first_festival")
		var all_joined = true
		for state in game.life.festivals.values():
			if state.visits==0: all_joined=false
		if all_joined: IslandMemories.unlock(game,"festival_tour")
		for person in EVENTS[id].neighbors: IslandLife.talk(game,person)
		game.remember("Shared the "+EVENTS[id].name+" with "+", ".join(EVENTS[id].neighbors)+".")
		text="Everyone thanks you for joining! "+IslandLife.coin_reward_text(earned)+(" Happiness +%d." % happiness_gained if happiness_gained>0 else " A happy memory is saved.")
	game.changed.emit()
	game.save_game()
	return {"ok":true,"text":text,"done":entry.step==3}
