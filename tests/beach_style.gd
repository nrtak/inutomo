extends SceneTree
var failures = 0
func _initialize():
 call_deferred("run")
func check(value: bool, message: String):
 if not value:
  push_error(message)
  failures += 1
func close_conversation(node: Node) -> void:
 for child in node.get_children():
  if child is Button and child.text == "Close":
   child.pressed.emit()
   return
  close_conversation(child)
func run():
 var game = root.get_node("Game")
 game.set_process(false)
 game.storage_path = "user://beach_style_test.json"
 game.intro_seen = true
 game.pending_stage = ""
 game.paused_at = 0
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.resting = false
 game.breed = "Puppy"
 game.needs.Energy = 90
 game.cooldowns.clear()
 game.set_reduce_motion(false,false)
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for view_size in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1281,720),Vector2i(1558,720)]:
  var view = SubViewport.new()
  view.size = view_size
  view.handle_input_locally = false
  root.add_child(view)
  var main = load("res://scenes/main.tscn").instantiate()
  view.add_child(main)
  main.show_page("Beach")
  await process_frame
  await process_frame
  check(main.habitat.background.texture == BeachStyle.BACKGROUND,"The playable beach uses the restored anime scenery")
  check(is_zero_approx(main.habitat.background.material.get_shader_parameter("water_shimmer")),"The ocean has no diagonal glossy overlay")
  var greeting = main.world_host.get_node("LocationGreeting")
  var resident = greeting.get_child(0)
  check(resident.frames[0].atlas == BeachStyle.KAI,"Kai shares the restored anime art direction")
  check(resident.get_global_rect().position.y >= 80 and resident.get_global_rect().position.y < 210,"Kai remains large and his head stays visible on phone screens")
  var menu_picture = main.menu_button.get_meta("picture")
  check(main.menu_button.get_global_rect().encloses(menu_picture.get_global_rect()),"Styling the menu never pushes its icon outside the button")
  var hub = main.body.get_child(0)
  check(hub.primary_actions.get_child_count() == 3 and hub.choices.get_child_count() == 1,"All four beach activities are directly accessible")
  var buttons = hub.primary_actions.get_children()+hub.choices.get_children()
  for breed in ["Puppy","Shiba Inu","Golden Retriever"]:
   game.breed = breed
   var dog = main.habitat.puppy
   dog._process(0)
   check(dog.sprite.texture == BeachStyle.dog_texture(breed,false),"The beach displays the player's actual breed: "+breed)
   for asleep in [false,true]:
    game.resting = asleep
    dog._process(0)
    check(dog.sprite.texture == BeachStyle.dog_texture(breed,asleep),"Resting selects the matching anime sleep pose")
    var bounds: Rect2 = dog.sprite.get_global_transform()*dog.sprite.get_rect()
    check(bounds.end.y <= view_size.y-20 and bounds.position.y > 200,"The whole dog is grounded above the bottom safe area")
    for button in buttons:
     check(not bounds.intersects(button.get_global_rect()),"The dog never overlaps an activity card")
   game.resting = false
  for button in buttons:
   var bounds = button.get_global_rect()
   check(bounds.position.x >= 105 and bounds.end.x <= view_size.x-105 and bounds.end.y <= view_size.y-24,"Activity card "+button.text+" fits phone "+str(view_size)+": "+str(bounds))
  main.open_photo_mode()
  check(not greeting.visible,"Photo mode hides the greeting cleanly")
  main.close_photo_mode()
  check(greeting.visible,"Leaving photo mode restores Kai")
  main.show_resident(Art.KAI,"Kai","Beach lifeguard","Welcome!")
  check(not greeting.visible,"A conversation never shows two copies of Kai")
  close_conversation(main.resident_overlay)
  check(greeting.visible,"Closing a conversation restores the location resident")
  game.breed = "Puppy"
  game.resting = false
  game.items.CoralBandana = 1
  game.life.accessory = "CoralBandana"
  main.habitat.puppy._process(0)
  check(main.habitat.puppy.sprite.material == main.habitat.puppy.style_material,"The dog retains the player's equipped bandana")
  hub.primary_actions.get_child(0).pressed.emit()
  check(main.page == "Life:Beach Activities" and main.body.get_child(0).beach_mode == "Shells","One tap opens the selected shell game")
  check(main.habitat.background.texture == BeachStyle.BACKGROUND and main.habitat.puppy.presentation_style == "Beach","Playing a beach game preserves the unified artwork")
  await process_frame
  await process_frame
  var browser = main.body.get_child(0)
  var dog_bounds: Rect2 = main.habitat.puppy.sprite.get_global_transform()*main.habitat.puppy.sprite.get_rect()
  check(not browser.get_child(1).get_global_rect().intersects(dog_bounds),"The activity panel never covers the player's dog at "+str(view_size))
  var icon = UI.resident_icon(Art.KAI)
  check(icon.atlas == BeachStyle.KAI,"Kai's help icon uses his current artwork")
  for kind in ["Cleanup","Sand Fetch"]:
   browser.choose_beach(kind)
   await process_frame
   await process_frame
   check(not browser.get_child(1).get_global_rect().intersects(dog_bounds),"Every beach game keeps the dog visible: "+kind)
   if kind == "Sand Fetch":
    check(browser.get_child(1).size.y < view_size.y*0.8,"Short activity panels shrink to their content instead of leaving a large empty box")
  var same_page = main.page
  var portrait_before = main.habitat.puppy.sprite.texture
  browser._process(0)
  check(main.page == same_page and main.habitat.puppy.sprite.texture == portrait_before,"Refreshing activity controls preserves the active dog")
  game.cooldowns.erase("Beach")
  for blocked in [true,false]:
   game.resting = blocked
   browser._process(0)
   for control in browser.content.get_children():
    if control is Button and control.has_meta("beach_action"):
     check(control.disabled == blocked,"Beach game controls reflect resting and waking immediately")
  main.go_back()
  await process_frame
  check(main.page == "Beach","Back returns directly to the beach")
  game.resting = true
  main.body.get_child(0).refresh()
  check(main.body.get_child(0).primary_actions.get_child(0).disabled,"Activities still respect the dog's resting state")
  game.resting = false
  main.show_page("Home")
  check(main.habitat.puppy.presentation_style.is_empty(),"The beach art pass keeps its own layout while sharing actor artwork")
  view.queue_free()
  await process_frame
 UI.safe_override.clear()
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Unified beach checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
