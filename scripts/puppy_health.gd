class_name PuppyHealth
extends RefCounted

const CONDITIONS = {
 "Tummy upset": {"symptom":"An unsettled tummy and less interest in playing.", "item":"Medicine", "recovery":900.0},
 "Itchy coat": {"symptom":"An itchy coat and a little extra scratching.", "item":"Medicine", "recovery":900.0},
 "Sore paw": {"symptom":"A tender paw after too much energetic play.", "item":"Bandage", "recovery":600.0}
}
static func fresh() -> Dictionary:
 return {"history":[], "condition":"", "diagnosed":false, "treated":false, "recovery":0.0, "exposure":0.0, "strain":0, "grace":900.0}

static func valid(data: Variant) -> bool:
 if not data is Dictionary:
  return false
 var history = data.get("history", [])
 if not history is Array or history.size() > 30:
  return false
 for entry in history:
  if not entry is Dictionary or not entry.get("date", null) is String or entry.date.length() > 32:
   return false
  if entry.get("event", "") not in ["Checkup", "Treatment", "Recovered"] or entry.get("condition", "") not in CONDITIONS:
   return false
 var condition = data.get("condition", "")
 if condition != "" and condition not in CONDITIONS:
  return false
 for key in ["diagnosed", "treated"]:
  if not data.get(key,false) is bool:
   return false
 for key in ["recovery", "exposure", "strain", "grace"]:
  var value = data.get(key,0)
  if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 3600:
   return false
 if data.get("strain",0) > 3 or data.get("strain",0) != floorf(data.get("strain",0)):
  return false
 if data.get("treated",false) and not data.get("diagnosed",false):
  return false
 if condition == "" and (data.get("diagnosed",false) or data.get("treated",false) or data.get("recovery",0) > 0):
  return false
 if condition != "" and (data.get("recovery",0) <= 0 or data.get("recovery",0) > CONDITIONS[condition].recovery):
  return false
 return true

static func normalized(data: Dictionary) -> Dictionary:
 var result = fresh()
 for key in result:
  if data.has(key):
   result[key] = data[key].duplicate(true) if data[key] is Array else data[key]
 result.strain = int(result.strain)
 return result

static func unwell(game: Node) -> bool:
 return game.health.condition != ""

static func status(game: Node) -> String:
 if not unwell(game):
  return "Feeling well"
 if game.health.treated:
  return "Recovering"
 return game.health.condition if game.health.diagnosed else "Needs a checkup"

static func start(game: Node, condition: String) -> bool:
 if condition not in CONDITIONS or unwell(game):
  return false
 game.health.condition = condition
 game.health.diagnosed = false
 game.health.treated = false
 game.health.recovery = CONDITIONS[condition].recovery
 game.health.exposure = 0.0
 game.health.strain = 0
 game.remember("Mochi felt under the weather. A visit to Leah would help.")
 game.say("Mochi isn't feeling well. Visit Vet Clinic for a free checkup.")
 game.changed.emit()
 game.save_game()
 return true

static func advance(game: Node, seconds: float, active: bool, resting: bool) -> void:
 if unwell(game):
  var rate = (2.0 if resting else 1.0) if game.health.treated else (1.0 if resting else 0.25)
  if not active:
   rate = 0.5 if game.health.treated or resting else 0.0
  game.health.recovery = maxf(0, game.health.recovery - seconds * rate)
  if game.health.recovery == 0:
   record(game, "Recovered")
   var history: Array = game.health.history
   game.health = fresh()
   game.health.history = history
   game.health.grace = 1800.0
   game.remember("Mochi felt better and was ready for gentle adventures again.")
   if active:
    game.say("Mochi is feeling better!")
  return
 if game.needs.Energy >= 60:
  game.health.strain = 0
 if not active:
  return
 if game.health.grace > 0:
  game.health.grace = maxf(0,game.health.grace-seconds)
  return
 var condition = "Tummy upset" if game.needs.Hunger < 20 else ("Itchy coat" if game.needs.Cleanliness < 20 else "")
 if condition == "":
  game.health.exposure = maxf(0,game.health.exposure-seconds)
 else:
  game.health.exposure = minf(600,game.health.exposure+seconds)
  if game.health.exposure >= 600:
   start(game,condition)

static func exertion(game: Node) -> void:
 if unwell(game) or game.health.grace > 0:
  return
 game.health.strain = mini(3,game.health.strain+1) if game.needs.Energy < 25 else maxi(0,game.health.strain-1)
 if game.health.strain >= 3:
  start(game,"Sore paw")

static func checkup(game: Node) -> String:
 if not unwell(game):
  return "Mochi looks healthy. Keep enjoying meals, gentle care and rest."
 if not game.health.diagnosed:
  record(game, "Checkup")
 game.health.diagnosed = true
 game.changed.emit()
 game.save_game()
 var entry: Dictionary = CONDITIONS[game.health.condition]
 if game.health.treated:
  return game.health.condition + ": recovering well. Rest at Home helps. Walks, Fetch and training can wait until recovery."
 return game.health.condition + ". " + entry.symptom + "\n\nChoose Free treatment here, or use Leah's " + entry.item.to_lower() + " from your Bag. Rest at Home helps recovery."

static func treat(game: Node, item: String = "") -> String:
 if not unwell(game):
  return "Feeling well already. Supplies stay in your Bag."
 if not game.health.diagnosed:
  return "Ask Leah for a free checkup first. Supplies stay in your Bag."
 if game.health.treated:
  return "Treatment is already helping. Rest at Home; no extra medicine is needed."
 if item != "":
  if item != CONDITIONS[game.health.condition].item:
   return "That isn't the treatment Leah recommends. Your item stays in the Bag."
  if game.items.get(item,0) <= 0:
   return "None left in your Bag. Leah offers free treatment at Vet Clinic."
  game.items[item] -= 1
 record(game, "Treatment")
 game.health.treated = true
 game.health.recovery = minf(game.health.recovery,180.0)
 game.resting = true
 game.remember("Leah's treatment helped Mochi begin recovering.")
 game.changed.emit()
 game.care_performed.emit("Rest")
 game.save_game()
 return "Treatment given. Rest at Home helps recovery. No extra dose is needed."

static func record(game: Node, event: String) -> void:
 game.health.history.push_front({"date":Time.get_datetime_string_from_system(false, true), "event":event, "condition":game.health.condition})
 game.health.history.resize(mini(30, game.health.history.size()))

static func advice(game: Node) -> String:
 if unwell(game):
  if not game.health.diagnosed:
   return "Visit Leah for a free checkup before choosing medicine."
  if not game.health.treated:
   return "Leah recommends treatment for " + game.health.condition.to_lower() + ". Choose Free treatment at the clinic, or use the recommended supply from your Bag."
  return "Treatment is helping. Rest at Home, offer meals and gentle care, and wait for recovery before Walks, Fetch or training. No extra dose is needed."
 var lowest = "Hunger"
 for need in game.needs:
  if game.needs[need] < game.needs[lowest]:
   lowest = need
 if game.needs[lowest] >= 75:
  return "All four needs look comfortable. Keep enjoying meals, gentle care and regular rest."
 return {"Hunger":"Offer a meal at Home. Keep Hunger comfortable with regular feeding.", "Happiness":"Try a gentle pet, a favorite toy or a puppy playdate.", "Energy":"Rest at Home before another outing. Tired paws need a breather.", "Cleanliness":"Use Care at Home or visit Leah for grooming. A clean coat stays comfortable."}[lowest]
