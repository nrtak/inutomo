class_name IslandSurprises
extends RefCounted

const REQUESTS = {
	"Toy":{"person":"Ben","place":"Park","object":"Momo's blue ball","icon":"play","goods":"Toy"},
	"Basket":{"person":"June","place":"Shop","object":"the picnic basket","icon":"menu_bag","goods":"PicnicPack"},
	"Parcel":{"person":"Owen","place":"Harbor","object":"a small Harbor parcel","icon":"menu_bag","goods":"Treat"}
}
const OWNERS={"Momo":"Nora","Pippin":"Ben","Milo":"June"}

static func fresh() -> Dictionary:
	return {"day":"","kind":"","buddy":"","accepted":false,"route":"","step":0,"fetch_start":0,"completed":0,"visits":0,"found_toy":false,"history":{}}

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if not IslandAdventure.date(data.get("day","")): return false
	if data.get("kind","") not in ["","Visit","Toy","Basket","Parcel"]: return false
	if data.get("buddy","") not in ["","Momo","Pippin","Milo"]: return false
	if not data.get("accepted",false) is bool or not data.get("found_toy",false) is bool: return false
	if data.get("route","") not in ["","Park","Beach","Hello","Fetch"]: return false
	for pair in [["step",2],["fetch_start",100000],["completed",100000],["visits",100000]]:
		if not IslandAdventure.integer(data.get(pair[0],0),pair[1]): return false
	if not data.get("history",{}) is Dictionary or data.get("history",{}).size()>3: return false
	for buddy in data.get("history",{}):
		if buddy not in OWNERS or data.history[buddy] not in ["Hello","Fetch"]: return false
	if data.get("kind","").is_empty(): return data.get("step",0)==0 and not data.get("accepted",false) and data.get("buddy","").is_empty() and data.get("route","").is_empty()
	if data.get("day","").is_empty(): return false
	if data.get("step",0)>0 and not data.get("accepted",false): return false
	if data.get("step",0)==0 and data.get("route","")!="": return false
	if data.kind=="Visit":
		return data.get("buddy","") in OWNERS and data.get("step",0)<=1 and (data.get("step",0)==0 or data.get("route","") in ["Hello","Fetch"])
	return data.get("buddy","")=="" and (data.get("step",0)==0 or data.get("route","") in ["Park","Beach"])

static func normalized(data: Dictionary) -> Dictionary:
	var result=fresh()
	result.merge(data.duplicate(true),true)
	for key in ["step","fetch_start","completed","visits"]: result[key]=int(result[key])
	return result

static func eligible(game: Node) -> bool:
	return IslandConnections.available(game) and game.points>=4 and game.needs.Hunger>=35 and game.needs.Energy>=25 and not (game.life.welcome_day.guest and not game.life.welcome_day.celebrated)

static func offer(game: Node) -> bool:
	var state: Dictionary=game.life.surprises
	if not eligible(game) or state.kind!="" or state.day>=IslandLife.today(): return false
	state.day=IslandLife.today()
	var random=RandomNumberGenerator.new()
	random.seed=absi((game.puppy_name+state.day+"Island visits").hash())
	if random.randf()<0.35:
		state.kind=["Visit","Visit","Toy","Basket","Parcel"][random.randi_range(0,4)]
		if state.kind=="Visit": state.buddy=OWNERS.keys()[random.randi_range(0,2)]
	game.changed.emit()
	game.save_game()
	return not state.kind.is_empty()

static func info(game: Node) -> Dictionary:
	var state: Dictionary=game.life.surprises
	if state.kind.is_empty(): return {}
	if state.kind=="Visit":
		var familiar=int(game.life.adventure.buddies.get(state.buddy,{}).get("visits",0))>=2
		var previous: String=state.history.get(state.buddy,"")
		var text=state.buddy+" remembers you! Another little game?" if familiar else OWNERS[state.buddy]+" brought "+state.buddy+" for a gentle visit. Say hello?"
		if familiar and previous=="Fetch": text=state.buddy+" remembers your last ball game and looks ready to play!"
		return {"text":text,"join":"Visit with "+state.buddy if state.accepted else "Welcome them","reaction":"Pet"}
	if state.accepted: return {}
	var spec: Dictionary=REQUESTS[state.kind]
	return {"text":spec.person+" could use "+game.puppy_name+"'s nose to find "+spec.object+". Help out?","join":"Hear the request","reaction":"Sniff"}

static func clear_active(state: Dictionary) -> void:
	state.kind=""
	state.buddy=""
	state.accepted=false
	state.route=""
	state.step=0
	state.fetch_start=0

