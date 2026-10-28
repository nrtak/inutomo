class_name IslandStory
extends RefCounted

const FLAGS = ["welcome", "kit", "met_keeper", "delivered", "lantern", "repair_supplies", "path_repaired", "lens_polished", "beacon_checked"]

static func valid(data: Variant) -> bool:
 if not data is Dictionary:
  return false
 for flag in data:
  if flag not in FLAGS or not data[flag] is bool:
   return false
 if data.get("kit", false) and not data.get("welcome", false):
  return false
 if data.get("delivered", false) and not (data.get("kit", false) and data.get("met_keeper", false)):
  return false
 if data.get("lantern", false) and not data.get("delivered", false):
  return false
 for pair in [["repair_supplies", "lantern"], ["path_repaired", "repair_supplies"], ["lens_polished", "path_repaired"], ["beacon_checked", "lens_polished"]]:
  if data.get(pair[0], false) and not data.get(pair[1], false):
   return false
 return true

static func restoration_step(game: Node) -> Dictionary:
 var story: Dictionary = game.life.story
 if not story.get("repair_supplies", false):
  return {"text":"Ren needs a repair crate from Owen at the Harbor.", "button":"Collect repair crate", "place":"Harbor", "action":"repair_supplies"}
 if not story.get("path_repaired", false):
  return {"text":"Bring the crate to Ren and help repair the cottage path.", "button":"Repair cottage path", "place":"Keeper’s Cottage", "action":"path_repaired"}
 if not story.get("lens_polished", false):
  if "Sea glass" not in game.life.keepsakes:
   return {"text":"Finish a Beach Walk to find sea glass for Ren's light display. You keep your keepsake.", "button":"Find sea glass", "place":"Beach", "action":""}
  return {"text":"Show Ren your sea glass and help polish his display lens. Your keepsake stays with you.", "button":"Polish display lens", "place":"Keeper’s Cottage", "action":"lens_polished"}
 if not story.get("beacon_checked", false):
  return {"text":"Join Ren at the cottage while he checks the lighthouse signal.", "button":"Check lighthouse signal", "place":"Keeper’s Cottage", "action":"beacon_checked"}
 return {"text":"Restoration complete! The cottage path and display are ready, and Ren checked the beacon. Tower visits will come in a later chapter.", "button":"Visit Ren", "place":"Keeper’s Cottage", "action":""}

static func next_step(game: Node) -> Dictionary:
 var story: Dictionary = game.life.story
 if not story.get("welcome", false):
  return {"text": "Owen is waiting at the Harbor ferry office.", "button": "Visit Harbor", "place": "Harbor"}
 if not story.get("kit", false):
  return {"text": "Collect Ren's lantern kit from Owen at the Harbor.", "button": "Collect at Harbor", "place": "Harbor"}
 if not story.get("met_keeper", false):
  return {"text": "Take the lantern kit to Ren at the Keeper’s Cottage.", "button": "Visit Cottage", "place": "Keeper’s Cottage"}
 if not story.get("delivered", false):
  return {"text": "Ren is ready to receive his lantern kit.", "button": "Return to Ren", "place": "Keeper’s Cottage"}
 if not story.get("lantern", false):
  return {"text": "Help Ren prepare the porch lantern for evening.", "button": "Help with lantern", "place": "Keeper’s Cottage"}
 return restoration_step(game)

static func advance(game: Node, action: String) -> String:
 var story: Dictionary = game.life.story
 var message = ""
 var memory = ""
 match action:
  "welcome":
   if story.get("welcome", false):
    return "Welcome back! Ren's cottage is up the coastal path."
   story.welcome = true
   message = "Welcome to the Harbor! Ren's lantern kit arrived on the ferry. Collect it here when you're ready."
   memory = "Owen welcomed us at the Harbor ferry office."
  "kit":
   if not story.get("welcome", false):
    return "Talk to Owen at the Harbor first."
   if story.get("kit", false):
    return "The lantern kit is already delivered." if story.get("delivered", false) else "You have the lantern kit. Visit Ren at the Keeper’s Cottage."
   story.kit = true
   message = "Lantern kit collected! Take it to Ren at the Keeper’s Cottage."
   memory = "Collected Ren's lantern kit from the Harbor."
  "meet":
   if story.get("met_keeper", false):
    if story.get("lantern", false):
     return restoration_step(game).text
    if story.get("delivered", false):
     return "The kit is here. Let's prepare the porch lantern for evening."
    if story.get("kit", false):
     return "You brought the lantern kit! Choose Deliver lantern kit when you're ready."
    return "Owen has my lantern kit at the Harbor. Could you bring it over?"
   story.met_keeper = true
   message = "I'm Ren, the lighthouse keeper. You brought my lantern kit! Choose Deliver lantern kit when you're ready." if story.get("kit", false) else "I'm Ren, the lighthouse keeper. My lantern kit is at the Harbor. Could you bring it over?"
   memory = "Met Ren, the lighthouse keeper."
  "deliver":
   if story.get("delivered", false):
    return "Ren already has the kit. Thank you!"
   if not story.get("kit", false) or not story.get("met_keeper", false):
    return "Meet Ren and collect the kit at the Harbor first."
   story.delivered = true
   message = "Thank you for bringing the kit! Let's prepare the porch lantern for evening."
   memory = "Delivered the lantern kit to Ren."
  "lantern":
   if story.get("lantern", false):
    return "The porch lantern is ready for evening. Thank you for helping!"
   if not story.get("delivered", false):
    return "Bring Ren the lantern kit first."
   story.lantern = true
   message = "Ready for evening! A welcoming light for the island. Your first Harbor story is complete."
   memory = "Helped Ren prepare a welcoming porch lantern."
  "repair_supplies", "path_repaired", "lens_polished", "beacon_checked":
   if story.get(action, false):
    return "That restoration task is already complete. " + restoration_step(game).text
   if not story.get("lantern", false):
    return "Help Ren prepare the porch lantern first."
   var step = restoration_step(game)
   if step.action != action:
    return step.text
   story[action] = true
   var messages = {
    "repair_supplies":"Owen handed over the repair crate. Take it to Ren at the cottage.",
    "path_repaired":"The cottage path is tidy and repaired! Next, let's add a sea-glass display beside the lantern.",
    "lens_polished":"The display lens sparkles beside your sea glass. Your keepsake stays in your collection.",
    "beacon_checked":"Ren checked the beacon while you waited safely at the cottage. A welcoming light again! You earned 15 coins. Tower visits will come in a later chapter."
   }
   message = messages[action]
   memory = {"repair_supplies":"Collected Ren's repair crate.", "path_repaired":"Helped Ren repair the cottage path.", "lens_polished":"Helped polish Ren's sea-glass display lens.", "beacon_checked":"Finished Ren's restoration chapter and checked the beacon."}[action]
   if action == "beacon_checked":
    game.coins = mini(1000000, game.coins + 15)
  _:
   return "Choose a Harbor or cottage activity."
 game.remember(memory)
 game.changed.emit()
 game.save_game()
 return message
