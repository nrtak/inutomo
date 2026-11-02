extends SceneTree
var failures = 0
func _initialize():
 call_deferred("run")
func check(value: bool, text: String):
 if not value:
  push_error(text)
  failures += 1
func complete_restoration(game: Node):
 for action in ["welcome","kit","meet","deliver","lantern","repair_supplies","path_repaired"]:
  IslandStory.advance(game,action)
 game.life.keepsakes = ["Sea glass"]
 IslandStory.advance(game,"lens_polished")
 IslandStory.advance(game,"beacon_checked")
func run():
 var game = root.get_node("Game")
 game.set_process(false)
 game.storage_path = "user://adventure_test.json"
 game.intro_seen = true
 game.name_chosen = true
 game.pending_stage = ""
 game.paused_at = 0
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.resting = false
 game.needs.Energy = 95
 game.coins = 100
 game.cooldowns.clear()
 var legacy = game.life.duplicate(true)
 legacy.erase("adventure")
 legacy.training = {"Sit":2,"Stay":1,"Come":0}
 check(IslandLife.valid(legacy),"Existing saves remain valid without expansion fields")
 var malformed = IslandLife.fresh()
 malformed.adventure.tower_visited = true
 malformed.story = "invalid"
 check(not IslandLife.valid(malformed),"A damaged lighthouse story is rejected safely")
 var normalized = IslandLife.normalized(legacy)
 check(normalized.adventure.buddies.is_empty() and normalized.training.Paw==0 and normalized.training.Sit==2,"Migration preserves old progress and fills new lessons")
 var corrupt = IslandAdventure.fresh()
 corrupt.scent.step = 3
 check(not IslandAdventure.valid(corrupt),"An unclaimed completed trail is rejected")
 corrupt = IslandAdventure.fresh()
 corrupt.buddies.Momo = {"visits":-1,"bonus_day":""}
 check(not IslandAdventure.valid(corrupt),"Invalid dog friendship counts are rejected")
 corrupt = IslandAdventure.fresh()
 corrupt.chapters.Ben = {"step":3,"progress":0}
 check(not IslandAdventure.valid(corrupt),"Completed stories require their task progress")
 var weather_types = []
 for day in range(1,29):
  var date = "2026-11-%02d" % day
  for hour in range(0,24,4):
   var kind = IslandWeather.at(date,hour)
   if kind not in weather_types: weather_types.append(kind)
   check(IslandWeather.at(date,hour+3)==kind,"Weather stays stable within a four-hour local forecast")
 check(weather_types.size()==3,"The forecast includes sunshine, clouds and gentle rain")
 for command in ["Paw","Spin","Bow","Roll Over"]:
  game.cooldowns.clear()
  game.needs.Energy = 95
  var before = game.life.training[command]
  IslandLife.train(game,command)
  check(game.life.training[command]==before+1,"Each new trick can be learned: "+command)
  var level = game.life.training[command]
  IslandLife.train(game,command)
  check(game.life.training[command]==level,"Rapid taps cannot skip a training cooldown")
 for breed in Art.PUPPIES:
  game.breed = breed
  var dog = load("res://scripts/puppy.gd").new()
  root.add_child(dog)
  dog.set_process(false)
  for command in ["Paw","Spin","Bow","Roll Over"]:
   dog.react_to_care(command)
   dog._process(1.4)
   check(dog.sprite.texture==Art.trick_sheet(breed),"Every breed displays real trick artwork")
   check(Rect2(Vector2.ZERO,dog.sprite.texture.get_size()).encloses(dog.sprite.region_rect),"Trick frames stay inside their atlas")
   check(is_zero_approx(dog.sprite.offset.y+dog.sprite.region_rect.size.y*0.5),"Trick paws stay on the ground")
   dog._process(4)
   check(dog.trick_command.is_empty(),"Tricks finish without leaving the puppy stuck")
  dog.queue_free()
  await process_frame
 game.breed = "Puppy"
 game.life = IslandLife.fresh()
 game.needs.Energy = 95
 game.coins = 999999
 var capped_reply = ""
 for step in 3:
  game.cooldowns.clear()
  capped_reply = IslandLife.playdate_step(game)
 check(game.coins==1000000 and "1 coin and" in capped_reply,"Playdate messages report the actual reward when the coin purse is nearly full")
 game.coins = 100
 game.life = IslandLife.fresh()
 IslandAdventure.choose_buddy(game,"Pippin")
 for step in 3:
  game.cooldowns.clear()
  IslandLife.playdate_step(game)
  if step==0:
   IslandAdventure.choose_buddy(game,"Momo")
   check(IslandAdventure.companion(game)=="Pippin","A playmate cannot change during a playdate")
 check(IslandAdventure.buddy_visits(game,"Pippin")==1,"Completed playdates remember the named dog")
 var coins = game.coins
 game.cooldowns.clear()
 IslandLife.playdate_step(game)
 IslandAdventure.choose_buddy(game,"Momo")
 IslandLife.playdate_step(game)
 check(game.coins==coins and IslandAdventure.buddy_visits(game,"Pippin")==1,"Changing companions cannot duplicate daily playdate rewards")
 check(IslandAdventure.companion(game)=="Momo","Choosing tomorrow's friend after a completed playdate updates the displayed dog")
 game.life.adventure.buddies.Pippin.visits = 4
 game.life.adventure.active_playmate = "Pippin"
 IslandAdventure.shared_activity(game,"Pippin","Mirror tricks")
 coins = game.coins
 IslandAdventure.shared_activity(game,"Pippin","Treasure pals")
 check(game.coins==coins,"Unlocked companion games share one daily bonus")
 game.life.adventure.chapters.clear()
 for person in IslandAdventure.CHAPTERS:
  var spec: Dictionary = IslandAdventure.CHAPTERS[person]
  IslandAdventure.record_task(game,spec.task)
  IslandAdventure.chapter(game,person)
  check(game.life.adventure.chapters[person].progress==0,"Story tasks start after hearing the introduction")
  IslandAdventure.chapter(game,person)
  check(game.life.adventure.chapters[person].step==1,"A story waits for its activity")
  for i in spec.goal:
   IslandAdventure.record_task(game,spec.task)
  IslandAdventure.chapter(game,person)
  IslandAdventure.chapter(game,person)
  var memories = game.journal.size()
  var hearts = game.life.friends[person].hearts
  IslandAdventure.chapter(game,person)
  check(game.life.adventure.chapters[person].step==3 and game.journal.size()==memories and game.life.friends[person].hearts==hearts,"Every story ends once without repeat rewards: "+person)
 game.life.adventure.scent = IslandAdventure.fresh().scent
 game.cooldowns.clear()
 game.resting = false
 game.needs.Energy = 95
 IslandWeather.preview = "Light rain"
 check(IslandAdventure.begin_scent(game) and game.life.adventure.scent.route==1,"Rain offers a different scent trail")
 coins = game.coins
 var miss = IslandAdventure.sniff(game,2)
 check(not miss.ok and game.life.adventure.scent.step==0 and game.coins==coins,"Wrong scent choices do not award progress")
 game.resting = true
 IslandAdventure.sniff(game,0)
 check(game.life.adventure.scent.step==0,"Sleeping dogs cannot play scent games")
 game.resting = false
 for choice in 3:
  game.cooldowns.clear()
  IslandAdventure.sniff(game,choice)
 check(game.life.adventure.scent.step==3 and game.coins==coins+6,"Three discoveries complete the scent trail")
 IslandAdventure.sniff(game,2)
 check(game.coins==coins+6 and not IslandAdventure.begin_scent(game),"Scent rewards cannot be repeated on the same day")
 check(not IslandAdventure.visit_tower(game),"The observation room requires restoration")
 complete_restoration(game)
 check(IslandAdventure.visit_tower(game),"Restoration opens the observation room")
 var memories = game.journal.size()
 IslandAdventure.visit_tower(game)
 check(game.journal.size()==memories,"The first tower memory is recorded only once")
 check(game.save_game(),"Expanded progress saves successfully")
 var saved = game.life.duplicate(true)
 game.life = IslandLife.fresh()
 game.load_game()
 check(game.life.adventure==saved.adventure and game.life.training==saved.training,"Tricks, friends, stories, scent progress and the tower survive reload")
 game.life.adventure.scent = IslandAdventure.fresh().scent
 game.cooldowns.clear()
 game.resting = false
 game.needs.Energy = 95
 UI.safe_override = {"left":105,"right":105,"top":20,"bottom":25}
 for width in [1280,1558]:
  var view = SubViewport.new()
  view.size = Vector2i(width,720)
  root.add_child(view)
  var main = load("res://scenes/main.tscn").instantiate()
  view.add_child(main)
  main.enter_lighthouse()
  await process_frame
  await process_frame
  check(main.page=="Lighthouse Room" and main.current_place=="Lighthouse","Interior keeps the map marker at the tower")
  check(main.camera_button.visible,"The lighthouse view supports keepsake photos")
  main.open_photo_mode()
  check(main.page=="Lighthouse Room" and is_instance_valid(main.photo_overlay),"The special photo stays in the observation room")
  main.close_photo_mode()
  for breed in Art.PUPPIES:
   game.breed = breed
   game.points = 25
   game.active_seconds = 2000
   main.habitat.puppy._process(0)
   var bounds: Rect2 = main.habitat.puppy.sprite.get_global_transform()*main.habitat.puppy.sprite.get_rect()
   var greeting = main.world_host.get_node("LocationGreeting")
   check(bounds.end.y<=695 and not bounds.intersects(greeting.get_child(1).get_global_rect()),"All growing dogs fit the lighthouse beside its speech bubble")
  game.breed = "Puppy"
  main.go_back()
  check(main.page=="Lighthouse","Back leaves the tower interior naturally")
  main.show_page("Park")
  await process_frame
  var resident = main.world_host.get_node("LocationGreeting").get_child(0)
  var press = InputEventMouseButton.new()
  press.pressed = true
  press.button_index = MOUSE_BUTTON_LEFT
  resident.gui_input.emit(press)
  check(is_instance_valid(main.resident_overlay),"Tapping a location resident opens their speaking story")
  for button in main.resident_overlay.find_children("*","Button",true,false):
   if button.text=="Close":
    button.pressed.emit()
    break
  main.start_scent_trail()
  await process_frame
  var trail = main.body.get_child(0)
  trail.set_process(false)
  main.habitat.puppy.set_process(false)
  trail.choose_spot(0)
  trail._process(0)
  check(game.life.adventure.scent.step==0,"Scent discovery waits until the puppy arrives")
  main.habitat.puppy.position = main.habitat.puppy.target
  trail._process(0)
  check(game.life.adventure.scent.step==1,"The selected spot resolves after arrival")
  game.life.adventure.scent = {"day":"2000-01-01","step":3,"route":0,"claimed":"2000-01-01","visits":1}
  game.resting = true
  main.show_page("Scent Trail")
  await process_frame
  var midnight_trail = main.body.get_child(0)
  midnight_trail.set_process(false)
  game.resting = false
  midnight_trail._process(0)
  check(game.life.adventure.scent.day==IslandLife.today() and game.life.adventure.scent.step==0,"A trail waiting during rest resets as soon as the dog wakes after midnight")
  main.go_back()
  check(main.page=="Park","Scent trail Back returns to Park")
  main.arrival_visits.erase("Beach")
  game.life.friends.erase("Kai")
  IslandWeather.preview = "Light rain"
  main.show_page("Beach")
  await process_frame
  check("shower" in main.world_host.get_node("LocationGreeting").text,"The first beach greeting reflects the actual rainy forecast")
  for section in ["Dog Friends","Stories","Playdate","Training"]:
   main.show_page("Life:"+section)
   await process_frame
   await process_frame
   check(main.body.get_child(0).mode==section,"New pages are reachable with existing navigation")
   if section=="Playdate":
    var playmate = main.habitat.playmate
    var friend_bounds: Rect2 = playmate.get_global_transform()*playmate.get_rect()
    var name_bounds: Rect2 = main.habitat.playmate_name.get_global_rect()
    check(friend_bounds.end.y<=695 and name_bounds.end.y<=695 and name_bounds.size.x>70,"Playmate and full name fit wide and compact screens")
  main.show_page("Life:Playdate")
  await process_frame
  game.life.adventure.playmate = "Momo"
  game.life.adventure.buddies.Momo = {"visits":4,"bonus_day":""}
  var playdate = main.body.get_child(0)
  playdate.shared_game("Momo","Mirror tricks")
  check(not is_instance_valid(main.notice_overlay) and not is_instance_valid(main.reward_notice),"Shared-game results appear once without duplicate popups over the panel")
  main.habitat.puppy._process(1.2)
  main.habitat._process(1.2)
  check(main.habitat.playmate.texture==Art.trick_sheet("Shiba Inu") and main.habitat.puppy.sprite.texture==Art.trick_sheet(game.breed),"Mirror tricks visibly animates both dogs offering a paw")
  main.habitat._process(3.5)
  check(main.habitat.shared_clock<0 and not main.habitat.playmate.region_enabled,"Shared tricks return the companion to a clean idle pose")
  game.life.adventure.buddies.Momo.bonus_day = ""
  playdate.shared_game("Momo","Treasure pals")
  main.habitat._process(1.3)
  check(main.habitat.discovery.visible and not main.habitat.ball.visible,"Treasure pals uncovers a visible toy instead of replaying fetch")
  game.resting = true
  main.habitat._process(0)
  check(main.habitat.shared_clock<0 and not main.habitat.discovery.visible,"Starting a rest cancels shared-game animation cleanly")
  playdate._process(0)
  for button in playdate.content.get_children():
   if button is Button and button.has_meta("shared_buddy"):
    check(button.disabled,"Shared games immediately reflect rest and recovery restrictions")
  game.resting = false
  var background = main.habitat.background
  var weather = background.get_child(0)
  check(weather.get_script()==load("res://scripts/weather_layer.gd"),"Weather is a scenery layer behind characters and UI")
  game.set_reduce_motion(true,false)
  var time = weather.clock
  weather._process(1)
  check(weather.clock==time,"Reduce Motion holds weather movement")
  game.set_reduce_motion(false,false)
  game.life.adventure.scent = IslandAdventure.fresh().scent
  game.cooldowns.clear()
  view.queue_free()
  await process_frame
 UI.safe_override.clear()
 IslandWeather.preview = ""
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Island adventure checks: ","PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