static func respond(game: Node, join: bool) -> Dictionary:
	var state: Dictionary=game.life.surprises
	if state.kind.is_empty(): return {"ok":false,"text":"The island is having a quiet moment."}
	if join and not eligible(game): return {"ok":false,"text":"A little rest first. This visit can wait."}
	if join:
		state.accepted=true
		state.fetch_start=game.fetches
	else: clear_active(state)
	game.changed.emit()
	game.save_game()
	return {"ok":true,"page":"Surprise" if join else "","text":"Another time is fine. Nothing is lost."}

static func place(game: Node) -> String:
	var state: Dictionary=game.life.surprises
	return state.route if state.route in ["Park","Beach"] else "Home"

static func choose_route(game: Node, place_name: String) -> bool:
	var state: Dictionary=game.life.surprises
	if state.kind not in REQUESTS or not state.accepted or state.step!=0 or place_name not in ["Park","Beach"] or not game.can_explore() or game.paused_at>0: return false
	state.route=place_name
	state.step=1
	game.changed.emit()
	game.save_game()
	return true

static func scent_spot(game: Node) -> int:
	var state: Dictionary=game.life.surprises
	return {"Toy":2,"Basket":1,"Parcel":0}.get(state.kind,0) if state.route=="Park" else {"Toy":0,"Basket":2,"Parcel":1}.get(state.kind,0)

static func search(game: Node, index: int) -> Dictionary:
	var state: Dictionary=game.life.surprises
	if state.kind not in REQUESTS or not state.accepted or state.step!=1 or not game.can_explore() or game.paused_at>0: return {"ok":false,"text":"Your clue is saved. Take a little rest if needed."}
	if index!=scent_spot(game): return {"ok":false,"text":game.puppy_name+" checks carefully. The familiar scent is stronger at the "+["left","middle","right"][scent_spot(game)]+" spot."}
	state.step=2
	game.changed.emit()
	game.save_game()
	return {"ok":true,"text":"Found it! Bring "+REQUESTS[state.kind].object+" back to "+REQUESTS[state.kind].person+"."}

static func ready_at(game: Node, place_name: String) -> bool:
	var state: Dictionary=game.life.surprises
	return state.kind in REQUESTS and state.accepted and state.step==2 and REQUESTS[state.kind].place==place_name

static func finish_request(game: Node, place_name: String) -> Dictionary:
	if not ready_at(game,place_name) or game.paused_at>0: return {"ok":false,"text":"Your neighbor request is safely saved."}
	var state: Dictionary=game.life.surprises
	var spec: Dictionary=REQUESTS[state.kind]
	var earned=mini(8,1000000-game.coins)
	game.coins+=earned
	game.needs.Happiness=minf(100,game.needs.Happiness+4)
	if state.kind=="Toy": state.found_toy=true
	state.completed=mini(100000,state.completed+1)
	game.remember("Helped "+spec.person+" find "+spec.object+" with our dog's nose.")
	IslandMemories.unlock(game,"neighbor_helper")
	clear_active(state)
	IslandLife.talk(game,spec.person)
	game.changed.emit()
	game.save_game()
	return {"ok":true,"text":"You found it! Thank you, "+game.puppy_name+". "+IslandLife.coin_reward_text(earned)}

static func choose_visit(game: Node, kind: String) -> bool:
	var state: Dictionary=game.life.surprises
	if state.kind!="Visit" or not state.accepted or kind not in ["Hello","Fetch"] or not game.can_explore() or game.paused_at>0: return false
	state.route=kind
	state.step=1
	game.save_game()
	return true

static func record_playmate(game: Node, buddy: String, kind: String) -> void:
	if buddy not in OWNERS or kind not in ["Hello","Fetch"]: return
	var entry: Dictionary=game.life.adventure.buddies.get(buddy,{"visits":0,"bonus_day":""})
	entry.visits=mini(1000,int(entry.visits)+1)
	game.life.adventure.buddies[buddy]=entry
	game.life.surprises.history[buddy]=kind

static func finish_visit(game: Node, kind: String) -> Dictionary:
	var state: Dictionary=game.life.surprises
	if state.kind!="Visit" or not state.accepted or state.step!=1 or state.route!=kind or (kind=="Hello" and (game.resting or PuppyHealth.unwell(game))) or game.paused_at>0: return {"ok":false,"text":"Your friend's visit is saved."}
	if kind=="Fetch" and game.fetches<=state.fetch_start: return {"ok":false,"text":"Finish your ball game together first."}
	var buddy: String=state.buddy
	var earned=mini(5,1000000-game.coins)
	game.coins+=earned
	game.needs.Happiness=minf(100,game.needs.Happiness+3)
	record_playmate(game,buddy,kind)
	state.visits=mini(100000,state.visits+1)
	game.remember(buddy+" came over for "+("a quiet hello." if kind=="Hello" else "a ball game together."))
	IslandMemories.unlock(game,"welcome_visitor")
	clear_active(state)
	game.changed.emit()
	game.save_game()
	return {"ok":true,"text":buddy+" had a lovely visit. "+IslandLife.coin_reward_text(earned)}
