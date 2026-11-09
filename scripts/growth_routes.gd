class_name GrowthRoutes
extends RefCounted

const BREEDS = ["Puppy","Golden Retriever","Shiba Inu","Dachshund","Miniature Collie","Beagle","Corgi","Toy Poodle"]
const HINTS = {"Golden Retriever":"Fetch games", "Shiba Inu":"Coastal walks", "Dachshund":"Scent discoveries", "Miniature Collie":"Training and tug games", "Beagle":"Beach activities", "Corgi":"Playdates with friends", "Toy Poodle":"Brushing, baths and grooming"}

static func fresh() -> Dictionary:
	return {"Dachshund":0,"Miniature Collie":0,"Beagle":0,"Corgi":0,"Toy Poodle":0}

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in data:
		if key not in fresh() or not IslandAdventure.integer(data[key],100000): return false
	return true

static func normalized(data: Dictionary) -> Dictionary:
	var result = fresh()
	for key in result: result[key] = int(data.get(key,0))
	return result

static func record(game: Node, activity: String) -> void:
	if game.breed != "Puppy": return
	var target = {"Scent":"Dachshund","Training":"Miniature Collie","Tug":"Miniature Collie","Beach":"Beagle","Playdate":"Corgi","Grooming":"Toy Poodle"}.get(activity,"")
	if not target.is_empty():
		game.life.growth_paths = normalized(game.life.get("growth_paths",{}))
		game.life.growth_paths[target] = mini(100000,game.life.growth_paths[target]+1)

static func scores(game: Node) -> Dictionary:
	var result = {"Golden Retriever":game.fetches,"Shiba Inu":game.walks}
	var interests: Dictionary = game.life.get("growth_paths",{})
	for breed in fresh(): result[breed] = interests.get(breed,0)
	return result

static func prediction(game: Node) -> String:
	var values = scores(game)
	var choice = "Golden Retriever"
	for breed in values:
		if values[breed]>values[choice]: choice = breed
	return choice
