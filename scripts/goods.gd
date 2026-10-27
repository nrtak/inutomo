class_name Goods
extends RefCounted
const ITEMS = {
 "Treat": {"name": "Puppy biscuits", "category": "Food", "price": 10, "limit": 5, "icon": "treat", "description": "Adds up to 8 Hunger to a meal; saved if the meal would already fill the bar. Or give one as a small snack."},
 "TrainingTreat": {"name": "Training bites", "category": "Food", "price": 8, "limit": 5, "icon": "training_treat", "description": "A little reward that boosts Happiness. Give from your Bag."},
 "Toy": {"name": "Bouncy ball", "category": "Toys", "price": 25, "limit": 1, "icon": "play", "description": "Keep forever. Every Play restores 4 extra Happiness."},
 "Brush": {"name": "Soft brush", "category": "Care", "price": 20, "limit": 1, "icon": "care", "description": "Keep forever. Every Care restores 4 extra Cleanliness."},
 "Shampoo": {"name": "Gentle shampoo", "category": "Care", "price": 12, "limit": 5, "icon": "shampoo", "description": "Use from your Bag for 25 Cleanliness. One bottle per use."},
 "Bed": {"name": "Cozy bed", "category": "Comfort", "price": 40, "limit": 1, "icon": "bed", "description": "Keep forever. Rest restores Energy about 30% faster."}
}
const CATEGORIES = ["Food", "Toys", "Care", "Comfort"]
static func icon(kind: String) -> Texture2D:
 return load("res://assets/ui/" + ITEMS[kind].icon + ".svg")

const PICTURE_SHEET = preload("res://assets/goods/goods_anime.png")
const PICTURE_REGIONS = {
 "Treat": Rect2(53, 57, 459, 412),
 "TrainingTreat": Rect2(564, 100, 441, 344),
 "Toy": Rect2(1118, 96, 361, 361),
 "Brush": Rect2(50, 512, 462, 457),
 "Shampoo": Rect2(643, 512, 381, 461),
 "Bed": Rect2(1024, 597, 505, 357),
}
static var pictures: Dictionary = {}
static func picture(kind: String) -> Texture2D:
 if not pictures.has(kind):
  var atlas = AtlasTexture.new()
  atlas.atlas = PICTURE_SHEET
  atlas.region = PICTURE_REGIONS[kind]
  pictures[kind] = atlas
 return pictures[kind]
