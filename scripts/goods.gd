class_name Goods
extends RefCounted
const ITEMS = {
 "Medicine": {"name":"Leah’s medicine", "category":"Care", "price":8, "limit":3, "icon":"medicine", "vet_only":true, "description":"For illnesses diagnosed by Leah. One dose starts recovery. No extra dose is needed. Free treatment is available at Vet Clinic."},
 "Bandage": {"name":"Paw bandages", "category":"Care", "price":6, "limit":3, "icon":"bandage", "vet_only":true, "description":"For a sore paw diagnosed by Leah. One bandage starts recovery. Free treatment is available at Vet Clinic."},
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
static func featured(date: String = "") -> Array:
 if date.is_empty():
  date = Time.get_date_string_from_system(false)
 var day = int(Time.get_unix_time_from_datetime_string(date) / 86400)
 var accessories = ["CoralBandana", "SunshineBandana", "LavenderBandana"]
 var snacks = ["Treat", "TrainingTreat", "CelebrationTreat", "PicnicPack"]
 var comforts = ["PlushToy", "TugRope", "CloudBed", "CoolingMat", "Blanket"]
 return [accessories[posmod(day, accessories.size())], snacks[posmod(day, snacks.size())], comforts[posmod(day, comforts.size())]]

static func prices() -> Dictionary:
 var values = {}
 for kind in ITEMS:
  values[kind] = ITEMS[kind].price
 return values
static func icon(kind: String) -> Texture2D:
 return load("res://assets/ui/" + ITEMS[kind].icon + ".svg")

static func picture(kind: String) -> Texture2D:
 if kind == "Toy":
  return preload("res://assets/ui/beach_ball.svg")
 if kind in ["PuppyMeal","AdultMeal"]:
  return preload("res://assets/goods/bowl_cel.svg")
 var cel_props = {"Bed":"bed","CloudBed":"cloud_bed","CoolingMat":"mat","Blanket":"blanket","PlushToy":"plush","TugRope":"rope","PicnicPack":"picnic"}
 if cel_props.has(kind):
  return load("res://assets/goods/"+cel_props[kind]+"_cel.svg")
 return icon(kind)
