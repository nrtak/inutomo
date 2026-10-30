extends SceneTree
var failures = 0
func _initialize():
 call_deferred("run")
func check(value: bool, message: String):
 if not value:
  push_error(message)
  failures += 1
func run():
 var game = root.get_node("Game")
 game.set_process(false)
 game.storage_path = "user://island_activities_test.json"
 game.life = IslandLife.fresh()
 game.health = PuppyHealth.fresh()
 game.intro_seen = true
 game.name_chosen = true
 game.pending_stage = ""
 game.resting = false
 game.needs = {"Hunger":80.0,"Happiness":60.0,"Energy":90.0,"Cleanliness":85.0}
 game.cooldowns = {}
 game.coins = 0
 IslandActivities.beach_action(game,"Shells",1)
 check(game.coins == 0 and game.life.beach.done.is_empty(), "Wrong shell answers do not award coins")
 IslandActivities.beach_action(game,"Shells",0)
 check(game.coins == 4 and "Shells" in game.life.beach.done, "Correct shell identification rewards once")
 IslandActivities.beach_action(game,"Shells",0)
 check(game.coins == 4, "Shell rewards cannot repeat")
 game.cooldowns.clear()
 IslandActivities.beach_action(game,"Cleanup",0)
 IslandActivities.beach_action(game,"Cleanup",1)
 check(game.life.beach.cleaned.size() == 1, "Beach steps respect the breather")
 game.cooldowns.clear()
 IslandActivities.beach_action(game,"Cleanup",0)
 check(game.life.beach.cleaned.size() == 1, "The same litter cannot be collected twice")
 game.haptics_enabled = false
 game.save_game()
 game.life = IslandLife.fresh()
 game.load_game()
 check(game.life.beach.cleaned.size() == 1 and not game.haptics_enabled, "Beach progress and vibration preferences survive reload")
 for choice in [1,2]:
  game.cooldowns.clear()
  IslandActivities.beach_action(game,"Cleanup",choice)
 for turn in 3:
  game.cooldowns.clear()
  IslandActivities.beach_action(game,"Sand Fetch")
 check(game.coins == 12 and game.life.beach.done.size() == 3, "Three different beach games each reward once")
 check(IslandActivities.valid(game.life.beach) and IslandActivities.valid({}), "Beach saves and legacy saves are supported")
 check(not IslandActivities.valid({"cleaned":[0,0]}) and not IslandActivities.valid({"throws":4}), "Malformed beach progress is rejected")
 check(IslandActivities.daily_card(game).size() == 3, "Daily card has only three suggestions")
 PuppyHealth.start(game,"Sore paw")
 game.life.beach = IslandActivities.fresh()
 game.cooldowns.clear()
 IslandActivities.beach_action(game,"Sand Fetch")
 check(game.life.beach.throws == 0, "Injured dogs wait before beach games")
 check(IslandActivities.daily_card(game)[0].place == "Vet Clinic", "Recovery daily card points to Leah")
 game.health = PuppyHealth.fresh()
 game.life.training.Sit = 5
 check("learned" in IslandActivities.greeting(game,"Ben","fallback"), "Ben remembers learned commands")
 game.life.playdate.visits = 2
 check("2 playdates" in IslandActivities.greeting(game,"Nora","fallback"), "Nora remembers past playdates")
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 main.show_page("Life:Beach Activities")
 await process_frame
 var browser = main.body.get_child(0)
 check(browser.mode == "Beach Activities" and main.habitat.location == "Beach", "Kai's activities use the Beach scenery")
 for game_kind in IslandActivities.BEACH_GAMES:
  browser.choose_beach(game_kind)
  await process_frame
  check(browser.beach_mode == game_kind and browser.content.get_child_count() > 0, "Every beach activity has controls")
 main.show_page("Life:Daily")
 await process_frame
 check(main.body.get_child(0).mode == "Daily", "Daily activity card opens")
 main.show_page("Home")
 check(main.daily_button.visible, "Home has a Today shortcut")
 game.resting = false
 game.life.toy = "Toy"
 game.items.Toy = 1
 main.show_page("Home")
 var puppy = main.habitat.puppy
 check(puppy.begin_toy_visit(), "A dog can approach its placed toy")
 for frame in 2400:
  puppy._process(1.0/60)
  if puppy.pending_decor_action == "":
   break
 check(puppy.pending_decor_action == "" and not puppy.carrying_toy and puppy.reaction_kind == "Play", "Toy sharing completes its safe return")
 puppy.react_to_care("Stay")
 check(puppy.reaction_kind == "Stay", "Stay has its own command reaction")
 puppy.reaction_time = 0
 puppy.command_delay = 0
 var old_position = puppy.position
 game.life.training.Come = 5
 puppy.react_to_care("Come")
 puppy._process(0.5)
 check(puppy.position.distance_to(old_position)>0, "Learned Come moves toward the call during its reaction")
 check(not IslandActivities.valid({"day":IslandLife.today(),"throws":3,"done":[]}), "Completed beach progress must include its claimed reward")
 check(not IslandActivities.valid({"shell":true,"done":["Shells"]}), "Beach progress requires a saved date")
 game.life.delivery = {"recipient":"", "claimed":IslandLife.today(), "completed":1}
 check("complete" in IslandActivities.greeting(game,"Owen","") and "Collect" not in IslandActivities.greeting(game,"Owen",""), "Owen recognizes deliveries already completed today")
 game.health = PuppyHealth.fresh()
 game.resting = false
 puppy.pending_decor_action = ""
 puppy.begin_toy_visit()
 PuppyHealth.start(game,"Sore paw")
 puppy._process(0.1)
 check(puppy.pending_decor_action == "" and not puppy.carrying_toy, "A new injury stops autonomous toy sharing")
 PuppyHealth.checkup(game)
 check(IslandActivities.daily_card(game)[0].done, "Daily card recognizes a completed checkup during recovery")
 main.queue_free()
 await process_frame
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for width in [1280,1558]:
  var phone = SubViewport.new()
  phone.size = Vector2i(width,720)
  root.add_child(phone)
  main = load("res://scenes/main.tscn").instantiate()
  phone.add_child(main)
  for section in ["Daily", "Beach Activities"]:
   main.show_page("Life:"+section)
   await process_frame
   await process_frame
   var view = main.body.get_child(0)
   var panel = view.get_child(1 if section == "Beach Activities" else 0)
   var bounds = panel.get_global_rect()
   check(bounds.position.x >= 105 and bounds.end.x <= width-105 and bounds.end.y <= 695, "New activity panels respect phone safe areas")
  main.queue_free()
  phone.queue_free()
  await process_frame
 UI.safe_override = {}
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Island activity checks: ", "PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
