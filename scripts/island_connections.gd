class_name IslandConnections
extends RefCounted

const INVITATIONS = ["Toy", "Cuddle", "Explore"]
const MYSTERY = [
	{"place":"Puppy Club", "person":"Nora", "title":"The missing welcome star", "button":"Nora's missing star", "hint":"The wooden star above our Club door is missing. A pink ribbon blew toward the Park. Shall we look together?", "icon":"heart", "spot":-1},
	{"place":"Park", "person":"Ben", "title":"A ribbon on the breeze", "button":"Follow the ribbon", "hint":"Look near the bench. A pink ribbon caught on the sunny path.", "icon":"welcome_ribbon", "spot":2},
	{"place":"Beach", "person":"Kai", "title":"Something washed ashore", "button":"Search the shoreline", "hint":"The tide left something beside the shell. Look along the safe sandy path.", "icon":"shell", "spot":1},
	{"place":"Harbor", "person":"Owen", "title":"A familiar little mark", "button":"Match the star's mark", "hint":"The star has a painted paw. Find the matching mark on the Harbor parcel.", "icon":"club", "spot":0},
	{"place":"Puppy Club", "person":"Nora", "title":"A place above the door", "button":"Bring the star home", "hint":"That's our welcome star! You and your dog followed every little clue. Let's put it back where everyone can see it.", "icon":"heart", "spot":-1},
]

static func fresh() -> Dictionary:
	return {"shared":0, "offer_day":"", "offers":0, "invitation":"", "joined":0, "mystery":0, "memory_breed":"", "memory_name":"", "arrivals":{}}

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	for pair in [["shared",100000],["offers",3],["joined",10000],["mystery",5]]:
		if not IslandAdventure.integer(data.get(pair[0],0),pair[1]): return false
	if not IslandAdventure.date(data.get("offer_day","")): return false
	if data.get("invitation","") not in ["","Toy","Cuddle","Explore"]: return false
	if data.get("offers",0)>0 and data.get("offer_day","").is_empty(): return false
	if not data.get("invitation","").is_empty() and data.get("offers",0)==0: return false
	if data.get("memory_breed","")!="" and data.get("memory_breed","") not in GrowthRoutes.BREEDS: return false
	if not data.get("memory_name","") is String or data.get("memory_name","").length()>16: return false
	if data.get("mystery",0)==5 and (data.get("memory_breed","").is_empty() or data.get("memory_name","").is_empty()): return false
	if not data.get("arrivals",{}) is Dictionary: return false
	for person in data.get("arrivals",{}):
		if person not in IslandLife.PEOPLE or not IslandAdventure.integer(data.arrivals[person],10000): return false
	return true

static func normalized(data: Dictionary) -> Dictionary:
	var state = fresh()
	state.merge(data.duplicate(true),true)
	for key in ["shared","offers","joined","mystery"]: state[key] = int(state[key])
	for person in state.arrivals: state.arrivals[person] = int(state.arrivals[person])
	return state

static func available(game: Node) -> bool:
	return game.can_explore() and game.paused_at<=0 and game.intro_seen and game.name_chosen and game.pending_stage.is_empty()

static func offer(game: Node) -> bool:
	if not available(game): return false
	if game.needs.Hunger<45 or game.needs.Cleanliness<30 or game.needs.Energy<30: return false
	var state: Dictionary = game.life.connections
	if state.offer_day > IslandLife.today(): return false
	if not state.invitation.is_empty(): return false
	if state.offer_day != IslandLife.today():
		state.offer_day = IslandLife.today()
		state.offers = 0
	if state.offers>=3: return false
	var first: int = {"Playful":0,"Cuddly":1,"Curious":2}[IslandLife.personality(game)]
	state.invitation = INVITATIONS[(first+state.offers)%INVITATIONS.size()]
	state.offers += 1
	game.changed.emit()
	game.save_game()
	return true

static func invitation_info(game: Node) -> Dictionary:
	var name: String = game.puppy_name
	match game.life.connections.invitation:
		"Toy": return {"text":name+(" brings a toy over. A little game?" if game.items.get(game.life.toy,0)>0 else " gives a little play bow. A game together?"), "join":"Play together", "page":"Moment:Home", "reaction":"Play", "icon":"play"}
		"Cuddle": return {"text":name+" settles close and looks up at you.", "join":"Sit together", "page":"", "reaction":"Pet", "icon":"heart"}
		"Explore": return {"text":name+" notices a scent by the door. Explore together?", "join":"Follow that nose", "page":"Moment:Beach" if game.life.adventure.scent.claimed>=IslandLife.today() else "Scent Trail", "reaction":"Sniff", "icon":"leaf"}
	return {}

static func respond(game: Node, join: bool) -> Dictionary:
	var info = invitation_info(game)
	if info.is_empty(): return {"ok":false,"text":"No little invitation is waiting."}
	if join and (not available(game) or invitation_wait(game)>0):
		return {"ok":false,"text":"A little rest or a breather first. Your invitation will wait."}
	game.life.connections.invitation = ""
	if join:
		game.life.connections.joined = mini(10000,game.life.connections.joined+1)
		if info.page.is_empty():
			game.cooldowns.Pet = 12.0
			game.needs.Happiness = minf(100,game.needs.Happiness+3)
			game.care_performed.emit("Pet")
			IslandLife.record(game,"Pet")
			game.remember("Sat quietly together when our dog asked for company.")
	game.changed.emit()
	game.save_game()
	return {"ok":true,"page":info.page if join else "", "text":game.puppy_name+" enjoys having you close." if join else "Another time is fine. Nothing is lost."}

