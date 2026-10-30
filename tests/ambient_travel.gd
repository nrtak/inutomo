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
 game.storage_path = "user://ambient_travel_test.json"
 game.intro_seen = true
 game.pending_stage = ""
 game.health = PuppyHealth.fresh()
 game.life = IslandLife.fresh()
 game.resting = false
 game.needs.Energy = 90
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 current_scene = main
 main.show_page("Island")
 await process_frame
 await process_frame
 var map = main.world_host.get_child(0)
 check(map.map_dog.current_breed == game.breed,"Map marker uses the player's actual dog")
 check(not map.map_dog.is_processing(),"Map marker cannot wander independently of its land route")
 var script = load("res://scripts/island_map.gd")
 for origin in map.PLACES:
  for destination in map.PLACES:
   var path = script.route_between(origin,destination)
   check(not path.is_empty(),"Every map destination has a connected land route")
   for i in range(1,path.size()):
    check([path[i-1],path[i]] in map.PATH_LINKS or [path[i],path[i-1]] in map.PATH_LINKS,"Travel follows explicit paths instead of crossing the island directly")
 var before = map.map_dog.position
 map.travel_to("Beach")
 check(main.page == "Island" and map.travelling,"Travel stays on the map while walking")
 map.travel_to("Shop")
 check(map.target_place == "Beach","Extra taps cannot redirect or duplicate travel")
 check(main.menu_button.disabled and main.back_button.disabled,"Navigation cannot interrupt travel with another overlay")
 map._process(map.travel_duration*0.5)
 check(map.map_dog.position.distance_to(before)>5,"The dog moves along its route")
 game.paused_at = 1
 var paused_position = map.map_dog.position
 map._process(1)
 check(map.map_dog.position == paused_position,"Backgrounding pauses map travel")
 game.paused_at = 0
 map._process(map.travel_duration)
 check(main.page == "Beach" and main.current_place == "Beach","Arrival transitions into the selected location")
 check(not main.menu_button.disabled and not main.back_button.disabled,"Arrival restores navigation")
 for place in ["Home","Park","Beach","Shop","Vet Clinic","Puppy Club","Harbor","Keeper’s Cottage","Lighthouse"]:
  main.show_page(place)
  await process_frame
  check(main.habitat.background.get_child_count()>0,"Each location has a layered ambient life renderer")
  var material: ShaderMaterial = main.habitat.background.material
  check(material.get_shader_parameter("water_area") != Vector4.ZERO,"Water movement is configured separately for each location")
 var button = main.menu_button
 button.button_down.emit()
 await create_timer(0.12).timeout
 check(button.scale.x < 1,"Touch feedback gives a small press animation")
 button.button_up.emit()
 await create_timer(0.12).timeout
 check(is_equal_approx(button.scale.x,1),"Releasing restores the button without changing layout")
 check(PuppySteps.COINS.reduce(func(total,value):return total+value,0)<=20,"Daily step rewards stay supplemental to normal play")
 check(Goods.ITEMS.PuppyMeal.price<=10 and Goods.ITEMS.Treat.price<=10,"A normal outing can cover a basic meal or treat")
 main.show_page("Home")
 game.cooldowns.clear()
 game.needs.Hunger = 30
 game.action("Feed")
 check(game.needs.Hunger>30,"A complete session starts with care")
 main.show_page("Island")
 await process_frame
 var trip = main.world_host.get_child(0)
 trip.travel_to("Park")
 trip._process(trip.travel_duration+0.1)
 main.start_activity("Fetch")
 check(main.page=="Fetch","Arriving at Park leads directly into Fetch")
 main.body.get_child(0).finished.emit()
 check(main.page=="Park","Finishing returns to the activity's location")
 main.go_back()
 main.go_back()
 check(main.page=="Home","The full care, map, activity and return flow ends at Home")
 check(game.save_game(),"The completed session saves cleanly")
 main.queue_free()
 await process_frame
 for suffix in ["", ".tmp", ".bak"]:
  if FileAccess.file_exists(game.storage_path+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path+suffix))
 print("Ambient and travel checks: ","PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
