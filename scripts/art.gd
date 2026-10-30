class_name Art
extends RefCounted

# Stable slots: replace these textures with layered production artwork.
const HOME = preload("res://assets/backgrounds/home_anime.png")
const PARK = preload("res://assets/backgrounds/park_anime.png")
const BEACH = preload("res://assets/backgrounds/beach_anime.png")
const ISLAND = preload("res://assets/backgrounds/island_swimming_cove.png")
const PUPPIES = {
	"Puppy": preload("res://assets/puppies/puppy_anime.png"),
	"Shiba Inu": preload("res://assets/puppies/shiba_anime.png"),
	"Golden Retriever": preload("res://assets/puppies/golden_anime.png")
}
const PUPPY_SLEEP = preload("res://assets/puppies/puppy_sleep_anime.png")
const PUPPY_SLEEP_REGION = Rect2i(12, 290, 1299, 708)
const SLEEP_TEXTURES = {
	"Puppy": PUPPY_SLEEP,
	"Shiba Inu": preload("res://assets/puppies/shiba_sleep_anime.png"),
	"Golden Retriever": preload("res://assets/puppies/golden_sleep_anime.png")
}
const SLEEP_REGIONS = {
	"Puppy": PUPPY_SLEEP_REGION,
	"Shiba Inu": Rect2i(43, 79, 1441, 820),
	"Golden Retriever": Rect2i(24, 210, 1489, 613)
}
const NORA = preload("res://assets/characters/nora_outdoors_v2.png")

const WALKS = {
	"Puppy": preload("res://assets/puppies/puppy_walk_anime.png"),
	"Shiba Inu": preload("res://assets/puppies/shiba_walk_anime.png"),
	"Golden Retriever": preload("res://assets/puppies/golden_walk_anime.png")
}

# Ground bounds and body anchors keep the eight walk phases aligned.
const WALK_REGIONS = {
	"Puppy": [Rect2(21, 75, 402, 337), Rect2(452, 75, 414, 338), Rect2(895, 75, 414, 338), Rect2(1337, 75, 416, 338), Rect2(17, 496, 406, 338), Rect2(460, 496, 407, 337), Rect2(894, 495, 416, 338), Rect2(1345, 495, 409, 338)],
	"Shiba Inu": [Rect2(30, 35, 413, 383), Rect2(443, 35, 443, 383), Rect2(913, 35, 416, 383), Rect2(1341, 37, 430, 381), Rect2(34, 474, 409, 383), Rect2(443, 474, 443, 382), Rect2(903, 474, 426, 382), Rect2(1345, 475, 425, 382)],
	"Golden Retriever": [Rect2(23, 76, 409, 322), Rect2(462, 76, 406, 324), Rect2(903, 76, 408, 328), Rect2(1342, 77, 411, 320), Rect2(21, 503, 407, 323), Rect2(459, 503, 409, 326), Rect2(901, 502, 410, 331), Rect2(1347, 503, 412, 323)],
}
const WALK_ANCHORS = {
	"Puppy": [207.44, 223.14, 225.04, 223.87, 216.5, 213.07, 226.99, 212.49],
	"Shiba Inu": [207.9, 233.16, 204.3, 221.75, 202.66, 235.88, 216.97, 219.26],
	"Golden Retriever": [205.78, 207.29, 207.41, 210.94, 207.99, 211.44, 209.41, 208.26],
}
const WALK_HEIGHTS = {"Puppy": 338.0, "Shiba Inu": 382.5, "Golden Retriever": 323.5}

const REN = preload("res://assets/characters/ren_redrawn_anime.png")
const BACKGROUNDS = {"Harbor": preload("res://assets/backgrounds/harbor_anime.png"), "Keeper’s Cottage": preload("res://assets/backgrounds/cottage_anime.png"),"Home": HOME, "Park": PARK, "Beach": BEACH,
	"Puppy Club": preload("res://assets/backgrounds/club_anime.png"),
	"Shop": preload("res://assets/backgrounds/shop_anime.png"),
	"Vet Clinic": preload("res://assets/backgrounds/vet_anime.png"),
	"Lighthouse": preload("res://assets/backgrounds/lighthouse_anime.png"),
}
const JUNE = preload("res://assets/characters/june_shop_v2.png")
const LEAH = preload("res://assets/characters/leah_anime.png")

const BEN = preload("res://assets/characters/ben_anime.png")
const KAI = preload("res://assets/characters/kai_beach.png")
const OWEN = preload("res://assets/characters/owen_anime.png")

const NORA_CORAL = preload("res://assets/characters/nora_coral_braid.png")
const JUNE_MINT = preload("res://assets/characters/june_mint_parcel.png")

const BEN_TRAINING = preload("res://assets/characters/ben_training.png")
const LEAH_TUNIC = preload("res://assets/characters/leah_tunic.png")
const OWEN_PARCEL = preload("res://assets/characters/owen_parcel.png")
const REN_SWEATER = preload("res://assets/characters/ren_sweater.png")

static func daily_portrait(texture: Texture2D, date: String = "") -> Texture2D:
	if date.is_empty():
		date = Time.get_date_string_from_system(false)
	var day = int(Time.get_unix_time_from_datetime_string(date) / 86400)
	var wardrobes = [[NORA, NORA_CORAL], [JUNE, JUNE_MINT], [BEN, BEN_TRAINING], [LEAH, LEAH_TUNIC], [OWEN, OWEN_PARCEL], [REN, REN_SWEATER]]
	for index in wardrobes.size():
		if texture in wardrobes[index]:
			return wardrobes[index][posmod(day + index, 2)]
	return texture
