extends SceneTree
var failures = 0
func _initialize():
 call_deferred("run")
func check(value: bool,message: String):
 if not value:
  push_error(message)
  failures += 1
func run():
 var game = root.get_node("Game")
 game.set_process(false)
 game.storage_path = "user://comfort_flow_test.json"
 game.intro_seen = true
 game.pending_stage = ""
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.resting = false
 game.breed = "Puppy"
 game.points = 0
 game.active_seconds = 0
 game.set_reduce_motion(true)
 check(game.save_game(),"Reduce Motion saves with game progress")
 game.reduce_motion = false
 game.load_game()
 check(game.reduce_motion,"Reduce Motion survives save/load")
 check(not root.get_node("Daylight").material_for("Beach").get_shader_parameter("motion_enabled"),"Reduce Motion freezes the scenery shader")
 var legacy = game.read_data(game.storage_path)
 legacy.erase("reduce_motion")
 check(game.valid_save(legacy),"Older saves remain valid without a motion preference")
 legacy.reduce_motion = "yes"
 check(not game.valid_save(legacy),"Invalid motion preference cannot corrupt the save")
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 current_scene = main
 main._process(0)
 check(not is_instance_valid(main.notice_overlay) and main.home_suggestion_card.visible,"First-play guidance uses one compact hint instead of a second floating notice")
 var home_dog = main.habitat.puppy
 home_dog.set_process(false)
 for kind in ["Feed","Play","Care","Pet","Treat","Sniff"]:
  home_dog.home_interactions = false
  home_dog.react_to_care(kind)
  home_dog._process(0.13)
  check(home_dog.sprite.position == Vector2.ZERO and is_zero_approx(home_dog.sprite.rotation) and home_dog.sprite.scale.is_equal_approx(Vector2.ONE*home_dog.base_scale),"Reduce Motion keeps Home care reactions still: "+kind)
  var icon_position = home_dog.reaction_icon.position
  home_dog._process(0.1)
  check(home_dog.reaction_icon.position.is_equal_approx(icon_position),"Reduce Motion keeps care icons still as well: "+kind)
 home_dog.sleepy_reaction = false
 home_dog.reaction_time = 0
 home_dog.nap_remaining = 50
 home_dog._process(0.13)
 check(home_dog.sprite.scale.is_equal_approx(Vector2.ONE*home_dog.base_scale),"Reduce Motion also stops the sleeping sprite pulsing")
 main.show_page("Beach")
 var dog = main.habitat.puppy
 game.set_process(true)
 game.cooldowns.erase("Pet")
 check(game.pet_puppy(),"The location dog accepts a gentle pat")
 game.set_process(false)
 dog._process(0.1)
 check(dog.reaction_icon.visible and dog.reaction_kind == "Pet","Petting at a location produces a visible reaction")
 dog.sprite.rotation = 0.02
 dog._process(0)
 check(is_zero_approx(dog.sprite.rotation),"Reduce Motion immediately levels a dog already reacting")
 var resident = main.world_host.get_node("LocationGreeting").get_child(0)
 game.set_reduce_motion(false,false)
 resident.show_frame(1)
 game.set_reduce_motion(true,false)
 resident._process(0)
 check(resident.frame_index == 1 and resident.texture == resident.frames[1] and resident.get_child_count() == 0,"Reduce Motion holds a single clean resident pose without blended overlays")

 main.show_page("Life:Events")
 main.show_page("Life:Training")
 main.go_back()
 check(main.page == "Life:Events","Back returns to the previous section instead of jumping to Park")
 game.health = PuppyHealth.fresh()
 game.needs.Energy = 90
 game.needs.Happiness = 99
 game.coins = 1000000
 main.show_page("Park")
 main.start_activity("Fetch")
 var fetch = main.body.get_child(0)
 game.checkpoint_outing(3,2)
 fetch.score = 2
 fetch.finish_fetch()
 check("0 coins earned" in fetch.status.text and "Happiness +1" in fetch.status.text,"Activity results report actual capped gains")
 check(fetch.throw_button.get_meta("caption").text == "Back to Park","Completion button names its destination")
 var coins = game.coins
 fetch.finish_fetch()
 check(game.coins == coins,"Showing results twice cannot award twice")
 fetch.finished.emit()
 check(main.page == "Park","Completion returns to the activity origin")
 game.breed = "Puppy"
 game.points = 4
 game.active_seconds = 300
 var milestone = game.growth_milestone()
 check(milestone.name == "Young puppy" and is_equal_approx(milestone.progress,50),"Growth displays progress to the next milestone")
 game.points = 8
 check(game.growth_milestone().progress < 100,"Care alone cannot skip the time requirement")
 game.breed = "Shiba Inu"
 check(game.growth_milestone().progress == 100,"Adults have a completed growth journey")
 game.breed = "Puppy"
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for dimensions in [Vector2i(1280,720),Vector2i(1558,720),Vector2i(1152,648)]:
  var phone = SubViewport.new()
  phone.size = dimensions
  root.add_child(phone)
  var scene = load("res://scenes/main.tscn").instantiate()
  phone.add_child(scene)
  scene.show_feedback("Yum! A fresh bowl and a happy tummy.")
  await process_frame
  await process_frame
  var feedback_bounds: Rect2 = scene.notice_overlay.get_child(0).get_global_rect()
  var dog_bounds: Rect2 = scene.habitat.puppy.sprite.get_global_transform()*scene.habitat.puppy.sprite.get_rect()
  check(not feedback_bounds.intersects(dog_bounds),"Home feedback stays beside the dog instead of covering its face or paws: "+str(dimensions)+" notice "+str(feedback_bounds)+" dog "+str(dog_bounds))
  for prop in scene.habitat.decor_sprites.values():
   check(not feedback_bounds.intersects(prop.get_global_transform()*prop.get_rect()),"Home feedback leaves the bowl and other placed objects visible")
  check(feedback_bounds.position.x>=105 and feedback_bounds.end.x<=dimensions.x-105 and feedback_bounds.end.y<=dimensions.y-25,"Home feedback respects the phone safe area")
  scene.open_navigation()
  await process_frame
  await process_frame
  var panel = scene.navigation_overlay.get_child(1).get_child(0)
  var rect = panel.get_global_rect()
  check(rect.position.y >= 20 and rect.end.y <= dimensions.y-25,"Menu and Reduce Motion fit phone safe areas")
  check(rect.position.x >= 105 and rect.end.x <= dimensions.x-105,"Menu clears phone cutouts")
  scene.queue_free()
  phone.queue_free()
  await process_frame
 UI.safe_override = {}
 main.queue_free()
 game.set_reduce_motion(false,false)
 await process_frame
 for suffix in ["",".tmp",".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Comfort and flow checks: ","PASS" if failures == 0 else "FAIL")
 quit(0 if failures == 0 else 1)
