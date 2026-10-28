class_name Goods
extends RefCounted
const ITEMS = {
 "Treat": {"name": "Puppy biscuits", "category": "Food", "price": 10, "limit": 5, "icon": "treat", "description": "Adds up to 8 Hunger to a meal; saved if the meal would already fill the bar. Or give one as a small snack."},
 "TrainingTreat": {"name": "Training bites", "category": "Food", "price": 8, "limit": 5, "icon": "training_treat", "description": "A little reward that boosts Happiness. Give from your Bag."},
 "Toy": {"name": "Bouncy ball", "category": "Toys", "price": 25, "limit": 1, "icon": "play", "description": "Keep forever. Every Play restores 4 extra Happiness."},
 "Brush": {"name": "Soft brush", "category": "Care", "price": 20, "limit": 1, "icon": "care", "description": "Keep forever. Every Care restores 4 extra Cleanliness."},
 "Shampoo": {"name": "Gentle shampoo", "category": "Care", "price": 12, "limit": 5, "icon": "shampoo", "description": "Use from your Bag for 25 Cleanliness. One bottle per use."},
 "Bed": {"name": "Cozy bed", "category": "Comfort", "price": 40, "limit": 1, "icon": "bed", "description": "Keep forever. Rest restores Energy about 30% faster."},
 "PuppyMeal": {"name": "Puppy meal", "category": "Food", "price": 6, "limit": 5, "icon": "feed", "need": "Hunger", "amount": 24, "description": "A little bowl for a growing friend. Restores Hunger."},
 "AdultMeal": {"name": "Hearty meal", "category": "Food", "price": 9, "limit": 5, "icon": "feed", "need": "Hunger", "amount": 32, "description": "A filling meal for any hungry dog."},
 "PicnicPack": {"name": "Picnic pack", "category": "Food", "price": 12, "limit": 5, "icon": "menu_bag", "need": "Hunger", "amount": 28, "description": "Enjoy a little island picnic. Fills Hunger and adds Happiness."},
 "CelebrationTreat": {"name": "Party biscuit", "category": "Food", "price": 12, "limit": 5, "icon": "heart", "need": "Happiness", "amount": 18, "description": "A special little reward for happy occasions."},
 "PlushToy": {"name": "Cuddle plush", "category": "Toys", "price": 28, "limit": 1, "icon": "heart", "description": "A soft playmate. Choose it in Home decorating."},
 "TugRope": {"name": "Tug rope", "category": "Toys", "price": 28, "limit": 1, "icon": "play", "description": "A playful favorite. Choose it in Home decorating."},
 "CloudBed": {"name": "Cloud bed", "category": "Comfort", "price": 45, "limit": 1, "icon": "bed", "description": "A soft pink bed. Rest recovers Energy faster."},
 "CoolingMat": {"name": "Cooling mat", "category": "Comfort", "price": 35, "limit": 1, "icon": "bed", "description": "A cool blue resting spot. Rest recovers Energy faster."},
 "Blanket": {"name": "Soft blanket", "category": "Comfort", "price": 30, "limit": 1, "icon": "bed", "description": "A folded cream blanket for a cozy resting spot. Rest recovers Energy faster."},
 "CoralBandana": {"name": "Coral bandana", "category": "Accessories", "price": 18, "limit": 1, "icon": "bandana_coral", "color": Color("ef8b9b"), "description": "A cheerful coral bandana. Preview and wear it in Wardrobe."},
 "SunshineBandana": {"name": "Sunshine bandana", "category": "Accessories", "price": 18, "limit": 1, "icon": "bandana_sunshine", "color": Color("f5c65b"), "description": "A warm yellow bandana. Preview and wear it in Wardrobe."},
 "LavenderBandana": {"name": "Lavender bandana", "category": "Accessories", "price": 18, "limit": 1, "icon": "bandana_lavender", "color": Color("b4a1e1"), "description": "A gentle purple bandana. Preview and wear it in Wardrobe."}
}
const CATEGORIES = ["Food", "Toys", "Care", "Comfort", "Accessories"]
static func prices() -> Dictionary:
 var values = {}
 for kind in ITEMS:
  values[kind] = ITEMS[kind].price
 return values
static func icon(kind: String) -> Texture2D:
 return load("res://assets/ui/" + ITEMS[kind].icon + ".svg")

const PICTURE_SHEET = preload("res://assets/goods/goods_anime.png")
const EXPANDED_SHEET = preload("res://assets/goods/expanded_goods_anime.png")
const EXPANDED_REGIONS = {
 "PuppyMeal": Rect2(65, 163, 298, 194), "AdultMeal": Rect2(429, 123, 395, 251), "PicnicPack": Rect2(870, 33, 357, 368),
 "CelebrationTreat": Rect2(82, 504, 280, 256), "PlushToy": Rect2(452, 457, 348, 328), "TugRope": Rect2(852, 475, 376, 313),
 "CloudBed": Rect2(25, 867, 392, 313), "CoolingMat": Rect2(439, 920, 381, 253), "Blanket": Rect2(847, 892, 383, 289)
}
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
 if kind == "Toy":
  return preload("res://assets/ui/play.svg")
 if EXPANDED_REGIONS.has(kind):
  if not pictures.has(kind):
   var expanded = AtlasTexture.new()
   expanded.atlas = EXPANDED_SHEET
   expanded.region = EXPANDED_REGIONS[kind]
   pictures[kind] = expanded
  return pictures[kind]
 if not PICTURE_REGIONS.has(kind):
  return icon(kind)
 if not pictures.has(kind):
  var atlas = AtlasTexture.new()
  atlas.atlas = PICTURE_SHEET
  atlas.region = PICTURE_REGIONS[kind]
  pictures[kind] = atlas
 return pictures[kind]
