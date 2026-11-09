class_name IslandAdventure
extends RefCounted

const BUDDIES = {
 "Momo":{"breed":"Shiba Inu","nature":"Playful","color":Color("ef8b9b")},
 "Pippin":{"breed":"Golden Retriever","nature":"Gentle","color":Color("b4a1e1")},
 "Milo":{"breed":"Puppy","nature":"Curious","color":Color("f5c65b")}
}
const CHAPTERS = {
 "Nora":{"title":"A place for everyone","task":"Playdate","goal":1,"intro":"I want every new puppy to feel at home. Share a playdate, then tell me how it went.","middle":"A quiet hello can be the start of a lovely friendship. Your puppy helped our newest friend feel welcome.","end":"I've put a little welcome ribbon in our club memory book. You both belong here."},
 "Ben":{"title":"Small victories","task":"Training","goal":2,"intro":"My first dog needed patience, too. Try two short lessons. Progress matters more than perfect tricks.","middle":"See that confidence? It grows when you celebrate the small tries. I still remember my first successful lesson.","end":"You're a good team. I've added your practice day to our trainer's memory book."},
 "June":{"title":"The picnic basket","task":"Feed","goal":1,"intro":"My family used to pack picnics for the harbor. Share a meal with your dog, then come back for a little story.","middle":"Those shared meals made the island feel like home. I hope your little friend feels the same.","end":"A good picnic needs company more than fancy things. Thank you for making another island memory with me."},
 "Leah":{"title":"Gentle hands","task":"Care","goal":1,"intro":"I learned to be a vet by caring for a shy island puppy. Give your dog a gentle brush, then visit again.","middle":"Patient care builds trust. That shy puppy eventually brought every visitor a toy!","end":"You have those same gentle hands. Keep making room for quiet moments together."},
 "Owen":{"title":"Letters from the sea","task":"Delivery","goal":1,"intro":"The ferry brought my first letter from a faraway friend. Finish a harbor parcel delivery and I'll tell you about it.","middle":"That letter reminded me that a small delivery can mean a great deal. Yours brightened someone's day, too.","end":"One day I'll write a new letter about you and your puppy. You're part of the harbor's story now."},
 "Kai":{"title":"The quiet shore","task":"Beach","goal":1,"intro":"I came here for the waves, but stayed for the people. Finish one beach game, then come share the view.","middle":"Helping a little makes this beach everyone's home. My favorite days aren't always the biggest adventures.","end":"Sometimes a clean shore, a dog beside you, and a sea breeze are all you need. Thanks for joining me."},
 "Ren":{"title":"A light to come home to","task":"Walk","goal":1,"intro":"The lighthouse once guided my father's boat home. Take a coastal Walk, then come back for the rest of the story.","middle":"He said the light meant someone was waiting. That's why I keep caring for it, even on quiet days.","end":"Now there are two more friends to welcome home. Thank you for sharing this little corner of the island."}
}
const TRAILS = [
 [{"name":"Heart leaf","icon":"leaf","clue":"A leafy scent. Look beneath the big tree.","point":Vector2(400,550)}, {"name":"Blue ribbon","icon":"bandana_coral","clue":"A little ribbon scent beside the fountain path.","point":Vector2(570,595)}, {"name":"Hidden ball","icon":"play","clue":"Your dog's favorite toy scent near the sunny bench.","point":Vector2(740,575)}],
 [{"name":"Rainy leaf","icon":"leaf","clue":"A fresh leafy scent by the tree.","point":Vector2(400,550)}, {"name":"Shell token","icon":"shell","clue":"A salty scent on the fountain path.","point":Vector2(570,595)}, {"name":"Hidden plush","icon":"heart","clue":"A soft toy scent near the sheltered bench.","point":Vector2(740,575)}]
]

static func fresh() -> Dictionary:
 return {"playmate":"Momo","active_playmate":"","buddies":{},"chapters":{},"scent":{"day":"","step":0,"route":0,"claimed":"","visits":0},"tower_visited":false}

