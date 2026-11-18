class_name IslandMemories
extends RefCounted

const ENTRIES = {
	"neighbor_helper":{"title":"A nose for helping","text":"Our dog found a neighbor's missing belonging.","icon":"leaf"},
	"welcome_visitor":{"title":"A friend at our door","text":"An island dog came over to spend time together.","icon":"club"},
	"first_catch":{"title":"Our first lovely catch","text":"A ball, a little courage, and a happy return.","icon":"play"},
	"first_trick":{"title":"Learning as a team","text":"Our first fully learned trick with Ben.","icon":"training_treat"},
	"first_friend":{"title":"A familiar friendly face","text":"Our first island neighbor welcomed us.","icon":"heart"},
	"first_find":{"title":"A little island treasure","text":"Our dog found something special to bring home.","icon":"shell"},
	"first_festival":{"title":"Part of the island","text":"Our first celebration with the neighbors.","icon":"club"},
	"festival_tour":{"title":"An island full of friends","text":"We shared all five neighbor gatherings.","icon":"island"}
}

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size()>ENTRIES.size(): return false
	for key in data:
		if key not in ENTRIES or not data[key] is String or not LocalDate.valid(data[key]): return false
	return true

static func unlock(game: Node, key: String) -> bool:
	if key not in ENTRIES or game.life.memories.has(key): return false
	game.life.memories[key] = IslandLife.today()
	game.remember("Memory: "+ENTRIES[key].title+".")
	return true

static func suggestion(game: Node) -> Dictionary:
	if PuppyHealth.unwell(game): return {"text":"A gentle checkup with Leah","place":"Vet Clinic","icon":"clinic"}
	if game.resting or game.needs.Energy<30: return {"text":"A cozy rest at Home","place":"Home","focus":"Rest","icon":"rest"}
	if game.needs.Hunger<45: return {"text":"A fresh meal together","place":"Home","focus":"Feed","icon":"feed"}
	if game.needs.Cleanliness<35: return {"text":"A gentle brush together","place":"Home","focus":"Care","icon":"care"}
	if game.needs.Happiness<45: return {"text":"A little play together","place":"Home","focus":"Play","icon":"play"}
	if game.points==0: return {"text":"Share a first meal","place":"Home","focus":"Feed","icon":"feed"}
	if game.life.surprises.kind!="" and game.life.surprises.accepted:
		return {"text":"Visit with "+game.life.surprises.buddy if game.life.surprises.kind=="Visit" else "Help "+IslandSurprises.REQUESTS[game.life.surprises.kind].person,"place":"Surprise","icon":"heart"}
	var festival = IslandFestivals.featured()
	if game.intro_seen and game.name_chosen and game.life.festivals.get(festival,{}).get("claimed","")<IslandLife.today():
		return {"text":IslandFestivals.EVENTS[festival].name,"place":"Festival:"+festival,"icon":IslandFestivals.EVENTS[festival].icon}
	if not game.life.memories.has("first_catch"): return {"text":"Try a lovely catch with Ben","place":"Park","icon":"play"}
	if not game.life.memories.has("first_trick"): return {"text":"Practice a favorite trick","place":"Life:Training","icon":"training_treat"}
	return {"text":"A walk with a familiar friend","place":"Beach","icon":"leaf"}
