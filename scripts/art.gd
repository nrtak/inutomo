class_name Art
extends RefCounted

static var EXTRA_DOGS: Dictionary = preload("res://assets/puppies/extra_dogs_anime_frames.json").data
static var REACTIONS: Dictionary = preload("res://assets/puppies/reactions_anime_frames.json").data

# Stable slots: replace these textures with layered production artwork.
const HOME = preload("res://assets/backgrounds/home_anime.png")
const PARK = preload("res://assets/backgrounds/park_anime.png")
const BEACH = preload("res://assets/backgrounds/beach_anime.png")
const ISLAND = preload("res://assets/backgrounds/island_anime_connected.png")
const DRESSED_PUPPIES = {
	"Puppy": preload("res://assets/puppies/puppy_anime.tres"),
	"Shiba Inu": preload("res://assets/puppies/shiba_anime.tres"),
	"Golden Retriever": preload("res://assets/puppies/golden_anime.tres"),
	"Dachshund": preload("res://assets/puppies/dachshund_anime.tres"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_anime.tres"),
	"Beagle": preload("res://assets/puppies/beagle_anime.tres"),
	"Corgi": preload("res://assets/puppies/corgi_anime.tres"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_anime.tres")
}
const PUPPIES = {
	"Puppy":preload("res://assets/puppies/puppy_bare_anime.tres"),
	"Shiba Inu":preload("res://assets/puppies/shiba_bare_anime.tres"),
	"Golden Retriever":preload("res://assets/puppies/golden_bare_anime.tres"),
	"Dachshund": preload("res://assets/puppies/dachshund_bare_anime.tres"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_bare_anime.tres"),
	"Beagle": preload("res://assets/puppies/beagle_bare_anime.tres"),
	"Corgi": preload("res://assets/puppies/corgi_bare_anime.tres"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_bare_anime.tres")
}
const PUPPY_SLEEP = preload("res://assets/puppies/puppy_bare_sleep_anime.tres")
static var PUPPY_SLEEP_REGION = Rect2i(Vector2i.ZERO,PUPPY_SLEEP.get_size())
const DRESSED_SLEEP_TEXTURES = {
	"Puppy": preload("res://assets/puppies/puppy_sleep_anime.tres"),
	"Shiba Inu": preload("res://assets/puppies/shiba_sleep_anime.tres"),
	"Golden Retriever": preload("res://assets/puppies/golden_sleep_anime.tres"),
	"Dachshund": preload("res://assets/puppies/dachshund_sleep_anime.tres"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_sleep_anime.tres"),
	"Beagle": preload("res://assets/puppies/beagle_sleep_anime.tres"),
	"Corgi": preload("res://assets/puppies/corgi_sleep_anime.tres"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_sleep_anime.tres")
}
const SLEEP_TEXTURES = {
	"Puppy":PUPPY_SLEEP,
	"Shiba Inu":preload("res://assets/puppies/shiba_bare_sleep_anime.tres"),
	"Golden Retriever":preload("res://assets/puppies/golden_bare_sleep_anime.tres"),
	"Dachshund": preload("res://assets/puppies/dachshund_bare_sleep_anime.tres"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_bare_sleep_anime.tres"),
	"Beagle": preload("res://assets/puppies/beagle_bare_sleep_anime.tres"),
	"Corgi": preload("res://assets/puppies/corgi_bare_sleep_anime.tres"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_bare_sleep_anime.tres")
}
static var SLEEP_REGIONS = {
	"Puppy": PUPPY_SLEEP_REGION,
	"Shiba Inu": Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Shiba Inu"].get_size()),
	"Golden Retriever": Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Golden Retriever"].get_size()),
	"Dachshund":Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Dachshund"].get_size()),
	"Miniature Collie":Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Miniature Collie"].get_size()),
	"Beagle":Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Beagle"].get_size()),
	"Corgi":Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Corgi"].get_size()),
	"Toy Poodle":Rect2i(Vector2i.ZERO,SLEEP_TEXTURES["Toy Poodle"].get_size())
}
const NORA = preload("res://assets/characters/nora_anime_0.tres")

const DRESSED_WALKS = {
	"Puppy": preload("res://assets/puppies/puppy_walk_anime.png"),
	"Shiba Inu": preload("res://assets/puppies/shiba_walk_anime.png"),
	"Golden Retriever": preload("res://assets/puppies/golden_walk_anime.png"),
	"Dachshund": preload("res://assets/puppies/dachshund_anime.png"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_anime.png"),
	"Beagle": preload("res://assets/puppies/beagle_anime.png"),
	"Corgi": preload("res://assets/puppies/corgi_anime.png"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_anime.png")
}

# Registered ground bounds and torso anchors keep the eight phases aligned.
const WALKS = {
	"Puppy":preload("res://assets/puppies/puppy_bare_walk_anime.png"),
	"Shiba Inu":preload("res://assets/puppies/shiba_bare_walk_anime.png"),
	"Golden Retriever":preload("res://assets/puppies/golden_bare_walk_anime.png"),
	"Dachshund": preload("res://assets/puppies/dachshund_bare_anime.png"),
	"Miniature Collie": preload("res://assets/puppies/mini_collie_bare_anime.png"),
	"Beagle": preload("res://assets/puppies/beagle_bare_anime.png"),
	"Corgi": preload("res://assets/puppies/corgi_bare_anime.png"),
	"Toy Poodle": preload("res://assets/puppies/toy_poodle_bare_anime.png")
}
static var DRESSED_WALK_DATA: Dictionary = with_extra(preload("res://assets/puppies/walk_anime_frames.json").data,"walk",true)
static var WALK_DATA: Dictionary = with_extra(preload("res://assets/puppies/bare_anime_frames.json").data.walks,"walk")
static var WALK_REGIONS: Dictionary = walk_values("regions")
static var WALK_ANCHORS: Dictionary = walk_values("anchors")
static var WALK_HEIGHTS: Dictionary = walk_values("height")
static var RESIDENT_DATA: Dictionary = preload("res://assets/characters/anime_frames.json").data

static func walk_values(field: String) -> Dictionary:
	var result = {}
	for breed in WALK_DATA:
		if field == "regions":
			result[breed] = []
			for bounds in WALK_DATA[breed][field]:
				result[breed].append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]))
		else:
			result[breed] = WALK_DATA[breed][field]
	return result

const REN = preload("res://assets/characters/ren_anime_0.tres")
const BACKGROUNDS = {"Lighthouse Room":preload("res://assets/backgrounds/lighthouse_room_anime.png"),"Harbor": preload("res://assets/backgrounds/harbor_anime.png"), "Keeper’s Cottage": preload("res://assets/backgrounds/cottage_anime.png"),"Home": HOME, "Park": PARK, "Beach": BEACH,
	"Puppy Club": preload("res://assets/backgrounds/club_anime.png"),
	"Shop": preload("res://assets/backgrounds/shop_anime.png"),
	"Vet Clinic": preload("res://assets/backgrounds/vet_anime.png"),
	"Lighthouse": preload("res://assets/backgrounds/lighthouse_anime.png"),
}
const JUNE = preload("res://assets/characters/june_anime_0.tres")
const LEAH = preload("res://assets/characters/leah_anime_0.tres")

const BEN = preload("res://assets/characters/ben_anime_0.tres")
const KAI = preload("res://assets/characters/kai_anime_0.tres")
const OWEN = preload("res://assets/characters/owen_anime_0.tres")

const NORA_CORAL = preload("res://assets/characters/nora_anime_1.tres")
const JUNE_MINT = preload("res://assets/characters/june_anime_1.tres")

const BEN_TRAINING = preload("res://assets/characters/ben_anime_1.tres")
const LEAH_TUNIC = preload("res://assets/characters/leah_anime_1.tres")
const OWEN_PARCEL = preload("res://assets/characters/owen_anime_1.tres")
const REN_SWEATER = preload("res://assets/characters/ren_anime_1.tres")

static func daily_portrait(texture: Texture2D, date: String = "") -> Texture2D:
	if date.is_empty():
		date = Time.get_date_string_from_system(false)
	var day = int(Time.get_unix_time_from_datetime_string(date) / 86400)
	var wardrobes = [[NORA, NORA_CORAL], [JUNE, JUNE_MINT], [BEN, BEN_TRAINING], [LEAH, LEAH_TUNIC], [OWEN, OWEN_PARCEL], [REN, REN_SWEATER]]
	for index in wardrobes.size():
		if texture in wardrobes[index]:
			return wardrobes[index][posmod(day + index, 2)]
	return texture

static var resident_cache: Dictionary = {}

static func resident_frames(source: Texture2D, torso_up: bool = false) -> Array[Texture2D]:
	var outfits = [[NORA,NORA_CORAL],[JUNE,JUNE_MINT],[BEN,BEN_TRAINING],[LEAH,LEAH_TUNIC],[OWEN,OWEN_PARCEL],[REN,REN_SWEATER],[KAI]]
	var names = ["nora","june","ben","leah","owen","ren","kai"]
	for index in outfits.size():
		var row = outfits[index].find(source)
		if row < 0:
			continue
		var key: String = names[index]+str(row)+("torso" if torso_up else "")
		if resident_cache.has(key):
			return resident_cache[key]
		var registered: Dictionary = RESIDENT_DATA[names[index]]
		var sheet: Texture2D = load("res://"+registered.atlas)
		var result: Array[Texture2D] = []
		var pose_index = 0
		var poses: Array = registered.torso_rows[row] if torso_up else registered.rows[row]
		for bounds in poses:
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
			frame.filter_clip = true
			if torso_up:
				var margin: Array = registered.torso_margins[row][pose_index]
				frame.margin = Rect2(margin[0],margin[1],margin[2],margin[3])
			else:
				var registration: Dictionary = registered.registration[row]
				frame.margin = Rect2(Vector2(registration.offsets[pose_index],0),Vector2(registration.padding,0))
			result.append(frame)
			pose_index += 1
		resident_cache[key] = result
		return result
	var frame = AtlasTexture.new()
	frame.atlas = source
	frame.region = source.get_image().get_used_rect()
	return [frame]

static var DRESSED_TRICK_DATA: Dictionary = with_extra(preload("res://assets/puppies/trick_anime_frames.json").data,"tricks",true)
static var TRICK_DATA: Dictionary = with_extra(preload("res://assets/puppies/bare_anime_frames.json").data.tricks,"tricks")
static var trick_cache: Dictionary = {}
static func trick_frames(breed: String, command: String, dressed: bool = false) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var data = DRESSED_TRICK_DATA if dressed else TRICK_DATA
	if not data.has(breed) or not data[breed].rows.has(command):
		return result
	for bounds in data[breed].rows[command]:
		result.append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]))
	return result

static func trick_sheet(breed: String, dressed: bool = false) -> Texture2D:
	var key = breed + str(dressed)
	if not trick_cache.has(key):
		trick_cache[key] = load("res://"+(DRESSED_TRICK_DATA if dressed else TRICK_DATA)[breed].atlas)
	return trick_cache[key]

static func with_extra(original: Dictionary, group: String, dressed: bool = false) -> Dictionary:
	var result = original.duplicate(true)
	for breed in EXTRA_DOGS:
		result[breed] = EXTRA_DOGS[breed]["dressed" if dressed else "bare"][group]
	return result

static func adult_height(breed: String) -> float:
	return {"Dachshund":180.0,"Miniature Collie":280.0,"Beagle":250.0,"Corgi":210.0,"Toy Poodle":220.0}.get(breed,320.0)

static func sleeping_width(breed: String) -> float:
	return {"Dachshund":350.0,"Miniature Collie":370.0,"Beagle":365.0,"Corgi":350.0,"Toy Poodle":310.0}.get(breed,390.0)

static var expression_cache: Dictionary = {}
static func tug_mouth(breed: String, dressed: bool = false) -> Vector2:
	var clothing = "dressed" if dressed else "bare"
	var point: Array = EXTRA_DOGS[breed][clothing].mouth if EXTRA_DOGS.has(breed) else REACTIONS[clothing].mouths[breed]
	return Vector2(point[0],point[1])

static func expression_texture(breed: String, pose: String, dressed: bool = false) -> Texture2D:
	var key = breed+pose+str(dressed)
	if not expression_cache.has(key):
		var data: Dictionary
		var box: Array
		if EXTRA_DOGS.has(breed):
			data = EXTRA_DOGS[breed]["dressed" if dressed else "bare"]
			box = data.moments[pose]
		else:
			data = REACTIONS["dressed" if dressed else "bare"]
			box = data.breeds[breed][pose]
		var frame = AtlasTexture.new()
		frame.atlas = load("res://"+data.atlas)
		frame.region = Rect2(box[0],box[1],box[2],box[3])
		frame.filter_clip = true
		expression_cache[key] = frame
	return expression_cache[key]
