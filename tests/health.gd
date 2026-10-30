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
 game.storage_path = "user://health_test.json"
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.needs = {"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
 game.items = {}
 for kind in Goods.ITEMS:
  game.items[kind] = 0
 game.coins = 0
 game.resting = false
 for condition in PuppyHealth.CONDITIONS:
  game.health = PuppyHealth.fresh()
  check(PuppyHealth.start(game,condition), "Each mild illness and injury can begin")
  game.items.Medicine = 2
  game.items.Bandage = 2
  check(not game.can_explore(), "Unwell puppies wait before strenuous outings")
  var points = game.points
  game.action("Play")
  check(game.points == points, "Play cannot bypass recovery")
  game.use_item("Medicine")
  check(game.items.Medicine == 2 and not game.health.treated, "Medicine requires a vet diagnosis")
  check(condition in game.clinic_checkup() and game.health.diagnosed, "Checkup diagnoses the condition for free")
  game.clinic_checkup()
  check(game.health.history.size() == 1, "Repeated checkups do not duplicate diagnoses")
  var wrong = "Medicine" if condition == "Sore paw" else "Bandage"
  game.use_item(wrong)
  check(game.items[wrong] == 2 and not game.health.treated, "Wrong treatment is not consumed")
  var right = PuppyHealth.CONDITIONS[condition].item
  game.use_item(right)
  check(game.items[right] == 1 and game.health.treated and game.resting, "Correct treatment is consumed once and starts rest")
  game.use_item(right)
  check(game.items[right] == 1, "Repeated medicine is not wasted")
  game.save_game()
  game.health = PuppyHealth.fresh()
  game.load_game()
  check(game.health.treated and game.health.diagnosed, "Health and treatment survive reload")
  PuppyHealth.advance(game,400,false,true)
  check(not PuppyHealth.unwell(game), "Treated puppies recover gently while away")
  check(game.health.history.size() == 3 and game.health.history[0].event == "Recovered", "Diagnosis, treatment and recovery remain in history")
  game.save_game()
  game.load_game()
  check(game.health.history.size() == 3, "Health history survives recovery and reload")
 game.health = PuppyHealth.fresh()
 game.health.grace = 0.0
 game.needs.Hunger = 5
 game.needs.Cleanliness = 80
 PuppyHealth.advance(game,7200,false,false)
 check(not PuppyHealth.unwell(game), "New illnesses never start while away")
 PuppyHealth.advance(game,599,true,false)
 check(not PuppyHealth.unwell(game), "Low needs must persist before illness")
 PuppyHealth.advance(game,1,true,false)
 check(game.health.condition == "Tummy upset", "Sustained poor appetite care can cause tummy upset")
 game.clinic_checkup()
 PuppyHealth.treat(game)
 check(game.health.treated and game.coins == 0, "Clinic treatment is free even with no coins")
 game.health = PuppyHealth.fresh()
 game.health.grace = 0
 game.needs.Energy = 10
 for i in 3:
  PuppyHealth.exertion(game)
 check(game.health.condition == "Sore paw", "Repeated exhausted activity can cause a sore paw")
 check(not PuppyHealth.valid({"condition":"Sore paw","recovery":100,"treated":true}), "Undiagnosed treatment state is rejected")
 check(PuppyHealth.valid({}), "Old saves without health are supported")
 game.health = PuppyHealth.fresh()
 game.intro_seen = true
 game.pending_stage = ""
 game.needs = {"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 main.browse_shop()
 var shop = main.body.get_child(0)
 shop.select_category("Care")
 check(not shop.rows.has("Medicine") and not shop.rows.has("Bandage"), "June does not sell veterinary supplies")
 main.show_page("Vet Supplies")
 await process_frame
 var supplies = main.body.get_child(0)
 check(supplies.rows.size() == 2 and supplies.rows.has("Medicine") and supplies.rows.has("Bandage"), "Clinic supplies show medicine and bandages")
 main.show_page("Home")
 PuppyHealth.start(game,"Itchy coat")
 await process_frame
 check(main.health_badge.visible, "Home shows the Visit Vet shortcut")
 main.health_badge.pressed.emit()
 await process_frame
 check(main.page == "Vet Clinic", "Health shortcut opens Leah's clinic")
 main.show_page("Life:Health Record")
 await process_frame
 check(main.body.get_child(0).mode == "Health Record", "Clinic history screen opens")
 check("checkup" in PuppyHealth.advice(game), "Undiagnosed symptoms guide players to a checkup")
 check(not PuppyHealth.valid({"history":[{"event":"Bad", "condition":"Sore paw", "date":"today"}]}), "Invalid health records are rejected")
 for i in 40:
  PuppyHealth.record(game,"Checkup")
 check(game.health.history.size() == 30 and PuppyHealth.valid(game.health), "Health history stays bounded and valid")
 var history_view = main.body.get_child(0)
 PuppyHealth.checkup(game)
 history_view._process(0)
 check(history_view.shown_health == history_view.health_snapshot(), "Open health history refreshes after a condition changes")
 main.show_page("Vet Clinic")
 game.life.bed = "Bed"
 game.items.Bed = 1
 game.resting = true
 var vet_puppy = main.habitat.puppy
 vet_puppy.react_to_care("Rest")
 check(not vet_puppy.settling_for_rest, "Clinic rest cannot send the dog toward Home furniture coordinates")
 game.resting = false
 var clinic = main.body.get_child(0)
 clinic.rest_at_home()
 check(main.page == "Home" and game.resting, "Clinic Rest at Home starts a nap after returning Home")
 main.show_page("Vet Clinic")
 main.body.get_child(0).rest_at_home()
 check(game.resting, "Clinic rest preserves an existing nap")
 main.queue_free()
 await process_frame
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Health checks: ", "PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