static func invitation_wait(game: Node) -> float:
	var info = invitation_info(game)
	if info.is_empty(): return 0.0
	var action: String = {"Moment:Home":"Play","Moment:Beach":"IslandMoment","Scent Trail":"Scent","":"Pet"}.get(info.page, "Pet")
	return float(game.cooldowns.get(action,0))

static func record(game: Node, action: String) -> void:
	if action in ["Pet","Play","Feed","Care","Training","Fetch","Walk","Playdate","Discovery"]:
		game.life.connections.shared = mini(100000,game.life.connections.shared+1)

static func bond_name(game: Node) -> String:
	var shared: int = game.life.connections.shared
	return "A familiar team" if shared>=35 else ("Growing trust" if shared>=10 else "Getting to know you")

static func mystery_step(game: Node) -> Dictionary:
	return MYSTERY[mini(4,int(game.life.connections.mystery))]

static func advance_mystery(game: Node, expected: int, place: String, choice: int = -1) -> Dictionary:
	var state: Dictionary = game.life.connections
	if expected!=state.mystery or expected>=5: return {"ok":false,"text":"This little clue is already saved."}
	var spec = mystery_step(game)
	if place!=spec.place or not available(game): return {"ok":false,"text":"A little rest first, then visit "+spec.place+". Your clues will wait."}
	if choice!=spec.spot:
		return {"ok":false,"text":"Not this one. "+spec.hint}
	state.mystery += 1
	game.care_performed.emit("Sniff" if expected in [1,2,3] else "Pet")
	if expected in [1,2,3]:
		IslandLife.record(game,"Discovery")
		if expected==2: IslandAdventure.record_task(game,"Beach")
		game.needs.Happiness = minf(100,game.needs.Happiness+2)
	var lines = ["Nora's welcome star is missing. Follow the pink ribbon to the Park.","A ribbon! Ben saw something drift toward the Beach.","The wooden star is safe. Owen may recognize its painted mark at the Harbor.","Owen recognizes the Club's paw mark. Bring the star back to Nora.","The welcome star is back above the Club door. A framed memory is waiting at Home."]
	if state.mystery==5:
		state.memory_breed = game.breed
		state.memory_name = game.puppy_name
		game.needs.Happiness = minf(100,game.needs.Happiness+5)
	game.remember(lines[expected])
	game.changed.emit()
	game.save_game()
	return {"ok":true,"text":lines[expected]}

static func arrive(game: Node, person: String) -> void:
	if person not in IslandLife.PEOPLE: return
	var arrivals: Dictionary = game.life.connections.arrivals
	arrivals[person] = mini(10000,int(arrivals.get(person,0))+1)
	game.save_game()

static func greeting(game: Node, person: String, fallback: String) -> String:
	var visits: int = game.life.connections.arrivals.get(person,0)
	if visits%3==2: return fallback
	var name: String = game.puppy_name
	if person=="Nora" and game.life.connections.mystery==5:
		return "Our welcome star is back, thanks to you both!"
	if person=="Ren" and game.life.moments.gathered:
		return "I still remember our evening by the light. Welcome back, you two."
	if person=="Ben" and game.life.training.Come>0:
		return name+" remembers our recall practice. Let's celebrate another little try."
	if person=="Kai" and game.life.moments.shell:
		return "Momo's been back to your shell spot, "+name+"!"
	if person=="June" and game.life.welcome_day.treats:
		return "Your picnic bag still makes me smile. How is "+name+"?"
	if person=="Owen" and game.life.connections.mystery>=4:
		return "Good eyes, "+name+"! You found our little painted paw."
	return fallback

static func fetch_profile(game: Node, variant: int) -> Dictionary:
	var profiles = [{"title":"A familiar toss","center":70.0,"speed":2.2},{"title":"A gentle short toss","center":60.0,"speed":1.8},{"title":"A sunny long toss","center":80.0,"speed":2.0}]
	var profile: Dictionary = profiles[clampi(variant,0,2)].duplicate()
	profile.radius = 24.0 if IslandLife.personality(game)=="Cuddly" else (20.0 if IslandLife.personality(game)=="Curious" else 18.0)
	return profile

static func personality_hint(game: Node, kind: String) -> String:
	var nature = IslandLife.personality(game)
	if kind=="Home":
		return {"Playful":"A playful bow! Roll the ball for a happy chase.","Cuddly":"A soft nudge. Roll the ball, then come back close.","Curious":"A curious nose follows the ball. Try a new spot on the rug."}[nature]
	if kind=="Recall":
		return {"Playful":"A bouncy learner. Call Come and celebrate the return.","Cuddly":"A gentle learner. Call Come and welcome those paws close.","Curious":"A thoughtful learner. Call Come along the clear path."}[nature]
	return {"Playful":"An eager little explorer! Follow the happy paws.","Cuddly":"A friend makes exploring easier. Follow those little paws together.","Curious":"That curious nose noticed something. Follow the scent."}[nature]
