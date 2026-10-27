extends SceneTree
var failures = 0
var game: Node
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, text: String) -> void:
 if not condition:
  push_error(text)
  failures += 1
func reset_items() -> void:
 game.items = {}
 for kind in Goods.ITEMS:
  game.items[kind] = 0
func run() -> void:
 game = root.get_node("Game")
 game.set_process(false)
 game.storage_path = "user://mobile_regression_test.json"
 game.intro_seen = true
 game.name_chosen = true
 game.pending_stage = ""
 game.active_outing = {}
 game.puppy_name = "Mochi"
 game.breed = "Puppy"
 game.points = 0
 game.active_seconds = 0
 game.resting = false
 game.coins = 500
 game.cooldowns = {}
 reset_items()
 for kind in Goods.ITEMS:
  check(game.PRICES[kind] == Goods.ITEMS[kind].price, "Shop and save prices agree")
  for purchase in Goods.ITEMS[kind].limit:
   game.buy_item(kind)
  var coins_before: int = game.coins
  game.buy_item(kind)
  check(game.items[kind] == Goods.ITEMS[kind].limit and game.coins == coins_before, "Stock limits prevent duplicate spending: " + kind)
 game.needs = {"Hunger": 40.0, "Happiness": 40.0, "Energy": 40.0, "Cleanliness": 40.0}
 var points_before: int = game.points
 game.use_item("Treat")
 check(game.items.Treat == 4 and game.needs.Hunger == 48 and game.points == points_before, "A biscuit is consumed without granting growth")
 game.use_item("TrainingTreat")
 check(game.items.TrainingTreat == 5, "Item cooldown prevents rapid consumption")
 game.advance(12)
 game.use_item("TrainingTreat")
 check(game.items.TrainingTreat == 4, "Training bites can be used after a pause")
 game.advance(12)
 game.use_item("Shampoo")
 check(game.items.Shampoo == 4 and game.needs.Cleanliness > 60, "Shampoo restores cleanliness")
 game.cooldowns.clear()
 game.needs.Hunger = 90
 game.cooldowns.clear()
 game.action("Feed")
 check(game.items.Treat == 4, "A filling meal does not waste an automatic biscuit")
 game.needs.Hunger = 100
 game.use_item("Treat")
 check(game.items.Treat == 4, "Full needs do not waste goods")
 game.needs.Energy = 40
 game.resting = true
 game.items.Bed = 0
 game.advance(10)
 var ordinary_rest: float = game.needs.Energy
 game.needs.Energy = 40
 game.items.Bed = 1
 game.advance(10)
 check(game.needs.Energy > ordinary_rest, "The cozy bed improves Rest")
 game.resting = false
 for key in game.NEEDS:
  game.needs[key] = 80.0
 var active_before: float = game.active_seconds
 game.advance(7200, false)
 check(game.needs.Hunger > 70 and game.active_seconds == active_before, "Time away is gentle and never rushes growth")
 game.cooldowns = {"Goods": 12.0}
 game.save_game()
 game.cooldowns.clear()
 game.load_game()
 check(game.cooldowns.get("Goods", 0) > 10, "Item cooldown survives reopening")
 check(game.items.Shampoo == 4 and game.items.TrainingTreat == 4 and game.items.Bed == 1, "New goods survive save and load")
 game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
 check(game.valid_save(game.read_data(game.storage_path)), "Closing the app writes a complete readable save")
 var legacy = game.read_data(game.storage_path)
 legacy.items = {"Treat": 1, "Toy": 1, "Brush": 0}
 for key in ["cooldowns", "active_outing", "effects_volume", "ambience_volume"]:
  legacy.erase(key)
 check(game.valid_save(legacy), "Existing saves migrate to the new goods and settings")
 var broken = legacy.duplicate(true)
 broken.items.Bed = 2
 check(not game.valid_save(broken), "Invalid durable quantities are rejected")
 broken = legacy.duplicate(true)
 broken.active_outing = {"kind":"Fetch", "checkpoint":1, "score":3}
 check(not game.valid_save(broken), "Impossible outing scores are rejected")
 game.begin_outing("Fetch")
 game.checkpoint_outing(1, 1)
 game.active_outing = {}
 game.load_game()
 game.pending_stage = ""
 game.needs.Energy = 90
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 current_scene = main
 main.start_activity("Fetch")
 await process_frame
 var fetch = main.body.get_child(0)
 check(fetch.rounds == 1 and fetch.score == 1, "Fetch resumes its last completed throw")
 var coins_before: int = game.coins
 check(not game.complete_outing("Fetch", 1) and game.coins == coins_before, "An unfinished outing cannot pay a reward")
 main.request_page("Island")
 check(is_instance_valid(main.leave_overlay), "Leaving an outing asks before interrupting it")
 main.close_leave_prompt()
 main.show_page("Home")
 game.checkpoint_outing(3, 2)
 main.start_activity("Fetch")
 await process_frame
 await process_frame
 check(main.body.get_child(0).complete and game.coins == coins_before + 12, "A completed checkpoint pays once when resumed")
 check(not game.complete_outing("Fetch", 2) and game.coins == coins_before + 12, "Reloading cannot duplicate the outing reward")
 game.begin_outing("Walk")
 game.checkpoint_outing(3)
 game.save_game()
 game.active_outing = {}
 game.load_game()
 main.start_activity("Walk")
 await process_frame
 var walk = main.body.get_child(0)
 check(walk.step == 3 and walk.next_button.text == "Head back", "A Walk resumes at the return trip")
 check(walk.next_button.get_meta("picture").texture == UI.place_icon("Home"), "A resumed return trip shows the Home icon")
 check(main.habitat.background.modulate == Color.WHITE, "Walk discoveries preserve the device-time lighting")
 walk._notification(NOTIFICATION_APPLICATION_PAUSED)
 check(walk.timer.paused, "Outing timers pause when the app is backgrounded")
 var time_before: float = game.active_seconds
 game._notification(NOTIFICATION_APPLICATION_PAUSED)
 game._process(30)
 check(game.active_seconds == time_before, "Background time is excluded from active growth")
 game._notification(NOTIFICATION_APPLICATION_RESUMED)
 walk._notification(NOTIFICATION_APPLICATION_RESUMED)
 check(not walk.timer.paused, "Outing timers resume after returning")
 walk._next()
 await create_timer(2.7).timeout
 check(walk.complete and game.active_outing.is_empty(), "The saved return trip completes safely")
 main.show_page("Home")
 main.queue_free()
 await process_frame
 await process_frame
 UI.safe_override = {"left": 105, "right": 105, "top":20, "bottom":25}
 for screen_size in [Vector2i(844,390), Vector2i(667,375), Vector2i(932,430)]:
  var mobile_view = SubViewport.new()
  mobile_view.size = Vector2i(roundi(float(screen_size.x) * 720 / screen_size.y), 720)
  root.add_child(mobile_view)
  await process_frame
  main = load("res://scenes/main.tscn").instantiate()
  mobile_view.add_child(main)
  main.show_page("Island")
  await process_frame
  await process_frame
  var map = main.world_host.get_child(0)
  var keys = map.pins.keys()
  for i in keys.size():
   var rect: Rect2 = map.pins[keys[i]].get_global_rect()
   check(rect.position.x >= 105 and rect.end.x <= mobile_view.size.x - 105, "Map markers clear the screen cutouts")
   check(rect.position.y >= 20 and rect.end.y <= 695, "Map markers stay within the visible screen height")
   for j in range(i + 1, keys.size()):
    check(not rect.intersects(map.pins[keys[j]].get_global_rect()), "Map markers " + str(keys[i]) + " / " + str(keys[j]) + " do not overlap at " + str(screen_size))
  check(map.go_button.get_global_rect().end.y <= 695, "Travel button stays above the safe bottom edge")
  map.select("Shop")
  map.travel()
  await process_frame
  check(main.page == "Shop", "Map travel opens the selected place")
  var browser = main.body.get_child(0)
  for category in Goods.CATEGORIES:
   browser.select_category(category)
   check(not browser.rows.is_empty(), "Shop categories contain their goods")
   browser.show_details(browser.rows.keys()[0])
   check(is_instance_valid(browser.detail_overlay), "Product pictures open their details")
   browser.close_details()
   await process_frame
  main.show_page("Bag")
  await process_frame
  check(not main.bag_button.visible, "The Bag does not repeat its own navigation button")
  for place in ["Puppy Club", "Park", "Beach", "Vet Clinic", "Lighthouse"]:
   main.show_page(place)
   await process_frame
   await process_frame
   var hub = main.body.get_child(0)
   for button in hub.choices.get_children():
    var bounds: Rect2 = button.get_global_rect()
    check(bounds.position.x >= 105 and bounds.end.x <= mobile_view.size.x - 105, place + " buttons clear screen cutouts")
    check(bounds.position.y >= 20 and bounds.end.y <= 695, place + " buttons fit the screen height")
  main.show_page("Beach")
  game.resting = true
  main.start_activity("Walk")
  check(is_instance_valid(main.notice_overlay) and main.page == "Beach", "An unavailable outing explains why it cannot start")
  game.resting = false
  for destination in ["Home", "Island", "Bag", "Journal", "My Dogs"]:
   main.open_navigation()
   var choices = main.navigation_overlay.find_children("*", "Button", true, false)
   for choice in choices:
    if choice.text == destination:
     choice.pressed.emit()
     break
   await process_frame
   check(main.page == destination and not is_instance_valid(main.navigation_overlay), "Compact menu opens " + destination)

  main.queue_free()
  await process_frame
  await process_frame
  mobile_view.queue_free()
  await process_frame
 UI.safe_override = {}
 var menu = load("res://scenes/start_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 menu.show_name_picker()
 menu.keyboard_height_override = 330
 menu.name_input.grab_focus()
 await process_frame
 await process_frame
 check(menu.name_panel.get_global_rect().end.y <= root.get_visible_rect().size.y - 330 + 1, "Naming form stays above the keyboard")
 var buttons = menu.name_content.find_children("*", "Button", false, false)
 for button in buttons:
  check(button.get_global_rect().end.y <= menu.name_panel.get_global_rect().end.y, "Naming actions remain visible with the keyboard open")
 menu.name_overlay.queue_free()
 menu.name_overlay = null
 menu.show_sound_settings()
 var sliders = menu.settings_overlay.find_children("*", "HSlider", true, false)
 sliders[0].value = 33
 check(is_equal_approx(game.effects_volume, 0.33), "Effects slider adjusts its own mix level")
 sliders[1].value = 77
 check(is_equal_approx(game.ambience_volume, 0.77) and is_equal_approx(game.effects_volume, 0.33), "Ambience and effects are independent")
 game.save_game()
 game.effects_volume = 1
 game.ambience_volume = 1
 game.load_game()
 check(is_equal_approx(game.ambience_volume, 0.77) and is_equal_approx(game.effects_volume, 0.33), "Audio levels survive reopening")
 menu.queue_free()
 await process_frame
 await process_frame
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path + suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
 print("Mobile regression checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
 quit(0 if failures == 0 else 1)