static func integer(value: Variant, maximum: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= maximum and value == floorf(value)

static func date(value: Variant) -> bool:
 return value is String and (value == "" or LocalDate.valid(value))

static func valid(data: Variant) -> bool:
 if not data is Dictionary or data.get("playmate","Momo") not in BUDDIES or data.get("active_playmate","") not in ["","Momo","Pippin","Milo"] or not data.get("tower_visited",false) is bool:
  return false
 for field in ["buddies","chapters","scent"]:
  if not data.get(field,{}) is Dictionary:
   return false
 for name in data.get("buddies",{}):
  var buddy = data.buddies[name]
  if name not in BUDDIES or not buddy is Dictionary or not integer(buddy.get("visits",0),1000) or not date(buddy.get("bonus_day","")):
   return false
 for person in data.get("chapters",{}):
  var chapter = data.chapters[person]
  if person not in CHAPTERS or not chapter is Dictionary or not integer(chapter.get("step",0),3) or not integer(chapter.get("progress",0),2):
   return false
  if chapter.get("step",0) == 0 and chapter.get("progress",0) != 0:
   return false
  if chapter.get("step",0) >= 2 and chapter.get("progress",0) < CHAPTERS[person].goal:
   return false
 var scent = data.get("scent",{})
 for field in ["day","claimed"]:
  if not date(scent.get(field,"")):
   return false
 if not integer(scent.get("step",0),3) or not integer(scent.get("route",0),1) or not integer(scent.get("visits",0),1000):
  return false
 if scent.get("step",0)>0 and scent.get("day","")=="":
  return false
 if scent.get("step",0)==3 and scent.get("claimed","")!=scent.get("day",""):
  return false
 if scent.get("claimed","")!="" and scent.get("claimed","")==scent.get("day","") and scent.get("step",0)!=3:
  return false
 return true

static func normalized(data: Dictionary) -> Dictionary:
 var result = fresh()
 result.merge(data.duplicate(true),true)
 var scent: Dictionary = fresh().scent
 scent.merge(result.scent,true)
 for field in ["step","route","visits"]:
  scent[field] = int(scent[field])
 result.scent = scent
 for name in result.buddies:
  result.buddies[name] = {"visits":int(result.buddies[name].get("visits",0)),"bonus_day":result.buddies[name].get("bonus_day","")}
 for person in result.chapters:
  result.chapters[person] = {"step":int(result.chapters[person].get("step",0)),"progress":int(result.chapters[person].get("progress",0))}
 return result

static func companion(game: Node) -> String:
 var active: String = game.life.adventure.active_playmate
 return active if game.life.playdate.day == IslandLife.today() and game.life.playdate.step > 0 and game.life.playdate.step < 3 and active in BUDDIES else game.life.adventure.playmate

static func choose_buddy(game: Node, name: String) -> String:
 if name not in BUDDIES:
  return "Choose an island dog friend."
 if game.life.playdate.day == IslandLife.today() and game.life.playdate.step > 0 and game.life.playdate.step < 3:
  return "Finish this playdate before choosing another friend."
 game.life.adventure.playmate = name
 game.save_game()
 return "Next playdate: " + name + "."

static func buddy_visits(game: Node, name: String) -> int:
 return int(game.life.adventure.buddies.get(name,{}).get("visits",0))

static func buddy_level(visits: int) -> String:
 return "Best friends" if visits >= 7 else ("Close friends" if visits >= 4 else ("Playmates" if visits >= 2 else "New friends"))

static func finish_playdate(game: Node) -> String:
 var name = companion(game)
 var record: Dictionary = game.life.adventure.buddies.get(name,{"visits":0,"bonus_day":""})
 record.visits = mini(1000,int(record.visits)+1)
 game.life.adventure.buddies[name] = record
 record_task(game,"Playdate")
 return buddy_greeting(game,name) + " " + buddy_level(record.visits) + "."

static func buddy_greeting(game: Node, name: String) -> String:
 var visits = buddy_visits(game,name)
 if visits>=7: return name+" runs over for a familiar nose-to-nose hello!"
 if visits>=4: return name+" brings the ball over to "+game.puppy_name+"."
 if visits>=2: return name+" recognizes "+game.puppy_name+" with a happy tail!"
 return name+" gives "+game.puppy_name+" a gentle first sniff."

static func shared_activity(game: Node, name: String, kind: String) -> String:
 var visits = buddy_visits(game,name)
 if name not in BUDDIES or kind not in ["Mirror tricks","Treasure pals"] or visits < (2 if kind == "Mirror tricks" else 4):
  return "More playdates will unlock this activity."
 if not game.can_explore():
  return "A little recovery or rest first."
 var record: Dictionary = game.life.adventure.buddies[name]
 if record.get("bonus_day","") >= IslandLife.today():
  return "A lovely day together! Try again tomorrow."
 record.bonus_day = IslandLife.today()
 var earned = mini(2,1000000-game.coins)
 game.coins += earned
 game.needs.Happiness = minf(100,game.needs.Happiness+4)
 game.needs.Energy = maxf(0,game.needs.Energy-2)
 game.care_performed.emit("Paw" if kind == "Mirror tricks" else "Sniff")
 game.remember("Enjoyed " + kind.to_lower() + " with " + name + ".")
 game.changed.emit()
 game.save_game()
 return name + (" copies your puppy's happy paw!" if kind == "Mirror tricks" else " helps uncover a hidden toy!") + (" %d coins earned." % earned if earned > 0 else " Your coin purse is full.")

static func record_task(game: Node, task: String) -> void:
 IslandConnections.record(game, task)
 WelcomeDay.record_task(game, task)
 for person in game.life.adventure.chapters:
  var chapter: Dictionary = game.life.adventure.chapters[person]
  if chapter.step == 1 and CHAPTERS[person].task == task:
   chapter.progress = mini(CHAPTERS[person].goal,int(chapter.progress)+1)

static func chapter_status(game: Node, person: String) -> Dictionary:
 var chapter: Dictionary = game.life.adventure.chapters.get(person,{"step":0,"progress":0})
 var spec: Dictionary = CHAPTERS[person]
 var ready = chapter.step != 1 or chapter.progress >= spec.goal
 return {"step":int(chapter.step),"ready":ready,"title":spec.title,"button":"Story complete" if chapter.step==3 else ("Hear the story" if chapter.step==0 else ("Continue story" if ready else "View story task")),"task":spec.task,"goal":spec.goal,"progress":chapter.progress}

static func chapter(game: Node, person: String) -> String:
 if person not in CHAPTERS:
  return "Choose an island resident."
 var spec: Dictionary = CHAPTERS[person]
 var entry: Dictionary = game.life.adventure.chapters.get(person,{"step":0,"progress":0})
 if entry.step == 0:
  entry.step = 1
 elif entry.step == 1:
  if entry.progress < spec.goal:
   return "Our next little memory: " + str(entry.progress) + " of " + str(spec.goal) + " completed. " + spec.intro
  entry.step = 2
 elif entry.step == 2:
  entry.step = 3
  game.remember("Shared " + spec.title.to_lower() + " with " + person + ".")
  var friend: Dictionary = game.life.friends.get(person,{"hearts":0,"talked":""})
  friend.hearts = mini(20,int(friend.hearts)+2)
  game.life.friends[person] = friend
 game.life.adventure.chapters[person] = entry
 game.changed.emit()
 game.save_game()
 return spec.intro if entry.step==1 else (spec.middle if entry.step==2 else spec.end)

static func begin_scent(game: Node) -> bool:
 if not game.can_explore():
  return false
 var scent: Dictionary = game.life.adventure.scent
 if scent.day < IslandLife.today():
  scent.day = IslandLife.today()
  scent.step = 0
  scent.route = 1 if IslandWeather.current()=="Light rain" else 0
 game.save_game()
 return scent.day == IslandLife.today() and scent.step < 3

static func scent_stop(game: Node) -> Dictionary:
 var scent: Dictionary = game.life.adventure.scent
 return TRAILS[scent.route][mini(scent.step,2)]

static func sniff(game: Node, choice: int) -> Dictionary:
 var scent: Dictionary = game.life.adventure.scent
 if not game.can_explore() or scent.day != IslandLife.today() or scent.claimed >= IslandLife.today():
  return {"ok":false,"text":"A little rest first, or return for a new trail tomorrow."}
 if game.cooldowns.get("Scent",0)>0:
  return {"ok":false,"text":"Let your dog finish this sniff."}
 if choice != scent.step:
  game.care_performed.emit("Sniff")
  return {"ok":false,"text":"Not this scent. Follow the clue and try another spot."}
 var found: String = scent_stop(game).name
 scent.step += 1
 GrowthRoutes.record(game,"Scent")
 game.cooldowns.Scent = 2.0
 game.care_performed.emit("Sniff")
 var reply = found + " found!"
 if scent.step == 3:
  scent.claimed = scent.day
  scent.visits = mini(1000,int(scent.visits)+1)
  var earned = mini(6,1000000-game.coins)
  game.coins += earned
  game.needs.Happiness = minf(100,game.needs.Happiness+6)
  game.needs.Energy = maxf(0,game.needs.Energy-4)
  game.remember("Followed a scent trail to a hidden toy at the Park.")
  reply += " Trail complete! " + ("%d coins earned." % earned if earned>0 else "Your coin purse is full.")
 game.changed.emit()
 game.save_game()
 return {"ok":true,"text":reply}

static func tower_open(game: Node) -> bool:
 return bool(game.life.story.get("beacon_checked",false))

static func visit_tower(game: Node) -> bool:
 if not tower_open(game):
  return false
 if not game.life.adventure.tower_visited:
  game.life.adventure.tower_visited = true
  game.remember("Our first visit to Ren's lighthouse observation room.")
  game.changed.emit()
  game.save_game()
 return true
