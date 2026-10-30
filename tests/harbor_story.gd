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
 game.storage_path = "user://harbor_story_test.json"
 game.life = IslandLife.fresh()
 game.journal = []
 check(IslandStory.next_step(game).place == "Harbor", "Fresh story starts at Harbor")
 IslandStory.advance(game,"deliver")
 check(not game.life.story.get("delivered",false), "Delivery requires the kit and meeting Ren")
 IslandStory.advance(game,"meet")
 check(game.life.story.met_keeper, "Cottage can be visited before Harbor")
 IslandStory.advance(game,"welcome")
 IslandStory.advance(game,"kit")
 game.save_game()
 game.life = IslandLife.fresh()
 game.load_game()
 check(game.life.story.kit and game.life.story.met_keeper, "Story survives save/load")
 check(IslandStory.next_step(game).place == "Keeper’s Cottage", "Journal points to delivery")
 IslandStory.advance(game,"deliver")
 IslandStory.advance(game,"lantern")
 var memories = game.journal.size()
 var coins = game.coins
 for action in ["welcome","kit","meet","deliver","lantern"]:
  IslandStory.advance(game,action)
 check(game.journal.size() == memories and game.coins == coins, "Repeating story actions adds no duplicate memories or rewards")
 check(IslandStory.valid({}) and not IslandStory.valid({"kit":true}) and not IslandStory.valid({"lantern":true}), "Legacy saves and story prerequisites are validated")
 IslandLife.talk(game,"Ren")
 check(game.life.friends.has("Ren"), "Ren joins friendships")
 game.intro_seen = true
 game.pending_stage = ""
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 for place in ["Harbor","Keeper’s Cottage"]:
  main.visit(place)
  await process_frame
  await process_frame
  check(main.page == place and main.habitat.background.texture == Art.BACKGROUNDS[place], "New destination loads its own scene")
  check(WalkArea.contains(main.habitat.puppy.walk_area, main.habitat.puppy.position), "Puppy starts on clear ground")
  check(main.camera_button.visible, "New destinations support photos")
 game.life = IslandLife.fresh()
 for step in ["kit", "deliver", "lantern"]:
  var place = "Harbor" if step in ["welcome", "kit"] else "Keeper’s Cottage"
  main.show_page(place)
  await process_frame
  main.body.get_child(0).primary_actions.get_child(0).pressed.emit()
  await process_frame
  await process_frame
  check(is_instance_valid(main.resident_overlay), "Story buttons open a speaking character")
  for button in main.resident_overlay.find_children("*", "Button", true, false):
   if button.text == "Close":
    button.pressed.emit()
    break
  await process_frame
 check(game.life.story.get("lantern",false), "The complete story is playable through location buttons")
 game.life.story = {"welcome":true,"kit":true}
 var introduction = IslandStory.advance(game,"meet")
 check("You brought" in introduction and "at the Harbor" not in introduction, "Ren recognizes a kit already collected before the introduction")
 check("Deliver lantern kit" in IslandStory.advance(game,"meet"), "Repeat conversations explain the current delivery step")
 IslandStory.advance(game,"deliver")
 check("prepare" in IslandStory.advance(game,"meet"), "Ren explains the lantern step after delivery")

 IslandStory.advance(game,"lantern")
 var restoration_coins = game.coins
 IslandStory.advance(game,"beacon_checked")
 check(not game.life.story.get("beacon_checked",false), "Restoration tasks cannot be skipped")
 for task in ["repair_supplies", "path_repaired"]:
  var step = IslandStory.restoration_step(game)
  main.show_page(step.place)
  await process_frame
  main.body.get_child(0).primary_actions.get_child(0).pressed.emit()
  await process_frame
  for button in main.resident_overlay.find_children("*", "Button", true, false):
   if button.text == "Close":
    button.pressed.emit()
    break
  await process_frame
  check(game.life.story.get(task,false), "Restoration location button completes " + task)
 game.life.keepsakes = []
 IslandStory.advance(game,"lens_polished")
 check(not game.life.story.get("lens_polished",false) and IslandStory.next_step(game).place == "Beach", "Display requires a sea-glass discovery and points to Beach")
 IslandLife.discover(game,2)
 IslandStory.advance(game,"lens_polished")
 check("Sea glass" in game.life.keepsakes, "Restoration does not consume collected keepsakes")
 IslandStory.advance(game,"beacon_checked")
 IslandStory.advance(game,"beacon_checked")
 check(game.coins == restoration_coins + 15, "Restoration reward is given only once")
 game.save_game()
 game.life = IslandLife.fresh()
 game.load_game()
 check(game.life.story.get("beacon_checked",false), "Restoration completion survives reload")
 check(not IslandStory.valid({"beacon_checked":true}) and not IslandStory.valid({"path_repaired":true}), "Invalid restoration prerequisites are rejected")

 main.show_page("Keeper’s Cottage")
 await process_frame
 var visual = main.habitat.restoration
 check(visual.state().path and visual.state().display and visual.state().beacon and not visual.state().crate, "Completed restoration shows its finished scenery layers")
 game.life.story = {"welcome":true,"kit":true,"met_keeper":true,"delivered":true,"lantern":true,"repair_supplies":true}
 check(visual.state().crate and not visual.state().path, "Repair crate appears only before path repairs")

 main.queue_free()
 await process_frame
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Harbor story checks: ", "PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
