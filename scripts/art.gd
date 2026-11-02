class_name Art
extends RefCounted

# Stable slots: replace these textures with layered production artwork.
const HOME = preload("res://assets/backgrounds/home_cel.png")
const PARK = preload("res://assets/backgrounds/park_cel.png")
const BEACH = preload("res://assets/backgrounds/walk_cel.png")
const ISLAND = preload("res://assets/backgrounds/island_cel.png")
const PUPPIES = {
	"Puppy": preload("res://assets/puppies/puppy_cel.tres"),
	"Shiba Inu": preload("res://assets/puppies/shiba_cel.tres"),
	"Golden Retriever": preload("res://assets/puppies/golden_cel.tres")
}
const PUPPY_SLEEP = preload("res://assets/puppies/puppy_sleep_cel.tres")
const PUPPY_SLEEP_REGION = Rect2i(0, 0, 396, 234)
const SLEEP_TEXTURES = {
	"Puppy": PUPPY_SLEEP,
	"Shiba Inu": preload("res://assets/puppies/shiba_sleep_cel.tres"),
	"Golden Retriever": preload("res://assets/puppies/golden_sleep_cel.tres")
}
const SLEEP_REGIONS = {
	"Puppy": PUPPY_SLEEP_REGION,
	"Shiba Inu": Rect2i(0, 0, 429, 258),
	"Golden Retriever": Rect2i(0, 0, 519, 276)
}
const NORA = preload("res://assets/characters/nora_cel_0.tres")

const WALKS = {
	"Puppy": preload("res://assets/puppies/puppy_walk_cel.png"),
	"Shiba Inu": preload("res://assets/puppies/shiba_walk_cel.png"),
	"Golden Retriever": preload("res://assets/puppies/golden_walk_cel.png")
}

# Registered ground bounds and torso anchors keep the eight phases aligned.
static var WALK_DATA: Dictionary = preload("res://assets/puppies/walk_cel_frames.json").data
static var WALK_REGIONS: Dictionary = walk_values("regions")
static var WALK_ANCHORS: Dictionary = walk_values("anchors")
static var WALK_HEIGHTS: Dictionary = walk_values("height")
static var CEL_RESIDENTS: Dictionary = preload("res://assets/characters/cel_frames.json").data

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

const REN = preload("res://assets/characters/ren_cel_0.tres")
const BACKGROUNDS = {"Lighthouse Room":preload("res://assets/backgrounds/lighthouse_room_cel.png"),"Harbor": preload("res://assets/backgrounds/harbor_cel.png"), "Keeper’s Cottage": preload("res://assets/backgrounds/cottage_cel.png"),"Home": HOME, "Park": PARK, "Beach": BEACH,
	"Puppy Club": preload("res://assets/backgrounds/club_cel.png"),
	"Shop": preload("res://assets/backgrounds/shop_cel.png"),
	"Vet Clinic": preload("res://assets/backgrounds/vet_cel.png"),
	"Lighthouse": preload("res://assets/backgrounds/lighthouse_cel.png"),
}
const JUNE = preload("res://assets/characters/june_cel_0.tres")
const LEAH = preload("res://assets/characters/leah_cel_0.tres")

const BEN = preload("res://assets/characters/ben_cel_0.tres")
const KAI = preload("res://assets/characters/kai_cel_0.tres")
const OWEN = preload("res://assets/characters/owen_cel_0.tres")

const NORA_CORAL = preload("res://assets/characters/nora_cel_1.tres")
const JUNE_MINT = preload("res://assets/characters/june_cel_1.tres")

const BEN_TRAINING = preload("res://assets/characters/ben_cel_1.tres")
const LEAH_TUNIC = preload("res://assets/characters/leah_cel_1.tres")
const OWEN_PARCEL = preload("res://assets/characters/owen_cel_1.tres")
const REN_SWEATER = preload("res://assets/characters/ren_cel_1.tres")

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

static func resident_frames(source: Texture2D) -> Array[Texture2D]:
	if source == KAI:
		return BeachStyle.resident_frames()
	var outfits = [[NORA,NORA_CORAL],[JUNE,JUNE_MINT],[BEN,BEN_TRAINING],[LEAH,LEAH_TUNIC],[OWEN,OWEN_PARCEL],[REN,REN_SWEATER],[KAI]]
	var names = ["nora","june","ben","leah","owen","ren","kai"]
	for index in outfits.size():
		var row = outfits[index].find(source)
		if row < 0:
			continue
		var key: String = names[index]+str(row)
		if resident_cache.has(key):
			return resident_cache[key]
		var registered: Dictionary = CEL_RESIDENTS[names[index]]
		var sheet: Texture2D = load("res://"+registered.atlas)
		var result: Array[Texture2D] = []
		var pose_index = 0
		for bounds in registered.rows[row]:
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
			frame.filter_clip = true
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

static var TRICK_DATA: Dictionary = preload("res://assets/puppies/trick_cel_frames.json").data
static var trick_cache: Dictionary = {}
static func trick_frames(breed: String, command: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not TRICK_DATA.has(breed) or not TRICK_DATA[breed].rows.has(command):
		return result
	for bounds in TRICK_DATA[breed].rows[command]:
		result.append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]))
	return result

static func trick_sheet(breed: String) -> Texture2D:
	if not trick_cache.has(breed):
		trick_cache[breed] = load("res://"+TRICK_DATA[breed].atlas)
	return trick_cache[breed]
