class_name IslandActivities
extends RefCounted

const BEACH_GAMES = ["Shells", "Cleanup", "Sand Fetch"]
static func fresh() -> Dictionary:
 return {"day":"", "shell":false, "cleaned":[], "throws":0, "done":[]}

static func valid(data: Variant) -> bool:
 if not data is Dictionary or not data.get("day", "") is String or not data.get("shell",false) is bool:
  return false
 var throws = data.get("throws",0)
 if not (throws is int or throws is float) or not is_finite(float(throws)) or throws < 0 or throws > 3 or throws != floorf(throws):
  return false
 for key in ["cleaned", "done"]:
  var values = data.get(key,[])
  if not values is Array or values.size() > 3:
   return false
  var seen = []
  for value in values:
   if value in seen or (value not in BEACH_GAMES if key == "done" else (not value is int and not value is float)):
    return false
   if key == "cleaned" and (value < 0 or value > 2 or value != floorf(value)):
    return false
   seen.append(value)
 var done = data.get("done",[])
 var has_progress = data.get("shell",false) or throws > 0 or not data.get("cleaned",[]).is_empty() or not done.is_empty()
 if has_progress and data.get("day", "") == "":
  return false
 return (data.get("shell",false) == ("Shells" in done)) and ((data.get("cleaned",[]).size() == 3) == ("Cleanup" in done)) and ((throws == 3) == ("Sand Fetch" in done))

static func normalized(data: Dictionary) -> Dictionary:
 var result = fresh()
 result.merge(data,true)
 result.throws = int(result.throws)
 return result

static func refresh(game: Node) -> void:
 if game.life.beach.day < IslandLife.today():
  game.life.beach = fresh()
  game.life.beach.day = IslandLife.today()

static func beach_action(game: Node, kind: String, choice: int = 0) -> String:
 if kind not in BEACH_GAMES:
  return "Choose a beach activity."
 if not game.can_explore():
  return "Recover with Leah first." if PuppyHealth.unwell(game) else "Wake up and rest first. Beach activities need 15 Energy."
 refresh(game)
 var beach: Dictionary = game.life.beach
 if beach.day > IslandLife.today() or kind in beach.done:
  return "Already completed today. Come back another day!"
 if game.cooldowns.get("Beach",0) > 0:
  return "Let those paws take a short breather."
 var reply = ""
 match kind:
  "Shells":
   if choice != 0:
    return "Sea glass is smooth glass. Look for the shell's curved ridges and try again."
   beach.shell = true
   reply = "A pearl shell! Its curved ridges help you recognize it. Leave living shells on the shore."
  "Cleanup":
   if choice < 0 or choice > 2 or choice in beach.cleaned:
    return "That patch is already tidy. Choose another piece of litter."
   beach.cleaned.append(choice)
   reply = "A cleaner shore! " + str(beach.cleaned.size()) + " of 3 pieces collected."
  "Sand Fetch":
   beach.throws = mini(3,beach.throws+1)
   reply = "A gentle roll across the sand. " + str(beach.throws) + " of 3 returns!"
 game.cooldowns.Beach = 3.0
 var completed = beach.shell if kind == "Shells" else (beach.cleaned.size() == 3 if kind == "Cleanup" else beach.throws == 3)
 if completed:
  beach.done.append(kind)
  game.needs.Happiness = minf(100,game.needs.Happiness+5)
  game.needs.Energy = maxf(0,game.needs.Energy-3)
  game.coins = mini(1000000,game.coins+4)
  game.remember("Enjoyed " + kind.to_lower() + " with Kai at the Beach.")
  reply += " You earned 4 coins."
  game.get_node("/root/Sound").feedback("discovery")
 game.care_performed.emit("Play" if kind == "Sand Fetch" else "Sniff")
 game.changed.emit()
 game.save_game()
 return reply

static func daily_card(game: Node) -> Array:
 IslandLife.refresh_day(game)
 if PuppyHealth.unwell(game):
  return [{"focus":"", "title":"Visit Leah", "place":"Vet Clinic", "icon":"clinic", "done":game.health.diagnosed}, {"focus":"Care", "title":"Brush your puppy", "place":"Home", "icon":"care", "done":game.life.daily.get("Care",0)>0}, {"focus":"Rest", "title":"Rest at Home", "place":"Home", "icon":"rest", "done":game.resting}]
 return [{"focus":"Feed", "title":"Feed your puppy", "place":"Home", "icon":"feed", "done":game.life.daily.get("Feed",0)>0}, {"focus":"", "title":"Try a beach game", "place":"Beach", "icon":"island", "done":game.life.daily.get("Walk",0)+game.life.daily.get("Fetch",0)>0 or (game.life.beach.day == IslandLife.today() and not game.life.beach.done.is_empty())}, {"focus":"", "title":"Start a puppy playdate", "place":"Life:Playdate", "icon":"heart", "done":game.life.playdate.claimed >= IslandLife.today()}]

static func greeting(game: Node, person: String, fallback: String) -> String:
 var name: String = game.puppy_name
 if person == "Leah" and not PuppyHealth.unwell(game) and not game.health.history.is_empty() and game.health.history[0].event == "Recovered":
  return name + " has recovered nicely. Keep enjoying meals, gentle care and rest. Your Health history keeps the record."
 if person == "Ben":
  var learned = 0
  for level in game.life.training.values():
   if level == 5:
    learned += 1
  if learned > 0:
   return name + " has learned " + str(learned) + (" command!" if learned == 1 else " commands!") + " Visit Training to practice or try another lesson."
 if person == "June" and Goods.ITEMS.has(game.life.accessory) and game.items.get(game.life.accessory,0)>0:
  return "That " + Goods.ITEMS[game.life.accessory].name.to_lower() + " looks lovely on " + name + "! Tap a shop picture to preview another look."
 if person == "Nora" and game.life.playdate.visits > 0:
  return "Lovely to see you both again! " + name + " has enjoyed " + str(game.life.playdate.visits) + (" playdate." if game.life.playdate.visits == 1 else " playdates.") + " Shall we meet our puppy friend again?"
 if person in ["Owen", "Ren"] and game.life.delivery.completed > 0:
  return "Thank you for helping with the Harbor parcels! " + str(game.life.delivery.completed) + (" delivery completed. " if game.life.delivery.completed == 1 else " deliveries completed. ") + (IslandLife.delivery_info(game).text if person == "Owen" else "The cottage always welcomes you both.")
 if person == "Kai" and game.life.beach.day == IslandLife.today() and not game.life.beach.done.is_empty():
  return "Thanks for joining our beach activities! " + str(game.life.beach.done.size()) + " completed today. Enjoy a rest and the sea breeze."
 return fallback
